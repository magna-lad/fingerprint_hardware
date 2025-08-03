`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 00:57:29
// Design Name: 
// Module Name: cla_14bit
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


module cla_14bit (
    input [13:0] a,
    input [13:0] b,
    output [13:0] sum
);

    wire [13:0] p, g;
    wire [14:0] c;
    
    assign p = a ^ b;
    assign g = a & b;
    assign c[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < 14; i = i + 1) begin : cla_stage
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate

endmodule

