module fir_direct_pipeline #(parameter TAPS = 100)(
    input  logic clk, rst,
    input  logic signed [15:0] x,
    input  logic signed [15:0] coeff [0:TAPS-1],
    output logic signed [47:0] y // 48-bit for internal precision
);
    logic signed [15:0] shift_reg [0:TAPS-1];
    logic signed [31:0] mult_reg [0:TAPS-1];
    logic signed [47:0] acc_reg;
    
    // Shifting
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i=0; i<TAPS; i++) shift_reg[i] <= 0;
        end else begin
            shift_reg[0] <= x;
            for (int i=1; i<TAPS; i++) shift_reg[i] <= shift_reg[i-1];
        end
    end

    // Multiplication
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i=0; i<TAPS; i++) mult_reg[i] <= 0;
        end else begin
            for (int i=0; i<TAPS; i++) mult_reg[i] <= shift_reg[i] * coeff[i];
        end
    end

    // Accumulation
    always_ff @(posedge clk) begin
        if (rst) begin
            acc_reg <= 0;
            y <= 0;
        end else begin
            acc_reg = 0;
            for (int i=0; i<TAPS; i++) acc_reg += mult_reg[i];
            y <= acc_reg;
        end
    end
endmodule