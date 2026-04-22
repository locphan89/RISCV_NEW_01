// =============================================================================
// store_buffer_fix.sv  -- FIXED v3
//
// ROOT CAUSE FIX (normalize_data):
//   For RISC-V sb/sh/sw, the CPU always puts the value in the LOWEST byte
//   lanes of mem_data:
//     sb: value in data[7:0],  mask_gen gives be with exactly ONE bit set
//     sh: value in data[15:0], mask_gen gives be with exactly TWO bits set
//     sw: value in data[31:0], be = 4'b1111
//
//   The original normalize_data did:  n[8*b:] = data[8*b:]  for each set bit b.
//   This is WRONG for sb/sh because data's useful bytes are in the LOWEST
//   lanes (b=0 for sb, b=0..1 for sh) but we must store them in lane b.
//
//   FIX: shift data left by (lo * 8), where lo = index of lowest set bit in be.
//   This moves data[7:0] -> data[8*lo : 8*(lo+1)] before masking and storing,
//   so the forwarding merge picks up the correct byte in each lane.
//
// Example:
//   sb x1(=0x82), 1(x5)  -> data=0x00000082, be=0b0010, lo=1
//   OLD: n[15:8] = data[15:8] = 0x00       WRONG
//   NEW: shifted = 0x00000082 << 8 = 0x00008200; n[15:8] = 0x82  CORRECT
// =============================================================================
module store_buffer_fix #(
    parameter DEPTH      = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                   i_clk,
    input  logic                   rst_n,

    // ===== CPU STORE =====
    input  logic                   cpu_sw_valid,
    input  logic [DATA_WIDTH-1:0]  cpu_sw_addr,
    input  logic [DATA_WIDTH-1:0]  cpu_sw_data,
    input  logic [3:0]             cpu_sw_be,
    output logic                   cpu_sw_ready,

    // ===== CPU LOAD (forwarding) =====
    input  logic                   cpu_lw_valid,
    input  logic [DATA_WIDTH-1:0]  cpu_lw_addr,
    input  logic [DATA_WIDTH-1:0]  cache_rdata,
    output logic                   cpu_sb_hit,
    output logic [DATA_WIDTH-1:0]  cpu_sb_rdata,

    // ===== Drain to cache =====
    output logic                   cache_drain_valid,
    output logic [DATA_WIDTH-1:0]  cache_drain_addr,
    output logic [DATA_WIDTH-1:0]  cache_drain_data,
    output logic [3:0]             cache_drain_be,
    input  logic                   cache_drain_ready
);

    localparam PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;

    // -------------------------------------------------------
    // Internal FIFO storage
    // -------------------------------------------------------
    logic                  buf_valid [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] buf_addr  [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] buf_data  [0:DEPTH-1];  // normalized: byte in correct lane
    logic [3:0]            buf_be    [0:DEPTH-1];

    logic [PTR_W-1:0]  head, tail;
    logic [PTR_W:0]    count;
    logic              sb_full;
    logic              do_pop, do_push;

    // Pop is registered (cache_drain_ready from cache has 1-cycle latency)
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n)  do_pop <= 1'b0;
        else         do_pop <= cache_drain_valid & cache_drain_ready;
    end

    // -------------------------------------------------------
    // Full / Ready
    // -------------------------------------------------------
    assign sb_full      = count[PTR_W];   // count == DEPTH
    assign cpu_sw_ready = !sb_full | do_pop;
    assign do_push      = cpu_sw_valid & cpu_sw_ready;

    // -------------------------------------------------------
    // FIX: normalize_data
    //   Shift data so each stored byte lands in its correct word lane.
    //   lo = position of lowest set bit in be (= byte offset within word).
    //   After shifting: data[7:0] -> lane lo, data[15:8] -> lane lo+1, etc.
    //   Then mask with be to zero unused lanes.
    // -------------------------------------------------------
    function automatic logic [31:0] normalize_data(
        input logic [31:0] data,
        input logic [3:0]  be
    );
        logic [31:0] n;
        integer lo;
        lo = 0;
        // Find lowest set bit
        for (int b = 0; b < 4; b++) begin
            if (be[b]) begin
                lo = b;
                break;
            end
        end
        // Shift data so its byte 0 lands in lane 'lo'
        n = data << (lo * 8);
        // Mask to only keep lanes selected by be
        for (int b = 0; b < 4; b++) begin
            if (!be[b])
                n[8*b +: 8] = 8'b0;
        end
        return n;
    endfunction

    // -------------------------------------------------------
    // Main sequential block
    // -------------------------------------------------------
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n) begin
            head  <= '0;
            tail  <= '0;
            count <= '0;
            for (int i = 0; i < DEPTH; i++)
                buf_valid[i] <= 1'b0;
        end else begin
            // PUSH
            if (do_push) begin
                buf_valid[tail] <= 1'b1;
                buf_addr [tail] <= cpu_sw_addr;
                buf_data [tail] <= normalize_data(cpu_sw_data, cpu_sw_be);
                buf_be   [tail] <= cpu_sw_be;
                tail <= (tail == PTR_W'(DEPTH-1)) ? '0 : tail + 1'b1;
            end

            // POP
            if (do_pop) begin
                buf_valid[head] <= 1'b0;
                head <= (head == PTR_W'(DEPTH-1)) ? '0 : head + 1'b1;
            end

            // Count update
            case ({do_push, do_pop})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: ;
            endcase
        end
    end

    // -------------------------------------------------------
    // Drain output (always from head)
    // -------------------------------------------------------
    assign cache_drain_valid = buf_valid[head];
    assign cache_drain_addr  = buf_addr [head];
    assign cache_drain_data  = buf_data [head];
    assign cache_drain_be    = buf_be   [head];

    // -------------------------------------------------------
    // Forwarding / Bypass for loads
    //
    // Scan oldest -> newest (head+0, head+1, ...) so that
    // the NEWEST matching entry's bytes win (later stores overwrite earlier
    // stores to the same address, which is the correct RISC-V behavior).
    //
    // buf_data already has bytes in correct word lanes (normalized above),
    // so the merge just copies enabled bytes directly.
    //
    // Also handle same-cycle bypass for the do_push case (the entry hasn't
    // been written to buf[] yet, so we forward directly from cpu_sw signals).
    // -------------------------------------------------------
    always_comb begin
        cpu_sb_hit   = 1'b0;
        cpu_sb_rdata = cache_rdata;

        if (cpu_lw_valid) begin
            logic [31:0] merged;
            merged = cache_rdata;

            // Scan buffered entries oldest -> newest
            for (int i = 0; i < DEPTH; i++) begin
                automatic integer idx;
                idx = (head + i) % DEPTH;
                if (buf_valid[idx] &&
                    (buf_addr[idx][31:2] == cpu_lw_addr[31:2])) begin
                    cpu_sb_hit = 1'b1;
                    // Merge byte-by-byte; buf_data bytes are already in correct lanes
                    for (int b = 0; b < 4; b++) begin
                        if (buf_be[idx][b])
                            merged[8*b +: 8] = buf_data[idx][8*b +: 8];
                    end
                end
            end

            // Same-cycle bypass: do_push hasn't been registered into buf[] yet
            if (do_push && (cpu_sw_addr[31:2] == cpu_lw_addr[31:2])) begin
                logic [31:0] push_norm;
                push_norm = normalize_data(cpu_sw_data, cpu_sw_be);
                cpu_sb_hit = 1'b1;
                for (int b = 0; b < 4; b++) begin
                    if (cpu_sw_be[b])
                        merged[8*b +: 8] = push_norm[8*b +: 8];
                end
            end

            cpu_sb_rdata = merged;
        end
    end

endmodule