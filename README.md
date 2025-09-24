# Basic_RayTracing
This project is a hardware-based ray tracing engine implemented in Verilog for the Xilinx PYNQ-Z2 FPGA board. It demonstrates the fundamentals of real-time graphics rendering using fixed-point arithmetic and modular design.

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
      (5 in parallel) to solve quadratic intersection equations.
      Mathematical computation are parallelized (square root and inverse), delays are being solved using FIFOs

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
    "Thread Generator launches pixel coordinates."
    
  - step: "2️⃣"
    "Ray Core builds corresponding ray directions."
    
  - step: "3️⃣"
    "Ray Intersector checks intersections with objects (spheres)." (Hard Coded for now)
    
  - step: "4️⃣"
    action: "Shading Module computes final color using lighting + normals." (Lightning coordinates are hard coded for now)
    
  - step: "5️⃣"
    action: "Pixel FIFO synchronizes pixel coordinates with shading output."
    
  - step: "6️⃣"
    action: "Frame Packer + AXI/HDMI send the final rendered frame to display." ( Still not working :( )


  🧩 The logic block design :
  <img width="2255" height="941" alt="image" src="https://github.com/user-attachments/assets/ace5bfcb-5e9f-49dd-ae81-489c5471420c" />


  🧩 The HDMI output block design (still non-functionnal) :
  <img width="2342" height="1102" alt="image" src="https://github.com/user-attachments/assets/561fc23a-fcb3-4ed0-958a-8ddf105a5b89" />



📊 The results are as follow :

For Pixel y = 109
In the ILA :
<img width="2466" height="153" alt="image" src="https://github.com/user-attachments/assets/88360559-20c9-4b8e-ab5d-516b8d31fe7a" />

In testbench simulation :
<img width="2125" height="399" alt="image" src="https://github.com/user-attachments/assets/d4f54d16-ca5b-4490-b221-7d218c513fa7" />



For Pixel y = 0bd
In the ILA :
<img width="2466" height="148" alt="image" src="https://github.com/user-attachments/assets/f6fc3c1c-e3b3-431b-8297-6786d232deb4" />

In testbench simulation :
<img width="2142" height="400" alt="image" src="https://github.com/user-attachments/assets/873d12ab-415e-4c77-8426-85e40e54e53b" />



Pixel y = 0d9
In the ILA :
<img width="2270" height="149" alt="image" src="https://github.com/user-attachments/assets/7a632553-02d9-4d93-ab3c-f6903f957bde" />
<img width="2468" height="148" alt="image" src="https://github.com/user-attachments/assets/ec0aac28-0552-42ba-9408-1202d5bdd2a3" />

In testbench simulation :
<img width="2124" height="405" alt="image" src="https://github.com/user-attachments/assets/5b444bc1-0087-4e80-89d7-defcb307f1dd" />


A quick look at the overall behavioural simulation:
<img width="2148" height="1240" alt="image" src="https://github.com/user-attachments/assets/ed6a3dbf-a546-448d-818a-7c1d648bc124" />

🎯 4 pixels are generated in 44 cycles (maths taking up 32 cycles) at a 25 MHz speed. Considering the ressources available with the Pynq Z2,
the goal is to achieve a 15 fps with 640x480p image quality using 2 parallelized Ray cores, considering the limited number of DSPs.
By optimazing the overall logic, an estimated 30 fps can be achieved by the end of the project using the PYNQ Z2.

  ## 🚧 Limitations
- Objects and light source are hard-coded.
- HDMI pipeline not yet functional (still under development).
- One-ray-at-a-time tracing model (not full parallelization yet).
- Fixed-point math introduces rounding errors.

## 🔮 Future Work
- Pipeline math and intersection modules to optimize speed and ressource usage.
- Add multiple objects (spheres, planes).
- Implement full parallelization.
- Enable reflections and recursive rays.
- Complete HDMI output and test on real display.


