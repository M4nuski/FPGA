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

    // VGA
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
    input mode // default VGA, push btn 1 for HD
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
wire videoClock = videoMode ? clock74 : clock25;

wire clk1 = clock25;
reg clk2, clk4, clk5, clk8; // Divided pixel clocks

reg clk4_count = 0;
reg [2:0] clk5_count = 0;
reg [1:0] clk8_count = 0;

always @(posedge videoClock or posedge VSYNC) begin
    if (VSYNC) begin
    clk2 <= 0;
    clk4 <= 0;
    clk4_count <= 1;
    clk5 <= 0;
    clk5_count <= 3'd2;
    clk8 <= 0;
    clk8_count <= 2'd3;
    end else if (DE) begin

        clk2 <= ~clk2;

        if (clk4_count == 1) begin
            clk4 <= ~clk4;
            clk4_count <= 0;
        end else clk4_count <= 1;

        if (clk5_count == 3'd4) begin
            clk5 <= 0;
            clk5_count <= 0;
        end else begin
            if (clk5_count == 3'd2)  clk5 <= 1;
            clk5_count <= clk5_count + 3'd1;
        end
     
        if (clk8_count == 2'd3) begin
            clk8 <= ~clk8;
            clk8_count <= 0;
        end else clk8_count <= clk8_count + 2'd1;
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

wire [4:0] clockTree = {clk8, clk5, clk4, clk2, clk1};

reg  [1:0] textResolution = 2'b0;
reg        bitmapResolution = 0;
wire [1:0] expBitmapResolution = {1'b1, bitmapResolution};

wire textPixelClock   = videoMode ? clockTree[     textResolution+1] : clockTree[     textResolution];
wire bitmapPixelClock = videoMode ? clockTree[expBitmapResolution+1] : clockTree[expBitmapResolution];


// Video Timing


video_timing_480DMT video_VGA(
    clock25,
    pllLocked,
    DE_480,
    HSYNC_480,
    VSYNC_480
);
video_timing_720DMT video_HD (
    clock74,
    pllLocked,
    DE_720,
    HSYNC_720,
    VSYNC_720
);

wire DE = videoMode ? DE_720 : DE_480;
wire HSYNC = videoMode ? HSYNC_720 : HSYNC_480;
wire VSYNC = videoMode ? VSYNC_720 : VSYNC_480;


// Video pipeline and compositon


reg fontBit = 0;
wire [15:0] RGB_out = fontBit ? fontColor : bitmapColor;

reg SYNC_H_delay1, SYNC_H_delay2;
reg SYNC_V_delay1, SYNC_V_delay2;
reg DE_out, DE_delay1, DE_delay2;

always @(posedge videoClock) begin
    SYNC_H_out    <= SYNC_H_delay2;
    SYNC_H_delay2 <= SYNC_H_delay1;
    SYNC_H_delay1 <= HSYNC;

    SYNC_V_out    <= SYNC_V_delay2;
    SYNC_V_delay2 <= SYNC_V_delay1;
    SYNC_V_delay1 <= VSYNC;

    DE_out    <= DE_delay2;
    DE_delay2 <= DE_delay1;
    DE_delay1 <= DE;

    RGB_R_out <= DE_out ? RGB_out[ 4: 0] : 5'd0;
    RGB_G_out <= DE_out ? RGB_out[10: 5] : 6'd0;
    RGB_B_out <= DE_out ? RGB_out[15:11] : 5'd0;

end


// Test

// 1280x720 = 921600 = 1110 0001 0000 0000 0000
// 640x480 = 307200 =   100 1011 0000 0000 0000
reg [19:0] pixel;
reg [10:0] column;
reg [10:0] row;

wire [10:0] columnLast = videoMode ? 11'd1279 : 11'd639;
wire [10:0] rowLast = videoMode ? 11'd719 : 11'd479;

wire test_checker = column[4] ^ row[4];
wire test_R = ((column == 0) | (column == columnLast));
wire test_G = ((row[9:0] == rowLast[10:1]) | (column[9:0] == columnLast[10:1]));
wire test_B = ((row == 0) | (row == rowLast));
wire test_RGB_underlay = test_checker & ~(test_R | test_G | test_B);
reg [15:0] RGB_delay1, RGB_delay2;

reg [23:0] vcount = 0;
always @(posedge XTAL_IN) begin
    videoMode <= ~mode; 
    led <= vcount[23];
    vcount <= vcount + 24'd1;
end

always @(posedge videoClock) begin
    if (~VSYNC) begin
        pixel <= 0;
        column <= 0;
        row <= 0;
   // end else if (~DE) begin
       // RGB_delay1 <= 16'd0;
    end else if (DE) begin

        pixel <= pixel + 20'b1;

        RGB_delay1[ 4: 0] <= (test_RGB_underlay | test_R) ?  5'b11111 : 0;
        RGB_delay1[10: 5] <= (test_RGB_underlay | test_G) ? 6'b111111 : 0;
        RGB_delay1[15:11] <= (test_RGB_underlay | test_B) ?  5'b11111 : 0;
          
        if (column == columnLast) begin
            column <= 0;
            row <= row + 11'd1;
        end else begin
            column <= column + 11'd1;
            row <= row;
        end
    end

    RGB_delay2 <= RGB_delay1;
    bitmapColor <= RGB_delay2;   
end


// CPU8 interface


// Text generator
reg fontMode = 0; // 8x8, 1:8x16
reg [15:0] fontColor = 16'b0111101111101111;

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

// Bitmap mode

reg [15:0] bitmapColor = 16'd0;
//BitmapColor <= palette[colorIndex]
//colorIndex <= bitmapRAM[pixelOffset] // ram fetch from address on clock up, inverting clock to fetch between latches
// pixelOffset <= pixel // pixel updated on clock up

endmodule