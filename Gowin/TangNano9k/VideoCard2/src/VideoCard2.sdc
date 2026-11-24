//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-24 10:51:40
create_clock -name XTAL -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}]
create_clock -name clk126 -period 7.937 -waveform {0 3.969} [get_nets {clkout126}]
create_clock -name clk25 -period 40 -waveform {0 20} [get_nets {clock25}]
create_clock -name hsync -period 22222.222 -waveform {0 11111.111} [get_nets {HSYNC}]
create_clock -name videoClock -period 13.468 -waveform {0 6.734} [get_nets {videoClock}]
create_clock -name pixelClock -period 26.936 -waveform {0 13.468} [get_nets {pixelClock}]
create_clock -name romClock -period 26.936 -waveform {0 13.468} [get_nets {romClock}]
