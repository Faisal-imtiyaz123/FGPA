module newton_raphson #(
    parameter I_BITS = 8,
    parameter F_BITS = 16
)(
    // input wire clk,
    // input wire reset,
    input wire [I_BITS+F_BITS-1:0] numerator,
    input wire [I_BITS+F_BITS-1:0] denominator,
    output reg [I_BITS+F_BITS-1:0] result
);

    localparam TOTAL_BITS = I_BITS + F_BITS;
    localparam ITERATIONS = 8;  // Fixed iterations
    localparam ONE  = 1 << F_BITS;       // 256
    localparam HALF = 1 << (F_BITS-1);   // 128

   function [TOTAL_BITS-1:0] mul;
    input [TOTAL_BITS-1:0] a, b;
    reg [2*TOTAL_BITS-1:0] product;  // product result
    begin
        product = a * b;
        mul = product >> F_BITS;
    end
   endfunction
   
function [TOTAL_BITS-1:0] normalize;
    input [TOTAL_BITS-1:0] D_in;
    reg [TOTAL_BITS-1:0] D_out;
    integer i;
    begin
        D_out = D_in;
        for (i = 0; i < TOTAL_BITS; i = i + 1) begin
            if (D_out < HALF)
                D_out = D_out << 1;
            else if (D_out > ONE)
                D_out = D_out >> 1;
        end
        normalize = D_out;
    end
endfunction
function integer compute_scale;
    input [TOTAL_BITS-1:0] D_in;
    reg [TOTAL_BITS-1:0] D_func;
    integer i;
    integer scale;
    begin
        scale = 0;
        D_func = D_in;

        for (i = 0; i < TOTAL_BITS; i = i + 1) begin
            if (D_func < HALF) begin
                D_func = D_func << 1;
                scale = scale - 1;
            end
            else if (D_func > ONE) begin
                D_func = D_func >> 1;
                scale = scale + 1;
            end
        end

        compute_scale = scale;
    end
endfunction

function [TOTAL_BITS-1:0] newton_raphson;
    input [TOTAL_BITS-1:0] D;
    reg [TOTAL_BITS-1:0] x;
    reg [TOTAL_BITS-1:0] D_norm;
    integer scale;
    integer i;
    begin
        // Constants in 8.16 fixed-point format
        
       localparam [TOTAL_BITS-1:0] CONST_48_17 = 24'b00000010_11010011_00010000; 
       localparam [TOTAL_BITS-1:0] CONST_32_17 = 24'b00000001_11100010_00001011; 
       localparam [TOTAL_BITS-1:0] TWO = 24'b00000010_00000000_00000000;   
        
        D_norm = normalize(D);
        scale = compute_scale(D);
        // $display("D_norm:%b scale:%d",D_norm,scale);
        // initial guess = 48/17 - (32/17)*D_normalized
        x = CONST_48_17 - mul(CONST_32_17, D_norm);
        
        // Newton-Raphson iterations: x = x * (2 - x*D)
        for (i = 0; i < ITERATIONS; i = i + 1) begin
            x = mul(x, TWO - mul(x, D_norm));
        end
        if (scale >= 0)
    newton_raphson = x >> scale;
else
    newton_raphson = x << (-scale);
    end
endfunction
 
    always @(*) begin
            result <= mul(numerator, newton_raphson(denominator));
        end

endmodule