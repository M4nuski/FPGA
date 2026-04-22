module CycloneIV_Test1 (
	input a,
	input b,
	output y,
	
	input btn0,
	input btn1,
	input btnReset,
	input btn2,
	input btn3,
	
	output led0,
	output led1,
	output led2,
	output led3,
	output led4,
	
	output tx,
	input rx,
	
	input clk50,
	output reg clk50d10,

	input clk27,
	output reg clk27d10,
	
	output clkVGA,
	output clkLocked,
	output reg clkVGAd10
	
);

assign y = a ^ b;

assign led0 = btn0;
assign led1 = btn1;
assign led2 = btnReset;
assign led3 = btn2;
assign led4 = btn3;

assign tx = rx;

reg[9:0] clk50_count = 0;
reg[9:0] clk27_count = 0;
reg[9:0] clkVGA_count = 0;

always @(posedge clk50) begin
	if (clk50_count == 0) begin 
	clk50_count <= 10'd499; 
	clk50d10 <= !clk50d10;
	end else clk50_count <= clk50_count - 10'd1;
end

always @(posedge clk27) begin
	if (clk27_count == 0) begin 
	clk27_count <= 10'd499; 
	clk27d10 <= !clk27d10;
	end else clk27_count <= clk27_count - 10'd1;
end

always @(posedge clkVGA) begin
	if (clkVGA_count == 0) begin 
	clkVGA_count <= 10'd499; 
	clkVGAd10 <= !clkVGAd10;
	end else clkVGA_count <= clkVGA_count - 10'd1;
end

PLL1 clk_VGA_PLL (
	.areset ( !btnReset ),
	.inclk0 ( clk50 ),
	.c0 ( clkVGA ),
	.locked ( clkLocked )
);

sfl sfl (1'b0);
endmodule