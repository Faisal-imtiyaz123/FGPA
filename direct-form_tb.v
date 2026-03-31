module tb_fir_direct();
    reg clk, rst_n;
    wire [31:0] dout;
    reg [15:0] din;
    reg [15:0] coeffs [0:99];
    reg [15:0] samples [0:1999];
    reg [31:0] out [0:499];
    integer idx;
    
    fir_direct u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout),
        .coeffs(coeffs)
    );
    
    initial clk = 0;
    always #1 clk = ~clk;

    always @(posedge clk)begin
        if(rst_n)begin
            idx<=0;
            din<=16'b0;
        end
        else begin
            if(idx<501)begin
                din<=samples[idx];
                out[idx]<=dout;
                idx = idx+1;
            end
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
        while (!$feof(in_file) && idx < 600) begin
            $fscanf(in_file, "%b\n", samples[idx]);
            idx = idx + 1;
        end
        $fclose(in_file);
    endtask;

    task writeFiles;
       integer j,out_file;
        out_file = $fopen("out_950_verilog.txt","w");
        for(j=0;j<500;j++)begin
            $fwrite(out_file,"%b\n",out[j]);
        end
    endtask;

    initial begin
        $dumpfile("wave-05.vcd"); 
        $dumpvars(0, tb_fir_direct);
    end
    initial begin
        rst_n = 1;
        idx =0;

        read_coeffs();
        read_q_2_14_950();

        #2;
        rst_n = 0;

        #10002;
      
        writeFiles();
        $finish;
    end
   
endmodule