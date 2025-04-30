module control_unit 
  import acc_pkg::*;
(
  input                                          clk_i,
  input                                          rst_ni,
  input                                          start_i,
  input smem_res_t                               smem_res_i,
  input               [7:                     0] ref_data_i,
  output logic        [SMemReadPortNum-1:0][9:0] smem_raddr_o,
  output logic        [7:                     0] ref_raddr_o,
  output logic                                   busy_o,
  output logic                                   finish_o,
  output sad_t                                   min_sad_o
);

  localparam PeNum = 8;
  localparam SImgLastAddr = (SImgSize * SImgSize) - 1;
  localparam RImgLastAddr = (RImgSize * RImgSize) - 1;

  typedef struct packed {
    logic [PeNum-1:0][16:0] sad;
  } sads_t;

  typedef struct packed {
    logic [PeNum-1:0][16:0] sad;
    logic [PeNum-1:0][9:0] addr; // addr in search image mem.
  } last_sads_t;

  // comb
  logic               [7:                    0] next_ref_raddr;
  logic               [9:                    0] next_search_raddr               [    SMemReadPortNum];
  logic               [3:                    0] next_saddr_set_switch_cntr;
  logic                                         next_saddr_set0_en;
  logic                                         next_saddr_set1_en;
  logic                                         next_saddr_set0_en_buff;
  logic                                         next_saddr_set1_en_buff;
  logic                                         next_pe_set_select              [             PeNum];
  logic               [7:                    0] pe_search_data                  [             PeNum];
  logic               [7:                    0] pe_ref_data                     [             PeNum];
  logic               [9:                    0] next_raddr_start_row_pe0;
  logic               [9:                    0] next_raddr_start_row_pe1;
  logic               [9:                    0] next_raddr_start_point_pe0;
  logic               [9:                    0] next_raddr_start_point_pe1;
  logic               [9:                    0] next_raddr_start_point_pe0_buff;
  logic               [9:                    0] next_raddr_start_point_pe1_buff;
  logic               [9:                    0] next_raddr_start_point_pe0_buff2;
  logic               [9:                    0] next_raddr_start_point_pe1_buff2;
  logic                                         next_second_process_ior; // second process in one row
  logic                                         next_pe_rst                     [             PeNum];
  logic                                         reset_addrs;
  logic                                         busy, finish;
  logic                                         next_compare_sad_start;
  logic               [1:                    0] pe_group_id;
  last_sads_t                                   next_sads;
  sads_t                                        new_sads;
  sad_t                                         next_min_sad;
  logic                                         compare_sad_flag;
  logic                                         next_first_sad_load;

  // ff
  logic               [3:                    0] saddr_set_switch_cntr;
  logic                                         saddr_set0_en;
  logic                                         saddr_set1_en;
  logic                                         saddr_set0_en_buff;
  logic                                         saddr_set1_en_buff;
  logic                                         pe_set_select                   [             PeNum];
  logic                                         pe_set_select_q2                [             PeNum];
  logic                                         second_process_ior; // second process in one row
  logic               [7:                    0] ref_data_q;
  logic               [7:                    0] ref_data_q2;
  logic               [7:                    0] ref_data_q3;
  logic               [7:                    0] ref_data_q4;
  logic               [7:                    0] ref_data_q5;
  logic               [7:                    0] ref_data_q6;
  logic               [9:                    0] raddr_start_point_pe0;
  logic               [9:                    0] raddr_start_point_pe1;
  logic               [9:                    0] raddr_start_point_pe0_buff;
  logic               [9:                    0] raddr_start_point_pe1_buff;
  logic               [9:                    0] raddr_start_point_pe0_buff2;
  logic               [9:                    0] raddr_start_point_pe1_buff2;
  logic               [9:                    0] raddr_start_row_pe0;
  logic               [9:                    0] raddr_start_row_pe1;
  logic               [16:                   0] accum                           [             PeNum];
  logic                                         pe_rst                          [             PeNum];
  logic                                         pe_rst_q                        [             PeNum];
  logic                                         start_q;
  logic                                         compare_sad_start;
  logic                                         compare_sad_start_q2;
  logic                                         compare_sad_start_q3;
  logic                                         compare_sad_start_q4;
  logic                                         compare_sad_start_q5;
  logic                                         compare_sad_start_q6;
  logic                                         compare_sad_start_q7;
  last_sads_t                                   sads;
  logic                                         first_sad_load;
  
  always_comb begin
    busy = busy_o; 
    next_sads = sads;
    finish = finish_o;
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
    next_compare_sad_start = compare_sad_start;
    next_raddr_start_point_pe0_buff = raddr_start_point_pe0_buff;
    next_raddr_start_point_pe1_buff = raddr_start_point_pe1_buff;
    next_min_sad = min_sad_o.sad;
    next_first_sad_load = first_sad_load;
    reset_addrs = 0;

    foreach (accum[i]) new_sads.sad[i] = accum[i];
    foreach (pe_rst[i]) next_pe_rst[i] = pe_rst[i];
    foreach (pe_set_select[i]) next_pe_set_select[i] = pe_set_select[i]; 
    foreach (next_search_raddr[i]) next_search_raddr[i] = smem_raddr_o[i];
    
    foreach (pe_search_data[i]) pe_search_data[i] = 0;
    pe_search_data[0] = smem_res_i.data[0];
    pe_search_data[1] = smem_res_i.data[1];

    // Those are wire names to see which process elements get which reference image data according to scheduling
    pe_ref_data[0] = ref_data_i;
    pe_ref_data[1] = ref_data_i;
    pe_ref_data[2] = ref_data_q2;
    pe_ref_data[3] = ref_data_q2;
    pe_ref_data[4] = ref_data_q4;
    pe_ref_data[5] = ref_data_q4;
    pe_ref_data[6] = ref_data_q6;
    pe_ref_data[7] = ref_data_q6;

    compare_sad_flag = compare_sad_start_q7 || compare_sad_start_q5 || compare_sad_start_q3 || compare_sad_start;

    if (!busy_o || (!start_q & start_i)) begin // IDLE STATE
      busy = 0;
      finish = 0;
      next_ref_raddr = 0;
      next_saddr_set0_en = 1;
      next_saddr_set1_en = 0;
      next_saddr_set0_en_buff = 0;
      next_saddr_set1_en_buff = 1;
      next_second_process_ior = 0;
      next_raddr_start_row_pe0 = 0;
      next_raddr_start_row_pe1 =  SImgSize + 1; // 'd32 = s(1,1) ;
      next_raddr_start_point_pe0 = 0;
      next_raddr_start_point_pe1 = SImgSize + 1;
      next_raddr_start_point_pe0_buff = 0;
      next_raddr_start_point_pe1_buff = 0;
      next_raddr_start_point_pe0_buff2 = 0;
      next_raddr_start_point_pe1_buff2 = 0;
      next_saddr_set_switch_cntr = 0;
      next_search_raddr[0] = 0;
      next_search_raddr[1] = SImgSize + 1; // 'd32 = s(1,1) 
      next_search_raddr[2] = SImgSize; // 'd31 = s(1,0)
      next_search_raddr[3] = 2 * SImgSize + 1; // 'd63 = s(2,1)
      next_compare_sad_start = 0;
      foreach (pe_rst[i]) next_pe_rst[i] = 1;
      foreach (next_pe_set_select[i]) next_pe_set_select[i] = 0;
      foreach (sads.sad[i]) next_sads = 0;
      busy = !start_q & start_i;
      next_first_sad_load = busy;
      next_min_sad.sad = 0;
      next_min_sad.addr = 0;
    end else begin // EXECUTION STATE
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

      if (saddr_set_switch_cntr == RImgSize - 1) begin // Determine the beginning addr to switch down row when calculating SAD in one square in the search block // Todo: assert whenever ref_addr_o 0 saddr_set0_en should be 1 and saddr_set1_en should be 0 
        next_raddr_start_row_pe0 = saddr_set0_en ? smem_raddr_o[0] + (SImgSize + 1) / 2: 
                                   saddr_set1_en ? smem_raddr_o[2] + (SImgSize + 1) / 2 : 0; // saving the (search block last raddr + image size) / 2 for pe0 to continue the process
        next_raddr_start_row_pe1 = saddr_set0_en ? smem_raddr_o[1] + (SImgSize + 1) / 2: 
                                   saddr_set1_en ? smem_raddr_o[3] + (SImgSize + 1) / 2 : 0; // saving the (search block last raddr + image size) / 2 for pe1 to continue the process
      end

      if (ref_raddr_o == 0) begin // Determine next reference addr. and save the start addresses of pe0 and pe1 // Todo: assert whenever ref_addr_o 0 saddr_set0_en should be 1 and saddr_set1_en should be 0 
        for (int i = 0; i < 2; i++) next_pe_rst[i] = 0;
        next_raddr_start_point_pe0 = !second_process_ior ? smem_raddr_o[0] + PeNum : smem_raddr_o[0] + PeNum + SImgSize - 1 + (SImgSize + 1) / 2; // if same process element execute on same row again, beginning addr. should be previous beginnig addr. + half of the search image size
        next_raddr_start_point_pe1 = !second_process_ior ? smem_raddr_o[1] + PeNum : smem_raddr_o[1] + PeNum + SImgSize - 1 + (SImgSize + 1) / 2; // if same process element down row, it must start at two bottom rows according to scheduling 
        next_raddr_start_point_pe0_buff = raddr_start_point_pe0;
        next_raddr_start_point_pe1_buff = raddr_start_point_pe1;
        next_raddr_start_point_pe0_buff2 = raddr_start_point_pe0_buff; 
        next_raddr_start_point_pe1_buff2 = raddr_start_point_pe1_buff; 
        next_ref_raddr++;
        next_compare_sad_start = 0;
      end else if (ref_raddr_o != RImgLastAddr) begin
        for (int i = 0; i < 2; i++) next_pe_rst[i] = 0;
        next_ref_raddr++;
        next_compare_sad_start = 0;
      end else begin
        for (int i = 0; i < 2; i++) next_pe_rst[i] = 1;
        next_second_process_ior = !second_process_ior; 
        next_ref_raddr = 0;
        next_compare_sad_start = 1;
      end

      pe_group_id = compare_sad_start_q7 ? 2'b11 : 
                    compare_sad_start_q5 ? 2'b10 :
                    compare_sad_start_q3 ? 2'b01 :
                    compare_sad_start ? 2'b00 : 2'b00;

      next_first_sad_load = compare_sad_start_q7 ? 0 : next_first_sad_load;

      next_sads = compare_sad(first_sad_load, sads, new_sads, pe_group_id, compare_sad_flag, raddr_start_point_pe0_buff2, raddr_start_point_pe1_buff2); 
      next_min_sad = determine_min_sad(next_sads);

      for (int i = 2; i < PeNum; i++) next_pe_rst[i] = pe_rst_q[i-2]; // PE reset signals are delayed except PE0 & PE1
      foreach (next_pe_set_select[i]) next_pe_set_select[i] = (((!saddr_set0_en && saddr_set1_en) || (saddr_set0_en && !saddr_set1_en)) && (next_saddr_set0_en && next_saddr_set1_en)) ? !pe_set_select[0] : pe_set_select[0]; // Select search mem. reading port for each PE
      for (int i = 2; i < PeNum; i++) next_pe_set_select[i] = pe_set_select_q2[i-2];
      
      for (int i = 0; i < PeNum; i = i + 2) begin // 2:1 muxes to select reading proper data from searh mem.
        pe_search_data[i]   = (!pe_set_select[i]) ? smem_res_i.data[0] : smem_res_i.data[2]; 
        pe_search_data[i+1] = (!pe_set_select[i+1]) ? smem_res_i.data[1] : smem_res_i.data[3]; 
      end

      reset_addrs = (smem_raddr_o[SMemReadPortNum-1] == SImgLastAddr - (PeNum - 2)) ? 1 : 0; 

      next_search_raddr[0] = reset_addrs ? 0 : (ref_raddr_o == RImgLastAddr) ? next_raddr_start_point_pe0 : ((next_saddr_set0_en) ? (!saddr_set0_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe0 : next_search_raddr[0] + 1) : 0); 
      next_search_raddr[1] = reset_addrs ? SImgSize + 1  : (ref_raddr_o == RImgLastAddr) ? next_raddr_start_point_pe1 : ((next_saddr_set0_en) ? (!saddr_set0_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe1 : next_search_raddr[1] + 1) : 0); 
      next_search_raddr[2] = (ref_raddr_o == RImgLastAddr) ? next_search_raddr[2] + 1 : ((next_saddr_set1_en) ? (!saddr_set1_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe0 : next_search_raddr[2] + 1) : 0); 
      next_search_raddr[3] = (ref_raddr_o == RImgLastAddr) ? next_search_raddr[3] + 1 : ((next_saddr_set1_en) ? (!saddr_set1_en && saddr_set_switch_cntr == RImgSize - 1 ? next_raddr_start_row_pe1 : next_search_raddr[3] + 1) : 0);

      busy = (smem_raddr_o[3] == SImgLastAddr) ? 0 : busy;
      finish = (smem_raddr_o[3] == SImgLastAddr) ? 1 : finish;
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      busy_o <= 0;
      start_q <= 0;
      finish_o <= 0;
      min_sad_o.sad <= 0;
      min_sad_o.addr <= 0;
      ref_data_q <= 0;
      ref_data_q2 <= 0;
      ref_data_q3 <= 0;
      ref_data_q4 <= 0;
      ref_data_q5 <= 0;
      ref_data_q6 <= 0;
      ref_raddr_o <= 0;
      saddr_set0_en <= 1;
      saddr_set1_en <= 0;
      first_sad_load <= 0;
      saddr_set0_en_buff <= 0;
      saddr_set1_en_buff <= 1;
      second_process_ior <= 0;
      raddr_start_row_pe0 <= 0;
      raddr_start_row_pe1 <=  SImgSize + 1; // 'd32 = s(1,1) ;
      raddr_start_point_pe0 <= 0;
      raddr_start_point_pe1 <= SImgSize + 1;
      raddr_start_point_pe0_buff <= 0;
      raddr_start_point_pe1_buff <= 0;
      raddr_start_point_pe0_buff2 <= 0;
      raddr_start_point_pe1_buff2 <= 0;
      saddr_set_switch_cntr <= 0;
      smem_raddr_o[0] <= 0;
      smem_raddr_o[1] <= SImgSize + 1; // 'd32 = s(1,1) 
      smem_raddr_o[2] <= SImgSize; // 'd31 = s(1,0)
      smem_raddr_o[3] <= 2 * SImgSize + 1; // 'd63 = s(2,1)
      compare_sad_start <= 0;
      compare_sad_start_q2 <= 0;
      compare_sad_start_q3 <= 0;
      compare_sad_start_q4 <= 0;
      compare_sad_start_q5 <= 0;
      compare_sad_start_q6 <= 0;
      compare_sad_start_q7 <= 0;
      foreach (pe_rst[i]) pe_rst[i] <= 1;
      foreach (pe_rst[i]) pe_rst_q[i] <= 1;
      foreach (sads.sad[i]) sads.sad[i] <= 0;
      foreach (pe_set_select[i]) pe_set_select[i] <= 0;
      foreach (pe_set_select_q2[i]) pe_set_select_q2[i] <= 0;
    end else begin
      busy_o <= busy;
      sads <= next_sads;
      finish_o <= finish;
      start_q <= start_i;
      ref_data_q <= ref_data_i;
      ref_data_q2 <= ref_data_q;
      ref_data_q3 <= ref_data_q2;
      ref_data_q4 <= ref_data_q3;
      ref_data_q5 <= ref_data_q4;
      ref_data_q6 <= ref_data_q5;
      ref_raddr_o <= next_ref_raddr;
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
      raddr_start_point_pe0_buff <= next_raddr_start_point_pe0_buff;
      raddr_start_point_pe1_buff <= next_raddr_start_point_pe1_buff;
      raddr_start_point_pe0_buff2 <= next_raddr_start_point_pe0_buff2;
      raddr_start_point_pe1_buff2 <= next_raddr_start_point_pe1_buff2;
      compare_sad_start <= next_compare_sad_start;
      compare_sad_start_q2 <= compare_sad_start;
      compare_sad_start_q3 <= compare_sad_start_q2;
      compare_sad_start_q4 <= compare_sad_start_q3;
      compare_sad_start_q5 <= compare_sad_start_q4;
      compare_sad_start_q6 <= compare_sad_start_q5;
      compare_sad_start_q7 <= compare_sad_start_q6;
      pe_rst <= next_pe_rst;
      pe_rst_q <= pe_rst;
      foreach (pe_set_select[i]) pe_set_select_q2[i] <= pe_set_select[i];
      foreach (pe_set_select[i]) pe_set_select[i] <= next_pe_set_select[i];
      foreach (smem_raddr_o[i]) smem_raddr_o[i] <= next_search_raddr[i];
      min_sad_o.sad <= next_min_sad.sad;
      min_sad_o.addr <= next_min_sad.addr;
      first_sad_load <= next_first_sad_load;
    end
  end

  always_ff @(posedge clk_i) begin : processing_elements
    if (!rst_ni) foreach (accum[i]) accum[i] <= 0;
    else foreach (accum[i]) accum[i] <= proces_element_func(pe_rst[i], accum[i], pe_ref_data[i], pe_search_data[i]);
  end

  // This function calculates the absolute difference between the reference image data and the search image data and adds it to the previous value of the PE accumulator.
  function automatic logic [16:0] proces_element_func (logic pe_rst, logic [16:0] pre_pe_value, logic [7:0] ref_data, logic [7:0] search_data);
    logic [7:0] abs_diff;
    if (search_data < ref_data) abs_diff = ref_data - search_data;
    else abs_diff = search_data - ref_data;
    return !pe_rst ? pre_pe_value + abs_diff : abs_diff;
  endfunction

  // This function compares the SAD values and returns the smaller one.
  function automatic last_sads_t compare_sad (logic first_load, last_sads_t pre_last_sads, sads_t new_sads, logic [1:0] pe_group_id, logic compare, logic [9:0] raddr_start_point_pe0, logic [9:0] raddr_start_point_pe1); 
    last_sads_t last_sads;
    logic [PeNum-1:0][9:0] min_sad_point_saddr;
    
    min_sad_point_saddr[0] = raddr_start_point_pe0;
    min_sad_point_saddr[1] = raddr_start_point_pe1;
    for (int i = 2; i < PeNum; i++) min_sad_point_saddr[i] = min_sad_point_saddr[i-2] + 2; 

    foreach (last_sads.sad[i]) last_sads.sad[i] = pre_last_sads.sad[i];
    foreach (last_sads.addr[i]) last_sads.addr[i] = pre_last_sads.addr[i];

    case (pe_group_id)
      2'b00: begin
        last_sads.sad[0] = (first_load || new_sads.sad[0] < pre_last_sads.sad[0]) ? new_sads.sad[0] : last_sads.sad[0];
        last_sads.sad[1] = (first_load || new_sads.sad[1] < pre_last_sads.sad[1]) ? new_sads.sad[1] : last_sads.sad[1];
        last_sads.addr[0] = (first_load || new_sads.sad[0] <= pre_last_sads.sad[0]) ? min_sad_point_saddr[0] : last_sads.addr[0];
        last_sads.addr[1] = (first_load || new_sads.sad[1] <= pre_last_sads.sad[1]) ? min_sad_point_saddr[1] : last_sads.addr[1];
      end
      2'b01: begin
        last_sads.sad[2] = (first_load || new_sads.sad[2] < pre_last_sads.sad[2]) ? new_sads.sad[2] : last_sads.sad[2];
        last_sads.sad[3] = (first_load || new_sads.sad[3] < pre_last_sads.sad[3]) ? new_sads.sad[3] : last_sads.sad[3];
        last_sads.addr[2] = (first_load || new_sads.sad[2] <= pre_last_sads.sad[2]) ? min_sad_point_saddr[2] : last_sads.addr[2];
        last_sads.addr[3] = (first_load || new_sads.sad[3] <= pre_last_sads.sad[3]) ? min_sad_point_saddr[3] : last_sads.addr[3];
      end
      2'b10: begin
        last_sads.sad[4] = (first_load || new_sads.sad[4] < pre_last_sads.sad[4]) ? new_sads.sad[4] : last_sads.sad[4];
        last_sads.sad[5] = (first_load || new_sads.sad[5] < pre_last_sads.sad[5]) ? new_sads.sad[5] : last_sads.sad[5];
        last_sads.addr[4] = (first_load || new_sads.sad[4] <= pre_last_sads.sad[4]) ? min_sad_point_saddr[4] : last_sads.addr[4];
        last_sads.addr[5] = (first_load || new_sads.sad[5] <= pre_last_sads.sad[5]) ? min_sad_point_saddr[5] : last_sads.addr[5];
      end
      2'b11: begin
        last_sads.sad[6] = (first_load || new_sads.sad[6] < pre_last_sads.sad[6]) ? new_sads.sad[6] : last_sads.sad[6];
        last_sads.sad[7] = (first_load || new_sads.sad[7] < pre_last_sads.sad[7]) ? new_sads.sad[7] : last_sads.sad[7];
        last_sads.addr[6] = (first_load || new_sads.sad[6] <= pre_last_sads.sad[6]) ? min_sad_point_saddr[6] : last_sads.addr[6];
        last_sads.addr[7] = (first_load || new_sads.sad[7] <= pre_last_sads.sad[7]) ? min_sad_point_saddr[7] : last_sads.addr[7];
      end
    endcase

    return compare ? last_sads : pre_last_sads;
  endfunction

  // This function determines the minimum SAD value from the last SAD values.
  function automatic sad_t determine_min_sad (last_sads_t sads);
    int lvl1_idx = 0;
    int lvl2_idx = 0;

    logic [16:0] min_sad_lvl1 [4];
    logic [16:0] min_sad_lvl2 [2];
    logic [9:0] min_sad_addr_lvl1 [4];
    logic [9:0] min_sad_addr_lvl2 [2];

    sad_t min_sad;

    for (int i = 1; i < PeNum; i = i + 2) begin
      if (sads.sad[i] <= sads.sad[i-1]) begin
        min_sad_lvl1[lvl1_idx] = sads.sad[i];
        min_sad_addr_lvl1[lvl1_idx] = sads.addr[i];
      end else begin
        min_sad_lvl1[lvl1_idx] = sads.sad[i-1];
        min_sad_addr_lvl1[lvl1_idx] = sads.addr[i-1];
      end
      lvl1_idx++;
    end
    
    for (int i = 1; i < lvl1_idx; i = i + 2) begin
      if (min_sad_lvl1[i] <= min_sad_lvl1[i-1]) begin
        min_sad_lvl2[lvl2_idx] = min_sad_lvl1[i];
        min_sad_addr_lvl2[lvl2_idx] = min_sad_addr_lvl1[i];
      end else begin
        min_sad_lvl2[lvl2_idx] = min_sad_lvl1[i-1];
        min_sad_addr_lvl2[lvl2_idx] = min_sad_addr_lvl1[i-1];
      end
      lvl2_idx++;
    end

    if (min_sad_lvl2[0] < min_sad_lvl2[1]) begin
      min_sad.sad = min_sad_lvl2[0];
      min_sad.addr = min_sad_addr_lvl2[0];
    end else begin
      min_sad.sad = min_sad_lvl2[1];
      min_sad.addr = min_sad_addr_lvl2[1];
    end

    return min_sad;
  endfunction

endmodule