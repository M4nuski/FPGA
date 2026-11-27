`default_nettype wire

// Hybrid mode video card 
// VGA 640x480 / HD 1280x720 (div to at most 640x360)

// CPU8 interface

// 3 step pipeline

// Text Mode
// Bitmap Mode

module top
(
    // clock
    input XTAL_IN, // 27Mhz

    // VGA signals with RGB565 colors
    output reg [4:0] RGB_R_out,
    output reg [5:0] RGB_G_out,
    output reg [4:0] RGB_B_out,
    output reg SYNC_H_out,
    output reg SYNC_V_out,

    // CPU8 interface
    input [7:0] data,
    input [4:0] address,
    input WRn,
    input RDn,

    // debug
    output reg led,
    input vmode, // VGA / HD
    input bres, // bitmap res
    input [1:0] tres, // text res
    input tsize, // text size
    output busy
);


// Clock generation


Gowin_rPLL_126 pll_27_126( // 27MHz to 126MHz
    .clkout(clkout126), //output clkout
    .lock(lock126), //output lock
    .clkin(XTAL_IN) //input clkin
);

Gowin_CLKDIV div_126_25( // 126MHz to 25.2MHz
    .clkout(clock25), //output clkout
    .hclkin(clkout126), //input hclkin
    .resetn(lock126) //input resetn
);

Gowin_rPLL_74p25 pll_27_74( // 27MHz to 74.25MHz
    .clkout(clock74), //output clkout
    .lock(lock74), //output lock
    .clkin(XTAL_IN) //input clkin
);

wire pllLocked = lock74 & lock126;
reg videoMode = 0; // 0:VGA, 1:HD

reg clock37 = 0; // divide 74.25MHz to 37.125MHz 
always @(posedge clock74) clock37 <= ~clock37;


// Clock selection


wire videoClock = videoMode ? clock74 : clock25;
wire pixelClock = videoMode ? clock37 : clock25;
wire romClock = videoMode ? ~pixelClock : pixelClock;


// X/Y position generation


// max is 1024x1024
reg [9:0] x = 0;
reg [9:0] y = 0;
reg [9:0] x2 = 0;
reg [9:0] y2 = 0;
reg [9:0] x4 = 0;
reg [9:0] y4 = 0;
reg [9:0] x5 = 0;
reg [9:0] y5 = 0;
reg [9:0] x8 = 0; // TODO reduce bitwidth
reg [9:0] y8 = 0;

reg       x2_count;
reg [1:0] x4_count;
reg [2:0] x5_count;
reg [2:0] x8_count;
reg       y2_count;
reg [1:0] y4_count;
reg [2:0] y5_count;
reg [2:0] y8_count;


// Vertical pixel counters


reg V_DEdelay; // skip first HSYNC after VSYNC as it is still y==0

always @(posedge HSYNC) begin
    V_DEdelay <= V_DE;
    if (VSYNC) begin

        y  <= 0;
        y2 <= 0;
        y2_count <= 0;
        y4 <= 0;
        y4_count <= 0;
        y5 <= 0;
        y5_count <= 0;
        y8 <= 0;
        y8_count <= 0;

    end else if (V_DEdelay) begin
        
        y <= y + 10'd1;

        if (y2_count == 1) begin
            y2 <= y2 + 10'd1;
            y2_count <= 0;
        end else y2_count <= 1;

        if (y4_count == 2'd3) begin
            y4 <= y4 + 10'd1;
            y4_count <= 0;
        end else y4_count <= y4_count + 2'd1;

        if (y5_count == 3'd4) begin
            y5 <= y5 + 10'd1;
            y5_count <= 0;
        end else y5_count <= y5_count + 3'd1;

        if (y8_count == 3'd7) begin
            y8 <= y8 + 10'd1;
            y8_count <= 0;
        end else y8_count <= y8_count + 3'd1;
    end
end

// Horizontal pixel counters

reg H_DEdelay; // skip first H_DE after HSYNC as it is still x==0

always @(posedge videoClock) begin
    H_DEdelay <= H_DE;
    if (HSYNC) begin

        x  <= 0; 
        x2 <= 0;      
        x2_count <= 0;    
        x4 <= 0;      
        x4_count <= 0; 
        x5 <= 0;      
        x5_count <= 0;  
        x8 <= 0;       
        x8_count <= 0; 

    end else if (H_DEdelay) begin

        x  <= x + 10'd1;

        if (x2_count == 1) begin
            x2 <= x2 + 10'd1;
            x2_count <= 0;
        end else x2_count <= 1;

        if (x4_count == 2'd3) begin
            x4 <= x4 + 10'd1;
            x4_count <= 0;
        end else x4_count <= x4_count + 2'd1;

        if (x5_count == 3'd4) begin
            x5 <= x5 + 10'd1;
            x5_count <= 0;
        end else x5_count <= x5_count + 3'd1;

        if (x8_count == 3'd7) begin
            x8 <= x8 + 10'd1;
            x8_count <= 0;
        end else x8_count <= x8_count + 3'd1;

    end
end


//mode0 resolutions
//00 640x480 4:3  div 1 80x60 / 80x30  - 4800 chars
//01 320x240 4:3  div 2 40x30 / 40x15  - 76800 pixels/frame
//10 160x120 4:3  div 4 20x15 / 20x7.5 - 19200 pixels/frame x3 buffers = 57600 bytes (28800 in 4 bpp)
//11 128x96  4:3  div 5 16x12 / 16x6   - 12288 pixels/frame x3 buffers = 36864 bytes (18432 in 4 bpp)

//mode1 resolutions 
//00 640x360 16:9 div 2 80x45 / 80x22.5
//01 320x180 16:9 div 4 40x22.5 / 40x11.25  - 57600 pixels/frame
//10 256x144 16:9 div 5 32x18 / 32x9        - 36864 pixels/frame x3 buffers = 110592 bytes (55296 in 4bpp)
//11 160x90  16:9 div 8 20x11.25 / 20x5.625 - 14400 pixels/frame x3 buffers =  43200 bytes (21600 in 4bpp)
wire [6:0] widthMux [7:0];
assign widthMux[0] = 7'd80;
assign widthMux[1] = 7'd40;
assign widthMux[2] = 7'd20;
assign widthMux[3] = 7'd16;
assign widthMux[4] = 7'd80;
assign widthMux[5] = 7'd40;
assign widthMux[6] = 7'd32;
assign widthMux[7] = 7'd20;

wire [6:0] textWidth = 80; //widthMux[{videoMode, textResolution}];

// X/Y positions selectors


reg  [1:0] textResolution;
reg        bitmapResolution;
wire [1:0] expBitmapResolution = {1'b1, bitmapResolution};

wire [9:0] xMux [4:0];
assign xMux[0] = x;
assign xMux[1] = x2;
assign xMux[2] = x4;
assign xMux[3] = x5;
assign xMux[4] = x8;
wire [9:0] yMux [4:0];
assign yMux[0] = y;
assign yMux[1] = y2;
assign yMux[2] = y4;
assign yMux[3] = y5;
assign yMux[4] = y8;

wire [9:0] textX   = videoMode ? xMux[     textResolution+1] : xMux[     textResolution];
wire [9:0] textY   = videoMode ? yMux[     textResolution+1] : yMux[     textResolution];
wire [9:0] bitmapX = videoMode ? xMux[expBitmapResolution+1] : xMux[expBitmapResolution];
wire [9:0] bitmapY = videoMode ? yMux[expBitmapResolution+1] : yMux[expBitmapResolution];


// Video Signal and Timing


video_timing_480DMT video_VGA(
    clock25,
    pllLocked,
    DE_480,
    HSYNC_480,
    VSYNC_480,
    HPOL_480,
    VPOL_480, 
    H_DE_480,
    V_DE_480
);
video_timing_720DMT video_HD (
    clock74,
    pllLocked,
    DE_720,
    HSYNC_720,
    VSYNC_720,
    HPOL_720,
    VPOL_720, 
    H_DE_720,
    V_DE_720
);

wire DE    = videoMode ? DE_720    : DE_480;
wire HSYNC = videoMode ? HSYNC_720 : HSYNC_480;
wire VSYNC = videoMode ? VSYNC_720 : VSYNC_480;
wire HPOL  = videoMode ? HPOL_720  : HPOL_480;
wire VPOL  = videoMode ? VPOL_720  : VPOL_480;
wire H_DE  = videoMode ? H_DE_720  : H_DE_480;
wire V_DE  = videoMode ? V_DE_720  : V_DE_480;


// Video compositon


reg fontBit = 0;
wire [15:0] RGB_out = fontBit ? fontColor : (palette[bitmapColorIndex] | testColor);


// Video pipelining and output


reg SYNC_H_delay1, SYNC_H_delay2;
reg SYNC_V_delay1, SYNC_V_delay2;
reg DE_out, DE_delay1, DE_delay2, DE_delay3;

always @(posedge pixelClock) begin
    SYNC_H_out    <= SYNC_H_delay2;
    SYNC_H_delay2 <= SYNC_H_delay1;
    SYNC_H_delay1 <= HSYNC ^ HPOL; // apply sync polarity

    SYNC_V_out    <= SYNC_V_delay2;
    SYNC_V_delay2 <= SYNC_V_delay1;
    SYNC_V_delay1 <= VSYNC ^ VPOL; // apply sync polarity
    
    DE_out    <= DE_delay3;
    DE_delay3 <= DE_delay2;
    DE_delay2 <= DE_delay1;
    DE_delay1 <= DE;

    RGB_B_out <= !DE_out ? 5'd0 : RGB_out[ 4: 0]; // apply blanking
    RGB_G_out <= !DE_out ? 6'd0 : RGB_out[10: 5];
    RGB_R_out <= !DE_out ? 5'd0 : RGB_out[15:11];
end


// Test


// 1280x720 = 921600 = 1110 0001 0000 0000 0000
// 640x480 = 307200 =   100 1011 0000 0000 0000
wire [10:0] xLast = /*videoMode ? 11'd1279 :*/ 11'd639;
wire [10:0] yLast = videoMode ? /*11'd719*/ 11'd359 : 11'd479;
wire [10:0] testX = xMux[videoMode];
wire [10:0] testY = yMux[videoMode];
wire test_checker = testX[4] ^ testY[4];
wire test_grid = (testX[4:0] == 5'd15) | (testY[4:0] == 5'd15);
wire test_R = ((testX == 0) | (testX == xLast));
wire test_G = ((testY[9:0] == yLast[10:1]) | (testX[9:0] == xLast[10:1]));
wire test_B = ((testY == 0) | (testY == yLast));
wire test_RGB_underlay = 0;//test_checker & ~(test_R | test_G | test_B);
reg [15:0] testColor, RGB_delay1, RGB_delay2;

reg [23:0] vcount = 0;
always @(posedge XTAL_IN) begin
    //videoMode <= vmode; 
    //fontSize <= tsize; 
    //textResolution <= tres;
    bitmapResolution <= bres;
    led <= vcount[23];
    vcount <= vcount + 24'd1;
end
assign busy = textClearing | bitmapClearing | textScrolling;

always @(posedge pixelClock) begin
    RGB_delay1[ 4: 0] <= (test_RGB_underlay | test_R) ?  5'b11111 : 0;
    RGB_delay1[10: 5] <= (test_RGB_underlay | test_G) ? 6'b111111 : 0;
    RGB_delay1[15:11] <= (test_RGB_underlay | test_B) ?  5'b11111 : 0;

    RGB_delay2 <= RGB_delay1;
    testColor <= RGB_delay2;   
end


// CPU8 interface


reg [4:0] inputAddress = 0;
reg [7:0] inputData = 0;
reg [1:0] WRnSR = 2'b11;
reg [1:0] RDnSR = 2'b11;
reg       Busy = 0;
reg [15:0] newColor;
reg textClearing = 0;
reg [7:0] textDataIn;
reg bitmapClearing = 0;

always @(posedge XTAL_IN) begin
    WRnSR <= { WRnSR[0], WRn };
    RDnSR <= { RDnSR[0], RDn };
    inputAddress <= address;
    inputData <= data;

    if (WRnSR == 2'b01) begin
        case (inputAddress)
        5'h00: videoMode <= inputData[0];//VideoControl
        5'h01: begin //TextControl
        //	b0 Font type 8x8 / 16x8
            fontSize <= inputData[0];
        //	b1 Cursor Off / Cursor On
            cursorVisible <= inputData[1];
        //	b2 Blink Off / Blink On
            cursorBlink <= inputData[2];
        //	b3 CursorInc Off / CursorInc On
            cursorInc <= inputData[3];
        //	b4 horizontal / vertical
            cursorVertical <= inputData[4];        
        //	b5
        //	b6 Text Resolution bit0
        //	b7 Text Resolution bit1
            textResolution <= inputData[7:6];
        end
        5'h02: begin // TextCommand
            if (inputData == 8'h00) begin //	00 Clear Screen   0.19ms at 27MHz
                textClearing <= 1;
                textCounter <= 0;
                textCursor <= 0;
                textDataIn <= 0;
            end else if (inputData == 8'h01) begin //	01 Home
                textCursor <= 0;
            end else if (inputData == 8'h02) begin //	02 Scroll Screen 1 line
                textScrolling <= 1;
                textCounter <= 0;
                textCursorLast <= textWidth;
                if (textCursor >= textWidth) textCursor <= textCursor - textWidth;
            end
        end
        5'h04: begin
            textRAMwrite <= 1;
            textDataIn <= inputData;
            if (cursorInc) textCursor <= textCursor + 13'd1; 
            textCursorLast <= textCursor;
        end
        5'h05: begin
            textRAMwrite <= 1;
            textDataIn <= inputData;
            if (cursorInc) textCursor <= textCursor + 13'd1; 
            textCursorLast <= textCursor;
        end
        5'h0A: fontColor[15:8] <= inputData;
        5'h0B: fontColor[ 7:0] <= inputData;

        5'h11: begin // BitmapCommand
            if (inputData == 8'h00) begin  //	00 Clear display buffer   1.4ms at 27MHz               
                bitmapClearing <= 1;
                bitmapCounter <= 0;
                bitmapCursor <= 0;
                bitmapDataIn <= 0;
            end
        end 
//	01 Clear current buffer
//	02 Swap buffer immediate
//	03 Swap buffer next VSync
        5'h1B: newColor[15:8] <= inputData; //BitmapPaletteHigh (565)
        5'h1C: newColor[ 7:0] <= inputData; //BitmapPaletteLow
        5'h1D: palette[inputData[3:0]] <= newColor;//BitmapPaletteIndex writes will set palette colors at Index per High and Low values
        endcase
    end else if (RDnSR == 2'b00) begin
    

    end else begin

        if (textClearing) begin
            if (textCounter != 4800) textCounter <= textCounter + 13'd1; else textClearing <= 0;
        end 

        if (textScrolling) begin
            if (textCounter != 4800-80) begin
                textCounter <= textCounter + 13'd1;
                textCursorLast <= textCursorLast + 13'd1;
            end else begin
                textScrolling <= 0;
                textClearing <= 1; // clear the last line
            end
        end

        if (bitmapClearing) begin
            if (bitmapCounter != 36864) bitmapCounter <= bitmapCounter + 16'd1; else bitmapClearing <= 0;
        end

        textRAMwrite <= 0;
    end// end RD

    
end


// Text generator


reg         fontSize = 0; // 0:8x8, 1:8x16
reg  [12:0] textOutAddress; // max 4799
wire [ 7:0] textDataOut; // max 255
reg  [15:0] fontColor = 16'b1111111111111111; //16'b0111101111101111;
//reg  [ 4:0] fontBitAddress2;
reg  [ 4:0] fontBitAddress;
reg  [ 5:0] fontYadress;// = fontAddress[10:5]; // 64 column
reg  [ 6:0] fontXadress;// = {6'd0, fontAddress[13:11]}; // 304 row
wire [31:0] fontDataOut;
reg  [ 2:0] textX20;
reg  [ 3:0] textY30;

reg cursorVisible = 1;
reg cursorBlink = 1;
reg cursorInc = 1;
reg cursorVertical = 1;

reg  [12:0] textCursor;
reg  [12:0] textCursorLast;
wire [ 6:0] textCursorX = textCursor - (textCursorY * textWidth); 
wire [ 5:0] textCursorY = textCursor / textWidth;
reg  [12:0] textCounter = 4800;
reg         textRAMwrite = 0;
reg         textScrolling = 0;

//reg [0:63] font = 64'b1000100001000001101000000001000110001000000001011000001000010001;
//10001000
//01000001
//10100000
//00010001
//10001000
//00000101
//10000010
//00010001

wire carretGen = cursorVertical ? (textX20 == 3'b000) : (fontSize ? textY30 == 4'b1111 : textY30[2:0] == 3'b111);
wire carretBit = ((cursorVisible & !cursorBlink) | (cursorVisible & cursorBlink & vcount[23])) & (textOutAddress == textCursor) & carretGen;
reg  carretBit2;

// todo verify y +1 in 8x16 mode
wire [15:0] textROMaddressYselector = fontSize ? {9'd0, textY30+1, 3'd0} : {10'd0, textY30[2:0], 3'd0}; // 8:16 *8 7 bits
wire [12:0] textRAMaddressYselector = fontSize ? (textY[8:4] * 13'd80)    : (textY[8:3] * 13'd80);     // X/8 max 80, Y/8:16 max 60:30, address max 4800:2400  13bits
wire [14:0] textCharSelector        = fontSize ? {textDataOut, 7'd0}      : {textDataOut, 6'd0};       // x128 / x64   8b x 6:7b 15 bits
wire [17:0] calculatedROMAddress =  ( fontSize ? 18'h04000 : 0 ) + textCharSelector + {15'd0, textX20} + textROMaddressYselector;

always @(posedge pixelClock) begin    
    // step 1, textRAM address from screen X/Y position
    textOutAddress <= textX[9:3] + textRAMaddressYselector; // X/8 max 80, Y/8:16 max 60:30, address max 4800:2400  13bits
    textX20 <= textX[2:0];
    textY30 <= textY[3:0];

    carretBit2 <= carretBit;

    // step 2, fontROM address from textRAM char index output
    fontBitAddress <= ~calculatedROMAddress[ 4: 0]; 
    fontYadress    <=  calculatedROMAddress[10: 5];
    fontXadress    <=  calculatedROMAddress[17:11]; 
    //fontBitAddress2 <= fontBitAddress;

    // step 3, fontBit from fontROM font data output
    fontBit <= fontDataOut[fontBitAddress] ^ carretBit2; // select 1 of 32 bits
end


Gowin_SDPB_4800_8 textRAM(
    .dout(textDataOut), //output [7:0] dout
    .clka(XTAL_IN), //input clka
    .cea(textClearing | textRAMwrite | textScrolling), //input cea
    .reseta(1'b0), //input reseta
    .clkb(textScrolling ? ~XTAL_IN : romClock), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'd1), //input oce
    .ada((textClearing | textScrolling) ? textCounter : textCursorLast), //input [12:0] ada
    .din(textScrolling ? textDataOut : textDataIn), //input [7:0] din
    .adb(textScrolling ? textCursorLast : textOutAddress) //input [12:0] adb
);

//    0 - 2047  8x8 CGA Font
// 2048 - 6143 8x16 VGA Font 0000100000000000

//2047 = 0x07FF = b'0000 0111 1111 1111'
//2048 = 0x0800 = b'0000 1000 0000 0000'
//6144 = 0x1800 = b'0001 1000 0000 0000'
//6143 = 0x17FF = b'0001 0111 1111 1111 bbbb b'
//2047 = 0x07FF = b'0000 0111 1111 1111'

Gowin_User_Flash fontROM(
    .dout(fontDataOut), //output [31:0] dout
    .xe(1'b1), //input xe
    .ye(1'b1), //input ye
    .se(romClock), //input se
    .prog(1'b0), //input prog
    .erase(1'b0), //input erase
    .nvstr(1'b0), //input nvstr
    .xadr({2'd0, fontXadress}), //input [8:0] xadr
    .yadr(fontYadress), //input [5:0] yadr
    .din(32'd0) //input [31:0] din
);


// Bitmap generator


reg [15:0] palette[15:0];
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

//reg  [15:0] bitmapColor = 16'd0;
wire [ 3:0] bitmapDataOut;
reg  [15:0] bitmapAddress;
reg  [ 3:0] bitmapColorIndex;
reg  [15:0] bitmapCounter = 36864;
reg  [ 3:0] bitmapDataIn = 0;
reg  [15:0] bitmapCursor = 0;

always @(posedge pixelClock) begin    
    bitmapAddress <= {bitmapY[7:0], bitmapX[7:0]};
    bitmapColorIndex <= bitmapDataOut;
   // bitmapColor <= palette[bitmapColorIndex];
end


Gowin_SDPB_36864_4b bitmapRAM(
    .dout(bitmapDataOut), //output [3:0] dout
    .clka(1'b0/*XTAL_IN*/), //input clka // XTAL_IN only will mess up the output pipeline addressing
    .cea(bitmapClearing), //input cea
    .reseta(1'b0), //input reseta
    .clkb(romClock), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'b1), //input oce
    .ada(bitmapClearing ? bitmapCounter : bitmapCursor), //input [15:0] ada
    .din(bitmapDataIn), //input [3:0] din
    .adb(bitmapAddress) //input [15:0] adb
);

endmodule

// 330 ohm 3.3V to 0.7 VGA

// 330
// 330 = 660
// 1000 = 1330/1320
// 2200+100 = 2630/2640
// 4700+220 = 5250/5280
// 10000+220 = 10550/10560

// MSB
// 220      220
// 470      220 220   /440
// 1000     680 220 900   470 470   940   /880
// 2200     1000 680  1680/1760
// 4700     3300 220  3520/3520
// 10000    4700 2200 6900/7040




//Registers:
//00 DisplayControl (R/W)
//	b0 Aspect Ratio 4:3 (640x480) / 16:9 (1280x720)
//	b1
//	b2
//	b3	
//	b4 Busy
//	b7 
//	b5 HSync
//	b6 VSync
//01 TextControl
//	b0 Font type 8x8 / 16x8
//	b1 Cursor Off / Cursor On
//	b2 Blink Off / Blink On
//	b3 CursorInc Off / CursorInc On
//	b4 Cursor Horizontal Bar / Cursor Vertical Bar
//	b5
//	b6 Text Resolution bit0
//	b7 Text Resolution bit1
//02 TextCommand
//	00 Clear Screen
//	01 Home
//	02 Scroll Screen 1 line
//03
//04 TextData
//05 TextData (duplicated to allow 6301 Double Accumulator Store)
//06 TextCursorX
//07 TextCursorY
//08 TextCursorHigh
//09 TextCursorLow
//0A TextFontColorHigh (565)
//0B TextFontColorLow
//0C //TextBackColorHigh (565) (back is bitmap layer)
//0D //TextBackColorLow (back is bitmap layer)
//0E
//0F
//10 BitmapControl
//	b0 Single buffer / Double buffer
//	b1 Double buffer: Keep on swap / Clear on swap
//	b2
//	b3	
//	b4 Write if higher
//	b5
//	b6 Bitmap Resolution bit0
//	b7 //Bitmap Resolution bit1 (==1) (only the 2 lowest resolutions for bitmap mode)
//11 BitmapCommand
//	00 Clear display buffer
//	01 Clear current buffer
//	02 Swap buffer immediate
//	03 Swap buffer next VSync
//12 BitmapData (duplicated to allow 6301 Double Accumulator Store)
//13 BitmapData
//14 BitmapCursorX
//15 //BitmapCursorXLow (cursorX < 256)
//16 BitmapCursorY
//17 //BitmapCursorYLow (cursorY < 256)
//18 BitmapCursorHigh [23:16]
//19 BitmapCursorMid  [15: 8]
//1A BitmapCursorLow  [ 7: 0]
//1B BitmapPaletteHigh (565)
//1C BitmapPaletteLow
//1D BitmapPaletteIndex writes will set palette colors at Index per High and Low values
//1E
//1F

