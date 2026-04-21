module tb_direct;
    reg clk=0, rst;
    reg signed [15:0] x1, x2, x3;
    wire signed [47:0] y1, y2, y3;
    reg signed [15:0] coeff[0:99], s950[0:1052], s1100[0:909], s2000[0:499];
    integer f1, f2, f3;
    integer i;

    fir_direct_pipeline #(100) dut1(.clk(clk), .rst(rst), .x(x1), .coeff(coeff), .y(y1));
    fir_direct_pipeline #(100) dut2(.clk(clk), .rst(rst), .x(x2), .coeff(coeff), .y(y2));
    fir_direct_pipeline #(100) dut3(.clk(clk), .rst(rst), .x(x3), .coeff(coeff), .y(y3));

    always #1 clk = ~clk;
    
    initial begin
        $dumpfile("wave_direct.vcd"); 
        $dumpvars(0, tb_direct);
    end
    
    initial begin
        // Fix: Changed variable names to match declarations
        $readmemb("fc_quantized_2_14.txt", coeff);  // was 'h', now 'coeff'
        $readmemb("q_2_14_950.txt", s950);
        $readmemb("q_2_14_1100.txt", s1100);
        $readmemb("q_2_14_2000.txt", s2000);
        
        f1 = $fopen("out_direct_950.txt", "w");
        f2 = $fopen("out_direct_1100.txt", "w");
        f3 = $fopen("out_direct_2000.txt", "w");
        
        rst = 1; 
        x1 = 0; x2 = 0; x3 = 0;
        #10 rst = 0;
        
        // Add the main simulation loop
        for(i = 0; i < 500; i++) begin  // Run for 500 samples (smallest array size)
            @(posedge clk);
            
            // Apply inputs (with bounds checking)
            if(i <= 1052) x1 <= s950[i];
            if(i <= 909)  x2 <= s1100[i];
            if(i <= 499)  x3 <= s2000[i];
            
        end
        
        $fclose(f1); 
        $fclose(f2); 
        $fclose(f3);
        $finish;
    end
endmodule