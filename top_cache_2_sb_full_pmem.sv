import rv32i_types::*;

// ============================================================
// top_cache_2_sb_full_pmem
// Top-level wrapper: CPU + Cache + Store Buffer + Physical Memory
// Physical memory model is implemented HERE (external to CPU).
// ============================================================
module top_cache_2_sb_full_pmem #(
    parameter MEM_SIZE_KB    = 4,
    parameter LATENCY_CYCLES = 3
)(
    input  logic                   i_clk,
    input  logic                   rst_n,

    // Testbench observables
    output logic                   flush,
    output logic                   stall,
    output logic [PC_WIDTH-1:0]    if_pc,
    output logic [INST_WIDTH-1:0]  if_inst,
    output logic stall_by_cache,

    output logic [DATA_WIDTH-1:0]  wb_result
);

    // ============================================================
    // Internal signals between CPU and physical memory model
    // ============================================================
    logic                    cpu_mem_wr;
    logic                    cpu_mem_rd;

    logic                    pmem_resp;
    logic [255:0]            pmem_rdata;
    logic [31:0]             pmem_address;
    logic [255:0]            pmem_wdata;
    logic                    pmem_read;
    logic                    pmem_write;

    // ============================================================
    // CPU + Cache + Store Buffer
    // ============================================================
    top_cache_2_sb_full u_cpu (
        .i_clk,
        .rst_n,
        .cpu_mem_wr,
        .cpu_mem_rd,
        // Physical memory interface
        .pmem_resp,
        .pmem_rdata,
        .pmem_address,
        .pmem_wdata,
        .pmem_read,
        .pmem_write,
        .stall_by_cache,

        // Testbench observables
        .flush,
        .stall,
        .if_pc,
        .if_inst,
        .wb_result
    );

    // ============================================================
    // Physical Memory Model  (latency = LATENCY_CYCLES cycles)
    // ============================================================
    localparam MEM_DEPTH = (MEM_SIZE_KB * 1024) / 32; // 256-bit words

    logic [255:0] memory [MEM_DEPTH];

    logic [$clog2(LATENCY_CYCLES+1)-1:0] lat_cnt;
    logic                                 op_active;
    logic                                 pending_read;
    logic                                 pending_write;
    logic [31:0]                          pending_addr;
    logic [255:0]                         pending_wdata;
    logic                                 block_next;

    logic [31:0] mem_index;
    assign mem_index = pending_addr[31:5];

    always_ff @(posedge i_clk or negedge rst_n) begin
        if (~rst_n) begin
            lat_cnt       <= '0;
            op_active     <= 1'b0;
            pmem_resp     <= 1'b0;
            pmem_rdata    <= '0;
            pending_read  <= 1'b0;
            pending_write <= 1'b0;
            pending_addr  <= '0;
            pending_wdata <= '0;
            block_next    <= 1'b0;
        end else begin
            pmem_resp <= 1'b0;

            if (lat_cnt == '0 && block_next)
                block_next <= 1'b0;

            // New request when idle
            if ((pmem_read || pmem_write) && lat_cnt == '0 && !block_next) begin
                lat_cnt       <= LATENCY_CYCLES;
                op_active     <= 1'b1;
                pending_read  <= pmem_read;
                pending_write <= pmem_write;
                pending_addr  <= pmem_address;
                pending_wdata <= pmem_wdata;
            end
            else if (lat_cnt > '0) begin
                lat_cnt <= lat_cnt - 1;
                if (lat_cnt == 1) begin
                    pmem_resp  <= 1'b1;
                    op_active  <= 1'b0;
                    block_next <= 1'b1;
                    if (pending_write)
                        memory[mem_index] <= pending_wdata;
                    else if (pending_read)
                        pmem_rdata <= memory[mem_index];
                    pending_read  <= 1'b0;
                    pending_write <= 1'b0;
                end
            end
        end
    end

    // Memory initialisation
    initial begin
        for (int i = 0; i < MEM_DEPTH; i++)
            memory[i] = {8{32'h00000010 + i[7:0]}};
        memory[0]  = {8{32'd20}};
        memory[31] = {8{32'd35}};
    end

endmodule