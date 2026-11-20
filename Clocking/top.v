module top (
    input reset,
    input clk,
    output reg clk2,
    output reg clk4,
    output reg clk5,
    output reg clk8
);

reg clk4_count = 0;
reg [2:0] clk5_count = 0;
reg [1:0] clk8_count = 0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
    clk2 <= 0;
    clk4 <= 0;
    clk4_count <= 1;
    clk5 <= 0;
    clk5_count <= 2;
    clk8 <= 0;
    clk8_count <= 3;
    end else begin

        clk2 <= ~clk2;

        if (clk4_count == 1) begin
            clk4 <= ~clk4;
            clk4_count <= 0;
        end else clk4_count <= 1;

        if (clk5_count == 4) begin
            clk5 <= 0;
            clk5_count <= 0;
        end else begin
            if (clk5_count == 2)  clk5 <= 1;
            clk5_count <= clk5_count + 1;
        end
     
        if (clk8_count == 3) begin
            clk8 <= ~clk8;
            clk8_count <=0;
        end else clk8_count <= clk8_count + 1;
    end
end

endmodule