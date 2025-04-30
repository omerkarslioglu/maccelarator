package acc_pkg;

  parameter SImgSize = 31; // Search Image Size
  parameter RImgSize = 16; // Reference Image Size

  // localparam string RImgMemPath = "/home/omer/yl/ee565_soc_design/project2/images/ref_image.txt";
  // localparam string SImgMemPath = "/home/omer/yl/ee565_soc_design/project2/images/search_image.txt";

   localparam string RImgMemPath = "/home/omer/yl/ee565_soc_design/project2/sw/reference_design/reference.txt";
   localparam string SImgMemPath = "/home/omer/yl/ee565_soc_design/project2/sw/reference_design/search.txt";

  localparam SMemReadPortNum = 4; // set0: 0-1, set1: 2-3 

  typedef struct packed {
    logic write;
    logic [9:0] waddr;
    logic [7:0] wdata;
    logic [SMemReadPortNum-1:0][9:0] raddr;
  } smem_req_t;

  typedef struct packed {
    logic [SMemReadPortNum-1:0][7:0] data;
  } smem_res_t;

  typedef struct packed {  
    logic [16:0] sad;
    logic [9:0] addr; // addr in search image mem.
  } sad_t;

endpackage