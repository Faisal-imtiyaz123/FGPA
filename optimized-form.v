module fir_optimized (
    input wire clk,
    input wire rst_n,
    input wire din_valid,
    input wire  [15:0] coeffs [0:99], 
    input wire [15:0] din,
    output reg [31:0] dout,
    output reg dout_valid
);
    // Transposed form: each tap has its own accumulator
    reg [31:0] tap_reg [0:TAPS-1];
    wire [31:0] next_tap [0:TAPS-1];
    
    integer i;
    
    // Generate next_tap values
    generate
        genvar j;
        
        // First tap
        assign next_tap[0] = din * coeffs[0];
        
        // Remaining taps
        for (j = 1; j < TAPS; j = j + 1) begin : tap_calc
            assign next_tap[j] = tap_reg[j-1] + (din * coeffs[j]);
        end
    endgenerate
    
    // Register all taps
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1)
                tap_reg[i] <= 32'b0;
            dout <= 32'b0;
            dout_valid <= 1'b0;
        end
        else if (din_valid) begin
            for (i = 0; i < TAPS; i = i + 1)
                tap_reg[i] <= next_tap[i];
            dout <= next_tap[TAPS-1];
            dout_valid <= 1'b1;
        end
        else begin
            dout_valid <= 1'b0;
        end
    end
    
endmodule