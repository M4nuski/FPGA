// Tang Nano basic 8 bit parallel interface (tri-state)
/*
// #WR #RD, no #RST, no #CS, no address
module top (
    input clk,
    input WRn,
    input RDn,
    inout wire [7:0] data
);

reg [7:0] dataBuffer = 8'hAA;
assign data = (RDn == 1'b0) ? dataBuffer : 8'bZ; // tri-state
always @(posedge WRn) dataBuffer <= data;

always @(posedge clk) begin
    //
end
endmodule
*/

// #WR #RD, no #RST, no #CS, 3 bit address
module top (
    input clk,
    input WRn,
    input RDn,
    input [2:0] address,
    inout wire [7:0] data
);

reg [7:0] dataBuffer[8];
assign data = (RDn == 1'b0) ? dataBuffer[address] : 8'bZ; // tri-state
always @(posedge WRn) dataBuffer[address] <= data; // posedge because of slow set time of data lines vs Enable

always @(posedge clk) begin
    // 
end
endmodule

// #WR #RD #CS, 2 bit address
/*module top (
    input clk,
    input CSn,
    input WRn,
    input RDn,
    input [1:0] address,
    inout wire [7:0] data
);

reg [7:0] dataBuffer[4];
assign data = (!RDn && !CSn) ? dataBuffer[address] : 8'bZ; // tri-state
always @(posedge (WRn || CSn)) dataBuffer[address] <= data;


always @(posedge clk) begin
    // 
end
endmodule*/