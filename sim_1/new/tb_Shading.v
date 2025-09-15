`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2025 05:32:53 PM
// Design Name: 
// Module Name: tb_Shading
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


module tb_Shading;

    reg clk = 0;
    reg rst = 0;
    reg hit;
    reg signed [31:0] normal_x, normal_y, normal_z;

    wire [23:0] color;
    wire color_valid;
    //wire signed [63:0] diffuse;

    // Instantiate the Shading module
    Shading uut (
        .clk(clk),
        .rst(rst),
        .hit(hit),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z),
        .color(color),
        .color_valid(color_valid)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns clock period

    initial begin
        $display("Time | Hit | Normal (x y z) | Color");

        // Reset
        rst = 1;
        #10;
        rst = 0;

        // Case 1: Hit with N aligned with light (all = 0.5)
        hit = 1;
        normal_x = 32'sd8192; // 0.5 in Q18.14
        normal_y = 32'sd8192;
        normal_z = 32'sd8192;
        #10;
        $display("%t | hit | %d %d %d | %h", $time, normal_x, normal_y, normal_z, color);

        // Case 2: Hit with N opposite light (should clamp to base color)
        normal_x = -32'sd8192;
        normal_y = -32'sd8192;
        normal_z = -32'sd8192;
        #10;
        $display("%t | hit | %d %d %d | %h", $time, normal_x, normal_y, normal_z, color);

        // Case 3: Hit with N orthogonal (should be mid-bright)
        normal_x = 32'sd8192;
        normal_y = 0;
        normal_z = 0;
        #10;
        $display("%t | hit | %d %d %d | %h", $time, normal_x, normal_y, normal_z, color);

        // Case 4: No hit
        hit = 0;
        #10;
        $display("%t | miss | %d %d %d | %h", $time, normal_x, normal_y, normal_z, color);

        $finish;
    end

endmodule