`timescale 1ns/1ps

module tb_top_cache_pmem;

    // Clock and reset
    logic i_clk;
    logic rst_n;
    
    // Signals to top_cache
    logic dcache_resp;
    logic stall_by_cache;
    logic cpu_mem_wr;
    logic cpu_mem_rd;
    logic flush;
    logic jmp_taken;
    logic id_branch_taken;
    logic [1:0] fw_alu_a;
    logic [1:0] fw_alu_b;
    logic [4:0] fw_b1;
    logic [4:0] fw_b2;
    logic stall;
    logic stall_lw;
    logic stall_lwlw;
    logic stall_mem;
    logic stall_beq;
    logic [29:0] if_pc;  // Changed to 30 bits to match port
    logic [4:0] id_wr_reg;
    logic [4:0] id_rs1;
    logic [4:0] id_rs2;
    logic [4:0] idex_wr_reg;
    logic id_mem_wr_sig;
    logic id_jmp_sig;
    logic id_branch_sig;
    logic [4:0] ex_wr_reg;
    logic [31:0] ex_alu_a;
    logic [31:0] ex_alu_b;
    logic [31:0] ex_alu_out;
    logic ex_mem_rd;
    logic mem_mem_rd;
    logic mem_mem_wr;
    logic [31:0] mem_data;
    logic [4:0] mem_wr_reg;
    logic [31:0] mem_rdata;
    logic [4:0] wb_wr_reg;
    logic [31:0] wb_result;
    
    // Physical memory interface signals
    logic pmem_resp;
    logic [31:0] pmem_address;
    logic [255:0] pmem_wdata;
    logic [255:0] pmem_rdata;
    logic pmem_read;
    logic pmem_write;
    
    // Debug signals to pmem
    logic [2:0] latency_counter_reg;
    logic operation_active;

    // ===== Clock Generation =====
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // 10ns period = 100MHz
    end

    // ===== DUT Instantiation =====
    
    // Top cache module
    top_cache dut_top_cache (
        .i_clk(i_clk),
        .rst_n(rst_n),
        .dcache_resp(dcache_resp),
        .stall_by_cache(stall_by_cache),
        .cpu_mem_wr(cpu_mem_wr),
        .cpu_mem_rd(cpu_mem_rd),
        .flush(flush),
        .jmp_taken(jmp_taken),
        .id_branch_taken(id_branch_taken),
        .fw_alu_a(fw_alu_a),
        .fw_alu_b(fw_alu_b),
        .fw_b1(fw_b1),
        .fw_b2(fw_b2),
        .stall(stall),
        .stall_lw(stall_lw),
        .stall_lwlw(stall_lwlw),
        .stall_mem(stall_mem),
        .stall_beq(stall_beq),
        .if_pc(if_pc),
        .id_wr_reg(id_wr_reg),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .idex_wr_reg(idex_wr_reg),
        .id_mem_wr_sig(id_mem_wr_sig),
        .id_jmp_sig(id_jmp_sig),
        .id_branch_sig(id_branch_sig),
        .ex_wr_reg(ex_wr_reg),
        .ex_alu_a(ex_alu_a),
        .ex_alu_b(ex_alu_b),
        .ex_alu_out(ex_alu_out),
        .ex_mem_rd(ex_mem_rd),
        .mem_mem_rd(mem_mem_rd),
        .mem_mem_wr(mem_mem_wr),
        .mem_data(mem_data),
        .mem_wr_reg(mem_wr_reg),
        .mem_rdata(mem_rdata),
        .wb_wr_reg(wb_wr_reg),
        .wb_result(wb_result),
        .pmem_resp(pmem_resp),
        .pmem_address(pmem_address),
        .pmem_rdata(pmem_rdata),    // Added missing connection
        .pmem_wdata(pmem_wdata),    // Added missing connection
        .pmem_read(pmem_read),
        .pmem_write(pmem_write)
    );
    
    // Simple PMEM module
    simple_pmem #(
        .MEM_SIZE_KB(64),
        .LATENCY_CYCLES(5)
    ) dut_pmem (
        .i_clk(i_clk),
        .rst_n(rst_n),
        .pmem_read(pmem_read),
        .pmem_write(pmem_write),
        .pmem_address(pmem_address),
        .pmem_wdata(pmem_wdata),
        .pmem_rdata(pmem_rdata),
        .pmem_resp(pmem_resp),
        .latency_counter_reg(latency_counter_reg),
        .operation_active(operation_active)
    );
    
    // State names for display - Fixed reference to use correct instance name
    string state_name;
    always_comb begin
        // Access the control state through the correct hierarchy
        // Adjust this path based on your actual hierarchy
        case(dut_top_cache.p_d_cache_0.control.state)
            0: state_name = "START";
            1: state_name = "MISS";
            2: state_name = "HIT";
            3: state_name = "WRITE_BACK";
            default: state_name = "UNKNOWN";
        endcase
    end

    // ===== Test Sequence =====
    initial begin
        $display("========================================");
        $display("  Testbench: top_cache + simple_pmem");
        $display("  Target: Write value 20 to pmem[15]");
        $display("========================================\n");
        
        // Initialize all inputs
        rst_n = 0;
        cpu_mem_wr = 0;
        cpu_mem_rd = 0;
        flush = 0;
        jmp_taken = 0;
        id_branch_taken = 0;
        fw_alu_a = 0;
        fw_alu_b = 0;
        fw_b1 = 0;
        fw_b2 = 0;
        if_pc = 0;
        id_wr_reg = 0;
        id_rs1 = 0;
        id_rs2 = 0;
        idex_wr_reg = 0;
        id_mem_wr_sig = 0;
        id_jmp_sig = 0;
        id_branch_sig = 0;
        ex_wr_reg = 0;
        ex_alu_a = 0;
        ex_alu_b = 0;
        ex_alu_out = 0;
        ex_mem_rd = 0;
        mem_mem_rd = 0;
        mem_mem_wr = 0;
        mem_data = 0;
        mem_wr_reg = 0;
        wb_wr_reg = 0;
        wb_result = 0;
        
        // Reset sequence
        repeat(3) @(posedge i_clk);
        rst_n = 1;
        $display("[TB] T=%0t Reset released", $time);
        
        // Wait for system to stabilize
        repeat(5) @(posedge i_clk);
        
        // Monitor memory transactions
        $display("\n[TB] T=%0t Starting memory transaction monitoring...", $time);
        
        // Wait for transactions to occur from CPU
        repeat(100) @(posedge i_clk);
        
        // Check final memory state
        $display("\n========================================");
        $display("  Checking Memory Content");
        $display("========================================");
        $display("[TB] Memory[15] = 0x%h", dut_pmem.memory[15]);
        
        if (dut_pmem.memory[15] == 256'h14) begin
            $display("[TB] ? TEST PASSED: memory[15] = 20 (0x14)");
        end else begin
            $display("[TB] ? TEST FAILED: memory[15] = 0x%h (expected 0x14)", 
                     dut_pmem.memory[15]);
        end
        
        $display("\n========================================");
        $display("  Simulation Complete");
        $display("========================================\n");
        
        $finish;
    end
    
    // ===== Monitor Transactions =====
    always @(posedge i_clk) begin
        if (pmem_write && !operation_active) begin
            $display("[TB] T=%0t >>> PMEM WRITE REQUEST: addr=0x%08h data=0x%h", 
                     $time, pmem_address, pmem_wdata);
        end
        
        if (pmem_read && !operation_active) begin
            $display("[TB] T=%0t >>> PMEM READ REQUEST: addr=0x%08h", 
                     $time, pmem_address);
        end
        
        if (pmem_resp) begin
            if (mem_mem_wr)
                $display("[TB] T=%0t <<< PMEM WRITE RESPONSE", $time);
            else if (mem_mem_rd)
                $display("[TB] T=%0t <<< PMEM READ RESPONSE: data=0x%h", 
                         $time, pmem_rdata);
        end
    end
    
    // ===== Timeout Protection =====
    initial begin
        #50000;  // 50us timeout
        $display("\n[TB] ERROR: Simulation timeout!");
        $finish;
    end
    
    // ===== Waveform Dump =====
    initial begin
        $dumpfile("tb_top_cache_pmem.vcd");
        $dumpvars(0, tb_top_cache_pmem);
    end

endmodule