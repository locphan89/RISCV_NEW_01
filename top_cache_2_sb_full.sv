import rv32i_types::*;

// ============================================================
// top_cache_2_sb_full
// CPU + Store Buffer + D-Cache, with pmem_rdata as INPUT.
// Designed to be used inside top_cache_2_sb_full_pmem which
// provides the physical memory model externally.
// ============================================================
module top_cache_2_sb_full (
    input  logic                    i_clk,
    input  logic                    rst_n,

    // CPU mem direction (observable)
    output logic                    cpu_mem_wr,
    output logic                    cpu_mem_rd,
output logic stall_by_cache,

    // Physical memory interface - driven by EXTERNAL pmem model
    input  logic                    pmem_resp,
    input  logic [255:0]            pmem_rdata,
    output logic [31:0]             pmem_address,
    output logic [255:0]            pmem_wdata,
    output logic                    pmem_read,
    output logic                    pmem_write,

    // Observable outputs for testbench
    output logic                    flush,
    output logic                    stall,
    output logic [PC_WIDTH-1:0]     if_pc,
    output logic [INST_WIDTH-1:0]   if_inst,
    output logic [DATA_WIDTH-1:0]   wb_result
);

    // ============================================================
    // Internal wires (not exposed upward)
    // ============================================================
    logic                    dcache_resp;
    logic                    stall_by_cache;
    logic                    jmp_taken;
    logic                    id_branch_taken;
    logic [FW_ALU_WIDTH-1:0] fw_alu_a, fw_alu_b;
    logic [4:0]              fw_b1, fw_b2;
    logic                    stall_lw, stall_lwlw, stall_mem, stall_beq;
    logic [R_ADDR_WIDTH-1:0] id_wr_reg, id_rs1, id_rs2, idex_wr_reg;
    logic                    id_mem_wr_sig, id_jmp_sig, id_branch_sig;
    logic [R_ADDR_WIDTH-1:0] ex_wr_reg;
    logic [DATA_WIDTH-1:0]   ex_alu_a, ex_alu_b, ex_alu_out;
    logic                    ex_mem_rd;
    logic                    mem_mem_rd, mem_mem_wr;
    logic [DATA_WIDTH-1:0]   mem_addr, mem_data, mem_rdata;
    logic [R_ADDR_WIDTH-1:0] mem_wr_reg;
    logic [R_ADDR_WIDTH-1:0] wb_wr_reg;
    logic [1:0]              cache_state_out;
    logic                    cache_hit;
    rv32i_mem_wmask          mem_byte_en;

    // Store-buffer ? cache bridging
    logic [DATA_WIDTH-1:0]   cache_rdata, sb_rdata;
    logic [DATA_WIDTH-1:0]   cache_drain_addr, cache_drain_data;
    logic [3:0]              cache_drain_be;
    logic                    cache_drain_valid, cache_drain_ready;
    logic                    cache_mem_read, sb_hit, sb_ready;
    logic [DATA_WIDTH-1:0]   cache_addr;
    logic                    sb_cache_resp;

    assign sb_cache_resp     = dcache_resp || sb_hit || (mem_mem_wr & sb_ready);
    assign mem_rdata         = sb_hit ? sb_rdata : cache_rdata;
    assign cache_drain_ready = !cache_mem_read && ((~|cache_state_out) || cache_hit);
    assign cache_mem_read    = !sb_hit && mem_mem_rd;
    assign cache_addr        = cache_drain_valid ? cache_drain_addr : mem_addr;

    // ============================================================
    // CPU Pipeline
    // ============================================================
    top_5stages_cache_full top_5stages_cache_full_0 (
        .i_clk,
        .rst_n,
        .dcache_resp     (sb_cache_resp),
        .stall_by_cache,
        .cpu_mem_wr,
        .cpu_mem_rd,
        .flush,
        .jmp_taken,
        .id_branch_taken,
        .fw_alu_a,   .fw_alu_b,
        .fw_b1,      .fw_b2,
        .stall,
        .stall_lw,   .stall_lwlw,
        .stall_mem,  .stall_beq,
        .if_pc,
        .if_inst,
        .id_wr_reg,
        .id_rs1,     .id_rs2,
        .id_rsb      (/* nc */),
        .id_rtb      (/* nc */),
        .idex_wr_reg,
        .id_mem_wr_sig,
        .id_jmp_sig,
        .id_branch_sig,
        .ex_rd1      (/* nc */),
        .ex_rd2      (/* nc */),
        .ex_wr_reg,
        .ex_alu_a,   .ex_alu_b,
        .ex_alu_out,
        .ex_mem_rd,
        .mem_mem_rd, .mem_mem_wr,
        .mem_data,   .mem_addr,
        .mem_wr_reg,
        .mem_rdata,
        .mem_byte_en,
        .wb_wr_reg,
        .wb_result
    );

    // ============================================================
    // Store Buffer
    // ============================================================
    store_buffer_fix #(
        .DEPTH      (4),
        .DATA_WIDTH (DATA_WIDTH)
    ) store_buffer_0 (
        .i_clk,
        .rst_n,
        .cpu_sw_valid      (mem_mem_wr),
        .cpu_sw_addr       (mem_addr),
        .cpu_sw_data       (mem_data),
        .cpu_sw_be         (mem_byte_en),
        .cpu_sw_ready      (sb_ready),
        .cpu_lw_valid      (mem_mem_rd),
        .cpu_lw_addr       (mem_addr),
        .cache_rdata       (cache_rdata),
        .cpu_sb_hit        (sb_hit),
        .cpu_sb_rdata      (sb_rdata),
        .cache_drain_valid (cache_drain_valid),
        .cache_drain_addr  (cache_drain_addr),
        .cache_drain_data  (cache_drain_data),
        .cache_drain_be    (cache_drain_be),
        .cache_drain_ready (cache_drain_ready)
    );

    // ============================================================
    // D-Cache
    // ============================================================
    p_d_cache p_d_cache_0 (
        .i_clk,
        .rst_n,
        .pmem_resp           (pmem_resp),
        .pmem_rdata          (pmem_rdata),
        .pmem_address        (pmem_address),
        .pmem_wdata          (pmem_wdata),
        .pmem_read           (pmem_read),
        .pmem_write          (pmem_write),
        .mem_read            (cache_mem_read),
        .mem_write           (cache_drain_valid),
        .mem_byte_enable_cpu (cache_drain_be),
        .mem_address         (cache_addr),
        .mem_wdata_cpu       (cache_drain_data),
        .if_id_reg_load      (1'b1),
        .mem_resp            (dcache_resp),
        .mem_rdata_cpu       (cache_rdata),
        .cache_state_out,
        .cache_hit
    );

endmodule