`timescale 1ns/1ps
import rv32i_types::*;

// =============================================================================
//  tb_top_cache_2.sv
//
//  Counter spec:
//  1. num_pmem_access : if (cpu_mem_rd || cpu_mem_wr) => num_pmem_access++
//  2. num_miss        : if (pmem_resp)                => num_miss++
//  3. miss_rate       : num_miss / num_pmem_access
//  4. cycle_cnt       : ??m cycle khi if_pc <= NUM_INST-1,
//                       sau ?ó ??m thêm ?úng 4 cycle drain r?i d?ng
//  5. CPI             : cycle_cnt / NUM_INST  (NUM_INST = 25, c? ??nh)
//
//  flush = id_cs.jmp_sig | ex_branch_taken | id_is_jalr_sig
// =============================================================================

module tb_top_cache_2;

    // =========================================================
    // Clock & Reset
    // =========================================================
    logic i_clk;
    logic rst_n;

    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // =========================================================
    // DUT port signals
    // =========================================================
    logic                    flush;
    logic                    stall;
    logic                    stall_by_cache;
    logic                    cpu_mem_wr;
    logic                    cpu_mem_rd;
    logic [PC_WIDTH-1:0]     if_pc;
    logic [INST_WIDTH-1:0]   if_inst;
    logic [DATA_WIDTH-1:0]   wb_result;
    logic                    pmem_resp;
    logic [31:0]             pmem_address;
    logic                    pmem_read;
    logic                    pmem_write;

    // =========================================================
    // Simulation parameters
    // =========================================================
    localparam SIM_CYCLES = 2880;
    localparam LOG_DETAIL = 0;

    // S? instruction th?c t? trong program (PC 0x0000 ~ 0x0018)
    localparam NUM_INST   = 25;

    // =========================================================
    // COUNTER 1: num_pmem_access
    //   if (cpu_mem_rd || cpu_mem_wr) => num_pmem_access++
    // =========================================================
    longint unsigned num_pmem_access = 0;

    always_ff @(posedge i_clk) begin
        if (rst_n)
            if (cpu_mem_rd || cpu_mem_wr)
                num_pmem_access <= num_pmem_access + 1;
    end

    // =========================================================
    // COUNTER 2: num_miss
    //   if (pmem_resp) => num_miss++
    // =========================================================
    longint unsigned num_miss = 0;

    always_ff @(posedge i_clk) begin
        if (rst_n)
            if (pmem_resp)
                num_miss <= num_miss + 1;
    end

    // =========================================================
    // COUNTER 3: cycle_cnt
    //   Giai ?o?n 1: if_pc <= NUM_INST-1  => cycle_cnt++
    //   Giai ?o?n 2: sau PC cu?i, ??m thêm ?úng 4 cycle r?i d?ng
    // =========================================================
    longint unsigned cycle_cnt = 0;
    int unsigned     drain_cnt = 0;
    logic            past_end  = 0;

    always_ff @(posedge i_clk) begin
        if (rst_n) begin
            if (!past_end) begin
                if (if_pc <= PC_WIDTH'(NUM_INST - 1)) begin
                    // Còn trong vùng program
                    cycle_cnt <= cycle_cnt + 1;
                end else begin
                    // V?a qua PC cu?i: b?t ??u drain, cycle này là drain cycle 1
                    past_end  <= 1'b1;
                    drain_cnt <= 1;
                    cycle_cnt <= cycle_cnt + 1;
                end
            end else begin
                // Drain: ??m thêm 3 cycle n?a (t?ng 4)
                if (drain_cnt < 4) begin
                    drain_cnt <= drain_cnt + 1;
                    cycle_cnt <= cycle_cnt + 1;
                end
                // drain_cnt == 4: d?ng h?n
            end
        end
    end

    // =========================================================
    // Stall counter (?? tính % stall)
    // =========================================================
    longint unsigned stall_cycles = 0;
    longint unsigned flush_count  = 0;
    longint unsigned total_cycles = 0;

    logic [PC_WIDTH-1:0] prev_pc      = '0;
    int                  pc_stuck_cnt = 0;

    logic stall_total;
    assign stall_total = stall | stall_by_cache;

    always_ff @(posedge i_clk) begin
        if (rst_n) begin
            total_cycles <= total_cycles + 1;

            if (stall_total)
                stall_cycles <= stall_cycles + 1;

            if (flush)
                flush_count <= flush_count + 1;

            prev_pc <= if_pc;
            if (if_pc == prev_pc && !stall_total && total_cycles > 5)
                pc_stuck_cnt <= pc_stuck_cnt + 1;
            else
                pc_stuck_cnt <= 0;
        end
    end

    // =========================================================
    // DUT instantiation
    // =========================================================
    top_cache_2_sb_std #(
        .MEM_SIZE_KB   (4),
        .LATENCY_CYCLES(3)
    ) dut (
        .i_clk,
        .rst_n,
        .flush,
        .stall,
        .stall_by_cache,
        .cpu_mem_wr,
        .cpu_mem_rd,
        .if_pc,
        .if_inst,
        .wb_result,
        .pmem_resp,
        .pmem_address,
        .pmem_read,
        .pmem_write,
        .dcache_resp        (),
        .jmp_taken          (),
        .id_branch_taken    (),
        .fw_alu_a           (),
        .fw_alu_b           (),
        .fw_b1              (),
        .fw_b2              (),
        .stall_lw           (),
        .stall_lwlw         (),
        .stall_mem          (),
        .stall_beq          (),
        .id_wr_reg          (),
        .id_rs1             (),
        .id_rs2             (),
        .idex_wr_reg        (),
        .id_mem_wr_sig      (),
        .id_jmp_sig         (),
        .id_branch_sig      (),
        .ex_wr_reg          (),
        .ex_alu_a           (),
        .ex_alu_b           (),
        .ex_alu_out         (),
        .ex_mem_rd          (),
        .mem_mem_rd         (),
        .mem_mem_wr         (),
        .mem_addr           (),
        .mem_data           (),
        .mem_wr_reg         (),
        .mem_rdata          (),
        .cache_state_out    (),
        .cache_hit          (),
        .sb_cache_resp      (),
        .sb_hit             (),
        .sb_ready           (),
        .cache_mem_read     (),
        .cache_drain_ready  (),
        .cache_drain_valid  (),
        .mem_byte_en        ()
    );

    // =========================================================
    // Reset
    // =========================================================
    initial begin
        rst_n = 1'b0;
        @(negedge i_clk);
        @(negedge i_clk);
        rst_n = 1'b1;
        $display("==========================================================");
        $display("  RESET RELEASED - Simulation START");
        $display("  Program : %0d instructions  (PC 0x0000 ~ 0x%04h)",
                 NUM_INST, NUM_INST - 1);
        $display("  Timeout : %0d cycles", SIM_CYCLES);
        $display("==========================================================");
    end

    // =========================================================
    // Waveform
    // =========================================================
    initial begin
        $dumpfile("tb_top_cache_2.vcd");
        $dumpvars(0, tb_top_cache_2);
    end

    // =========================================================
    // Task: Print report
    // =========================================================
    task automatic print_report(input string reason);
        longint unsigned cpi_int, cpi_frac;
        longint unsigned stall_pct;
        longint unsigned miss_int, miss_frac;

        // CPI = cycle_cnt / NUM_INST  (bi?t ch?c NUM_INST l?nh)
        cpi_int  = cycle_cnt / NUM_INST;
        cpi_frac = (cycle_cnt % NUM_INST) * 10000 / NUM_INST;

        stall_pct = (total_cycles > 0) ?
                    (stall_cycles * 1000) / total_cycles : 0;

        if (num_pmem_access > 0) begin
            miss_int  = (num_miss * 100)   / num_pmem_access;
            miss_frac = (num_miss * 10000) / num_pmem_access - miss_int * 100;
        end else begin
            miss_int  = 0;
            miss_frac = 0;
        end

        $display("");
        $display("============================================================");
        $display("  PERFORMANCE REPORT  [%s]", reason);
        $display("============================================================");
        $display("  Total Cycles    : %0d", total_cycles);
        $display("  Cycle Count     : %0d  (PC 0x0000~0x%04h + 4 drain)",
                 cycle_cnt, NUM_INST - 1);
        $display("  CPI             : %0d.%04d  (cycle_cnt / %0d instr)",
                 cpi_int, cpi_frac, NUM_INST);
        $display("  Final IF_PC     : 0x%04h", if_pc);
        $display("  Stall Cycles    : %0d  (%0d.%01d%%)",
                 stall_cycles, stall_pct/10, stall_pct%10);
        $display("  Flush Count     : %0d", flush_count);
        $display("------------------------------------------------------------");
        $display("  CACHE MISS RATE");
        $display("    num_pmem_access = %0d", num_pmem_access);
        $display("    num_miss        = %0d", num_miss);
        $display("    miss_rate       = %0d.%02d%%", miss_int, miss_frac);
        $display("============================================================");
        $display("");
    endtask

    // =========================================================
    // Stop 1: PC stuck (program ended)
    // =========================================================
    always @(posedge i_clk) begin
        if (rst_n && pc_stuck_cnt >= 10) begin
            $display("\n[TB] Program end: PC=0x%04h stuck", if_pc);
            print_report("PROGRAM END");
            $finish;
        end
    end

    // =========================================================
    // Stop 2: Timeout
    // =========================================================
    initial begin
        repeat (SIM_CYCLES) @(posedge i_clk);
        $display("\n[TB] TIMEOUT after %0d cycles!", SIM_CYCLES);
        print_report("TIMEOUT");
        $finish;
    end

    // =========================================================
    // Cycle log (LOG_DETAIL=1 ?? b?t)
    // =========================================================
    always @(posedge i_clk) begin
        if (rst_n && LOG_DETAIL)
            $display("CY=%-5d PC=%04h drain=%0d | stall=%b stall$=%b flush=%b | rd=%b wr=%b resp=%b | WB=%08h",
                total_cycles, if_pc, drain_cnt,
                stall, stall_by_cache, flush,
                cpu_mem_rd, cpu_mem_wr, pmem_resp, wb_result);
    end

endmodule