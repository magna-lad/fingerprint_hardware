`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.07.2025 17:48:42
// Design Name: 
// Module Name: loader
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


module loader(
// should contain the clock
// the image will be loaded via 32 bit i/p bus => should contain 32 bit input bus
// should contain 512 8 bit registers
// shold contain a decoder which will choose 4 registers at a time, thus 128 clock pulses required to complete 512 regiesters
    
    // data coming from outside the system
    
    input wire clock, // clock pulse
    input wire reset_n, // to reset all the registers
    input wire [31:0] data_in, // 32 bit input bus
    input wire data_valid, 
    output reg data_ready,
    output reg loaded_image
);

// things inside the loader module

    reg [7:0] registers [0:511]; // 512 8-bit registers
    reg [7:0] counter; // 7 bit counter to cover all the 128 outputs in the decoder
    integer i;
    
    // first reset all the registers
    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin // when reset goes low everything is reset
                            // new image is reloaded
            counter <= 7'b0;
            data_ready <= 1'b0;
            loaded_image <= 1'b0; 
            
            // will set all the registers to zero
            for(i=0;i<512;i=i+1) begin
                registers[i] <= 8'b0;
            end
        end
        else begin // begin with the implementation
        // this will only bring out one line of the image
            if (data_valid && !loaded_image) begin
                registers[counter*4 +0]<= data_in[7:0]; // relation b/w register and data_input (see figure11.)
                registers[counter*4 +1] <= data_in[15:8];
                registers[counter*4 +2] <= data_in[23:16];
                registers[counter*4 +3] <= data_in[31:24];
                
                
                // conditional blocks
                if (counter == 7'd127) begin
                    // all the images have been loaded
                    loaded_image <= 1'b1;
                    counter <= 7'd0;
                 end else begin
                    counter <= counter + 1'b1;
                 end   
             end
             // call binarisation
             
         end   
     end


// will be connected with binarization
endmodule
