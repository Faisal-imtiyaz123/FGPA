module add(
    input  wire        clk,
    input  wire        rst,
    input  wire [16:0] a, 
    input  wire [16:0] b, 
    output reg  [17:0] result
);

always @(*) begin
    if (rst) begin
        result <= 18'b0;
    end else begin
        
        result <= {{2{a[16]}}, a} + {{2{b[16]}}, b};
    end
end

endmodule

module subtract(
    input  wire        clk,
    input  wire        rst,
    input  wire [16:0] a, 
    input  wire [16:0] b,
    output reg  [17:0] result
);

wire [17:0] a_ext, b_ext, b_neg;

assign a_ext = {{2{a[16]}}, a};
assign b_ext = {{2{b[16]}}, b};
assign b_neg = ~b_ext + 18'b1; 

always @(*) begin
    if (rst) begin
        result <= 18'b0;
    end else begin
        result <= a_ext + b_neg; 
    end
end

endmodule

module mul(
    input  wire        clk,
    input  wire        rst,
    input  wire [16:0] a, 
    input  wire [16:0] b,
    output reg  [33:0] result
);

always @(*) begin
    if (rst) begin
        result <= 34'b0;
    end else begin
        result <= {{17{a[16]}}, a} * {{17{b[16]}}, b};
    end
end

endmodule