module simple_pmem #(
    parameter MEM_SIZE_KB = 64,
    parameter LATENCY_CYCLES = 5
)(
    input  logic         i_clk,
    input  logic         rst_n,
    
    // PMEM interface
    input  logic         pmem_read,
    input  logic         pmem_write,
    input  logic [31:0]  pmem_address,
    input  logic [255:0] pmem_wdata,
    output logic [255:0] pmem_rdata,
    output logic         pmem_resp,
    
    // Debug outputs for testbench
    output logic [$clog2(LATENCY_CYCLES+1)-1:0] latency_counter_reg,
    output logic         operation_active
);

    // Memory array
    localparam MEM_DEPTH = (MEM_SIZE_KB * 1024) / 32;
    logic [255:0] memory [MEM_DEPTH];
    
    // COMBINATIONAL counter - visible ngay l?p t?c
    logic [$clog2(LATENCY_CYCLES+1)-1:0] latency_counter;
    
    // Latch request info khi b?t d?u MISS
    logic        pending_read;
    logic        pending_write;
    logic [31:0] pending_address;
    logic [255:0] pending_wdata;
    logic        will_resp_next_cycle;  // Block request cycle sau response
    
    // Address calculation
    logic [31:0] mem_index;
    assign mem_index = pending_address[31:5];
    
    // ===== COMBINATIONAL LOGIC: Counter visible ngay l?p t?c =====
    always_comb begin
        if ((pmem_read || pmem_write) && latency_counter_reg == '0 && !will_resp_next_cycle) begin
            latency_counter = LATENCY_CYCLES;
        end else begin
            latency_counter = latency_counter_reg;
        end
    end
    
    // ===== SEQUENTIAL LOGIC =====
    always_ff @(posedge i_clk or negedge rst_n) begin
        if (~rst_n) begin
            latency_counter_reg   <= '0;
            operation_active      <= 1'b0;
            pmem_resp             <= 1'b0;
            pmem_rdata            <= '0;
            pending_read          <= 1'b0;
            pending_write         <= 1'b0;
            pending_address       <= '0;
            pending_wdata         <= '0;
            will_resp_next_cycle  <= 1'b0;
        end else begin
            // Default: no response
            pmem_resp <= 1'b0;
            
            // ===== DEBUG: Show state =====
            $display("[PMEM] [DEBUG] T=%0t counter=%0d rd=%b wr=%b flag=%b resp=%b",
                     $time, latency_counter_reg, pmem_read, pmem_write, 
                     will_resp_next_cycle, pmem_resp);
            
            // ===== Clear flag when at HIT state =====
            if (latency_counter_reg == '0 && will_resp_next_cycle) begin
                will_resp_next_cycle <= 1'b0;
                $display("[PMEM] [FLAG] T=%0t Clearing flag", $time);
            end
            
            // ===== B?T Ð?U MISS: Ch? khi counter=0 VÀ flag=0 =====
            if ((pmem_read || pmem_write) && 
                latency_counter_reg == '0 && 
                !will_resp_next_cycle) begin
                
                latency_counter_reg <= LATENCY_CYCLES;
                operation_active    <= 1'b1;
                pending_read        <= pmem_read;
                pending_write       <= pmem_write;
                pending_address     <= pmem_address;
                pending_wdata       <= pmem_wdata;
                
                $display("[PMEM] [HIT?MISS] T=%0t ? %s REQUEST addr=0x%08h ? latency=%0d",
                         $time, pmem_write ? "WRITE" : "READ", pmem_address, LATENCY_CYCLES);
            end
            
            // ===== Ð?M XU?NG =====
            else if (latency_counter_reg > '0) begin
                latency_counter_reg <= latency_counter_reg - 1;
                
                $display("[PMEM] [MISS] T=%0t Counting: %0d ? %0d",
                         $time, latency_counter_reg, latency_counter_reg - 1);
                
                // Response khi counter = 1
                if (latency_counter_reg == 1) begin
                    pmem_resp            <= 1'b1;
                    operation_active     <= 1'b0;
                    will_resp_next_cycle <= 1'b1;  // Set flag
                    
                    if (pending_write) begin
                        memory[mem_index] <= pending_wdata;
                        $display("[PMEM] [MISS?HIT] T=%0t ? RESP WRITE addr=0x%08h",
                                 $time, pending_address);
                    end else if (pending_read) begin
                        pmem_rdata <= memory[mem_index];
                        $display("[PMEM] [MISS?HIT] T=%0t ? RESP READ addr=0x%08h data=0x%h",
                                 $time, pending_address, memory[mem_index]);
                    end
                    
                    pending_read  <= 1'b0;
                    pending_write <= 1'b0;
                end
            end
        end
    end
    
    // Initialize memory
    initial begin
        for (int i = 0; i < MEM_DEPTH; i++) begin
            memory[i] = {8{32'h00000010 + i[7:0]}};
        end
    end

endmodule