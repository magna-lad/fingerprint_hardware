`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 00:59:08
// Design Name: 
// Module Name: thinning_stage
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



module thinning_stage (
    input wire clk,
    input wire rst_n,
    input wire [511:0] binary_in,
    input wire data_valid,
    output reg [511:0] thinned_out,
    output reg data_ready,
    output reg processing_complete
);

    parameter SUPER_STAGES = 6;
    
    // 3×3 line buffer
    reg [511:0] line_buffer [0:2];
    reg [1:0] buffer_count;
    reg [2:0] iteration_count;
    reg [8:0] window_3x3;
    
    // TPC outputs
    wire tpc1_remove, tpc2_remove;
    reg sub_iteration;
    
    integer i, j;

    // Instantiate Thinning Processor Circuits
    thinning_processor tpc1 (
        .window_3x3(window_3x3),
        .iteration_type(1'b0),
        .pixel_remove(tpc1_remove)
    );
    
    thinning_processor tpc2 (
        .window_3x3(window_3x3),
        .iteration_type(1'b1),
        .pixel_remove(tpc2_remove)
    );

    // Line buffer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 3; i = i + 1) begin
                line_buffer[i] <= 512'b0;
            end
            buffer_count <= 2'b0;
            iteration_count <= 3'b0;
            thinned_out <= 512'b0;
            data_ready <= 1'b0;
            processing_complete <= 1'b0;
            sub_iteration <= 1'b0;
        end else if (data_valid) begin
            // Shift line buffer
            line_buffer[2] <= line_buffer[1];
            line_buffer[1] <= line_buffer[0];
            line_buffer[0] <= binary_in;
            
            if (buffer_count < 2) begin
                buffer_count <= buffer_count + 1;
            end
            
            // Process when we have 3 lines
            if (buffer_count == 2) begin
                for (i = 1; i < 511; i = i + 1) begin
                    // Form 3×3 window
                    window_3x3 <= {line_buffer[2][i-1], line_buffer[2][i], line_buffer[2][i+1],
                                  line_buffer[1][i-1], line_buffer[1][i], line_buffer[1][i+1],
                                  line_buffer[0][i-1], line_buffer[0][i], line_buffer[0][i+1]};
                    
                    // Apply thinning
                    if (!sub_iteration) begin
                        thinned_out[i] <= line_buffer[1][i] & ~tpc1_remove;
                    end else begin
                        thinned_out[i] <= line_buffer[1][i] & ~tpc2_remove;
                    end
                end
                
                // Handle border pixels
                thinned_out[0] <= line_buffer[1][0];
                thinned_out[511] <= line_buffer[1][511];
                
                data_ready <= 1'b1;
                
                // Toggle sub-iteration
                sub_iteration <= ~sub_iteration;
                
                // Count iterations
                if (sub_iteration) begin
                    iteration_count <= iteration_count + 1;
                end
                
                // Check completion
                if (iteration_count == 6) begin
                    processing_complete <= 1'b1;
                end
            end
        end
    end

endmodule
