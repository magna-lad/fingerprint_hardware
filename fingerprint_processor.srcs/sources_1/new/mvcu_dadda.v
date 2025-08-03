`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 01:01:42
// Design Name: 
// Module Name: mvcu_dadda
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


module mvcu_dadda (
    input wire clk,
    input wire rst_n,
    input wire [127:0] pixel_data_flat,    // Flattened 16 pixels (16*8=128 bits)
    input wire [12:0] previous_sum,        // Sum from previous line
    input wire data_valid,
    output reg [7:0] threshold_value,
    output reg threshold_ready
);

    // Unpack flattened pixel data
    wire [7:0] pixel_data [0:15];
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : pixel_unpack
            assign pixel_data[k] = pixel_data_flat[k*8 +: 8];
        end
    endgenerate

    // Dadda tree structure for 17-input addition
    wire [12:0] stage1_sum [0:3];
    wire [12:0] stage1_carry [0:3];
    wire [12:0] stage1_reduced [0:12];
    
    wire [12:0] stage2_outputs [0:8];
    wire [12:0] stage3_outputs [0:5];
    wire [12:0] stage4_outputs [0:3];
    wire [12:0] stage5_outputs [0:2];
    wire [12:0] final_sum, final_carry;
    
    wire [13:0] total_result;
    
    // Stage 1: Initial reduction from 17 to 13 inputs
    csa_13bit csa1_1 (
        .a({5'b0, pixel_data[0]}),
        .b({5'b0, pixel_data[1]}),
        .c({5'b0, pixel_data[2]}),
        .sum(stage1_sum[0]),
        .carry(stage1_carry[0])
    );
    
    csa_13bit csa1_2 (
        .a({5'b0, pixel_data[3]}),
        .b({5'b0, pixel_data[4]}),
        .c({5'b0, pixel_data[5]}),
        .sum(stage1_sum[1]),
        .carry(stage1_carry[1])
    );
    
    csa_13bit csa1_3 (
        .a({5'b0, pixel_data[6]}),
        .b({5'b0, pixel_data[7]}),
        .c({5'b0, pixel_data[8]}),
        .sum(stage1_sum[2]),
        .carry(stage1_carry[2])
    );
    
    csa_13bit csa1_4 (
        .a({5'b0, pixel_data[9]}),
        .b({5'b0, pixel_data[10]}),
        .c({5'b0, pixel_data[11]}),
        .sum(stage1_sum[3]),
        .carry(stage1_carry[3])
    );
    
    // Assign reduced inputs for stage 2
    assign stage1_reduced[0] = stage1_sum[0];
    assign stage1_reduced[1] = {stage1_carry[0], 1'b0};
    assign stage1_reduced[2] = stage1_sum[1];
    assign stage1_reduced[3] = {stage1_carry[1], 1'b0};
    assign stage1_reduced[4] = stage1_sum[2];
    assign stage1_reduced[5] = {stage1_carry[2], 1'b0};
    assign stage1_reduced[6] = stage1_sum[3];
    assign stage1_reduced[7] = {stage1_carry[3], 1'b0};
    assign stage1_reduced[8] = {5'b0, pixel_data[12]};
    assign stage1_reduced[9] = {5'b0, pixel_data[13]};
    assign stage1_reduced[10] = {5'b0, pixel_data[14]};
    assign stage1_reduced[11] = {5'b0, pixel_data[15]};
    assign stage1_reduced[12] = previous_sum;
    
    // Stage 2: Reduce 13 to 9 inputs
    csa_13bit csa2_1 (
        .a(stage1_reduced[0]),
        .b(stage1_reduced[1]),
        .c(stage1_reduced[2]),
        .sum(stage2_outputs[0]),
        .carry(stage2_outputs[1])
    );
    
    csa_13bit csa2_2 (
        .a(stage1_reduced[3]),
        .b(stage1_reduced[4]),
        .c(stage1_reduced[5]),
        .sum(stage2_outputs[2]),
        .carry(stage2_outputs[3])
    );
    
    csa_13bit csa2_3 (
        .a(stage1_reduced[6]),
        .b(stage1_reduced[7]),
        .c(stage1_reduced[8]),
        .sum(stage2_outputs[4]),
        .carry(stage2_outputs[5])
    );
    
    assign stage2_outputs[6] = stage1_reduced[9];
    assign stage2_outputs[7] = stage1_reduced[10];
    assign stage2_outputs[8] = stage1_reduced[11];
    
    // Stage 3: Reduce 9 to 6 inputs
    csa_13bit csa3_1 (
        .a(stage2_outputs[0]),
        .b({stage2_outputs[1], 1'b0}),
        .c(stage2_outputs[2]),
        .sum(stage3_outputs[0]),
        .carry(stage3_outputs[1])
    );
    
    csa_13bit csa3_2 (
        .a({stage2_outputs[3], 1'b0}),
        .b(stage2_outputs[4]),
        .c({stage2_outputs[5], 1'b0}),
        .sum(stage3_outputs[2]),
        .carry(stage3_outputs[3])
    );
    
    assign stage3_outputs[4] = stage2_outputs[6];
    assign stage3_outputs[5] = stage2_outputs[7];
    
    // Stage 4: Reduce 6 to 4 inputs
    csa_13bit csa4_1 (
        .a(stage3_outputs[0]),
        .b({stage3_outputs[1], 1'b0}),
        .c(stage3_outputs[2]),
        .sum(stage4_outputs[0]),
        .carry(stage4_outputs[1])
    );
    
    assign stage4_outputs[2] = {stage3_outputs[3], 1'b0};
    assign stage4_outputs[3] = stage3_outputs[4];
    
    // Stage 5: Reduce 4 to 3 inputs
    csa_13bit csa5_1 (
        .a(stage4_outputs[0]),
        .b({stage4_outputs[1], 1'b0}),
        .c(stage4_outputs[2]),
        .sum(stage5_outputs[0]),
        .carry(stage5_outputs[1])
    );
    
    assign stage5_outputs[2] = stage4_outputs[3];
    
    // Stage 6: Final reduction to 2 inputs
    csa_13bit csa6_1 (
        .a(stage5_outputs[0]),
        .b({stage5_outputs[1], 1'b0}),
        .c(stage5_outputs[2]),
        .sum(final_sum),
        .carry(final_carry)
    );
    
    // Final addition using Carry Look-Ahead Adder
    cla_14bit final_adder (
        .a({1'b0, final_sum}),
        .b({final_carry, 1'b0}),
        .sum(total_result)
    );
    
    // Output processing with 8-bit right shift (divide by 256)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_value <= 8'b0;
            threshold_ready <= 1'b0;
        end else if (data_valid) begin
            threshold_value <= total_result[13:6];  // 8-bit right shift
            threshold_ready <= 1'b1;
        end else begin
            threshold_ready <= 1'b0;
        end
    end

endmodule
