import rv32i_types::*;
module control_unit_std_full
 
(
    input  logic [OP_WIDTH-1:0]     if_op_i,
	 input  logic [FUNCT3_WIDTH-1:0] if_funct3_i,
	 input  logic                    if_funct7_i,
    output ctrl_unit_sig            if_ctrl_sig_o,
	 
	 output logic                    is_jalr_sig
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
	
	is_jalr_sig                 = 1'b0;
	 
    case (if_op_i)
      op_rtype: begin // R-type, 
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
				unique case (if_funct3_i)
                3'b000: // add / sub
					 begin
					    if (if_funct7_i) begin
                       if_ctrl_sig_o.alu_op_sig = alu_sub;
                   end
						 else begin
						     if_ctrl_sig_o.alu_op_sig = alu_add;
					    end
					 end
					 
                3'b111: // and
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_and;
                end
                3'b110: // or
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_or;
                end
                3'b100: // xor
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_xor;
                end
                3'b001: // sll
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_sll;
                end
					 3'b101: // srl / sra
					 begin
					    if (if_funct7_i) begin
                       if_ctrl_sig_o.alu_op_sig = alu_sra;  // sra
                   end
						 else begin
						     if_ctrl_sig_o.alu_op_sig = alu_srl; // srl
						 end
					 end
					 3'b010: // slt
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_slt;
					 end
					 3'b011: // sltu
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_sltu;
					 end
                default: if_ctrl_sig_o.alu_op_sig = alu_add;
            endcase
       end

      op_imm: begin // I-type: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
            if_ctrl_sig_o.alu_src2_sig   = 1'b1;
            if_ctrl_sig_o.reg_wr_sig     = 1'b1;
				unique case (if_funct3_i)
                3'b000: // addi
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_add;
                end
                3'b111: // andi
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_and;
                end
                3'b110: // ori
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_or;
                end
                3'b100: // xori
                begin
                   if_ctrl_sig_o.alu_op_sig = alu_xor;
                end
                3'b001: // slli
                begin
                    if_ctrl_sig_o.alu_op_sig = alu_sll;
                end
					 3'b101: // srli / srai
					 begin
					    if (if_funct7_i) begin
                       if_ctrl_sig_o.alu_op_sig = alu_sra;  // srai
                   end
						 else begin
						     if_ctrl_sig_o.alu_op_sig = alu_srl; // srli
						 end
					 end
					 3'b010: // slti
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_slt;
					 end
					 3'b011: // sltiu
					 begin
						  if_ctrl_sig_o.alu_op_sig = alu_sltu;
					 end
                default: if_ctrl_sig_o.alu_op_sig = alu_add;
            endcase
       end
		 
		 op_jalr: begin //jalr
		      if_ctrl_sig_o.pc2reg_sig    = 1'b1;
				if_ctrl_sig_o.reg_wr_sig    = 1'b1;
				is_jalr_sig                 = 1'b1;
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