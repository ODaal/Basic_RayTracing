`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2025 06:55:01 PM
// Design Name: 
// Module Name: tb_SphereIntersector
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

module tb_SphereIntersector;

    // Inputs
    reg clk;
    reg rst;
    reg valid;
    
    reg signed [31:0] ox, oy, oz;
    reg signed [31:0] dx, dy, dz;
    reg signed [31:0] cx, cy, cz;
    reg signed [31:0] radius;

    // Outputs
    wire hit;
    wire signed [31:0] disc;
    wire signed [31:0] A;
    wire signed [63:0] B;

    // Instantiate the Unit Under Test (UUT)
    RaySphereIntersector1 uut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .ox(ox),
        .oy(oy),
        .oz(oz),
        .dx(dx),
        .dy(dy),
        .dz(dz),
        .cx(cx),
        .cy(cy),
        .cz(cz),
        .radius(radius),
        .hit(hit),
        .discriminant(disc),
        .A(A),
        .B(B)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Display intermediate values
    always @(posedge clk) begin
        if (valid) begin
            $display("Time: %0t", $time);
            $display("Inputs:");
            $display("  Origin: (%0.4f, %0.4f, %0.4f)", $itor(ox)/16384.0, $itor(oy)/16384.0, $itor(oz)/16384.0);
            $display("  Direction: (%0.4f, %0.4f, %0.4f)", $itor(dx)/16384.0, $itor(dy)/16384.0, $itor(dz)/16384.0);
            $display("  Center: (%0.4f, %0.4f, %0.4f)", $itor(cx)/16384.0, $itor(cy)/16384.0, $itor(cz)/16384.0);
            $display("  Radius: %0.4f", $itor(radius)/16384.0);
            
            // Display internal values (1 cycle delayed)
            #1; // Wait for registers to update
            $display("Intermediate Values:");
            $display("  oc: (%0.4f, %0.4f, %0.4f)", $itor(uut.ocx)/16384.0, $itor(uut.ocy)/16384.0, $itor(uut.ocz)/16384.0);
            $display("  A: %0.4f", $itor(uut.A)/16384.0);
            $display("  B: %0.4f", $itor(uut.B)/16384.0);
            $display("  C: %0.4f", $itor(uut.C)/16384.0);
            $display("  Discriminant: %0.4f", $itor(uut.disc)/16384.0);
        end
    end

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        valid = 0;
        ox = 0; oy = 0; oz = 0;
        dx = 0; dy = 0; dz = 0;
        cx = 0; cy = 0; cz = 0;
        radius = 0;

        // Reset
        #10;
        rst = 0;
        #10;

        // Test Case 1: Ray through center of sphere
        $display("\nTest Case 1: Ray through center");
        valid = 1;
        ox = 0; oy = 0; oz = 0;               // Origin at (0,0,0)
        dx = 16384; dy = 0; dz = 0;            // Direction (1,0,0)
        cx = 32'd65536; cy = 0; cz = 0;  // Center at (4,0,0) Q18.14
        radius = 32'd16384;              // Radius = 1.0 Q18.14
        #10;
        valid = 0;
        #20;

        // Test Case 2: Ray missing sphere
        $display("\nTest Case 2: Ray missing sphere");
        valid = 1;
        ox = 0; oy = 0; oz = 0;               // Origin at (0,0,0)
        dx = 16384; dy = 16384; dz = 0;       // Direction (1,1,0)
        cx = 32'd65536; cy = 0; cz = 0; // Center at (4,0,0)
        radius = 32'd8192;               // Radius = 0.5 Q18.14
        #10;
        valid = 0;
        #20;

        // Test Case 3: Tangent ray
        $display("\nTest Case 3: Tangent ray");
        valid = 1;
        ox = 0; oy = 16384; oz = 0;           // Origin at (0,1,0)
        dx = 16384; dy = 0; dz = 0;           // Direction (1,0,0)
        cx = 32'd65536; cy = 0; cz = 0; // Center at (4,0,0)
        radius = 32'd16384;             // Radius = 1.0 Q18.14
        #10;
        valid = 0;
        #20;
        
        $display("\nTest Case 4: Random hit case - exact conversion");
        valid = 1;
        // Ray origin (1.0, 0.5, 0.0) in Q18.14
        ox = 32'd16384;    // 1.0 * 16384
        oy = 32'd8192;     // 0.5 * 16384
        oz = 0;            // 0.0
        // Normalized direction [0.70710678, 0.35355339, -0.70710678] in Q2.14
        dx = 14'd11585;    // 0.70710678 * 16384
        dy = 14'd5793;     // 0.35355339 * 16384
        dz = -14'd11585;   // -0.70710678 * 16384
        // Sphere center (3.0, 1.0, -2.0) in Q18.14
        cx = 32'd49152;    // 3.0 * 16384
        cy = 32'd16384;    // 1.0 * 16384
        cz = -32'd32768;   // -2.0 * 16384
        // Radius 2.5 in Q18.14
        radius = 32'd40960; // 2.5 * 16384
        #10;
        valid = 0;
        #20;

        // Finish simulation
        $display("\nSimulation Complete");
        $finish;
    end

endmodule