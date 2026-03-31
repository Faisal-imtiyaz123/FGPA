module fir_genvar (
    input wire clk,
    input wire rst_n,
    input wire din_valid,
    input wire  [15:0] coeffs [0:99], 
    input wire [15:0] din,
    output reg [31:0] dout,
    output reg dout_valid
);
    // Delay line
    reg [15:0] delay_line [0:TAPS-1];
    
    // Multiplication results
    wire [31:0] mult [0:TAPS-1];
    
    // Sum
    reg [31:0] sum;
    integer i;
    
    // Shift register (regular always block)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay_line[i] <= 16'b0;
            dout <= 32'b0;
            dout_valid <= 1'b0;
        end
        else if (din_valid) begin
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_line[i] <= delay_line[i-1];
            delay_line[0] <= din;
            dout_valid <= 1'b1;
        end
        else begin
            dout_valid <= 1'b0;
        end
    end
    
    // Generate multipliers
    generate
        genvar j;
        for (j = 0; j < TAPS; j = j + 1) begin : mult_gen
            assign mult[j] = delay_line[j] * coeffs[j];
        end
    endgenerate
    
    // Sum all products
    always @* begin
        sum = 32'b0;
        for (i = 0; i < TAPS; i = i + 1)
            sum = sum + mult[i];
    end
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout <= 32'b0;
        else if (din_valid)
            dout <= sum;
    end
    
endmodule