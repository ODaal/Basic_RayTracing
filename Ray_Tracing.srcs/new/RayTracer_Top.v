`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2025 07:03:20 PM
// Design Name: 
// Module Name: RayTracer_Top
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


module RayTracer_Top;

reg clk = 0;
reg rst = 1;

    parameter OX = 32'sd0,
              OY = 32'sd0,
              OZ = 32'sd0,
              CX = 32'sd0,
              CY = 32'sd0,
              CZ = -32'sd1024,
              RADIUS = 32'sd2048;
              
    // Thread generator output
    reg [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire pixel_valid; reg ray_valid; wire disc_valid; wire hit_valid; wire hit_valid2; wire color_valid;
    wire [9:0] delayed_x;
    wire [9:0] delayed_y;
   
   
    // Ray core output
    wire signed [31:0] ray_dir_x, ray_dir_y, ray_dir_z;

    // Ray-sphere intersector output
    wire signed [31:0] a, disc_sqrt;
    wire signed [63:0] disc, b;
    wire signed [31:0] normal_x, normal_y, normal_z;

    // Shading output
    wire [23:0] color;
    
    // HDMI Stuff
    wire [23:0] scan_out;
    wire [9:0] scan_x;
    wire scan_y;
    wire hsync, vsync; 
    wire video_active;

    // Instantiate thread generator
    ThreadGenerator #(
        .WIDTH(640),
        .HEIGHT(480)
    ) thread_gen (
        .clk(clk),
        .rst(rst),
        .ray_core_free(ray_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .valid(pixel_valid)
    );

    /*/ Instantiate ray core (ray generation)
    Ray_Core ray_core (
        .clk(clk),
        .rst(rst),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .valid(pixel_valid),
        .out_valid(ray_valid),
        .ray_dir_x(ray_dir_x),
        .ray_dir_y(ray_dir_y),
        .ray_dir_z(ray_dir_z)
    );

    // Instantiate ray-sphere intersection
    /* RaySphereIntersector1 ray_sphere (
        .clk(clk),
        .rst(rst),
        .valid(ray_valid),
        .ox(OX), .oy(OY), .oz(OZ),  // Camera at origin
        .dx(ray_dir_x),
        .dy(ray_dir_y),
        .dz(ray_dir_z),
        .cx(CX),
        .cy(CY),
        .cz(CZ),  // Sphere at z = -4
        .radius(RADIUS),  // Radius = 2.0 in Q18.14
        .hit(hit_valid),
        .discriminant(disc),
        .B(b),
        .A(a)
    );
       
    square_q18 #(.N(64)) sqrt_unit (
        .Clock(clk),
        .reset(rst),
        .num_in(disc),
        .done(disc_valid),
        .sq_root(disc_sqrt)
    );

    RaySphereIntersector2 ray_sphere2 (
        .clk(clk),
        .rst(rst),
        .hit(disc_valid),
        .sqr_discriminant(disc_sqrt),
        .ox(OX), .oy(OY), .oz(OZ),  // Camera at origin
        .dx(ray_dir_x),
        .dy(ray_dir_y),
        .dz(ray_dir_z),
        .cx(CX),
        .cy(CY),
        .cz(CZ),  // Sphere at z = -4
        .radius(RADIUS),  // Radius = 2.0 in Q18.14
        .A(a),
        .B(b),
        .valid2(hit_valid2),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z)
    );
    
    
   // Instantiate shading
    Shading shading (
        .clk(clk),
        .rst(rst),
        .hit(hit_valid2),
        .normal_x(normal_x),  //Q2.14 → Q18.14
        .normal_y(normal_y),
        .normal_z(normal_z),
        .color(color),
        .color_valid(color_valid)
    );

    // Frame buffer

    
    PixelDelayFIFO #(.DEPTH(32)) fifo_inst (
    .clk(clk),
    .rst(rst),
    .push_en(pixel_valid),         // Push pixel in only when valid
    .pixel_x_in(pixel_x),
    .pixel_y_in(pixel_y),
    .pixel_x_out(delayed_x),
    .pixel_y_out(delayed_y)
);

   FrameBuffer framebuffer (
        .clk(clk),
        .rst(rst),
        .we(color_valid),
        .pixel_x(delayed_x),
        .pixel_y(delayed_y),
        .color_in(color),
        .read_x(read_x),
        .read_y(read_y),
        .color_out(scan_out)
    );
    
   /* VideoTimingGenerator timing_gen (
        .clk(clk),
        .rst(rst),
        .scan_x(scan_x),
        .scan_y(scan_y),
        .hsync(hsync),
        .vsync(vsync),
        .video_active(video_active)
    ); */
    
always #10 clk = ~clk;

initial begin
        #10 rst = 0;
        #10 rst = 1;
        #10 rst = 0;
        #10 ray_valid = 1;
        #10 ray_valid = 0;
        #10 ray_valid = 1;
        #50 rst = 1;
        #500 $finish;
    end
endmodule




