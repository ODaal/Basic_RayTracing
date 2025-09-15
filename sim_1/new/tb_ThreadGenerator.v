`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2025 05:07:14 PM
// Design Name: 
// Module Name: tb_ThreadGenerator
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


module tb_ThreadGenerator;

reg clk = 0;
reg rst = 1;
reg free = 0;
wire [9:0] pixelx;
wire [9:0] pixely;
wire valid2;

ThreadGenerator tg (
        .clk(clk),
        .rst(rst),
        .ray_core_free(free),
        .pixel_x(pixelx),
        .pixel_y(pixely),
        .valid(valid2)
);

always #1 clk = ~clk; // 2ns period

initial begin
        #10 rst = 0;
        #10 rst = 1;
        #10 rst = 0;
        #10 free = 1;
        #10 free = 0;
        #10 free = 1;
        #50 rst = 1;   
    end
endmodule
