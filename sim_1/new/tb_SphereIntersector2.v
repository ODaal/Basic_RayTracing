`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2025 10:02:03 PM
// Design Name: 
// Module Name: tb_SphereIntersector2
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

module tb_SphereIntersector2();

    // Clock and reset
    reg clk = 0;
    reg rst = 1;

    // Parameters for test case
    reg [63:0] discriminant = 64'd444405;  // Discriminant = 16.0 in Q18.14 (sqrt = 4.0)
    reg [31:0] A = 32'd18432;                // A = 1.0 in Q18.14
    reg [63:0] B = -64'd98475;              // B = -8.0 in Q18.14

    // Ray origin (Q18.14)
    reg signed [31:0] ox = 32'd16384, oy = 32'd8192, oz = 0;

    // Direction (Q2.14 = 2^14 = 16384 = 1.0)
    reg signed [31:0] dx = 14'd11585, dy = 14'd5793, dz = -14'd11585;

    // Sphere center (Q18.14 = 4.0)
    reg signed [31:0] cx = 32'd49152, cy = 32'd16384, cz = -32'd32768;
    
    reg signed [31:0] radius = 32'd40960;

    // SQRT module outputs
    wire sqrt_done;
    wire [31:0] sqrt_result;

    // Intersector outputs
    reg sqrt_valid;
    wire intersect_valid;
    wire [31:0] normal_x, normal_y, normal_z;

    // Instantiate sqrt module
    square_q18 #(.N(64)) sqrt_unit (
        .Clock(clk),
        .reset(rst),
        .num_in(discriminant),
        .done(sqrt_done),
        .sq_root(sqrt_result)
    );

    // Instantiate intersector
    RaySphereIntersector2 intersect (
        .clk(clk),
        .rst(rst),
        .hit(sqrt_valid),
        .ox(ox), .oy(oy), .oz(oz),
        .dx(dx), .dy(dy), .dz(dz),
        .cx(cx), .cy(cy), .cz(cz),
        .sqr_discriminant(sqrt_result),
        .radius(radius),
        .A(A),
        .B(B),
        .valid2(intersect_valid),
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting Sphere Intersector Test...");

        // Initial reset
        #10 rst = 0;
        #10 rst = 1;
        #10 rst = 0;

        // Wait for square root to be ready
        wait(sqrt_done);  
        #5;
        sqrt_valid = 1;
        #10;
        sqrt_valid = 0;

        // Wait for intersection result
        wait(intersect_valid);

        $display("Normal Vector: (%f, %f, %f)",
            $itor(normal_x) / 16384.0,
            $itor(normal_y) / 16384.0,
            $itor(normal_z) / 16384.0
        );

        #20 $finish;
    end
endmodule
