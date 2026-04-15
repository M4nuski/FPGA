## Generated SDC file "CycloneIV_Test1.out.sdc"

## Copyright (C) 2025  Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Altera and sold by Altera or its authorized distributors.  Please
## refer to the Altera Software License Subscription Agreements 
## on the Quartus Prime software download page.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 25.1std.0 Build 1129 10/21/2025 Patches 0.02std SC Lite Edition"

## DATE    "Fri Mar 27 10:15:20 2026"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk50} -period 1.000 -waveform { 0.000 0.500 } [get_ports {clk50}]
create_clock -name {clk27} -period 1.000 -waveform { 0.000 0.500 } [get_ports {clk27}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk50}] -rise_to [get_clocks {clk50}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk50}] -fall_to [get_clocks {clk50}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk50}] -rise_to [get_clocks {clk50}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk50}] -fall_to [get_clocks {clk50}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk27}] -rise_to [get_clocks {clk27}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk27}] -fall_to [get_clocks {clk27}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk27}] -rise_to [get_clocks {clk27}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk27}] -fall_to [get_clocks {clk27}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

