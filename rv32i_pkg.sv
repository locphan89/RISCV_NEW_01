`ifndef _RV32I_PKG_
`define _RV32I_PKG_

package rv32i_pkg;

typedef logic [31:0] rv32i_word;
typedef logic [4:0]  rv32i_reg;
typedef logic [3:0]  rv32i_mem_wmask;

   // Parameter
   parameter OP_WIDTH     = 3'd7;
   parameter ALUOP_WIDTH  = 2'd3;
   parameter FUNCT3_WIDTH = 2'd3;
	parameter FUNCT7_WIDTH = 3'd7;
   parameter ALUC_WIDTH   = 3'd4;
   parameter R_ADDR_WIDTH = 3'd5;
   parameter ADDR_WIDTH   = 32;
   parameter DATA_WIDTH   = 32;

   parameter FW_ALU_WIDTH = 2'd2;
   parameter PC_WIDTH     = 30;
   parameter DEPTH        = 256;
   parameter INST_WIDTH   = 32;
	
	
	

typedef enum bit [OP_WIDTH-1:0] {
    op_rtype = 7'b0110011, // Rtype: add, sub, and, or, xor, sll, srl, slt
	 op_imm   = 7'b0010011, // Itype: addi, andi, ori, xori, slli, srli, slti
	 op_load  = 7'b0000011, // Itype: lb, lw
	 op_jtype = 7'b1101111, // Jtype: jal
	 op_stype = 7'b0100011, // Stype: sb, sw
	 op_btype = 7'b1100011, // Btype: beq, bne, blt, bgt
	 op_utype = 7'b0110111  // Utype: lui
} rv32i_opcode;


typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lw  = 3'b010
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000,
    aand = 3'b001,
	 aor  = 3'b010,
	 axor = 3'b011,
	 sll  = 3'b100,
	 srl  = 3'b101,
	 slt  = 3'b110
} arith_funct3_t;

/*typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_and = 3'b111,
    alu_or  = 3'b110,
    alu_xor = 3'b100,
    alu_sll = 3'b011,
    alu_srl = 3'b101,
    alu_slt = 3'b010
} alu_ops;*/

typedef enum bit [2:0] {
    alu_add = 3'b000,
	 alu_sub = 3'b001,
    alu_and = 3'b010,
    alu_or  = 3'b011,
    alu_xor = 3'b100,
    alu_sll = 3'b101,
    alu_srl = 3'b110,
    alu_slt = 3'b111
} alu_ops;

typedef enum bit [4:0] {
    fwb_regfile = 5'b00001,
    fwb_wb      = 5'b00010,
	 fwb_alu     = 5'b00100,
    fwb_lui     = 5'b01000,
	 fwb_jal     = 5'b10000
} fw_branch_type;

   // Control Unit
   typedef struct packed {
      logic                   mem_rd_sig;
      logic                   mem_wr_sig;
      logic                   branch_sig;
      logic                   mem2reg_sig;
		logic                   alu_src2_sig;
      logic                   jmp_sig;
      logic                   reg_wr_sig;
      logic [ALUOP_WIDTH-1:0] alu_op_sig;
		
		logic                   pc2reg_sig;
		logic                   imm2reg_sig;
   } ctrl_unit_sig;

   typedef struct packed {
      logic                   mem_rd_sig;
      logic                   mem_wr_sig;
      //logic                   branch_sig;
      logic                   mem2reg_sig;
		logic                   alu_src2_sig;
      //logic                   jmp_sig;
      logic                   reg_wr_sig;
      logic [ALUOP_WIDTH-1:0] alu_op_sig;
		
		logic                   pc2reg_sig;
		logic                   imm2reg_sig;
   } ex_ctrl_unit_sig;

    typedef struct packed {
      logic                   mem_rd_sig;
      logic                   mem_wr_sig;
      logic                   mem2reg_sig;
      logic                   reg_wr_sig;
		
		logic                   pc2reg_sig;
		logic                   imm2reg_sig;
   } mem_ctrl_unit_sig;

    typedef struct packed {
      logic                   mem2reg_sig;
      logic                   reg_wr_sig;
		
		logic                   pc2reg_sig;
		logic                   imm2reg_sig;
   } wb_ctrl_unit_sig; 
	
	

typedef struct packed {
    logic [255:0] dataout;
    logic way_0_hit;
    logic way_1_hit;
    logic way_2_hit;
    logic way_3_hit;
    logic hit;
    logic [2:0] LRU_array_dataout;
} i_cache_pipeline_data;

typedef struct packed {

    rv32i_word cpu_address;
    logic [255:0] dataout;
    logic [255:0] mem_wdata;
	 
	 //logic [127:0] dataout;
    //logic [127:0] mem_wdata;
	 
    logic [31:0]  mem_byte_enable256;
	 
	 //logic [15:0]  mem_byte_enable256;
	 
    logic way_0_hit;
    logic way_1_hit;
    logic way_2_hit;
    logic way_3_hit;
    logic hit;
    logic dirty;
    logic mem_write;
    logic mem_read;
    logic [2:0] LRU_array_dataout;

} d_cache_pipeline_reg;

typedef struct packed {
    logic way_0_hit;
    logic way_1_hit;
    logic way_2_hit;
    logic way_3_hit;
    logic hit;
    logic dirty;
    logic mem_write;
    logic mem_read;
    logic [2:0] LRU_array_dataout;

} cache_pipeline_control;



endpackage
`endif
