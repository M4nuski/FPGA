//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Tue Nov  3 19:00:56 2026

module Gowin_SDPB (dout, clka, cea, reseta, clkb, ceb, resetb, oce, ada, din, adb);

output [7:0] dout;
input clka;
input cea;
input reseta;
input clkb;
input ceb;
input resetb;
input oce;
input [8:0] ada;
input [7:0] din;
input [8:0] adb;

wire [23:0] sdpb_inst_0_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

SDPB sdpb_inst_0 (
    .DO({sdpb_inst_0_dout_w[23:0],dout[7:0]}),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,ada[8:0],gw_gnd,gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:0]}),
    .ADB({gw_gnd,gw_gnd,adb[8:0],gw_gnd,gw_gnd,gw_gnd})
);

defparam sdpb_inst_0.READ_MODE = 1'b0;
defparam sdpb_inst_0.BIT_WIDTH_0 = 8;
defparam sdpb_inst_0.BIT_WIDTH_1 = 8;
defparam sdpb_inst_0.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_0.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_0.RESET_MODE = "SYNC";
defparam sdpb_inst_0.INIT_RAM_00 = 256'h344D20202020204B31206E69776F47202C353635424752202C32373278303834;
defparam sdpb_inst_0.INIT_RAM_01 = 256'h746E6F4620202020202020202020202036323032202D20766F4E20796B73756E;
defparam sdpb_inst_0.INIT_RAM_02 = 256'h203731783033202020202020202020202020202020202020387838204147433A;
defparam sdpb_inst_0.INIT_RAM_03 = 256'h6164207469622038202020202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_04 = 256'h74697257203A3020535220202020202020202020206E5257202C5352202C6174;
defparam sdpb_inst_0.INIT_RAM_05 = 256'h6E616D6D6F43203A312053522020202020202020202020202020617461442065;
defparam sdpb_inst_0.INIT_RAM_06 = 256'h7372754320646464642064643030202020202020202020202020202020207364;
defparam sdpb_inst_0.INIT_RAM_07 = 256'h726F73727543206464646420646431302020202020202020202020205820726F;
defparam sdpb_inst_0.INIT_RAM_08 = 256'h4220726F73727543204278787820303030312020202020202020202020205920;
defparam sdpb_inst_0.INIT_RAM_09 = 256'h726F6C6F6320746E6F46206464646420313030312066666F2F6E6F206B6E696C;
defparam sdpb_inst_0.INIT_RAM_0A = 256'h4720726F6C6F6320746E6F462064646464203031303120656C6262696E205220;
defparam sdpb_inst_0.INIT_RAM_0B = 256'h6E204220726F6C6F6320746E6F462064646464203131303120656C6262696E20;
defparam sdpb_inst_0.INIT_RAM_0C = 256'h20202020207261656C43202C656D6F482043487878203030313120656C626269;
defparam sdpb_inst_0.INIT_RAM_0D = 256'h6C6262696E205220726F6C6F63206B6361422064646464203130313120202020;
defparam sdpb_inst_0.INIT_RAM_0E = 256'h20656C6262696E204720726F6C6F63206B636142206464646420303131312065;
defparam sdpb_inst_0.INIT_RAM_0F = 256'h202020656C6262696E204220726F6C6F63206B63614220646464642031313131;

endmodule //Gowin_SDPB
