`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 01:05:25
// Design Name: 
// Module Name: tb_fingerprint_processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module tb_fingerprint_processor;

    reg clk;
    reg rst_n;
    reg [31:0] image_data_in;
    reg data_valid;
    wire [511:0] processed_data_out;
    wire processing_done;

    // Clock generation (200 MHz target)
    always #2.5 clk = ~clk;

    // Instantiate the complete system
    fingerprint_processor_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .image_data_in(image_data_in),
        .data_valid(data_valid),
        .processed_data_out(processed_data_out),
        .processing_done(processing_done)
    );

    // Test stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        image_data_in = 32'b0;
        data_valid = 0;

        // Reset sequence
        #10 rst_n = 1;
        #10;

        // Load test image data (128 clock cycles for 512 pixels)
        data_valid = 1;
        for (integer i = 0; i < 128; i = i + 1) begin
            image_data_in = $random; // Random test data
            #5; // One clock cycle
        end
        data_valid = 0;

        // Wait for processing to complete
        wait(processing_done);
        
        $display("Processing completed successfully!");
        $display("Final processed data: %h", processed_data_out);
        
        #100;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %t, Reset: %b, Data Valid: %b, Processing Done: %b", 
                 $time, rst_n, data_valid, processing_done);
    end

endmodule
