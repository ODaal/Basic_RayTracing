`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2025 06:26:01 PM
// Design Name: 
// Module Name: Ray_Intersector_Wrapper
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


module Ray_Intersector_Wrapper(
    input clk,
    input rst,
    input ray_VALID,
    // Ray Origin (Q18.14) - Camera position
    input signed [31:0] OX, OY, OZ,
    // Ray Direction (Q2.14) 
    input signed [31:0] DX, DY, DZ,
    // Sphere Center (Q18.14)
    input signed [31:0] CX, CY, CZ,
    // Sphere Radius (Q18.14)
    input signed [31:0] RADIUS,
    input signed [31:0] inverse_RADIUS,
    output signed [31:0] normal_X,
    output signed [31:0] normal_Y,
    output signed [31:0] normal_Z,
    output [4:0] sqrt_START,
    output out_VALID
    );
        /*parameter O_X = 32'sd0,
              O_Y = 32'sd0,
              O_Z = 32'sd0,
              C_X = 32'sd0,
              C_Y = 32'sd0,
              C_Z = -32'sh400,
              RAD = 32'sd2048,
              INVERSERADIUS = 32'sd131072;*/
    
    wire signed [31:0] ray_dir_x_delayed, ray_dir_y_delayed, ray_dir_z_delayed;
    wire hit_valid, valid_to_inverse, forcePull;
    wire signed [63:0] disc, b, b_temp, b_delayed;
    wire [63:0] disc;
    wire unsigned [31:0] double_a, double_a_input,inverse_double_a, inverse_double_a_delayed;
    wire unsigned [63:0] sqrt_input;
    wire fifo_empty, fifo_empty_a, fifo_empty_b, fifo_empty_rays, a_b_delay_empty;
    wire a_inverse_done;
    
    wire [4:0] sqrt_done, sqrt_busy;
    wire [31:0] sqrt_roots [0:4];
    reg [4:0] hit_pipe;
    
    reg [31:0] disc_sqrt;
    reg disc_valid;
    
    /*assign OX = O_X;
    assign OY = O_Y;
    assign OZ = O_Z;
    assign CX = C_X;
    assign CY = C_Y;
    assign CZ = C_Z;
    assign RADIUS = RAD;
    assign inverse_RADIUS = INVERSERADIUS;*/
    
        // Instantiate ray-sphere intersection
    RaySphereIntersector1 ray_sphere_intersect1 (
        .clk(clk),
        .rst(rst),
        .valid(ray_VALID),
        .ox(OX), .oy(OY), .oz(OZ),
        .dx(DX),
        .dy(DY),
        .dz(DZ),
        .cx(CX),
        .cy(CY),
        .cz(CZ),
        .radius(RADIUS),
        .hit(hit_valid),
        .discriminant(disc),
        .B(b),
        .A(double_a_input)
    );
       
     TripleDelayFIFO #(6,31) fifo_rays(
        .rst(rst),
        .clk(clk),
        .push_en(ray_VALID),
        .pull_en(disc_valid & (~fifo_empty_rays)),
        .in_x(DX),
        .in_y(DY),
        .in_z(DZ),
        .out_x(ray_dir_x_delayed),
        .out_y(ray_dir_y_delayed),
        .out_z(ray_dir_z_delayed),
        .isEmpty(fifo_empty_rays)
    );
        
     SingleDelayFIFO #(6,63) fifo_sqrt(
        .rst(rst),
        .clk(clk),
        .push_en(hit_valid),
        .pull_en(|(~sqrt_busy) & (~fifo_empty)),
        .in(disc),
        .out(sqrt_input),
        .isEmpty(fifo_empty)
    );
    
    SingleDelayFIFO #(6,31) fifo_inverse(
        .rst(rst),
        .clk(clk),
        .push_en(hit_valid),
        .pull_en((a_inverse_done & ~fifo_empty_a) | (forcePull)),
        .in(double_a_input),
        .out(double_a),
        .valid(valid_to_inverse),
        .isNoLongerEmpty(forcePull),
        .isEmpty(fifo_empty_a)
    );
    
        SingleDelayFIFO #(6,63) fifo_b(
        .rst(rst),
        .clk(clk),
        .push_en(hit_valid),
        .pull_en((a_inverse_done & ~fifo_empty_b) | (forcePull)),
        .in(b),
        .out(b_temp),
        .isEmpty(fifo_empty_b)
    );
    
 
  
//////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge rst) begin
    if (!rst) 
        hit_pipe <= 5'b0;
    else 
        hit_pipe <= { hit_pipe[3:0], hit_valid };
    end
    
    //////////////////////////////////////////////////////////////////////
    genvar i;
    generate 
        for (i = 0; i < 5; i = i + 1) begin : sqrt_gen
            square_q18 #(.N(64)) sqrt_unit (
            .Clock(clk),
            .reset(rst),
            .start(hit_pipe[i]),  // Start when idle and FIFO has data
            .num_in(sqrt_input),
            .done(sqrt_done[i]),
            .sq_root(sqrt_roots[i]),
            .sqrt_busy(sqrt_busy[i])
        );
        assign sqrt_START[i] = ~sqrt_busy[i];
    end endgenerate
    
    ////////////////////////////////////////////////////
   
    
    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        disc_sqrt <= 32'b0;
        disc_valid <= 1'b0;
    end else begin
        disc_valid <= |sqrt_done;
        case (sqrt_done)
            5'b00001: disc_sqrt <= sqrt_roots[0];
            5'b00010: disc_sqrt <= sqrt_roots[1];
            5'b00100: disc_sqrt <= sqrt_roots[2];
            5'b01000: disc_sqrt <= sqrt_roots[3];
            5'b10000: disc_sqrt <= sqrt_roots[4];
            default: disc_sqrt <= disc_sqrt;
        endcase
        
    end
    end
    
    
    reciprocal_q18_14 double_a_reciprocal_wrapper (
        .clk(clk),
        .rst(rst),
        .start(valid_to_inverse),
        .x_in(double_a),
        .done(a_inverse_done),
        .x_inv(inverse_double_a)
    );
    
    PixelDelayFIFO #(10,31,63) fifo_A_B_wrapper (
        .clk(clk),
        .rst(rst),
        .push_en(a_inverse_done),
        .pull_en(disc_valid),
        .pixel_x_in(inverse_double_a),
        .pixel_y_in(b_temp),
        .pixel_x_out(inverse_double_a_delayed),
        .pixel_y_out(b_delayed),
        .isEmpty(a_b_delay_empty)
    );

    // Ray-sphere intersection 2 (final intersection + normal)
    RaySphereIntersector2 ray_sphere2_wrapper (
        .clk(clk),
        .rst(rst),
        .hit(disc_valid),
        .sqr_discriminant(disc_sqrt),
        .ox(OX), .oy(OY), .oz(OZ),
        .dx(ray_dir_x_delayed),
        .dy(ray_dir_y_delayed),
        .dz(ray_dir_z_delayed),
        .cx(CX),
        .cy(CY),
        .cz(CZ),
        .inverse_radius(inverse_RADIUS),
        .A2_inv(inverse_double_a_delayed),
        .B(b_delayed),
        .valid2(out_VALID),  // Connect to downstream logic
        .normal_x(normal_X),
        .normal_y(normal_Y),
        .normal_z(normal_Z)
    );
    
endmodule
