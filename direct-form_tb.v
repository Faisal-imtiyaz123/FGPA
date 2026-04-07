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
    reg signed [15:0] samples [0:1052];
    reg signed [39:0] out_950 [0:1899];
    reg signed [39:0] out_1100 [0:1899];
    reg signed [39:0] out_2000 [0:1899];
    integer idx;
    
    fir_direct u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .din_950(din_950),
        .din_1100(din_1100),
        .din_2000(din_2000),
        .dout_950(dout_950),
        .dout_1100(dout_1100),
        .dout_2000(dout_2000),
        .coeffs(coeffs),
        .samples(samples)
    );
    
    initial clk = 0;
    always #1 clk = ~clk;

    always @(posedge clk)begin
        if(rst_n)begin
            idx<=0;
            din_950<=16'b0;
            din_1100<=16'b0;
            din_2000<=16'b0;
        end
        else begin
                din_950<=samples[idx];
                din_1100<=samples[idx];
                din_2000<=samples[idx];
                out_950[idx]<=dout_950;
                out_1100[idx]<=dout_1100;
                out_2000[idx]<=dout_2000;
                idx <= idx+1;
        end
    end

    task read_coeffs;
       integer  coeff_file;
       integer  i;
        coeff_file = $fopen("fc_quantized_2_14.txt", "r");
        for (i = 0; i < 100; i = i + 1)
            $fscanf(coeff_file, "%b\n", coeffs[i]);
        $fclose(coeff_file);
        $display("Read 100 coefficients");

    endtask;

    task read_q_2_14_950;
        integer in_file;
        integer  idx;
        in_file = $fopen("q_2_14_950.txt", "r");
        idx = 0;
        for (idx=0;idx<1053;idx++) begin
            $fscanf(in_file, "%b\n", samples[idx]);
        end
        $fclose(in_file);
    endtask;
    
    task readFiles;
        read_coeffs();
        read_q_2_14_950();
        read_q_2_14_1100();
        read_q_2_14_2000();
    endtask;
    task read_q_2_14_1100;
        integer in_file;
        integer  idx;
        in_file = $fopen("q_2_14_1100.txt", "r");
        idx = 0;
        for (idx=0;idx<1053;idx++) begin
            $fscanf(in_file, "%b\n", samples[idx]);
        end
        $fclose(in_file);
    endtask;

    task read_q_2_14_2000;
        integer in_file;
        integer  idx;
        in_file = $fopen("q_2_14_2000.txt", "r");
        idx = 0;
        for (idx=0;idx<1053;idx++) begin
            $fscanf(in_file, "%b\n", samples[idx]);
        end
        $fclose(in_file);
    endtask;

    task writeFiles;
       integer j,out_950_file,out_1100_file,out_2000_file;
        out_950_file = $fopen("out_950_verilog.txt","w");
        out_1100_file = $fopen("out_1100_verilog.txt","w");
        out_2000_file = $fopen("out_2000_verilog.txt","w");
        for(j=0;j<503;j++)begin
            $fwrite(out_950_file,"%b\n",out_950[j]);
            $fwrite(out_1100_file,"%b\n",out_1100[j]);
            $fwrite(out_2000_file,"%b\n",out_2000[j]);
        end
        $fclose(out_950_file);
        $fclose(out_1100_file);
        $fclose(out_2000_file);
    endtask;

    initial begin
        $dumpfile("wave-05.vcd"); 
        $dumpvars(0, tb_fir_direct);
    end
    initial begin
        rst_n = 1;
        idx =0;

        readFiles();

        #2;
        rst_n = 0;

        #10008;
      
        writeFiles();
        $finish;
    end
   
endmodule