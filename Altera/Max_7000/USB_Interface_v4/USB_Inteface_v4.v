//`define VERSION_1
`define VERSION_2

module top
(
	input clk,
	
	inout [7:0] FT_D,
	input FT_TXn, // 1 fifo full, 0 fifo has space for write,
	input FT_RXn, // 1 not data in fifo, 0 data available for read in fifo
	output FT_WRn,
	output FT_RDn,
	
	output [23:0] out,
	input [23:0] in
);

`ifdef VERSION_1
	v1 top_v1(
		clk,
		
		FT_D,
		FT_TXn,
		FT_RXn,
		FT_WRn,
		FT_RDn,
		
		out,
		in
	);
	
`elsif VERSION_2
	v2 top_v2(
		clk,
		
		FT_D,
		FT_TXn,
		FT_RXn,
		FT_WRn,
		FT_RDn,
		
		out,
		in
	);
	
`endif


endmodule