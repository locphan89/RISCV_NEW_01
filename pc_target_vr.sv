import rv32i_types::*;
module pc_target_vr
  
   (
    input logic                 i_clk,
    input logic                 rst_n,

    input logic [PC_WIDTH-1:0]  if_pc_plus_i,
    
    input logic [PC_WIDTH-1:0]  branch_target,
    input logic [PC_WIDTH-1:0]  jmp_target,
    input logic                 branch_taken,
    input logic                 jmp_taken,

    output logic [PC_WIDTH-1:0] if_pc_o,
	 
	 input  logic                if_ready_i
    );

   // PC update - CHỈ khi if_ready = 1
	always_ff @(posedge i_clk or negedge rst_n) begin
		if (!rst_n) begin
			if_pc_o    <= '0;
		end else begin
			if (jmp_taken) begin
				if_pc_o    <= jmp_target;
        end else if (branch_taken) begin
            if_pc_o    <= branch_target;
        end else if (if_ready_i) begin  
            if_pc_o    <= if_pc_plus_i;
        end
        // Nếu if_ready = 0: PC giữ nguyên (automatic stall!)
    end
end
   

endmodule // pc_target

   
 
 
