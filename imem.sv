import rv32i_types::*;
module imem
  
(
   output logic [DATA_WIDTH-1:0]    if_inst_o, 
   input  logic [PC_WIDTH-1:0]    if_pc_i
);

  //(* romstyle = "M10K" *)  // hoặc "logic"
  logic [DATA_WIDTH-1:0] imem [0:DEPTH-1]; 

  initial begin
     $readmemb("test3.txt", imem); 
  end

 // assign if_inst_o = imem [if_pc_i >> 2];
   assign if_inst_o = imem [if_pc_i];
 

endmodule
