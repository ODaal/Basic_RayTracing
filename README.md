# Basic_RayTracing
This project is a hardware-based ray tracing engine implemented in Verilog for the PYNQ-Z2 FPGA board. It demonstrates the fundamentals of real-time graphics rendering using fixed-point arithmetic and modular design.

Features 🚀:
  - "🟦 Thread Generator"
    description: >
      Generates pixel coordinates (x, y) for each ray to be traced.
      Ensures launching one ray at a time into the Ray Core for now.

  - "🟩 Ray Core"
    description: >
      Calculates ray direction vectors based on pixel coordinates.
      Passes normalized rays into the Ray Intersector for object hit testing.

  - "🟥 Ray Intersector Wrapper"
    description: >
      Performs ray-sphere intersection tests using Q18.14 fixed-point math.
      Computes object surface normals for shading and uses a square root module
      (with sqrt_START) to solve quadratic intersection equations.

  - "🌞 Shading Module"
    description: >
      Implements Lambertian lighting model.
      Inputs: light position (XYZ), surface normal, and base color.
      Outputs: 24-bit RGB pixel values (color[23:0]).

  - "📦 Pixel Delay FIFO"
    description: >
      Buffers pixel coordinates to synchronize with shading results.
      Ensures pixel positions align with their computed color values.

  - "🖼️ Frame Packer"
    description: >
      Collects shaded pixel data into a framebuffer.
      Prepares frames for AXI Stream interface to HDMI out.

  - "⏱️ Clocking Wizard"
    description: >
      Provides multiple clock domains to coordinate math units,
      FIFO synchronization, and video timing.

  - "🔗 AXI SmartConnect"
    description: >
      Bridges framebuffer output to the HDMI pipeline (rgb2dvi) for monitor display.

SYSTEM FLOW 💻:

  - step: "1️⃣"
    action: "Thread Generator launches pixel coordinates."
    
  - step: "2️⃣"
    action: "Ray Core builds corresponding ray directions."
    
  - step: "3️⃣"
    action: "Ray Intersector checks intersections with objects (spheres)."
    
  - step: "4️⃣"
    action: "Shading Module computes final color using lighting + normals."
    
  - step: "5️⃣"
    action: "Pixel FIFO synchronizes pixel coordinates with shading output."
    
  - step: "6️⃣"
    action: "Frame Packer + AXI/HDMI send the final rendered frame to display."
