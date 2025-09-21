`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2025 12:24:01 AM
// Design Name: 
// Module Name: FrameBuffer
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


module FrameBuffer (
    input clk,
    input rst,

    // Write port
    input we,                        // Write enable
    input [9:0] pixel_x,             // Write X coordinate
    input [9:0] pixel_y,             // Write Y coordinate
    input [23:0] color_in,           // Color to write

    // Read port
    input [9:0] read_x,              // Read X coordinate
    input [9:0] read_y,              // Read Y coordinate
    output reg [23:0] color_out      // Color to display
);
    parameter WIDTH = 640;
    parameter HEIGHT = 480;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;

    // Framebuffer: linear array
    reg [23:0] buffer [0:TOTAL_PIXELS-1];

    wire [18:0] write_addr = pixel_y * WIDTH + pixel_x;
    wire [18:0] read_addr  = read_y * WIDTH + read_x;

    always @(posedge clk) begin
        if (we) begin
            buffer[write_addr] <= color_in;
        end
        color_out <= buffer[read_addr];
    end
endmodule

