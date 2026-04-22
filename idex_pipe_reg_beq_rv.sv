import rv32i_types::*;
module idex_pipe_reg_beq_rv 
  
(
   input logic                     i_clk,
   input logic                     rst_n,
	input logic                     ex_flush,
	
   // Decide side
   input ex_ctrl_unit_sig          id_cs,
   input logic [DATA_WIDTH-1:0]    id_rd1,
   input logic [DATA_WIDTH-1:0]    id_rd2,
   input logic [DATA_WIDTH-1:0]    id_imm,
   input logic [R_ADDR_WIDTH-1:0]  id_wr_reg,
   input logic [FUNCT3_WIDTH-1:0]  id_funct3,
	input logic [PC_WIDTH-1:0]      id_branch_addr,
	input logic                     id_branch_taken,
	
	input logic [PC_WIDTH-1:0]      id_jal_result,
	
	//input logic [R_ADDR_WIDTH-1:0]  id_rs,
	//input logic [R_ADDR_WIDTH-1:0]  id_rt,
    
   // Execute side 
   output ex_ctrl_unit_sig         ex_cs,
   output logic [DATA_WIDTH-1:0]   ex_rd1,
   output logic [DATA_WIDTH-1:0]   ex_rd2,
   output logic [DATA_WIDTH-1:0]   ex_imm,
   output logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
   output logic [FUNCT3_WIDTH-1:0] ex_funct3,
	output logic [PC_WIDTH-1:0]     ex_branch_addr,
	output logic                    ex1_branch_taken,
	
	output logic [PC_WIDTH-1:0]     ex_jal_result,
	
	input logic                     id_is_rtype,
	output logic                    ex1_is_rtype,
	
	
	// Handshake
	input  logic                    id_hazard,
	//input  logic                    nxt_id_hazard,
	
	input  logic                    id_valid_i,
	input logic                     id_ready_i,
	
	output logic                    ex1_valid_o
	
	
);
	logic id_active;
	assign id_active = id_valid_i & id_ready_i;
	
	//assign id_ready_o = (~id_hazard || (id_hazard && ~nxt_id_hazard));
	//assign id_ready_o = ~id_hazard || ();
	
   always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n) begin
           ex_cs            <= '0;
           ex_rd1           <= '0;
			  ex_rd2           <= '0;
	        ex_imm           <= '0;
	        ex_wr_reg        <= '0;
	        ex_funct3          <= '0;
			  ex_branch_addr   <= '0;
			  //ex_rs            <= '0;
			  //ex_rt            <= '0;
			  ex1_branch_taken <= '0;
			  ex1_valid_o      <= 1'b0;
			  
			  ex_jal_result    <= '0;
			  ex1_is_rtype <= 1'b0;
		  end else begin
			  if (ex_flush) begin
					ex1_valid_o <= '0;
			  end
			  else if (id_active) begin
					ex1_valid_o <= 1'b1;
		     end
			  if (id_active) begin
					ex_rd1           <= id_rd1;
					ex_rd2           <= id_rd2;
					ex_imm           <= id_imm;
					ex_funct3          <= id_funct3;
					ex_branch_addr   <= id_branch_addr;
					//ex_rs            <= id_rs;
					//ex_rt            <= id_rt;
					ex1_branch_taken <= id_branch_taken;
					ex_jal_result    <= id_jal_result;
					
					ex_wr_reg <= id_wr_reg;
			  end
			  
			  if (id_active) begin
					ex_cs     <= id_cs;
					//ex_wr_reg <= id_wr_reg;
					ex1_is_rtype <= id_is_rtype;
				end else if (id_hazard) begin
					ex_cs     <= '0;
				   //ex_wr_reg <= '0;
					ex1_is_rtype <= 1'b0;
				end

		 end
	end
endmodule
