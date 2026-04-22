// =============================================
// MODULE 2: ALU Phase 2 - Result Selection
// =============================================
import rv32i_types::*;

module alu_phase2 (
   // Inputs from Phase 1
   input  logic [DATA_WIDTH-1:0] phase1_add_i,
   input  logic [DATA_WIDTH-1:0] phase1_sub_i,
   input  logic [DATA_WIDTH-1:0] phase1_and_i,
   input  logic [DATA_WIDTH-1:0] phase1_or_i,
   input  logic [DATA_WIDTH-1:0] phase1_xor_i,
   input  logic [DATA_WIDTH-1:0] phase1_sll_i,
   input  logic [DATA_WIDTH-1:0] phase1_srl_i,
   input  logic                  phase1_slt_i,
   input  logic [ALUC_WIDTH-1:0] phase1_aluc_i,
   
   // Final output
   output logic [DATA_WIDTH-1:0] ex_alu_o
);
   
   // =============================================
   // MUX Selection Logic
   // =============================================
   always_comb begin
      // synthesis parallel_case full_case
      unique case (phase1_aluc_i)
         4'd0: ex_alu_o = phase1_add_i;
         4'd1: ex_alu_o = phase1_sub_i;
         4'd2: ex_alu_o = phase1_and_i;
         4'd3: ex_alu_o = phase1_or_i;
         4'd4: ex_alu_o = phase1_xor_i;
         4'd5: ex_alu_o = phase1_sll_i;
         4'd6: ex_alu_o = phase1_srl_i;
         4'd7: ex_alu_o = {{(DATA_WIDTH-1){1'b0}}, phase1_slt_i}; //slt
         default: ex_alu_o = {{(DATA_WIDTH-8){1'b0}}, phase1_add_i[7:0]}; //lbu
      endcase
   end

endmodule