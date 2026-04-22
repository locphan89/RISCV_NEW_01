import rv32i_types::*;
module control_unit_std
 
(
    input  logic [OP_WIDTH-1:0]     if_op_i,
	 input  logic [FUNCT3_WIDTH-1:0] if_funct3_i,
	 input  logic                    if_funct7_i,
    output ctrl_unit_sig            if_ctrl_sig_o
 );

always_comb begin
   if_ctrl_sig_o.mem_rd_sig    = 1'b0;
   if_ctrl_sig_o.mem2reg_sig   = 1'b0;
   if_ctrl_sig_o.reg_wr_sig    = 1'b0;
	if_ctrl_sig_o.alu_src2_sig  = 1'b0;
   if_ctrl_sig_o.alu_op_sig    = alu_ops'(1'b1);
   if_ctrl_sig_o.jmp_sig       = 1'b0;
   if_ctrl_sig_o.mem_wr_sig    = 1'b0;
   if_ctrl_sig_o.branch_sig    = 1'b0;
   //if_ctrl_sig_o.reg_dst_sig   = 1'b0;
	
	if_ctrl_sig_o.pc2reg_sig    = 1'b0;
	if_ctrl_sig_o.imm2reg_sig   = 1'b0;
	 
    case (if_op_i)
      op_rtype: begin // R-type, 
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
				//if_ctrl_sig_o.alu_op_sig     = if_funct3_i;
				unique case (if_funct3_i)
                add:
					 begin
					    if (if_funct7_i) begin
                       if_ctrl_sig_o.alu_op_sig = alu_sub;
                   end
						 else begin
						     if_ctrl_sig_o.alu_op_sig = alu_add;
					    end
					 end
					 
                aand : 
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_and;
                end
                aor :
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_or;
                end
                axor : 
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_xor;
                end

                sll :
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_sll;
                end
					 
					 srl :
					 begin
					 //if (if_funct7_i) begin
                       // if_ctrl_sig_o.alu_op_sig = alu_sra;
                  // end
						// else begin
						     if_ctrl_sig_o.alu_op_sig = alu_srl;
					   // end
					 end
					 
					 slt :
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_slt;
					 end
            endcase
       end

      op_imm: begin // I-type: addi, andi, ori, xori, slli, srli, slti
            if_ctrl_sig_o.alu_src2_sig   = 1'b1;
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
            //if_ctrl_sig_o.alu_op_sig     = if_funct3_i;
				unique case (if_funct3_i)
                add:
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_add;
                end
                aand : 
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_and;
                end
                aor :
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_or;
                end
                axor : 
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_xor;
                end

                sll :
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_sll;
                end
					 
					 srl :
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_srl;
					 end
					 
					 slt :
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_slt;
					 end
            endcase
       end

        op_load: begin // lb, lw
				if_ctrl_sig_o.alu_src2_sig   = 1'b1;
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
            if_ctrl_sig_o.alu_op_sig     = alu_add;
				if_ctrl_sig_o.mem_rd_sig     = 1'b1;
				if_ctrl_sig_o.mem2reg_sig    = 1'b1;
        end

        op_jtype: begin // J-type: jal
            if_ctrl_sig_o.pc2reg_sig    = 1'b1;
				if_ctrl_sig_o.reg_wr_sig    = 1'b1;
				if_ctrl_sig_o.jmp_sig       = 1'b1;
        end

        op_stype: begin // S-type: sw. sb
            if_ctrl_sig_o.mem_wr_sig    = 1'b1;
            if_ctrl_sig_o.alu_src2_sig   = 1'b1;
        end

        op_btype: begin // B-type: beq, bne, blt. bgt
				if_ctrl_sig_o.branch_sig    = 1'b1;
        end

         op_utype: begin // U-type: lui
				if_ctrl_sig_o.imm2reg_sig   = 1'b1;
				if_ctrl_sig_o.reg_wr_sig    = 1'b1;
        end

        default:;

    endcase
end

endmodule
