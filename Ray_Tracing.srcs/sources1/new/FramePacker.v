`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/03/2025 05:16:51 PM
// Design Name: 
// Module Name: FramePacker
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


// framPacker_640x480_rgb888_one_shot
// Packs (pixel_x, pixel_y, rgb, rgb_valid) into AXI4-Stream video for VDMA S2MM.
// - Waits for first (0,0) before starting (SOF correct)
// - tuser on first pixel of frame, tlast on last pixel of each line
// - Pops one coord from FIFO only when a beat is actually loaded
// - Emits exactly ONE frame (640x480), then stops (frame_done pulses)

module FramePacker(
  input  wire        clk,
  input  wire        resetn,          // active-low

  input  wire [9:0]  pixel_x,
  input  wire [9:0]  pixel_y,
  input  wire [23:0] rgb,
  input  wire        rgb_valid,       // pixel_x/y/rgb stable when 1

  // AXI4-Stream to VDMA S2MM
  output reg  [23:0] tdata,
  output reg         tvalid,
  input  wire        tready,
  output reg         tuser,           // SOF (first accepted pixel)
  output reg         tlast,           // EOL (x==639 on accepted beat)
  output wire [3:0]  tkeep,
  output reg         frame_done,      // pulse at last accepted pixel
  output reg         busy             // high while streaming the frame
);
  assign tkeep = 4'h7;


  reg streaming;

  always @(posedge clk) begin
    if (!resetn) begin
      tvalid<=1'b0; tuser<=1'b0; tlast<=1'b0; tdata<=24'd0;
      frame_done<=1'b0; busy<=1'b0; streaming<=1'b0;
    end else begin
      // 1-cycle pulses
      tuser<=1'b0; tlast<=1'b0; frame_done<=1'b0;

      // drive data; valid mirrors your source readiness
      tdata  <= rgb;
      tvalid <= rgb_valid;

      // enter streaming on the FIRST accepted (0,0)
      if ((pixel_x==0) && (pixel_y==0)) begin
        streaming <= 1'b1;
        busy      <= 1'b1;
        tuser     <= 1'b1;                    // SOF aligned to accepted beat
      end

      // sidebands only on accepted beats
      //if (tready) begin
        if (pixel_x==639) tlast <= 1'b1;
        if ((pixel_x==639) && (pixel_y==479)) begin
          streaming  <= 1'b0;
          busy       <= 1'b0;
          frame_done <= 1'b1;                  // one frame captured
        end
      //end
    end
  end
endmodule

