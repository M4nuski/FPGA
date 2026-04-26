module test ();
    reg clk = 0;
    wire outClk;
    reg miso = 0;
    wire mosi;

    wire chipSel;
    wire dataCommand;
    wire reset;

top #(32) moduleToTest(
    clk,
    outClk,
    miso,
    mosi,
    chipSel,
    dataCommand,
    reset
);

initial begin
    #1024

    $finish;
end

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, test);
end

always begin
    #1 clk <= ~clk;
end






endmodule