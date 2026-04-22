import rv32i_types::*;
module ex1ex2_pipe_reg_rv 
  
(
   input logic                     i_clk,
   input logic                     rst_n,
	
   // EX1 side
   input ex_ctrl_unit_sig          ex1_cs,
   input logic [DATA_WIDTH-1:0]    ex1_alu_a,
   input logic [DATA_WIDTH-1:0]    ex1_alu_b,
   input logic [DATA_WIDTH-1:0]    ex1_fw_b,
   input logic [R_ADDR_WIDTH-1:0]  ex1_wr_reg,
	input logic [ALUC_WIDTH-1:0]    ex1_aluc,
    
   // EX2 side 
   output ex_ctrl_unit_sig         ex2_cs,
   output logic [DATA_WIDTH-1:0]   ex2_alu_a,
   output logic [DATA_WIDTH-1:0]   ex2_alu_b,
   output logic [DATA_WIDTH-1:0]   ex2_fw_b,
   output logic [R_ADDR_WIDTH-1:0] ex2_wr_reg,
	output logic [ALUC_WIDTH-1:0]   ex2_aluc,
	
	input  logic                     ex1_valid_i,
	
	input  logic [PC_WIDTH-1:0]      ex1_jal_result,
	output logic [PC_WIDTH-1:0]      ex2_jal_result,
	
	input  rv32i_word                ex1_imm,
	output rv32i_word                ex2_imm,
	
	input logic [FUNCT3_WIDTH-1:0]   ex1_funct3,
	output logic [FUNCT3_WIDTH-1:0]  ex2_funct3,
	
	output logic ex2_is_rtype,
	input logic ex1_is_rtype
	
	
);

	always_ff @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			ex2_alu_a  <= '0;
			ex2_alu_b  <= '0;
			ex2_aluc   <= '0;
			ex2_cs     <= '0;
			ex2_fw_b   <= '0;
			ex2_wr_reg <= '0;
			ex2_jal_result <= '0;
			ex2_imm <= '0;
			ex2_funct3 <= '0;
			ex2_is_rtype <= 1'b0;
		end else begin
			if (ex1_valid_i) begin
				ex2_alu_a  <= ex1_alu_a;
				ex2_alu_b  <= ex1_alu_b;
				ex2_aluc   <= ex1_aluc;
				ex2_fw_b   <= ex1_fw_b;
				ex2_cs     <= ex1_cs;
				ex2_wr_reg <= ex1_wr_reg;
				ex2_jal_result <= ex1_jal_result;
				ex2_imm <= ex1_imm;
				ex2_funct3 <= ex1_funct3;
				ex2_is_rtype <= ex1_is_rtype;
			end
	  end
	end
	
endmodule
