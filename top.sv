import rv32i_types::*;
module top 
  
(
    input logic                     i_clk,
    input logic                     rst_n,

    // Control siganls
    output logic                    flush,
    output logic                    jmp_taken,
    //output logic                    branch_taken,
    output logic [FW_ALU_WIDTH-1:0] fw_alu_a,
    output logic [FW_ALU_WIDTH-1:0] fw_alu_b,
    output logic [4:0]              fw_b1, //**************
    output logic [4:0]              fw_b2, //**************
	 

    // Stall signals
    /*output logic                    lw_beq_hazard,
    output logic                    alu_beq_hazard,
    output logic                    lw_alu_hazard,
    output logic                    alu_alu_hazard,
	 
	 output logic                    nxt_alu_beq_haz,
	 output logic                    nxt_lw_alu_haz,*/
    
    // IF Stage
    output logic [PC_WIDTH-1:0]     if_pc,
    output logic [INST_WIDTH-1:0]   if_inst,
	 
	 //output logic [PC_WIDTH-1:0]     if_branch_addr,

    // ID Stage
    output logic [R_ADDR_WIDTH-1:0] id_wr_reg,
    output logic [R_ADDR_WIDTH-1:0] id_rs1,
	 output logic [R_ADDR_WIDTH-1:0] id_rs2,
	 output logic [PC_WIDTH-1:0]     ex_branch_addr,
	 
	 //output logic [DATA_WIDTH-1:0]   id_rs1b,
	//output logic [DATA_WIDTH-1:0]   id_rs2b,
	 
	 output logic [R_ADDR_WIDTH-1:0] idex_wr_reg,
	 
	 
	 output logic                    id_jmp_sig,
	 output logic                    id_branch_sig,
	 
	 output logic                    id_reg_wr_sig,
	 output logic                    id_mem_rd_sig,

    // EX Stage
    output logic [8-1:0]            ex1_rd1,
    output logic [8-1:0]            ex1_rd2,
    output logic [R_ADDR_WIDTH-1:0] ex1_wr_reg,
    output logic [DATA_WIDTH-1:0]   ex1_alu_a,
    output logic [DATA_WIDTH-1:0]   ex1_alu_b,
	 //output logic                    ex1_mem_wr_sig,
	 output logic                    ex1_mem_rd_sig,
	 output logic                    ex1_reg_wr_sig,
	 
	 output logic                    ex2_mem_rd_sig,
	// output logic [DATA_WIDTH-1:0]   ex2_alu_result,

    // MEM Stage
    output logic                    mem_mem_rd,
    output logic                    mem_mem_wr,
    //output logic [DATA_WIDTH-1:0]   mem_addr,
    //output logic [DATA_WIDTH-1:0]   mem_data,
    output logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
    output logic [DATA_WIDTH-1:0]   mem_rdata,
	// output logic [DATA_WIDTH-1:0]   mem_result,

    // WB Stage
    output logic [R_ADDR_WIDTH-1:0] wb_wr_reg,
    output logic [DATA_WIDTH-1:0]   wb_result
	
	 // Handshake
	 //output logic                    if_valid,
	 //output logic                    if_ready,
	 //output logic                    id_valid,
	 //output logic                    id_ready,
	 //output logic                    ex1_valid
	 //output logic                    ex1_ready
);

   //========================================================================
   // SIGNAL DECLARATIONS - Organized by Pipeline Stage
   //========================================================================
   //------------------------------------------------------------------------
   // Debug Signals
   //------------------------------------------------------------------------
	//logic [FW_ALU_WIDTH-1:0] fw_alu_a;
	//logic [FW_ALU_WIDTH-1:0] fw_alu_b;
	
	//logic  [1:0]                  fw_b1;
   //logic  [1:0]                  fw_b2;
	
	//logic                    stall;
   //logic                    stall_lw;
   //logic                    stall_lwlw;
   //logic                    stall_mem;
   //logic                    stall_beq;
	
	//logic [R_ADDR_WIDTH-1:0] id_wr_reg;
   //logic [R_ADDR_WIDTH-1:0] id_rs1;
	
	logic [DATA_WIDTH-1:0]   id_rs1b;
   logic [DATA_WIDTH-1:0]   id_rs2b;
	 
	//logic [R_ADDR_WIDTH-1:0] idex_wr_reg;
	 
	logic                    id_mem_wr_sig;
	//logic                    id_jmp_sig;
	//logic                    id_branch_sig;
	//logic                      branch_taken;
	
	//logic [8-1:0]            ex1_rd1;
   //logic [8-1:0]            ex1_rd2;
   //logic [R_ADDR_WIDTH-1:0] ex_wr_reg;
   //logic [DATA_WIDTH-1:0]   ex_alu_a;
   //logic [DATA_WIDTH-1:0]   ex_alu_b;
   //logic [DATA_WIDTH-1:0]   ex_alu_out;
	 
	//logic                    ex_mem_rd;
	
	logic [DATA_WIDTH-1:0]   mem_data;
	
	logic [DATA_WIDTH-1:0]   mem_addr;

	

   //------------------------------------------------------------------------
   // Common Signals
   //------------------------------------------------------------------------
   //logic                            i_sclk;
   //logic                            rs_ifid_match;
  // logic                            rt_ifid_match;
   //logic                            rs_ifex_match;
   //logic                            rt_ifex_match;
	
	 logic                    lw_beq_hazard;
    logic                    alu_beq_hazard;
    logic                    lw_alu_hazard;
    logic                    alu_alu_hazard;
	 
	 logic                    nxt_alu_beq_haz;
	 logic                    nxt_lw_alu_haz;
	 
	 logic                    if_valid;
	 logic                    if_ready;
	 logic                    id_valid;
	 logic                    id_ready;
	 logic                    ex1_valid;
   
   //------------------------------------------------------------------------
   // IF Stage Signals
   //------------------------------------------------------------------------
   logic [PC_WIDTH-1:0]             if_pc_plus;
   ctrl_unit_sig                    if_cs;
   logic [OP_WIDTH-1:0]             if_op;
	
	//logic                            if_valid;
	//logic                            if_ready;
	
	logic [R_ADDR_WIDTH-1:0]         if_rs1;
	assign                           if_rs1 = if_inst[19:15];
	
	logic [R_ADDR_WIDTH-1:0]         if_rs2;
	assign                           if_rs2 = if_inst[24:20];
	
	logic                            if_reg_wr_sig;
	assign                           if_reg_wr_sig = if_cs.reg_wr_sig;
	
	logic                            if_branch_sig;
	assign                           if_branch_sig = if_cs.branch_sig;
   
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
   //logic [R_ADDR_WIDTH-1:0]         id_rs2;
   logic [DATA_WIDTH-1:0]           id_wdata;
   logic                            id_wren;
   logic [DATA_WIDTH-1:0]           id_rd1;
   logic [DATA_WIDTH-1:0]           id_rd2;
   //logic [DATA_WIDTH-1:0]           id_rs1b;
   //logic [DATA_WIDTH-1:0]           id_rs2b;
  // logic [ALUOP_WIDTH-1:0]          id_aluop;
   logic [FUNCT3_WIDTH-1:0]          id_funct3;
   logic [OP_WIDTH-1:0]             id_op;
   logic [ALUC_WIDTH-1:0]           id_aluc;
   //ex_ctrl_unit_sig                 id_cs_stall;
   //logic [R_ADDR_WIDTH-1:0]         idex_wr_reg;
   

   assign                           jmp_taken = id_cs.jmp_sig;
   logic                            id_branch_taken;
   
   //logic                            id_valid;
	//logic                            id_ready;
	
	assign                           id_reg_wr_sig = id_cs.reg_wr_sig;
	
   //------------------------------------------------------------------------
   // EX1 Stage Signals (outputs from ID/EX pipeline register)
   //------------------------------------------------------------------------
   ex_ctrl_unit_sig                 ex1_cs;
   logic [ALUC_WIDTH-1:0]           ex1_aluc;
   logic [DATA_WIDTH-1:0]           ex1_imm;
   
	
   logic [DATA_WIDTH-1:0]           ex1_fw_b;
	
	//logic                            ex1_mem_rd;
	assign                           ex1_mem_rd_sig = ex1_cs.mem_rd_sig;

	logic                            ex1_branch_taken;
	
	//logic                            ex1_valid;
	//logic                            ex1_ready;
	
	//logic [R_ADDR_WIDTH-1:0]         ex1_rs;
	//logic [R_ADDR_WIDTH-1:0]         ex1_rt;
	
	//logic                            ex1_reg_wr_sig;
   assign                           ex1_reg_wr_sig	= ex1_cs.reg_wr_sig;
	
	//------------------------------------------------------------------------
   // EX2 Stage Signals (outputs from EX1-EX2 pipeline register)
   //------------------------------------------------------------------------
	logic [DATA_WIDTH-1:0]           ex2_alu_result;
	logic [DATA_WIDTH-1:0]           ex2_alu_a, ex2_alu_b;
	logic [ALUC_WIDTH-1:0]           ex2_aluc;
	ex_ctrl_unit_sig                 ex2_cs;
	logic [DATA_WIDTH-1:0]           ex2_fw_b;
	logic [R_ADDR_WIDTH-1:0]         ex2_wr_reg;
	
	assign                           ex2_mem_rd_sig = ex2_cs.mem_rd_sig;
	
	mem_ctrl_unit_sig                exmem_cs;
   
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


   //------------------------------------------------------------------------
   // ALU Forwarding Unit
   //------------------------------------------------------------------------
	logic [FW_ALU_WIDTH-1:0] id_fw_alu_a;
	logic [FW_ALU_WIDTH-1:0] id_fw_alu_b;
	
	logic rs_idex_match;
	assign rs_idex_match =  (id_rs1 == ex2_wr_reg);
	
	
	logic rt_idex_match;
	assign rt_idex_match =  (id_rs2 == ex2_wr_reg);
	
	logic rs_idmem_match;
	assign rs_idmem_match =  (id_rs1 == mem_wr_reg);
	
	logic rt_idmem_match;
	assign rt_idmem_match =  (id_rs2 == mem_wr_reg);
	
   forward_alu_unit 
    forward_alu_unit_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .id_reg_wr_sig(ex1_cs.reg_wr_sig),
       .id_mem_rd(ex1_cs.mem_rd_sig),
       .ex_reg_wr_sig(mem_cs.reg_wr_sig),
       .rs_ifid_match(rs_idex_match),
       .rt_ifid_match(rt_idex_match),
       .rs_ifex_match(rs_idmem_match),
       .rt_ifex_match(rt_idmem_match),
       .fw_alu_a(fw_alu_a),
       .fw_alu_b(fw_alu_b)
   );
	

   //------------------------------------------------------------------------
   // Branch Forwarding Unit
   //------------------------------------------------------------------------
	
	
	forward_branch_nopipe_unit_6stage
    forward_branch_nopipe_unit_6stage_0 (
       .mem_wr_reg(mem_wr_reg),
		 .mem_is_rtype(mem_is_rtype),
		 
		 .ex_imm2reg_sig(ex1_cs.imm2reg_sig),
		 .ex_pc2reg_sig(ex1_cs.pc2reg_sig),
		 .ex_wr_reg(ex1_wr_reg),
		 
		 .wb_wr_reg(wb_wr_reg),
		 .wb_mem2reg_sig(wb_cs.mem2reg_sig),
		 
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
   pc_target_vr 
    pc_target_vr_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .if_pc_plus_i(if_pc_plus),
       .branch_target(ex_branch_addr),
       .jmp_target(id_jmp_addr),
       .branch_taken(ex1_branch_taken),
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
       .if_ctrl_sig_o(if_cs)
   );
   
   //------------------------------------------------------------------------
   // IF/ID Pipeline Register
   //------------------------------------------------------------------------
   ifid_pipe_reg_vr 
    ifid_pipe_reg_vr_0 (
       .flush_i(flush),
       .i_clk(i_clk),
       .rst_n(rst_n),
       .if_inst_i(if_inst),
       .if_pc_i(if_pc),
       //.if_branch_addr_i(if_branch_addr),
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
	
	immediate_gen 
	immediate_gen_0 (
		.inst(id_inst),
		.imm(id_imm),
		.b_imm(id_bimm),
		.j_imm(id_jimm)
		);
	
	//------------------------------------------------------------------------
   // Branch Target Calculation
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
   assign 					id_rs1             = id_inst[19:15];
   assign 					id_rs2             = id_inst[24:20];
   assign 					id_wdata           = wb_result;

   assign 					id_wren            = wb_cs.reg_wr_sig;
   
   reg_file 
    reg_file_0 (
       .i_clk(i_clk),
       .raddr0_i(id_rs1),
       .raddr1_i(id_rs2),
       .waddr_i(wb_wr_reg), // **********************************************
       .wdata_i(id_wdata),
       .wren_i(id_wren),
       .rdata0_o(id_rd1),
       .rdata1_o(id_rd2)
   );

   //------------------------------------------------------------------------
   // Branch Forwarding
   //------------------------------------------------------------------------
	
	logic [DATA_WIDTH-1:0] ex_lui_result;
	assign               ex_lui_result = ex1_imm;
	
	logic [PC_WIDTH-1:0] ex_jal_result;
	
	assign id_rs1b = (fw_b1[3]) ? ex_lui_result :  // Forward từ EX
						  (fw_b1[4]) ? ex_jal_result :
						  (fw_b1[2]) ? mem_addr      :  // Forward từ MEM
						  (fw_b1[1]) ? wb_result     :  // Forward từ WB
                                 id_rd1;          // Không forward

	assign id_rs2b = (fw_b2[3]) ? ex_lui_result :  // Forward từ EX
						  (fw_b2[4]) ? ex_jal_result :
						  (fw_b2[2]) ? mem_addr      :  // Forward từ MEM
						  (fw_b2[1]) ? wb_result     :  // Forward từ WB
                                 id_rd2;          // Không forward
												  
   
   //------------------------------------------------------------------------
   // ALU Control
   //------------------------------------------------------------------------
	//logic [2:0] id_aluop;
  // assign				 id_aluop   = id_cs.alu_op_sig;
   assign 				 id_funct3  = id_inst[14:12];
	assign 				 id_op       = id_inst[2:0];
	
	logic              id_is_rtype;
   assign             id_is_rtype	= (~|id_op);
   

   //------------------------------------------------------------------------
   // Write Register Destination
   //------------------------------------------------------------------------
	assign id_mem_wr_sig = id_cs.mem_wr_sig;
	assign id_jmp_sig    = id_cs.jmp_sig;
	assign id_branch_sig = id_cs.branch_sig;
	assign id_mem_rd_sig = id_cs.mem_rd_sig;
	
	assign id_wr_reg   = id_inst[11:7];
   assign idex_wr_reg = ( id_mem_wr_sig | id_jmp_sig | id_branch_sig) ? 
                       '0 : id_wr_reg; 
   
   //------------------------------------------------------------------------
   // Branch Decision & Flush
   //------------------------------------------------------------------------
   
	logic id_branch_result;
	
	branch_cmp
	branch_cmp_0 (
			.cmpop(id_funct3),
			.a(id_rs1b),
			.b(id_rs2b),
			.cmp_result(id_branch_result)
			);
			
	assign id_branch_taken = id_branch_result && id_cs.branch_sig;
	
	assign flush = id_cs.jmp_sig | ex1_branch_taken;
	
	
   //------------------------------------------------------------------------
   // ID Hazard Detection 
	//		- alu_beq hazard
	//    - lw beq hazard
   //------------------------------------------------------------------------
	//logic lw_beq_hazard;
	//logic alu_beq_hazard;
	
	logic  nxt_lw_beq_haz, nxt_alu_alu_haz;
	
	id_hazard_detection_pipelined 
	id_hazard_detection_pipelined_0(
	 .i_clk(i_clk),
	 .rst_n(rst_n),

    .if_rs(if_rs1),
    .if_rt(if_rs2),
	 .if_branch(if_branch_sig),
	 .if_reg_wr_sig(if_reg_wr_sig),
	 
	 .id_rs(id_rs1),
    .id_rt(id_rs2),
    .id_wr_reg(id_wr_reg),
	 .id_mem_rd(id_mem_rd_sig),
	 .id_reg_wr_sig(id_reg_wr_sig),
	 .id_branch(id_cs.branch_sig),

	 .ex1_wr_reg(ex1_wr_reg),
	 .ex1_reg_wr_sig(ex1_reg_wr_sig),
	 .ex1_mem_rd(ex1_mem_rd_sig),
    
    .ex2_wr_reg(ex2_wr_reg),
    .ex2_mem_rd(ex2_mem_rd_sig),
	 //.ex2_reg_wr_sig(ex2_cs.reg_wr_sig),
	 
	 .mem_mem_rd(mem_cs.mem_rd_sig),
	 //.mem_wr_reg(mem_wr_reg),

    .lw_beq_hazard(lw_beq_hazard),    // LW followed by BEQ
    .alu_beq_hazard(alu_beq_hazard),   // ALU followed by BEQ
	 .lw_alu_hazard(lw_alu_hazard),
	 .alu_alu_hazard(alu_alu_hazard),
	 
	 .nxt_lw_beq_haz(nxt_lw_beq_haz),
	 .nxt_alu_beq_haz(nxt_alu_beq_haz),
	 .nxt_lw_alu_haz(nxt_lw_alu_haz),
	 .nxt_alu_alu_haz(nxt_alu_alu_haz)
	);  
	
	
	logic id_hazard;
	assign id_hazard = lw_beq_hazard | alu_beq_hazard | lw_alu_hazard | alu_alu_hazard;
											  
	assign id_ready = ~id_hazard;
	
	
   //------------------------------------------------------------------------
   // ID/EX Pipeline Register
   //------------------------------------------------------------------------
	ex_ctrl_unit_sig                 idex1_cs;
	assign idex1_cs.mem_rd_sig  = id_cs.mem_rd_sig;
   assign idex1_cs.mem_wr_sig  = id_cs.mem_wr_sig;
   assign idex1_cs.alu_src2_sig = id_cs.alu_src2_sig;
   assign idex1_cs.reg_wr_sig  = id_cs.reg_wr_sig;
   assign idex1_cs.mem2reg_sig = id_cs.mem2reg_sig;
	
	assign idex1_cs.alu_op_sig = id_cs.alu_op_sig;
	
	assign idex1_cs.pc2reg_sig = id_cs.pc2reg_sig;
	assign idex1_cs.imm2reg_sig = id_cs.imm2reg_sig;
	
	logic [PC_WIDTH-1:0] id_jal_result;
	assign               id_jal_result = id_pc + (PC_WIDTH)'(1'b1);
	
	logic [FUNCT3_WIDTH-1:0] ex1_funct3;
	logic ex1_is_rtype;
	
   idex_pipe_reg_beq_rv 
    idex_pipe_reg_beq_rv_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
		 .ex_flush(ex1_branch_taken),
       .id_cs(idex1_cs), //******id_cs_stall
       .id_rd1(id_rd1),
       .id_rd2(id_rd2),
       .id_imm(id_imm),
       .id_wr_reg(idex_wr_reg), //**************idex_wr_reg
       //.id_aluc(id_funct3),
		 //.id_rs1(id_rs1),
		 //.id_rs2(id_rs2),
		 .id_branch_taken(id_branch_taken),
		 .id_jal_result(id_jal_result),
		 
		 .id_funct3(id_funct3),
		 .ex_funct3(ex1_funct3),
		 
       .ex_cs(ex1_cs),
       .ex_rd1(ex1_rd1),
       .ex_rd2(ex1_rd2),
       .ex_imm(ex1_imm),
       .ex_wr_reg(ex1_wr_reg),
       //.ex_aluc(ex1_aluc),
		 //.ex_rs(ex1_rs),
		 //.ex_rt(ex1_rt),
		 .ex1_branch_taken(ex1_branch_taken),
		 
		 .id_branch_addr(id_branch_addr),
		 .ex_branch_addr(ex_branch_addr),
		 
		 .ex_jal_result(ex_jal_result),
		 
		 .id_is_rtype(id_is_rtype),
		 .ex1_is_rtype(ex1_is_rtype),
		 
		 .id_valid_i(id_valid),
		 .id_ready_i(id_ready),
		 .ex1_valid_o(ex1_valid),
		 //.ex1_ready_i(ex1_ready),
		 
		 .id_hazard(id_hazard)
		 //.nxt_id_hazard(nxt_id_hazard)
   );
	
	

   //========================================================================
   // EX1 STAGE
   //========================================================================
   
   //------------------------------------------------------------------------
   // Control Signal Propagation to MEM Stage
   //------------------------------------------------------------------------
	
   alu_in_target 
    alu_in_target_0 (
       .ex_rf_rd1(ex1_rd1),
       .ex_rf_rd2(ex1_rd2),
       .mem_addr(mem_addr),
       .wb_result(wb_result),
       .ex_imm(ex1_imm),
       .fw_alu_a(fw_alu_a),
       .fw_alu_b(fw_alu_b),
       .ex_alu_src_sig(ex1_cs.alu_src2_sig),
       .ex_alu_tar_a(ex1_alu_a),
       .ex_alu_tar_b(ex1_alu_b),
       .ex_fw_b(ex1_fw_b)
   );
	

	
	//------------------------------------------------------------------------
   // EX1/EX2 Pipeline Register
   //------------------------------------------------------------------------
	logic [FUNCT3_WIDTH-1:0] ex2_funct3;
	logic [PC_WIDTH-1:0]     ex2_jal_result;
	rv32i_word               ex2_imm;
	logic ex2_is_rtype;
	
   ex1ex2_pipe_reg_rv 
    ex1ex2_pipe_reg_rv_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
		 .ex1_cs(ex1_cs),
		 .ex1_alu_a(ex1_alu_a),
		 .ex1_alu_b(ex1_alu_b),
		 .ex1_fw_b(ex1_fw_b),
		 .ex1_wr_reg(ex1_wr_reg),
		 .ex1_aluc(idex1_cs.alu_op_sig),
		 
		 .ex1_funct3(ex1_funct3),
		 .ex2_funct3(ex2_funct3),
		 
		 .ex2_cs(ex2_cs),
		 .ex2_alu_a(ex2_alu_a),
		 .ex2_alu_b(ex2_alu_b),
		 .ex2_fw_b(ex2_fw_b),
		 .ex2_wr_reg(ex2_wr_reg),
		 .ex2_aluc(ex2_aluc),
		 
		 .ex1_valid_i(ex1_valid),
		 
		 .ex1_jal_result(ex_jal_result),
		 .ex2_jal_result(ex2_jal_result),
		 .ex1_imm(ex1_imm),
		 .ex2_imm(ex2_imm),
		 
		 .ex2_is_rtype(ex2_is_rtype),
		 .ex1_is_rtype(ex1_is_rtype)
   );
	
   //========================================================================
   // EX2 STAGE
   //========================================================================
	
	//------------------------------------------------------------------------
   // ALU
   //------------------------------------------------------------------------
   /*alu 
    alu_0 (
       .ex_a_i(ex2_alu_a),
       .ex_b_i(ex2_alu_b),
       .ex_aluc_i(ex2_aluc),
       .ex_alu_o(ex2_alu_result)
   );*/
	logic [DATA_WIDTH-1:0] phase1_add;
   logic [DATA_WIDTH-1:0] phase1_sub;
   logic [DATA_WIDTH-1:0] phase1_and;
   logic [DATA_WIDTH-1:0] phase1_or;
   logic [DATA_WIDTH-1:0] phase1_xor;
   logic [DATA_WIDTH-1:0] phase1_sll;
   logic [DATA_WIDTH-1:0] phase1_srl;
   logic                  phase1_slt;
   logic [ALUC_WIDTH-1:0] phase1_aluc;
	
	alu_phase1 u_alu_phase1 (
      .clk            (i_clk),
      .rst_n          (rst_n),
      .ex_a_i         (ex2_alu_a),
      .ex_b_i         (ex2_alu_b),
      .ex_aluc_i      (ex2_aluc),
      .phase1_add_o   (phase1_add),
      .phase1_sub_o   (phase1_sub),
      .phase1_and_o   (phase1_and),
      .phase1_or_o    (phase1_or),
      .phase1_xor_o   (phase1_xor),
      .phase1_sll_o   (phase1_sll),
      .phase1_srl_o   (phase1_srl),
      .phase1_slt_o   (phase1_slt),
      .phase1_aluc_o  (phase1_aluc)
   );
	
	/*logic [FUNCT3_WIDTH-1:0] mem_funct3;
	always_ff @(posedge i_clk or negedge rst_n) begin
		if(~rst_n) begin
			mem_funct3 <= '0;
		end else begin
			mem_funct3 <= ex2_funct3;
		end
	end*/
	
	 
   //------------------------------------------------------------------------
   // EX/MEM Pipeline Register
   //------------------------------------------------------------------------
	
		alu_phase2 u_alu_phase2 (
      .phase1_add_i   (phase1_add),
      .phase1_sub_i   (phase1_sub),
      .phase1_and_i   (phase1_and),
      .phase1_or_i    (phase1_or),
      .phase1_xor_i   (phase1_xor),
      .phase1_sll_i   (phase1_sll),
      .phase1_srl_i   (phase1_srl),
      .phase1_slt_i   (phase1_slt),
      .phase1_aluc_i  (phase1_aluc),
      .ex_alu_o       (ex2_alu_result)
   );
  
   assign mem_addr = ex2_alu_result;
	
	// Mask generate for MEM WRIte
	/*mask_gen
	mask_gen_0(
    .alu_out(ex2_alu_result),
    .funct3(mem_funct3),
    .write_read_mask
    );*/
	 
	
	assign exmem_cs.mem_rd_sig  = ex2_cs.mem_rd_sig;
   assign exmem_cs.mem_wr_sig  = ex2_cs.mem_wr_sig;
   assign exmem_cs.mem2reg_sig = ex2_cs.mem2reg_sig;
   assign exmem_cs.reg_wr_sig  = ex2_cs.reg_wr_sig;
	
	assign exmem_cs.pc2reg_sig  = ex2_cs.pc2reg_sig;
	assign exmem_cs.imm2reg_sig = ex2_cs.imm2reg_sig;
	
	logic [PC_WIDTH-1:0]    mem_jal_result;
	rv32i_word              mem_imm;
	logic mem_is_rtype;
	
   exmem_pipe_reg 
    exmem_pipe_reg_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .ex_cs(exmem_cs),
       .ex_b(ex2_fw_b),
       //.ex_alu_out(ex2_alu_result),
		 .ex_alu_out(0),
       .ex_wr_reg(ex2_wr_reg),
       .mem_cs(mem_cs),
       //.mem_addr(mem_addr),
       .mem_data(mem_data),
       .mem_wr_reg(mem_wr_reg),
		 
		 .ex2_jal_result(ex2_jal_result),
		 .mem_jal_result(mem_jal_result),
		 .ex2_imm(ex2_imm),
		 .mem_imm(mem_imm),
		 
		 .ex2_is_rtype(ex2_is_rtype),
		 .mem_is_rtype(mem_is_rtype)
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
   
   //------------------------------------------------------------------------
   // Data Memory
   //------------------------------------------------------------------------
   dmem 
    dmem_0 (
       .i_clk(i_clk),
       .rst_n(rst_n),
       .mem_wr_sig(mem_cs.mem_wr_sig),
       .mem_rd_sig(mem_cs.mem_rd_sig), //****************HERE****************
       .mem_addr(mem_addr),
       .mem_wdata(mem_data),
       .mem_rdata_o(mem_rdata)
   );
	
	 //assign mem_result = mem_cs.mem2reg_sig ? mem_rdata : mem_addr;
   
   //------------------------------------------------------------------------
   // MEM/WB Pipeline Register
   //------------------------------------------------------------------------
	 logic [PC_WIDTH-1:0]    wb_jal_result;
	 rv32i_word              wb_imm;
	 
   memwb_pipe_reg 
    memwb_pipe_reg_0 (
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
		 .mem_imm(mem_imm)
   );

   //========================================================================
   // WB STAGE
   //========================================================================
   
   //------------------------------------------------------------------------
   // Write Back Data Selection
   //------------------------------------------------------------------------
   assign wb_result = wb_cs.mem2reg_sig ? wb_rdata      : 
							 wb_cs.pc2reg_sig  ? wb_jal_result :
							 wb_cs.imm2reg_sig ? wb_imm        :
							 wb_addr;

endmodule // top
