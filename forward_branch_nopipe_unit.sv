import rv32i_types::*;
module forward_branch_nopipe_unit (
  
    input logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
  
    input logic                    mem_rd_sig,
	 
 
 
    input logic [R_ADDR_WIDTH-1:0] id_rs,
    input logic [R_ADDR_WIDTH-1:0] id_rt,
	 
	 
 
    output logic 	                 fw_b1, 
    output logic                   fw_b2
);

    logic  branch_fw_rs;
	 assign branch_fw_rs = (mem_wr_reg == id_rs) &&(|mem_wr_reg) && ~mem_rd_sig;
    logic  branch_fw_rt;
	 assign branch_fw_rt = (mem_wr_reg == id_rt) &&(|mem_wr_reg) && ~mem_rd_sig;

    assign fw_b1 = branch_fw_rs;
    assign fw_b2 = branch_fw_rt;

endmodule
