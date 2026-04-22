import rv32i_types::*;
module alu_in_target 
  
(
   input logic [DATA_WIDTH-1:0]   ex_rf_rd1, 
   input logic [DATA_WIDTH-1:0]   ex_rf_rd2,
   input logic [DATA_WIDTH-1:0]   mem_addr, 
   input logic [DATA_WIDTH-1:0]   wb_result,
   input logic [DATA_WIDTH-1:0]   ex_imm,
	
   input logic [FW_ALU_WIDTH-1:0] fw_alu_a,
   input logic [FW_ALU_WIDTH-1:0] fw_alu_b,
   input logic                    ex_alu_src_sig, 
	
   output logic [DATA_WIDTH-1:0]  ex_alu_tar_a,
   output logic [DATA_WIDTH-1:0]  ex_alu_tar_b,
   output logic [DATA_WIDTH-1:0]  ex_fw_b
);
   // Internal regs
   //logic [DATA_WIDTH-1:0]         ex_fw_b;
   
  always_comb begin
      case (fw_alu_a)
        'b01: begin
           ex_alu_tar_a = mem_addr;
        end
        'b10: begin
           ex_alu_tar_a = wb_result;
        end
        default: begin
           ex_alu_tar_a = ex_rf_rd1;
        end
      endcase // case (fw_alu_a)

      case (fw_alu_b)
        'b01: begin
           ex_fw_b = mem_addr;
        end
        'b10: begin
           ex_fw_b = wb_result;
        end
        default: begin
           ex_fw_b = ex_rf_rd2;
        end
      endcase // case (fw_alu_b)

      ex_alu_tar_b = (ex_alu_src_sig) ? ex_imm : ex_fw_b;
        
   end // always_comb
	
	/* always_comb begin
      if (fw_alu_a[0]) begin
           ex_alu_tar_a = mem_addr;
      end else if (fw_alu_a[1]) begin
           ex_alu_tar_a = wb_result;
      end else begin
           ex_alu_tar_a = ex_rf_rd1;
      end

      if (fw_alu_b[0]) begin
           ex_fw_b = mem_addr;
      end else if (fw_alu_b[1]) begin
           ex_fw_b = wb_result;
      end else begin
           ex_fw_b = ex_rf_rd2;
      end

      ex_alu_tar_b = (ex_alu_src_sig) ? ex_imm : ex_fw_b;
        
   end // always_comb*/

endmodule // alu_in_target	   
