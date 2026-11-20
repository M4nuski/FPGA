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
wire clockSource = videoMode ? clock74 : clock25;

wire clk1 = clock25;
reg clk2, clk4, clk5, clk8; // Divided pixel clocks

reg clk4_count = 0;
reg [2:0] clk5_count = 0;
reg [1:0] clk8_count = 0;

always @(posedge clockSource or posedge VSYNC) begin
    if (VSYNC) begin
    clk2 <= 0;
    clk4 <= 0;
    clk4_count <= 1;
    clk5 <= 0;
    clk5_count <= 3'd2;
    clk8 <= 0;
    clk8_count <= 2'd3;
    end else begin

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


reg SYNC_H_reg1, SYNC_H_reg2;
reg SYNC_V_reg1, SYNC_V_reg2;

reg [4:0] RGB_R, RGB_R_reg1, RGB_R_reg2;
reg [5:0] RGB_G, RGB_G_reg1, RGB_G_reg2;
reg [4:0] RGB_B, RGB_B_reg1, RGB_B_reg2;

always @(posedge clockSource) begin
    SYNC_H_out  <= SYNC_H_reg2;
    SYNC_H_reg2 <= SYNC_H_reg1;
    SYNC_H_reg1 <= HSYNC;

    SYNC_V_out  <= SYNC_V_reg2;
    SYNC_V_reg2 <= SYNC_V_reg1;
    SYNC_V_reg1 <= VSYNC;

    RGB_R_out <= RGB_R_reg2;
    RGB_G_out <= RGB_G_reg2;
    RGB_B_out <= RGB_B_reg2;

    RGB_R_reg2 <= RGB_R_reg1;
    RGB_G_reg2 <= RGB_G_reg1;
    RGB_B_reg2 <= RGB_B_reg1;

    RGB_R_reg1 <= RGB_R;
    RGB_G_reg1 <= RGB_G;
    RGB_B_reg1 <= RGB_B;
end


// Test


// 307200 100 1011 0000 0000 0000
reg [19:0] pixel;
reg [10:0] column;
reg [10:0] row;

wire [10:0] columnLast = videoMode ? 11'd1279 : 11'd639;
wire [10:0] rowLast = videoMode ? 11'd719 : 11'd479;
wire testclock = clockSource; // videoMode ? clk2 : clk1;
wire testchecker = column[4] ^ row[4];
wire test_R = ((column == 0) | (column == columnLast));
wire test_G = ((row[9:0] == rowLast[10:1]) | (column[9:0] == columnLast[10:1]));
wire test_B = ((row == 0) | (row == rowLast));
wire test_RGB_underlay = testchecker & ~(test_R | test_G | test_B);

reg [23:0] vcount = 0;
always @(posedge XTAL_IN) begin
    videoMode <= ~mode; 
    led <= vcount[23];
    vcount <= vcount + 24'd1;
end



always @(posedge testclock or negedge VSYNC) begin
    if (~VSYNC) begin
        pixel <= 0;
        //RGB_R <= 5'b0;
        //RGB_G <= 6'b0;
        //RGB_B <= 5'b0;
        column <= 0;
        row <= 0;
    end else if (~DE) begin
        RGB_R <= 5'b0;
        RGB_G <= 6'b0;
        RGB_B <= 5'b0;
    end else begin
        pixel <= pixel + 20'b1;

        RGB_R <= (test_RGB_underlay | test_R) ?  5'b11111 : 0;
        RGB_G <= (test_RGB_underlay | test_G) ? 6'b111111 : 0;
        RGB_B <= (test_RGB_underlay | test_B) ?  5'b11111 : 0;
          
        if (column == columnLast) begin
            column <= 0;
            row <= row + 11'd1;
        end else begin
            column <= column + 11'd1;
            row <= row;
        end
    end

end

// CPU8 interface


// Text mode


// Bitmap mode



endmodule