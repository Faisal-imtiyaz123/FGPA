`timescale 1ns/1ns

module tb;

reg        clk;
reg        rst;
reg  [16:0] q_3_14 [0:47999];   
reg  [16:0] q_5_12 [0:47999];   
reg  [16:0] q_3_14_reg, q_5_12_reg;
wire [16:0] q_3_14_aligned;

wire [17:0] add_res, sub_res;
wire [33:0] mul_res;

reg [16:0] i;


function reg[16:0] convert_to_5_12;
input reg[16:0] a;
reg[16:0] temp;
begin
    temp = {{2{a[16]}}, a[16:2]};
    if(a[1] == 1'b1) begin   
        temp = temp + 1'b1;
    end
    convert_to_5_12 = temp;
end
endfunction


assign q_3_14_aligned = convert_to_5_12(q_3_14_reg);

add add_mod (
    .clk(clk),
    .rst(rst),
    .a(q_3_14_aligned), 
    .b(q_5_12_reg), 
    .result(add_res)
);

subtract sub_mod (
    .clk(clk),
    .rst(rst),
    .a(q_3_14_aligned), 
    .b(q_5_12_reg), 
    .result(sub_res)
);

mul mul_mod (
    .clk(clk),
    .rst(rst),
    .a(q_3_14_aligned),  
    .b(q_5_12_reg),  
    .result(mul_res)
);

always #1 clk = ~clk;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        q_3_14_reg <= 17'b0;
        q_5_12_reg <= 17'b0;
        i <= 17'b0;
    end else if(i < 48000) begin
        q_3_14_reg <= q_3_14[i];  
        q_5_12_reg <= q_5_12[i];
        i <= i + 1;
    end
end

task read_q_3_14;
    integer i, file;
    begin
        file = $fopen("q_3_14.txt", "r");
        for(i = 0; i < 48000; i = i + 1) begin
            $fscanf(file, "%b\n", q_3_14[i]);
        end
        $fclose(file);
    end
endtask

task read_q_5_12;
    integer i, file;
    begin
        file = $fopen("q_5_12.txt", "r");
        for(i = 0; i < 48000; i = i + 1) begin
            $fscanf(file, "%b\n", q_5_12[i]);
        end
        $fclose(file);
    end
endtask

initial begin
    $dumpfile("wave-03.vcd"); 
    $dumpvars(0, tb);
end

initial begin
    clk = 0;
    rst = 1;
    i = 17'b0;

    read_q_3_14();
    read_q_5_12(); 
    
    #2 rst = 0;
    #500;
    $finish;
end

endmodule