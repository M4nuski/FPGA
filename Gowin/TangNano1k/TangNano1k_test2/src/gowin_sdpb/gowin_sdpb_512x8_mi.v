//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Sat Oct 31 19:12:09 2026

module Gowin_SDPB_512x8_mi (dout, clka, cea, reseta, clkb, ceb, resetb, oce, ada, din, adb);

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
defparam sdpb_inst_0.INIT_RAM_00 = 256'h6F47202020202020202020202020202020203536354247522032373278303834;
defparam sdpb_inst_0.INIT_RAM_01 = 256'h352E33312020202020202020202020202020202020312D5A4E315747206E6977;
defparam sdpb_inst_0.INIT_RAM_02 = 256'h6B73756E344D202020202020202020202020202020206B636F6C4370207A484D;
defparam sdpb_inst_0.INIT_RAM_03 = 256'h2020202020202020202020202020202020202020202020202020363230322079;
defparam sdpb_inst_0.INIT_RAM_04 = 256'h656C616373207478655420202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_05 = 256'h387838204147433A746E6F46202020202020202020202020202020202020323A;
defparam sdpb_inst_0.INIT_RAM_06 = 256'h2020202020202020203731783033202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_07 = 256'h2020202020202020202020202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_08 = 256'h20202020333A656C6163732070616D7469422020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_09 = 256'h20202020202073726F6C6F632036312F70706234202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_0A = 256'h2020202020202020202020202020202030397830363120202020202020202020;
defparam sdpb_inst_0.INIT_RAM_0B = 256'h20202020202020202020657474656C6170203536354247522020202020202020;
defparam sdpb_inst_0.INIT_RAM_0C = 256'h2020202020202020202020202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_0D = 256'h2020202020202020202020202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_0E = 256'h2020202020202020202020202020202020202020202020202020202020202020;
defparam sdpb_inst_0.INIT_RAM_0F = 256'h2020202020202020202020202020202020202020202020202020202020202020;

endmodule //Gowin_SDPB_512x8_mi
