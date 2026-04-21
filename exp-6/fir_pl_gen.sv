module add_reg_stage (
    input clk, rst,
    input signed [31:0] mult_in, // Comes from the shared multiplier
    input signed [47:0] acc_in,
    output reg signed [47:0] acc_out
);
    always @(posedge clk) begin
        if (rst) acc_out <= 0;
        else     acc_out <= acc_in + mult_in;
    end
endmodule

module fir_transposed_sym #(parameter N = 100)(
    input clk, rst,
    input signed [15:0] x,
    // Note: We only need HALF the coefficients now!
    input signed [15:0] h [0:(N/2)-1], 
    output signed [47:0] y
);
    localparam HALF = N / 2;
    
    // 1. Array to hold the shared multiplier outputs
    wire signed [31:0] mult [0:HALF-1];
    
    // 2. Accumulation chain
    wire signed [47:0] acc [0:N];
    assign acc[N] = 0;

    genvar i;
    generate
        // STEP A: Generate exactly N/2 multipliers
        for(i = 0; i < HALF; i = i + 1) begin : DSP_MULT
            assign mult[i] = x * h[i];
        end

        // STEP B: Generate N accumulation stages
        for(i = 0; i < N; i = i + 1) begin : ACC_CHAIN
            // This maps the index so it counts up to 49, then back down to 0
            localparam mult_idx = (i < HALF) ? i : (N - 1 - i);
            
            add_reg_stage stage (
                .clk(clk), .rst(rst),
                .mult_in(mult[mult_idx]), // Re-use the multiplier output!
                .acc_in(acc[i+1]), 
                .acc_out(acc[i])
            );
        end
    endgenerate
    
    assign y = acc[0];
endmodule