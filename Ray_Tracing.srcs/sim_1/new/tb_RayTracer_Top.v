`timescale 1ns / 1ps

/*module tb_RayTracer_Top;
    // Clock and reset
    reg clk = 0;
    reg rst = 1;
  //  reg gen = 1;

    // Instantiate the DUT
    RayTracer_Top dut (
        .clk(clk),
        //.ray_core_Free(gen),
        .rst(rst)
    );

    // Clock generation: 10 ns period
    always #1 clk = ~clk;
    
   
    // Stimulus: event-synchronized rather than time-based
    integer i;
    initial begin
        // Dump waveforms
        
        //$dumpfile("tb_RayTracer_Top.vcd");
        //$dumpvars(0, tb_RayTracer_Top);

        // Release reset
        #20;
        rst = 0;
        
        force dut.hit_valid2 = 1'b1;
        wait (dut.pixel_valid);
        release dut.hit_valid2;
        
        // Capture a sequence of pixels, synchronized through each pipeline stage
        for (i = 0; i < 32; i = i + 1) begin
            wait (dut.pixel_valid);
            // Wait for ThreadGenerator
            wait (dut.pixel_valid);  
            // Wait for Ray_Core
            wait (dut.ray_valid);
            // Wait for Intersector1 discriminant valid
            wait (dut.hit_valid);
            // Wait for discriminant valid
            wait (dut.disc_valid);
            // Wait for Intersector2 hit/normal valid
            wait (dut.hit_valid2);         
            // Wait for Shading output valid
            wait (dut.color_valid);

            /// Display the result for this pixel
            $display("Time=%0t | pixel=(%0d,%0d) | = %h %h",
                     $time,
                     dut.pixel_x,
                     dut.pixel_y,
                     dut.color,
                     dut.color_valid);
        end

        $display("Testbench finished - captured %0d pixels", i);
        $finish;
    end

endmodule */


module tb_RayTracer_Top;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    reg pixel_x;

    // Clock generation (1ns period → 1GHz; adjust if needed)
    always #10 clk = ~clk;

    // Instantiate the DUT
    RayTracer_Top dut (
        .clk(clk),
        .rst(rst)
        // .read_x, .read_y, .scan_out - not used for this testbench
    );


    // Count how many pixels were rendered
    integer pixel_count;    


    initial begin
        assign pixel_x = dut.pixel_x;
        $display("Starting RayTracer simulation...");
        pixel_count = 0;

        // Optional: dump VCD for waveform
        // $dumpfile("tb_RayTracer_Top.vcd");
        // $dumpvars(0, tb_RayTracer_Top);

        // Apply reset
        #10;
        rst = 0;
        force dut.ray_valid = 1'b1;
        //@(posedge clk);
        //release dut.ray_valid;
        
        // Run simulation until N pixels are rendered
        while (pixel_count < 32) begin
            @(posedge clk);
            if (dut.pixel_valid) begin
                pixel_x = dut.pixel_x;
                $display("Time=%0t | Pixel (%0d,%0d) | Ray = %h",
                         $time,
                         dut.pixel_x,
                         dut.pixel_y,
                         dut.ray_valid);
                pixel_count = pixel_count + 1;
            end
        end

        $display("✅ Testbench finished - rendered %0d pixels", pixel_count);
        $finish;
    end

endmodule
