set_property PACKAGE_PIN M20 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

set_property PACKAGE_PIN M14 [get_ports {Color}]
set_property IOSTANDARD LVCMOS33 [get_ports {Color}]

set_property PACKAGE_PIN N16 [get_ports ResetLED]
set_property IOSTANDARD LVCMOS33 [get_ports ResetLED]

set_property PACKAGE_PIN P14 [get_ports valid1]
set_property IOSTANDARD LVCMOS33 [get_ports valid1]

set_property PACKAGE_PIN R14 [get_ports clock]
set_property IOSTANDARD LVCMOS33 [get_ports clock]



# HDMI Output Clock
set_property PACKAGE_PIN L16 [get_ports {TMDS_Clk_p_0}]
set_property PACKAGE_PIN L17 [get_ports {TMDS_Clk_n_0}]

# HDMI Output Data Channel 0
set_property PACKAGE_PIN K17 [get_ports {TMDS_Data_p_0[0]}]
set_property PACKAGE_PIN K18 [get_ports {TMDS_Data_n_0[0]}]

# HDMI Output Data Channel 1
set_property PACKAGE_PIN K19 [get_ports {TMDS_Data_p_0[1]}]
set_property PACKAGE_PIN J19 [get_ports {TMDS_Data_n_0[1]}]

# HDMI Output Data Channel 2
set_property PACKAGE_PIN J18 [get_ports {TMDS_Data_p_0[2]}]
set_property PACKAGE_PIN H18 [get_ports {TMDS_Data_n_0[2]}]

# IOSTANDARD for TMDS differential pairs
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_Clk_p_0 TMDS_Clk_n_0}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_Data_p_0[*] TMDS_Data_n_0[*]}]