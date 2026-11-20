// 16 bit port counter with clock prescaler

module top
(
    input clk,
    output reg [15:0] port = 0
);

localparam WAIT_TIME = 1;

//reg [15:0] portCounter = 16'b1;
reg [23:0] clockCounter = 0;

//assign port = portCounter;

always @(posedge clk) begin
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 1;
        port <= port + 1; 
    end else clockCounter <= clockCounter + 1;
end

endmodule