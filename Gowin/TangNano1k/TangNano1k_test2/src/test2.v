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
    input [1:0] address,
    input [7:0] data
//ERROR  (PR2017) : 'data[4]' cannot be placed according to constraint, for the location is a dedicated pin (DONE) 45
//ERROR  (PR2017) : 'data[3]' cannot be placed according to constraint, for the location is a dedicated pin (READY)46
);
// interface
reg [7:0] dataBuffer;
reg [1:0] addressBuffer;
// Address 0: Write text data, increment cursor
// Address 1: Write text data, increment cursor
// Address 2: Command
//				0 : Home Cursor
//				1 : Clear Screen
//				2 : Set Cursor X
//				3 : Set Cursor Y
//				4 : Set Font Color High Byte
//				5 : Set Font Color Low Byte
//				6 : Set Back Color High Byte
//				7 : Set Back Color Low Byte
//				8 : Blink On
//				9 : Blink Off
// Address 3: Command argument

// 16 bits 565 RGB         RRRRRGGGGGGBBBBB
reg [15:0] fontColor = 16'b0111101111101111;
reg [15:0] backColor = 16'b0000000000000000;

reg [23:0] blinkerCounter = 0;
reg blink = 1;

reg Reset = 1;
reg [8:0] counter = 0; // 0-511
wire CLS = counter != 9'd511;
reg [8:0] cursor = 0;
reg [2:0] WR = 3'b111;
reg [7:0] currentData;
reg [7:0] command;
reg RAMwrite = 0;

// to allow unsync of WR and XTAL
always @(posedge WRn) begin
	addressBuffer <= address;
	dataBuffer <= data;
end

wire [15:0] h;//todo reduce bitwidth
wire [15:0] v;

// 480 * 272 pixels
//  60 *  34 chars at 8x8 (2040)
//  30 *  17 chars in bin2 (510)
wire  [7:0] din;
wire [11:0] adb; 
wire  [7:0] dout;
wire [11:0] ada;

always @(negedge XTAL_IN) begin
	// write gate
	WR <= { WR[1:0], WRn };

	if (RAMwrite == 1) RAMwrite <= 0;

	// counter
	if (counter != 9'd511) begin
		counter <= counter + 9'd1;
		RAMwrite <= 1;
	end else Reset <= 0;

	// address commands and data
	if (WR == 3'b011) begin
		case (addressBuffer)
			2'd0: begin // write and advance cursor
				currentData <= dataBuffer;
				cursor <= cursor + 9'd1;
				RAMwrite <= 1;
			end
			2'd1: begin // write and advance cursor
				currentData <= dataBuffer;
				cursor <= cursor + 9'd1;
				RAMwrite <= 1;
			end
			2'd2: begin // command
				case (dataBuffer)
					0 : cursor <= 9'd0;
					1 : begin
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

wire [9:0] cursorX = cursor % 30;
wire [9:0] cursorY = cursor / 30;
wire [11:0] voffset = (v[8:4] << 5) - (v[8:4] << 1);
assign adb = h[8:4] + voffset; // char ram address to read
assign ada = (CLS) ? counter-1 : (cursor - 9'd1); // char ram address to write
assign din = (CLS) ? ((Reset == 1) ? (counter + 8'h21) : 0) : currentData; // char ram data to write

// fetch font data
wire fontBit;
wire [13:0] fontAddress = (dout * 64) + h[3:1] + (v[3:1] * 8); 
wire fontCarret = ((blinkerCounter[23] == 1) && (cursor == adb) && (v[3:1] == 3'd7)) ? (blink ? 1 : fontBit) : fontBit;

//overlay font data
assign LCD_R = (fontCarret == 1) ? fontColor[15:11] : backColor[15:11];
assign LCD_G = (fontCarret == 1) ? fontColor[10:5] : backColor[10:5];
assign LCD_B = (fontCarret == 1) ? fontColor[4:0] : backColor[4:0];
/*assign LCD_R = (fontCarret == 1) ? (5'b11111 ) : gen_R;
assign LCD_G = (fontCarret == 1) ? (6'b111111) : gen_G;
assign LCD_B = (fontCarret == 1) ? (5'b11111 ) : gen_B;*/
/*assign LCD_R = gen_R;
assign LCD_G = gen_G;
assign LCD_B = gen_B;*/

//color layer from timing generator
wire [4:0] gen_R;
wire [5:0] gen_G;
wire [4:0] gen_B;

// LCD clock at 13.5MHz
always @(posedge XTAL_IN) LCD_CLK <= ~LCD_CLK;
always @(posedge LCD_CLK) blinkerCounter <= blinkerCounter + 1;

VGA_timing VGA(
	LCD_CLK, !Reset,
	LCD_DEN, LCD_HYNC, LCD_SYNC,	
	gen_R, gen_G, gen_B,
	h, v
);
//14 bit addres, 1 bit data
Gowin_pROM fontData(fontBit, LCD_CLK, 1'b1, 1'b1, 1'b0, fontAddress);
//a writes, b reads, 12 bit address, 7 bit data
Gowin_SDPB charRAM(dout, XTAL_IN, RAMwrite, 1'b0, ~XTAL_IN, 1'b1, 1'b0, 1'b1, ada, din, adb);


endmodule