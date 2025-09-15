`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2025 04:55:30 PM
// Design Name: 
// Module Name: tb_VideoTimingGenerator
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


module tb_VideoTimingGenerator();

    // Inputs
    reg clk;
    reg reset;

    // Outputs
    wire [9:0] hcount;
    wire [9:0] vcount;
    wire hsync;
    wire vsync;
    wire video_active;

    // Instantiate DUT
    VideoTimingGenerator dut (
        .clk(clk),
        .reset(reset),
        .hcount(hcount),
        .vcount(vcount),
        .hsync(hsync),
        .vsync(vsync),
        .video_active(video_active)
    );

    // Clock generation (74.25 MHz for 720p)
    initial begin
        clk = 0;
        forever #6.734 clk = ~clk;  // 1/(74.25MHz * 2)
    end

    // Reset and test sequence
    initial begin
        // Initialize and reset
        reset = 1;
        #100 reset = 0;

        // Monitor outputs
        $monitor("Time=%0t: hcount=%0d, vcount=%0d, hsync=%b, vsync=%b, active=%b", 
                 $time, hcount, vcount, hsync, vsync, video_active);

        // Run for 2 full frames
        #(2 * 1650 * 750 * 6.734 * 2);  // 2 frames in ns
        $finish;
    end

    // Frame validation
    always @(posedge clk) begin
        if (!reset) begin
            // Check sync pulse timing
            if (hcount == H_ACTIVE + H_FRONT) 
                assert(hsync === 1'b1) else $error("HSYNC failed to assert");
            if (hcount == H_ACTIVE + H_FRONT + H_SYNC) 
                assert(hsync === 1'b0) else $error("HSYNC failed to deassert");

            if (vcount == V_ACTIVE + V_FRONT && hcount == 0) 
                assert(vsync === 1'b1) else $error("VSYNC failed to assert");
            if (vcount == V_ACTIVE + V_FRONT + V_SYNC && hcount == 0) 
                assert(vsync === 1'b0) else $error("VSYNC failed to deassert");

            // Check active video region
            if (hcount < H_ACTIVE && vcount < V_ACTIVE) 
                assert(video_active === 1'b1) else $error("Video active failed");
            else 
                assert(video_active === 1'b0) else $error("Video inactive failed");
        end
    end
endmodule