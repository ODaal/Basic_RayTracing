`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2025 07:49:35 PM
// Design Name: 
// Module Name: ThreadGenerator
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


module ThreadGenerator(
    input rst,
    input clk,
    input wire ray_core_free,
    output reg [0:9] pixel_x,
    output reg [0:9] pixel_y,
    output reg valid
    );

parameter WIDTH = 640;
parameter HEIGHT = 480;
    
always @(posedge clk) begin
    if (rst) begin 
        pixel_x <= 0;
        pixel_y <= 0;
        valid <= 0;
    end else begin
        if(ray_core_free) begin
            valid <= 1;
            pixel_x <= pixel_x + 1;
            if(pixel_x == WIDTH - 1) begin
                pixel_x <= 0;
                pixel_y <= pixel_y + 1;
                if (pixel_y == HEIGHT - 1) begin
                    pixel_y <= 0;
                end
            end
        end else begin
            valid <= 0;
        end
    end
end 
endmodule  
