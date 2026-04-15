// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky JAN-2026

// v1a: Sqr, Length

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1a (
    input clk,
    input WRn,
    input RDn,
    input [2:0] address, // 3
    inout wire [7:0] data // 8
);

// interface
reg [2:0] addressBuffer;
reg [7:0] dataBufferIn[0:4];
wire [7:0] dataBufferOut[0:5];
assign data = (RDn == 1'b0) ? dataBufferOut[address] : 8'bZ; // tri-state
always @(posedge WRn) begin
    dataBufferIn[address] <= data;
    addressBuffer <= address;
end
// Address map
// on write
//  0: Ah
//  1: Al
//  2: Bh
//  3: Bl
//  4: Operation
//      0: Sqr      Q = A*A
//      1: Length   X = Sqrt(A*A + B*B)

//      
// on read
//  0: Xh (Q.A) Sqr MSB Lenh
//  1: Xl (Q.B)         Lenl
//  2: Yh (Q.C) 
//  3: Yl (Q.D) Sqr LSB
//  4: [0, 0, 0, Busy,  0, 0, 0, Operation]
//  5: Random byte

// global state
reg Status = 0;
wire Operation = dataBufferIn[4][0];
reg [5:0] Seq = 0; // 0-63

// math
wire [14:0] A = { dataBufferIn[0][6:0], dataBufferIn[1] }; // 15
wire [14:0] B = { dataBufferIn[2][6:0], dataBufferIn[3] }; // 15
wire Asign = dataBufferIn[0][7];
wire Bsign = dataBufferIn[2][7];
wire Xsign = Asign ^ Bsign;
wire [14:0] Apos = (Asign == 0) ? A : -A; // 15
wire [14:0] Bpos = (Bsign == 0) ? B : -B; // 15

reg [32:0] Ax = 0; // work register 33
reg [32:0] Bx = 0; // work register 33
reg [32:0] Y = 0; // work register 33
reg [32:0] X = 0; // output register 33

assign dataBufferOut[0] = X[31:24];
assign dataBufferOut[1] = X[23:16];
assign dataBufferOut[2] = X[15:8];
assign dataBufferOut[3] = X[7:0];
assign dataBufferOut[4] = { 3'b0, Status, 3'b0, Operation };
//PRNG
wire randomBit;
reg [7:0] randomByte = 0; // 8
lfsr #() randomGen (clk, randomBit);
always @(posedge clk) randomByte <= { randomByte[6:0], randomBit };
assign debug = Status;
assign dataBufferOut[5] = randomByte;
// 7FFF sqr
// sqr is 0011 1111  1111 1111  0000 0000  0000 0001
// A+B is 0111 1111  1111 1110  0000 0000  0000 0010
//        0100 sqrt initial not enough
//      1 0000 sqrt max is 33 bits long
reg [2:0] WRn_prev = 0;
// Main state machine
always @(posedge clk) begin
   WRn_prev <= { WRn_prev[1:0], WRn };
   if ((WRn_prev == 3'b011) & (addressBuffer == 3'd4) & (Status == 1'b0)) begin
        Seq <= 6'd0;
        Status <= 1'b1;
    end else if (Status == 1'b1) begin
        Seq <= Seq + 6'd1;
        case (Operation)
        //sqr16
        0: begin
                if (Seq == 6'd0) begin // init
                    X <= 33'd0;
                    Ax <= {  18'd0, Apos }; // clear and copy pos value
                end else if (Seq <= 6'd16) begin 
                    if (Ax[(2*Seq)-2] == 1'b1) X <= X + Ax;
                    Ax <= Ax << 1;
                end else begin
                    Status <= 1'b0; // not busy
                end
        end // end sqr16 op


        // len16
        1: begin
            if (Seq == 6'd0) begin // init
                X <= 33'd0;
                Y <= 33'd0;
                Ax <= { 18'd0, Apos }; // clear and copy pos value
                Bx <= { 18'd0, Bpos }; // clear and copy pos value
            end else if (Seq <= 6'd16) begin // compute square of A and B
                if (Ax[(2*Seq)-2] == 1'b1) X <= X + Ax;
                Ax <= Ax << 1;
                if (Bx[(2*Seq)-2] == 1'b1) Y <= Y + Bx;
                Bx <= Bx << 1;
            end else if (Seq == 6'd17) begin // SQRT init
                Ax <= X + Y; // sum of the 2 squared values
                X <= 33'd0; // clear result
                Bx <= 33'h100000000; // initial (maximal) guess
            end else if (Seq <= 6'd51) begin //1-34 reduce
                if (Seq[0] == 1'd1) begin // odd step
                    if (Bx == 33'd0) begin
                        Status <= 1'b0;
                    end else if (Ax >= (X + Bx)) begin
                        Ax <= Ax - (X + Bx);
                        X <= X + (Bx << 1);
                    end
                end else begin // even step
                    X <= X >> 1;
                    Bx <= Bx >> 2;
                end
            end // end sqrt reduce
        end // end len16
        endcase // end case operation
    end // end status == 1
end // end clk
endmodule
