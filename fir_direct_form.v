module fir_direct_form (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] x_in,      // Q(2,14) input
    input wire valid_in,
    output reg signed [15:0] y_out,     // Q(2,14) output
    output reg valid_out
);

    parameter TAPS = 100;
    
    // Filter coefficients (loaded from external file via testbench)
    reg signed [15:0] coeff [0:TAPS-1];
    
    // Delay line
    reg signed [15:0] delay_line [0:TAPS-1];
    
    // Internal variables
    integer i;
    reg signed [31:0] acc;              // Accumulator (higher precision)
    
    // Load coefficients (will be done in testbench)
    initial begin
        for (i = 0; i < TAPS; i = i + 1) begin
            coeff[i] = 16'sd0;
            delay_line[i] = 16'sd0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                delay_line[i] <= 16'sd0;
            end
            y_out <= 16'sd0;
            valid_out <= 1'b0;
            acc <= 32'sd0;
        end
        else if (valid_in) begin
            // Shift delay line
            for (i = TAPS-1; i > 0; i = i - 1) begin
                delay_line[i] <= delay_line[i-1];
            end
            delay_line[0] <= x_in;
            
            // Compute convolution: y[n] = sum(h[k] * x[n-k])
            acc = 32'sd0;
            for (i = 0; i < TAPS; i = i + 1) begin
                acc = acc + (coeff[i] * delay_line[i]);
            end
            
            // Round and saturate to Q(2,14) format
            y_out <= acc[29:14];  // Shift right by 14 bits
            valid_out <= 1'b1;
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule