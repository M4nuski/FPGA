// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky DEC-2025

// v1x blast multiply 16x16 

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1x (
    input clk,
    input WRn,
    input RDn,
    input [2:0] address,
    inout wire [7:0] data
);

// interface 
reg [7:0] dataBufferIn[0:5];
wire [7:0] dataBufferOut[0:5];
assign data = !RDn ? dataBufferOut[address] : 8'bZ; // tri-state
always @(negedge WRn) dataBufferIn[address] <= data;

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
/*
wire [15:0] A = { dataBufferIn[0], dataBufferIn[1] }; // input register
wire [15:0] B = { dataBufferIn[2], dataBufferIn[3] }; // input register
reg [31:0] X = 0; // output register
wire [30:0] Y = 0; // working sum

wire [14:0] AA = (A[15] == 1'b0) ? A[14:0] : -A[14:0];
wire [14:0] BB = (B[15] == 1'b0) ? B[14:0] : -B[14:0];
wire sign = A[15] ^ B[15];

assign dataBufferOut[0] = X[31:24];
assign dataBufferOut[1] = X[23:16];
assign dataBufferOut[2] = X[15:8];
assign dataBufferOut[3] = X[7:0];

wire [31:0] B0;
wire [31:0] B1;
wire [31:0] B2;
wire [31:0] B3;

wire [31:0] B4;
wire [31:0] B5;
wire [31:0] B6;
wire [31:0] B7;

wire [31:0] B8;
wire [31:0] B9;
wire [31:0] B10;
wire [31:0] B11;

wire [31:0] B12;
wire [31:0] B13;
wire [31:0] B14;

//always @(*) begin
assign    B0 = (AA[0] == 1'b1) ? (BB) : 0;
assign    B1 = (AA[1] == 1'b1) ? (BB<<1) : 0;
assign    B2 = (AA[2] == 1'b1) ? (BB<<2) : 0;
assign    B3 = (AA[3] == 1'b1) ? (BB<<3) : 0;

assign    B4 = (AA[4] == 1'b1) ? (BB<<4) : 0;
assign    B5 = (AA[5] == 1'b1) ? (BB<<5) : 0;
assign    B6 = (AA[6] == 1'b1) ? (BB<<6) : 0;
assign    B7 = (AA[7] == 1'b1) ? (BB<<7) : 0;

assign    B8 = (AA[8] == 1'b1) ? (BB<<8) : 0;
assign    B9 = (AA[9] == 1'b1) ? (BB<<9) : 0;
assign    B10 = (AA[10] == 1'b1) ? (BB<<10) : 0;
assign    B11 = (AA[11] == 1'b1) ? (BB<<11) : 0;

assign   B12 = (AA[12] == 1'b1) ? (BB<<12) : 0;
assign   B13 = (AA[13] == 1'b1) ? (BB<<13) : 0;
assign   B14 = (AA[14] == 1'b1) ? (BB<<14) : 0;

assign    Y = B0;// + B1 + B2 + B3 + B4 + B5 + B6 + B7 + B8 + B9 + B10 + B11 + B12 + B13 + B14;
*/
    
   // Y = AA * BB;
//end;

wire signed [15:0] A = { dataBufferIn[0], dataBufferIn[1] }; // input register A
wire signed [15:0] B = { dataBufferIn[2], dataBufferIn[3] }; // input register B
wire signed [31:0] X = A * B;
assign dataBufferOut[0] = X[31:24];
assign dataBufferOut[1] = X[23:16];
assign dataBufferOut[2] = X[15:8];
assign dataBufferOut[3] = X[7:0];

// Main state machine
always @(posedge clk) begin
  //  if (sign) begin
 //       X <= { 1'b1, -Y};
  //  end else begin
   //     X <= { 1'b0,  Y};
  //  end
end // end clk 

endmodule
