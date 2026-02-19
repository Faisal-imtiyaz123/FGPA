module add(
    input  wire  clk,        
    input  wire  rst,       
    input  wire [16:0] a,         
    input  wire [16:0] b,         
    output reg  [17:0] result     
);

reg [16:0] a_reg, b_reg;          

always @(posedge clk or posedge rst) begin
    if (rst) begin
        result   <= 17'b0;
    end else begin
         a_reg<=a;
         b_reg<=b;
         result <= {a_reg[16], a_reg} + {b_reg[16], b_reg};
    end
end

endmodule

module subtract(
    input  wire  clk,
    input  wire  rst,
    input  wire [16:0] a,
    input  wire [16:0] b,
    output reg  [17:0] result
);

reg [16:0] a_reg, b_reg, b_neg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        result   <= 17'b0;
    end else begin
            a_reg <= a;
            b_reg <= b;
            // Compute two's complement of b
            b_neg <= ~b_reg + 1'b1;
            // Add a and negated b
            result <= {a_reg[16], a_reg} + {b_neg[16], b_neg};
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

reg [33:0] product;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        result <= 34'b0;
    end else begin
        // Sign-extend and multiply
        product <= {{17{a[16]}}, a} * {{17{b[16]}}, b};
        result  <= product;
    end
end

endmodule
