module curr_mem 
  import acc_pkg::*;
(
  input clk_i,
  input we_i,
  input [7:0] waddr_i,
  input [7:0] wdata_i,
  input [7:0] raddr_i,
  output logic [7:0] data_o
);

`define XILINX_FPGA
`ifdef XILINX_FPGA
  (* ram_style="block" *)
`endif
  logic [7:0] mem [0:(16*16)-1];
  int initial_file;

  initial begin
    initial_file =  $fopen(RImgMemPath, "r");
    // if (!initial_file) $error("[ERROR-01] IN MEMORY - Input file was not opened!"); // comment in to sythesis
    $readmemh(RImgMemPath, mem); // load image
    for (int i = 0; i < 5; i++) begin // check mem
      $display("memory[%0d] = %h", i, mem[i]);
    end
  end

  always_ff @(posedge clk_i) if (we_i) mem[waddr_i] <= wdata_i;

  always_comb begin
    data_o = mem[raddr_i];
  end

endmodule