`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED line %0d expected: value, returned: 32'h%0000h", `__LINE__, signal); \
            $finish; \
        end

`define testop(Ah, Al, Bh, Bl, op) \
    DataBuffer <= Ah; \
    addressBus <= 0;\
    #5 writeBus <= 0; #5 writeBus <= 1; #5\
    DataBuffer <= Al;\
    addressBus <= 1;\
    #5 writeBus <= 0; #5 writeBus <= 1; #5\
    DataBuffer <= Bh;\
    addressBus <= 2;\
    #5 writeBus <= 0; #5 writeBus <= 1; #5\
    DataBuffer <= Bl;\
    addressBus <= 3;\
    #5 writeBus <= 0; #5 writeBus <= 1; #5\
    DataBuffer <= op; \
    addressBus <= 15; \
    #5 writeBus <= 0; #5 writeBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz;\
    #128

module test ();
reg clk = 0;
reg [7:0] DataBuffer = 8'bzzzzzzzz;
wire [7:0] dataBus;
assign dataBus = DataBuffer;
reg [2:0] addressBus = 0;
reg readBus = 1;
reg writeBus = 1;

localparam OP_sInt16_MULT = 0;
localparam OP_sInt16_DIVMOD = 1;
localparam OP_sInt16_DIVFRACT = 2;
localparam OP_sInt16_SQRT = 3;

top Int16MCP (
    clk,
    readBus,
    writeBus,
    addressBus,
    dataBus
);

always begin
    #1 clk <= ~clk;
end

initial begin
    #10
    DataBuffer <= 8'hAA;
    addressBus <= 0; // ah
    #5 writeBus <= 0; #5 writeBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz; // write register
    `assert(Int16MCP.A, 16'hAA00);

    #10
    DataBuffer <= 8'hAA;
    addressBus <= 1; // al
    #5 writeBus <= 0; #5 writeBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz; // write register
    `assert(Int16MCP.A, 16'hAAAA);

    #10
    DataBuffer <= 8'h55;
    addressBus <= 2; // bh
    #5 writeBus <= 0; #5 writeBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz; // write register
    `assert(Int16MCP.B, 16'h5500);
/*
    #10
    DataBuffer <= 8'h00; // add
    addressBus <= 15; // operation
    #5 writeBus <= 0; #5 writeBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz; // write register
    `assert(Int16MCP.X, 32'hFFAA0000);
*/
/*
    #10
    addressBus <= 0; // Xh
    #5 readBus <= 0; #5// read register
    `assert(dataBus, 8'hFF);
    #5 readBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz;

    addressBus <= 1; // Xl
    #5 readBus <= 0; #5// read register
    `assert(dataBus, 8'hAA);
    #5 readBus <= 1; #5 DataBuffer <=  8'bzzzzzzzz;
*/
    // 7FFF x 7FFF = 3FFF 0001
    `testop(8'h7F, 8'hFF, 8'h7F, 8'hFF, OP_sInt16_MULT);
    `assert(Int16MCP.X, 32'h3FFF0001);

    // 1 * -1 = -1
    // 0001 x FFFF = FFFF FFFF
    `testop(8'h00, 8'h01, 8'hFF, 8'hFF, OP_sInt16_MULT);
    `assert(Int16MCP.X, 32'hFFFFFFFF);

    // -16 * -1 = 16
    // FFF0 x FFFF = 0000 0010
    `testop(8'hFF, 8'hF0, 8'hFF, 8'hFF, OP_sInt16_MULT);
    `assert(Int16MCP.X, 32'h00000010);
/*
    // FFFF + FFFF = FFFE
    // -1 + -1 = -2
    `testop(8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00);// TODO flag
    `assert(Int16MCP.X, 32'hFFFE0010);

    // 7FFF + 7FFF = FFFE
    // 32767 + 32767 = -2
    `testop(8'h7F, 8'hFF, 8'h7F, 8'hFF, 8'h00); // TODO flag
    `assert(Int16MCP.X, 32'hFFFE0010);
*/
    // 7FFF / 7FFF = 0001 0000
    // 32767 / 32767 = 1
    `testop(8'h7F, 8'hFF, 8'h7F, 8'hFF, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'h00010000);

    // 3 / 2 = 1 reste 1
    // 0003 / 0002 = 0001 0001
    `testop(8'h00, 8'h03, 8'h00, 8'h02, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'h00010001);

    // 1 / 3 = 0 reste 1
    // 0001 0003 = 0000 0003
    `testop(8'h00, 8'h01, 8'h00, 8'h03, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'h00000001);

    // 7FFE / 7FFF = 0000 7FFE
    `testop(8'h7F, 8'hFE, 8'h7F, 8'hFF, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'h00007FFE);

    // -16 / 4 = -4 reste 0
    // FFF0 / 0004 = FFFC 0000
    `testop(8'hFF, 8'hF0, 8'h00, 8'h04, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'hFFFC0000);
    
    // -4 / 4 = -1 reste 0
    // FFFC / 0004 = FFFF 0000
    `testop(8'hFF, 8'hFC, 8'h00, 8'h04, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'hFFFF0000);

    // -16 / 3 = -5 reste -1
    // FFF0 / 0003 = FFFB FFFF
    `testop(8'hFF, 8'hF0, 8'h00, 8'h03, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'hFFFBFFFF);

    // -768 / -256 = 3 reste 0
    // FD00 / FF00 = 0003 0000
    `testop(8'hFD, 8'h00, 8'hFF, 8'h00, OP_sInt16_DIVMOD);
    `assert(Int16MCP.X, 32'h00030000);

    // 3 // 2 = 1.5 op 4 divFract
    // 0003 / 0002 = 0001 0001
    `testop(8'h00, 8'h03, 8'h00, 8'h02, OP_sInt16_DIVFRACT);
    `assert(Int16MCP.X, 32'h00018000);

    `testop(8'h7F, 8'hFF, 8'h00, 8'h01, OP_sInt16_DIVFRACT);
    `assert(Int16MCP.X, 32'h7FFF0000);

    `testop(8'h7F, 8'hFF, 8'h00, 8'h03, OP_sInt16_DIVFRACT);
    `assert(Int16MCP.X, 32'h2AAA5555);

    // 1 // 4 = 0.25 op 4 divFract
    // 0003 / 0002 = 0001 0001
    `testop(8'h00, 8'h01, 8'h00, 8'h04, OP_sInt16_DIVFRACT);
    `assert(Int16MCP.X, 32'h00004000);

    // 10 // 3 = 3.33333334
    `testop(8'h00, 8'h0A, 8'h00, 8'h03, OP_sInt16_DIVFRACT);
    `assert(Int16MCP.X, 32'h00035555);

    // SQRT(4) = 2
    `testop(8'h00, 8'h04, 8'h00, 8'h00, OP_sInt16_SQRT);
    `assert(Int16MCP.X, 32'h00020000);

    // SQRT(100) = 10
    `testop(8'h00, 8'h64, 8'h00, 8'h00, OP_sInt16_SQRT);
    `assert(Int16MCP.X, 32'h000A0000);

    // SQRT(2) = 1.4142  0x01.6A 09
    `testop(8'h00, 8'h02, 8'h00, 8'h00, OP_sInt16_SQRT);
    `assert(Int16MCP.X, 32'h00016A00);

    // SQRT(32767) = 181.016  0xB5.04
    `testop(8'h7F, 8'hFF, 8'h00, 8'h00, OP_sInt16_SQRT);
    `assert(Int16MCP.X, 32'h00B50400);

    $finish;

end

initial begin
    $dumpfile("HBC_MCPv1.vcd");
    $dumpvars(0, test);
end

endmodule