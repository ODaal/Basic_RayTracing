`timescale 1ns / 1ps

module tb_Ray_Core;
    reg clk = 0;
    reg rst = 1;
    reg [9:0] pixel_x = 0;
    reg [9:0] pixel_y = 0;
    reg valid = 0;

    wire signed [31:0] ray_dir_x, ray_dir_y, ray_dir_z;
    //wire signed [31:0] norm_x;
    //wire signed [31:0] norm_y;
    wire done;

    Ray_Core uut (
        .clk(clk),
        .rst(rst),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .valid(valid),
        .out_valid(done),
        //.norm_x(norm_x), FOR TESTING
        //.norm_y(norm_y), FOR TESTING 
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z)
    );

    always #5 clk = ~clk;

    initial begin
        #20 rst = 0;
        #10 pixel_x = 640; pixel_y = 120; valid = 1;
        #20 valid = 0;
        #50 $finish;
    end
endmodule
