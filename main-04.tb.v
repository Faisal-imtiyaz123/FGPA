`timescale 1ns/1ns
module tb;
    localparam F = 8;           // Fractional bits
    localparam CLK_PERIOD = 1ns; // 10ns clock period
    localparam I_BITS = 8;
    localparam F_BITS = 16;
    localparam TOTAL_BITS = I_BITS + F_BITS;
    reg clk;
    reg reset;
    reg [TOTAL_BITS-1:0] num, den;
    wire [TOTAL_BITS-1:0] result;
    reg [3:0] i;
    integer nums[0:9];
    integer dens[0:9];
    reg [TOTAL_BITS-1:0] results [0:10];
    
    // Instantiate DUT (clocked version)
    newton_raphson #(
        .I_BITS(I_BITS),
        .F_BITS(F_BITS)
    ) dut (
        .numerator(num),
        .denominator(den),
        .result(result)
    );
    task write_results;
        integer fd, j;
        begin
            fd = $fopen("newton_raphson_results.txt", "w");
            if (fd == 0) begin
                $display("ERROR: Could not open output file!");
                $finish;
            end
            for (j = 1; j <=10; j = j + 1) begin
                $fwrite(fd,"%b\n", results[j]);
            end
            $fclose(fd);
        end
    endtask
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Waveform dumping
    initial begin
        $dumpfile("newton_raphson.vcd");
        $dumpvars(0, tb);
    end
    function [15:0] make_8_8;
        input integer val;
        reg [7:0] int_part;
        int_part = val;
        make_8_8 = {int_part,8'b0};
    endfunction
    always @(posedge clk)begin
        if(reset)begin
            nums[0]<=3;
            dens[0]<=21;
        end
        else if(i<=10) begin
            num<=make_8_8(nums[i]);
            den<=make_8_8(dens[i]);
            results[i]<=result;
            i<=i+1;
        end
    end
    initial begin
        nums[0] = 3;   nums[1] = 7;   nums[2] = 9;   nums[3] = 11;  nums[4] = 17;
        nums[5] = 31;  nums[6] = 41;  nums[7] = 51;  nums[8] = 67;  nums[9] = 81;
        
        dens[0] = 21;  dens[1] = 31;  dens[2] = 41;  dens[3] = 51;  dens[4] = 81;
        dens[5] = 67;  dens[6] = 91;  dens[7] = 101; dens[8] = 131; dens[9] = 151;
    end
    initial begin
        // Initialize
        reset = 1;
        i=0;

        #(CLK_PERIOD*2);
        
        reset = 0;
        #(CLK_PERIOD *30);
        write_results();
        $finish;
    end

endmodule