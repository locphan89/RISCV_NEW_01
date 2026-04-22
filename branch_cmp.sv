import rv32i_types::*;
module branch_cmp
(
    input [2:0]            cmpop,
    input logic [31:0] 		a,
	 input logic [31:0] 		b,
    output logic 				cmp_result
);


	always_comb
	begin
		cmp_result = '0;
		unique case(cmpop)
			beq:   cmp_result = (a == b);
			bne:   cmp_result = (a != b);
			blt:   cmp_result = $signed(a) < $signed(b);
			bge:   cmp_result = $signed(a) >= $signed(b);
			bltu:  cmp_result = (a < b);
         bgeu:  cmp_result = (a >= b);
			default:; 
		endcase
	end
endmodule : branch_cmp
