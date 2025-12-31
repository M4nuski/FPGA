// Simple Signed Int16 Math coprocessor for homebrew computers
// 8 bit parallel interface
// M4nusky DEC-2025

// Tang Nano 1K
// pass at board's default 27MHz clock
// yosys need -nowidelut

module top_v1b (
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
//      0: Sqr      XY = A*A
//      1: Length   X = Sqrt(A*A + B*B)

//      
// on read
//  0: Xh (Q.A) Sqr MSB Lenh
//  1: Xl (Q.B)         Lenl
//  2: Yh (Q.C) 
//  3: Yl (Q.D) Sqr LSB
//  7: Busy

reg [7:0] DataBuffer;
assign Data = DataBuffer;

reg [15:0] A = 0; // input register
reg [31:0] Ax = 0; // work register
reg [15:0] B = 0; // input register
reg [31:0] Bx = 0; // work register
reg [31:0] X = 0; // output register
reg [31:0] Y = 0; // work register

reg Operation = 0;
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
                Operation <= Data[0];
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
            //sqr16
            0: begin
                if (Seq == 7'd0) begin // init
                    X <= 32'd0;
                    Ax <= {  17'd0, (A[15] == 1'b0) ? A[14:0] : -A[14:0] }; // clear and copy pos value
                end else if (Seq <= 7'd16) begin 
                    if (Ax[(2*Seq)-2] == 1'b1) X <= X + Ax;
                    Ax <= Ax << 1;
                end else begin
                    Status <= 0; // not busy
                end
            end // end sqr16 op


            // len16
            1: begin
                if (Seq == 7'd0) begin // init
                    X <= 32'd0;
                    Y <= 32'd0;
                    Ax <= {  17'd0, (A[15] == 1'b0) ? A[14:0] : -A[14:0] }; // clear and copy pos value
                    Bx <= {  17'd0, (B[15] == 1'b0) ? B[14:0] : -B[14:0] }; // clear and copy pos value
                end else if (Seq <= 7'd16) begin 
                    if (Ax[(2*Seq)-2] == 1'b1) X <= X + Ax;
                    Ax <= Ax << 1;
                    if (Bx[(2*Seq)-2] == 1'b1) Y <= Y + Bx;
                    Bx <= Bx << 1;
                end else if (Seq == 7'd17) begin // SQRT init
                    Ax <= X + Y;
                    X <= 32'd0; // clear result
                    Bx <= 32'h40000000; // initial guess
                end else if (Seq <= 7'd51) begin //1-34 reduce
                    if (Seq[0] == 1'd1) begin // odd step
                        if (Bx == 32'd0) begin
                            Seq <= 7'd52;
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
