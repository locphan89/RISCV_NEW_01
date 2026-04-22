import rv32i_types::*;
module branch_target
   
(
    input  logic [PC_WIDTH-1:0] if_pc_plus_i, // PC không có 2 bit cuối => word address
    input  logic [31:0] if_imm_i,          
    output logic [ADDR_WIDTH-3:0] if_branch_addr_o   
);
    logic [PC_WIDTH-1:0] offset;

    // vì PC_plus4 là word address, imm là byte offset đã dịch 2-bit,
    // nên để tính word offset ta bỏ 2 bit cuối, tức là shift imm >> 2 (tức là không shift gì vì đã word-aligned)
    // giả sử imm đã được encode ở định dạng word-aligned

    assign offset = {{14{if_imm_i[15]}}, if_imm_i};  // sign-extend từ 16 bit lên 30 bit

    assign if_branch_addr_o = if_pc_plus_i + offset;
endmodule
