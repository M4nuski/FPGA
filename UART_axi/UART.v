// UART for TangNano
// Axi interface

`default_nettype none

module UART
#(
    parameter DELAY_FRAMES = 234
    // clk at 27MHz
    // 234 : 115200 baud rate
    // 2812 : 9600 baud rate
)
(
    input resetn,
    input clk,

    input uart_rx,
    output reg axi_inData_available,
    input axi_inData_readyToRead,
    output reg [7:0] inData,

    output reg uart_tx,
    output reg axi_outData_readyToRead,
    input axi_outData_available,
    input [7:0] outData
);

    // RX
    reg [2:0] rxState = 0;
    reg [12:0] rxCounter = 0;
    reg [2:0] rxBitNumber = 0;
    reg [1:0] lineState = 2'd0;

    localparam RX_STATE_IDLE = 0;
    localparam RX_STATE_START_BIT = 1;
    localparam RX_STATE_READ_WAIT = 2;
    localparam RX_STATE_READ = 3;
    localparam RX_STATE_STOP_BIT = 4;

    localparam HALF_DELAY_FRAMES = (DELAY_FRAMES / 2);

    // reset
    always @(posedge clk) begin
        if (!resetn) begin
            rxState <= RX_STATE_IDLE;
            axi_inData_available <= 0;
            inData <= 8'b0;
        end else case (rxState)
        RX_STATE_IDLE: begin
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
             //   axi_inData_available <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_FRAMES) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 0;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            //rxCounter <= rxCounter + 1;
	    lineState <= { lineState[0], uart_rx };
	    if ((lineState == 2'b10) || (lineState == 2'b01)) rxCounter <= HALF_DELAY_FRAMES; else rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES) rxState <= RX_STATE_READ;
        end
        RX_STATE_READ: begin
            rxCounter <= 0;
            inData <= {uart_rx, inData[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if (rxCounter == DELAY_FRAMES) begin
                rxState <= RX_STATE_IDLE;
               // rxCounter <= 0;
                axi_inData_available <= 1;
            end
        end
    endcase
    end

   // axi rx data transfer out of module
    always @(posedge clk) begin
        if (axi_inData_available & axi_inData_readyToRead) axi_inData_available <= 0;
    end


    // TX 
    reg [1:0] txState = 0;
    reg [12:0] txCounter = 0;
    reg [2:0] txBitNumber = 0;
    reg [7:0] outDataBuffer;

    localparam TX_STATE_IDLE = 0;
    localparam TX_STATE_START_BIT = 1;
    localparam TX_STATE_WRITE = 2;
    localparam TX_STATE_STOP_BIT = 3;

    always @(posedge clk) begin
        if (!resetn) begin
            txState <= RX_STATE_IDLE;
            axi_outData_readyToRead <= 0;
            uart_tx <= 1;
        end else case (txState)
        TX_STATE_IDLE: begin
            if (axi_outData_readyToRead & axi_outData_available) begin
                outDataBuffer <= outData;
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                axi_outData_readyToRead <= 0;
            end else axi_outData_readyToRead <= 1;
        end 
        TX_STATE_START_BIT: begin
            uart_tx <= 0;
            if (txCounter == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            uart_tx <= outDataBuffer[txBitNumber];
            if (txCounter == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            uart_tx <= 1;
            if (txCounter == DELAY_FRAMES) begin
                txState <= TX_STATE_IDLE;
               // txCounter <= 0;
            end else txCounter <= txCounter + 1;
        end
    endcase
end

endmodule