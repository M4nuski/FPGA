module top (
    output CLKdiv2,
    output reg CLKdiv2div1000 = 0,

    output CLK27,
    output reg CLK27div1000 = 0
);

reg[9:0] clk_div_count = 10'd0;
reg[9:0] clk27_div_count = 10'd0;

Gowin_OSC OSC( // 250MHz / 2 = 125MHz
    .oscout(internal_osc), //output oscout
    .oscen(1'b1) //input oscen
);

Gowin_PLLVR PLL( // 27MHz
    .clkout(clkout27), //output clkout
    .clkin(internal_osc) //input clkin
);

assign CLK27 = clkout27;
assign CLKdiv2 = internal_osc;

always @(posedge internal_osc) begin
    if (clk_div_count == 10'd0) begin
        clk_div_count <= 10'd498;
        CLKdiv2div1000 <= !CLKdiv2div1000;
    end else clk_div_count <= clk_div_count - 10'd1;
end

always @(posedge clkout27) begin
    if (clk27_div_count == 10'd0) begin
        clk27_div_count <= 10'd498;
        CLK27div1000 <= !CLK27div1000;
    end else clk27_div_count <= clk27_div_count - 10'd1;
end


endmodule