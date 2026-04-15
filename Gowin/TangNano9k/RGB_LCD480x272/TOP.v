module top
(
	input			Reset_Button,
    input           User_Button,
    input           XTAL_IN,

	output			LCD_CLK,
	output			LCD_HYNC,
	output			LCD_SYNC,
	output			LCD_DEN,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B
);

wire [15:0] h;
wire [15:0] v;
reg [7:0] testData [0:7];
assign testData[0] = "M";
assign testData[1] = "4";
assign testData[2] = "n";
assign testData[3] = "u";
assign testData[4] = "s";
assign testData[5] = "k";
assign testData[6] = "y";
assign testData[7] = " ";
// 480 * 272 pixels
//  60 *  34 chars
//  30 *  17 chars in bin2

wire [7:0] char = testData[h[6:4]];
wire [13:0] ad = (char * 64) + h[3:1] + (v[3:1] * 8); 
wire fontBit;

assign LCD_R = !LCD_DE ? ((fontBit == 1) ? (5'b11111 ) : gen_R) : 5'd0;
assign LCD_G = !LCD_DE ? ((fontBit == 1) ? (6'b111111) : gen_G) : 6'd0;
assign LCD_B = !LCD_DE ? ((fontBit == 1) ? (5'b11111 ) : gen_B) : 5'd0;
//assign LCD_B = !LCD_DE ? ((Font[v[15:1] % 8][h[15:1] % 8] == 1) ? (5'b11111 ) : gen_B) : 5'd0;

wire [4:0] gen_R;
wire [5:0] gen_G;
wire [4:0] gen_B;

    Gowin_rPLL Gowin_rPLL_9Mhz(
        .clkout(LCD_CLK), // 9MHz
        .clkin(XTAL_IN)   //27MHz
    );

	VGA_timing	VGA_timing_inst(
		.PixelClk	(	LCD_CLK		),
		.nRST		(	Reset_Button),

		.LCD_DE		(	LCD_DEN	 	),
		.LCD_HSYNC	(	LCD_HYNC 	),
    	.LCD_VSYNC	(	LCD_SYNC 	),

		.LCD_B		(	gen_R		),
		.LCD_G		(	gen_G		),
		.LCD_R		(	gen_B		),

		.H (h),
   		.V (v)
	);
	
Gowin_pROM fontData (fontBit, LCD_CLK, 1'b1, 1'b1, 1'b0, ad);



endmodule