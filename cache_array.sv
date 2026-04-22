/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER.
A register array to be used for tag arrays, LRU array, etc. */

module cache_array #(
    parameter s_index = 3,
    parameter width = 1
)
(
    i_clk,
    rst_n,
    read,
    load,
    rindex,
    windex,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input i_clk;
input rst_n;
input read;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

(* ramstyle = "logic" *) logic [width-1:0] data [num_sets-1:0] ;
logic [width-1:0] _dataout;
assign dataout = _dataout;

always_ff @(posedge i_clk or negedge rst_n)
begin
    if (~rst_n) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= '0;
    end
    else begin
        if (read)
            _dataout <= (load  & (rindex == windex)) ? datain : data[rindex];

        if(load)
            data[windex] <= datain;
    end
end

endmodule : cache_array