module search_mem 
  import acc_pkg::*;
(
  input clk_i,
  input smem_req_t mem_req_i,
  output smem_res_t mem_res_o
);

`define XILINX_FPGA
`ifdef XILINX_FPGA
  (* ram_style="block" *)
`endif
  logic [7:0] mem [0:(31*31)-1];

  int initial_file;

  initial begin
    initial_file =  $fopen(SImgMemPath, "r");
    // if (!initial_file) $error("[ERROR-01] IN MEMORY - Input file was not opened!"); // comment in to sythesis
    $readmemh(SImgMemPath, mem); // load image
    for (int i = 0; i < 5; i++) begin // check mem
      $display("memory[%0d] = %h", i, mem[i]);
    end
  end

  always_ff @(posedge clk_i) if (mem_req_i.write) mem[mem_req_i.waddr] <= mem_req_i.wdata;

  always_comb begin
    foreach (mem_req_i.raddr[i]) begin
      mem_res_o.data[i] = mem[mem_req_i.raddr[i]];
    end
  end

endmodule