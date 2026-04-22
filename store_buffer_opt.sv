module store_buffer_opt #(
    parameter DEPTH = 4,
	 parameter PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input  logic        i_clk,
    input  logic        rst_n,

    // ===== CPU STORE =====
    input  logic        cpu_sw_valid,
    input  logic [31:0] cpu_sw_addr,
    input  logic [31:0] cpu_sw_data,
    input  logic [3:0]  cpu_sw_be,
    output logic        cpu_sw_ready,
    //output logic        cpu_sb_full,

    // ===== CPU LOAD =====
    input  logic        cpu_lw_valid,
    input  logic [31:0] cpu_lw_addr,
    input  logic [31:0] cache_rdata,
    output logic        cpu_sb_hit,
    output logic [31:0] cpu_sb_rdata,

    // ===== Drain → cache =====
    output logic        cache_drain_valid,
    output logic [31:0] cache_drain_addr,
    output logic [31:0] cache_drain_data,
    output logic [3:0]  cache_drain_be,
    input  logic        cache_drain_ready,
	 
	 output logic             cpu_sb_full,
	 output logic             do_pop,
	 output logic             do_push,
	 output logic [PTR_W:0] nxt_cnt, 
	 output logic [PTR_W:0] count
	 
);

    // ==========================================
    // PARAM
    // ==========================================
    //localparam PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;

    // ==========================================
    // BUFFER (Quartus-friendly)
    // ==========================================
    logic        buf_valid [0:DEPTH-1];
    logic [31:0] buf_addr  [0:DEPTH-1];
    logic [31:0] buf_data  [0:DEPTH-1];
    logic [3:0]  buf_be    [0:DEPTH-1];

    logic [PTR_W-1:0] head, tail;
    //logic [PTR_W:0]   nxt_cnt, count;
	 
	 //logic             cpu_sb_nfull;
	  //logic do_push, do_pop;
	 
	  always_ff @(posedge i_clk or negedge rst_n) begin
			  if (!rst_n) begin
					do_pop <= '0;
			  end
			  else begin
					do_pop <= cache_drain_valid && cache_drain_ready;
			  end
	  end

    // ==========================================
    // WRAP FUNCTION
    // ==========================================
    function automatic integer wrap_idx(input integer val);
        if (val < 0) return val + DEPTH;
        else if (val >= DEPTH) return val - DEPTH;
        else return val;
    endfunction

    // ==========================================
    // FULL / READY
    // ==========================================
    assign cpu_sw_ready = !cpu_sb_full || do_pop;

    // ==========================================
    // CONTROL
    // ==========================================
   

    assign do_push = cpu_sw_valid && cpu_sw_ready;
    //assign do_pop  = cache_drain_valid && cache_drain_ready_r;
	 
	 always_comb begin
        nxt_cnt = count;
		  case ({do_push, do_pop})
                2'b10: nxt_cnt = count + 1'b1;
                2'b01: nxt_cnt = count - 1'b1;
                default: ;
        endcase
		  
    end // always_comb

    // ==========================================
    // MAIN SEQUENTIAL BLOCK (FIX MULTI-DRIVER)
    // ==========================================
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (!rst_n) begin
            head  <= '0;
            tail  <= '0;
            count <= '0;

            for (int i = 0; i < DEPTH; i++) begin
                buf_valid[i] <= 1'b0;
            end
        end else begin

            // =========================
            // PUSH
            // =========================
            if (do_push) begin
                buf_valid[tail] <= 1'b1;
                buf_addr [tail] <= cpu_sw_addr;
                buf_data [tail] <= cpu_sw_data;
                buf_be   [tail] <= cpu_sw_be;

                if (tail == DEPTH-1)
                    tail <= '0;
                else
                    tail <= tail + 1'b1;
            end

            // =========================
            // POP
            // =========================
            if (do_pop) begin
                buf_valid[head] <= 1'b0;

                if (head == DEPTH-1)
                    head <= '0;
                else
                    head <= head + 1'b1;
            end

            // =========================
            // COUNT UPDATE
            // =========================
            count        <= nxt_cnt;
				cpu_sb_full  <= nxt_cnt[PTR_W];
        end
    end

    // ==========================================
    // DRAIN OUTPUT
    // ==========================================
    assign cache_drain_valid = buf_valid[head];
    assign cache_drain_addr  = buf_addr [head];
    assign cache_drain_data  = buf_data [head];
    assign cache_drain_be    = buf_be   [head];

    // ==========================================
    // BYPASS + FORWARDING
    // ==========================================
    always_comb begin
        cpu_sb_hit   = 1'b0;
        cpu_sb_rdata = cache_rdata;

        if (cpu_lw_valid) begin
            logic [31:0] merged;
            merged = cache_rdata;

            // -------------------------------
            // SAME-CYCLE BYPASS
            // -------------------------------
            if (do_push && (cpu_sw_addr[31:2] == cpu_lw_addr[31:2])) begin
                cpu_sb_hit = 1'b1;
                for (int b = 0; b < 4; b++) begin
                    if (cpu_sw_be[b])
                        merged[8*b +: 8] = cpu_sw_data[8*b +: 8];
                end
            end

            // -------------------------------
            // SCAN NEWEST → OLDEST
            // -------------------------------
            for (int i = 0; i < DEPTH; i++) begin
                integer idx;
                idx = wrap_idx(tail - 1 - i);

                if (buf_valid[idx] &&
                    (buf_addr[idx][31:2] == cpu_lw_addr[31:2])) begin

                    cpu_sb_hit = 1'b1;

                    for (int b = 0; b < 4; b++) begin
                        if (buf_be[idx][b])
                            merged[8*b +: 8] = buf_data[idx][8*b +: 8];
                    end

                    // 🔥 giảm delay
                    break;
                end
            end

            cpu_sb_rdata = merged;
        end
    end

endmodule