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
//ERROR  (PR2017) : 'data[4]' cannot be placed according to constraint, for the location is a dedicated pin (DONE) 45
//ERROR  (PR2017) : 'data[3]' cannot be placed according to constraint, for the location is a dedicated pin (READY)46
);

// 480 * 272 pixels

// text layer
// 480/8 = 60
// 272/8 = 34
// 60x34 = 2040
// bin 2
// 30x17 = 510*
// 640/8 = 80
// 480/8 = 60
// 80x60 = 4800
// bin 2
// 40x30 = 1200

// bitmap layer
// bin 3
// 480/3 = 160
// 272/3 = 90.667
// 160*90 = 14400
// bin 2
// 480/2 = 240
// 272/2 = 136
// 240x136 = 32640

// ROM 8x8 CGA font 2K
// RAM 9K
// 510 text mode
// 16 palette 4bpp to 565
// 4bpp * 14400 = 7200

//reg[255:0] palette = {16'h0000,16'h001F,16'h02A0,16'h02BF,16'h0540,16'h055F,16'h07E0,16'h07FF,16'hF800,16'hF81F,16'hFAA0,16'hFABF,16'hFD40,16'hFD5F,16'hFFE0,16'hFFFF};
//reg[255:0] palette = {16'h0000, 16'h001F, 16'h07E0, 16'h07FF, 16'hF800, 16'hF81F, 16'hFFE0, 16'hFFFF, 16'h0000, 16'h2124, 16'h4A49, 16'h6B6D, 16'h9492, 16'hB5B6, 16'hDEDB, 16'hFFFF};
reg [15:0] palette[15:0];// = (, , , , , , , , , , , , , ,, 0);
//reg[255:0] palette = {16'hFFFF, 16'hFFE0, 16'hF81F, 16'hF800, 16'h07FF, 16'h07E0, 16'h001F, 16'h0000, 16'hFFFF, 16'hDEDB, 16'hB5B6, 16'h9492, 16'h6B6D, 16'h4A49, 16'h2124, 16'h0000};
initial begin
palette[ 0] = 16'h0000;
palette[ 1] = 16'h2124;
palette[ 2] = 16'h4A49;
palette[ 3] = 16'h6B6D;
palette[ 4] = 16'h9492;
palette[ 5] = 16'hB5B6;
palette[ 6] = 16'hDEDB;
palette[ 7] = 16'hFFFF;
palette[ 8] = 16'h0000;
palette[ 9] = 16'h001F;
palette[10] = 16'h07E0;
palette[11] = 16'h07FF;
palette[12] = 16'hF800;
palette[13] = 16'hF81F;
palette[14] = 16'hFFE0;
palette[15] = 16'hFFFF;
end
// interface
reg [7:0] dataBuffer;
reg [2:0] addressBuffer;

// Address 0: Write text data
// Address 1: CursorX
// Address 2: CursorY

// Address 3: Write bitmap data
// Address 4: PositionX
// Address 5: PositionY

// Address 6: Command
// Address 7: Argument

// high nibble: command, low nibble: data
//
// 0 Clear      x   x   BMP  TXT
// 1 Cursor     x   INC BLNK HOME
// 2 Increment  enX enY posX posY
// 3 TextColor  cccc
// 4 ClearColor cccc 
// 5 Load Argument as pallette cccc High Byte
// 6 Load Argument as pallette cccc Low Byte
// 7 

// Address 2: Command
//				0 : Home Cursor
//				1 : Clear Text Screen
//				2 : Set Cursor X
//				3 : Set Cursor Y
//				4 : Set Font Color High Byte
//				5 : Set Font Color Low Byte
//				6 : Set Back Color High Byte
//				7 : Set Back Color Low Byte
//				8 : Blink On
//				9 : Blink Off
//              A : Clear Bitmap Screen
//              B : Set Palette Index
//              C : Set Palette Value High Byte
//              D : Set Palette Value Low Byte
//              E :
//              F :
//             Fx : Set position increment value x : 0000 posX posY, 0001 posX negY, 0010 negX posY, 0011 negX negY 
//                                                   10xx noX      , 01xx      noY,  11xx noX  noY
//             FF : No position increment (default)
         
