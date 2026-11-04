// Text mode video card 
// RGB565 480x272 pixel output
// 8x8 CGA font
// CPU8 interface

// 480 * 272 pixels
// text layer, bin 2
// 480/8/2 = 30 chars wide
// 272/8/2 = 17 lines high
// 30x17 = 510 chars total

module top
(
    input XTAL_IN,

	output reg LCD_CLK,
	output LCD_HYNC,
	output LCD_SYNC,
	output LCD_DEN,
	output [4:0] LCD_R,
	output [5:0] LCD_G,
	output [4:0] LCD_B,

	input WRn,
    input [2:0] address,
    input [7:0] data
);


// interface
reg [7:0] dataBuffer;
reg [2:0] addressBuffer;

// Address 0 Write char, advance cursor
// Address 1 Write char, advance cursor
// Address 2 Command
//           0 Home cursor
//           1 Clear Screen, home cursor
//           2 Set argument as cursor X
//           3 Set argument as cursor Y
//           4 Set argument as font color high byte
//           4 Set argument as font color low byte
//           4 Set argument as back color high byte
//           4 Set argument as back color low byte
//           8 Blink On
//           9 Blink Off
// Address 3 Argument


// 16 bits 565 RGB         RRRRRGGGGGGBBBBB
reg [15:0] fontColor = 16'b0111101111101111;
reg [15:0] backColor = 16'b0000000000000000;

reg [22:0] blinkerCounter = 0;
reg blink = 1;

reg Reset = 1;
reg [8:0] counter = 0; // 0-511
wire CLS = counter != 9'd511;
reg [8:0] cursor = 8*30;
reg [2:0] WR = 3'b111;
reg [7:0] currentData;
reg [7:0] command;
reg tRAMwrite = 0;

// to allow unsync of WR and XTAL
always @(posedge WRn) begin
	addressBuffer <= address;
	dataBuffer <= data;
end

wire [9:0] h;
wire [9:0] ph = h + 10'd1; // fetch char 1 pixel in advance
wire [9:0] v;

wire [7:0] tdin; // text data in
wire [8:0] tadb; // text out address
wire [7:0] tdout; // text data out
wire [8:0] tada; // text in address

always @(posedge XTAL_IN) begin
	// write gate
	WR <= { WR[1:0], WRn };

	if (tRAMwrite == 1) tRAMwrite <= 0;

	// counter
	if (counter != 9'd511) begin
		counter <= counter + 9'd1;
		tRAMwrite <= 1;
	end else Reset <= 0;

	// address commands and data
	if (WR == 3'b011) begin
		case (addressBuffer)
			2'd0: begin // write and advance cursor
				currentData <= dataBuffer;
				cursor <= cursor + 9'd1;
				tRAMwrite <= 1;
			end
			2'd1: begin // write and advance cursor
				currentData <= dataBuffer;
				cursor <= cursor + 9'd1;
				tRAMwrite <= 1;
			end
			2'd2: begin // command
				case (dataBuffer)
					0 : cursor <= 9'd0; // home
					1 : begin           // CLS
						counter <= 9'd0;
						cursor <= 9'd0;
					end
					8 : blink <= 1;
					9 : blink <= 0;
					default: command <= dataBuffer;
				endcase
			end
			2'd3: begin // command argument
				case (command)
					2 : cursor <= dataBuffer + (cursorY << 5) - (cursorY << 1);
					3 : cursor <= cursorX + (dataBuffer << 5) - (dataBuffer << 1);	
					4 : fontColor[15:8] <= dataBuffer;
					5 : fontColor[7:0] <= dataBuffer;
					6 : backColor[15:8] <= dataBuffer;
					7 : backColor[7:0] <= dataBuffer;
				endcase
			end 
		endcase
	end
end

wire [6:0] cursorX = cursor % 7'd30;
wire [6:0] cursorY = (cursor / 7'd30);
wire [8:0] voffset = (v[8:4] << 5) - (v[8:4] << 1); // x30
assign tadb = ph[8:4] + voffset; // char ram address to read
assign tada = (CLS) ? (counter - 9'd1) : (cursor - 9'd1); // char ram address to write
assign tdin = (CLS) ? ((Reset == 1) ? (counter[7:0] + 8'h21) : 0) : currentData; // char ram data to write

// fetch font data
wire [31:0] fdout;
wire [13:0] fontAddress = (tdout * 64) + h[3:1] + (v[3:1] * 8); 
wire fontBit = fdout[~fontAddress[4:0]];
wire pixel = ((blinkerCounter[22] == 1) && (cursor == (h[8:4] + voffset)) && (v[3:1] == 3'd7)) ? (blink ? ~fontBit : fontBit) : fontBit;

// gen font bitmap
assign LCD_R = (pixel == 1) ? fontColor[15:11] : backColor[15:11];
assign LCD_G = (pixel == 1) ? fontColor[10: 5] : backColor[10: 5];
assign LCD_B = (pixel == 1) ? fontColor[ 4: 0] : backColor[ 4: 0];

// LCD clock at 13.5MHz
always @(posedge XTAL_IN) LCD_CLK <= ~LCD_CLK;
always @(posedge LCD_CLK) blinkerCounter <= blinkerCounter + 23'd1;

RGB565_timing videoGen(
	LCD_CLK,
    !Reset,
	LCD_DEN, 
    LCD_HYNC,
    LCD_SYNC,	
	h,
    v
);

//Gowin_RAM16SDP textRAM(
//        .dout(tdout), //output [7:0] dout
//        .wre(tRAMwrite), //input wre
//        .wad(tada), //input [8:0] wad
//        .di(tdin), //input [7:0] di
//        .rad(tadb), //input [8:0] rad
//        .clk(XTAL_IN) //input clk
//    );

Gowin_SDPB textRAM(tdout, XTAL_IN, tRAMwrite, 1'b0, ~XTAL_IN, 1'b1, 1'b0, 1'b1, tada, tdin, tadb);

wire [5:0] fyadr = fontAddress[10:5]; // column
wire [4:0] fxadr = {2'b00, fontAddress[13:11]}; // row
Gowin_User_Flash fontROM (fdout, 1'b1, 1'b1, XTAL_IN, 1'b0, 1'b0, 1'b0, fxadr, fyadr, 32'd0);


endmodule


