module fir_direct (
    input wire clk,
    input wire rst_n,
    input wire [15:0] coeffs [0:99], 
    input wire [15:0] din,
    output reg [31:0] dout
);
    parameter TAPS = 100;
    
    // Delay line
    reg [15:0] delay_line [0:TAPS-1];
    
    // Accumulator
    reg [31:0] next_accum;
    integer i;
    
    // Shift register (always runs)
    always @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay_line[i] <= 16'b0;
            dout <= 32'b0;
        end
        else begin
            // Shift every clock cycle
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= din;
            dout <= next_accum;
        end
    end
    
    // Compute output every cycle
    always @* begin
        next_accum = 32'b0;
        for (i = 0; i < TAPS; i = i + 1)
            next_accum = next_accum + (delay_line[i] * coeffs[i]);
    end
    
endmodule