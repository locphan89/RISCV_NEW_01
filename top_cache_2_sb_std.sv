// =============================================================================
//  top_cache_2_sb_std.sv  -  FIXED v2
//
//  Key fixes vs original:
//  1. stall_by_cache does NOT stall on sb_hit (store-buffer hit is 1-cycle)
//  2. Store buffer receives correct per-byte enable (mem_byte_en from mask_gen)
//  3. SB forwarding: returns the FULL cache-line word aligned to the load addr;
//     byte/half sign-extension is done in the WB stage of top_5stages_cache_full.
//     The SB must forward the 4-byte word at the cache-line word that contains
//     the stored bytes, merged into the correct positions, so the WB shift-
//     extract logic works correctly.
//  4. JALR return-address (x22): the "round-trip" test stores PC+1 into rd via
//     pc2reg_sig; this already works in top_5stages_cache_full. No change needed
//     in the top-level for this - the fix in the SB forwarding resolves it
//     indirectly (no spurious stalls corrupting the pipeline).
// =============================================================================
import rv32i_types::*;

module top_cache_2_sb_std #(
    parameter MEM_SIZE_KB    = 4,
    parameter LATENCY_CYCLES = 3
)(
    input  logic                     i_clk,
    input  logic                     rst_n,

    // ---- Cache / stall ----
    output logic                     dcache_resp,
    output logic                     stall_by_cache,
    output logic                     cpu_mem_wr,
    output logic                     cpu_mem_rd,

    // ---- Control ----
    output logic                     flush,
    output logic                     jmp_taken,
    output logic                     id_branch_taken,
    output logic [FW_ALU_WIDTH-1:0]  fw_alu_a,
    output logic [FW_ALU_WIDTH-1:0]  fw_alu_b,
    output logic [4:0]               fw_b1,
    output logic [4:0]               fw_b2,

    // ---- Stall ----
    output logic                     stall,
    output logic                     stall_lw,
    output logic                     stall_lwlw,
    output logic                     stall_mem,
    output logic                     stall_beq,

    // ---- IF ----
    output logic [PC_WIDTH-1:0]      if_pc,
    output logic [INST_WIDTH-1:0]    if_inst,

    // ---- ID ----
    output logic [R_ADDR_WIDTH-1:0]  id_wr_reg,
    output logic [R_ADDR_WIDTH-1:0]  id_rs1,
    output logic [R_ADDR_WIDTH-1:0]  id_rs2,
    output logic [R_ADDR_WIDTH-1:0]  idex_wr_reg,
    output logic                     id_mem_wr_sig,
    output logic                     id_jmp_sig,
    output logic                     id_branch_sig,

    // ---- EX ----
    output logic [R_ADDR_WIDTH-1:0]  ex_wr_reg,
    output logic [DATA_WIDTH-1:0]    ex_alu_a,
    output logic [DATA_WIDTH-1:0]    ex_alu_b,
    output logic [DATA_WIDTH-1:0]    ex_alu_out,
    output logic                     ex_mem_rd,

    // ---- MEM ----
    output logic                     mem_mem_rd,
    output logic                     mem_mem_wr,
    output logic [DATA_WIDTH-1:0]    mem_addr,
    output logic [DATA_WIDTH-1:0]    mem_data,
    output logic [R_ADDR_WIDTH-1:0]  mem_wr_reg,
    output logic [DATA_WIDTH-1:0]    mem_rdata,

    // ---- WB ----
    output logic [R_ADDR_WIDTH-1:0]  wb_wr_reg,
    output logic [DATA_WIDTH-1:0]    wb_result,

    // ---- Physical memory (observable) ----
    output logic                     pmem_resp,
    output logic [31:0]              pmem_address,
    output logic                     pmem_read,
    output logic                     pmem_write,

    // ---- Debug ----
    output logic [1:0]               cache_state_out,
    output logic                     cache_hit,
    output logic                     sb_cache_resp,
    output logic                     sb_hit,
    output logic                     sb_ready,
    output logic                     cache_mem_read,
    output logic                     cache_drain_ready,
    output logic                     cache_drain_valid,
    output rv32i_mem_wmask           mem_byte_en
);

    // ==================================================================
    // Physical-memory model (integrated)
    // ==================================================================
    logic [255:0] pmem_rdata;
    logic [255:0] pmem_wdata;

    localparam CNT_W     = $clog2(LATENCY_CYCLES + 1);
    localparam MEM_DEPTH = (MEM_SIZE_KB * 1024) / 32;

    logic [CNT_W-1:0] latency_counter_reg;
    logic             operation_active;
    logic             will_resp_next_cycle;
    logic             pending_read_r, pending_write_r;
    logic [31:0]      pending_address_r;
    logic [255:0]     pending_wdata_r;
    logic [31:0]      mem_index_r;

    // Testbench accesses dut.memory[] directly
    logic [255:0] memory [MEM_DEPTH];

    assign mem_index_r = pending_address_r[31:5];

    logic [CNT_W-1:0] latency_counter;
    always_comb begin
        if ((pmem_read || pmem_write)
                && latency_counter_reg == '0
                && !will_resp_next_cycle)
            latency_counter = CNT_W'(LATENCY_CYCLES);
        else
            latency_counter = latency_counter_reg;
    end

    always_ff @(posedge i_clk or negedge rst_n) begin
        if (~rst_n) begin
            latency_counter_reg  <= '0;
            operation_active     <= 1'b0;
            pmem_resp            <= 1'b0;
            pmem_rdata           <= '0;
            pending_read_r       <= 1'b0;
            pending_write_r      <= 1'b0;
            pending_address_r    <= '0;
            pending_wdata_r      <= '0;
            will_resp_next_cycle <= 1'b0;
        end else begin
            pmem_resp <= 1'b0;

            if (latency_counter_reg == '0 && will_resp_next_cycle)
                will_resp_next_cycle <= 1'b0;

            if ((pmem_read || pmem_write)
                    && latency_counter_reg == '0
                    && !will_resp_next_cycle) begin
                latency_counter_reg <= CNT_W'(LATENCY_CYCLES);
                operation_active    <= 1'b1;
                pending_read_r      <= pmem_read;
                pending_write_r     <= pmem_write;
                pending_address_r   <= pmem_address;
                pending_wdata_r     <= pmem_wdata;
            end else if (latency_counter_reg > '0) begin
                latency_counter_reg <= latency_counter_reg - 1'b1;
                if (latency_counter_reg == 1) begin
                    pmem_resp            <= 1'b1;
                    operation_active     <= 1'b0;
                    will_resp_next_cycle <= 1'b1;
                    if (pending_write_r)
                        memory[mem_index_r] <= pending_wdata_r;
                    else if (pending_read_r)
                        pmem_rdata <= memory[mem_index_r];
                    pending_read_r  <= 1'b0;
                    pending_write_r <= 1'b0;
                end
            end
        end
    end

    initial begin
        for (int i = 0; i < MEM_DEPTH; i++)
            memory[i] = '0;
    end

    // ==================================================================
    // Internal wires
    // ==================================================================
    logic [DATA_WIDTH-1:0] cache_rdata_w;
    logic [DATA_WIDTH-1:0] sb_rdata_w;
    logic [DATA_WIDTH-1:0] drain_addr_w;
    logic [DATA_WIDTH-1:0] drain_data_w;
    logic [3:0]            drain_be_w;
    logic [DATA_WIDTH-1:0] id_rsb_w, id_rtb_w;
    logic [DATA_WIDTH-1:0] cache_addr_w;

    // ==================================================================
    // FIX 1: stall_by_cache must NOT stall when sb_hit
    // When the store buffer has the data, the load completes in 1 cycle
    // (sb_rdata_w is available combinationally). Only stall on real
    // cache misses, i.e. when the cache is busy and SB has no hit.
    //
    // The pipeline's own stall_by_cache comes from top_5stages_cache_full:
    //   stall_by_cache = ~dcache_resp & (mem_rd | mem_wr)
    // We need to override this by feeding sb_cache_resp as dcache_resp.
    // sb_cache_resp = dcache_resp | sb_hit | (mem_wr & sb_ready)
    // This already satisfies stores (sb_ready=1 ? no stall for SW).
    // For loads: sb_hit=1 ? sb_cache_resp=1 ? dcache_resp seen as 1 ? no stall. ?
    // ==================================================================
    assign sb_cache_resp   = dcache_resp | sb_hit | (mem_mem_wr & sb_ready);

    // FIX 2: cache reads only when SB has no hit (avoid redundant cache access)
    assign cache_mem_read  = !sb_hit && mem_mem_rd;

    // Drain ready: can drain from SB to cache when cache is idle or in HIT state
    // and not currently busy with a CPU load
    assign cache_drain_ready = !cache_mem_read
                               && ((~|cache_state_out) || cache_hit);

    assign cache_addr_w    = cache_drain_valid ? drain_addr_w : mem_addr;

    // FIX 3: mem_rdata mux - SB hit takes priority
    assign mem_rdata = sb_hit ? sb_rdata_w : cache_rdata_w;

    // ==================================================================
    // Pipeline: top_5stages_cache_full
    // (provides lb/lbu/lh/lhu, sra, sltu, bltu, bgeu, jalr)
    // ==================================================================
    top_5stages_cache_full top_5stages_cache_full_0 (
        .i_clk,
        .rst_n,
        // FIX: feed sb_cache_resp so pipeline sees "done" when SB hits
        .dcache_resp    (sb_cache_resp),
        .stall_by_cache,
        .cpu_mem_wr,
        .cpu_mem_rd,
        .flush,
        .jmp_taken,
        .id_branch_taken,
        .fw_alu_a,
        .fw_alu_b,
        .fw_b1,
        .fw_b2,
        .stall,
        .stall_lw,
        .stall_lwlw,
        .stall_mem,
        .stall_beq,
        .if_pc,
        .if_inst,
        .id_wr_reg,
        .id_rs1,
        .id_rs2,
        .id_rsb  (id_rsb_w),
        .id_rtb  (id_rtb_w),
        .idex_wr_reg,
        .id_mem_wr_sig,
        .id_jmp_sig,
        .id_branch_sig,
        .ex_rd1  (),
        .ex_rd2  (),
        .ex_wr_reg,
        .ex_alu_a,
        .ex_alu_b,
        .ex_alu_out,
        .ex_mem_rd,
        .mem_mem_rd,
        .mem_mem_wr,
        .mem_addr,
        .mem_data,
        .mem_wr_reg,
        .mem_rdata,
        .mem_byte_en,
        .wb_wr_reg,
        .wb_result
    );

    // ==================================================================
    // Store buffer
    // FIX 4: pass mem_byte_en (from mask_gen) so SB stores correct bytes
    // FIX 5: SB forwarding must merge bytes at correct word position so
    //         the WB shift+sign-extend logic in top_5stages_cache_full works.
    //         The store_buffer module already does byte-granule forwarding:
    //         it merges stored bytes into `merged` (initialized from cache_rdata),
    //         so sb_rdata_w contains the correctly merged word at [31:0].
    //         The WB stage then does: shifted = sb_rdata_w >> (offset*8)
    //         followed by sign/zero extension - this works correctly.
    // ==================================================================
    store_buffer #(
        .DEPTH (4)
    ) store_buffer_0 (
        .i_clk,
        .rst_n,
        // CPU store
        .cpu_sw_valid    (mem_mem_wr),
        .cpu_sw_addr     (mem_addr),
        .cpu_sw_data     (mem_data),
        .cpu_sw_be       (mem_byte_en),   // FIX: real byte-enable from mask_gen
        .cpu_sw_ready    (sb_ready),
        // CPU load - forward from SB into a full 32-bit word
        .cpu_lw_valid    (mem_mem_rd),
        .cpu_lw_addr     (mem_addr),
        .cache_rdata     (cache_rdata_w),
        .cpu_sb_hit      (sb_hit),
        .cpu_sb_rdata    (sb_rdata_w),
        // Drain to D-cache
        .cache_drain_valid,
        .cache_drain_addr   (drain_addr_w),
        .cache_drain_data   (drain_data_w),
        .cache_drain_be     (drain_be_w),
        .cache_drain_ready
    );

    // ==================================================================
    // D-cache (p_d_cache)
    // ==================================================================
    p_d_cache p_d_cache_0 (
        .i_clk,
        .rst_n,
        // Physical memory
        .pmem_resp,
        .pmem_rdata,
        .pmem_address,
        .pmem_wdata,
        .pmem_read,
        .pmem_write,
        // CPU-side
        .mem_read            (cache_mem_read),
        .mem_write           (cache_drain_valid),
        .mem_byte_enable_cpu (drain_be_w),
        .mem_address         (cache_addr_w),
        .mem_wdata_cpu       (drain_data_w),
        .if_id_reg_load      (1'b1),
        .mem_resp            (dcache_resp),
        .mem_rdata_cpu       (cache_rdata_w),
        .cache_state_out,
        .cache_hit
    );

endmodule