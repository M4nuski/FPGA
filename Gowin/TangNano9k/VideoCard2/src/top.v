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
    input tsize // text size
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

//Gowin_CLKDIV2 div_74_37(
//    .clkout(clock37), //output clkout
//    .hclkin(clock74), //input hclkin
//    .resetn(lock74) //input resetn
//);

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
reg V_DEdelay;
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
always @(posedge videoClock) begin
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

    end else if (H_DE) begin

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


// X/Y positions selectors


reg  [1:0] textResolution;//  = tres;//2'b0;
reg        bitmapResolution;// = bres;
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
wire [15:0] RGB_out = fontBit ? fontColor : (bitmapColor | testColor);


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
    
    DE_out    <= DE_delay2;
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
    videoMode <= vmode; 
    fontSize <= tsize; 
    textResolution <= tres;
    bitmapResolution <= bres;
    led <= vcount[23];
    vcount <= vcount + 24'd1;
end

always @(posedge pixelClock) begin
    RGB_delay1[ 4: 0] <= (test_RGB_underlay | test_R) ?  5'b11111 : 0;
    RGB_delay1[10: 5] <= (test_RGB_underlay | test_G) ? 6'b111111 : 0;
    RGB_delay1[15:11] <= (test_RGB_underlay | test_B) ?  5'b11111 : 0;

    RGB_delay2 <= RGB_delay1;
    testColor <= RGB_delay2;   
end


// CPU8 interface


// Text generator


reg fontSize = 0; // 8x8, 1:8x16
reg  [12:0] textOutAddress;
wire [ 7:0] textDataOut; // max 255
reg  [15:0] fontColor = 16'b1111111111111111; //16'b0111101111101111;
reg  [ 4:0] fontBitAddress2;
reg  [ 4:0] fontBitAddress;
reg  [ 5:0] fontYadress;// = fontAddress[10:5]; // 64 column
reg  [ 6:0] fontXadress;// = {6'd0, fontAddress[13:11]}; // 304 row
wire [31:0] fontDataOut;
reg  [ 2:0] textX20;

// 8x8 / 8x16
// cursorX cursorY cursor 

reg [0:63] font = 64'b1000100001000001101000000001000110001000000001011000001000010001;
//10001000
//01000001
//10100000
//00010001
//10001000
//00000101
//10000010
//00010001

wire [15:0] textROMaddressYselector = fontSize ? {9'd0, textY[3:0], 3'd0} : {10'd0, textY[2:0], 3'd0}; // 8:16 *8 7 bits
wire [12:0] textRAMaddressYselector = fontSize ? (textY[8:4] * 13'd80)    : (textY[8:3] * 13'd80);     // X/8 max 80, Y/8:16 max 60:30, address max 4800:2400  13bits
wire [14:0] textCharSelector        = fontSize ? {textDataOut, 7'd0}      : {textDataOut, 6'd0};       // x128 / x64   8b x 6:7b 15 bits
wire [17:0] calculatedROMAddress =  ( fontSize ? 18'h04000 : 0 ) + textCharSelector + {15'd0, textX20} + textROMaddressYselector;

always @(posedge pixelClock) begin    
    // step 1, textRAM address from screen X/Y position
    textOutAddress <= textX[9:3] + textRAMaddressYselector; // X/8 max 80, Y/8:16 max 60:30, address max 4800:2400  13bits
    textX20 <= textX[2:0];


    // step 2, fontROM address from textRAM char index output
    //fontAddress <= calculatedROMAddress;   
    fontBitAddress <= ~calculatedROMAddress[ 4: 0]; 
    fontYadress    <=  calculatedROMAddress[10: 5];
    fontXadress    <=  calculatedROMAddress[17:11]; 
    fontBitAddress2 <= fontBitAddress;

    // step 3, fontBit from fontROM font data output
    fontBit <= fontDataOut[fontBitAddress2]; // select 1 of 32 bits
end


Gowin_SDPB_4800_8 textRAM(
    .dout(textDataOut), //output [7:0] dout
    .clka(1'b0), //input clka
    .cea(1'b0), //input cea
    .reseta(1'b0), //input reseta
    .clkb(romClock), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'd1), //input oce
    .ada(13'd0), //input [12:0] ada
    .din(8'd0), //input [7:0] din
    .adb(textOutAddress) //input [12:0] adb
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
    .xadr({1'd0, fontXadress}), //input [8:0] xadr
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

reg  [15:0] bitmapColor = 16'd0;
wire [ 3:0] bitmapDataOut;
reg  [15:0] bitmapAddress;
reg  [ 3:0] bitmapColorIndex;

always @(posedge pixelClock) begin    
    bitmapAddress <= {bitmapY[7:0], bitmapX[7:0]};
    bitmapColorIndex <= bitmapDataOut;
    bitmapColor <= palette[bitmapColorIndex];
end


Gowin_SDPB_36864_4 bitmapRAM(
    .dout(bitmapDataOut), //output [3:0] dout
    .clka(1'b0), //input clka
    .cea(1'b0), //input cea
    .reseta(1'b0), //input reseta
    .clkb(romClock), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(1'b0), //input resetb
    .oce(1'b1), //input oce
    .ada(16'd0), //input [15:0] ada
    .din(4'd0), //input [3:0] din
    .adb(bitmapAddress) //input [15:0] adb
);

endmodule