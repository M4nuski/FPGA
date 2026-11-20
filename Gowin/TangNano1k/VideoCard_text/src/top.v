// Text mode video card 
// RGB565 480x272 pixel output
// 8x8 CGA font
// CPU8 interface v2

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
    input address,
    input [7:0] data
); 
// v1: 11 wires, 222/1152 LE
// D7-D0
// A1-A0
// WRn

// v2: 10 wire, 315/1152 LE
// D7-D0
// WRn A0

// 8 wire interface?
//  D3 D2 D1 D0
// WRn HN A1 A0

// V2
// Address 0 Data: Write Char data, increase cursor

// Address 1 Commands:
// 00dd dddd Cursor X
// 01dd dddd Cursor Y

// 1000 xxxB Cursor Blink on/off
// 1001 dddd font color R nibble 
// 1010 dddd font color G nibble 
// 1011 dddd font color B nibble 

// 1100 xxHC Home cursor, Clear Screen
// 1101 dddd back color R nibble
// 1110 dddd back color G nibble
// 1111 dddd back color B nibble

// interface
reg [7:0] dataBuffer;
reg addressBuffer;

// 16 bits 565 RGB         RRRRRGGGGGGBBBBB
reg [15:0] fontColor = 16'b0111101111101111;
reg [15:0] backColor = 16'b0000000000000000;

reg [22:0] blinkerCounter = 0;
reg blink = 1;

reg Reset = 1;
reg [8:0] counter = 9'd511; // 0-511
wire CLS = counter != 9'd511;
reg [8:0] cursor = 0;
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
			1'd0: begin // data
				currentData <= dataBuffer;
				cursor <= cursor + 9'd1;
				tRAMwrite <= 1;
			end
			1'd1: begin // command
                if (dataBuffer[7:6] == 2'b00) begin // set X
                    cursor <= dataBuffer[5:0] + (cursorY << 5) - (cursorY << 1);
                end else if (dataBuffer[7:6] == 2'b01) begin // set Y
                    cursor <= cursorX + (dataBuffer[5:0] << 5) - (dataBuffer[5:0] << 1);	
                end else case (dataBuffer[7:4])
                    // 1000 xxxB Cursor Blink on/off
                    4'b1000: blink <= dataBuffer[0]; 
                    4'b1001: fontColor[15:11] <= {dataBuffer[3:0], dataBuffer[0]};
                    4'b1010: fontColor[10:5] <= {dataBuffer[3:0], dataBuffer[0], dataBuffer[0]};   
                    4'b1011: fontColor[4:0] <= {dataBuffer[3:0], dataBuffer[0]};    
                    // 1100 xxHC Home cursor, Clear Screen
                    4'b1100: begin
                        if (dataBuffer[0]) begin
                            counter <= 9'd0;
                            currentData <= 0;
                        end
                        if (dataBuffer[1]) cursor <= 9'd0;
                    end
                    4'b1101: backColor[15:11] <= {dataBuffer[3:0], dataBuffer[0]};
                    4'b1110: backColor[10:5] <= {dataBuffer[3:0], dataBuffer[0], dataBuffer[0]};   
                    4'b1111: backColor[4:0] <= {dataBuffer[3:0], dataBuffer[0]};          
                endcase // command
			end // Address == 1 
        endcase // address
    end // write
end // clk


wire [6:0] cursorX = cursor % 7'd30;
wire [6:0] cursorY = (cursor / 7'd30);
wire [8:0] voffset = (v[8:4] << 5) - (v[8:4] << 1); // x30
assign tadb = ph[8:4] + voffset; // char ram address to read
assign tada = (CLS) ? (counter - 9'd1) : (cursor - 9'd1); // char ram address to write
assign tdin = (CLS) ? 0 : currentData; // char ram data to write

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
//    ); changed back to dpbsram to regain a few hundred LE

Gowin_SDPB textRAM(tdout, XTAL_IN, tRAMwrite, 1'b0, ~XTAL_IN, 1'b1, 1'b0, 1'b1, tada, tdin, tadb);

wire [5:0] fyadr = fontAddress[10:5]; // column
wire [4:0] fxadr = {2'b00, fontAddress[13:11]}; // row
Gowin_User_Flash fontROM (fdout, 1'b1, 1'b1, XTAL_IN, 1'b0, 1'b0, 1'b0, fxadr, fyadr, 32'd0);


endmodule


