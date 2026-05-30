module top (
    input clk,
    input btn1,
    input btn2,
    output ledR,
    output ledG,
    output ledB
);

localparam WAIT_TIME = 32'd5400000;
reg [31:0] clkDiv = 0;
reg [2:0] led = 0;

always @(posedge clk) begin
    if (clkDiv == WAIT_TIME) begin
        clkDiv <= 0;
        if (btn1 == 0) led <= led + 1;
    end else clkDiv <= clkDiv + 1;
    if (btn2 == 0) led <= led + 1;
end

wire dimmer = clkDiv[4] | clkDiv[5] | clkDiv[6] | clkDiv[7];

assign ledR = ~led[0] | dimmer;
assign ledG = ~led[1] | dimmer;
assign ledB = ~led[2] | dimmer;

endmodule
