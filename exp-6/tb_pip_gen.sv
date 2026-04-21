`timescale 1ns/1ns
module tb_fir_direct();
    reg clk, rst_n;
    wire signed [39:0] dout_950;
    wire signed [39:0] dout_1100;
    wire signed [39:0] dout_2000;
    reg signed [15:0] din_950;
    reg signed [15:0] din_1100;
    reg signed [15:0] din_2000;
    reg signed [15:0] coeffs [0:99];
    reg signed [15:0] samples_950 [0:1052];
    reg signed [15:0] samples_1100 [0:909];
    reg signed [15:0] samples_2000 [0:499];
    reg signed [39:0] out_950 [0:1899];
    reg signed [39:0] out_1100 [0:1899];
    reg signed [39:0] out_2000 [0:1899];
    integer idx;
    
    // Three separate FIR modules
    fir_genvar #(.TAPS(100)) u_dut_950 (
        .clk(clk),
        .rst_n(rst_n),
        .din(din_950),
        .dout(dout_950),
        .coeffs(coeffs)
    );
    
    fir_genvar #(.TAPS(100)) u_dut_1100 (
        .clk(clk),
        .rst_n(rst_n),
        .din(din_1100),
        .dout(dout_1100),
        .coeffs(coeffs)
    );
    
    fir_genvar #(.TAPS(100)) u_dut_2000 (
        .clk(clk),
        .rst_n(rst_n),
        .din(din_2000),
        .dout(dout_2000),
        .coeffs(coeffs)
    );
    
    initial clk = 0;
    always #1 clk = ~clk;

    always @(posedge clk) begin
        if(rst_n) begin
            idx <= 0;
            din_950 <= 16'b0;
            din_1100 <= 16'b0;
            din_2000 <= 16'b0;
        end
        else begin
            // Apply different samples to each input
            if(idx <= 1052) din_950 <= samples_950[idx];
            else din_950 <= 16'b0;
            
            if(idx <= 909) din_1100 <= samples_1100[idx];
            else din_1100 <= 16'b0;
            
            if(idx <= 499) din_2000 <= samples_2000[idx];
            else din_2000 <= 16'b0;
            
            // Store outputs
            out_950[idx] <= dout_950;
            out_1100[idx] <= dout_1100;
            out_2000[idx] <= dout_2000;
            
            idx <= idx + 1;
        end
    end

    task read_coeffs;
        integer coeff_file;
        integer i;
        coeff_file = $fopen("fc_quantized_2_14.txt", "r");
        if (coeff_file == 0) begin
            $display("Error: Cannot open fc_quantized_2_14.txt");
            $finish;
        end
        for (i = 0; i < 100; i = i + 1)
            $fscanf(coeff_file, "%b\n", coeffs[i]);
        $fclose(coeff_file);
        $display("Read 100 coefficients");
    endtask;

    task read_q_2_14_950;
        integer in_file;
        integer idx;
        in_file = $fopen("q_2_14_950.txt", "r");
        if (in_file == 0) begin
            $display("Error: Cannot open q_2_14_950.txt");
            $finish;
        end
        for (idx = 0; idx < 1053; idx = idx + 1) begin
            $fscanf(in_file, "%b\n", samples_950[idx]);
        end
        $fclose(in_file);
        $display("Read 1053 samples for 950 Hz");
    endtask;
    
    task read_q_2_14_1100;
        integer in_file;
        integer idx;
        in_file = $fopen("q_2_14_1100.txt", "r");
        if (in_file == 0) begin
            $display("Error: Cannot open q_2_14_1100.txt");
            $finish;
        end
        for (idx = 0; idx < 910; idx = idx + 1) begin
            $fscanf(in_file, "%b\n", samples_1100[idx]);
        end
        $fclose(in_file);
        $display("Read 910 samples for 1100 Hz");
    endtask;

    task read_q_2_14_2000;
        integer in_file;
        integer idx;
        in_file = $fopen("q_2_14_2000.txt", "r");
        if (in_file == 0) begin
            $display("Error: Cannot open q_2_14_2000.txt");
            $finish;
        end
        for (idx = 0; idx < 500; idx = idx + 1) begin
            $fscanf(in_file, "%b\n", samples_2000[idx]);
        end
        $fclose(in_file);
        $display("Read 500 samples for 2000 Hz");
    endtask;
    
    task readFiles;
        read_coeffs();
        read_q_2_14_950();
        read_q_2_14_1100();
        read_q_2_14_2000();
    endtask;
    
    task writeFiles;
        integer j, out_950_file, out_1100_file, out_2000_file;
        out_950_file = $fopen("out_direct_950.txt", "w");
        out_1100_file = $fopen("out_direct_1100.txt", "w");
        out_2000_file = $fopen("out_direct_2000.txt", "w");
        
        for(j = 0; j < idx; j = j + 1) begin
            $fdisplay(out_950_file, "%b", out_950[j]);
            $fdisplay(out_1100_file, "%b", out_1100[j]);
            $fdisplay(out_2000_file, "%b", out_2000[j]);
        end
        
        $fclose(out_950_file);
        $fclose(out_1100_file);
        $fclose(out_2000_file);
        $display("Wrote %0d samples to output files", idx);
    endtask;

    initial begin
        $dumpfile("wave_direct.vcd"); 
        $dumpvars(0, tb_fir_direct);
    end
    
    initial begin
        rst_n = 1;
        idx = 0;
        
        readFiles();
        
        #2;
        rst_n = 0;
        
        // Run for enough cycles to process all samples + pipeline flush
        #( (1053 + 100) * 2 );  // 2ns per clock cycle (500MHz)
        
        writeFiles();
        $finish;
    end
endmodule