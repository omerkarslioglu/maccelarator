module tb_accelerator;

  logic clk = 1;
  logic rst_n = 0;

  logic curr_mem_we = 0;
  logic search_mem_we = 0;
  logic [7:0] curr_mem_waddr;
  logic [9:0] search_mem_waddr;
  logic [7:0] curr_mem_wdata;
  logic [7:0] search_mem_wdata;
  logic start = 0;
  logic finish;
  logic busy;

  accelerator dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .start_i(start),
    .curr_mem_we_i(curr_mem_we),
    .curr_mem_waddr_i(curr_mem_waddr),
    .curr_mem_wdata_i(curr_mem_wdata),
    .search_mem_we_i(search_mem_we),
    .search_mem_waddr_i(search_mem_waddr),
    .search_mem_wdata_i(search_mem_wdata),
    .finish_o(finish),
    .busy_o(busy)
  );

  initial forever #0.5 clk = !clk;

  initial begin
    start <= 0;
    rst_n <= 0;
    repeat (2) @(posedge clk);
    rst_n <= 1;
    start <= 1;

    @(posedge clk);
    start <= 0;
    
    repeat (254) @(posedge clk) if (dut.cu.accum[1] != 0) $error("Error! time = %0t, accum[1] = %0d", $time, dut.cu.accum[1]); 

    #100000;
    $finish;
  end

endmodule