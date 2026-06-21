// USB Interface V4
// Version 3
// MSB of 0: Write nibble
// MSB of 1: Read nibble

// data format is [xaaadddd] where x is read or write, aaa is nibble address and dddd is nibble data
// up to 32 bits in and 32 bits out
// FT_WRn switched to FT_WR for active high

module v3 (
	input clk,
	
	inout [7:0] FT_D,
	input FT_TXn, // 1 fifo full, 0 fifo has space for write,
	input FT_RXn, // 1 not data in fifo, 0 data available for read in fifo
	output reg FT_WR = 0,
	output reg FT_RDn = 1,
	
	output reg [23:0] out,
	input [23:0] in
);

reg [7:0] data = 0;
//reg [7:0] command = 0;
reg WEn = 1;
assign FT_D = (WEn == 0) ? data : 8'bZZZZZZZZ; // tri-state inout port

reg [2:0] step = 0;
wire [2:0] Hnibble = FT_D[6:4];
wire [3:0] Lnibble = FT_D[3:0];
 
always @(posedge clk) begin
case (step)

	0: begin
		WEn <= 1; // high-Z after FIFO FT_WR hold-off
		if (FT_RXn == 0) begin
			FT_RDn <= 0; // read signal
			step <= 1;
		end
	end

	1: begin		
		FT_RDn <= 1;
		if (FT_D[7] == 0) begin // write
			out[{Hnibble, 2'b00}] <= Lnibble[0];
			out[{Hnibble, 2'b01}] <= Lnibble[1];
			out[{Hnibble, 2'b10}] <= Lnibble[2];
			out[{Hnibble, 2'b11}] <= Lnibble[3];
			step <= 0;
		end else begin // read
			//command <= FT_D; // fetch FIFO
			data[7:4] <= {1'b0, Hnibble};
			data[0] <= in[{Hnibble, 2'b00}];
			data[1] <= in[{Hnibble, 2'b01}];
			data[2] <= in[{Hnibble, 2'b10}];
			data[3] <= in[{Hnibble, 2'b11}];
			step <= 2;
		end		
	end
	
	2: begin
		if (FT_TXn == 0) begin // if FIFO available write 
			FT_WR <= 1;
			WEn <= 0;
			step <= 3;
		end else step <= 0;
	end

	3: begin
		FT_WR <= 0; // latch data in FIFO
		step <= 0;
	end
	
	default: step <= 0;
endcase
end

endmodule
