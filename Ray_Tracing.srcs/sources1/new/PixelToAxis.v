`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2025 10:52:19 PM
// Design Name: 
// Module Name: PixelToAxis
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


module PixelToAxis #(
  parameter WIDTH=640, HEIGHT=480
)(
  input  wire        clk, reset,
  input  wire [23:0] pixel,
  input  wire        pixel_valid,           // from producer
  output wire        pixel_ready,           // backpressure to producer
  input  wire [9:0]  pixel_x,
  input  wire [9:0]  pixel_y,

  output reg  [23:0] m_tdata,
  output reg         m_tvalid,
  input  wire        m_tready,
  output reg         m_tuser,               // SOF
  output reg         m_tlast                // EOL
);

  // accept new pixel when downstream is ready OR we're idle
  assign pixel_ready = m_tready | ~m_tvalid;

  // capture new pixel if producer is sending and we can accept
  wire take_new = pixel_valid & pixel_ready; // supposed to be pixel_ready

  always @(posedge clk) begin
    if (!reset) begin
      m_tvalid <= 1'b0;
      m_tdata  <= 24'd0;
      m_tuser  <= 1'b0;
      m_tlast  <= 1'b0;
    end else begin
      // if current word was accepted this cycle, we can drop valid next unless we load a new one
      if (m_tvalid && m_tready) m_tvalid <= 1'b0;

      if (take_new) begin
        m_tdata  <= pixel;
        m_tuser  <= (pixel_x==10'd0 && pixel_y==10'd0);  // SOF only on first pixel
        m_tlast  <= (pixel_x==WIDTH-1);                  // EOL on last pixel of line
        m_tvalid <= 1'b1;                                // present until accepted
      end
    end
  end
endmodule

