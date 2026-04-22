// ============================================================
//  tb_individual_test.sv  - Test t?ng l?nh riêng bi?t
//  lb, lbu, lh, lhu, sltu, srai, bltu, bgeu
// ============================================================
`timescale 1ns/1ps
import rv32i_types::*;

module tb_individual_test;

    logic i_clk, rst_n;
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // ?? DUT signals ??????????????????????????????????????????
    logic                    flush, stall, stall_by_cache;
    logic                    stall_lw, stall_lwlw, stall_mem, stall_beq;
    logic [PC_WIDTH-1:0]     if_pc;
    logic [INST_WIDTH-1:0]   if_inst;
    logic [R_ADDR_WIDTH-1:0] wb_wr_reg;
    logic [DATA_WIDTH-1:0]   wb_result;
    logic [DATA_WIDTH-1:0]   ex_alu_out;
    logic [DATA_WIDTH-1:0]   mem_addr, mem_data;
    logic                    mem_mem_rd, mem_mem_wr;
    logic                    dcache_resp, sb_hit, cache_hit;
    logic [1:0]              cache_state_out;

    // ?? DUT ??????????????????????????????????????????????????
    top_cache_2_sb_std #(
        .MEM_SIZE_KB   (4),
        .LATENCY_CYCLES(3)
    ) dut (
        .i_clk, .rst_n,
        .flush, .stall, .stall_by_cache,
        .stall_lw, .stall_lwlw, .stall_mem, .stall_beq,
        .if_pc, .if_inst,
        .wb_wr_reg, .wb_result,
        .ex_alu_out,
        .mem_addr, .mem_data,
        .mem_mem_rd, .mem_mem_wr,
        .dcache_resp, .sb_hit, .cache_hit,
        .cache_state_out,
        .cpu_mem_wr         (),
        .cpu_mem_rd         (),
        .jmp_taken          (),
        .id_branch_taken    (),
        .fw_alu_a           (),
        .fw_alu_b           (),
        .fw_b1              (),
        .fw_b2              (),
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
        .ex_mem_rd          (),
        .mem_wr_reg         (),
        .mem_rdata          (),
        .pmem_resp          (),
        .pmem_address       (),
        .pmem_read          (),
        .pmem_write         (),
        .sb_cache_resp      (),
        .sb_ready           (),
        .cache_mem_read     (),
        .cache_drain_ready  (),
        .cache_drain_valid  (),
        .mem_byte_en        ()
    );

    // ?? Init physical memory ?????????????????????????????????
    initial begin
        #1;
        for (int i = 0; i < 128; i++)
            dut.memory[i] = '0;
        $display("[TB] pmem cleared, imem loaded from test_individual.txt");
    end

    // ?? Shadow RF ????????????????????????????????????????????
    logic [DATA_WIDTH-1:0] rf [0:31];
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (~rst_n) begin
            for (int i=0;i<32;i++) rf[i] <= 0;
        end else begin
            if (wb_wr_reg != 0)
                rf[wb_wr_reg] <= wb_result;
        end
    end

    // ?? Stuck / cycle counter ?????????????????????????????????
    logic [PC_WIDTH-1:0] prev_pc;
    logic [31:0]         stuck_cnt;
    logic [63:0]         cyc;
    int                  done;
    initial done = 0;

    always_ff @(posedge i_clk or negedge rst_n) begin
        if (~rst_n) begin prev_pc<=0; stuck_cnt<=0; cyc<=0;
        end else begin
            cyc <= cyc+1;
            prev_pc <= if_pc;
            if (if_pc==prev_pc && !stall && !stall_by_cache && cyc>10)
                stuck_cnt <= stuck_cnt+1;
            else
                stuck_cnt <= 0;
        end
    end

    // ?? Optional trace ???????????????????????????????????????
    always @(posedge i_clk) begin
        if (rst_n && cyc<=300)
            $display("CY=%-4d IF_PC=%02h INST=%08h | stall=%b stall$=%b flush=%b | WB x%02d=0x%08h",
                cyc, if_pc, if_inst, stall, stall_by_cache, flush,
                wb_wr_reg, wb_result);
    end

    // ?? Checks ???????????????????????????????????????????????
    int pass_cnt, fail_cnt;

    task automatic chk(input int num, input int reg_idx,
                       input logic [31:0] exp, input string desc);
        logic [31:0] got;
        got = rf[reg_idx];
        if (got === exp) begin
            $display("  [PASS] %2d  x%02d  %s   got=0x%08h", num, reg_idx, desc, got);
            pass_cnt++;
        end else begin
            $display("  [FAIL] %2d  x%02d  %s   exp=0x%08h  got=0x%08h",
                     num, reg_idx, desc, exp, got);
            fail_cnt++;
        end
    endtask

    task run_checks();
        pass_cnt=0; fail_cnt=0;
        $display("");
        $display("????????????????????????????????????????????????????");
        $display("?           INDIVIDUAL INSTRUCTION TEST            ?");
        $display("????????????????????????????????????????????????????");

        $display("?  ??? LOAD BYTE (lb) ??????????????????????????  ?");
        chk( 0, 10, 32'hFFFFFFAB, "lb  0(x5) sign_ext(0xAB)");
        chk( 1, 11, 32'hFFFFFFF0, "lb  2(x5) sign_ext(0xF0)");

        $display("?  ??? LOAD BYTE UNSIGNED (lbu) ????????????????  ?");
        chk( 2, 12, 32'h000000AB, "lbu 0(x5) zero_ext(0xAB)");
        chk( 3, 13, 32'h00000082, "lbu 1(x5) zero_ext(0x82)");

        $display("?  ??? LOAD HALF (lh) ??????????????????????????  ?");
        chk( 4, 14, 32'hFFFF82AB, "lh  0(x5) sign_ext(0x82AB)");
        chk( 5, 15, 32'h000001F0, "lh  2(x5) sign_ext(0x01F0)");

        $display("?  ??? LOAD HALF UNSIGNED (lhu) ????????????????  ?");
        chk( 6, 16, 32'h000082AB, "lhu 0(x5) zero_ext(0x82AB)");
        chk( 7, 17, 32'h000001F0, "lhu 2(x5) zero_ext(0x01F0)");

        $display("?  ??? SET LESS THAN UNSIGNED (sltu) ???????????  ?");
        chk( 8, 18, 32'h00000001, "sltu x2<x3  (1<0x80000000)=1");
        chk( 9, 19, 32'h00000000, "sltu x3<x2  (0x80000000<1)=0");

        $display("?  ??? SHIFT RIGHT ARITH IMM (srai) ????????????  ?");
        chk(10, 20, 32'hF8000000, "srai x4>>4   0x80000000>>4");
        chk(11, 21, 32'hFFFFFFFF, "srai x4>>31  0x80000000>>31");
        chk(12, 22, 32'h00000010, "srai x6>>2   64>>2=16");

        $display("?  ??? BRANCH LESS THAN UNSIGNED (bltu) ????????  ?");
        chk(13, 23, 32'h00000001, "bltu TAKEN:  x2<x3  ?x23=1");
        chk(14, 24, 32'h00000064, "bltu NTAKEN: x3<x2? ?x24=100");

        $display("?  ??? BRANCH GEQ UNSIGNED (bgeu) ??????????????  ?");
        chk(15, 25, 32'h00000001, "bgeu TAKEN:  x3>=x2 ?x25=1");
        chk(16, 26, 32'h00000064, "bgeu NTAKEN: x2>=x3? ?x26=100");

        $display("????????????????????????????????????????????????????");
        $display("?  TOTAL: %2d / %2d PASSED   (%0d cycles)%s",
                 pass_cnt, pass_cnt+fail_cnt, cyc,
                 fail_cnt==0 ? "  ALL PASS ?" : "           ?");
        if (fail_cnt > 0)
            $display("?  >>> %0d FAILED <<<                               ?", fail_cnt);
        $display("????????????????????????????????????????????????????");

        $display("");
        $display("Shadow RF (non-zero):");
        for (int r=0;r<32;r++)
            if (rf[r]!==32'h0)
                $display("  x%-2d = 0x%08h", r, rf[r]);
    endtask

    // ?? Stop conditions ??????????????????????????????????????
    always @(posedge i_clk) begin
        if (rst_n && stuck_cnt>=20 && !done) begin
            done=1;
            $display("[TB] halt detected: PC=0x%02h  cycle=%0d", if_pc, cyc);
            run_checks();
            $finish;
        end
    end

    initial begin
        repeat(5000) @(posedge i_clk);
        if (!done) begin
            done=1;
            $display("[TB] TIMEOUT at cycle %0d", cyc);
            run_checks();
            $finish;
        end
    end

    // ?? Reset ????????????????????????????????????????????????
    initial begin
        rst_n=0;
        @(negedge i_clk); @(negedge i_clk);
        rst_n=1;
        $display("[TB] Reset released");
    end

    initial begin
        $dumpfile("tb_individual_test.vcd");
        $dumpvars(0, tb_individual_test);
    end

endmodule