module osc (
	input X1in,
	output X1out,
	input X2in,
	output X2out,
	
	input clkX,
	output reg clkX_out = 0,
	
	input clk50, // PIN_64
	output reg clk50_out = 0
);


assign X1out = !X1in;
assign X2out = !X2in;

reg [9:0] clkXCount = 0;
always @(posedge clkX) begin
	if (clkXCount != 0) begin
		clkXCount <= clkXCount - 10'd1;
	end else begin
		clkX_out <= !clkX_out;
		clkXCount <=  10'd499;
	end
end

reg [9:0] clk50Count = 0;
always @(posedge clk50) begin
	if (clk50Count != 0) begin
		clk50Count <= clk50Count - 10'd1;
	end else begin
		clk50_out <= !clk50_out;
		clk50Count <=  10'd499;
	end
end

endmodule
