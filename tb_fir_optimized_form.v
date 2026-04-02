`timescale 1ns / 1ps

module tb_fir_optimized_form();
    
    reg clk;
    reg rst_n;
    reg signed [15:0] test_input;
    reg valid_in;
    wire signed [15:0] filter_output;
    wire valid_out;
    
    integer coeff_file, signal_file, output_file;
    integer i, j, num_samples;
    reg [15:0] coeff_data [0:99];
    reg [15:0] signal_data [0:999];
    
    // Instantiate optimized FIR filter
    fir_optimized_form #(.TAPS(100)) uut (
        .clk(clk),
        .rst_n(rst_n),
        .x_in(test_input),
        .valid_in(valid_in),
        .y_out(filter_output),
        .valid_out(valid_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test procedure
    initial begin
        rst_n = 0;
        valid_in = 0;
        test_input = 16'sd0;
        
        #20;
        rst_n = 1;
        #10;
        
        // Load coefficients
        coeff_file = $fopen("filter_coeffs_q214.txt", "r");
        if (coeff_file == 0) begin
            $display("Error: Could not open filter_coeffs_q214.txt");
            $finish;
        end
        
        for (i = 0; i < 100; i = i + 1) begin
            $fscanf(coeff_file, "%d\n", coeff_data[i]);
            uut.coeff[i] = coeff_data[i];
        end
        $fclose(coeff_file);
        
        // Process signals
        process_signal("signal_950hz_q214.txt", "output_optimized_950hz.txt");
        process_signal("signal_1100hz_q214.txt", "output_optimized_1100hz.txt");
        process_signal("signal_2000hz_q214.txt", "output_optimized_2000hz.txt");
        
        #100;
        $finish;
    end
    
    task process_signal;
        input string input_filename;
        input string output_filename;
        integer signal_file_in, signal_file_out;
        integer sample_count;
        
        begin
            signal_file_in = $fopen(input_filename, "r");
            signal_file_out = $fopen(output_filename, "w");
            
            sample_count = 0;
            
            while (!$feof(signal_file_in)) begin
                if ($fscanf(signal_file_in, "%d\n", signal_data[sample_count]) == 1) begin
                    test_input = signal_data[sample_count];
                    valid_in = 1;
                    #10;
                    
                    @(posedge clk);
                    while (!valid_out) begin
                        @(posedge clk);
                    end
                    
                    $fdisplay(signal_file_out, "%d", filter_output);
                    sample_count = sample_count + 1;
                end
            end
            
            $fclose(signal_file_in);
            $fclose(signal_file_out);
        end
    endtask

endmodule