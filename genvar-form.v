module fir_genvar (
    input wire clk,
    input wire rst_n,
    input wire signed [15:0] coeffs [0:99],
    input wire signed [15:0] din_950,
    input wire signed [15:0] din_1100,
    input wire signed [15:0] din_2000,
    output reg signed [39:0] dout_950,
    output reg signed [39:0] dout_1100,
    output reg signed [39:0] dout_2000
);
    parameter TAPS = 100;
    parameter INPUTS = 3;
    parameter DATA_WIDTH = 16;
    parameter ACCUM_WIDTH = 40;
    
    // 2D delay line [input][tap]
    reg signed [DATA_WIDTH-1:0] delay_line [0:INPUTS-1][0:TAPS-1];
    
    // Accumulators for each input
    reg signed [ACCUM_WIDTH-1:0] next_accum [0:INPUTS-1];
    
    // Generate delay line reset
    generate
        genvar i, j;
        
        // Reset all delay lines using genvar
        for (i = 0; i < INPUTS; i = i + 1) begin : gen_input_reset
            for (j = 0; j < TAPS; j = j + 1) begin : gen_tap_reset
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        delay_line[i][j] <= {DATA_WIDTH{1'b0}};
                    end
                end
            end
        end
        
        // Generate shift register for each input
        for (i = 0; i < INPUTS; i = i + 1) begin : gen_input_shift
            always @(posedge clk or negedge rst_n) begin
                integer k;
                if (!rst_n) begin
                    // Already handled by reset above
                end
                else begin
                    // Shift operation
                    for (k = TAPS-1; k > 0; k = k - 1) begin
                        delay_line[i][k] <= delay_line[i][k-1];
                    end
                end
            end
        end
        
        // Generate input assignment
        always @(*) begin
            delay_line[0][0] = din_950;
            delay_line[1][0] = din_1100;
            delay_line[2][0] = din_2000;
        end
        
        // Generate MAC operations for each input and tap
        for (i = 0; i < INPUTS; i = i + 1) begin : gen_input_mac
            always @(*) begin
                reg signed [ACCUM_WIDTH-1:0] accum;
                integer k;
                
                accum = {ACCUM_WIDTH{1'b0}};
                for (k = 0; k < TAPS; k = k + 1) begin
                    accum = accum + (delay_line[i][k] * coeffs[k]);
                end
                next_accum[i] = accum;
            end
        end
        
        // Generate output assignment
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dout_950 <= {ACCUM_WIDTH{1'b0}};
                dout_1100 <= {ACCUM_WIDTH{1'b0}};
                dout_2000 <= {ACCUM_WIDTH{1'b0}};
            end
            else begin
                dout_950 <= next_accum[0];
                dout_1100 <= next_accum[1];
                dout_2000 <= next_accum[2];
            end
        end
        
    endgenerate
    
endmodule