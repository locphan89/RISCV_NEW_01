import rv32i_types::*;

module alu_full (
   input  logic [DATA_WIDTH-1:0] ex_a_i,
   input  logic [DATA_WIDTH-1:0] ex_b_i,
   input  logic [9:0]            ex_aluc_i,
   output logic [DATA_WIDTH-1:0] ex_alu_o
);

   // =============================================
   // Pre-compute datapath
   // =============================================
   logic [DATA_WIDTH-1:0] alu_add;
   logic [DATA_WIDTH-1:0] alu_sub;

   assign alu_add = ex_a_i + ex_b_i;
   assign alu_sub = ex_a_i - ex_b_i;

   // =============================================
   // SLT (signed) — correct with overflow fix
   // =============================================
   logic overflow;
   logic slt_signed;

   assign overflow   = (ex_a_i[31] ^ ex_b_i[31]) & (ex_a_i[31] ^ alu_sub[31]);
   assign slt_signed = alu_sub[31] ^ overflow;

   // =============================================
   // SLTU (unsigned)
   // =============================================
   logic slt_unsigned;
   assign slt_unsigned = (ex_a_i < ex_b_i);

   // =============================================
   // Shift operations
   // =============================================
   logic [DATA_WIDTH-1:0] sll, srl, sra;

   assign sll = ex_a_i << ex_b_i[4:0];
   assign srl = ex_a_i >> ex_b_i[4:0];
   assign sra = $signed(ex_a_i) >>> ex_b_i[4:0];

   // =============================================
   // Final output (one-hot OR-combine)
   // =============================================
   assign ex_alu_o =
        ({DATA_WIDTH{ex_aluc_i[0]}} & alu_add) |
        ({DATA_WIDTH{ex_aluc_i[1]}} & alu_sub) |
        ({DATA_WIDTH{ex_aluc_i[2]}} & (ex_a_i & ex_b_i)) |
        ({DATA_WIDTH{ex_aluc_i[3]}} & (ex_a_i | ex_b_i)) |
        ({DATA_WIDTH{ex_aluc_i[4]}} & (ex_a_i ^ ex_b_i)) |
        ({DATA_WIDTH{ex_aluc_i[5]}} & sll) |
        ({DATA_WIDTH{ex_aluc_i[6]}} & srl) |
        ({DATA_WIDTH{ex_aluc_i[7]}} & {{31{1'b0}}, slt_signed}) |
        ({DATA_WIDTH{ex_aluc_i[8]}} & {{31{1'b0}}, slt_unsigned}) |
        ({DATA_WIDTH{ex_aluc_i[9]}} & sra);


endmodule