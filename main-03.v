module basic_operation;

real q_3_14 [0:47999];
real q_15_2 [0:47999];



task read_q_3_14;

integer i,file;
real val;
begin
    file = $fopen("q_3_14.txt","r");
for(i=0;i<48000;i++)begin
    $fscanf(file,"%f",q_3_14[i]);
end
$fclose(file);
end
endtask

task read_q_5_12;

integer i,file;
real val;
begin
    file = $fopen("q_15_2.txt","r");
    for(i=0;i<48000;i++)
    begin
      $fscanf(file,"%f",q_15_2[i]);
    end
  $fclose(file);
end

endtask

function integer real_to_int;
    input real num;
    integer int_num;
    real frac;
    
    begin
        int_num = num; 
        frac = num - int_num;
        
        if (frac >= 0.5) begin
            real_to_int = int_num + 1;
        end else begin
            real_to_int = int_num;
        end
    end
endfunction

function real convert;
input real num; input integer m,n;
real scale,scaled;
integer rounded;
real val;

begin

scale = 2**n;
scaled = num*scale;
rounded = real_to_int(scaled);
val = rounded/scale;
convert = val;

end
endfunction

task add;

integer i,file;
real res,x;

begin

file = $fopen("add.txt","w");
for(i=0;i<48000;i++)begin
    x = convert(q_3_14[i],15,2);
    res = x + q_15_2[i];
    $fwrite(file,"%0.20f\n",res);
end
$fclose(file);

end

endtask

task subtract;

integer i,file;
real res,x;

begin

file = $fopen("sub.txt","w");
for(i=0;i<48000;i++)begin
    x = convert(q_3_14[i],15,2);
    res = x - q_15_2[i];
    $fwrite(file,"%0.20f\n",res);
end
$fclose(file);

end


endtask

task mul;


integer i,file;
real res,val;

begin

file = $fopen("mul.txt","w");
for(i=0;i<48000;i++)begin
    res = q_3_14[i] * q_15_2[i];
    val = convert(res,18,16);
    $fwrite(file,"%0.20f\n",val);
end
$fclose(file);

end


endtask

initial begin
    read_q_3_14();read_q_5_12();
    add();subtract();mul();
    // integer x;
    // x = real_to_int(-3.6);
    // $display(x);
end

endmodule;