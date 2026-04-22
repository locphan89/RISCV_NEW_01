/*import rv32i_types::*;

module br_jmp_target_full
(
    input  logic [PC_WIDTH-1:0]   id_pc_i,
    input  logic [DATA_WIDTH-1:0] id_rs1,

    input  rv32i_word             id_bimm_i,
    input  rv32i_word             id_jimm_i,
    input  rv32i_word             id_iimm_i,

    // control
    input  logic                  ex_branch_taken,
    input  logic                  jmp_taken,
    input  logic                  jalr_taken,

    output logic [PC_WIDTH-1:0]   target_addr_o,
    output logic                  target_taken_o,
	 
	 output logic [PC_WIDTH-1:0]   id_branch_addr,
	 input  logic [PC_WIDTH-1:0]   ex_branch_addr
);

    //logic [PC_WIDTH-1:0] branch_addr;
    logic [PC_WIDTH-1:0] jmp_addr;
    logic [PC_WIDTH-1:0] jalr_addr;

    // =========================
    // Compute all candidates
    // =========================

    assign id_branch_addr = id_pc_i + id_bimm_i[31:2];
    assign jmp_addr       = id_pc_i + id_jimm_i[31:2];

    logic [31:0] jalr_byte;
    assign jalr_byte = id_rs1 + id_iimm_i;

    // clear bit 0 + >>2
    assign jalr_addr = (jalr_byte & 32'hFFFFFFFE) >> 2;

    // =========================
    // Select ONE target
    // =========================
   assign target_taken_o = jalr_taken | jmp_taken | ex_branch_taken;
    always_comb begin
        target_addr_o  = '0;
        if (jalr_taken) begin
            target_addr_o  = jalr_addr;
        end else if (jmp_taken) begin
            target_addr_o  = jmp_addr;
        end else if (ex_branch_taken) begin
            target_addr_o  = ex_branch_addr;
        end
    end

endmodule*/

import rv32i_types::*;
module br_jmp_target_full
   
(
    input  logic [PC_WIDTH-1:0] id_pc_i, // PC không có 2 bit cuối => word address
    input  rv32i_word           id_bimm_i,
	 input  rv32i_word           id_jimm_i,
	 input  rv32i_word           id_iimm_i,
	 input  logic [DATA_WIDTH-1:0] id_rs1,
    output logic [PC_WIDTH-1:0] id_branch_addr_o,
	 output logic [PC_WIDTH-1:0] id_jump_addr_o,
	 output logic [PC_WIDTH-1:0] id_jalr_addr_o
);
    logic [31:0] b_offset;
	 logic [31:0] j_offset;

    // vì PC_plus4 là word address, imm là byte offset đã dịch 2-bit,
    // nên để tính word offset ta bỏ 2 bit cuối, tức là shift imm >> 2 (tức là không shift gì vì đã word-aligned)
    // giả sử imm đã được encode ở định dạng word-aligned

    assign b_offset = id_bimm_i[31:2]; 
	 assign j_offset = id_jimm_i[31:2];

    assign id_branch_addr_o = id_pc_i + b_offset;
	 assign id_jump_addr_o   = id_pc_i + j_offset; 
	 
	 logic [31:0] jalr_byte;
    assign jalr_byte = id_rs1 + id_iimm_i;

    // clear bit 0 + >>2
    assign id_jalr_addr_o = (jalr_byte & 32'hFFFFFFFE) >> 2;
	 
endmodule
