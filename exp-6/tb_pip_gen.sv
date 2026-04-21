module tb_transposed;
    reg clk=0, rst;
    reg signed [15:0] x1, x2, x3;
    wire signed [47:0] y1, y2, y3;
    
    // 1. Added separate arrays for full and half coefficients
    reg signed [15:0] h_full[0:99];
    reg signed [15:0] h_half[0:49]; 
    
    reg signed [15:0] s950[0:999], s1100[0:999], s2000[0:999];
    integer f1, f2, f3;

    // 2. Updated to instantiate 'fir_transposed_sym' and pass 'h_half'
    fir_transposed_sym #(100) dut1(.clk(clk),.rst(rst),.x(x1),.h(h_half),.y(y1));
    fir_transposed_sym #(100) dut2(.clk(clk),.rst(rst),.x(x2),.h(h_half),.y(y2));
    fir_transposed_sym #(100) dut3(.clk(clk),.rst(rst),.x(x3),.h(h_half),.y(y3));

    always #1 clk = ~clk;

    initial begin
        // 3. Read the full file, then copy the first 50 coefficients
        $readmemh("fir_coeff_q214.txt", h_full);
        for(int k=0; k<50; k++) begin
            h_half[k] = h_full[k];
        end

        $readmemh("sine950_Q214.txt", s950);
        $readmemh("sine1100_Q214.txt", s1100);
        $readmemh("sine2000_Q214.txt", s2000);
        
        f1=$fopen("out_trans_950.txt","w"); 
        f2=$fopen("out_trans_1100.txt","w"); 
        f3=$fopen("out_trans_2000.txt","w");
        
        rst=1; x1=0; x2=0; x3=0; #10 rst=0;
        
        for(int i=0; i<1000; i++) begin
            @(posedge clk); 
            x1<=s950[i]; 
            x2<=s1100[i]; 
            x3<=s2000[i];
            
            $fdisplay(f1, "%f", $itor(y1)/(1<<28));
            $fdisplay(f2, "%f", $itor(y2)/(1<<28));
            $fdisplay(f3, "%f", $itor(y3)/(1<<28));
        end
        
        // Good practice to close files before finishing
        $fclose(f1); 
        $fclose(f2); 
        $fclose(f3);
        $finish;
    end
endmodule