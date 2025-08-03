`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2025 20:42:43
// Design Name: 
// Module Name: binarisation
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



module binarization_stage (
    input wire clk,
    input wire rst_n,
    input wire [4095:0] pixel_line_flat,    // Flattened 512*8 bits
    input wire line_valid,
    output reg [511:0] binary_line,
    output reg binary_ready,
    output reg stage_complete
);

    // Parameters from the paper
    parameter BLOCK_SIZE = 16;
    parameter NUM_BLOCKS = 34;
    parameter PIPELINE_STAGES = 15;
    
    // Unpack flattened input
    wire [7:0] pixel_line [0:511];
    genvar k;
    generate
        for (k = 0; k < 512; k = k + 1) begin : pixel_unpack
            assign pixel_line[k] = pixel_line_flat[k*8 +: 8];
        end
    endgenerate
    
    // MVCU connections
    wire [7:0] threshold_values [0:33];
    wire [33:0] threshold_ready;
    reg [127:0] mvcu_inputs_flat [0:33];  // Flattened MVCU inputs
    reg [12:0] accumulated_sums [0:33];
    
    // Pipeline registers for 15 stages
    reg [4095:0] pipeline_data_flat [0:14];
    reg [14:0] pipeline_valid;
    
    // Line buffer for 16×16 block processing
    reg [4095:0] line_buffer_flat [0:15];
    reg [3:0] buffer_line_count;
    reg [4:0] line_counter;
    
    integer i, j, m;
    
    // Generate 34 MVCU units
    genvar g;
    generate
        for (g = 0; g < NUM_BLOCKS; g = g + 1) begin : mvcu_dadda_array
            mvcu_dadda mvcu_inst (
                .clk(clk),
                .rst_n(rst_n),
                .pixel_data_flat(mvcu_inputs_flat[g]),
                .previous_sum(accumulated_sums[g]),
                .data_valid(line_valid && (buffer_line_count == 15)),
                .threshold_value(threshold_values[g]),
                .threshold_ready(threshold_ready[g])
            );
        end
    endgenerate
    
    // Line buffer management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_line_count <= 4'b0;
            line_counter <= 5'b0;
            for (i = 0; i < 16; i = i + 1) begin
                line_buffer_flat[i] <= 4096'b0;
            end
        end else if (line_valid) begin
            // Shift line buffer
            for (i = 15; i > 0; i = i - 1) begin
                line_buffer_flat[i] <= line_buffer_flat[i-1];
            end
            
            // Add new line to buffer
            line_buffer_flat[0] <= pixel_line_flat;
            
            // Update counters
            if (buffer_line_count < 15) begin
                buffer_line_count <= buffer_line_count + 1;
            end
            
            line_counter <= line_counter + 1;
        end
    end
    
    // Prepare MVCU inputs with 1-pixel overlap
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
                mvcu_inputs_flat[i] <= 128'b0;
                accumulated_sums[i] <= 13'b0;
            end
        end else if (buffer_line_count == 15) begin
            // Create 16×16 blocks with 1-pixel overlap
            for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    // Calculate pixel position with 15-pixel spacing
                    m = i * 15 + j;
                    if (m < 512) begin
                        mvcu_inputs_flat[i][j*8 +: 8] <= pixel_line_flat[m*8 +: 8];
                    end else begin
                        mvcu_inputs_flat[i][j*8 +: 8] <= 8'b0;
                    end
                end
                
                // Reset accumulated sums for new blocks
                if (line_counter % 16 == 0) begin
                    accumulated_sums[i] <= 13'b0;
                end
            end
        end
    end
    
    // 15-stage pipeline processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                pipeline_data_flat[i] <= 4096'b0;
            end
            pipeline_valid <= 15'b0;
        end else if (line_valid && buffer_line_count == 15) begin
            // Shift pipeline stages
            for (i = PIPELINE_STAGES-1; i > 0; i = i - 1) begin
                pipeline_data_flat[i] <= pipeline_data_flat[i-1];
            end
            
            // Load new data into first stage
            pipeline_data_flat[0] <= line_buffer_flat[0];
            
            // Shift valid signals
            pipeline_valid <= {pipeline_valid[13:0], line_valid};
        end
    end
    
    // Binarization comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_line <= 512'b0;
            binary_ready <= 1'b0;
            stage_complete <= 1'b0;
        end else if (pipeline_valid[14] && (&threshold_ready)) begin
            // Compare each pixel with corresponding block threshold
            for (i = 0; i < 512; i = i + 1) begin
                // Determine which MVCU block this pixel belongs to
                j = i / 15;
                if (j >= NUM_BLOCKS) j = NUM_BLOCKS - 1;
                
                // Binarization comparison
                binary_line[i] <= (pipeline_data_flat[14][i*8 +: 8] > threshold_values[j]) ? 1'b1 : 1'b0;
            end
            
            binary_ready <= 1'b1;
            stage_complete <= 1'b1;
        end else begin
            binary_ready <= 1'b0;
            stage_complete <= 1'b0;
        end
    end

endmodule
