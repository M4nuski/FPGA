module test ();
    reg clk = 0;
    wire outClk;
    reg miso = 0;
    wire mosi;

    reg MOSI_dataAvailable;
    wire MOSI_readyToRead;
    reg [7:0] MOSI_data;

    wire MISO_dataAvailable; // when 1 and clock posedge read the content of MISO_data
    reg MISO_readyToRead; // set to 1 to initiate read
    wire [7:0] MISO_data;

SPI spi (
    clk, outClk,
    miso, mosi,

    MOSI_dataAvailable,
    MOSI_readyToRead,
    MOSI_data,

    MISO_dataAvailable, 
    MISO_readyToRead, 
    MISO_data
);

initial begin
    MISO_readyToRead = 0;
    #10
    MOSI_data = 8'hAA;
    MOSI_dataAvailable = 1;
    #4
    MOSI_dataAvailable = 0;
    #64
    MOSI_data = 8'hBE;
    MOSI_dataAvailable = 1;
    #4
    MOSI_dataAvailable = 0;
    #64

    MISO_readyToRead = 1;
     #4
    MISO_readyToRead = 0;
    miso = 1; #4
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
    #10
    MISO_readyToRead = 1;
     #2
    MISO_readyToRead = 0;
      #2
    MISO_readyToRead = 1;
     #2
    MISO_readyToRead = 0;
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
    miso = 1; #4
    miso = 0; #4
        miso = 1; #4
     #96



    $finish;
end

initial begin
    $dumpfile("SPI_tb.vcd");
    $dumpvars(0, test);
end

always begin
    #1 clk <= ~clk;
end






endmodule