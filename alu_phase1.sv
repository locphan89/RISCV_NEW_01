// =============================================
// MODULE 1: ALU Phase 1 - Arithmetic Operations
// =============================================
import rv32i_types::*;

module alu_phase1 (
   input  logic                  clk,
   input  logic                  rst_n,
   input  logic [DATA_WIDTH-1:0] ex_a_i,
   input  logic [DATA_WIDTH-1:0] ex_b_i,
   input  logic [ALUC_WIDTH-1:0] ex_aluc_i,
   
   // Outputs to Phase 2
   output logic [DATA_WIDTH-1:0] phase1_add_o,
   output logic [DATA_WIDTH-1:0] phase1_sub_o,
   output logic [DATA_WIDTH-1:0] phase1_and_o,
   output logic [DATA_WIDTH-1:0] phase1_or_o,
   output logic [DATA_WIDTH-1:0] phase1_xor_o,
   output logic [DATA_WIDTH-1:0] phase1_sll_o,
   output logic [DATA_WIDTH-1:0] phase1_srl_o,
   output logic                  phase1_slt_o,
   output logic [ALUC_WIDTH-1:0] phase1_aluc_o
);
   
   // =============================================
   // Combinational Operations (parallel)
   // =============================================
   logic [DATA_WIDTH-1:0] alu_add;
   logic [DATA_WIDTH-1:0] alu_sub;
   logic [DATA_WIDTH-1:0] alu_and;
   logic [DATA_WIDTH-1:0] alu_or;
   logic [DATA_WIDTH-1:0] alu_xor;
   logic [DATA_WIDTH-1:0] alu_sll;
   logic [DATA_WIDTH-1:0] alu_srl;
   logic                  slt_result;
   
   assign alu_add = ex_a_i + ex_b_i;
   assign alu_sub = ex_a_i - ex_b_i;
   assign alu_and = ex_a_i & ex_b_i;
   assign alu_or  = ex_a_i | ex_b_i;
   assign alu_xor = ex_a_i ^ ex_b_i;
   assign alu_sll = ex_a_i << ex_b_i[4:0];
   assign alu_srl = ex_a_i >> ex_b_i[4:0];
   assign slt_result = alu_sub[DATA_WIDTH-1];  // Sign bit for SLT
   
   // =============================================
   // Pipeline Register
   // =============================================
   always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         phase1_add_o  <= '0;
         phase1_sub_o  <= '0;
         phase1_and_o  <= '0;
         phase1_or_o   <= '0;
         phase1_xor_o  <= '0;
         phase1_sll_o  <= '0;
         phase1_srl_o  <= '0;
         phase1_slt_o  <= '0;
         phase1_aluc_o <= '0;
      end else begin
         phase1_add_o  <= alu_add;
         phase1_sub_o  <= alu_sub;
         phase1_and_o  <= alu_and;
         phase1_or_o   <= alu_or;
         phase1_xor_o  <= alu_xor;
         phase1_sll_o  <= alu_sll;
         phase1_srl_o  <= alu_srl;
         phase1_slt_o  <= slt_result;
         phase1_aluc_o <= ex_aluc_i;
      end
   end

endmodule