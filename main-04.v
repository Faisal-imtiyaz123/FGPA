module newtonRaphson;
    function real normalize;
        input real D_in;
        real D_out;
        begin
            D_out = D_in;
            while(D_out < 0.5 || D_out > 1) begin
                if (D_out < 0.5) begin
                    D_out = D_out * 2;
                end
                else begin
                    D_out = D_out / 2;
                end
            end
        end
        normalize = D_out;
    endfunction

    function real compute_scale;
        input real D_in;
        real scale;
        begin
            scale = 1.0;
            while(D_in < 0.5 || D_in > 1) begin
                if (D_in < 0.5) begin
                    D_in = D_in * 2;
                    scale = scale / 2;
                end
                else begin
                    D_in = D_in / 2;
                    scale = scale * 2;
                end
            end
        end
        compute_scale = scale;
    endfunction

    function real initialGuess;
        input real D;
        begin
            initialGuess = 48.0/17.0 - (32.0/17.0) * D;
        end
    endfunction

    function real x_n_plus_1;
        input real x_n;
        input real D;
        begin
            x_n_plus_1 = x_n * (2.0 - x_n * D);
        end
    endfunction

    function real newton_raphson;
        input real D;
        real D_norm,scale;
        real x_n, x_n_1;
        begin
            scale = compute_scale(D);
            D_norm = normalize(D);
            x_n = initialGuess(D_norm);
            x_n_1 = x_n_plus_1(x_n, D_norm);
            
            while ($abs(x_n_1 - x_n) > 1e-6) begin
                x_n = x_n_1;
                x_n_1 = x_n_plus_1(x_n, D_norm);
            end
            
            newton_raphson = x_n_1 / scale;
        end
    endfunction

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


    function real fixed_point;
        input real x;
        input integer I;
        input integer F;
        real scale_val, scaled;
        integer rounded;
        begin
            scale_val = 2.0 ** F;
            scaled = x * scale_val;
            rounded = real_to_int(scaled);
            fixed_point = rounded / scale_val;
        end
    endfunction

    initial begin
        real arr [0:9], numerators [0:9], denominators [0:9];
        real res;
        real fraction;
        integer i, file;
        
        arr[0] = 3.0/21.0;
        arr[1] = 7.0/31.0;
        arr[2] = 9.0/41.0;
        arr[3] = 11.0/51.0;
        arr[4] = 17.0/81.0;
        arr[5] = 31.0/67.0;
        arr[6] = 41.0/91.0;
        arr[7] = 51.0/101.0;
        arr[8] = 67.0/131.0;
        arr[9] = 81.0/151.0;

        numerators[0] = 3.0;
        numerators[1] = 7.0;
        numerators[2] = 9.0;
        numerators[3] = 11.0;
        numerators[4] = 17.0;
        numerators[5] = 31.0;
        numerators[6] = 41.0;
        numerators[7] = 51.0;
        numerators[8] = 67.0;
        numerators[9] = 81.0;

        denominators[0] = 21.0;
        denominators[1] = 31.0;
        denominators[2] = 41.0;
        denominators[3] = 51.0;
        denominators[4] = 81.0;
        denominators[5] = 67.0;
        denominators[6] = 91.0;
        denominators[7] = 101.0;
        denominators[8] = 131.0;
        denominators[9] = 151.0;
        
        file = $fopen("arr_processed_verilog.txt", "w");
        
        for (i=0; i<10; i=i+1) 
        begin
             fraction = newton_raphson(denominators[i]);
             $display("Fraction: %0.8f", fraction);
             res = numerators[i] * fraction;
            $display("Result: %0.8f", res);
             $fwrite(file, "%0.8f\n", fixed_point(res, 8, 8));
        end
    end

endmodule