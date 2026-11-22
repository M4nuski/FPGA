`default_nettype wire

// Hybrid mode video card 
// VGA 640x480 / HD 1280x720

// CPU8 interface

// 3 stage pipeline

// Text Mode
// Bitmap Mode

module top
(
    // clock
    input XTAL_IN, // 27Mhz

    // VGA with RGB565 colors
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
    input mode, // default VGA, push btn 1 for HD
    input res
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

reg clock37 = 0;
always @(posedge clock74) clock37 <= ~clock37;

wire videoClock = videoMode ? clock74 : clock25;
wire pixelClock = videoMode ? clock37 : clock25;
wire romClock = videoMode ? ~pixelClock : pixelClock;
// Clock and X/Y dividers 

//wire clk1 = videoClock;


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


// Clocks and X/Y positions selectors


wire  [1:0] textResolution = {1'b0, ~res};//2'b0;
reg        bitmapResolution = 0;
wire [1:0] expBitmapResolution = {1'b1, bitmapResolution};

wire [9:0] xTree [4:0];
assign xTree[0] = x;
assign xTree[1] = x2;
assign xTree[2] = x4;
assign xTree[3] = x5;
assign xTree[4] = x8;
wire [9:0] yTree [4:0];
assign yTree[0] = y;
assign yTree[1] = y2;
assign yTree[2] = y4;
assign yTree[3] = y5;
assign yTree[4] = y8;

wire [9:0] textX   = videoMode ? xTree[     textResolution+1] : xTree[     textResolution];
wire [9:0] textY   = videoMode ? yTree[     textResolution+1] : yTree[     textResolution];
wire [9:0] bitmapX = videoMode ? xTree[expBitmapResolution+1] : xTree[expBitmapResolution];
wire [9:0] bitmapY = videoMode ? yTree[expBitmapResolution+1] : yTree[expBitmapResolution];


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
wire [15:0] RGB_out = fontBit ? fontColor : bitmapColor;
wire [10:0] xLast = videoMode ? 11'd1279 : 11'd639;
wire [10:0] yLast = videoMode ? 11'd719 : 11'd479;


// Video pipelining


reg SYNC_H_delay1, SYNC_H_delay2;
reg SYNC_V_delay1, SYNC_V_delay2;
reg DE_out, DE_delay1, DE_delay2, DE_delay3;

//reg fP1, lP1, fP2, lP2;

always @(posedge pixelClock) begin
    SYNC_H_out    <= SYNC_H_delay2;
    SYNC_H_delay2 <= SYNC_H_delay1;
    SYNC_H_delay1 <= HSYNC ^ HPOL; // apply sync polarity

    SYNC_V_out    <= SYNC_V_delay2;
    SYNC_V_delay2 <= SYNC_V_delay1;
    SYNC_V_delay1 <= VSYNC ^ VPOL; // apply sync polarity
    
    DE_out    <= DE_delay2;
   // DE_delay3 <= DE_delay2;
    DE_delay2 <= DE_delay1;
    DE_delay1 <= DE;

//    RGB_R_out <= DE_out ? RGB_out[ 4: 0] : 5'd0; // apply blanking
//    RGB_G_out <= DE_out ? RGB_out[10: 5] : 6'd0;
//    RGB_B_out <= DE_out ? RGB_out[15:11] : 5'd0;
    RGB_B_out <= !DE_out ? 5'd0 : RGB_out[ 4: 0];
    RGB_G_out <= !DE_out ? 6'd0 : RGB_out[10: 5];
    RGB_R_out <= !DE_out ? 5'd0 : RGB_out[15:11];

//    
//    lP2 <= lP1;
//    lP1 <= lastPixel;
//    fP2 <= fP1;
//    fP1 <= firstPixel;
end


// Test


// 1280x720 = 921600 = 1110 0001 0000 0000 0000
// 640x480 = 307200 =   100 1011 0000 0000 0000

wire test_checker = x[4] ^ y[4];
wire test_grid = (x[4:0] == 5'd15) | (y[4:0] == 5'd15);
wire test_R = ((x == 0) | (x == xLast));
wire test_G = ((y[9:0] == yLast[10:1]) | (x[9:0] == xLast[10:1]));
wire test_B = ((y == 0) | (y == yLast));
wire test_RGB_underlay = 0;//test_checker & ~(test_R | test_G | test_B);
reg [15:0] RGB_delay1, RGB_delay2;

reg [23:0] vcount = 0;
always @(posedge XTAL_IN) begin
    videoMode <= ~mode; 
    led <= vcount[23];
    vcount <= vcount + 24'd1;
end

always @(posedge pixelClock) begin
    RGB_delay1[ 4: 0] <= (test_RGB_underlay | test_R) ?  5'b11111 : 0;
    RGB_delay1[10: 5] <= (test_RGB_underlay | test_G) ? 6'b111111 : 0;
    RGB_delay1[15:11] <= (test_RGB_underlay | test_B) ?  5'b11111 : 0;

    RGB_delay2 <= RGB_delay1;
    bitmapColor <= RGB_delay2;   
end


// CPU8 interface


// Text generator
reg fontMode = 0; // 8x8, 1:8x16
reg [7:0] charIndex;
reg [15:0] fontColor = 16'b1111111111111111; //16'b0111101111101111;
reg [13:0] fontAddress;
reg [4:0] fontBitAddress;
wire [31:0] fontDataOut;
//reg fontBit = fontDataOut[~fontAddress[4:0]]; // select 1 of 32 bits
// 8x8 / 8x16
// cursorX cursorY cursor 
// font ROM
// char RAM
// 
// RGB_x_out <= FontBit ? FontColor : BitmapColor
// FontBit <= fontROM[char][fontOffset]
// wire fontOffset 
// char <= charRAM[textOffset] 
// textOffset <= pixel[19:3]??
reg [0:63] font = 64'b1000100001000001101000000001000110001000000001011000001000010001;
//10001000
//01000001
//10100000
//00010001
//10001000
//00000101
//10000010
//00010001
wire [13:0] calculatedAddress = {charIndex, 6'd0} + {11'd0, textX[2:0]} + {8'd0, textY[2:0], 3'd0};
//reg bitDelay3, bitDelay2, bitDelay1;
always @(posedge pixelClock) begin    
    charIndex <= textX[9:3] + (textY[6:3]*8'd80);
    fontAddress <= calculatedAddress;
    fontBitAddress <= ~fontAddress[4:0];
    fontBit <= fontDataOut[fontBitAddress]; // select 1 of 32 bits
   // fontBit <= bitDelay1;
end

// font ROM address calculations
wire [5:0] fontYadr = fontAddress[10:5]; // 64 column
wire [8:0] fontXadr = {6'd0, fontAddress[13:11]}; // 304 row

Gowin_User_Flash fontROM(
    .dout(fontDataOut), //output [31:0] dout
    .xe(1'b1), //input xe
    .ye(1'b1), //input ye
    .se(romClock), //input se
    .prog(1'b0), //input prog
    .erase(1'b0), //input erase
    .nvstr(1'b0), //input nvstr
    .xadr(fontXadr), //input [8:0] xadr
    .yadr(fontYadr), //input [5:0] yadr
    .din(32'd0) //input [31:0] din
);

// Bitmap mode

reg [15:0] bitmapColor = 16'd0;
//BitmapColor <= palette[colorIndex]
//colorIndex <= bitmapRAM[pixelOffset] // ram fetch from address on clock up, inverting clock to fetch between latches
// pixelOffset <= pixel // pixel updated on clock up

endmodule