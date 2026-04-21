module fir_direct_pipeline #(parameter TAPS = 100)(
    input  logic clk, rst,
    input  logic signed [15:0] x,
    input  logic signed [15:0] coeff [0:TAPS-1],
    output logic signed [47:0] y // 48-bit for internal precision
);
    logic signed [15:0] shift_reg [0:TAPS-1];
    logic signed [31:0] mult_stage [0:TAPS-1];
    logic signed [47:0] acc_stage;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i=0; i<TAPS; i++) shift_reg[i] <= 0;
            y <= 0;
        end else begin
            shift_reg[0] <= x;
            for (int i=1; i<TAPS; i++) shift_reg[i] <= shift_reg[i-1];
            for (int i=0; i<TAPS; i++) mult_stage[i] <= shift_reg[i] * coeff[i];
            
            acc_stage = 0;
            for (int i=0; i<TAPS; i++) acc_stage += mult_stage[i];
            y <= acc_stage;
        end
    end
endmodule