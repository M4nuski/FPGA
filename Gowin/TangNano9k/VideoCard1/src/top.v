// Text mode video card 
// HDMI / VGA 640x480 pixel output
// 8x8 CGA font
// CPU8 interface

// 320 * 240 pixels
// text layer, bin 2
// 320/8 = 40 chars wide
// 240/8 = 30 lines high
// 40x30 = 1200 chars total

module top
(
    input XTAL_IN,

    output  RGB_R,
    output  RGB_G,
    output  RGB_B,

    output RGB_Blank,
    output RGB_Clock,

    output SYNC_H,
    output SYNC_V,
    output led
);


reg Resetn = 0;
assign RGB_Clock = vgaClk;

Gowin_rPLL_27_126 clkMult(
    .clkout(clkoutx5), //output clkout
    .clkin(XTAL_IN), //input clkin
    .lock(locked)
);

Gowin_CLKDIV5 clkDiv(
    .clkout(vgaClk), //output clkout
    .hclkin(clkoutx5), //input hclkin
    .resetn(locked) //input resetn
);

wire rgb_vs, rgb_hs, rgb_de;
wire [9:0] pixel, line;
wire [9:0] pixelNext = pixel + 10'd1; // fetch char 1 pixel in advance

VGA_timing videoGen(
	vgaClk,
    locked,
	rgb_de, 
    rgb_hs,
    rgb_vs,	
    pixel,
    line
);

//always @(negedge vgaClk)  begin
 assign    SYNC_H = rgb_hs;
 assign    SYNC_V = rgb_vs;
 assign    RGB_R = rgb_de & (((pixel == 0  ) || (pixel == 639)) ? 1 | Text_R : Text_R);
 assign    RGB_G = rgb_de & (((line  == 0  ) || (line  == 479)) ? 1 | Text_G : Text_G);
 assign    RGB_B = rgb_de & (((pixel == 320) || (line  == 240)) ? 1 | Text_B : Text_B);
assign     RGB_Blank = rgb_de;
//end
// interface
//reg [7:0] dataBuffer;
//reg [2:0] addressBuffer;

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

reg [23:0] blinkerCounter = 0;
reg blink = 1;
assign led = blinkerCounter[23];

//assign RGB_R = rgb_de & (((pixel == 0  ) || (pixel == 639)) ? 1 | Text_R : Text_R);
//assign RGB_G = rgb_de & (((line  == 0  ) || (line  == 479)) ? 1 | Text_G : Text_G);
//assign RGB_B = rgb_de & (((pixel == 320) || (line  == 240)) ? 1 | Text_B : Text_B);

reg [10:0] counter = 0; // 0-1199
wire CLS = counter != 11'd1200;
reg [10:0] cursor = 0;
wire [5:0] cursorX = cursor % 6'd40;
wire [5:0] cursorY = cursor / 6'd40;

//reg [2:0] WR = 3'b111;
reg [7:0] currentData = 0;
//reg [7:0] command;
reg tRAMwrite = 0;

// to allow unsync of WR and XTAL
//always @(posedge WRn) begin
//	addressBuffer <= address;
//	dataBuffer <= data;
//end




wire [ 7:0] TextInData; // text data in
wire [10:0] TextOutAddress; // text out address
wire [ 7:0] TextOutData; // text data out
wire [10:0] TextInAddress; // text in address

