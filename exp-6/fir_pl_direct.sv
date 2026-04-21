module fir_direct #(parameter TAPS = 100)(
    input  logic clk, rst_n,
    input  logic signed [15:0] din,
    input  logic signed [15:0] coeffs [0:TAPS-1],
    output logic signed [39:0] dout
);
    logic signed [15:0] shift_reg [0:TAPS-1];
    logic signed [31:0] mult_reg [0:TAPS-1];
    logic signed [39:0] acc_reg;
    
    // Shifting
    always_ff @(posedge clk) begin
        if (rst_n) begin
            for (int i=0; i<TAPS; i++) shift_reg[i] <= 0;
        end else begin
            shift_reg[0] <= din;
            for (int i=1; i<TAPS; i++) shift_reg[i] <= shift_reg[i-1];
        end
    end

    // Multiplication
    always_ff @(posedge clk) begin
        if (rst_n) begin
            for (int i=0; i<TAPS; i++) mult_reg[i] <= 0;
        end else begin
            for (int i=0; i<TAPS; i++) mult_reg[i] <= shift_reg[i] * coeffs[i];
        end
    end

    // Accumulation
    always_ff @(posedge clk) begin
        if (rst_n) begin
            acc_reg <= 0;
            dout <= 0;
        end else begin
            acc_reg = 0;
            for (int i=0; i<TAPS; i++) acc_reg += mult_reg[i];
            dout <= acc_reg;
        end
    end
endmodule