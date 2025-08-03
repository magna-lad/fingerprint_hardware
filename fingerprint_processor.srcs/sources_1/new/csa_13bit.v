`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 00:56:48
// Design Name: 
// Module Name: csa_13bit
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


module dilation_stage (
    input wire clk,
    input wire rst_n,
    input wire [511:0] binary_in,       // Binary input line from binarization
    input wire data_valid,
    output reg [511:0] dilated_out,     // Dilated output line
    output reg data_ready,
    output reg stage_complete
);

    // 2×2 morphological dilation implementation
    reg [511:0] line_buffer [0:1];      // Two-line buffer for 2×2 window
    reg buffer_valid [0:1];
    reg [15:0] line_counter;
    
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_buffer[0] <= 512'b0;
            line_buffer[1] <= 512'b0;
            buffer_valid[0] <= 1'b0;
            buffer_valid[1] <= 1'b0;
            dilated_out <= 512'b0;
            data_ready <= 1'b0;
            stage_complete <= 1'b0;
            line_counter <= 16'b0;
        end else if (data_valid) begin
            // Shift line buffers
            line_buffer[1] <= line_buffer[0];
            line_buffer[0] <= binary_in;
            buffer_valid[1] <= buffer_valid[0];
            buffer_valid[0] <= data_valid;
            
            // Perform 2×2 dilation when we have two lines
            if (buffer_valid[1]) begin
                for (i = 0; i < 511; i = i + 1) begin
                    // 2×2 dilation: set pixel to 1 if any neighbor in 2×2 window is 1
                    dilated_out[i] <= line_buffer[0][i] | line_buffer[0][i+1] | 
                                     line_buffer[1][i] | line_buffer[1][i+1];
                end
                // Handle last pixel
                dilated_out[511] <= line_buffer[0][511] | line_buffer[1][511];
                
                data_ready <= 1'b1;
                line_counter <= line_counter + 1;
            end
            
            // Completion detection for 512×512 image
            if (line_counter == 512) begin
                stage_complete <= 1'b1;
            end
        end else begin
            data_ready <= 1'b0;
        end
    end

endmodule

