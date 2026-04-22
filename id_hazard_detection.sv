import rv32i_types::*;

module id_hazard_detection (
	 
	 input logic                    i_clk,
	 input logic                    rst_n,
    // IF stage signals
    input logic [R_ADDR_WIDTH-1:0] if_rs,
    input logic [R_ADDR_WIDTH-1:0] if_rt,

	  
    // ID stage signals
	 input logic [R_ADDR_WIDTH-1:0] id_rs,
    input logic [R_ADDR_WIDTH-1:0] id_rt,
    input logic [R_ADDR_WIDTH-1:0] id_wr_reg,
	 input logic                    id_branch,


    // EX1 stage signals
    //input logic [R_ADDR_WIDTH-1:0] ex1_wr_reg,
	 input logic                    ex1_reg_wr_sig,
	 input logic                    ex1_mem_rd,
    
    // EX2 stage signals
    input logic [R_ADDR_WIDTH-1:0] ex2_wr_reg,
    input logic                    ex2_mem_rd,
	 input logic                    ex2_reg_wr_sig,
	 
	 // MEM stage signals
	 input logic [R_ADDR_WIDTH-1:0] mem_wr_reg,
	 input logic                    mem_mem_rd,
    
    // Stall outputs
    output logic                   lw_beq_hazard,    // LW followed by BEQ
    output logic                   alu_beq_hazard   // ALU followed by BEQ
	 
);  

	 // ===== Hazard Detection Matching Logic =====
    
    // ID-EX1 matching (1 stage apart)
    /*logic rs_idex1_match, rt_idex1_match, idex1_match;
	 
    assign rs_idex1_match = ~|(id_rs ^ ex1_wr_reg);
    assign rt_idex1_match = ~|(id_rt ^ ex1_wr_reg);
    assign idex1_match    = (rs_idex1_match | rt_idex1_match);*/
	 
	 logic rs_ifid_match, rt_ifid_match, ifid_match;
	 
    assign rs_ifid_match = ~|(if_rs ^ id_wr_reg);
    assign rt_ifid_match = ~|(if_rt ^ id_wr_reg);
    assign ifid_match    = (rs_ifid_match | rt_ifid_match);
	 
	 logic idex1_match;
	 always_ff @(posedge i_clk or negedge rst_n) begin
		if (~rst_n) begin
			idex1_match <= '0;
		end else begin
			idex1_match <= ifid_match;
		end
	end
    
    // ID-EX2 matching (2 stages apart)
    logic rs_idex2_match, rt_idex2_match, idex2_match;
	 
    assign rs_idex2_match = ~|(id_rs ^ ex2_wr_reg);
    assign rt_idex2_match = ~|(id_rt ^ ex2_wr_reg);
    assign idex2_match    = (rs_idex2_match | rt_idex2_match);
    
    // ID-MEM matching (3 stages apart)
    logic rs_idmem_match, rt_idmem_match, idmem_match;
    assign rs_idmem_match = ~|(id_rs ^ mem_wr_reg);
    assign rt_idmem_match = ~|(id_rt ^ mem_wr_reg);
    assign idmem_match    = (rs_idmem_match | rt_idmem_match);
    
    // ===== Stall Condition Logic =====
    
    // Stall MEM: LW followed by BEQ (need 3 cycles stall)
    // BEQ resolves at ID, commits at EX1
    // LW has data at MEM, BEQ needs at ID
    //logic lw_beq_hazard;
	 
	 assign lw_beq_hazard = id_branch & (
        (ex1_mem_rd & idex1_match) |    // LW at ID, need 3 cycles
        (ex2_mem_rd & idex2_match) |  // LW at EX1, need 2 cycles
        (mem_mem_rd & idmem_match)    // LW at EX2, need 1 cycle
    );
    
    // Stall BEQ: ALU followed by BEQ (need 2 cycles stall)
    // ALU has result at MEM, BEQ needs at ID
    //logic alu_beq_hazard;

	 assign alu_beq_hazard = id_branch & (
        (ex1_reg_wr_sig & idex1_match & ~ex1_mem_rd) |   // ALU at ID, need 2 cycles
        (ex2_reg_wr_sig & idex2_match & ~ex2_mem_rd)    // ALU at EX1, need 1 cycle
    );

endmodule