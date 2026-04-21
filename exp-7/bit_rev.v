module bit_rev #(
    parameter WIDTH = 3
)(
    input  wire [WIDTH-1:0] addr_in,
    output wire [WIDTH-1:0] addr_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign addr_out[i] = addr_in[WIDTH-1-i];
        end
    endgenerate
endmodule