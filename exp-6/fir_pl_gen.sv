`timescale 1ns/1ns

// ============= SHIFT REGISTER MODULE =============
module shift_stage #(
    parameter TAP_INDEX = 0
)(
    input logic clk, rst_n,
    input logic signed [15:0] din,
    output logic signed [15:0] dout
);
    always_ff @(posedge clk) begin
        if (!rst_n) dout <= 16'sb0;
        else dout <= din;
    end
endmodule


// ============= MULTIPLIER MODULE =============
module mul_stage #(
    parameter TAP_INDEX = 0
)(
    input logic clk, rst_n,
    input logic signed [15:0] din,
    input logic signed [15:0] coeff,
    output logic signed [31:0] mult_out
);
    always_ff @(posedge clk) begin
        if (!rst_n) mult_out <= 32'sb0;
        else mult_out <= din * coeff;
    end
endmodule


// ============= ACCUMULATOR MODULE =============
module acc_stage #(
    parameter TAP_INDEX = 0
)(
    input logic clk, rst_n,
    input logic signed [31:0] mult_in,
    input logic signed [39:0] acc_in,
    output logic signed [39:0] acc_out
);
    always_ff @(posedge clk) begin
        if (!rst_n) acc_out <= 40'sb0;
        else acc_out <= acc_in + mult_in;
    end
endmodule


// ============= SINGLE TAP MODULE (Combines Shift + Mul + Acc) =============
module fir_tap #(
    parameter TAP_INDEX = 0
)(
    input logic clk, rst_n,
    input logic signed [15:0] din,
    input logic signed [15:0] coeff,
    input logic signed [39:0] acc_in,
    output logic signed [15:0] dout,
    output logic signed [39:0] acc_out
);
    logic signed [15:0] shift_out;
    logic signed [31:0] mult_out;
    
    // Instantiate shift stage
    shift_stage #(.TAP_INDEX(TAP_INDEX)) shift_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(shift_out)
    );
    
    // Instantiate multiplier stage
    mul_stage #(.TAP_INDEX(TAP_INDEX)) mul_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(shift_out),
        .coeff(coeff),
        .mult_out(mult_out)
    );
    
    // Instantiate accumulator stage
    acc_stage #(.TAP_INDEX(TAP_INDEX)) acc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mult_in(mult_out),
        .acc_in(acc_in),
        .acc_out(acc_out)
    );
    
    assign dout = shift_out;
endmodule


// ============= TOP LEVEL FIR MODULE =============
module fir_genvar #(
    parameter TAPS = 100
)(
    input logic clk, rst_n,
    input logic signed [15:0] din,
    input logic signed [15:0] coeffs [0:TAPS-1],
    output logic signed [39:0] dout
);
    logic signed [15:0] tap_out [0:TAPS-1];
    logic signed [39:0] acc_chain [0:TAPS];
    
    // End of accumulator chain (start with 0)
    assign acc_chain[TAPS] = 40'sb0;
    
    genvar i;
    generate
        for(i = 0; i < TAPS; i = i + 1) begin : TAP_GEN
            if (i == 0) begin
                // First tap - takes input directly
                fir_tap #(.TAP_INDEX(i)) tap_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .din(din),
                    .coeff(coeffs[i]),
                    .acc_in(acc_chain[i+1]),
                    .dout(tap_out[i]),
                    .acc_out(acc_chain[i])
                );
            end else begin
                // Other taps - take output from previous tap
                fir_tap #(.TAP_INDEX(i)) tap_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .din(tap_out[i-1]),
                    .coeff(coeffs[i]),
                    .acc_in(acc_chain[i+1]),
                    .dout(tap_out[i]),
                    .acc_out(acc_chain[i])
                );
            end
        end
    endgenerate
    
    assign dout = acc_chain[0];
endmodule