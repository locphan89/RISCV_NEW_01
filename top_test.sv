import rv32i_types::*;
module top_test
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
    output logic [DATA_WIDTH-1:0]   wb_result
);

	//logic [DATA_WIDTH-1:0]   mem_addr;
	logic [8-1:0]            ex_rd1;
   logic [8-1:0]            ex_rd2;
	
	logic [INST_WIDTH-1:0]   if_inst;
	
	logic [DATA_WIDTH-1:0]   id_rsb;
   logic [DATA_WIDTH-1:0]   id_rtb;
	
	logic [255:0] pmem_wdata;

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
  .mem_read(cpu_mem_rd),
  .mem_write(cpu_mem_wr),
  .mem_byte_enable_cpu(4'b1111),
  .mem_address(mem_addr),
  .mem_wdata_cpu(mem_data),
  .if_id_reg_load(1'b1),
  .mem_resp(dcache_resp),
  .mem_rdata_cpu(mem_rdata)
);

simple_pmem simple_pmem_0(
    .i_clk,
    .rst_n,
    
    // PMEM interface
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .pmem_address(pmem_address),
    .pmem_wdata(pmem_wdata),
    .pmem_rdata(pmem_rdata),
    .pmem_resp(pmem_resp)
);

endmodule