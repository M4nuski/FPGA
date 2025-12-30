// LED flasher demo

module top
(
    input clk,
    output [5:0] led,
    input btn1
);

localparam WAIT_TIME = 10000000;
reg [5:0] ledCounter = 6'b1;
reg [23:0] clockCounter = 0;
reg dir = 0;

always @(posedge clk) begin
    clockCounter <= clockCounter + 1;
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 0;
        case (dir) 
        0: begin
            ledCounter <= ledCounter + 1;
        end 
        1: begin 
           // ledCounter <= ledCounter - 1;
            ledCounter <= {ledCounter[4:0], ledCounter[5]};
        end
        endcase
        if (btn1 == 0) dir <= ~dir;
    end
end

assign led = ~ledCounter;
endmodule