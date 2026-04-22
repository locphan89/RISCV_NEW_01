import rv32i_types::*;
module immediate_gen_full
(
    input logic [INST_WIDTH-1:0] inst,
    
    output rv32i_word            imm,
	 output rv32i_word				b_imm,
	 output rv32i_word				j_imm,
	 output rv32i_word				i_imm
);

//rv32i_word i_imm;
rv32i_word s_imm;
//rv32i_word b_imm;
rv32i_word u_imm;
//rv32i_word j_imm;
rv32i_opcode opcode;

assign i_imm = {{21{inst[31]}}, inst[30:20]};
assign s_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign b_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign u_imm = {inst[31:12], 12'h000};
assign j_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

assign opcode = rv32i_opcode'(inst[6:0]);

always_comb begin

    imm = '0; // set to 0 for debugging

    unique case(opcode)

        op_utype: 
        begin
            imm = u_imm;
        end

        op_jtype: 
        begin
            imm = j_imm;
        end

        op_load: 
        begin
            imm = i_imm;
        end

        op_stype:
        begin
            imm = s_imm;
        end

        op_imm: 
        begin
            imm = i_imm;
        end

        default:
        begin
            
            // $display("%0b", opcode);
        end 
    endcase

end


endmodule : immediate_gen_full