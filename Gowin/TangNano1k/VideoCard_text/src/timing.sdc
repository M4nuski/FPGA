//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-04 14:04:58
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}]
create_clock -name lcd_clock_d -period 74.074 -waveform {0 37.037} [get_nets {LCD_CLK_d}]
