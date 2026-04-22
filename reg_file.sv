import rv32i_types::*;
module reg_file
  
(
       //--------------------------
       // Input Ports
       //--------------------------
	input logic		       i_clk,
	input logic [R_ADDR_WIDTH-1:0] raddr0_i,
	input logic [R_ADDR_WIDTH-1:0] raddr1_i,
	input logic [R_ADDR_WIDTH-1:0] waddr_i,
	input logic [DATA_WIDTH-1:0]   wdata_i,
	input logic  		       wren_i,
	
	//input logic                    rd_wr_same_dest_a,
	//input logic                    rd_wr_same_dest_b,
	
	//--------------------------
	// Output Ports
	//--------------------------
	output logic [DATA_WIDTH-1:0]  rdata0_o,
	output logic [DATA_WIDTH-1:0]  rdata1_o
);

	//-------------------------------------------------
	// Internal signal
	//-------------------------------------------------
	//logic	[DATA_WIDTH-1:0] ram_file [0:DATA_WIDTH-1];
	(* ramstyle = "logic" *) logic [31:0] regs [0:31];

	//-------------------------------------------------
	// Initialization: all registers = 0
	// (x0 luôn = 0, x1..x31 kh?i t?o s?ch)
	//-------------------------------------------------
	initial begin
		for (int i = 0; i < 32; i++)
			regs[i] = 32'h0;
	end

	//-------------------------------------------------
	// Write Operation
	//-------------------------------------------------
	always_ff @(posedge i_clk) begin
		if (wren_i && (|waddr_i)) begin
		   regs[waddr_i] <= wdata_i;
		end
	end
	

	//-------------------------------------------------
	// Combinational Read Logic (with bypass)
	//-------------------------------------------------
	always_comb begin
	       rdata0_o = (~|(raddr0_i ^ waddr_i)&& wren_i) ? wdata_i : regs[raddr0_i];
	       rdata1_o = (~|(raddr1_i ^ waddr_i) && wren_i) ? wdata_i : regs[raddr1_i];
			 
			 //rdata0_o = regs[raddr0_i];
	       //rdata1_o = regs[raddr1_i];
	end

endmodule