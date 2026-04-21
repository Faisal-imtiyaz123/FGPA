module fft_8point_stream (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        input_valid,
    input  wire [7:0]  input_real,
    input  wire [7:0]  input_imag,
    output reg  [7:0]  output_real [0:7],
    output reg  [7:0]  output_imag [0:7],
    output reg         output_valid
);

    // Internal storage for 8 samples
    reg [7:0] sample_real [0:7];
    reg [7:0] sample_imag [0:7];
    reg [2:0] sample_cnt;
    
    // Twiddle factors (cos/sin for -2πk/N)
    // For 8-point FFT: W8^0 = 1, W8^1 = 0.707-0.707j, W8^2 = -j, W8^3 = -0.707-0.707j
    // Scaled to 8-bit fixed point (multiply by 128)
    localparam W_REAL0 = 8'd128, W_IMAG0 = 8'd0;      // 1
    localparam W_REAL1 = 8'd91,  W_IMAG1 = -8'd91;    // 0.707 - 0.707j
    localparam W_REAL2 = 8'd0,   W_IMAG2 = -8'd128;   // -j
    localparam W_REAL3 = -8'd91, W_IMAG3 = -8'd91;    // -0.707 - 0.707j
    
    // Pipeline stages
    // Stage 1: Butterfly operations (inputs x0,x4; x1,x5; x2,x6; x3,x7)
    reg [15:0] s1_real [0:7], s1_imag [0:7];
    reg [2:0] s1_cnt;
    reg s1_valid;
    
    // Stage 2: Butterfly operations with W8^0, W8^2
    reg [15:0] s2_real [0:7], s2_imag [0:7];
    reg [2:0] s2_cnt;
    reg s2_valid;
    
    // Stage 3: Final butterfly operations with W8^0, W8^1, W8^2, W8^3
    reg [15:0] s3_real [0:7], s3_imag [0:7];
    reg [2:0] s3_cnt;
    reg s3_valid;
    
    // Bit-reversed addressing
    function [2:0] bit_rev;
        input [2:0] addr;
        begin
            bit_rev = {addr[0], addr[1], addr[2]};
        end
    endfunction
    
    // Stage 1: Input buffering and first butterfly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt <= 0;
            s1_valid <= 0;
        end else if (input_valid) begin
            // Store input in natural order
            sample_real[sample_cnt] <= input_real;
            sample_imag[sample_cnt] <= input_imag;
            
            if (sample_cnt == 7) begin
                // All 8 samples received, perform stage 1 butterflies
                // Butterfly: a+b and a-b for each pair (0,4), (1,5), (2,6), (3,7)
                for (int i = 0; i < 4; i++) begin
                    s1_real[i*2]   <= {sample_real[i], 8'b0} + {sample_real[i+4], 8'b0};
                    s1_imag[i*2]   <= {sample_imag[i], 8'b0} + {sample_imag[i+4], 8'b0};
                    s1_real[i*2+1] <= {sample_real[i], 8'b0} - {sample_real[i+4], 8'b0};
                    s1_imag[i*2+1] <= {sample_imag[i], 8'b0} - {sample_imag[i+4], 8'b0};
                end
                s1_valid <= 1;
                s1_cnt <= 0;
                sample_cnt <= 0;
            end else begin
                sample_cnt <= sample_cnt + 1;
            end
        end
    end
    
    // Stage 2: Second stage butterflies (W8^0 and W8^2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 0;
        end else if (s1_valid) begin
            // Process 2 butterflies per cycle
            if (s1_cnt == 0 || s1_cnt == 1) begin
                // Group 0: indices (0,2) with W8^0
                // Group 1: indices (1,3) with W8^0
                int idx0 = s1_cnt * 4;
                int idx1 = s1_cnt * 4 + 2;
                
                s2_real[idx0]   <= s1_real[idx0] + s1_real[idx1];
                s2_imag[idx0]   <= s1_imag[idx0] + s1_imag[idx1];
                s2_real[idx1]   <= s1_real[idx0] - s1_real[idx1];
                s2_imag[idx1]   <= s1_imag[idx0] - s1_imag[idx1];
                
                s2_real[idx0+1] <= s1_real[idx0+1] + s1_real[idx1+1];
                s2_imag[idx0+1] <= s1_imag[idx0+1] + s1_imag[idx1+1];
                s2_real[idx1+1] <= s1_real[idx0+1] - s1_real[idx1+1];
                s2_imag[idx1+1] <= s1_imag[idx0+1] - s1_imag[idx1+1];
                
                if (s1_cnt == 1) begin
                    s2_valid <= 1;
                    s2_cnt <= 0;
                end
                s1_cnt <= s1_cnt + 1;
            end else begin
                // Group 2: indices (4,6) with W8^0
                // Group 3: indices (5,7) with W8^2
                int idx0 = 4;
                int idx1 = 6;
                
                // W8^2 multiplication: (a + jb) * (-j) = b - ja
                s2_real[idx0]   <= s1_real[idx0] + s1_real[idx1];
                s2_imag[idx0]   <= s1_imag[idx0] + s1_imag[idx1];
                
                // (s1_real[idx0] - s1_real[idx1]) * W8^2
                s2_real[idx1]   <= s1_imag[idx0] - s1_imag[idx1];
                s2_imag[idx1]   <= s1_real[idx1] - s1_real[idx0];
                
                s2_real[idx0+1] <= s1_real[idx0+1] + s1_real[idx1+1];
                s2_imag[idx0+1] <= s1_imag[idx0+1] + s1_imag[idx1+1];
                
                s2_real[idx1+1] <= s1_imag[idx0+1] - s1_imag[idx1+1];
                s2_imag[idx1+1] <= s1_real[idx1+1] - s1_real[idx0+1];
                
                s2_valid <= 1;
                s2_cnt <= 0;
                s1_valid <= 0;
            end
        end
    end
    
    // Stage 3: Final butterflies
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid <= 0;
        end else if (s2_valid) begin
            // Process final stage butterflies
            for (int i = 0; i < 4; i++) begin
                int idx0 = i;
                int idx1 = i + 4;
                
                case (i)
                    0: begin // W8^0
                        s3_real[idx0] <= s2_real[idx0] + s2_real[idx1];
                        s3_imag[idx0] <= s2_imag[idx0] + s2_imag[idx1];
                        s3_real[idx1] <= s2_real[idx0] - s2_real[idx1];
                        s3_imag[idx1] <= s2_imag[idx0] - s2_imag[idx1];
                    end
                    1: begin // W8^1
                        // Multiply by (0.707 - 0.707j) = (a*0.707 + b*0.707) + j(b*0.707 - a*0.707)
                        s3_real[idx0] <= s2_real[idx0] + 
                                        ((s2_real[idx1] * W_REAL1) >> 7) + 
                                        ((s2_imag[idx1] * W_REAL1) >> 7);
                        s3_imag[idx0] <= s2_imag[idx0] + 
                                        ((s2_imag[idx1] * W_REAL1) >> 7) - 
                                        ((s2_real[idx1] * W_REAL1) >> 7);
                        s3_real[idx1] <= s2_real[idx0] - 
                                        ((s2_real[idx1] * W_REAL1) >> 7) - 
                                        ((s2_imag[idx1] * W_REAL1) >> 7);
                        s3_imag[idx1] <= s2_imag[idx0] - 
                                        ((s2_imag[idx1] * W_REAL1) >> 7) + 
                                        ((s2_real[idx1] * W_REAL1) >> 7);
                    end
                    2: begin // W8^2
                        s3_real[idx0] <= s2_real[idx0] + s2_imag[idx1];
                        s3_imag[idx0] <= s2_imag[idx0] - s2_real[idx1];
                        s3_real[idx1] <= s2_real[idx0] - s2_imag[idx1];
                        s3_imag[idx1] <= s2_imag[idx0] + s2_real[idx1];
                    end
                    3: begin // W8^3
                        // Multiply by (-0.707 - 0.707j)
                        s3_real[idx0] <= s2_real[idx0] - 
                                        ((s2_real[idx1] * W_REAL3_ABS) >> 7) + 
                                        ((s2_imag[idx1] * W_REAL3_ABS) >> 7);
                        s3_imag[idx0] <= s2_imag[idx0] - 
                                        ((s2_imag[idx1] * W_REAL3_ABS) >> 7) - 
                                        ((s2_real[idx1] * W_REAL3_ABS) >> 7);
                        s3_real[idx1] <= s2_real[idx0] + 
                                        ((s2_real[idx1] * W_REAL3_ABS) >> 7) - 
                                        ((s2_imag[idx1] * W_REAL3_ABS) >> 7);
                        s3_imag[idx1] <= s2_imag[idx0] + 
                                        ((s2_imag[idx1] * W_REAL3_ABS) >> 7) + 
                                        ((s2_real[idx1] * W_REAL3_ABS) >> 7);
                    end
                endcase
            end
            s3_valid <= 1;
            s3_cnt <= 0;
            s2_valid <= 0;
        end else if (s3_valid) begin
            // Output with bit-reversed order
            for (int i = 0; i < 8; i++) begin
                output_real[bit_rev(i)] <= s3_real[i][15:8];  // Keep upper 8 bits
                output_imag[bit_rev(i)] <= s3_imag[i][15:8];
            end
            output_valid <= 1;
            s3_valid <= 0;
        end else begin
            output_valid <= 0;
        end
    end
    
endmodule