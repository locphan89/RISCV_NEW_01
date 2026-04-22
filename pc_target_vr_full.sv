import rv32i_types::*;

module pc_target_vr_full (
    input  logic                  i_clk,
    input  logic                  rst_n,

    // Sequential next PC
    input  logic [PC_WIDTH-1:0]   if_pc_plus,

    // Branch / jump targets
    input  logic [PC_WIDTH-1:0]   ex_branch_addr,
    input  logic [PC_WIDTH-1:0]   id_jmp_addr,
    input  logic [PC_WIDTH-1:0]   id_jalr_addr,

    // Control flags (all 1-bit)
    input  logic                  ex_branch_taken,
    input  logic                  id_jmp_taken,
    input  logic                  id_jalr_taken,   // BUG FIX: original was [PC_WIDTH-1:0]

    // Handshake
    input  logic                  if_ready,

    // Output
    output logic [PC_WIDTH-1:0]   if_pc
);

    // ================================================================
    // PC register
    // Priority (highest ? lowest):
    //   1. JAL   (id_jmp_taken)
    //   2. JALR  (id_jalr_taken)
    //   3. Branch taken (ex_branch_taken)
    //   4. PC + 1 sequential (if_ready)
    //   If none ? PC holds (stall)
    // ================================================================
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n) begin
            if_pc <= '0;
        end else begin
            if (id_jmp_taken)
                if_pc <= id_jmp_addr;
            else if (id_jalr_taken)
                if_pc <= id_jalr_addr;
            else if (ex_branch_taken)
                if_pc <= ex_branch_addr;
            else if (if_ready)
                if_pc <= if_pc_plus;
            // else if_ready = 0: PC gi? nguyên (stall)
        end
    end

endmodule