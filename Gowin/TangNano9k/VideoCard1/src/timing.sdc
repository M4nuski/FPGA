//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-05 14:53:36
create_clock -name XTAL_IN -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}]
create_clock -name XTAL_IN_d -period 37.037 -waveform {0 19.861} [get_nets {XTAL_IN_d}]
//create_clock -name vgaClk -period 39.722 -waveform {0 19.861} [get_nets {vgaClk}]
