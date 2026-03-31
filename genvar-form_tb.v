// tb_fir_genvar.v
`timescale 1ns / 1ps
import fir_pkg::*;

module tb_fir_genvar();
    logic clk, rst_n, din_valid, dout_valid;
    logic signed [15:0] din;
    logic signed [31:0] dout;
    
    integer file_in, file_out;
    integer samples[0:1999];
    int idx, num_samples;
    
    fir_genvar u_dut (.*);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // Read 2000Hz file
        file_in = $fopen("q_2_14_2000.txt", "r");
        idx = 0;
        while (!$feof(file_in) && idx < 500) begin
            $fscanf(file_in, "%d\n", samples[idx]);
            idx++;
        end
        num_samples = idx;
        $fclose(file_in);
        
        file_out = $fopen("output_genvar_2000.txt", "w");
        
        rst_n = 0;
        #20;
        rst_n = 1;
        #10;
        
        for (idx = 0; idx < num_samples; idx++) begin
            @(posedge clk);
            din = samples[idx];
            din_valid = 1;
        end
        @(posedge clk);
        din_valid = 0;
        
        #1000;
        $fclose(file_out);
        $finish;
    end
    
    always @(posedge clk) begin
        if (dout_valid)
            $fwrite(file_out, "%d\n", dout);
    end
endmodule