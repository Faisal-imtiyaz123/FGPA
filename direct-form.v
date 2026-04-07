module fir_direct (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] coeffs [0:99], 
    input wire signed [15:0] samples [0:1052],
    input wire signed [15:0] din_950,
    input wire signed [15:0] din_1100,
    input wire signed [15:0] din_2000,
    output reg signed [39:0] dout_950,
    output reg signed [39:0] dout_1100,
    output reg signed [39:0] dout_2000
);
    parameter TAPS = 100;
    
    // Delay line
    reg signed [15:0] delay_line_950 [0:TAPS-1];
    reg signed [15:0] delay_line_1100 [0:TAPS-1];
    reg signed [15:0] delay_line_2000 [0:TAPS-1];
    
    // Accumulator
    reg signed [39:0] next_accum_950;
    reg signed [39:0] next_accum_1100;
    reg signed [39:0] next_accum_2000;

    // Shift register (always runs)
    always @(posedge clk or negedge rst_n) begin
        integer i;
        if (rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line_950[i] <= 16'sb0;
                delay_line_1100[i] <= 16'sb0;
                delay_line_2000[i] <= 16'sb0;
            end
            dout_950 <= 40'sb0;
            dout_1100 <= 40'sb0;
            dout_2000 <= 40'sb0;
        end
        else begin
            integer i;
            // Shift every clock cycle
            for (i = TAPS-1; i > 0; i = i - 1)begin
                delay_line_950[i] <= delay_line_950[i-1];
                delay_line_1100[i] <= delay_line_1100[i-1];
                delay_line_2000[i] <= delay_line_2000[i-1];
            end
            delay_line_950[0] <= din_950;
            delay_line_1100[0] <= din_1100;
            delay_line_2000[0] <= din_2000;
            dout_950 <= next_accum_950;
            dout_1100 <= next_accum_1100;
            dout_2000 <= next_accum_2000;
        end
    end
    
    // Compute output every cycle
   always @(*) begin
        integer i;
        reg signed [39:0] accum_950, accum_1100, accum_2000;
        reg signed [31:0] product_950;
        reg signed [31:0] product_1100;
        reg signed [31:0] product_2000;
        
        accum_950 = 40'sb0;
        accum_1100 = 40'sb0;
        accum_2000 = 40'sb0;
        for (i = 0; i < TAPS; i = i + 1) begin
            product_950 = delay_line_950[i] * coeffs[i];
            product_1100 = delay_line_1100[i] * coeffs[i];
            product_2000 = delay_line_2000[i] * coeffs[i];
            accum_950 = accum_950 + { {8{product_950[31]}}, product_950 }; 
            accum_1100 = accum_1100 + { {8{product_1100[31]}}, product_1100 }; 
            accum_2000 = accum_2000 + { {8{product_2000[31]}}, product_2000 }; 
        end
        next_accum_950 = accum_950;
        next_accum_1100 = accum_1100;
        next_accum_2000 = accum_2000;
    end
    
endmodule