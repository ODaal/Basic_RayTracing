-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
-- Date        : Sun Aug 31 20:39:28 2025
-- Host        : ODrog running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub -rename_top design_1_rgb2dvi_1_0 -prefix
--               design_1_rgb2dvi_1_0_ Testing_rgb2dvi_1_0_stub.vhdl
-- Design      : Testing_rgb2dvi_1_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity design_1_rgb2dvi_1_0 is
  Port ( 
    TMDS_Clk_p : out STD_LOGIC;
    TMDS_Clk_n : out STD_LOGIC;
    TMDS_Data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    TMDS_Data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    aRst_n : in STD_LOGIC;
    vid_pData : in STD_LOGIC_VECTOR ( 23 downto 0 );
    vid_pVDE : in STD_LOGIC;
    vid_pHSync : in STD_LOGIC;
    vid_pVSync : in STD_LOGIC;
    PixelClk : in STD_LOGIC;
    SerialClk : in STD_LOGIC
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of design_1_rgb2dvi_1_0 : entity is "Testing_rgb2dvi_1_0,rgb2dvi,{}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of design_1_rgb2dvi_1_0 : entity is "yes";
end design_1_rgb2dvi_1_0;

architecture stub of design_1_rgb2dvi_1_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "TMDS_Clk_p,TMDS_Clk_n,TMDS_Data_p[2:0],TMDS_Data_n[2:0],aRst_n,vid_pData[23:0],vid_pVDE,vid_pHSync,vid_pVSync,PixelClk,SerialClk";
  attribute x_interface_info : string;
  attribute x_interface_info of TMDS_Clk_p : signal is "digilentinc.com:interface:tmds:1.0 TMDS CLK_P, xilinx.com:signal:clock:1.0 TMDS_Clk_p CLK";
  attribute x_interface_mode : string;
  attribute x_interface_mode of TMDS_Clk_p : signal is "master TMDS_Clk_p";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of TMDS_Clk_p : signal is "XIL_INTERFACENAME TMDS, BOARD.ASSOCIATED_PARAM TMDS_BOARD_INTERFACE, XIL_INTERFACENAME TMDS_Clk_p, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute x_interface_info of TMDS_Clk_n : signal is "digilentinc.com:interface:tmds:1.0 TMDS CLK_N, xilinx.com:signal:clock:1.0 TMDS_Clk_n CLK";
  attribute x_interface_mode of TMDS_Clk_n : signal is "master TMDS_Clk_n";
  attribute x_interface_parameter of TMDS_Clk_n : signal is "XIL_INTERFACENAME TMDS_Clk_n, ASSOCIATED_RESET aRst_n, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute x_interface_info of TMDS_Data_p : signal is "digilentinc.com:interface:tmds:1.0 TMDS DATA_P";
  attribute x_interface_info of TMDS_Data_n : signal is "digilentinc.com:interface:tmds:1.0 TMDS DATA_N";
  attribute x_interface_info of aRst_n : signal is "xilinx.com:signal:reset:1.0 AsyncRst_n RST";
  attribute x_interface_mode of aRst_n : signal is "slave AsyncRst_n";
  attribute x_interface_parameter of aRst_n : signal is "XIL_INTERFACENAME AsyncRst_n, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute x_interface_info of vid_pData : signal is "xilinx.com:interface:vid_io:1.0 RGB DATA";
  attribute x_interface_mode of vid_pData : signal is "slave RGB";
  attribute x_interface_info of vid_pVDE : signal is "xilinx.com:interface:vid_io:1.0 RGB ACTIVE_VIDEO";
  attribute x_interface_info of vid_pHSync : signal is "xilinx.com:interface:vid_io:1.0 RGB HSYNC";
  attribute x_interface_info of vid_pVSync : signal is "xilinx.com:interface:vid_io:1.0 RGB VSYNC";
  attribute x_interface_info of PixelClk : signal is "xilinx.com:signal:clock:1.0 PixelClk CLK";
  attribute x_interface_mode of PixelClk : signal is "slave PixelClk";
  attribute x_interface_parameter of PixelClk : signal is "XIL_INTERFACENAME PixelClk, FREQ_HZ 25178571, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_0_clk_out1, INSERT_VIP 0";
  attribute x_interface_info of SerialClk : signal is "xilinx.com:signal:clock:1.0 SerialClk CLK";
  attribute x_interface_mode of SerialClk : signal is "slave SerialClk";
  attribute x_interface_parameter of SerialClk : signal is "XIL_INTERFACENAME SerialClk, ASSOCIATED_RESET aRst:aRst_n:pRst:pRst_n, FREQ_HZ 125892857, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_0_clk_out1, INSERT_VIP 0";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "rgb2dvi,Vivado 2024.2";
begin
end;
