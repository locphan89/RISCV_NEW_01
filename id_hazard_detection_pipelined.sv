import rv32i_types::*;

module id_hazard_detection_pipelined (
	 
	 input logic                    i_clk,
	 input logic                    rst_n,
    // IF stage signals
    input logic [R_ADDR_WIDTH-1:0] if_rs,
    input logic [R_ADDR_WIDTH-1:0] if_rt,
	 input logic                    if_branch,
	 input logic                    if_reg_wr_sig,

	  
    // ID stage signals
    input logic [R_ADDR_WIDTH-1:0] id_wr_reg,
	 input logic                    id_mem_rd,
	 input logic                    id_reg_wr_sig,
	 input logic [R_ADDR_WIDTH-1:0] id_rs,
    input logic [R_ADDR_WIDTH-1:0] id_rt,
	 input logic                    id_branch,


    // EX1 stage signals
    input logic [R_ADDR_WIDTH-1:0] ex1_wr_reg,
	 input logic                    ex1_reg_wr_sig,
	 input logic                    ex1_mem_rd,
    
    // EX2 stage signals
    input logic [R_ADDR_WIDTH-1:0] ex2_wr_reg,
    input logic                    ex2_mem_rd,
	 //input logic                    ex2_reg_wr_sig,
	 
	 // MEM stage signals
	 input logic                    mem_mem_rd,

    
    // Stall outputs
    output logic                   lw_beq_hazard,    // LW followed by BEQ
    output logic                   alu_beq_hazard,   // ALU followed by BEQ
	 output logic                   lw_alu_hazard,
	 output logic                   alu_alu_hazard,
	 
	 output logic                   nxt_lw_beq_haz,
	 output logic                   nxt_alu_beq_haz,
	 output logic                   nxt_lw_alu_haz,
	 output logic                   nxt_alu_alu_haz
	 
);  

	 // ===== Hazard Detection Matching Logic 
	 
	  // IF-ID matching
	 logic rs_ifid_match, rt_ifid_match, ifid_match;
    assign rs_ifid_match = ~|(if_rs ^ id_wr_reg);
    assign rt_ifid_match = ~|(if_rt ^ id_wr_reg);
    assign ifid_match    = (rs_ifid_match | rt_ifid_match);
    
    // IF-EX1 matching
    /*logic rs_ifex1_match, rt_ifex1_match, ifex1_match;
    assign rs_ifex1_match = ~|(if_rs ^ ex1_wr_reg);
    assign rt_ifex1_match = ~|(if_rt ^ ex1_wr_reg);
    assign ifex1_match    = (rs_ifex1_match | rt_ifex1_match);*/
	 
	 // IF-EX1 matching
    logic rs_ifex1_match, rt_ifex1_match, ifex1_match;
    assign rs_ifex1_match = ~|(if_rs ^ ex1_wr_reg);
    assign rt_ifex1_match = ~|(if_rt ^ ex1_wr_reg);
    assign ifex1_match    = (rs_ifex1_match | rt_ifex1_match);
	 
	 // IF-EX1 matching
    logic rs_ifex2_match, rt_ifex2_match, ifex2_match;
    assign rs_ifex2_match = ~|(if_rs ^ ex2_wr_reg);
    assign rt_ifex2_match = ~|(if_rt ^ ex2_wr_reg);
    assign ifex2_match    = (rs_ifex2_match | rt_ifex2_match);
	 
	 // ID-EX1 matching
    logic rs_idex1_match, rt_idex1_match, idex1_match;
    assign rs_idex1_match = ~|(id_rs ^ ex1_wr_reg);
    assign rt_idex1_match = ~|(id_rt ^ ex1_wr_reg);
    assign idex1_match    = (rs_idex1_match | rt_idex1_match);
	 
	 // ID-EX2 matching
    /*logic rs_idex2_match, rt_idex2_match, idex2_match;
    assign rs_idex2_match = ~|(id_rs ^ ex2_wr_reg);
    assign rt_idex2_match = ~|(id_rt ^ ex2_wr_reg);
    assign idex2_match    = (rs_idex2_match | rt_idex2_match);*/
	 
	
   // NEXT HAZARD 
	 always_comb begin
			/*nxt_lw_beq_haz  = if_branch & (
									(id_mem_rd & ifid_match) |    // LW at ID, need 3 cycles
									(ex1_mem_rd & ifex1_match) |  // LW at EX1, need 2 cycles
									(ex2_mem_rd & ifex2_match));    // LW at EX2, need 1 cycle*/
									
			nxt_lw_beq_haz  = (if_branch & (id_mem_rd & ifid_match)) |    // LW at ID, need 3 cycles
									(if_branch & (ex1_mem_rd & ifex1_match)) |  // LW at EX1, need 2 cycles
									(if_branch & (ex2_mem_rd & ifex2_match));    // LW at EX2, need 1 cycle
			
			/*nxt_alu_beq_haz =  if_branch & (
									(id_reg_wr_sig & ifid_match & ~id_mem_rd) |   // ALU at ID, need 2 cycles
									(ex1_reg_wr_sig & ifex1_match & ~ex1_mem_rd));    // ALU at EX1, need 1 cycle*/
									
			nxt_alu_beq_haz = (if_branch & (id_reg_wr_sig & ifid_match & ~id_mem_rd)) |   // ALU at ID, need 2 cycles
									((id_branch | if_branch) & (ex1_reg_wr_sig & idex1_match & ~ex1_mem_rd));    // ALU at EX1, need 1 cycle
									
			/*nxt_alu_beq_haz = (id_branch & (ex1_reg_wr_sig & idex1_match & ~ex1_mem_rd)) |   // ALU at ID, need 2 cycles
									(id_branch & (ex2_reg_wr_sig & idex2_match & ~ex2_mem_rd));    // ALU at EX1, need 1 cycle*/
			
			//nxt_lw_alu_haz  = if_reg_wr_sig && ((id_mem_rd & ifid_match) | (ex1_mem_rd & ifex1_match));
			nxt_lw_alu_haz  = (if_reg_wr_sig && (id_mem_rd & ifid_match)) | 
									(id_reg_wr_sig && (ex1_mem_rd & idex1_match));
									
			/*
			nxt_lw_alu_haz  = (id_reg_wr_sig && (ex1_mem_rd & idex1_match)) | 
									(id_reg_wr_sig && (mem_mem_rd & idmem_match));*/
			
			nxt_alu_alu_haz = ~id_mem_rd & ifid_match & if_reg_wr_sig & id_reg_wr_sig;
    end
	 
	 // HAZARD
	 always_ff @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			lw_beq_hazard  <= '0;
			alu_beq_hazard <= '0;
			lw_alu_hazard  <= '0;
			alu_alu_hazard <= '0;
		end else begin
			lw_beq_hazard  <= nxt_lw_beq_haz & ~lw_alu_hazard;
			alu_beq_hazard <= nxt_alu_beq_haz & ~lw_alu_hazard;
			lw_alu_hazard  <= nxt_lw_alu_haz;
			alu_alu_hazard <= nxt_alu_alu_haz;
		end
	end

endmodule