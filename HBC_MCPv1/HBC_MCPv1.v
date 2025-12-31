// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky DEC-2025

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1 (
    input clk,
    input RDn,
    input WRn,
    input [2:0] Address,
    inout [7:0] Data
);

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

reg [7:0] DataBuffer;
assign Data = DataBuffer;

reg [15:0] A = 0; // input register
reg [31:0] Ax = 0; // work register
reg [15:0] B = 0; // input register
reg [31:0] Bx = 0; // work register
reg [31:0] X = 0; // output register

reg [1:0] Operation = 0;
reg [6:0] Seq = 0; // operation sub steps
reg Status = 0; // 1: busy

// Main state machine
always @(posedge clk) begin
    // write register
    if ((WRn == 1'b0) && (RDn == 1'b1)) begin 
        case (Address)
            0: A [15:8] <= Data;
            1: A [7:0]  <= Data;
            2: B [15:8] <= Data;
            3: B [7:0]  <= Data;
            7: begin
                Operation <= Data[1:0];
                Status <= 1'b1;
                Seq <= 7'd0;
            end
        endcase
    // read register
    end else if ((WRn == 1'b1) && (RDn == 1'b0)) begin 
        case (Address)
            0: DataBuffer <= X [31:24];
            1: DataBuffer <= X [23:16];
            2: DataBuffer <= X [15:8];
            3: DataBuffer <= X [7:0];
            7: DataBuffer <= {7'd0, Status};
        endcase
    // high-Z
    end else DataBuffer <= 8'bzzzzzzzz;

    // process operation
    if (Status == 1'b1) begin
        Seq <= Seq + 1;
        case (Operation)
            //mult16
            0: begin 
                if (Seq == 7'd0) begin // init
                    X <= { (A[15] ^ B[15]), 31'd0 }; // sign bit, clear
                    Bx <= { 17'd0, (B[15] == 1'b0) ? B[14:0] : -B[14:0] }; // clear and copy except sign
                    Ax[14:0] <= (A[15] == 1'b0) ? A[14:0] : -A[14:0]; // copy except sign
                end else if (Seq <= 7'd16) begin 
                    if (Ax[0] == 1'b1) X <= X + Bx;
                    Ax[14:0] <= Ax[14:0] >> 1;
                    Bx <= Bx << 1;
                end else begin
                    Status <= 0; // not busy
                    if (X[31] == 1'b1) X[30:0] <= -X[30:0]; // re-adjust sign
                end
            end // end mult16 op

            // divmod16
            1: begin 
                if (Seq == 7'd0) begin // init
                    X <= { (A[15] ^ B[15]), 31'd0 }; // sign bit, clear
                    Ax <= { 17'd0, (A[15] == 1'b0) ? A[14:0] : -A[14:0] }; // copy positive part
                    Bx <= { 3'd0, (B[15] == 1'b0) ? B[14:0] : -B[14:0], 14'd0 }; // copy positive part
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
                    if (X[31] == 1'b1) begin
                        X[30:16] <= -X[30:16];
                        X[15:0] <= -X[15:0];
                    end
                    Status <= 0;
                end
            end // end divmod16 op

            // divfract16
            2: begin 
                if (Seq == 7'd0) begin // init
                    X <= { (A[15] ^ B[15]), 31'd0 }; // sign bit, clear
                    Ax <= { 17'd0, (A[15] == 1'b0) ? A[14:0] : -A[14:0] }; // copy positive part
                    Bx <= { 3'd0, (B[15] == 1'b0) ? B[14:0] : -B[14:0], 14'd0 }; // copy positive part
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
                    if (X[31] == 1'b1) X[30:0] <= -X[30:0];
                    Status <= 0;
                end
            end // end divfract16

            // sqrt16.8
            3: begin
                if (Seq == 7'd0) begin //0 init
                    Ax <= { 1'd0, A[14:0], 16'd0 }; // target, shifted by 16 bits to allow fractional part
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
    end // end status == 1
end // end clk 

endmodule
