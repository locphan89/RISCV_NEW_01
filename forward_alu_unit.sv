import rv32i_types::*;
module forward_alu_unit 
  
(  
    input  logic                    i_clk,
    input  logic                    rst_n,
    input  logic                    id_reg_wr_sig,
    input  logic                    id_mem_rd,
    input  logic                    ex_reg_wr_sig,
	 
    input  logic                    rs_ifid_match,
    input  logic                    rt_ifid_match,
    input  logic                    rs_ifex_match,
    input  logic                    rt_ifex_match,


    output logic [FW_ALU_WIDTH-1:0] fw_alu_a,
    output logic [FW_ALU_WIDTH-1:0] fw_alu_b

);
   logic                            exmem_fw_rs;
   logic                            exmem_fw_rt;
   logic                            memwb_fw_rs;
   logic                            memwb_fw_rt;
	
	logic                            is_lw_n;
   assign is_lw_n = id_reg_wr_sig && ~id_mem_rd;

   // Combinational detection using ID-stage rs vs EX/MEM-stage destinations.
   // These signals are registered one cycle so that when the ID instruction
   // advances to EX the forwarding select is already stable.
   always_comb begin
      exmem_fw_rs = rs_ifid_match && is_lw_n;
      exmem_fw_rt = rt_ifid_match && is_lw_n;
      memwb_fw_rs = rs_ifex_match && ex_reg_wr_sig;
      memwb_fw_rt = rt_ifex_match && ex_reg_wr_sig;
   end

   // REGISTERED output: result computed at cycle N is used at cycle N+1
   // when the instruction that was in ID moves into EX.
   always_ff @(posedge i_clk or negedge rst_n) begin
      if (!rst_n) begin
         fw_alu_a <= '0;
         fw_alu_b <= '0;
      end else begin
         if (exmem_fw_rs)
            fw_alu_a <= 'b01;
         else if (memwb_fw_rs)
            fw_alu_a <= 'b10;
         else
            fw_alu_a <= '0;

         if (exmem_fw_rt)
            fw_alu_b <= 'b01;
         else if (memwb_fw_rt)
            fw_alu_b <= 'b10;
         else
            fw_alu_b <= '0;
      end
   end

endmodule