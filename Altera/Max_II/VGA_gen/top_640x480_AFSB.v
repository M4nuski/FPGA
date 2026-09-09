// 640x480@60
// 25.175 pin 14
//
// AFSB - odd sync artefacts

module top
(
	input clkVGA, // PIN14 25.175MHz 

	output vsync, // inverted through 74LVC2G14 at 3.3V, then 100 ohm resistor
	output hsync, // inverted through 74LVC2G14 at 3.3V, then 100 ohm resistor
	output pattern1,
	output pattern2,
	output pattern2r,
	output pattern2g,
	output pattern2b,
	
	output reg clkVGA1000
);

localparam H_Active = 10'd640;
localparam H_FrontPorch = 10'd16;
localparam H_Sync = 10'd96;
localparam H_BackPorch = 10'd48;
localparam H_Max = H_Active + H_FrontPorch + H_Sync + H_BackPorch - 1;

localparam V_Active = 10'd480;
localparam V_FrontPorch = 10'd10;
localparam V_Sync = 10'd2;
localparam V_BackPorch = 10'd33;
localparam V_Max = V_Active + V_FrontPorch + V_Sync + V_BackPorch - 1;

wire[2:0] rgb [3:0];
assign rgb[0] = 3'b100;
assign rgb[1] = 3'b010;
assign rgb[2] = 3'b001;
assign rgb[3] = 3'b111;

reg[9:0] H_PixelCount = 0;
reg[9:0] V_LineCount = 0;

// a 100
// f 2
// s 2
// b 2
// t 106
// m 105

// ca 0 - 99
// cf 100 - 101
// cs 102 - 103
// cb 104 - 105

assign vsync = ( (V_LineCount  >= (V_Active + V_FrontPorch)) && (V_LineCount  < (V_Active + V_FrontPorch + V_Sync)) );
assign hsync = ( (H_PixelCount >= (H_Active + H_FrontPorch)) && (H_PixelCount < (H_Active + H_FrontPorch + H_Sync)) );

wire active_gate = (H_PixelCount < H_Active) && (V_LineCount < V_Active);

// Contours and center pattern
wire H_pix = (H_PixelCount == 0) || (H_PixelCount == (H_Active/2)) || (H_PixelCount == (H_Active-1));
wire V_pix = (V_LineCount  == 0) || (V_LineCount  == (V_Active/2)) || (V_LineCount == (V_Active-1));
assign pattern1 = active_gate && (H_pix || V_pix);// ? 1 : 0;

// Checkered white pattern
assign pattern2 = active_gate && (H_PixelCount[4] ^ V_LineCount[4]);

// Checkered RGB pattern
assign pattern2r = active_gate && rgb[{V_LineCount[4], H_PixelCount[4]}][2];
assign pattern2g = active_gate && rgb[{V_LineCount[4], H_PixelCount[4]}][1];
assign pattern2b = active_gate && rgb[{V_LineCount[4], H_PixelCount[4]}][0];

always @(posedge clkVGA) begin
	if (H_PixelCount == H_Max) begin
		H_PixelCount <= 10'd0;
		if (V_LineCount == V_Max) begin
			V_LineCount <= 10'd0;
		end else begin
			V_LineCount <= V_LineCount + 10'd1;
		end
	end else begin
		H_PixelCount <= H_PixelCount + 10'd1;
	end
end



reg [9:0] clk50Count = 0;
always @(posedge clkVGA) begin
	if (clk50Count != 10'd0) begin
		clk50Count <= clk50Count - 10'd1;
	end else begin
		clkVGA1000 <= !clkVGA1000;
		clk50Count <=  10'd499;
	end
end


endmodule
