module fir_optimized (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] coeffs [0:99],
    input wire signed din,
    input wire signed dout
);
    parameter TAPS = 100;
    

    reg signed [39:0] tap_reg [0:TAPS-1];
    
    integer i;
    
    // Transposed form implementation (more pipelined)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                tap_reg[i] <= 40'sb0;
            end
            dout <= 16'sb0;
        end
        else begin
            // First tap (no feedback)
            tap_reg[0] <= din * coeffs[0];
            
            // Remaining taps with accumulation
            for (i = 1; i < TAPS; i = i + 1) begin
                tap_reg[i] <= tap_reg[i-1] + (din * coeffs[i]);
            end
            
            // Output is the last tap
            dout <= tap_reg[TAPS-1];
        end
    end
    
endmodule