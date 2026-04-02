module fir_genvar_form (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] x_in,
    input wire valid_in,
    output reg signed [15:0] y_out,
    output reg valid_out
);

    parameter TAPS = 100;
    
    // Filter coefficients
    reg signed [15:0] coeff [0:TAPS-1];
    
    // Delay line
    reg signed [15:0] delay_line [0:TAPS-1];
    
    // MAC results from each tap
    wire signed [31:0] product [0:TAPS-1];
    wire signed [31:0] sum [0:TAPS-1];
    
    genvar i;
    
    // Generate product terms
    generate
        for (i = 0; i < TAPS; i = i + 1) begin : fir_taps
            assign product[i] = coeff[i] * delay_line[i];
        end
    endgenerate
    
    // Generate adder tree (parallel summation)
    generate
        for (i = 0; i < TAPS; i = i + 1) begin : adder_tree
            if (i == 0) begin
                assign sum[i] = product[i];
            end
            else begin
                assign sum[i] = sum[i-1] + product[i];
            end
        end
    endgenerate
    
    integer j;
    
    initial begin
        for (j = 0; j < TAPS; j = j + 1) begin
            coeff[j] = 16'sd0;
            delay_line[j] = 16'sd0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < TAPS; j = j + 1) begin
                delay_line[j] <= 16'sd0;
            end
            y_out <= 16'sd0;
            valid_out <= 1'b0;
        end
        else if (valid_in) begin
            // Shift delay line
            for (j = TAPS-1; j > 0; j = j - 1) begin
                delay_line[j] <= delay_line[j-1];
            end
            delay_line[0] <= x_in;
            
            // Output the final sum
            y_out <= sum[TAPS-1][29:14];
            valid_out <= 1'b1;
        end
        else begin
            valid_out <= 1'b0;
        end
    end

endmodule