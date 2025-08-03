`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.07.2025 00:54:32
// Design Name: 
// Module Name: thinning_processor
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




module thinning_processor (
    input wire [8:0] window_3x3,
    input wire iteration_type,
    output reg pixel_remove
);

    // Extract window pixels
    wire P1, P2, P3, P4, P5, P6, P7, P8, P9;
    assign {P9, P8, P7, P6, P5, P4, P3, P2, P1} = window_3x3;
    
    // Calculate B(P1) - number of non-zero neighbors
    wire [3:0] B_P1;
    assign B_P1 = P2 + P3 + P4 + P5 + P6 + P7 + P8 + P9;
    
    // Calculate A(P1) - number of 01 patterns
    wire [3:0] A_P1;
    wire [7:0] transitions;
    assign transitions[0] = (~P2 & P3);
    assign transitions[1] = (~P3 & P4);
    assign transitions[2] = (~P4 & P5);
    assign transitions[3] = (~P5 & P6);
    assign transitions[4] = (~P6 & P7);
    assign transitions[5] = (~P7 & P8);
    assign transitions[6] = (~P8 & P9);
    assign transitions[7] = (~P9 & P2);
    
    assign A_P1 = transitions[0] + transitions[1] + transitions[2] + transitions[3] +
                  transitions[4] + transitions[5] + transitions[6] + transitions[7];
    
    // Common conditions
    wire condition_a, condition_b;
    assign condition_a = (B_P1 >= 3) && (B_P1 <= 6);
    assign condition_b = (A_P1 == 1);
    
    // Specific conditions for each sub-iteration
    wire condition_c1, condition_d1;
    wire condition_c2, condition_d2;
    
    assign condition_c1 = ~(P2 & P4 & P6);
    assign condition_d1 = ~(P4 & P6 & P8);
    
    assign condition_c2 = ~(P2 & P4 & P8);
    assign condition_d2 = ~(P2 & P6 & P8);
    
    // Pixel removal logic
    always @(*) begin
        if (P1 == 1'b1) begin
            if (iteration_type == 1'b0) begin
                pixel_remove = condition_a & condition_b & condition_c1 & condition_d1;
            end else begin
                pixel_remove = condition_a & condition_b & condition_c2 & condition_d2;
            end
        end else begin
            pixel_remove = 1'b0;
        end
    end

endmodule
