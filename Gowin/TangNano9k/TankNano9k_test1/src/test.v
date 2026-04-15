module top (
    input clk,
    input btn1,
    input btn2,
    output reg led1
);

reg [23:0] counter;

always @(posedge clk) begin
    if (counter == 0) begin
        led1 <= btn1 ^ btn2;
        counter <= 10000000;
    end else counter <= counter + 24'b1;
end

endmodule