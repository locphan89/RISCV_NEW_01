import rv32i_types::*;
module ifid_pipe_reg_vr_full
  
 (
   input logic                    flush_i,
   input logic                    i_clk,
   input logic                    rst_n,
    
   input logic [INST_WIDTH-1:0]   if_inst_i,
   input logic [PC_WIDTH-1:0]     if_pc_i,
   input logic [PC_WIDTH-1:0]     if_branch_addr_i,
   input ctrl_unit_sig            if_ctrl_sig_i,
	
	

   output logic [INST_WIDTH-1:0]  id_inst_o,
	
	output logic [INST_WIDTH-1:0]  id_inst_dup1_o,
	output logic [INST_WIDTH-1:0]  id_inst_dup2_o,
	
   output logic [PC_WIDTH-1:0]    id_pc_o,
   output logic [PC_WIDTH-1:0]    id_branch_addr_o,
   output ctrl_unit_sig           id_ctrl_sig_o,
	
	input  logic                   if_valid_i,
	output logic                   if_ready_o,
	
	input  logic                   id_ready_i,
	output logic                   id_valid_o,
	
	input logic                    if_is_jalr_sig,
	output logic                   id_is_jalr_sig
	
);
	assign if_ready_o = !id_valid_o || id_ready_i;
	logic  if_active;
	assign if_active = if_valid_i && if_ready_o;
	
	always_ff @(posedge i_clk or negedge rst_n) begin
		if (!rst_n) begin
			id_valid_o       <= 1'b0;
			id_inst_o        <= '0;
			id_pc_o          <= '0;
			id_branch_addr_o <= '0;
			id_ctrl_sig_o    <= '0;
			id_inst_dup1_o   <= '0;
			id_inst_dup2_o   <= '0;
			
			id_is_jalr_sig   <= '0;
		end
		else begin
			if (flush_i) begin
				id_valid_o       <= 1'b0;
				id_ctrl_sig_o    <= '0;
				id_is_jalr_sig   <= '0;
			end
			else if (if_active) begin
				id_valid_o       <= 1'b1;
			end
			// STALL → giữ nguyên
		
			if (if_active) begin
				id_inst_o        <= if_inst_i;
				id_pc_o          <= if_pc_i;
				id_branch_addr_o <= if_branch_addr_i;
				id_ctrl_sig_o    <= if_ctrl_sig_i;
				id_inst_dup1_o   <= if_inst_i;
				id_inst_dup2_o   <= if_inst_i;
				
				id_is_jalr_sig   <= if_is_jalr_sig;
			end
		end
	end


endmodule
