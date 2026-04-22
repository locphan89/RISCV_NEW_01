import rv32i_types::*;
module top_5stages_cache
(
    input logic                     i_clk,
    input logic                     rst_n,
	 
	 input logic                     dcache_resp,
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
	 
	 /*output logic                    if_valid,
	 output logic                    if_ready,
	 output logic                    id_valid,
	 output logic                    id_ready,
	 output logic                    ex_ready,
	 output logic                    ex_valid,
	
	 output logic                    mem_valid,
	 output logic                    mem_ready,*/
	 
	 // FW debug
	 //output logic                    rs_ifid_match,
    //output logic                    rt_ifid_match,
    //output logic                    rs_ifex_match,
    //output logic                    rt_ifex_match,
    
    // IF Stage
    output logic [PC_WIDTH-1:0]     if_pc,
    output logic [INST_WIDTH-1:0]   if_inst,

    // ID Stage
    output logic [R_ADDR_WIDTH-1:0] id_wr_reg,
    output logic [R_ADDR_WIDTH-1:0] id_rs1,
	 output logic [R_ADDR_WIDTH-1:0] id_rs2,
	 //output logic [PC_WIDTH-1:0]     ex_branch_addr,
	 
	 output logic [DATA_WIDTH-1:0]   id_rsb,
    output logic [DATA_WIDTH-1:0]   id_rtb,
	 
	 output logic [R_ADDR_WIDTH-1:0] idex_wr_reg,
	 
	 output logic                    id_mem_wr_sig,
	 output logic                    id_jmp_sig,
	 output logic                    id_branch_sig,

    // EX Stage
    output logic [8-1:0]            ex_rd1,
    output logic [8-1:0]            ex_rd2,
    output logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
    output logic [DATA_WIDTH-1:0]   ex_alu_a,
    output logic [DATA_WIDTH-1:0]   ex_alu_b,
    output logic [DATA_WIDTH-1:0]   ex_alu_out,
	 
	 output logic                    ex_mem_rd,

    // MEM Stage
    output logic                    mem_mem_rd,
    output logic                    mem_mem_wr,
    output logic [DATA_WIDTH-1:0]    mem_addr,
    output logic [DATA_WIDTH-1:0]    mem_data,
    output logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
    input logic [DATA_WIDTH-1:0]   mem_rdata,

    // WB Stage
    output logic [R_ADDR_WIDTH-1:0] wb_wr_reg,
    output logic [DATA_WIDTH-1:0]   wb_result 
);

   //========================================================================
   // SIGNAL DECLARATIONS - Organized by Pipeline Stage
   //========================================================================
   //------------------------------------------------------------------------
   // Debug Signals
   //------------------------------------------------------------------------
	//logic [FW_ALU_WIDTH-1:0] fw_alu_a;
	//logic [FW_ALU_WIDTH-1:0] fw_alu_b;
	
	//logic                    fw_b1;
   //logic                    fw_b2;
	
	//logic                    stall;
   //logic                    stall_lw;
   //logic                    stall_lwlw;
   //logic                    stall_mem;
   //logic                    stall_beq;
	
	//logic [R_ADDR_WIDTH-1:0] id_wr_reg;
   //logic [R_ADDR_WIDTH-1:0] id_rs;
	
	//logic [DATA_WIDTH-1:0]   id_rsb;
   //logic [DATA_WIDTH-1:0]   id_rtb;
	 
	//logic [R_ADDR_WIDTH-1:0] idex_wr_reg;
	 
	//logic                    id_mem_wr_sig;
	//logic                    id_jmp_sig;
	//logic                    id_branch_sig;
	//logic                      branch_taken;
	
	//logic [8-1:0]            ex_rd1;
   //logic [8-1:0]            ex_rd2;
   //logic [R_ADDR_WIDTH-1:0] ex_wr_reg;
   //logic [DATA_WIDTH-1:0]   ex_alu_a;
   //logic [DATA_WIDTH-1:0]   ex_alu_b;
   //logic [DATA_WIDTH-1:0]   ex_alu_out;
	 
	//logic                    ex_mem_rd;
	
	//logic [DATA_WIDTH-1:0]   mem_rdata;
	
	//logic [DATA_WIDTH-1:0]   mem_addr;

	
	
	
	
	
	
   //------------------------------------------------------------------------
   // Common Signals
   //------------------------------------------------------------------------
   //logic                            i_sclk;
   //logic                            rs_ifid_match;
  // logic                            rt_ifid_match;
   //logic                            rs_ifex_match;
   //logic                            rt_ifex_match;
   
   //------------------------------------------------------------------------
   // IF Stage Signals
   //------------------------------------------------------------------------
   logic [PC_WIDTH-1:0]             if_pc_plus;

   ctrl_unit_sig                    if_cs;
   logic [OP_WIDTH-1:0]             if_op;
	
	logic [R_ADDR_WIDTH-1:0]         if_rs1;
	assign                           if_rs1 = if_inst[19:15];
	
	logic [R_ADDR_WIDTH-1:0]         if_rs2;
	assign                           if_rs2 = if_inst[24:20];
	
   
   //------------------------------------------------------------------------
   // ID Stage Signals (outputs from IF/ID pipeline register)
   //------------------------------------------------------------------------
   logic [PC_WIDTH-1:0]             id_pc;
   logic [INST_WIDTH-1:0]           id_inst;
   logic [PC_WIDTH-1:0]             id_branch_addr;
   logic [PC_WIDTH-1:0]             id_jmp_addr;
   ctrl_unit_sig                    id_cs;
   logic                            id_rd_wr_same_dest_a;
   logic                            id_rd_wr_same_dest_b;
	
   
   // ID Stage internal signals
   logic [DATA_WIDTH-1:0]           id_imm;
   //logic [R_ADDR_WIDTH-1:0]         id_rt;
   logic [DATA_WIDTH-1:0]           id_wdata;
   logic                            id_wren;
   logic [DATA_WIDTH-1:0]           id_rd1;
   logic [DATA_WIDTH-1:0]           id_rd2;
   //logic [DATA_WIDTH-1:0]           id_rsb;
   //logic [DATA_WIDTH-1:0]           id_rtb;
   logic [ALUOP_WIDTH-1:0]          id_aluop;
   logic [FUNCT3_WIDTH-1:0]          id_funct3;
   logic [OP_WIDTH-1:0]             id_op;
   logic [ALUC_WIDTH-1:0]           id_aluc;
   ex_ctrl_unit_sig                 id_cs_stall;

   //logic                            id_branch_taken;

   assign                           jmp_taken = id_cs.jmp_sig;
	
   
   //------------------------------------------------------------------------
   // EX Stage Signals (outputs from ID/EX pipeline register)
   //------------------------------------------------------------------------
   ex_ctrl_unit_sig                 ex_cs;

   logic [DATA_WIDTH-1:0]           ex_imm;

	
	//logic [DATA_WIDTH-1:0]           ex_rd1;
   //logic [DATA_WIDTH-1:0]           ex_rd2;
   
   // EX Stage internal signals
   logic [R_ADDR_WIDTH-1:0]         ex_rs;
   logic [DATA_WIDTH-1:0]           ex_alu_result;
	assign                           ex_alu_out = ex_alu_result;
   logic [DATA_WIDTH-1:0]           ex_fw_b;
   mem_ctrl_unit_sig                exmem_cs;
	
	assign                           ex_mem_rd = ex_cs.mem_rd_sig;
   
   //------------------------------------------------------------------------
   // MEM Stage Signals (outputs from EX/MEM pipeline register)
   //------------------------------------------------------------------------
   mem_ctrl_unit_sig                mem_cs;
	
	assign                           mem_mem_rd =  mem_cs.mem_rd_sig;
	assign                           mem_mem_wr =  mem_cs.mem_wr_sig;
   
   // MEM Stage internal signals
   wb_ctrl_unit_sig                 memwb_cs;
   
   //------------------------------------------------------------------------
   // WB Stage Signals (outputs from MEM/WB pipeline register)
   //------------------------------------------------------------------------
   wb_ctrl_unit_sig                 wb_cs;
   logic [DATA_WIDTH-1:0]           wb_rdata;
   logic [DATA_WIDTH-1:0]           wb_addr;

   //========================================================================
   // COMBINATIONAL LOGIC & MODULE INSTANTIATIONS
   //========================================================================
   
   //assign i_sclk = i_clk | stall;

   //------------------------------------------------------------------------
   // Stall Unit
   //------------------------------------------------------------------------
	logic                    if_valid;
	logic                    if_ready;
	logic                    id_valid;
	logic                    id_ready;
	logic                    ex_valid;
	logic                    ex_ready;
	
	logic                    mem_valid;
	logic                    mem_ready;
	
	
	
	
   stall_unit
    stall_unit_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .if_rs(if_rs1),
       .if_rt(if_rs2),
       .if_mem_rd(if_cs.mem_rd_sig),
       .if_jmp(if_cs.jmp_sig),
       .if_branch(if_cs.branch_sig),
       .id_wr_reg(idex_wr_reg), //-------------------HERRE---------
       .id_mem_rd(id_cs.mem_rd_sig),
       .ex_wr_reg(ex_wr_reg),
       .ex_mem_rd(ex_mem_rd),
       .stall_lw(stall_lw),
       .stall_lwlw(stall_lwlw),
       .stall(stall),
       .stall_mem(stall_mem),
       .stall_beq(stall_beq)
   );

   //------------------------------------------------------------------------
   // ALU Forwarding Unit
   //------------------------------------------------------------------------
	logic [FW_ALU_WIDTH-1:0] id_fw_alu_a;
	logic [FW_ALU_WIDTH-1:0] id_fw_alu_b;
	
	logic rs1_idex_match;
	//assign rs_idex_match =  ~|(id_rs ^ ex_wr_reg);
	assign rs1_idex_match =  (id_rs1 == ex_wr_reg);
	
	
	logic rs2_idex_match;
	//assign rt_idex_match =  ~|(id_rt ^ ex_wr_reg);
	assign rs2_idex_match =  (id_rs2 == ex_wr_reg);
	
	logic rs1_idmem_match;
	//assign rs1_idmem_match =  ~|(id_rs1 ^ mem_wr_reg);
	assign rs1_idmem_match =  (id_rs1 == mem_wr_reg);
	
	logic rs2_idmem_match;
	//assign rs2_idmem_match =  ~|(id_rs2 ^ mem_wr_reg);
	assign rs2_idmem_match =  (id_rs2 == mem_wr_reg);
	
   forward_alu_unit 
    forward_alu_unit_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .id_reg_wr_sig(ex_cs.reg_wr_sig),
       .id_mem_rd(ex_cs.mem_rd_sig),
       .ex_reg_wr_sig(mem_cs.reg_wr_sig),
       .rs_ifid_match(rs1_idex_match),
       .rt_ifid_match(rs2_idex_match),
       .rs_ifex_match(rs1_idmem_match),
       .rt_ifex_match(rs2_idmem_match),
		 //.idex_wr_reg(idex_wr_reg),
       .fw_alu_a(fw_alu_a),
       .fw_alu_b(fw_alu_b)
   );

   //------------------------------------------------------------------------
   // Branch Forwarding Unit
   //------------------------------------------------------------------------
	
	forward_branch_nopipe_unit_5stage
    forward_branch_nopipe_unit_6stage_0 (
       .mem_wr_reg(mem_wr_reg),
		 .mem_is_rtype(mem_is_rtype),
		 
		 .ex_imm2reg_sig(ex_cs.imm2reg_sig),
		 .ex_pc2reg_sig(ex_cs.pc2reg_sig),
		 .ex_wr_reg(ex_wr_reg),
		 
       .id_rs1(id_rs1),
		 .id_rs2(id_rs2),
       .fw_b1(fw_b1),
       .fw_b2(fw_b2)
   );


   //========================================================================
   // IF STAGE
   //========================================================================
   
   assign if_op = if_inst[2:0];
   assign if_pc_plus = if_pc + PC_WIDTH'(1);
	assign if_valid = ~flush;
   
   //------------------------------------------------------------------------
   // PC Target
   //------------------------------------------------------------------------
   /*pc_target 
    pc_target_0 (
       .i_clk(i_sclk),
       .rst_n(rst_n),
       .if_pc_plus_i(if_pc_plus),
       .id_branch_addr_i(id_branch_addr),
       .id_jmp_addr_i(id_jmp_addr),
       .id_branch_sig_i(id_branch_taken),
       .id_jmp_sig_i(id_cs.jmp_sig),
       .if_pc_o(if_pc)
   );*/
	logic                            ex_branch_taken;
	logic [PC_WIDTH-1:0]             ex_branch_addr;
	
	pc_target_vr 
    pc_target_vr_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .if_pc_plus_i(if_pc_plus),
       .branch_target(ex_branch_addr),
       .jmp_target(id_jmp_addr),
       .branch_taken(ex_branch_taken),
       .jmp_taken(jmp_taken),
       .if_pc_o(if_pc),
		 .if_ready_i(if_ready)
   );
   
   //------------------------------------------------------------------------
   // Instruction Memory
   //------------------------------------------------------------------------
   imem 
    imem_0 (
       .if_inst_o(if_inst),
       .if_pc_i(if_pc)
   );
   
   
   //------------------------------------------------------------------------
   // Control Unit
   //------------------------------------------------------------------------
   control_unit 
    control_unit_0 (
       .if_op_i(if_op),
		 .if_funct3_i(if_inst[14:12]),  // 22/03
       .if_ctrl_sig_o(if_cs)
   );
   
   //------------------------------------------------------------------------
   // IF/ID Pipeline Register
   //------------------------------------------------------------------------
   /*ifid_pipe_reg 
    ifid_pipe_reg_0 (
       .flush_i(flush),
       .i_clk(i_sclk),
       .rst_n(rst_n),
       .if_inst_i(if_inst),
       .if_pc_i(if_pc),
       .if_branch_addr_i(if_branch_addr),
       .if_ctrl_sig_i(if_cs),
       //.ex_wr_reg_i(ex_wr_reg),
       .id_inst_o(id_inst),
       .id_pc_o(id_pc),
       .id_branch_addr_o(id_branch_addr),
       //.rd_wr_same_dest_a_o(id_rd_wr_same_dest_a),
       //.rd_wr_same_dest_b_o(id_rd_wr_same_dest_b),
       .id_ctrl_sig_o(id_cs)
   );*/
	
	ifid_pipe_reg_vr 
    ifid_pipe_reg_vr_0 (
       .flush_i(flush),
       .i_clk(i_clk),
       .rst_n(rst_n),
       .if_inst_i(if_inst),
       .if_pc_i(if_pc),
       .if_branch_addr_i('0),
       .if_ctrl_sig_i(if_cs),
       .id_inst_o(id_inst),
       .id_pc_o(id_pc),
       //.id_branch_addr_o(id_branch_addr),
       .id_ctrl_sig_o(id_cs),
		 
		 .if_valid_i(if_valid),
		 .if_ready_o(if_ready),
		 .id_valid_o(id_valid),
		 .id_ready_i(id_ready)
   );

   //========================================================================
   // ID STAGE
   //========================================================================
   rv32i_word id_bimm;
	rv32i_word id_jimm;
	//rv32i_word id_uimm;
	
	//rv32i_word ex_uimm;
	
	immediate_gen 
	immediate_gen_0 (
		.inst(id_inst),
		.imm(id_imm),
		.b_imm(id_bimm),
		.j_imm(id_jimm)
		);
		
	/*immediate_gen2
	immediate_gen2_0(
    .inst(id_inst),
    .imm(id_imm),
	 .b_imm(id_bimm),
	 .j_imm(id_jimm),
	 .u_imm(id_uimm)
	);*/
	/*always_ff @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			ex_uimm <= '0;
		end else begin
			ex_uimm <= id_uimm;
		end
	end*/
   
   //------------------------------------------------------------------------
   // Jump, Branch Address Calculation
   //------------------------------------------------------------------------
   br_jmp_target 
    br_jmp_target_0 (
       .if_pc_plus_i(id_pc),
       .if_bimm_i(id_bimm),
		 .if_jimm_i(id_jimm),
       .if_branch_addr_o(id_branch_addr),
		 .if_jump_addr_o(id_jmp_addr)
   );
		
   
   //------------------------------------------------------------------------
   // Register File Connections
   //------------------------------------------------------------------------
   assign id_rs1 = id_inst[19:15];
   assign id_rs2 = id_inst[24:20];
   assign id_wdata = wb_result;
   assign id_wren = wb_cs.reg_wr_sig;
   
   reg_file 
    reg_file_0 (
       .i_clk(i_clk),
       //.rst_n(rst_n),
       .raddr0_i(id_rs1),
       .raddr1_i(id_rs2),
       .waddr_i(wb_wr_reg),
       .wdata_i(id_wdata),
       .wren_i(id_wren),
       .rdata0_o(id_rd1),
       .rdata1_o(id_rd2)
   );

   //------------------------------------------------------------------------
   // Branch Forwarding
   //------------------------------------------------------------------------
	
	logic [DATA_WIDTH-1:0] ex_lui_result;
	assign               ex_lui_result = ex_imm;
	
	logic [PC_WIDTH-1:0] ex_jal_result;
	
	assign id_rsb =  (fw_b1[3]) ? ex_lui_result :  // Forward từ EX
						  (fw_b1[4]) ? ex_jal_result :
						  (fw_b1[2]) ? mem_addr      :  // Forward từ MEM
                                 id_rd1;          // Không forward

	assign id_rtb =  (fw_b2[3]) ? ex_lui_result :  // Forward từ EX
						  (fw_b2[4]) ? ex_jal_result :
						  (fw_b2[2]) ? mem_addr      :  // Forward từ MEM
                                 id_rd2;          // Không forward
   
   //------------------------------------------------------------------------
   // ALU Control
   //------------------------------------------------------------------------
   assign 				 id_funct3  = id_inst[14:12];
	assign 				 id_op      = id_inst[2:0];
	
	logic              id_is_rtype;
   assign             id_is_rtype = (~|id_op);
   
   //------------------------------------------------------------------------
   // Write Register Destination
   //------------------------------------------------------------------------
	assign id_mem_wr_sig = id_cs.mem_wr_sig;
	assign id_jmp_sig    = id_cs.jmp_sig;
	assign id_branch_sig = id_cs.branch_sig;
	
	assign id_wr_reg   = id_inst[11:7];
	
   assign idex_wr_reg = (stall | stall_by_cache | id_mem_wr_sig | id_jmp_sig | id_branch_sig) ? 
                        '0 : id_wr_reg; 
   
   //------------------------------------------------------------------------
   // Branch Decision & Flush
   //------------------------------------------------------------------------
   
	logic id_branch_result;
	
	branch_cmp
	branch_cmp_0 (
			.cmpop(id_funct3),
			.a(id_rsb),
			.b(id_rtb),
			.cmp_result(id_branch_result)
			);
			
	assign id_branch_taken = id_branch_result && id_branch_sig;
	
	assign flush = id_cs.jmp_sig | ex_branch_taken;
	
   
   //------------------------------------------------------------------------
   // ID/EX Pipeline Register
   //------------------------------------------------------------------------
	//assign id_ready = ~stall;
	
	ex_ctrl_unit_sig                 idex_cs;
	assign idex_cs.mem_rd_sig  = id_cs.mem_rd_sig;
   assign idex_cs.mem_wr_sig  = id_cs.mem_wr_sig;
   assign idex_cs.alu_src2_sig = id_cs.alu_src2_sig;
   assign idex_cs.reg_wr_sig  = id_cs.reg_wr_sig;
   assign idex_cs.mem2reg_sig = id_cs.mem2reg_sig;
	
	assign idex_cs.alu_op_sig = id_cs.alu_op_sig;
	
	assign idex_cs.pc2reg_sig = id_cs.pc2reg_sig;
	assign idex_cs.imm2reg_sig = id_cs.imm2reg_sig;
	
	logic [PC_WIDTH-1:0] id_jal_result;
	assign               id_jal_result = id_pc + (PC_WIDTH)'(1'b1);
	
	logic [FUNCT3_WIDTH-1:0] ex_funct3;
	logic ex_is_rtype;
	
	
	idex_pipe_reg_beq_rv_cache 
    idex_pipe_reg_beq_rv_cache_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
		 .ex_flush(ex_branch_taken), // id_branch_taken
       .id_cs(idex_cs), //******id_cs_stall
       .id_rd1(id_rd1),
       .id_rd2(id_rd2),
       .id_imm(id_imm),
       .id_wr_reg(idex_wr_reg), //**************idex_wr_reg
		 
		 .id_branch_taken(id_branch_taken),
		 .id_jal_result(id_jal_result),
		 
		 .id_funct3(id_funct3),
		 .ex_funct3(ex_funct3),
		 
       .ex_cs(ex_cs),
       .ex_rd1(ex_rd1),
       .ex_rd2(ex_rd2),
       .ex_imm(ex_imm),
       .ex_wr_reg(ex_wr_reg),

		 .ex_branch_taken(ex_branch_taken),
		 .ex_branch_addr(ex_branch_addr),
		 .id_branch_addr(id_branch_addr),
		 .ex_jal_result(ex_jal_result),
		 .id_is_rtype(id_is_rtype),
		 .ex_is_rtype(ex_is_rtype),
		
		 
		 .id_valid_i(id_valid),
		 .id_ready_o(id_ready),
		 
		 .ex_valid_o(ex_valid),
		 .ex_ready_i(ex_ready),
		 
		 .id_hazard(stall)
   );

   //========================================================================
   // EX STAGE
   //========================================================================
   
   //------------------------------------------------------------------------
   // ALU Input Target (Forwarding Mux)
   //------------------------------------------------------------------------
	logic ex_alu_src2_sig;
	assign ex_alu_src2_sig = ex_cs.alu_src2_sig;
	
   alu_in_target 
    alu_in_target_0 (
       .ex_rf_rd1(ex_rd1),
       .ex_rf_rd2(ex_rd2),
       .mem_addr(mem_addr),
       .wb_result(wb_result),
       .ex_imm(ex_imm),
       .fw_alu_a(fw_alu_a),
       .fw_alu_b(fw_alu_b),
       .ex_alu_src_sig(ex_alu_src2_sig),
       .ex_alu_tar_a(ex_alu_a),
       .ex_alu_tar_b(ex_alu_b),
       .ex_fw_b(ex_fw_b)
   );

   //------------------------------------------------------------------------
   // ALU
   //------------------------------------------------------------------------
   alu 
    alu_0 (
       .ex_a_i(ex_alu_a),
       .ex_b_i(ex_alu_b),
       .ex_aluc_i(ex_cs.alu_op_sig), //*****************22/03
       .ex_alu_o(ex_alu_result)
   );
   
   //------------------------------------------------------------------------
   // Control Signal Propagation to MEM Stage
   //------------------------------------------------------------------------
   assign exmem_cs.mem_rd_sig  = ex_cs.mem_rd_sig;
   assign exmem_cs.mem_wr_sig  = ex_cs.mem_wr_sig;
   assign exmem_cs.mem2reg_sig = ex_cs.mem2reg_sig;
   assign exmem_cs.reg_wr_sig  = ex_cs.reg_wr_sig;
	
	assign exmem_cs.pc2reg_sig  = ex_cs.pc2reg_sig;
	assign exmem_cs.imm2reg_sig = ex_cs.imm2reg_sig;
	
	logic [PC_WIDTH-1:0]    mem_jal_result;
	rv32i_word              mem_imm;
	logic mem_is_rtype;
   
   //------------------------------------------------------------------------
   // EX/MEM Pipeline Register
   //------------------------------------------------------------------------
	//assign ex_valid = ~ex_branch_taken & id_valid & id_ready;
   /*exmem_pipe_reg_rv 
    exmem_pipe_reg_rv_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .ex_cs(exmem_cs),
       .ex_b(ex_fw_b),
       .ex_alu_out(ex_alu_result),
       .ex_wr_reg(ex_wr_reg),
       .mem_cs(mem_cs),
       .mem_addr(mem_addr),
       .mem_data(mem_data),
       .mem_wr_reg(mem_wr_reg),
		 .ex_valid_i(ex_valid)
   );*/
	
	exmem_pipe_reg_rv_cache 
    exmem_pipe_reg_rv_cache_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .ex_cs(exmem_cs),
       .ex_b(ex_fw_b),
		 .ex_alu_out(ex_alu_result),
       .ex_wr_reg(ex_wr_reg),
       .mem_cs(mem_cs),
       .mem_data(mem_data),
       .mem_wr_reg(mem_wr_reg),
		 .mem_addr(mem_addr),
		 
		 
		 .ex2_jal_result(ex_jal_result),
		 .mem_jal_result(mem_jal_result),
		 .ex2_imm(ex_imm),
		 .mem_imm(mem_imm),
		 
		 .ex2_is_rtype(ex_is_rtype),
		 .mem_is_rtype(mem_is_rtype),
		 
		 .ex_valid_i(ex_valid),
		 .ex_ready_o(ex_ready),
		 .mem_ready_i(mem_ready),
		 .mem_valid_o(mem_valid)
   );

   //========================================================================
   // MEM STAGE
   //========================================================================
   
   //------------------------------------------------------------------------
   // Control Signal Propagation to WB Stage
   //------------------------------------------------------------------------
   assign memwb_cs.mem2reg_sig = mem_cs.mem2reg_sig;
   assign memwb_cs.reg_wr_sig  = mem_cs.reg_wr_sig;
	
	assign memwb_cs.pc2reg_sig  = mem_cs.pc2reg_sig;
	assign memwb_cs.imm2reg_sig = mem_cs.imm2reg_sig;
	
	//logic stall_by_cache;
	assign stall_by_cache = ~dcache_resp & (mem_cs.mem_rd_sig | mem_cs.mem_wr_sig);
	
	//assign cpu_mem_rd = stall_by_cache ? 1'b0 : mem_cs.mem_rd_sig;
	//assign cpu_mem_wr = stall_by_cache ? 1'b0 : mem_cs.mem_wr_sig;
	
	/*always_ff @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			cpu_mem_rd <= 1'b0;
			cpu_mem_wr <= 1'b0;*/
	
	assign cpu_mem_rd = mem_mem_rd;
	assign cpu_mem_wr = mem_mem_wr;
   
   //------------------------------------------------------------------------
   // Data Memory
   //------------------------------------------------------------------------
   /*dmem 
    dmem_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .mem_wr_sig(mem_cs.mem_wr_sig),
       .mem_rd_sig(mem_cs.mem_rd_sig), //****************HERE****************
       .mem_addr(mem_addr),
       .mem_wdata(mem_data),
       .mem_rdata_o(mem_rdata)
   );*/
   
   //------------------------------------------------------------------------
   // MEM/WB Pipeline Register
   //------------------------------------------------------------------------
	 logic [PC_WIDTH-1:0]    wb_jal_result;
	 rv32i_word              wb_imm;
	
	memwb_pipe_reg_cache 
    memwb_pipe_reg_cache_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .mem_cs(memwb_cs),
       .mem_rd_dmem(mem_rdata),
       .mem_addr(mem_addr),
       .mem_wr_reg(mem_wr_reg),
       .wb_cs(wb_cs),
       .wb_rd_dmem(wb_rdata),
       .wb_addr(wb_addr),
       .wb_wr_reg(wb_wr_reg),
		 .wb_jal_result(wb_jal_result),
		 .mem_jal_result(mem_jal_result),
		 .wb_imm(wb_imm),
		 .mem_imm(mem_imm),
		 
		 .stall_by_cache(stall_by_cache),
		 .mem_valid_i(mem_valid),
		 .mem_ready_o(mem_ready)
   );

   //========================================================================
   // WB STAGE
   //========================================================================
   
   //------------------------------------------------------------------------
   // Write Back Data Selection
   //------------------------------------------------------------------------
   //assign wb_result = wb_cs.mem2reg_sig ? wb_rdata : wb_addr;
	
	assign wb_result = wb_cs.mem2reg_sig ? wb_rdata      : 
							 wb_cs.pc2reg_sig  ? wb_jal_result :
							 wb_cs.imm2reg_sig ? wb_imm        :
							 wb_addr;

endmodule // top
