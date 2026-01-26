// Math Co-Processor for 8 bit homebrew test module
// 8 bit parallel interface
// M4nusky JAN-2026

// v0 interface test
// Q = A * B

// Address map
// on write
//  0: Ah (D.A)
//  1: Al (D.B)
//  2: Bh (D.A)
//  3: Bl (D.B)
//      
// on read
//  0: Xh (Q.A) Mul MSB
//  1: Xl (Q.B)         
//  2: Yh (Q.C)         
//  3: Yl (Q.D) Mul LSB

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top (
    input clk,
    input WRn,
    input RDn,
    input [2:0] address,
    inout wire [7:0] data
);

// interface
reg [7:0] dataBufferIn[5];
reg [7:0] dataBufferOut[5];
assign data = (RDn == 1'b0) ? dataBufferOut[address] : 8'bZ; // tri-state
always @(posedge WRn) dataBufferIn[address] <= data;

// math
wire signed [15:0] A = { dataBufferIn[0], dataBufferIn[1] };
wire signed [15:0] B = { dataBufferIn[2], dataBufferIn[3] };
wire signed [31:0] Y = A * B;

always @(negedge RDn) begin
    dataBufferOut[0] <= Y[31:24];
    dataBufferOut[1] <= Y[23:16];
    dataBufferOut[2] <= Y[15:8];
    dataBufferOut[3] <= Y[7:0];
    dataBufferOut[4] <= 8'hAA;
end
endmodule
