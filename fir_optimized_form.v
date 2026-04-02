module fir_optimized_form (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] x_in,      // Q(2,14) input
    input wire valid_in,
    output reg signed [15:0] y_out,     // Q(2,14) output
    output reg valid_out
);

    parameter TAPS = 100;
    
    // Filter coefficients
    reg signed [15:0] coeff [0:TAPS-1];
    
    // Multiply-accumulate pipeline (transposed form)
    reg signed [31:0] mac [0:TAPS-1];
    reg signed [15:0] delay [0:TAPS-1];
    
    integer i;
    
    initial begin
        for (i = 0; i < TAPS; i = i + 1) begin
            coeff[i] = 16'sd0;
            mac[i] = 32'sd0;
            delay[i] = 16'sd0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                mac[i] <= 32'sd0;
                delay[i] <= 16'sd0;
            end
            y_out <= 16'sd0;
            valid_out <= 1'b0;
        end
        else if (valid_in) begin
            // Transposed direct form
            for (i = 0; i < TAPS; i = i + 1) begin
                if (i == 0) begin
                    mac[i] <= (coeff[i] * x_in);
                    delay[i] <= x_in;
                end
                else begin
                    mac[i] <= mac[i-1] + (coeff[i] * delay[i-1]);
                    delay[i] <= delay[i-1];
                end
            end
            
            // Output is the last MAC value
            y_out <= mac[TAPS-1][29:14];
            valid_out <= 1'b1;
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule