import rv32i_types::*;
module idex_pipe_reg_beq_rv_cache 
  
(
   input logic                     i_clk,
   input logic                     rst_n,
   input logic                     ex_flush,
	
   // Decode side
   input ex_ctrl_unit_sig          id_cs,
   input logic [DATA_WIDTH-1:0]    id_rd1,
   input logic [DATA_WIDTH-1:0]    id_rd2,
   input logic [DATA_WIDTH-1:0]    id_imm,
   input logic [R_ADDR_WIDTH-1:0]  id_wr_reg,
   input logic [FUNCT3_WIDTH-1:0]  id_funct3,
   input logic [PC_WIDTH-1:0]      id_branch_addr,
   input logic                     id_branch_taken,
	
   input logic [PC_WIDTH-1:0]      id_jal_result,
	
   // Execute side 
   output ex_ctrl_unit_sig         ex_cs,
   output logic [DATA_WIDTH-1:0]   ex_rd1,
   output logic [DATA_WIDTH-1:0]   ex_rd2,
   output logic [DATA_WIDTH-1:0]   ex_imm,
   output logic [R_ADDR_WIDTH-1:0] ex_wr_reg,
   output logic [FUNCT3_WIDTH-1:0] ex_funct3,
   output logic [PC_WIDTH-1:0]     ex_branch_addr,
   output logic                    ex_branch_taken,
	
   output logic [PC_WIDTH-1:0]     ex_jal_result,
	
   input logic                     id_is_rtype,
   output logic                    ex_is_rtype,
	
   // Handshake
   input  logic                    id_hazard,
	
   input  logic                    id_valid_i,
   output logic                    id_ready_o,
	
   output logic                    ex_valid_o,
   input  logic                    ex_ready_i
);

   logic id_active;
   assign id_active = id_valid_i & id_ready_o;
	
   assign id_ready_o = ~id_hazard && (!ex_valid_o || ex_ready_i);
	
   always_ff @(posedge i_clk or negedge rst_n) begin
      if (!rst_n) begin
         ex_cs            <= '0;
         ex_rd1           <= '0;
         ex_rd2           <= '0;
         ex_imm           <= '0;
         ex_wr_reg        <= '0;
         ex_funct3        <= '0;
         ex_branch_addr   <= '0;
         ex_branch_taken  <= '0;
         ex_valid_o       <= 1'b0;
         ex_jal_result    <= '0;
         ex_is_rtype      <= 1'b0;
      end else begin
         // ------------------------------------------------------------------
         // FIX: On flush, clear ex_valid_o AND all control/forwarding fields.
         //
         // Without clearing ex_wr_reg on flush, the stale destination register
         // from the flushed instruction keeps matching incoming operands in
         // forward_alu_unit (rs_ifid_match fires) and in forward_branch_unit
         // (ex_wr_reg matched against branch rs1/rs2).
         //
         // Without clearing ex_jal_result, the stale JAL return address can be
         // forwarded via fwb_jal to a subsequent branch operand mux, giving
         // an incorrect operand value to bltu/bgeu/beq/bne.
         //
         // Clearing ex_branch_taken prevents a double-flush on the next cycle.
         // ------------------------------------------------------------------
         if (ex_flush) begin
            ex_valid_o      <= 1'b0;
            ex_cs           <= '0;
            ex_wr_reg       <= '0;       // CRITICAL: prevents stale ALU forwarding
            ex_jal_result   <= '0;       // CRITICAL: prevents stale JAL forwarding
            ex_is_rtype     <= 1'b0;
            ex_branch_taken <= 1'b0;     // prevent double-flush
            ex_funct3       <= '0;       // prevent stale funct3 in forwarding unit
         end
         else if (id_active) begin
            ex_valid_o <= 1'b1;
         end

         // Datapath registers: only update on id_active
         if (id_active) begin
            ex_rd1          <= id_rd1;
            ex_rd2          <= id_rd2;
            ex_imm          <= id_imm;
            ex_funct3       <= id_funct3;
            ex_branch_addr  <= id_branch_addr;
            ex_branch_taken <= id_branch_taken;
            ex_jal_result   <= id_jal_result;
            ex_wr_reg       <= id_wr_reg;
         end

         // Control signals: bubble on hazard, new value on active
         if (id_active) begin
            ex_cs       <= id_cs;
            ex_is_rtype <= id_is_rtype;
         end else if (id_hazard) begin
            ex_cs       <= '0;
            ex_is_rtype <= 1'b0;
         end
      end
   end

endmodule