`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2025 08:30:09 PM
// Design Name: 
// Module Name: Ray_Core
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

module Ray_Core (
    input clk,
    input rst,
    input wire [9:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire valid,
   
    //output reg signed [31:0] norm_x, FOR TEST BENCH
    //output reg signed [31:0] norm_y, FOR TEST BENCH
    
    output reg signed [31:0] ray_dir_x,
    output reg signed [31:0] ray_dir_y,
    output reg signed [31:0] ray_dir_z,
    output reg out_valid
);
    parameter INVERSE_WIDTH  =  18'd24;
    parameter INVERSE_HEIGHT = 18'd34;
    // Camera position
    /*parameter signed [31:0] CAM_POS_X = 0;
    parameter signed [31:0] CAM_POS_Y = 0;
    parameter signed [31:0] CAM_POS_Z = 0;
    // Image Plane Z at -1.0 (Q18.14)
    parameter signed [31:0] PLANE_Z = -32'sd16384;*/

    reg signed [31:0] norm_x;
    reg signed [31:0] norm_y;


    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ray_dir_x <= 0;
            ray_dir_y <= 0;
            ray_dir_z <= 0;
            norm_x <= 0;
            norm_y <= 0;
            out_valid <= 0;
        end else if (valid) begin
            ray_dir_x <= ((pixel_x <<< 1) * INVERSE_WIDTH) - 16'sd16384;
            ray_dir_y <= ((pixel_y <<< 1) * INVERSE_HEIGHT) - 16'sd16384;
            ray_dir_z <= -32'sd16384; //PLANE_Z;      
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end
endmodule


module RaySphereIntersector1 (
    input clk,
    input rst,
    input valid,
    // Ray Origin (Q18.14) - Camera position
    input signed [31:0] ox, oy, oz,
    // Ray Direction (Q2.14) 
    input signed [31:0] dx, dy, dz,
    // Sphere Center (Q18.14)
    input signed [31:0] cx, cy, cz,
    // Sphere Radius (Q18.14)
    input signed [31:0] radius,
    // Outputs
    output reg hit,
    output reg signed [63:0] discriminant,
    output reg [31:0] A,
    output reg signed [63:0] B
);

    // Internal registers (Q18.14 unless noted)
    reg signed [31:0] ocx, ocy, ocz;  // Ray origin to center (Q18.14)
    reg signed [63:0] a;
    reg signed [51:0] b;
    reg signed [63:0] c;        // Quadratic coefficients
    reg signed [103:0] disc;


    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            hit <= 0;
            discriminant <= 0;
            A <= 0;
            B <= 0;
            
        end else if (valid) begin
            // 1. Compute L = O - C 
            ocx = ox - cx;  
            ocy = oy - cy;
            ocz = oz - cz;
    
            // 2. Quadratic coefficients (all Q18.14)
            a = ((dx * dx) + (dy * dy) + (dz * dz)) >> 14;  // A = D·D (Q2.14 * Q2.14 = Q4.28 -> trunc to Q18.14)
            b = (dx*ocx + dy*ocy + dz*ocz) >>> 13; 
            c = ((ocx*ocx + ocy*ocy + ocz*ocz) >>> 14) - ((radius * radius) >>> 14);  // C = L·L - r²         
            // 3. Discriminant (Q18.14)
            disc = (b*b - (4*a*c )) >>> 14;

            // 4. Hit test
            if (disc >= 0) begin
                   A <= a << 1;
                   B <= b;
                   discriminant<= disc[63:0];
                   hit <= 1 ;
            end else begin
                hit <= 1;
                A <= 0;
                B <= 0;
                discriminant<= 0;
            end
        end else begin
         hit <= 0;
         A <= 0;
         B <= 0;
         discriminant<= 0;
        end
    end
endmodule


module RaySphereIntersector2 (
    input clk,
    input rst,
    input hit,
    // Ray Origin (Q18.14) - Camera position
    input signed [31:0] ox, oy, oz,
    // Ray Direction (Q2.14) 
    input signed [31:0] dx, dy, dz,
    // Sphere Center (Q18.14)
    input signed [31:0] cx, cy, cz,
    // Sphere Radius (Q18.14)
    input signed [31:0] sqr_discriminant,
    input signed [31:0] inverse_radius,
    input signed [31:0] A2_inv,
    input signed [63:0] B,
    // Outputs
    output reg valid2,
    output reg signed [31:0] normal_x,  // Q2.14
    output reg signed [31:0] normal_y,
    output reg signed [31:0] normal_z
);

    // Internal registers (Q18.14 unless noted)
    reg signed [63:0] t;              // Intersection distance (Q18.14)
    reg signed [31:0] hit_x, hit_y, hit_z;  // Hit point (Q18.14)  

    always @(posedge clk or negedge rst) begin 
        if (!rst) begin
            valid2 <= 0;
            normal_x <= 0;
            normal_y <= 0;
            normal_z <= 0;
        end else if (hit) begin    
            //t = (((-B - sqr_discriminant)*A2_inv) >>> 14);
            // 5. Hit point (Q18.14)
            //hit_x = ((ox) + (((((-B - sqr_discriminant)*A2_inv) >>> 14) * dx) >>> 14));  // Q18.14 + (Q18.14 * Q2.14)
            //hit_y = ((oy) + (((((-B - sqr_discriminant)*A2_inv) >>> 14) * dy) >>> 14));
            //hit_z = ((oz) + (((((-B - sqr_discriminant)*A2_inv) >>> 14) * dz) >>> 14));
            // 6. Normals
            normal_x <= ((((ox) + (((((-B - sqr_discriminant)*A2_inv) >> 14) * dx) >> 14)) - cx) * inverse_radius) >> 14;
            normal_y <= ((((oy) + (((((-B - sqr_discriminant)*A2_inv) >> 14) * dy) >> 14)) - cy) * inverse_radius) >> 14;
            normal_z <= ((((oz) + (((((-B - sqr_discriminant)*A2_inv) >> 14) * dz) >> 14)) - cz) * inverse_radius) >> 14;
            valid2 <= 1;
         end else begin
            valid2 <= 0;
            normal_x <= 0;
            normal_y <= 0;
            normal_z <= 0;
         end
    end
endmodule


module Shading (
    input clk,
    input rst,
    input hit,
    input signed [31:0] LIGHT_X, LIGHT_Y, LIGHT_Z,
    input [7:0] COLOR_R, COLOR_G, COLOR_B,
    input signed [31:0] normal_x, normal_y, normal_z,  
    output reg [23:0] color,                          // RGB
    //output reg signed [63:0] diffuse, USED FOR TESTBENNCH
    output reg color_valid
);

    // Light direction (Q18.14, normalized)
    /*parameter signed [31:0] LIGHT_X = 18'sd8192;  // 0.5
    parameter signed [31:0] LIGHT_Y = 18'sd8192;  // 0.5
    parameter signed [31:0] LIGHT_Z = 18'sd8192;  // 0.5*/

    /* Object color 
    parameter [7:0] COLOR_R = 8'h49;
    parameter [7:0] COLOR_G = 8'h92;
    parameter [7:0] COLOR_B = 8'hF0;*/

    //reg signed [63:0] diffuse;
    reg [7:0] red_val;
    reg [7:0] green_val;
    reg [7:0] blue_val;
    reg signed [63:0] diffuse;
    
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin
            color <= 24'h000000;
            color_valid <= 0;
        end else begin    
            if (hit) begin
                // Compute dot product (N·L) in Q18.14
                diffuse = (((normal_x * LIGHT_X) + (normal_y * LIGHT_Y) + (normal_z * LIGHT_Z)) >> 14);
                //Clamp to [0, 1] and apply to material color
                if (diffuse > 0) begin
                    // Diffuse is in Q36.28 (from Q18.14*Q18.14), shift right by 28 bits to get Q8.0   
                    //red_val   = ((COLOR_R * diffuse) >> 14);
                    green_val = ((COLOR_G * diffuse) >>> 14);
                    blue_val  = (COLOR_B * diffuse) >>> 14;
                    color <= {((COLOR_R * diffuse) >>> 14), green_val, blue_val};
                    color_valid <= 1;
                end else begin
                    color <= {COLOR_R, COLOR_G, COLOR_B};  // Display object color
                    color_valid <= 1;
                end
            end else begin
                color <= 24'h000000;  // Black background (miss)
                color_valid <= 0;
            end
        end
    end
endmodule


/// I HAVEN'T WROTE THIS
module square_q18
    #(parameter N = 64)
    (   input Clock,  //Clock
        input reset,  //Asynchronous active high reset.
        input start,    
        input [N-1:0] num_in,   //this is the number for which we want to find square root.
        output reg sqrt_busy,
        output reg done,     //This signal goes high when output is ready
        output reg [N/2-1:0] sq_root  //square root of 'num_in'
    );

    reg [N-1:0] a;   //original input.
    reg [N/2+1:0] left,right;     //input to adder/sub.r-remainder.
    reg signed [N/2+1:0] r;
    reg [N/2-1:0] q;    //result.
    integer i;   //index of the loop. 

    always @(posedge Clock or negedge reset) 
    begin
        if (!reset) begin   //reset the variables.
            sqrt_busy <= 0;
            done <= 0;
            sq_root <= 0;
            i = 0;
            a = 0;
            left = 0;
            right = 0;
            r = 0;
            q = 0;           
        end else if (start || i != 0) begin
            sqrt_busy <= 1;
            //Before we start the first clock cycle get the 'input' to the variable 'a'.
            if(i == 0) begin  
                a = num_in;
                done <= 0;    //reset 'done' signal.
                i = i+1;   //increment the loop index.
            end
            else if(i < N/2) begin //keep incrementing the loop index.
                i = i+1;  
            end
            //These statements below are derived from the block diagram.
            right = {q,r[N/2+1],1'b1};
            left = {r[N/2-1:0], a[N-1:N-2]};
            a = {a[N-3:0], 2'b0};  //shifting left by 2 bit.
            if ( r[N/2+1] == 1)    //add or subtract as per this bit.
                r = left + right;
            else
                r = left - right;
            q = {q[N/2-2:0], ~r[N/2+1]};
            if(i == N/2) begin    //This means the max value of loop index has reached.
                sqrt_busy <= 0;
                done <= 1;    //make 'done' high because output is ready.
                i = 0; //reset loop index for beginning the next cycle.
                sq_root <= q << 7;   //assign 'q' to the output port.
                //reset other signals for using in the next cycle.
                left = 0;
                right = 0;
                r = 0;
                q = 0;
            end
        end else begin
            sqrt_busy <= 0;
            done <= 0;
            //sq_root <= 0;
            i = 0;
            a = 0;
            left = 0;
            right = 0;
            r = 0;
            q = 0; 
        end
    end

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    parameter TOTAL_PIXELS = 307200;

    // Framebuffer: linear array
    reg [23:0] buffer [0:TOTAL_PIXELS-1];

    wire [18:0] write_addr = pixel_y * WIDTH + pixel_x;
    wire [18:0] read_addr  = read_y * WIDTH + read_x;

    always @(posedge clk) begin
        if (we) begin
            buffer[write_addr] <= color_in;
            color_out <= color_in;
        end
        //color_out <= buffer[read_addr];
    end
endmodule



module PixelDelayFIFO #(
    parameter DEPTH = 32,
    parameter SIZE_X = 9,
    parameter SIZE_Y = 9
)(
    input clk,
    input rst,
    input push_en,
    input pull_en,
    input [SIZE_X:0] pixel_x_in,
    input [SIZE_Y:0] pixel_y_in,
    output reg [SIZE_X:0] pixel_x_out,
    output reg isEmpty,
    output reg [SIZE_Y:0] pixel_y_out
);

    reg [SIZE_X:0] fifo_x [0:DEPTH-1];
    reg [SIZE_Y:0] fifo_y [0:DEPTH-1];
    integer wr_ptr;
    integer rd_ptr;
    integer i;
    
    always @(posedge clk) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                fifo_x[i] <= 0;
                fifo_y[i] <= 0;
            end
            isEmpty <= 1;
            pixel_x_out <= 0;
            pixel_y_out <= 0;
        end else if (push_en & pull_en) begin
            fifo_x[wr_ptr] <= pixel_x_in;
            fifo_y[wr_ptr] <= pixel_y_in;
            pixel_x_out <= fifo_x[rd_ptr];
            pixel_y_out <= fifo_y[rd_ptr];
            fifo_x[rd_ptr] <= 0;
            fifo_y[rd_ptr] <= 0;
            wr_ptr <= wr_ptr + 1;
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end else if (push_en) begin
            fifo_x[wr_ptr] <= pixel_x_in;
            fifo_y[wr_ptr] <= pixel_y_in;
            wr_ptr <= wr_ptr + 1;
            isEmpty <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end else if (pull_en) begin
            pixel_x_out <= fifo_x[rd_ptr];
            pixel_y_out <= fifo_y[rd_ptr];
            fifo_x[rd_ptr] <= 0;
            fifo_y[rd_ptr] <= 0;
            rd_ptr <= rd_ptr + 1;
            isEmpty <= 0;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if (rd_ptr == wr_ptr)
                isEmpty <= 1;   
        end
    end
endmodule 


module SingleDelayFIFO #(
    parameter DEPTH = 32,
    parameter SIZE = 31
)(
    input clk,
    input rst,
    input push_en,
    input pull_en,
    input [SIZE:0] in,
    output reg [SIZE:0] out,
    output reg valid,
    output reg isNoLongerEmpty,
    output reg isEmpty
);

    reg [SIZE:0] fifo [0:DEPTH-1];
    integer wr_ptr;
    integer rd_ptr;
    integer i;
        
    always @(posedge clk) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                fifo[i] <= 0;
            end
            isEmpty <= 1;
            isNoLongerEmpty <= 0;
            valid <= 1;
            out <= 0;
        end else if (push_en & pull_en) begin
            fifo[wr_ptr] <= in;
            out <= fifo[rd_ptr];
            fifo[rd_ptr] <= 0;
            wr_ptr <= wr_ptr + 1;
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
            valid <= 1;
            isNoLongerEmpty <= 0; 
        end else if (push_en) begin
            fifo[wr_ptr] <= in;
            wr_ptr <= wr_ptr + 1;
            if (isEmpty)
                isNoLongerEmpty <= 1;
            isEmpty <= 0;
            valid <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end else if (pull_en) begin
            out <= fifo[rd_ptr];
            fifo[rd_ptr] <= 0;
            rd_ptr <= rd_ptr + 1;
            valid <= 1;
            isNoLongerEmpty <= 0; 
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if ((rd_ptr + 1 == wr_ptr) || (rd_ptr == DEPTH-1 && wr_ptr == 0))
                isEmpty <= 1;   
        end else begin
            valid <= 0;
            isNoLongerEmpty <= 0;
        end
    end
endmodule


module TripleDelayFIFO #(
    parameter DEPTH = 6,
    parameter SIZE = 31
)(
    input clk,
    input rst,
    input push_en,
    input pull_en,
    input [SIZE:0] in_x,
    input [SIZE:0] in_y,
    input [SIZE:0] in_z,
    output reg [SIZE:0] out_x,
    output reg [SIZE:0] out_y,
    output reg [SIZE:0] out_z,
    output reg valid,
    output reg isEmpty
);

    reg [SIZE:0] fifo_x [0:DEPTH-1];
    reg [SIZE:0] fifo_y [0:DEPTH-1];
    reg [SIZE:0] fifo_z [0:DEPTH-1];
    integer wr_ptr;
    integer rd_ptr;
    integer i;

    always @(posedge clk) begin
        if (!rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                fifo_x[i] <= 0;
                fifo_y[i] <= 0;
                fifo_z[i] <= 0;
            end
            isEmpty <= 1;
            out_x <= 0;
            out_y <= 0;
            out_z <= 0;
        end else if (push_en & pull_en) begin
            fifo_x[wr_ptr] <= in_x;
            fifo_y[wr_ptr] <= in_y;
            fifo_z[wr_ptr] <= in_z;
            out_x <= fifo_x[rd_ptr];
            out_y <= fifo_y[rd_ptr];
            out_z <= fifo_z[rd_ptr];
            fifo_x[rd_ptr] <= 0;
            fifo_y[rd_ptr] <= 0;
            fifo_z[rd_ptr] <= 0;
            wr_ptr <= wr_ptr + 1;
            rd_ptr <= rd_ptr + 1;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end else if (push_en) begin
            fifo_x[wr_ptr] <= in_x;
            fifo_y[wr_ptr] <= in_y;
            fifo_z[wr_ptr] <= in_z;
            wr_ptr <= wr_ptr + 1;
            isEmpty <= 0;
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
        end else if (pull_en) begin
            out_x <= fifo_x[rd_ptr];
            out_y <= fifo_y[rd_ptr];
            out_z <= fifo_z[rd_ptr];
            fifo_x[rd_ptr] <= 0;
            fifo_y[rd_ptr] <= 0;
            fifo_z[rd_ptr] <= 0;
            rd_ptr <= rd_ptr + 1;
            isEmpty <= 0;
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            if (rd_ptr == wr_ptr)
                isEmpty <= 1;   
        end
    end
endmodule




module ThreadGenerator(
    input rst,
    input clk,
    input multiplier,
    input wire ray_core_free,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y,
    output reg valid
    );

parameter WIDTH = 640;
parameter HEIGHT = 480;
    
always @(posedge clk or negedge rst) begin
    if (!rst) begin 
        pixel_x <= -1;  // set it as 0 or 1 later
        pixel_y <= 0;
        valid <= 0;
    end else begin
        if(ray_core_free) begin
            valid <= 1;
            pixel_x <= pixel_x + 1; // add two
            if(pixel_x == WIDTH - 1) begin // change the condition
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




module reciprocal_q18_14 (
    input clk,
    input rst,
    input start,
    input signed [31:0] x_in,       // Q18.14
    output reg done,
    output reg signed [31:0] x_inv  // Q18.14
);

    integer i;
    reg signed [31:0] x;
    reg signed [31:0] y;  // Q18.14

    //reg unsigned [63:0] mult1, mult2, correction;

    always @(posedge clk or negedge rst) begin
        //$display(x_in);
        if (!rst) begin
            i = 0;
            done <= 0;
            x <= 0;
            y <= 0;
            x_inv <= 0;
        end else if (i==0 && start) begin  
            i = 1;
            done <= 0;
            x <= x_in;
            // Initial guess: 1 / x ≈ shift for large/small values
            // You may improve this with a LUT
            y <= 32'sd3000;
        end else if (i < 4 && i > 0) begin
            //mult1 = (x * y);
            //orrection = (32'sd32768 - (mult1 >>> 14));
            //mult2 = (y * (32'sd32768 - ((x * y) >>> 14)));
            y <= (y * (32'sd32768 - ((x * y) >>> 14))) >>> 14; // Keep in Q18.14
            done <= 0;
            i = i + 1;
        end else if (i == 4) begin
            x_inv <= y;
            done <= 1;
            i = 0;
        end else begin
            x_inv <= 0;
            done <= 0;
            i = 0;
        end
    end
endmodule




