module control_unit 
  import acc_pkg::*;
(
  input clk_i,
  input rst_ni,

  input smem_res_t smem_res_i,
  output smem_req_t smem_req_o,

  input [7:0] ref_data_i,
  output logic [7:0] ref_raddr_o
);

  localparam PeNum = 8;
  localparam SImgLastAddr = (SImgSize * SImgSize) - 1;
  localparam RImgLastAddr = (RImgSize * RImgSize) - 1;

  // TODO: if (next_search_raddr3_o == SImgLastAddr) is reset condition for all reg

  // comb
  logic [7:0] next_ref_raddr;
  logic [9:0] next_search_raddr [SMemReadPortNum];
  logic [3:0] next_saddr_set_switch_cntr;
  logic next_saddr_set0_en;
  logic next_saddr_set1_en;
  logic next_saddr_set0_en_buff;
  logic next_saddr_set1_en_buff;
  logic next_pe_set_select [PeNum];
  logic [7:0] pe_search_data [PeNum];
  logic [7:0] pe_ref_data [PeNum];
  logic [9:0] next_raddr_start_row_pe0;
  logic [9:0] next_raddr_start_row_pe1;
  logic [9:0] next_raddr_start_point_pe0;
  logic [9:0] next_raddr_start_point_pe1;
  logic next_second_process_ior; // second process in one row
  logic next_pe_rst [PeNum];
  logic reset_addrs;

  // ff
  logic [3:0] saddr_set_switch_cntr;
  logic saddr_set0_en;
  logic saddr_set1_en;
  logic saddr_set0_en_buff;
  logic saddr_set1_en_buff;
  logic pe_set_select [PeNum];

  logic pe_set_select_q2 [PeNum];

  logic second_process_ior; // second process in one row
  logic [7:0] ref_data_q;
  logic [7:0] ref_data_q2;
  logic [7:0] ref_data_q3;
  logic [7:0] ref_data_q4;
  logic [7:0] ref_data_q5;
  logic [7:0] ref_data_q6;
  logic [9:0] raddr_start_point_pe0;
  logic [9:0] raddr_start_point_pe1;
  logic [9:0] raddr_start_row_pe0;
  logic [9:0] raddr_start_row_pe1;
  logic [16:0] accum [PeNum];
  logic pe_rst [PeNum];
  logic pe_rst_q [PeNum];
  
  always_comb begin
    next_ref_raddr = ref_raddr_o;
    next_saddr_set0_en = saddr_set0_en;
    next_saddr_set1_en = saddr_set1_en;
    next_raddr_start_point_pe0 = raddr_start_point_pe0;
    next_raddr_start_point_pe1 = raddr_start_point_pe1;
    next_saddr_set_switch_cntr = saddr_set_switch_cntr;
    next_saddr_set0_en_buff = saddr_set0_en_buff; 
    next_saddr_set1_en_buff = saddr_set1_en_buff;
    next_raddr_start_row_pe0 = raddr_start_row_pe0; 
    next_raddr_start_row_pe1 = raddr_start_row_pe1;
    next_second_process_ior = second_process_ior;
    next_pe_set_select = pe_set_select;

    foreach (pe_rst[i]) next_pe_rst[i] = pe_rst[i];
    foreach (pe_set_select[i]) next_pe_set_select[i] = pe_set_select[i]; 
    foreach (next_search_raddr[i]) next_search_raddr[i] = smem_req_o.raddr[i];

    // Those are wire names to see which process elements get which reference image data according to scheduling
    pe_ref_data[0] = ref_data_i;
    pe_ref_data[1] = ref_data_i;
    pe_ref_data[2] = ref_data_q2;
    pe_ref_data[3] = ref_data_q2;
    pe_ref_data[4] = ref_data_q4;
    pe_ref_data[5] = ref_data_q4;
    pe_ref_data[6] = ref_data_q6;
    pe_ref_data[7] = ref_data_q6;

    if (saddr_set_switch_cntr == 5) begin
      next_saddr_set_switch_cntr++;
      next_saddr_set0_en = !saddr_set0_en_buff;
      next_saddr_set1_en = !saddr_set1_en_buff;
    end else if (saddr_set_switch_cntr == 14) begin // to select which search reading port will be activated
      next_saddr_set_switch_cntr++;
      next_saddr_set0_en_buff = saddr_set0_en; 
      next_saddr_set1_en_buff = saddr_set1_en;
    end else if (saddr_set_switch_cntr != RImgSize - 1) begin
      next_saddr_set_switch_cntr++;
    end else begin // if saddr_set_switch_cntr equals to RImgSize - 1, four port (two sets of ports) will be activated for 6 cycles
      next_saddr_set_switch_cntr = 0;
      next_saddr_set0_en = 1; 
      next_saddr_set1_en = 1;
    end

    // Determine the beginning addr to switch down row when calculating SAD in one square in the search block
    if (saddr_set_switch_cntr == RImgSize - 1) begin // Todo: assert whenever ref_addr_o 0 saddr_set0_en should be 1 and saddr_set1_en should be 0 
      next_raddr_start_row_pe0 = saddr_set0_en ? smem_req_o.raddr[0] + (SImgSize + 1) / 2: 
                                 saddr_set1_en ? smem_req_o.raddr[2] + (SImgSize + 1) / 2 : 0; // saving the (search block last raddr + image size) / 2 for pe0 to continue the process
      next_raddr_start_row_pe1 = saddr_set0_en ? smem_req_o.raddr[1] + (SImgSize + 1) / 2: 
                                 saddr_set1_en ? smem_req_o.raddr[3] + (SImgSize + 1) / 2 : 0; // saving the (search block last raddr + image size) / 2 for pe1 to continue the process
    end

    // Determine next reference addr. and save the start addresses of pe0 and pe1
    if (ref_raddr_o == 0) begin // Todo: assert whenever ref_addr_o 0 saddr_set0_en should be 1 and saddr_set1_en should be 0 
      for (int i = 0; i < 2; i++) next_pe_rst[i] = 0;
      next_raddr_start_point_pe0 = !second_process_ior ? smem_req_o.raddr[0] + PeNum : smem_req_o.raddr[0] + PeNum + SImgSize - 1 + (SImgSize + 1) / 2; // if same process element execute on same row again, beginning addr. should be previous beginnig addr. + half of the search image size
      next_raddr_start_point_pe1 = !second_process_ior ? smem_req_o.raddr[1] + PeNum : smem_req_o.raddr[1] + PeNum + SImgSize - 1 + (SImgSize + 1) / 2; // if same process element down row, it must start at two bottom rows according to scheduling 
      next_ref_raddr++;
    end else if (ref_raddr_o != RImgLastAddr) begin
      for (int i = 0; i < 2; i++) next_pe_rst[i] = 0;
      next_ref_raddr++;
    end else begin
      for (int i = 0; i < 2; i++) next_pe_rst[i] = 1;
      next_second_process_ior = !second_process_ior; 
      next_ref_raddr = 0;
    end

    // PE reset signals are delayed except PE0 & PE1
    for (int i = 2; i < PeNum; i++) next_pe_rst[i] = pe_rst_q[i-2];

    // Select search mem. reading port for each PE
    next_pe_set_select[0] = (((!saddr_set0_en && saddr_set1_en) || (saddr_set0_en && !saddr_set1_en)) && (next_saddr_set0_en && next_saddr_set1_en)) ? !pe_set_select[0] : pe_set_select[0];
    next_pe_set_select[1] = next_pe_set_select[0]; // same with pe0
    for (int i = 2; i < PeNum; i++) next_pe_set_select[i] = pe_set_select_q2[i];

    // 2:1 muxes to select reading proper data from searh mem.
    for (int i = 0; i < PeNum; i = i + 2) begin
      pe_search_data[i]   = (!pe_set_select[i]) ? smem_res_i.data[0] : smem_res_i.data[2]; 
      pe_search_data[i+1] = (!pe_set_select[i+1]) ? smem_res_i.data[1] : smem_res_i.data[3]; 
    end

    reset_addrs = (smem_req_o.raddr[SMemReadPortNum-1] == SImgLastAddr - (PeNum - 2)) ? 1 : 0; 

    // Determine the search addresses
    next_search_raddr[0] = reset_addrs ? 0 : (ref_raddr_o == RImgLastAddr) ? next_raddr_start_point_pe0 : ((next_saddr_set0_en) ? (!saddr_set0_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe0 : next_search_raddr[0] + 1) : 0); 
    next_search_raddr[1] = reset_addrs ? SImgSize + 1  : (ref_raddr_o == RImgLastAddr) ? next_raddr_start_point_pe1 : ((next_saddr_set0_en) ? (!saddr_set0_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe1 : next_search_raddr[1] + 1) : 0); 
    next_search_raddr[2] = (ref_raddr_o == RImgLastAddr) ? next_search_raddr[2] + 1 : ((next_saddr_set1_en) ? (!saddr_set1_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe0 : next_search_raddr[2] + 1) : 0); 
    next_search_raddr[3] = (ref_raddr_o == RImgLastAddr) ? next_search_raddr[3] + 1 : ((next_saddr_set1_en) ? (!saddr_set1_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe1 : next_search_raddr[3] + 1) : 0);
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ref_data_q <= 0;
      ref_data_q2 <= 0;
      ref_data_q3 <= 0;
      ref_data_q4 <= 0;
      ref_data_q5 <= 0;
      ref_data_q6 <= 0;
      ref_raddr_o <= 0;
      saddr_set0_en <= 1;
      saddr_set1_en <= 0;
      saddr_set0_en_buff <= 0;
      saddr_set1_en_buff <= 1;
      second_process_ior <= 0;
      raddr_start_point_pe0 <= 0;
      raddr_start_point_pe1 <= 0;
      saddr_set_switch_cntr <= 0;
      smem_req_o.raddr[0] <= 0;
      smem_req_o.raddr[1] <= SImgSize + 1; // 'd32 = s(1,1) 
      smem_req_o.raddr[2] <= SImgSize; // 'd31 = s(1,0)
      smem_req_o.raddr[3] <= 2 * SImgSize + 1; // 'd63 = s(2,1)
      foreach (pe_rst[i]) pe_rst[i] <= 1;
      foreach (pe_rst[i]) pe_rst_q[i] <= 1;
      foreach (pe_set_select[i]) pe_set_select[i] <= 0;
      foreach (pe_set_select_q2[i]) pe_set_select_q2[i] <= 0;
    end else begin 
      ref_raddr_o <= next_ref_raddr;

      ref_data_q <= ref_data_i;
      ref_data_q2 <= ref_data_q;
      ref_data_q3 <= ref_data_q2;
      ref_data_q4 <= ref_data_q3;
      ref_data_q5 <= ref_data_q4;
      ref_data_q6 <= ref_data_q5;
      
      saddr_set0_en <= next_saddr_set0_en;
      saddr_set1_en <= next_saddr_set1_en;

      saddr_set0_en_buff <= next_saddr_set0_en_buff;
      saddr_set1_en_buff <= next_saddr_set1_en_buff;
      second_process_ior <= next_second_process_ior;

      raddr_start_row_pe0 <= next_raddr_start_row_pe0;
      raddr_start_row_pe1 <= next_raddr_start_row_pe1;
      
      saddr_set_switch_cntr <= next_saddr_set_switch_cntr;
      raddr_start_point_pe0 <= next_raddr_start_point_pe0;
      raddr_start_point_pe1 <= next_raddr_start_point_pe1;

      foreach (pe_rst[i]) pe_rst[i] <= next_pe_rst[i];
      foreach (pe_rst[i]) pe_rst_q[i] <= pe_rst[i];
      foreach (pe_set_select[i]) pe_set_select_q2[i] <= pe_set_select[i];
      foreach (pe_set_select[i]) pe_set_select[i] <= next_pe_set_select[i];
      foreach (smem_req_o.raddr[i]) smem_req_o.raddr[i] <= next_search_raddr[i];
    end
  end

  always_ff @(posedge clk_i) begin : processing_elements
    if (!rst_ni) foreach (accum[i]) accum[i] <= 0;
    else foreach (accum[i]) accum[i] <= proces_element_func(pe_rst[i], accum[i], pe_ref_data[i], pe_search_data[i]);
  end

  function automatic logic [16:0] proces_element_func (logic pe_rst, logic [16:0] pre_pe_value, logic [7:0] ref_data, logic [7:0] search_data);
    logic [7:0] abs_diff;
    if (search_data < ref_data) abs_diff = ref_data - search_data;
    else abs_diff = search_data - ref_data;
    return !pe_rst ? pre_pe_value + abs_diff : abs_diff;
  endfunction

endmodule