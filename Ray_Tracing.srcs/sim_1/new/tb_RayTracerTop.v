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


module tb_RayTracerTop;

    reg clk = 0;
    reg rst = 1;
    reg TREADY = 1;

    parameter OX = 32'sd0,
              OY = 32'sd0,
              OZ = 32'sd0,
              CX = 32'sd0,
              CY = 32'sd0,
              CZ = -32'sd1024,
              RADIUS = 32'sd2048,
              INVERSE_RADIUS = 32'sd131072;
    parameter signed [31:0] light_x = 18'sd8192;  // 0.5
    parameter signed [31:0] light_y = 18'sd8192;  // 0.5
    parameter signed [31:0] light_z = 18'sd8192;
    parameter [7:0] color_r = 8'h49;
    parameter [7:0] color_g = 8'h92;
    parameter [7:0] color_b = 8'hF0;
              
    // Thread generator output
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire pixel_valid; wire ray_valid; wire [4:0] sqrt_done; wire hit_valid; wire forcePull; wire [4:0] sqrt_start; wire hit_valid2; wire color_valid; wire valid_to_inverse;
    wire fifo_empty;
    wire fifo_full;
    wire [4:0] sqrt_busy;
    wire [9:0] delayed_x;
    wire [9:0] delayed_y;
    wire fifo_empty_a;
    wire fifo_empty_b;
    wire fifo_empty_rays;
    wire a_inverse_done;
   
  
    // Ray core output
    wire signed [31:0] ray_dir_x, ray_dir_y, ray_dir_z, ray_dir_x_delayed, ray_dir_y_delayed, ray_dir_z_delayed;

    // Ray-sphere intersector output
    wire [31:0] double_a, double_a_input, inverse_double_a, inverse_double_a_delayed;
    wire [31:0] sqrt_roots [0:4];  //change
    wire [63:0] disc, sqrt_input;
    wire signed [63:0] b, b_temp, b_delayed;
    wire signed [31:0] normal_x, normal_y, normal_z;

    // Shading output
    wire [23:0] color;
   
    // HDMI Stuff
    wire [23:0] scan_out;
    wire TKEEP;
    wire TVALID;
    wire TUSER;
    wire TLAST;
    wire FRAME;
    wire BUSY;

    // Instantiate thread generator
    ThreadGenerator thread_gen (
        .clk(clk),
        .rst(rst),
        .ray_core_free((&sqrt_start) & ~color_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .valid(pixel_valid)
    );

    // Instantiate ray core (ray generation)
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


    
    /*Ray_Intersector_Wrapper ray_Intersect (
        .clk(clk),
        .rst(rst),
        .ray_VALID(ray_valid),
        .OX(OX), .OY(OY), .OZ(OZ),  // Camera at origin
        .DX(ray_dir_x),
        .DY(ray_dir_y),
        .DZ(ray_dir_z),
        .CX(CX),
        .CY(CY),
        .CZ(CZ),
        .RADIUS(RADIUS),  // Radius = 2.0 in Q18.14
        .inverse_RADIUS(INVERSE_RADIUS),
        .normal_X(normal_x),
        .normal_Y(normal_y),
        .normal_Z(normal_z),
        .sqrt_START(sqrt_start),
        .out_VALID(hit_valid2)
    );*/

////// ======= UNROLLED Ray_Intersector_Wrapper Logic START ======= //////

    // Intermediate wire


    // Intersection #1
    RaySphereIntersector1 ray_sphere_wrapper (
        .clk(clk),
        .rst(rst),
        .valid(ray_valid),
        .ox(OX), .oy(OY), .oz(OZ),
        .dx(ray_dir_x),
        .dy(ray_dir_y),
        .dz(ray_dir_z),
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
        .push_en(ray_valid),
        .pull_en(disc_valid & (~fifo_empty_rays)),
        .in_x(ray_dir_x),
        .in_y(ray_dir_y),
        .in_z(ray_dir_z),
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
    
    SingleDelayFIFO #(6,63) fifo_b(
        .rst(rst),
        .clk(clk),
        .push_en(hit_valid),
        .pull_en((a_inverse_done & ~fifo_empty_b) | (forcePull)),
        .in(b),
        .out(b_temp),
        .isEmpty(fifo_empty_b)
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

    // Pipelined hit propagation
    reg [4:0] hit_pipe_wrapper;
    always @(posedge clk or negedge rst) begin
        if (!rst)
            hit_pipe_wrapper <= 5'b0;
        else
            hit_pipe_wrapper <= { hit_pipe_wrapper[3:0], hit_valid };
    end

    // Square root units (5-way parallel)
    genvar j;
    generate
        for (j = 0; j < 5; j = j + 1) begin : sqrt_gen_wrapper
            square_q18 #(.N(64)) sqrt_unit_wrapper (
                .Clock(clk),
                .reset(rst),
                .start(hit_pipe_wrapper[j]),
                .num_in(sqrt_input),
                .done(sqrt_done[j]),
                .sq_root(sqrt_roots[j]),
                .sqrt_busy(sqrt_busy[j])
            );
            assign sqrt_start[j] = ~sqrt_busy[j];
        end
    endgenerate
    
    
    reg [31:0] disc_sqrt;
    reg disc_valid;
    // Discriminant sqrt selection logic
    always @(posedge clk or posedge rst) begin
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
                default:  disc_sqrt <= disc_sqrt;
            endcase
        end
    end
    

    // Reciprocal module (for 1/(2a))
    reciprocal_q18_14 double_a_reciprocal_wrapper (
        .clk(clk),
        .rst(rst),
        .start(valid_to_inverse),
        .x_in(double_a),
        .done(a_inverse_done),
        .x_inv(inverse_double_a)
    );

    // Delay FIFO for A_inv and B
    PixelDelayFIFO #(10,31,63) fifo_A_B_wrapper (
        .clk(clk),
        .rst(rst),
        .push_en(a_inverse_done),
        .pull_en(disc_valid),
        .pixel_x_in(inverse_double_a),
        .pixel_y_in(b_temp),
        .pixel_x_out(inverse_double_a_delayed),
        .pixel_y_out(b_delayed)
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
        .inverse_radius(INVERSE_RADIUS),
        .A2_inv(inverse_double_a_delayed),
        .B(b_delayed),
        .valid2(hit_valid2),  // Connect to downstream logic
        .normal_x(normal_x),
        .normal_y(normal_y),
        .normal_z(normal_z)
    );

