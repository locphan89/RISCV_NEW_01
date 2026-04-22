import rv32i_types::*;
module memwb_pipe_reg 
  
(
    input logic                     i_clk,
    input logic                     rst_n,
	 
    // Mem side
    input wb_ctrl_unit_sig          mem_cs,
    input logic [DATA_WIDTH-1:0]    mem_rd_dmem,
    input logic [DATA_WIDTH-1:0]    mem_addr,
    input logic [R_ADDR_WIDTH-1:0]  mem_wr_reg,
	 
    // Write back side
    output wb_ctrl_unit_sig         wb_cs,
    output logic [DATA_WIDTH-1:0]   wb_rd_dmem,
    output logic [DATA_WIDTH-1:0]   wb_addr,
    output logic [R_ADDR_WIDTH-1:0] wb_wr_reg,
	 
	 output  logic [PC_WIDTH-1:0]    wb_jal_result,
	 input logic [PC_WIDTH-1:0]      mem_jal_result,
	
	 output  rv32i_word              wb_imm,
	 input rv32i_word                mem_imm
);
  
    always_ff @(posedge i_clk or negedge rst_n) begin
      if (~rst_n) begin
         wb_cs      <= '0;
			wb_rd_dmem <= '0;
         wb_addr    <= '0;
			wb_wr_reg <= '0;
			wb_jal_result <= '0;
			wb_imm <= '0;
      end else begin
         wb_cs      <= mem_cs;
			wb_rd_dmem <= mem_rd_dmem;
			wb_addr <= mem_addr;
			wb_wr_reg  <= mem_wr_reg;
			wb_jal_result <= mem_jal_result;
			wb_imm <= mem_imm;
      end
    end
endmodule
