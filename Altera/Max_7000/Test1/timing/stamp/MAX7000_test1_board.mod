/*
 Copyright (C) 1991-2013 Altera Corporation
 Your use of Altera Corporation's design tools, logic functions 
 and other software and tools, and its AMPP partner logic 
 functions, and any output files from any of the foregoing 
 (including device programming or simulation files), and any 
 associated documentation or information are expressly subject 
 to the terms and conditions of the Altera Program License 
 Subscription Agreement, Altera MegaCore Function License 
 Agreement, or other applicable license agreement, including, 
 without limitation, that your use is for the sole purpose of 
 programming logic devices manufactured by Altera and sold by 
 Altera or its authorized distributors.  Please refer to the 
 applicable agreement for further details.
*/
MODEL
/*MODEL HEADER*/
/*
 This file contains Slow Corner delays for the design using part EPM7128SLC84-15
 with speed grade 15, core voltage Auto, and temperature 2147483647 Celsius

*/
MODEL_VERSION "1.0";
DESIGN "MAX7000_test1";
DATE "04/26/2026 00:06:37";
PROGRAM "Quartus II 64-Bit";



INPUT clk;
INPUT FT_RXn;
INPUT FT_TXn;
INOUT FT_D[4];
INPUT in[4];
INPUT in[3];
INPUT in[2];
INPUT in[1];
INPUT in[0];
INOUT FT_D[0];
INOUT FT_D[3];
INOUT FT_D[1];
INOUT FT_D[2];
INOUT FT_D[5];
INOUT FT_D[6];
INOUT FT_D[7];
OUTPUT out[5];
OUTPUT out[6];
OUTPUT out[7];
OUTPUT out[8];
OUTPUT out[9];
OUTPUT out[10];
OUTPUT out[11];
OUTPUT out[12];
OUTPUT out[13];
OUTPUT out[14];
OUTPUT out[15];
OUTPUT out[16];
OUTPUT out[17];
OUTPUT out[18];
OUTPUT out[19];
OUTPUT out[20];
OUTPUT out[21];
OUTPUT out[22];
OUTPUT out[23];
OUTPUT FT_WRn;
OUTPUT FT_RDn;
OUTPUT out[0];
OUTPUT out[4];
OUTPUT out[1];
OUTPUT out[2];
OUTPUT out[3];

/*Arc definitions start here*/
pos_FT_D[0]__clk__setup:		SETUP (POSEDGE) FT_D[0] clk ;
pos_FT_D[1]__clk__setup:		SETUP (POSEDGE) FT_D[1] clk ;
pos_FT_D[2]__clk__setup:		SETUP (POSEDGE) FT_D[2] clk ;
pos_FT_D[3]__clk__setup:		SETUP (POSEDGE) FT_D[3] clk ;
pos_FT_D[4]__clk__setup:		SETUP (POSEDGE) FT_D[4] clk ;
pos_FT_RXn__clk__setup:		SETUP (POSEDGE) FT_RXn clk ;
pos_FT_TXn__clk__setup:		SETUP (POSEDGE) FT_TXn clk ;
pos_in[0]__clk__setup:		SETUP (POSEDGE) in[0] clk ;
pos_in[1]__clk__setup:		SETUP (POSEDGE) in[1] clk ;
pos_in[2]__clk__setup:		SETUP (POSEDGE) in[2] clk ;
pos_in[3]__clk__setup:		SETUP (POSEDGE) in[3] clk ;
pos_in[4]__clk__setup:		SETUP (POSEDGE) in[4] clk ;
pos_FT_D[0]__clk__hold:		HOLD (POSEDGE) FT_D[0] clk ;
pos_FT_D[1]__clk__hold:		HOLD (POSEDGE) FT_D[1] clk ;
pos_FT_D[2]__clk__hold:		HOLD (POSEDGE) FT_D[2] clk ;
pos_FT_D[3]__clk__hold:		HOLD (POSEDGE) FT_D[3] clk ;
pos_FT_D[4]__clk__hold:		HOLD (POSEDGE) FT_D[4] clk ;
pos_FT_RXn__clk__hold:		HOLD (POSEDGE) FT_RXn clk ;
pos_FT_TXn__clk__hold:		HOLD (POSEDGE) FT_TXn clk ;
pos_in[0]__clk__hold:		HOLD (POSEDGE) in[0] clk ;
pos_in[1]__clk__hold:		HOLD (POSEDGE) in[1] clk ;
pos_in[2]__clk__hold:		HOLD (POSEDGE) in[2] clk ;
pos_in[3]__clk__hold:		HOLD (POSEDGE) in[3] clk ;
pos_in[4]__clk__hold:		HOLD (POSEDGE) in[4] clk ;
pos_clk__FT_D[0]__delay:		DELAY (POSEDGE) clk FT_D[0] ;
pos_clk__FT_D[1]__delay:		DELAY (POSEDGE) clk FT_D[1] ;
pos_clk__FT_D[2]__delay:		DELAY (POSEDGE) clk FT_D[2] ;
pos_clk__FT_D[3]__delay:		DELAY (POSEDGE) clk FT_D[3] ;
pos_clk__FT_D[4]__delay:		DELAY (POSEDGE) clk FT_D[4] ;
pos_clk__FT_D[5]__delay:		DELAY (POSEDGE) clk FT_D[5] ;
pos_clk__FT_D[6]__delay:		DELAY (POSEDGE) clk FT_D[6] ;
pos_clk__FT_D[7]__delay:		DELAY (POSEDGE) clk FT_D[7] ;
pos_clk__FT_RDn__delay:		DELAY (POSEDGE) clk FT_RDn ;
pos_clk__FT_WRn__delay:		DELAY (POSEDGE) clk FT_WRn ;
pos_clk__out[0]__delay:		DELAY (POSEDGE) clk out[0] ;
pos_clk__out[1]__delay:		DELAY (POSEDGE) clk out[1] ;
pos_clk__out[2]__delay:		DELAY (POSEDGE) clk out[2] ;
pos_clk__out[3]__delay:		DELAY (POSEDGE) clk out[3] ;
pos_clk__out[4]__delay:		DELAY (POSEDGE) clk out[4] ;

ENDMODEL
