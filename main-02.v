`timescale 1 ns / 1 ps

module sine_quant_tb;
    

    real Fs = 48000.0;
    real f = 1000.0;
    real pi = 3.141592653589793;
    real Ts = 1.0 / 48000.0;
    real samples [0:47999];

    task readSamples;
    integer file,i;
    begin
        file = $fopen("samples.txt","r");
        for(i=0;i<48000;i++)$fscanf(file,"%f",samples[i]);
        $fclose(file);
    end
    endtask;
    
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

    function real quantize;
        input real x;
        input integer I;
        input integer F;
        real scale,scaled;
        integer rounded;
        begin
            scale = 2.0 ** F;
            scaled = x*scale;
            rounded = real_to_int(scaled);
            quantize = rounded/scale;
        end
    endfunction
    

    task generateQuantizedValues;
        input integer I, F;
        integer file, i;
        string fname;
        real quantizedVal;
        begin
            fname = $sformatf("q_%0d_%0d_verilog.txt", I, F);
            file = $fopen(fname, "w");
            
            for (i = 0; i < 48000; i = i + 1) begin
                quantizedVal = quantize(samples[i], I, F);
                $fwrite(file, "%0.20f\n", quantizedVal);
            end
            
            $fclose(file);
        end
    endtask
    

    task generateErrors;
        input integer I, F;
        integer q_file, err_file, i;
        string q_fname, err_fname;
        real quantized [0:47999];
        real error;
        begin
            q_fname = $sformatf("q_%0d_%0d_verilog.txt", I, F);
            err_fname = $sformatf("err_q_%0d_%0d.txt", I, F);
            q_file = $fopen(q_fname, "r");
            
            if (q_file == 0) begin
                $display("Can't open file %s", q_fname);
            end
            
            err_file = $fopen(err_fname, "w");
            
            for (i = 0; i < 48000; i = i + 1) begin
                if ($fscanf(q_file, "%f", quantized[i]) != 1) begin
                    $display("Couldn't read value at line %0d", i + 1);
                    $fclose(q_file);
                end
                error = samples[i] - quantized[i];
                $fwrite(err_file, "%0.20f\n", error);
            end
            
            $fclose(err_file);
            $fclose(q_file);
        end
    endtask
    

    function real sqnrDb;
        input integer I, F;
        real signal_power;
        real error_power;
        integer file, i;
        string fname;
        real errorVal;
        begin
            fname = $sformatf("err_q_%0d_%0d.txt", I, F);
            file = $fopen(fname, "r");
            
            if (file == 0) begin
                $display("Can't open file %s", fname);
            end
            
            signal_power = 0.0;
            error_power = 0.0;
            
            for (i = 0; i < 48000; i = i + 1) begin
                if ($fscanf(file, "%f",errorVal) != 1) begin
                    $display("Error reading from file %s at line %0d", fname, i + 1);
                    $fclose(file);
                end
                signal_power += (samples[i] * samples[i]);
                error_power += (errorVal * errorVal);
            end
            
            signal_power /= 48000.0;
            error_power /= 48000.0;
            
            $display("Signal-Power, Error-Power: %0.15f %0.15f", signal_power, error_power);
            sqnrDb = 10 * $log10(signal_power / error_power);
        end
    endfunction
    
    initial begin
        readSamples();

        generateQuantizedValues(3, 14);
        generateQuantizedValues(15, 2);
        generateQuantizedValues(8, 4);
        
        generateErrors(3, 14);
        generateErrors(15, 2);
        generateErrors(8, 4);
        
        $display("SQNR Q(3,14) = %0.15f dB", sqnrDb(3, 14));
        $display("SQNR Q(15,2) = %0.15f dB", sqnrDb(15, 2));
        $display("SQNR Q(8,4) = %0.15f dB", sqnrDb(8, 4));
        
        $finish;
    end
    
endmodule