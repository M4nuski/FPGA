//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-09 12:52:33
create_clock -name clk27 -period 37.037 -waveform {0 18.518} [get_ports {clk27}]
create_clock -name clk126 -period 7.937 -waveform {0 3.969} [get_nets {clk126}]
create_clock -name clk25 -period 40 -waveform {0 20} [get_nets {clk25}]
create_clock -name clk27d -period 37.037 -waveform {0 18.518} [get_nets {clk27_d}]
