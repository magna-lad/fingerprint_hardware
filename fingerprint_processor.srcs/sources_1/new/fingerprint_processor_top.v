`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 01:03:25
// Design Name: 
// Module Name: fingerprint_processor_top
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



module fingerprint_processor_top (
    input wire clk,
    input wire rst_n,
    input wire [31:0] image_data_in,
    input wire data_valid,
    output wire [511:0] processed_data_out,
    output wire processing_done
);

    // Inter-stage connections
    wire [4095:0] loaded_line_flat;
    wire line_loaded;
    wire [511:0] binary_output;
    wire binary_ready;
    wire [511:0] dilated_output;
    wire dilation_ready;
    wire [511:0] thinned_output;
    wire thinning_complete;

    // Loader module instantiation
    loader loader (
        .clock(clk),
        .reset_n(rst_n),
        .data_in(image_data_in),
        .data_valid(data_valid),
        .loaded_image(line_loaded)
    );

    // Convert loader registers to flattened format
    genvar m;
    generate
        for (m = 0; m < 512; m = m + 1) begin : reg_to_flat
            assign loaded_line_flat[m*8 +: 8] = loader_inst.register[m];
        end
    endgenerate

    // Binarization stage
    binarization_stage binarization_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_line_flat(loaded_line_flat),
        .line_valid(line_loaded),
        .binary_line(binary_output),
        .binary_ready(binary_ready),
        .stage_complete(/* not used */)
    );

    // Dilation stage
    dilation_stage dilation_inst (
        .clk(clk),
        .rst_n(rst_n),
        .binary_in(binary_output),
        .data_valid(binary_ready),
        .dilated_out(dilated_output),
        .data_ready(dilation_ready),
        .stage_complete(/* not used */)
    );

    // Thinning stage
    thinning_stage thinning_inst (
        .clk(clk),
        .rst_n(rst_n),
        .binary_in(dilated_output),
        .data_valid(dilation_ready),
        .thinned_out(thinned_output),
        .data_ready(/* not used */),
        .processing_complete(thinning_complete)
    );

    // Final outputs
    assign processed_data_out = thinned_output;
    assign processing_done = thinning_complete;

endmodule
