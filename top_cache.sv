import rv32i_types::*;
module top_cache
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
    //output logic [INST_WIDTH-1:0]   if_inst,

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
  input logic                        pmem_resp,
  //input logic [255:0]                pmem_rdata,
  output logic [31:0]                pmem_address,
  //output logic [255:0]               pmem_wdata,
  output logic                       pmem_read,
  output logic                       pmem_write,
  
   output logic [1:0] cache_state_out,
	
	output logic cache_hit
);

	//logic [DATA_WIDTH-1:0]   mem_addr;
	logic [8-1:0]            ex_rd1;
   logic [8-1:0]            ex_rd2;
	
	logic [INST_WIDTH-1:0]   if_inst;
	
	logic [DATA_WIDTH-1:0]   id_rsb;
   logic [DATA_WIDTH-1:0]   id_rtb;
	
	logic [255:0] pmem_wdata;
	

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

	/*top_5stages_cache top_5stages_cache_0
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
);*/

	logic sb_cache_resp;
   assign sb_cache_resp	= dcache_resp || sb_hit || (mem_mem_wr & sb_ready);

top_5stages_cache top_5stages_cache_0
(
    .i_clk,
    .rst_n,
	 
	 .dcache_resp(sb_cache_resp),
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


logic [255:0] temp;
assign temp = {8{32'd00000020}};

logic [DATA_WIDTH-1:0] cache_rdata, sb_rdata, cache_drain_addr, cache_drain_data;
logic                  sb_hit;
logic                  sb_ready;
logic [3:0]            cache_drain_be;
logic                  cache_drain_valid;


/*assign mem_rdata = sb_hit ? sb_rdata : cache_rdata;

assign cache_drain_ready = (cache_state_out == 2'b00) || cache_hit;

store_buffer_fix #(
    .DEPTH (4),
	 .ADDR_WIDTH(ADDR_WIDTH),
	 .DATA_WIDTH(DATA_WIDTH)
)store_buffer_0 (
    .i_clk,
    .rst_n,

    // ===== CPU STORE =====
    .cpu_sw_valid(mem_mem_wr),
    .cpu_sw_addr(mem_addr),
    .cpu_sw_data(mem_data),
    .cpu_sw_be(4'b1111),
    .cpu_sw_ready(sb_ready),

    // ===== CPU LOAD =====
    .cpu_lw_valid(mem_mem_rd),
    .cpu_lw_addr(mem_addr),
    .cache_rdata(cache_rdata),
    .cpu_sb_hit(sb_hit),
    .cpu_sb_rdata(sb_rdata),

    // ===== Drain → cache =====
    .cache_drain_valid(cache_drain_valid),
    .cache_drain_addr(cache_drain_addr),
    .cache_drain_data(cache_drain_data),
    .cache_drain_be(cache_drain_be),
    .cache_drain_ready(cache_drain_ready)
);

p_d_cache p_d_cache_0

(
  .i_clk,
  .rst_n,
  // Physical memory signals 
  .pmem_resp(pmem_resp),
  .pmem_rdata(temp),
  .pmem_address(pmem_address),
  .pmem_wdata(pmem_wdata),
  .pmem_read(pmem_read),
  .pmem_write(pmem_write),

  // CPU memory signals 
  .mem_read(!sb_hit && mem_mem_rd),
  .mem_write(cache_drain_valid),
  .mem_byte_enable_cpu(cache_drain_be),
  .mem_address(cache_drain_valid ? cache_drain_addr : mem_addr),
  .mem_wdata_cpu(cache_drain_data),
  .if_id_reg_load(1'b1),
  .mem_resp(dcache_resp),
  .mem_rdata_cpu(cache_rdata),
  
  .cache_state_out(cache_state_out),
  .cache_hit(cache_hit)
);*/

p_d_cache p_d_cache_0

(
  .i_clk,
  .rst_n,
  // Physical memory signals 
  .pmem_resp(pmem_resp),
  .pmem_rdata(temp),
  .pmem_address(pmem_address),
  .pmem_wdata(pmem_wdata),
  .pmem_read(pmem_read),
  .pmem_write(pmem_write),

  // CPU memory signals 
  .mem_read(cpu_mem_rd),
  .mem_write(cpu_mem_wr),
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