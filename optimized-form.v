module fir_optimized (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] coeffs [0:99],
    input wire signed [15:0] din_950,
    input wire signed [15:0] din_1100,
    input wire signed [15:0] din_2000,
    output reg signed [39:0] dout_950,
    output reg signed [39:0] dout_1100,
    output reg signed [39:0] dout_2000
);
    parameter TAPS = 100;
    
    // Transposed form uses registers after each multiply-accumulate
    reg signed [39:0] tap_reg_950 [0:TAPS-1];
    reg signed [39:0] tap_reg_1100 [0:TAPS-1];
    reg signed [39:0] tap_reg_2000 [0:TAPS-1];
    
    integer i;
    
    // Transposed form implementation (more pipelined)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                tap_reg_950[i] <= 40'sb0;
                tap_reg_1100[i] <= 40'sb0;
                tap_reg_2000[i] <= 40'sb0;
            end
            dout_950 <= 40'sb0;
            dout_1100 <= 40'sb0;
            dout_2000 <= 40'sb0;
        end
        else begin
            // First tap (no feedback)
            tap_reg_950[0] <= din_950 * coeffs[0];
            tap_reg_1100[0] <= din_1100 * coeffs[0];
            tap_reg_2000[0] <= din_2000 * coeffs[0];
            
            // Remaining taps with accumulation
            for (i = 1; i < TAPS; i = i + 1) begin
                tap_reg_950[i] <= tap_reg_950[i-1] + (din_950 * coeffs[i]);
                tap_reg_1100[i] <= tap_reg_1100[i-1] + (din_1100 * coeffs[i]);
                tap_reg_2000[i] <= tap_reg_2000[i-1] + (din_2000 * coeffs[i]);
            end
            
            // Output is the last tap
            dout_950 <= tap_reg_950[TAPS-1];
            dout_1100 <= tap_reg_1100[TAPS-1];
            dout_2000 <= tap_reg_2000[TAPS-1];
        end
    end
    
endmodule