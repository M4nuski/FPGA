// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky JAN-2026

// v1a, Sqr, Length

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1a (
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
//  4: Operation
//      0: Sqr      XY = A*A
//      1: Length   X = Sqrt(A*A + B*B)

//      
// on read
//  0: Xh (Q.A) Sqr MSB Lenh
//  1: Xl (Q.B)         Lenl
//  2: Yh (Q.C) 
//  3: Yl (Q.D) Sqr LSB
//  4: Busy

// global state
reg Status = 0;
wire Operation = dataBufferIn[4][0];
reg [5:0] Seq = 0; // 0-63

// math
wire [14:0] A = { dataBufferIn[0][6:0], dataBufferIn[1] };
wire [14:0] B = { dataBufferIn[2][6:0], dataBufferIn[3] };
wire Asign = dataBufferIn[0][7];
wire Bsign = dataBufferIn[2][7];
wire Xsign = Asign ^ Bsign;
wire [14:0] Apos = (Asign == 0) ? A : -A;
wire [14:0] Bpos = (Bsign == 0) ? B : -B;

reg [31:0] Ax = 0; // work register
reg [31:0] Bx = 0; // work register
reg [31:0] Y = 0; // work register

reg [31:0] X = 0; // output register
assign dataBufferOut[0] = X[31:24];
assign dataBufferOut[1] = X[23:16];
assign dataBufferOut[2] = X[15:8];
assign dataBufferOut[3] = X[7:0];
assign dataBufferOut[4] = { 7'b0, Status };


// Main state machine
always @(posedge clk) if ((WRn == 1'b0) && (address == 3'd4)) begin
    Seq <= 6'd0; // on write to op byte, reset sequence and set status
    Status <= 1'b1;
end else if (Status == 1'b1) begin

    Seq <= Seq + 6'd1;

    case (Operation)
        //sqr16
        0: begin
                if (Seq == 6'd0) begin // init
                    X <= 32'd0;
                    Ax <= {  17'd0, Apos }; // clear and copy pos value
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
                X <= 32'd0;
                Y <= 32'd0;
                Ax <= { 17'd0, Apos }; // clear and copy pos value
                Bx <= { 17'd0, Bpos }; // clear and copy pos value
            end else if (Seq <= 6'd16) begin // compute square of A and B
                if (Ax[(2*Seq)-2] == 1'b1) X <= X + Ax;
                Ax <= Ax << 1;
                if (Bx[(2*Seq)-2] == 1'b1) Y <= Y + Bx;
                Bx <= Bx << 1;
            end else if (Seq == 6'd17) begin // SQRT init
                Ax <= X + Y; // sum of the 2 squared values
                X <= 32'd0; // clear result
                Bx <= 32'h40000000; // initial (maximal) guess
            end else if (Seq <= 6'd51) begin //1-34 reduce
                if (Seq[0] == 1'd1) begin // odd step
                    if (Bx == 32'd0) begin
                    //    Seq <= 8'd127;
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
end // end clk 

endmodule
