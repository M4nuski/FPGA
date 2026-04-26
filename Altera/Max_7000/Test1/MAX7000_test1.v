module MAX7000_test1
(
	input clk,
	
	inout [7:0] FT_D,
	input FT_TXn, // 0 ok to write, 1 fifo full
	input FT_RXn, // 1 not data, 0 data available in fifo
	output reg FT_WRn = 1,
	output reg FT_RDn = 1,
	
	output reg [23:0] out,
	input [23:0] in
);

reg [7:0] data = 0;
wire [7:0] FT_Buffer = (FT_WRn == 0) ? data : 8'bZZZZZZZZ;
assign FT_D = FT_Buffer;

reg [3:0] step = 0;
reg [6:0] address;
wire [6:0] Hnibble = FT_D[7:4] << 2;
wire [3:0] Lnibble = FT_D[3:0];
 
always @(posedge clk) begin
case (step)

	0: begin
		if (FT_RXn == 0) begin
			FT_RDn <= 0; // read
			step <= 1;
		end
	end
	
	1: begin
		address <= Hnibble;
		
		out[Hnibble+0] <= Lnibble[0];
		out[Hnibble+1] <= Lnibble[1];
		out[Hnibble+2] <= Lnibble[2];
		out[Hnibble+3] <= Lnibble[3];
		
		step <= 2;
	end
	
	2: begin
		FT_RDn <= 1;
		data[7:4] <= address[5:2];
		data[0] <= in[address+0];
		data[1] <= in[address+1];
		data[2] <= in[address+2];
		data[3] <= in[address+3];
		step <= 3;
	end
	3: begin
		if (FT_TXn == 0) begin
			FT_WRn <= 0;
			step <= 4;
		end else step <= 0;
	end
	4: begin
		FT_WRn <= 1;
		step <= 0;
	end
	
endcase
end

endmodule