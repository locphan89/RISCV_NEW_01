import rv32i_types::*;

module alu_ctrl(
   input  logic [ALUOP_WIDTH-1:0] id_alu_op_sig_i,
   input  logic [FUNCT3_WIDTH-1:0] id_funct3_i,   // s?a FUNCT_WIDTH ? FUNCT3_WIDTH
   input  logic [OP_WIDTH-1:0]    id_op_i,
   output logic [ALUC_WIDTH-1:0]  id_aluc_o
);

always_comb begin
    case (id_alu_op_sig_i)

        // R-type
        'd0: begin
            id_aluc_o = ALUC_WIDTH'(id_funct3_i);
        end

        // I-type / load / store
        'd1: begin
            case (id_op_i)
                op_imm:  id_aluc_o = 'd0;  // addi
                op_load: id_aluc_o = 'd0;  // lw
                op_stype:id_aluc_o = 'd0;  // sw
                default: id_aluc_o = 'd10;
            endcase
        end

        // ANDI
        'd2: id_aluc_o = 'd2;

        // ORI
        'd3: id_aluc_o = 'd3;

        // shift (ví d?)
        'd4: id_aluc_o = 'd7;

        default: id_aluc_o = 'd10;

    endcase
end

endmodule