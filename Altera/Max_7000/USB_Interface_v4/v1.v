// USB Interface V4
// Initial Version
// Read - Modify
// Same nibble each time

// data format is [aaaadddd] where aaaa is nibble address and dddd is nibble data
// up to 64 bits in and 64 bits out

module v1 (
	input clk,
	
	inout [7:0] FT_D,
	input FT_TXn, // 1 fifo full, 0 fifo has space for write,
	input FT_RXn, // 1 not data in fifo, 0 data available for read in fifo
	output reg FT_WRn = 1,
	output reg FT_RDn = 1,
	
	output reg [23:0] out,
	input [23:0] in
);

reg [7:0] data = 0;
reg [7:0] command = 0;
reg WEn = 1;
assign FT_D = (WEn == 0) ? data : 8'bZZZZZZZZ; // tri-state inout port

reg [2:0] step = 0;
wire [2:0] Hnibble = command[6:4];
wire [3:0] Lnibble = command[3:0];
 
always @(posedge clk) begin
case (step)

	0: begin
		if (FT_RXn == 0) begin
			FT_RDn <= 0; // read signal
			step <= 1;
		end
	end

	1: begin
		command <= FT_D; // fetch FIFO
		FT_RDn <= 1;
		step <= 2;
	end
	
	2: begin
		data[7:4] <= {1'b0, Hnibble}; // read input pins
		data[0] <= in[{Hnibble, 2'b00}];
		data[1] <= in[{Hnibble, 2'b01}];
		data[2] <= in[{Hnibble, 2'b10}];
		data[3] <= in[{Hnibble, 2'b11}];
		
		step <= 3;
	end
	
	3: begin		
		out[{Hnibble, 2'b00}] <= Lnibble[0]; // write output pins
		out[{Hnibble, 2'b01}] <= Lnibble[1];
		out[{Hnibble, 2'b10}] <= Lnibble[2];
		out[{Hnibble, 2'b11}] <= Lnibble[3];
		
		if (FT_TXn == 0) begin // if FIFO available write 
			FT_WRn <= 0;
			WEn <= 0;
			step <= 4;
		end else step <= 0;
	end

	4: begin
		FT_WRn <= 1; // latch data in FIFO
		step <= 5;
	end
	
	5: begin
		WEn <= 1; // high-Z after FIFO FT_WRn hold-off
		step <= 0;
	end
	
endcase
end

endmodule
