// Tang Nano basic 8 bit parallel interface (tri-state)
// ROM emulator with UART update
// 16K memory space

module top (
    input btn1, // reset
    input clk, // 27MHz

    // CPU interface
//    input RDn,
//    input [13:0] address,
//    inout wire [7:0] data

    // uart interface
    input uart_rx,
    output uart_tx
);

//reg [7:0] dataBuffer[0:7];
//assign data = (RDn == 1'b0) ? dataBuffer[address] : 8'bZ; // tri-state

wire txReadyToRead;
reg txDataAvailable = 0;
reg [7:0] txBuffer; 

wire rxDataAvailable;
reg rxReadyToRead = 1;
wire [7:0] rxBuffer; 

UART uart(
    btn1, // resetn
    clk, 

    uart_rx, 
    rxDataAvailable, rxReadyToRead, rxBuffer,

    uart_tx, 
    txReadyToRead, txDataAvailable, txBuffer
);

reg [2:0] state = 0;
localparam STATE_IDLE = 0;
localparam STATE_WAIT_UART = 1;
localparam STATE_LOAD = 2;
localparam STATE_ROM = 3;

always @(posedge clk) begin
    case (state)
         STATE_IDLE : begin
            txBuffer <= "?";
            if (txDataAvailable & txReadyToRead) begin
                txDataAvailable <= 0;

                state <= STATE_WAIT_UART;
            end else txDataAvailable <= 1;
         end
         STATE_WAIT_UART : begin
            if (rxDataAvailable & rxReadyToRead) begin
                state <= STATE_LOAD;
                txBuffer <= rxBuffer;
            end
         end
         STATE_LOAD : begin
            if (txDataAvailable & txReadyToRead) begin
                txDataAvailable <= 0;
                state <= STATE_WAIT_UART;
            end else txDataAvailable <= 1;
         end
         STATE_ROM : begin
         end
    endcase
end
endmodule