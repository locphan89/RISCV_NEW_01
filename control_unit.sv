import rv32i_types::*;
module control_unit
 
(
    input  logic [OP_WIDTH-1:0]     if_op_i,
	 input  logic [FUNCT3_WIDTH-1:0] if_funct3_i,
    output ctrl_unit_sig            if_ctrl_sig_o
 );
  
always_comb begin
   if_ctrl_sig_o.mem_rd_sig    = 1'b0;
   if_ctrl_sig_o.mem2reg_sig   = 1'b0;
   if_ctrl_sig_o.reg_wr_sig    = 1'b0;
	if_ctrl_sig_o.alu_src2_sig  = 1'b0;
   if_ctrl_sig_o.alu_op_sig    = {ALUOP_WIDTH{1'b0}};
   if_ctrl_sig_o.jmp_sig       = 1'b0;
   if_ctrl_sig_o.mem_wr_sig    = 1'b0;
   if_ctrl_sig_o.branch_sig    = 1'b0;
   //if_ctrl_sig_o.reg_dst_sig   = 1'b0;
	
	if_ctrl_sig_o.pc2reg_sig    = 1'b0;
	if_ctrl_sig_o.imm2reg_sig   = 1'b0;
	
   
    case (if_op_i)
      'd0: begin // R-type, 
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
				if_ctrl_sig_o.alu_op_sig     = if_funct3_i; //*********************
       end

      'd1: begin // I-type: addi, andi, ori, xori, slli, srli, slti
            if_ctrl_sig_o.alu_src2_sig   = 1'b1;
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
            if_ctrl_sig_o.alu_op_sig     = if_funct3_i;
       end

        'd2: begin // lb, lw
				if_ctrl_sig_o.alu_src2_sig   = 1'b1;
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
            if_ctrl_sig_o.alu_op_sig     = alu_add;
				if_ctrl_sig_o.mem_rd_sig     = 1'b1;
				if_ctrl_sig_o.mem2reg_sig    = 1'b1;
        end

        'd3: begin // J-type: jal
            if_ctrl_sig_o.pc2reg_sig    = 1'b1;
				if_ctrl_sig_o.reg_wr_sig    = 1'b1;
				if_ctrl_sig_o.jmp_sig       = 1'b1;
        end

        'd4: begin // S-type: sw. sb
            if_ctrl_sig_o.mem_wr_sig    = 1'b1;
            if_ctrl_sig_o.alu_src2_sig   = 1'b1;
        end

        'd5: begin // B-type: beq, bne, blt. bgt
				if_ctrl_sig_o.branch_sig    = 1'b1;
        end

         'd6: begin // U-type: lui
				if_ctrl_sig_o.imm2reg_sig   = 1'b1;
				if_ctrl_sig_o.reg_wr_sig    = 1'b1;
        end

        default:;

    endcase
end

endmodule