// Address 3: Command argument

// Address 4: Write bitmap data, increment position 
// Address 5: Write bitmap data, increment position

// Address 6: Write position X
// Address 7: Write position Y

// 16 bits 565 RGB         RRRRRGGGGGGBBBBB
reg [15:0] fontColor = 16'b0111101111101111;
//reg [15:0] backColor = 16'b0000000000000000;

reg [23:0] blinkerCounter = 0;
reg blink = 1;

reg Reset = 0;
reg [8:0] counter = 0; // 0-511
wire CLS = counter != 9'd511;
reg [8:0] cursor = 13*30;
reg [2:0] WR = 3'b111;
reg [7:0] currentData;
reg [7:0] command;
reg tRAMwrite = 0;
reg bRAMwrite = 0;

// to allow unsync of WR and XTAL
always @(posedge WRn) begin
	addressBuffer <= address;
	dataBuffer <= data;
end

wire [9:0] h;//todo reduce bitwidth
wire [9:0] ph = h + 10'd1; // fetch char 1 pixel in advance
wire [9:0] v;


wire [7:0] tdin;
wire [8:0] tadb;
wire [7:0] tdout;
wire [8:0] tada;
/*
always @(posedge XTAL_IN) begin


	// write gate
	WR <= { WR[1:0], WRn };

	if (tRAMwrite == 1) tRAMwrite <= 0;
    if (bRAMwrite == 1) bRAMwrite <= 0;

	// counter
	if (counter != 9'd511) begin
		counter <= counter + 9'd1;
		//bRAMwrite <= 1;
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
				//	6 : backColor[15:8] <= dataBuffer;
				//	7 : backColor[7:0] <= dataBuffer;
				endcase
			end 
		endcase
	end
end
*/

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
wire fontCarret = ((blinkerCounter[23] == 1) && (cursor == (h[8:4] + voffset)) && (v[3:1] == 3'd7)) ? (blink ? 1 : fontBit) : fontBit;

//overlay font data
assign LCD_R = (fontCarret == 1) ? fontColor[15:11] : selColor[15:11];
assign LCD_G = (fontCarret == 1) ? fontColor[10:5] : selColor[10:5];
assign LCD_B = (fontCarret == 1) ? fontColor[4:0] : selColor[4:0]; //((h[3] == 0) ? 5'b11111 : backColor[4:0]);
//wire bit = h[15:1] ^ v[15:1];
//assign LCD_R = bit ? 5'b11111 : 0;
//assign LCD_G = bit ? 6'b111111: 0;
//assign LCD_B = bit ? 5'b11111 : 0;
/*assign LCD_R = (fontCarret == 1) ? (5'b11111 ) : gen_R;
assign LCD_G = (fontCarret == 1) ? (6'b111111) : gen_G;
assign LCD_B = (fontCarret == 1) ? (5'b11111 ) : gen_B;*/
/*assign LCD_R = gen_R;
assign LCD_G = gen_G;
assign LCD_B = gen_B;*/
/*assign LCD_R = ((v == 0) | (v == 271)) ? 5'b11111 : 5'b00000 ;
assign LCD_G = ((h == 0) | (h == 479)) ? 6'b111111 : 6'b000000 ;
assign LCD_B = ((h[2] ^ v[2]) == 1) ? 5'b11111 : 5'b00000 ;*/
//color layer from timing generator

//wire [4:0] gen_R;
//wire [5:0] gen_G;
//wire [4:0] gen_B;

reg [6:0] bCount = 0;
reg [1:0] div3Clock = 0;
reg [1:0] bitmapVdiv3 = 0;
always @(posedge LCD_CLK) if ((div3Clock == 2'd2) | (h == 0)) div3Clock <= 0; else div3Clock <= div3Clock + 2'd1; 

//wire lineClock = v == 0;


always @(posedge div3Clock) begin
    if (h == 1) begin
        bCount <= 0;    
        if (v == 1) begin 
            bitmapVdiv3 <= 0;
            bitmapLineOffset <= 0;
        end else if (bitmapVdiv3 == 2'd2) begin
            bitmapVdiv3 <= 0;
            bitmapLineOffset <= bitmapLineOffset + 14'd160;
        end else bitmapVdiv3 <= bitmapVdiv3 + 2'd1;
    end else bCount <= bCount + 6'd1; 
end

reg [13:0] bitmapLineOffset = 0;


wire [3:0] bdin = counter[3:0];
wire [3:0] bdout;
wire [13:0] badb = bCount + bitmapLineOffset ;// + ((v/3)*480);
wire [13:0] bada = badb;
wire [15:0] selColor = palette[bdout];
/*
always @(posedge ~XTAL_IN) case (bdout)
    0: selColor <= palette[ 15:  0];
    1: selColor <= palette[ 31: 16];
    2: selColor <= palette[ 47: 32];
    3: selColor <= palette[ 63: 48];

    4: selColor <= palette[ 79: 64];
    5: selColor <= palette[ 95: 80];
    6: selColor <= palette[111: 96];
    7: selColor <= palette[127:112];

    8: selColor <= palette[143:128];
    9: selColor <= palette[159:144];
   10: selColor <= palette[175:160];
   11: selColor <= palette[191:176];

   12: selColor <= palette[207:192];
   13: selColor <= palette[223:208];
   14: selColor <= palette[239:224];
   15: selColor <= palette[255:240];
    endcase
*/
// LCD clock at 13.5MHz
always @(posedge XTAL_IN) LCD_CLK <= ~LCD_CLK;
always @(posedge LCD_CLK) blinkerCounter <= blinkerCounter + 24'd1;

VGA_timing VGA(
	LCD_CLK, !Reset,
	LCD_DEN, LCD_HYNC, LCD_SYNC,	
	h, v
);
//14 bit addres, 1 bit data
//Gowin_pROM fontData(fontBit, LCD_CLK, 1'b1, 1'b1, 1'b0, fontAddress);
//a writes, b reads, 12 bit address, 7 bit data
Gowin_RAM16SDP_512x8 textRAM(
        .dout(tdout), //output [7:0] dout
        .wre(tRAMwrite), //input wre
        .wad(tada), //input [8:0] wad
        .di(tdin), //input [7:0] di
        .rad(tadb), //input [8:0] rad
        .clk(XTAL_IN) //input clk
    );

//Gowin_SDPB_512x8_mi textRAM(tdout, XTAL_IN, tRAMwrite, 1'b0, ~XTAL_IN, 1'b1, 1'b0, 1'b1, tada, tdin, tadb);
//input [4:0] xadr;
//input [5:0] yadr;
//     [31:0] fdout

wire [5:0] fyadr = fontAddress[10:5]; // column
wire [4:0] fxadr = {2'b00, fontAddress[13:11]}; // row
wire fse = XTAL_IN;
Gowin_User_Flash fontROM (fdout, 1'b1, 1'b1, fse, 1'b0, 1'b0, 1'b0, fxadr, fyadr, 32'd0);

Gowin_SDPB_7200x4_mi bitmapRAM (
        .dout(bdout), //output [3:0] dout
        .clka(XTAL_IN), //input clka
        .cea(bRAMwrite), //input cea
        .reseta(1'b0), //input reseta
        .clkb(~XTAL_IN), //input clkb
        .ceb(1'b1), //input ceb
        .resetb(1'b0), //input resetb
        .oce(1'b1), //input oce
        .ada(bada), //input [13:0] ada
        .din(bdin), //input [3:0] din
        .adb(badb) //input [13:0] adb
    );
endmodule


