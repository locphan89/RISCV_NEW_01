import rv32i_types::*;
module dmem
  
(
   input logic                   i_clk,
   input logic                   rst_n,                   
   input logic                   mem_wr_sig,
   input logic                   mem_rd_sig,
   input logic [DATA_WIDTH-1:0]  mem_addr,
   input logic [DATA_WIDTH-1:0]  mem_wdata,
   output logic [DATA_WIDTH-1:0] mem_rdata_o
 );

   logic [DATA_WIDTH-1:0]        mem [0:DATA_WIDTH-1];
	
	// For debug
	initial begin
     mem[15] = 'd20;
   end
   
   always_ff @(posedge i_clk or negedge rst_n) begin
      if (~rst_n) begin
      end else begin
         if (mem_wr_sig) begin
            mem[mem_addr] <= mem_wdata;
         end
      end
   end // always_ff @ (posedge i_clk or negedge rst_n)

	
	assign mem_rdata_o = mem_rd_sig ?  mem[mem_addr] : '0;
	
endmodule // dmem



   
