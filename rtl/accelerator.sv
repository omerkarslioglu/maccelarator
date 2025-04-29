module accelerator 
  import acc_pkg::*;
(
  input clk_i,
  input rst_ni,
  input start_i,
  input curr_mem_we_i,
  input [7:0] curr_mem_waddr_i,
  input [7:0] curr_mem_wdata_i,
  input search_mem_we_i,
  input [9:0] search_mem_waddr_i,
  input [7:0] search_mem_wdata_i,
  output finish_o,
  output busy_o
  );

  logic [7:0] ref_raddr;
  logic [7:0] ref_data;
  smem_res_t smem_res;
  smem_req_t smem_req;
  logic [SMemReadPortNum-1:0][9:0] smem_raddr;

  curr_mem c_mem (
    .clk_i(clk_i),
    .we_i(curr_mem_we_i),
    .waddr_i(curr_mem_waddr_i),
    .wdata_i(curr_mem_wdata_i),
    .raddr_i(ref_raddr),
    .data_o(ref_data)
  );

  search_mem s_mem (
    .clk_i(clk_i),
    .mem_req_i(smem_req),
    .mem_res_o(smem_res)
  );

  control_unit cu (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(start_i),
    .finish_o(finish_o),
    .busy_o(busy_o),
    .smem_res_i(smem_res),
    .smem_raddr_o(smem_raddr),
    .ref_data_i(ref_data),
    .ref_raddr_o(ref_raddr)
  );

  always_comb begin
    foreach (smem_raddr[i]) smem_req.raddr[i] = smem_raddr[i];
    smem_req.waddr = search_mem_waddr_i;
    smem_req.wdata = search_mem_wdata_i;
    smem_req.write = search_mem_we_i;
  end 

endmodule