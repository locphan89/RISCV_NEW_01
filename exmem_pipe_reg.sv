import rv32i_types::*;
module exmem_pipe_reg
  
(
    input logic                     i_clk,
    input logic                     rst_n,
	 
    // Excute side
    input mem_ctrl_unit_sig         ex_cs,
    input logic [DATA_WIDTH-1:0]    ex_alu_out,
    input logic [DATA_WIDTH-1:0]    ex_b,
    input logic [R_ADDR_WIDTH-1:0]  ex_wr_reg,
	 
    // Mem side
    output mem_ctrl_unit_sig        mem_cs,
    output logic [DATA_WIDTH-1:0]   mem_addr,
    output logic [DATA_WIDTH-1:0]   mem_data,
    output logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
	 
	 input  logic [PC_WIDTH-1:0]     ex2_jal_result,
	 output logic [PC_WIDTH-1:0]     mem_jal_result,
	
	 input  rv32i_word               ex2_imm,
	 output rv32i_word               mem_imm,
	 
	 output logic mem_is_rtype,
	 input logic ex2_is_rtype
);
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n) begin
           mem_cs     <= '0;
			  mem_data   <= '0;
			  mem_addr   <= '0;
			  mem_wr_reg <= '0;
			  mem_jal_result <= '0;
			  mem_imm <= '0;
			  mem_is_rtype <= 1'b0;
		  end else begin
			  mem_cs     <= ex_cs;
			  mem_data   <= ex_b;
			  mem_addr   <= ex_alu_out;
			  mem_wr_reg <= ex_wr_reg;
			  mem_jal_result <= ex2_jal_result;
			  mem_imm <= ex2_imm;
			  mem_is_rtype <= ex2_is_rtype;
	     end
    end
endmodule
