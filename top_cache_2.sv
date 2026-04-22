import rv32i_types::*;
module top_cache_2 #(
    parameter MEM_SIZE_KB = 4,
    parameter LATENCY_CYCLES = 3
)
(
    input logic                     i_clk,
    input logic                     rst_n,
	 
	 output logic                    dcache_resp,
	 output logic                    stall_by_cache,
	 
	 output logic                    cpu_mem_wr,
	 output logic                    cpu_mem_rd,

    // Control siganls
    output logic                    flush,
    output logic                    jmp_taken,
    output logic                    id_branch_taken,
    output logic [FW_ALU_WIDTH-1:0] fw_alu_a,
    output logic [FW_ALU_WIDTH-1:0] fw_alu_b,
    output logic [4:0]              fw_b1,
    output logic [4:0]              fw_b2,

    // Stall signals
    output logic                    stall,
    output logic                    stall_lw,
    output logic                    stall_lwlw,
    output logic                    stall_mem,
    output logic                    stall_beq,

    // IF Stage
    output logic [PC_WIDTH-1:0]     if_pc,
    output logic [INST_WIDTH-1:0]   if_inst,

    // ID Stage
    output logic [R_ADDR_WIDTH-1:0] id_wr_reg,
    output logic [R_ADDR_WIDTH-1:0] id_rs1,
	 output logic [R_ADDR_WIDTH-1:0] id_rs2,
	 
	 //output logic [DATA_WIDTH-1:0]   id_rsb,
    //output logic [DATA_WIDTH-1:0]   id_rtb,
	 
	 output logic [R_ADDR_WIDTH-1:0] idex_wr_reg,
	 
	 output logic                    id_mem_wr_sig,
	 output logic                    id_jmp_sig,
	 output logic                    id_branch_sig,

    // EX Stage
    //output logic [8-1:0]            ex_rd1,
    //output logic [8-1:0]            ex_rd2,
    output logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
    output logic [DATA_WIDTH-1:0]   ex_alu_a,
    output logic [DATA_WIDTH-1:0]   ex_alu_b,
    output logic [DATA_WIDTH-1:0]   ex_alu_out,
	 
	 output logic                    ex_mem_rd,

    // MEM Stage
    output logic                    mem_mem_rd,
    output logic                    mem_mem_wr,
    output logic [DATA_WIDTH-1:0]   mem_addr,
    output logic [DATA_WIDTH-1:0]   mem_data,
    output logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
    output logic [DATA_WIDTH-1:0]   mem_rdata,

    // WB Stage
    output logic [R_ADDR_WIDTH-1:0] wb_wr_reg,
    output logic [DATA_WIDTH-1:0]   wb_result,
	
	/* Physical memory signals */
  output logic                        pmem_resp,
  //input logic [255:0]                pmem_rdata,
  output logic [31:0]                pmem_address,
  //output logic [255:0]               pmem_wdata,
  output logic                       pmem_read,
  output logic                       pmem_write,
  
   output logic [1:0] cache_state_out,
	
	output logic cache_hit
);
	 logic [255:0]                pmem_rdata;
	 logic [255:0]                pmem_wdata;
	 
	 logic [$clog2(LATENCY_CYCLES+1)-1:0] latency_counter_reg;
    logic         operation_active;
	 
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

            // ===== Clear flag when at HIT state =====
            if (latency_counter_reg == '0 && will_resp_next_cycle) begin
                will_resp_next_cycle <= 1'b0;
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
                
            end
            
            // ===== Ð?M XU?NG =====
            else if (latency_counter_reg > '0) begin
                latency_counter_reg <= latency_counter_reg - 1;
                
                // Response khi counter = 1
                if (latency_counter_reg == 1) begin
                    pmem_resp            <= 1'b1;
                    operation_active     <= 1'b0;
                    will_resp_next_cycle <= 1'b1;  // Set flag
                    
                    if (pending_write) begin
                        memory[mem_index] <= pending_wdata;
                    end else if (pending_read) begin
                        pmem_rdata <= memory[mem_index];       
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
				memory[0] = {8{32'd00000020}};
				memory[31] = {8{32'd00000035}};
        end
    end

	//logic [DATA_WIDTH-1:0]   mem_addr;
	logic [8-1:0]            ex_rd1;
   logic [8-1:0]            ex_rd2;
	
	///logic [INST_WIDTH-1:0]   if_inst;
	
	logic [DATA_WIDTH-1:0]   id_rsb;
   logic [DATA_WIDTH-1:0]   id_rtb;
	
	
	

    /*always_comb begin
        // Access the control state through the correct hierarchy
        // Adjust this path based on your actual hierarchy
        case(p_d_cache_0.control.state)
            0: state_name = 1;
            1: state_name = 2;
            2: state_name = 3;
            3: state_name = 4;
            default: state_name = 0;
        endcase
    end*/

	top_5stages_cache top_5stages_cache_0
(
    .i_clk,
    .rst_n,
	 
	 .dcache_resp(dcache_resp),
	 .stall_by_cache,
	 
	 .cpu_mem_wr(cpu_mem_wr),
	 .cpu_mem_rd(cpu_mem_rd),

    // Control siganls
    .flush,
    .jmp_taken,
    .id_branch_taken,
    .fw_alu_a,
    .fw_alu_b,
    .fw_b1,
    .fw_b2,

    // Stall signals
    .stall,
    .stall_lw,
    .stall_lwlw,
    .stall_mem,
    .stall_beq,
    
    // IF Stage
    .if_pc,
    .if_inst,

    // ID Stage
    .id_wr_reg,
    .id_rs1,
	 .id_rs2,
	 
	 .id_rsb,
    .id_rtb,
	 
	 .idex_wr_reg,
	 
	 .id_mem_wr_sig,
	 .id_jmp_sig,
	 .id_branch_sig,

    // EX Stage
    .ex_rd1,
    .ex_rd2,
    .ex_wr_reg,
    .ex_alu_a,
    .ex_alu_b,
    .ex_alu_out,
	 
	 .ex_mem_rd,

    // MEM Stage
    .mem_mem_rd,
    .mem_mem_wr,
    .mem_data(mem_data),
	 .mem_addr(mem_addr),
    .mem_wr_reg,
    .mem_rdata(mem_rdata),

    // WB Stage
    .wb_wr_reg,
    .wb_result 
);

//logic [255:0] temp;
//assign temp = {8{32'd00000020}};

p_d_cache p_d_cache_0

(
  .i_clk,
  .rst_n,
  /* Physical memory signals */
  .pmem_resp(pmem_resp),
  .pmem_rdata(pmem_rdata),
  .pmem_address(pmem_address),
  .pmem_wdata(pmem_wdata),
  .pmem_read(pmem_read),
  .pmem_write(pmem_write),

  /* CPU memory signals */
  .mem_read(mem_mem_rd),
  .mem_write(mem_mem_wr),
  .mem_byte_enable_cpu(4'b1111),
  .mem_address(mem_addr),
  .mem_wdata_cpu(mem_data),
  .if_id_reg_load(1'b1),
  .mem_resp(dcache_resp),
  .mem_rdata_cpu(mem_rdata),
  
  .cache_state_out(cache_state_out),
  .cache_hit(cache_hit)
);

endmodule