always @(posedge vgaClk) begin
	// write gate
	//WR <= { WR[1:0], WRn };

	if (tRAMwrite == 1) tRAMwrite <= 0;

	// counter
	if (counter != 11'd1200) begin
		counter <= counter + 11'd1;
		tRAMwrite <= 1;
	end else Resetn <= 1;

    blinkerCounter <= blinkerCounter + 24'd1;
    //FontOutData <= FontData;
//	 address commands and data
//	if (WR == 3'b011) begin
//		case (addressBuffer)
//			2'd0: begin // write and advance cursor
//				currentData <= dataBuffer;
//				cursor <= cursor + 9'd1;
//				tRAMwrite <= 1;
//			end
//			2'd1: begin // write and advance cursor
//				currentData <= dataBuffer;
//				cursor <= cursor + 9'd1;
//				tRAMwrite <= 1;
//			end
//			2'd2: begin // command
//				case (dataBuffer)
//					0 : cursor <= 9'd0; // home
//					1 : begin           // CLS
//						counter <= 9'd0;
//						cursor <= 9'd0;
//					end
//					8 : blink <= 1;
//					9 : blink <= 0;
//					default: command <= dataBuffer;
//				endcase
//			end
//			2'd3: begin // command argument
//				case (command)
//					2 : cursor <= dataBuffer + (cursorY << 5) - (cursorY << 1);
//					3 : cursor <= cursorX + (dataBuffer << 5) - (dataBuffer << 1);	
//					4 : fontColor[15:8] <= dataBuffer;
//					5 : fontColor[7:0] <= dataBuffer;
//					6 : backColor[15:8] <= dataBuffer;
//					7 : backColor[7:0] <= dataBuffer;
//				endcase
//			end 
//		endcase
//	end
end



wire [10:0] voffset = (line[9:4] << 5) + (line[9:4] << 3);
assign TextOutAddress = pixelNext[9:4] + voffset; // char ram address to read
assign TextInAddress  = (CLS) ? (counter - 11'd1) : (cursor - 11'd1); // char ram address to write
assign TextInData     = (CLS) ? ((Resetn == 0) ? (counter[7:0] + 8'h21) : 0) : currentData; // char ram data to write

//wire [13:0] FontAddress = (TextOutData * 64) + pixel[3:1] + (line[3:1] * 8); 
wire [13:0] FontAddress = (TextOutAddress * 14'd64) + pixel[3:1] + (line[3:1] * 14'd8); 
wire fontBit = FontOutData[~FontAddress[4:0]];
wire Tpixel = ((blinkerCounter[23] == 1) && (cursor == (pixel[9:4] + voffset)) && (line[3:1] == 3'd7)) ? (blink ? ~fontBit : fontBit) : fontBit;
// fetch font data
reg [31:0] FontOutData;

//reg vgaClk2 = 0;
always @(negedge vgaClk) FontOutData <= FontData;

//always @(posedge vgaClk or negedge locked) begin
  //  if (!locked) vgaClk2 <= 1; else vgaClk2 <= ~vgaClk2;
//end
// gen font bitmap
wire Text_R = Tpixel;
wire Text_G = Tpixel;
wire Text_B = Tpixel;
//wire Text_R = (pixel == 1) ? fontColor[15:11] : backColor[15:11];
//wire Text_G = (pixel == 1) ? fontColor[10: 5] : backColor[10: 5];
//wire Text_B = (pixel == 1) ? fontColor[ 4: 0] : backColor[ 4: 0];


//Gowin_SDPB textRAM(TextOutData, vgaClk, tRAMwrite, 1'b0, ~vgaClk, 1'b1, 1'b0, 1'b1, TextInAddress, TextInData, TextOutAddress);
Gowin_SDPB textRAM(
    .dout(TextOutData), //output [7:0] dout
    .clka(vgaClk), //input clka
    .cea(tRAMwrite), //input cea
    .reseta(1'b0), //input reseta
    .clkb(~vgaClk), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'b1), //input oce
    .ada(TextInAddress), //input [10:0] ada
    .din(TextInData), //input [7:0] din
    .adb(TextOutAddress) //input [10:0] adb
);


wire [5:0] FontAddressY = FontAddress[10:5]; // column
wire [8:0] FontAddressX = {6'd0, FontAddress[13:11]}; // row

wire[31:0] FontData;// = FontAddress[12:5];
Gowin_User_Flash fontROM(
    .dout(FontData), //output [31:0] dout
    .xe(1'b1), //input xe
    .ye(1'b1), //input ye
    .se(~vgaClk), //input se
    .prog(1'b0), //input prog
    .erase(1'b0), //input erase
    .nvstr(1'b0), //input nvstr
    .xadr(FontAddressX), //input [8:0] xadr
    .yadr(FontAddressY), //input [5:0] yadr
    .din(32'd0) //input [31:0] din
);

endmodule


