module test ();

    reg tclk = 0;
    reg treset = 0;

top TOP (
     treset,
     tclk,
      clk2,
      clk4,
      clk5,
      clk8
);

initial begin
    tclk = 0;
    treset = 1;#1;
    tclk = 1;#1;
    tclk = 0;#1;
    treset = 0;#1;
    repeat (50) begin tclk <= ~tclk; #1; end

    tclk = 1;
    treset = 1;#1;
    tclk = 0;#1;
    tclk = 1;#1;
    treset = 0;#1;
    repeat (50) begin tclk <= ~tclk; #1; end

    $finish;

end

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, test);
end






endmodule