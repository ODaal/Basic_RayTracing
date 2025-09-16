`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2025 08:32:36 PM
// Design Name: 
// Module Name: tb_FrameBuffer
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


`timescale 1ns / 1ps

module tb_FrameBuffer;

    reg clk = 0;
    reg rst = 1;
    reg we = 0;
    reg [9:0] pixel_x = 0;
    reg [9:0] pixel_y = 0;
    reg [23:0] color_in = 0;
    reg [9:0] read_x = 0;
    reg [9:0] read_y = 0;
    wire [23:0] color_out;

    // Instantiate the FrameBuffer
    FrameBuffer uut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .color_in(color_in),
        .read_x(read_x),
        .read_y(read_y),
        .color_out(color_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Reset pulse
        #10 rst = 0;

        // Write a red pixel at (100, 50)
        #10 pixel_x = 10'd100;
            pixel_y = 10'd50;
            color_in = 24'hFF0000;  // Red
            we = 1;

        #10 we = 0;

        // Set read address to same location
        #10 read_x = 10'd100;
            read_y = 10'd50;

        // Wait a few cycles and observe color_out
        #20;

        // Show result in simulator
        $display("Read Color = %h at (%d, %d)", color_out, read_x, read_y);

        // Finish simulation
        #20 $finish;
    end

endmodule
