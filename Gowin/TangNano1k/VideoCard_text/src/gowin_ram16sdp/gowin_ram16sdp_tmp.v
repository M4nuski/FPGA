//Copyright (C)2014-2025 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.11.03 Education
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Tue Nov  3 18:46:49 2026

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_RAM16SDP your_instance_name(
        .dout(dout), //output [7:0] dout
        .wre(wre), //input wre
        .wad(wad), //input [8:0] wad
        .di(di), //input [7:0] di
        .rad(rad), //input [8:0] rad
        .clk(clk) //input clk
    );

//--------Copy end-------------------
