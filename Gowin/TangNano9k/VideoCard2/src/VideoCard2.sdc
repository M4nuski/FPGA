//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-19 20:57:50
create_clock -name XTAL -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}]
//create_clock -name clkdiv2 -period 26.936 -waveform {0 13.468} [get_nets {clk2}]
create_clock -name clk126 -period 7.937 -waveform {0 3.969} [get_nets {clkout126}]
create_clock -name clk25 -period 40 -waveform {0 20} [get_nets {clock25}]
create_clock -name clk74 -period 13.468 -waveform {0 6.734} [get_nets {clock74}]
//create_clock -name video_hcount0 -period 26.936 -waveform {0 13.468} [get_nets {video_HD/H_Count[0]}]

//create_clock -name pixel0 -period 26.936 -waveform {0 13.468} [get_nets {pixel[0]}]
create_clock -name clockSource -period 26.936 -waveform {0 13.468} [get_nets {clockSource}]
