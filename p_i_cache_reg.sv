import rv32i_types::*;
module p_i_cache_reg 

(
    input logic i_clk,
    input logic rst_n,
    input logic load,
    input i_cache_pipeline_reg in,
    output i_cache_pipeline_reg out
);

i_cache_pipeline_reg data;

always_ff @ (posedge i_clk or negedge rst_n) begin
    if (~rst_n) begin
        data <= '0;
    end

    else if (load) begin
        data <= in;
    end
end

always_comb begin

    out = data;

end

endmodule: p_i_cache_reg