////// ======= UNROLLED Ray_Intersector_Wrapper Logic END ======= //////


    
    
   // Instantiate shading 
    Shading shading (
        .clk(clk),
        .rst(rst),
        .LIGHT_X(light_x),
        .LIGHT_Y(light_y),
        .LIGHT_Z(light_z),
        .COLOR_R(color_r),
        .COLOR_G(color_g),
        .COLOR_B(color_b),
        .hit(hit_valid2),
        .normal_x(normal_x),  //Q2.14 → Q18.14
        .normal_y(normal_y),
        .normal_z(normal_z),
        .color(color),
        .color_valid(color_valid)
    );

    // Frame buffer

    
    PixelDelayFIFO #(.DEPTH(5)) fifo_inst (
    .clk(clk),
    .rst(rst),
    .push_en(pixel_valid),        // Push pixel in only when valid
    .pull_en(hit_valid2),
    .pixel_x_in(pixel_x),
    .pixel_y_in(pixel_y),
    .pixel_x_out(delayed_x),
    .pixel_y_out(delayed_y)
);


   /*FrameBuffer framebuffer (
        .clk(clk),
        .rst(rst),
        .we(color_valid),
        .pixel_x(delayed_x),
        .pixel_y(delayed_y),
        .color_in(color),
        .read_x(read_x),
        .read_y(read_y),
        .color_out(scan_out)
    );*/
    
    FramePacker framepacker (
        .clk(clk),
        .resetn(rst),
        .rgb_valid(color_valid),
        .pixel_x(delayed_x),
        .pixel_y(delayed_y),
        .rgb(color),
        .tdata(scan_out),
        .tvalid(TVALID),
        .tready(TREADY),
        .tuser(TUSER),         // SOF
        .tlast(TLAST),         // EOL
        .tkeep(TKEEP),         // always 3'b111 for 24bpp
        .frame_done(FRAME),    // 1-cycle pulse when last pixel loaded
        .busy(BUSY)           // high while streaming the frame
        
    );
    
always #10 clk = ~clk;

initial begin
        rst = 0;
        #11 rst = 1;
        //#90001 $finish;
    end
endmodule
