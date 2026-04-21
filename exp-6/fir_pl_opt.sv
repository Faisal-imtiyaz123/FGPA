module fir_optimized1 #(parameter N = 100)(
    input clk, rst,
    input signed [15:0] x,
    input signed [15:0] h [0:N/2-1],
    output reg signed [47:0] y
);
    localparam HALF = N/2;
    reg signed [15:0] delay [0:N-1];
    wire signed [16:0] preadd [0:HALF-1];
    wire signed [33:0] mult   [0:HALF-1];
    reg signed [33:0] mult_pipe [0:HALF-1][0:HALF-1];
    reg signed [47:0] stage [0:HALF-1];

    genvar k;
    generate
        for(k = 0; k < HALF; k = k + 1) begin : PREMULT
            assign preadd[k] = delay[k] + delay[N-1-k];
            assign mult[k]   = preadd[k] * h[k];
        end
    endgenerate

    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            for(i=0; i<N; i++) delay[i] <= 0;
            for(i=0; i<HALF; i++) begin
                stage[i] <= 0;
                for(j=0; j<HALF; j++) mult_pipe[i][j] <= 0;
            end
            y <= 0;
        end else begin
            delay[0] <= x;
            for(i=1; i<N; i++) delay[i] <= delay[i-1];
            for(i=0; i<HALF; i++) begin
                mult_pipe[i][0] <= mult[i];
                for(j=1; j<=i; j++) mult_pipe[i][j] <= mult_pipe[i][j-1];
            end
            stage[0] <= mult_pipe[0][0];
            for(i=1; i<HALF; i++) stage[i] <= stage[i-1] + mult_pipe[i][i];
            y <= stage[HALF-1];
        end
    end
endmodule