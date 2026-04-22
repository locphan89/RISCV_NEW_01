`ifndef MSHR_SIZE
  `define MSHR_SIZE      8
`endif
`ifndef WORDS_PER_LINE
  `define WORDS_PER_LINE 4
`endif
`ifndef ADDR_WIDTH
  `define ADDR_WIDTH     32
`endif
`ifndef DATA_WIDTH
  `define DATA_WIDTH     16
`endif
`ifndef REG_WIDTH
  `define REG_WIDTH      5
`endif

`define MSHR_IDX  $clog2(`MSHR_SIZE)
`define WORD_IDX  $clog2(`WORDS_PER_LINE)
`define LINE_ADDR (`ADDR_WIDTH - `WORD_IDX - 2)

// ============================================================
//  STRUCT DEFINITIONS (FIXED: packed array)
// ============================================================

typedef struct packed {
    logic                    valid;
    logic                    is_store;
    logic [`LINE_ADDR-1:0]   line_addr;
    logic [`WORD_IDX-1:0]    word_offset;
    logic [`DATA_WIDTH-1:0]  store_data;
    logic [`REG_WIDTH-1:0]   dest_reg;
} cpu_req_t;

typedef struct packed {
    logic                    valid;
    logic [`MSHR_IDX-1:0]    mshr_idx;
    logic [`WORD_IDX-1:0]    word_offset;
    logic [`REG_WIDTH-1:0]   dest_reg;
} rq_enqueue_t;

typedef struct packed {
    logic                    valid;
    logic [`LINE_ADDR-1:0]   line_addr;
    logic [`WORDS_PER_LINE-1:0][`DATA_WIDTH-1:0] data; // FIX
    logic                    dirty;
} cache_wb_t;

typedef struct packed {
    logic                    valid;
    logic [`LINE_ADDR-1:0]   line_addr;
} mem_req_t;

typedef struct packed {
    logic                    valid;
    logic [`WORDS_PER_LINE-1:0][`DATA_WIDTH-1:0] data; // FIX
} mem_resp_t;

typedef struct packed {
    logic                    valid;
    logic [`DATA_WIDTH-1:0]  data;
    logic [`REG_WIDTH-1:0]   dest_reg;
} forward_t;

typedef struct packed {
    logic                    valid;
    logic [`MSHR_IDX-1:0]    mshr_idx;
    logic [`WORDS_PER_LINE-1:0][`DATA_WIDTH-1:0] data; // FIX
} rq_scan_t;

typedef struct packed {
    logic                        V;
    logic                        S;
    logic [`LINE_ADDR-1:0]       line_addr;
    logic [`WORDS_PER_LINE-1:0][`DATA_WIDTH-1:0] data; // FIX
    logic [`WORDS_PER_LINE-1:0]  Vi;
} mshr_entry_t;


// ============================================================
//  MODULE
// ============================================================

module mshr (
    input  logic         clk,
    input  logic         rst,

    input  cpu_req_t     cpu_req,
    output logic         stall_cpu,

    output forward_t     fwd_to_cpu,

    output rq_enqueue_t  rq_enqueue,
    input  logic         rq_full,
    output rq_scan_t     rq_scan,

    output mem_req_t     mem_req,
    input  logic         mem_req_ack,
    input  mem_resp_t    mem_resp,

    output cache_wb_t    cache_wb,

    output logic         mshr_full,
    output logic         mshr_empty
);

    mshr_entry_t mshr      [`MSHR_SIZE];
    mshr_entry_t mshr_next [`MSHR_SIZE];

    logic [`MSHR_IDX-1:0] alloc_ptr, alloc_ptr_next;
    logic [`MSHR_IDX-1:0] send_ptr, send_ptr_next;
    logic [`MSHR_IDX-1:0] return_ptr, return_ptr_next;

    logic [`MSHR_SIZE-1:0] hit_vec;
    logic [`MSHR_IDX-1:0]  hit_idx;
    logic                  mshr_hit;

    cache_wb_t cache_wb_comb;
    assign cache_wb = cache_wb_comb;

    function automatic logic [`MSHR_IDX-1:0] ptr_inc(input logic [`MSHR_IDX-1:0] p);
        ptr_inc = (p == (`MSHR_SIZE - 1)) ? '0 : p + 1;
    endfunction

    // ============================================================
    // SEARCH
    // ============================================================
    always_comb begin
        hit_vec = '0;
        for (int i = 0; i < `MSHR_SIZE; i++)
            hit_vec[i] = mshr[i].V && (mshr[i].line_addr == cpu_req.line_addr);
    end

    always_comb begin
        hit_idx = '0;
        for (int i = 0; i < `MSHR_SIZE; i++)
            if (hit_vec[i]) hit_idx = i;
    end

    assign mshr_hit = |hit_vec;

    assign mshr_empty = ~(|hit_vec);
    assign mshr_full  = mshr[alloc_ptr].V;

    assign stall_cpu = cpu_req.valid && !mshr_hit && mshr_full;

    // ============================================================
    // COMB
    // ============================================================
    always_comb begin
        mshr_next = mshr;

        alloc_ptr_next  = alloc_ptr;
        send_ptr_next   = send_ptr;
        return_ptr_next = return_ptr;

        cache_wb_comb = '0;

        // RETURN
        if (mem_resp.valid) begin
            for (int w = 0; w < `WORDS_PER_LINE; w++) begin
                if (mshr[return_ptr].Vi[w])
                    cache_wb_comb.data[w] = mshr[return_ptr].data[w];
                else
                    cache_wb_comb.data[w] = mem_resp.data[w];
            end

            cache_wb_comb.valid     = 1;
            cache_wb_comb.line_addr = mshr[return_ptr].line_addr;
            cache_wb_comb.dirty     = |mshr[return_ptr].Vi;

            mshr_next[return_ptr].V  = 0;
            mshr_next[return_ptr].Vi = 0;
            return_ptr_next          = ptr_inc(return_ptr);
        end

        // ALLOC
        if (cpu_req.valid && !mshr_hit && !mshr_full) begin
            mshr_next[alloc_ptr].V         = 1;
            mshr_next[alloc_ptr].S         = 1;
            mshr_next[alloc_ptr].line_addr = cpu_req.line_addr;
            mshr_next[alloc_ptr].Vi        = 0;

            if (cpu_req.is_store) begin
                mshr_next[alloc_ptr].data[cpu_req.word_offset] = cpu_req.store_data;
                mshr_next[alloc_ptr].Vi[cpu_req.word_offset]   = 1;
            end

            alloc_ptr_next = ptr_inc(alloc_ptr);
        end

        // SEND
        if (mshr[send_ptr].V && mshr[send_ptr].S && mem_req_ack) begin
            mshr_next[send_ptr].S = 0;
            send_ptr_next         = ptr_inc(send_ptr);
        end
    end

    assign mem_req.valid     = mshr[send_ptr].V && mshr[send_ptr].S;
    assign mem_req.line_addr = mshr[send_ptr].line_addr;

    // ============================================================
    // SEQ
    // ============================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mshr       <= '{default:0};
            alloc_ptr  <= 0;
            send_ptr   <= 0;
            return_ptr <= 0;
        end else begin
            mshr       <= mshr_next;
            alloc_ptr  <= alloc_ptr_next;
            send_ptr   <= send_ptr_next;
            return_ptr <= return_ptr_next;
        end
    end

endmodule