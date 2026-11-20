//Copyright (C)2014-2026 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2026-11-11 15:02:27
create_clock -name clk_osc -period 37.037 -waveform {0 18.518} [get_ports {clk}]
set_max_delay -from [get_regs {out_r_7_s0}] -to [get_regs {svo_tmds_0/q_out_7_s0}] 13.5
