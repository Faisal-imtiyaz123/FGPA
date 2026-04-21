module tb_direct;
    reg clk=0, rst;
    reg signed [15:0] x1, x2, x3;
    wire signed [47:0] y1, y2, y3;
    reg signed [15:0] h[0:99], s950[0:999], s1100[0:999], s2000[0:999];
    integer f1, f2, f3;

    fir_direct_pipeline #(100) dut1(.clk(clk),.rst(rst),.x(x1),.coeff(h),.y(y1));
    fir_direct_pipeline #(100) dut2(.clk(clk),.rst(rst),.x(x2),.coeff(h),.y(y2));
    fir_direct_pipeline #(100) dut3(.clk(clk),.rst(rst),.x(x3),.coeff(h),.y(y3));

    always #1 clk = ~clk;

    initial begin
        $readmemh("fir_coeff_q214.txt", h);
        $readmemh("sine950_Q214.txt", s950);
        $readmemh("sine1100_Q214.txt", s1100);
        $readmemh("sine2000_Q214.txt", s2000);
        f1=$fopen("out_direct_950.txt","w"); f2=$fopen("out_direct_1100.txt","w"); f3=$fopen("out_direct_2000.txt","w");
        rst=1; x1=0; x2=0; x3=0; #10 rst=0;
        for(int i=0; i<1000; i++) begin
            @(posedge clk); x1<=s950[i]; x2<=s1100[i]; x3<=s2000[i];
            $fdisplay(f1, "%f", $itor(y1)/(1<<28));
            $fdisplay(f2, "%f", $itor(y2)/(1<<28));
            $fdisplay(f3, "%f", $itor(y3)/(1<<28));
        end
        $fclose(f1); $fclose(f2); $fclose(f3); $finish;
    end
endmodule