module test ();
    reg tclk = 0;
    reg treset = 0;
    wire [15:0] port;

top testTop (
    tclk,
    port
);



initial begin
    treset = 1;
    #1;
    treset = 0;
    #1;
    repeat (256) #1 tclk <= ~tclk;


    $finish;

end

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, test);
end

 


endmodule
