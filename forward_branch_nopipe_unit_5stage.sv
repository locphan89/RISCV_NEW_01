 import rv32i_types::*;

module forward_branch_nopipe_unit_5stage (
    // MEM stage signals (for ADD→BEQ forwarding)
    input logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
	 input logic                    mem_is_rtype,
	 
	 // EX Stage U-type: lui, J-type: jal
	 input logic                    ex_imm2reg_sig,
	 input logic                    ex_pc2reg_sig,
	 input logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
	 
    
    
    // ID stage signals (BEQ operands)
    input logic [R_ADDR_WIDTH-1:0] id_rs1,
    input logic [R_ADDR_WIDTH-1:0] id_rs2,
    
    // Forward control outputs
    output fw_branch_type          fw_b1,
    output fw_branch_type          fw_b2 
);
	 
	 /*logic  is_mem_n;
	 assign is_mem_n = ~mem_is_rtype;
	 
	 logic  is_ex_n;
	 assign is_ex_n  = ~(ex_imm2reg_sig | ex_pc2reg_sig);*/
	 
	 logic rs1_idex_match;
	 assign rs1_idex_match = (ex_wr_reg == id_rs1);
	 
	 logic rs2_idex_match;
	 assign rs2_idex_match = (ex_wr_reg == id_rs2);
	 
	 // Priority: EX > MEM > WB
	 
    // ===== RS Forwarding Logic ==================================================
    logic branch_fw_rs1_from_alu;
    logic branch_fw_rs1_from_wb;
	 logic branch_fw_rs1_from_lui;
    logic branch_fw_rs1_from_jal;
	 
	 //logic temp_alu;
	 //assign temp_alu = mem_is_rtype && is_ex_n;
	 
	 //logic temp_lw;
	 //assign temp_lw = wb_reg_wr_sig && is_mem_n && is_ex_n;
    
    // Forward từ MEM stage (ALU result)
    assign branch_fw_rs1_from_alu = (mem_wr_reg == id_rs1) && mem_is_rtype;
    
    
	 // Forward từ EX stage (LUI result)
    assign branch_fw_rs1_from_lui = rs1_idex_match && ex_imm2reg_sig;
	 
	 // Forward từ EX stage (JAL result)
    assign branch_fw_rs1_from_jal = rs1_idex_match && ex_pc2reg_sig;
	 
    // ===== RT Forwarding Logic ==================================================
    logic branch_fw_rs2_from_alu;
    logic branch_fw_rs2_from_wb;
	 logic branch_fw_rs2_from_lui;
    logic branch_fw_rs2_from_jal;
    
    // Forward từ MEM stage (ALU result)
    assign branch_fw_rs2_from_alu = (mem_wr_reg == id_rs2) && mem_is_rtype;
    
	 // Forward từ EX stage (LUI result)
    assign branch_fw_rs2_from_lui = rs2_idex_match && ex_imm2reg_sig;
	 
	 // Forward từ EX stage (JAL result)
    assign branch_fw_rs2_from_jal = rs2_idex_match && ex_pc2reg_sig;
    
    // ===== Output Encoding ======================================================
    
     assign fw_b1 = branch_fw_rs1_from_jal      ? fwb_jal :
                    branch_fw_rs1_from_alu      ? fwb_alu :
						  branch_fw_rs1_from_lui      ? fwb_lui :
						                                fwb_regfile;
																  
     assign fw_b2 = branch_fw_rs2_from_jal      ? fwb_jal :
                    branch_fw_rs2_from_alu      ? fwb_alu :
						  branch_fw_rs2_from_lui      ? fwb_lui :
						                                fwb_regfile;

endmodule