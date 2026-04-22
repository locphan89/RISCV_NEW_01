import rv32i_types::*;
module stall_unit
  
(
    input logic                    i_clk,
    input logic                    rst_n,
	 
    input logic [R_ADDR_WIDTH-1:0] if_rs,
    input logic [R_ADDR_WIDTH-1:0] if_rt,
    input logic                    if_mem_rd,
    input logic                    if_jmp,
    input logic                    if_branch,
	  
    input logic [R_ADDR_WIDTH-1:0] id_wr_reg,
    input logic                    id_mem_rd,
   
    input logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
    input logic                    ex_mem_rd,

    output logic                   stall_lw,
    output logic                   stall_lwlw,
    output logic                   stall,
    output logic                   stall_mem,
    output logic                   stall_beq
	 
    // For forwarding alu 
    /*output logic                   rs_ifid_match,
    output logic                   rt_ifid_match,
    output logic                   rs_ifex_match,
    output logic                   rt_ifex_match*/
);  
    logic                   rs_ifid_match;
    logic                   rt_ifid_match;
    logic                   rs_ifex_match;
    logic                   rt_ifex_match;
	 
    assign       rs_ifid_match = ~|(if_rs ^ id_wr_reg);
    assign       rt_ifid_match = ~|(if_rt ^ id_wr_reg);
    assign       rs_ifex_match = ~|(if_rs ^ ex_wr_reg);
    assign       rt_ifex_match = ~|(if_rt ^ ex_wr_reg);
    logic        ifid_match;
    assign       ifid_match    = (rs_ifid_match | rt_ifid_match);
    logic        ifex_match;
    assign       ifex_match    = (rs_ifex_match | rt_ifex_match);

   logic         idex_hazard;
   assign        idex_hazard   = id_mem_rd & ifid_match;
   logic         exmem_hazard;
   assign        exmem_hazard  = ex_mem_rd & ifex_match;
	 
	 always_ff @(posedge i_clk or negedge rst_n) begin
	    if (!rst_n) begin
	       stall_lw   <= '0;
	       stall_lwlw <= '0;
	       stall_mem  <= '0;
	       stall_beq  <= '0;
               
	    end else begin
	       stall_lw   <= ~if_jmp && idex_hazard && |id_wr_reg;
	       stall_lwlw <= if_mem_rd && idex_hazard;		 
	       stall_mem  <= exmem_hazard && if_branch && ~stall_lw;
	       stall_beq  <= ifid_match && if_branch;
	    end
         end

    //assign stall = stall_lw | stall_lwlw | stall_mem | stall_beq;
	 
	 assign stall = stall_lw | stall_mem | stall_beq;

endmodule
