// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky DEC-2025

// v1b: Mult, Div (mod), Div (fraction), Sqrt

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1b (
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

// Address map
// on write
//  0: Ah (D.A)
//  1: Al (D.B)
//  2: Bh (D.A)
//  3: Bl (D.B)
//  7: Operation
//      0: Mult 16x16 to 32 bit             XY = A * B   (20 clocks)
//      1: Div and Modulus                  X = A / B, Y = A % B    (33 clocks)
//      2: Div with 16 bit fractional part  X.Y = A / B (X: int part, Y: fract part)  (65 clocks)
//      3: Sqrt with 8 bit fractional part  X.Yh = Sqrt(A) (X: int part, Yh: fract part) (36 clocks)
//      
// on read
//  0: Xh (Q.A) Mul MSB, Div h, Div h,       Sqrt h
//  1: Xl (Q.B)          Div l, Div l,       Sqrt l
//  2: Yh (Q.C)          Mod h, Div fract h, Sqrt fract
//  3: Yl (Q.D) Mul LSB, Mod l, Div fract l
//  7: Busy

// global state
reg Status = 0; // 1: busy
wire [1:0] Operation = dataBufferIn[4][1:0];
reg [6:0] Seq = 0; // operation sub steps 0-127

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

reg [31:0] X = 0; // output register
assign dataBufferOut[0] = X[31:24];
assign dataBufferOut[1] = X[23:16];
assign dataBufferOut[2] = X[15:8];
assign dataBufferOut[3] = X[7:0];
assign dataBufferOut[4] = { 7'b0, Status };

// Main state machine
always @(posedge clk) begin
    if ((WRn == 1'b0) && (address == 3'd4)) begin
        Seq <= 7'd0; // on write to op byte, reset and save data
        Status <= 1'b1;
    end
    else if (Status == 1'b1) begin
        Seq <= Seq + 7'd1;
        case (Operation)
        //mult16
        0: begin 
            if (Seq == 7'd0) begin // init
               // X <= { (A[15] ^ B[15]), 31'd0 }; // sign bit, clear
                X <= 32'd0;
                Bx <= { 17'd0, Bpos }; // clear and copy except sign
                Ax[14:0] <= Apos; // copy except sign
            end else if (Seq <= 7'd16) begin 
                if (Ax[0] == 1'b1) X <= X + Bx;
                Ax[14:0] <= Ax[14:0] >> 1;
                Bx <= Bx << 1;
            end else begin
                Status <= 0; // not busy
            //    if (Xsign) X[31:0] <= { 1'b1, -X[30:0] }; // re-adjust sign
            end
        end // end mult16 op

        // divmod16
        1: begin 
            if (Seq == 7'd0) begin // init
                //X <= { (A[15] ^ B[15]), 31'd0 }; // sign bit, clear
                X <= 32'd0;
                Ax <= { 17'd0, Apos }; // copy positive part
                Bx <= { 3'd0, Bpos, 14'd0 }; // copy positive part
            end else if (Seq <= 7'd30) begin // calc
                if (Seq[0] == 1'd1) begin // odd step
                    if (Bx <= Ax) begin
                        X <= X | (1 << 30-((Seq-1)/2));
                        Ax <= Ax - Bx;
                    end
                end else begin // even step
                    Bx <= Bx >> 1;
                    if (Ax[14:0] == 15'd0) Seq <= 7'd31;
                end
            end else if (Seq == 7'd31) begin
                X[14:0] <= Ax[14:0]; // remainder 
            end else begin //32 sign and finalize
                if (Xsign) begin
                    X[31:16] <= { 1'b1, -X[30:16] };
                    X[15:0] <= -X[15:0];
                end
                Status <= 0;
            end
        end // end divmod16 op

        // divfract16
        2: begin 
            if (Seq == 7'd0) begin // init
                //X <= { Xsign, 31'd0 }; // sign bit, clear
                X <= 32'd0;
                Ax <= { 17'd0, Apos }; // copy positive part
                Bx <= { 3'd0, Bpos, 14'd0 }; // copy positive part
            end else if (Seq <= 7'd62) begin // calc
                if (Seq[0] == 1'd1) begin // odd step
                    if (Bx <= Ax) begin
                        X <= X | (1 << 30-((Seq-1)/2));
                        Ax <= Ax - Bx;
                    end
                end else begin // even step
                    if (Ax[29:0] == 30'd0) Seq <= 7'd63;
                    if (Seq == 7'd30) begin // fraction
                        Ax <= Ax << 16; 
                        Bx <= Bx << 15;
                    end else Bx <= Bx >> 1;
                end
            end else begin //32 sign and finalize
            //    if (Xsign) X[31:0] <= { 1'b1, -X[30:0] };
                Status <= 0;
            end
        end // end divfract16

        // sqrt16.8
        3: begin
            if (Seq == 7'd0) begin //0 init
                Ax <= { 1'd0, Apos, 16'd0 }; // target, shifted by 16 bits to allow fractional part
                X <= 32'd0; // clear result
                Bx <= 32'h40000000; // initial guess
            end else if (Seq <= 7'd34) begin //1-34 reduce
                if (Seq[0] == 1'd1) begin // odd step
                    if (Bx == 32'd0) begin
                        Seq <= 7'd35;
                    end else if (Ax >= (X + Bx)) begin
                        Ax <= Ax - (X + Bx);
                        X <= X + (Bx << 1);
                    end
                end else begin // even step
                    X <= X >> 1;
                    Bx <= Bx >> 2;
                end
            end else begin //35 finalize
                Status <= 1'b0;
                X <= X << 8; // offset back to align fraction
            end
        end // end sqrt16.8

    endcase // end case operation
    end
end // end clk 

endmodule
