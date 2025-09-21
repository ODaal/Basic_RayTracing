`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2025 09:55:35 PM
// Design Name: 
// Module Name: sqrt_q18
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


module sqrt_q18 (
    input wire [31:0] x,  // Q18.14 input (32-bit)
    output reg [31:0] sqr  // Q18.14 output
);
    reg [31:0] temp;
    reg [31:0] root;
    integer i;
    
    always @(*) begin
        temp = x;
        root = 0;
        
        // 16 iterations for Q14 fractional precision
        for (i = 0; i < 16; i = i+1) begin
            root = {root[30:0], 1'b1};  // Shift left + set LSB
            if (root * root > temp) begin
                root[0] = 1'b0;  // Clear bit if squared exceeds input
            end
        end
    sqr <= root;
    end
endmodule