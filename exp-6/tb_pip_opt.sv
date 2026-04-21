`timescale 1ns/1ns
module tb_fir_optimized();
    reg clk, rst_n;
    wire signed [39:0] dout_950, dout_1100, dout_2000;
    reg signed [15:0] din_950, din_1100, din_2000;
    reg signed [15:0] coeffs [0:99];
    reg signed [15:0] samples_950 [0:1052];
    reg signed [15:0] samples_1100 [0:1052];
    reg signed [15:0] samples_2000 [0:1052];
    reg signed [39:0] out_950 [0:1899];
    reg signed [39:0] out_1100 [0:1899];
    reg signed [39:0] out_2000 [0:1899];
    integer idx;
    
    fir_optimized #(.TAPS(100)) u_dut_950 (
    .clk(clk),
    .rst_n(rst_n),
    .din(din_950),
    .dout(dout_950),
    .coeffs(coeffs)
);
        fir_optimized #(.TAPS(100)) u_dut2 (
            .clk(clk),
            .rst_n(rst_n),
            .din(din_1100),
            .dout(dout_1100),
            .coeffs(coeffs)
        );
    fir_optimized #(.TAPS(100)) u_dut3 (
        .clk(clk),
        .rst_n(rst_n),
        .din(din_2000),
        .dout(dout_2000),
        .coeffs(coeffs)
    );

    
    initial clk = 0;
    always #1 clk = ~clk;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            idx <= 0;
            din_950 <= 16'sb0;
            din_1100 <= 16'sb0;
            din_2000 <= 16'sb0;
        end
        else begin
            if (idx < 1053) begin
                din_950 <= samples_950[idx];
                din_1100 <= samples_1100[idx];
                din_2000 <= samples_2000[idx];
                out_950[idx] <= dout_950;
                out_1100[idx] <= dout_1100;
                out_2000[idx] <= dout_2000;
                idx <= idx + 1;
            end
        end
    end
    
    task read_coeffs;
        integer coeff_file, i;
        begin
            coeff_file = $fopen("fc_quantized_2_14.txt", "r");
            for (i = 0; i < 100; i = i + 1)
                $fscanf(coeff_file, "%b\n", coeffs[i]);
            $fclose(coeff_file);
            $display("Read 100 coefficients");
        end
    endtask
    
    task read_samples;
        integer file_950, file_1100, file_2000, i;
        begin
            file_950 = $fopen("q_2_14_950.txt", "r");
            file_1100 = $fopen("q_2_14_1100.txt", "r");
            file_2000 = $fopen("q_2_14_2000.txt", "r");
            
            for (i = 0; i < 1053; i = i + 1) begin
                $fscanf(file_950, "%b\n", samples_950[i]);
                $fscanf(file_1100, "%b\n", samples_1100[i]);
                $fscanf(file_2000, "%b\n", samples_2000[i]);
            end
            
            $fclose(file_950);
            $fclose(file_1100);
            $fclose(file_2000);
            $display("Read samples for all frequencies");
        end
    endtask
    
    task write_outputs;
        integer j, f_950, f_1100, f_2000;
        begin
            f_950 = $fopen("out_950_optimized.txt", "w");
            f_1100 = $fopen("out_1100_optimized.txt", "w");
            f_2000 = $fopen("out_2000_optimized.txt", "w");
            
            for (j = 100; j < 603; j = j + 1) begin  // Skip initial transients
                $fwrite(f_950, "%b\n", out_950[j]);
                $fwrite(f_1100, "%b\n", out_1100[j]);
                $fwrite(f_2000, "%b\n", out_2000[j]);
            end
            
            $fclose(f_950);
            $fclose(f_1100);
            $fclose(f_2000);
            $display("Written optimized outputs");
        end
    endtask
    
    initial begin
        $dumpfile("wave_optimized.vcd");
        $dumpvars(0, tb_fir_optimized);
    end
    
    initial begin
        rst_n = 0;
        idx = 0;
        
        read_coeffs();
        read_samples();
        
        #2;
        rst_n = 1;
        
        #10008;
        
        write_outputs();
        $finish;
    end
    
endmodule