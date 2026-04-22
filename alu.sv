
import rv32i_types::*;
module alu (
   input  logic [DATA_WIDTH-1:0] ex_a_i,
   input  logic [DATA_WIDTH-1:0] ex_b_i,
   input  logic [ALUC_WIDTH-1:0] ex_aluc_i,
   output logic [DATA_WIDTH-1:0] ex_alu_o
);
   
   // Pre-compute both operations
   logic [DATA_WIDTH-1:0] alu_add;
   logic [DATA_WIDTH-1:0] alu_sub;
   logic                  slt_result;
   
   assign alu_add = ex_a_i + ex_b_i;
   assign alu_sub = ex_a_i - ex_b_i;
   
   // =============================================
   // Fast SLT using subtraction result
   // =============================================
   // For signed comparison: check MSB of (A - B)
   // If A < B (signed), then (A - B) is negative → MSB = 1
   assign slt_result = alu_sub[DATA_WIDTH-1];  // Sign bit
	
	always_comb begin
   // synthesis parallel_case full_case
   unique case (ex_aluc_i)
      alu_sub: ex_alu_o = alu_sub;
      alu_and: ex_alu_o = ex_a_i & ex_b_i;
      alu_or: ex_alu_o = ex_a_i | ex_b_i;
      alu_xor: ex_alu_o = ex_a_i ^ ex_b_i;
      alu_sll: ex_alu_o = ex_a_i << ex_b_i[4:0];
      alu_srl: ex_alu_o = ex_a_i >> ex_b_i[4:0];
      alu_slt: ex_alu_o = {{(DATA_WIDTH-1){1'b0}}, slt_result};
      default: ex_alu_o = alu_add;
   endcase
end

endmodule

