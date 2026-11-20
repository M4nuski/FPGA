module top (
    input clk27,
    output O_tmds_clk_p,
    output O_tmds_clk_n,
    output [2:0] O_tmds_data_p,
    output [2:0] O_tmds_data_n
);

reg reset_r = 0;
reg [7:0] resetCount = 8'd0;

always @(posedge clk27) if (resetCount != 8'd255) reset_r <= 1; else resetCount <= resetCount + 8'd1;

Gowin_rPLL_27_126 clock_mult( // 27 to 125.9
    .clkout(clk126), //output clkout
    .clkin(clk27) //input clkin
);

Gowin_CLKDIV_5 clock_div( // 125.9 to 25.175
    .clkout(clk25), //output clkout
    .hclkin(clk126), //input hclkin
    .resetn(reset_r) //input resetn
);

wire [9:0] video_col, video_line;
wire [7:0] video_r, video_g, video_b;

video_timing video(
    .PixelClk(~clk25),
    .Resetn(reset_r),
    .DE(video_de),
    .HSYNC(video_hs),
    .VSYNC(video_vs),
    .Pixel(video_col),
    .Line(video_line)
);

DVI_TX_Top dvi(
    .I_rst_n(reset_r), //input I_rst_n
    .I_serial_clk(clk126), //input I_serial_clk
    .I_rgb_clk(clk25), //input I_rgb_clk
    .I_rgb_vs(video_vs), //input I_rgb_vs
    .I_rgb_hs(video_hs), //input I_rgb_hs
    .I_rgb_de(video_de), //input I_rgb_de
    .I_rgb_r(video_r), //input [7:0] I_rgb_r
    .I_rgb_g(video_g), //input [7:0] I_rgb_g
    .I_rgb_b(video_b), //input [7:0] I_rgb_b
    .O_tmds_clk_p(O_tmds_clk_p), //output O_tmds_clk_p
    .O_tmds_clk_n(O_tmds_clk_n), //output O_tmds_clk_n
    .O_tmds_data_p(O_tmds_data_p), //output [2:0] O_tmds_data_p
    .O_tmds_data_n(O_tmds_data_n) //output [2:0] O_tmds_data_n
);

// test pattern
assign video_r = video_de & (((video_col  == 0  ) | (video_col  == 639)) ? 8'hFF : 8'h00);
assign video_g = video_de & (((video_line == 0  ) | (video_line == 479)) ? 8'hFF : 8'h00);
assign video_b = video_de & (((video_col  == 320) | (video_line == 240)) ? 8'hFF : 8'h00);

endmodule