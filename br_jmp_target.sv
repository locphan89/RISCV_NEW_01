import rv32i_types::*;
module br_jmp_target
   
(
    input  logic [PC_WIDTH-1:0] if_pc_plus_i, // PC không có 2 bit cuối => word address
    input  rv32i_word           if_bimm_i,
	 input  rv32i_word           if_jimm_i,
    output logic [PC_WIDTH-1:0] if_branch_addr_o,
	 output logic [PC_WIDTH-1:0] if_jump_addr_o
);
    logic [31:0] b_offset;
	 logic [31:0] j_offset;

    // vì PC_plus4 là word address, imm là byte offset đã dịch 2-bit,
    // nên để tính word offset ta bỏ 2 bit cuối, tức là shift imm >> 2 (tức là không shift gì vì đã word-aligned)
    // giả sử imm đã được encode ở định dạng word-aligned

    assign b_offset = if_bimm_i[31:2]; 
	 assign j_offset = if_jimm_i[31:2];
	 
	 

    assign if_branch_addr_o = if_pc_plus_i + b_offset;
	 assign if_jump_addr_o   = if_pc_plus_i + j_offset; 
endmodule
