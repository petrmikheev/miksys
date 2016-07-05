#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.1.0 Build 162 10/23/2013 SJ Web Edition
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.



# Clock constraints

create_clock -name "CLK100MHZ" -period 10.000ns [get_ports {CLK100MHZ}]


# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set_false_path -from [get_clocks {pll1|altpll_component|auto_generated|pll1|clk[2]}] -to [get_clocks {pll1|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from [get_clocks {pll1|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {pll1|altpll_component|auto_generated|pll1|clk[2]}]

# tsu/th constraints

# tco constraints

# tpd constraints

