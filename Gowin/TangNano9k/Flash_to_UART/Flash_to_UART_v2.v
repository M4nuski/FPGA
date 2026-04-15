// Flash data to UART
// Reads flash memory 32 bytes per chunk and send it to UART prefixed with 3 byte address
// v2 with AXI flow control

`default_nettype none
module top (
    //main clock
    input clk,
    //uart
    input uart_rx,
    output reg uart_tx,
    //UI
    output reg [5:0] led,
    input btn1, input btn2,
    //flash
    output reg flashClk,
    input flashMiso,
    output reg flashMosi,
    output reg flashCs
);

localparam UART_BAUD_DELAY_9600 = 13'd2812;
localparam UART_BAUD_DELAY_115200 = 13'd234;

UART #(UART_BAUD_DELAY_115200) urxtx(
    // physical interface
    clk, 
    uart_rx, 
    uart_tx, 

    // UI
    led, 
    btn1, btn2,

    // data
    top_dataBuffer,
    f2u_DA, f2u_RtR
);

wire [24+255:0] top_dataBuffer;

wire f2u_DA;
wire f2u_RtR;

flashReader flash(
    // physical interface
    clk,
    flashClk,
    flashMiso,
    flashMosi,
    flashCs,

    // data
    top_dataBuffer, // 3+32 bytes
    f2u_DA, f2u_RtR // DataAvailable, ReadyToRead
);
endmodule


module UART
#(
    parameter DELAY_FRAMES = 13'd234, //115200 default
    parameter DEBOUNCE_WAIT = 23'b111111111111111111
)
(
    input clk,
    input uart_rx,
    output reg uart_tx = 1,
    output reg [5:0] led,
    input btn1, input btn2,

    input [24+255:0] f_dataBuffer,

    input u_dataAvailable,
    output reg u_readyToRead = 0
);


    reg [3:0] rxState = 0;
    reg [12:0] rxCounter = 0;
    reg [2:0] rxBitNumber = 0;
    reg [7:0] dataIn = 0;
    reg byteReady = 0;

    localparam RX_STATE_IDLE = 0;
    localparam RX_STATE_START_BIT = 1;
    localparam RX_STATE_READ_WAIT = 2;
    localparam RX_STATE_READ = 3;
    localparam RX_STATE_STOP_BIT = 5;

    localparam HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

    // RX
    always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            if (uart_rx == 0) begin
                rxState <= RX_STATE_START_BIT;
                rxCounter <= 1;
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end 
        RX_STATE_START_BIT: begin
            if (rxCounter == HALF_DELAY_WAIT) begin
                rxState <= RX_STATE_READ_WAIT;
                rxCounter <= 1;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ_WAIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_READ;
            end
        end
        RX_STATE_READ: begin
            rxCounter <= 1;
            dataIn <= {uart_rx, dataIn[7:1]};
            rxBitNumber <= rxBitNumber + 1;
            if (rxBitNumber == 3'b111)
                rxState <= RX_STATE_STOP_BIT;
            else
                rxState <= RX_STATE_READ_WAIT;
        end
        RX_STATE_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_STATE_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase
    end

    // display data on LEDs
    always @(posedge clk) begin
        if (byteReady) led <= ~dataIn[5:0];
    end

    // TX 
reg [3:0] txState = 0;//0-15
reg [24:0] txCounter = 0;//0-32M
reg [7:0] dataOut = 0;//0-255
reg [2:0] txBitNumber = 0;//0-7
reg [7:0] txByteCounter = 0;//0-255

localparam MEMORY_LENGTH = 3+32;

reg [24+255:0] interalMemory;
/*
initial begin
    interalMemory[0] = 8'hAA;
    interalMemory[1] = 8'h55;
    interalMemory[2] = 8'hAA;
    interalMemory[3] = 8'h55;
end*/

localparam TX_STATE_IDLE = 0;
localparam TX_STATE_WAIT_START = 1;
localparam TX_STATE_START_BIT = 2;
localparam TX_STATE_WRITE = 3;
localparam TX_STATE_STOP_BIT = 4;
localparam TX_STATE_DEBOUNCE = 5;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if ((u_readyToRead == 1) && (u_dataAvailable == 1)) begin
                u_readyToRead <= 0;
                interalMemory <= f_dataBuffer;
                txState <= TX_STATE_WAIT_START;
            end
            else begin
                uart_tx <= 1;
                u_readyToRead <= 1;
            end
        end 

        TX_STATE_WAIT_START: begin
            if (btn1 == 0) begin
                txState <= TX_STATE_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
            end
        end
        TX_STATE_START_BIT: begin
            uart_tx <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState <= TX_STATE_WRITE;
                dataOut <= interalMemory[((txByteCounter*8)+7) -:8];
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            uart_tx <= dataOut[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            uart_tx <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == MEMORY_LENGTH - 1) begin
                    txState <= TX_STATE_DEBOUNCE;

                end else begin
                    txByteCounter <= txByteCounter + 1;
                    txState <= TX_STATE_START_BIT;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_DEBOUNCE: begin
            uart_tx <= 1;
            if (txCounter == DEBOUNCE_WAIT) begin
                if (btn1 == 1) txState <= TX_STATE_IDLE;
            end else
                txCounter <= txCounter + 1;
        end
    endcase      
end

endmodule

module flashReader
#(
  parameter STARTUP_WAIT = 32'd10000000
)
(
    input clk,
    output reg flashClk,
    input flashMiso,
    output reg flashMosi = 0,
    output reg flashCs = 1,

    output [24+255:0] f_dataBuffer, // 3+32 bytes
    output reg f_dataAvailable = 0,
    input f_readyToRead

);

  reg [23:0] readAddress = 0;
  reg [7:0] command = 8'h03; // read
  reg [7:0] currentByteOut = 0;
  reg [7:0] currentByteNum = 0;
  reg [24+255:0] dataIn = 0;

  //reg [24+255:0] innerDataBuffer = 256'd0;
  //assign f_dataBuffer = innerDataBuffer;
    assign f_dataBuffer = dataIn;

  localparam STATE_INIT_POWER = 8'd0;
  localparam STATE_LOAD_CMD_TO_SEND = 8'd1;
  localparam STATE_SEND = 8'd2;
  localparam STATE_LOAD_ADDRESS_TO_SEND = 8'd3;
  localparam STATE_READ_DATA = 8'd4;
  localparam STATE_DONE = 8'd5;

  reg [23:0] dataToSend = 0;
  reg [8:0] bitsToSend = 0;

  reg [31:0] counter = 0;
  reg [2:0] state = 0;
  reg [2:0] returnState = 0;

 

  always @(posedge clk) begin
    case (state)
      STATE_INIT_POWER: begin
        if (counter > STARTUP_WAIT) begin
          state <= STATE_LOAD_CMD_TO_SEND;
          counter <= 32'b0;
          currentByteNum <= 0;
          currentByteOut <= 0;
        end
        else
          counter <= counter + 1;
      end
      STATE_LOAD_CMD_TO_SEND: begin
          flashCs <= 0;
          dataToSend[23-:8] <= command;
          bitsToSend <= 8;
          state <= STATE_SEND;
          returnState <= STATE_LOAD_ADDRESS_TO_SEND;
      end
      STATE_SEND: begin
        if (counter == 32'd0) begin
          flashClk <= 0;
          flashMosi <= dataToSend[23];
          dataToSend <= {dataToSend[22:0],1'b0};
          bitsToSend <= bitsToSend - 1;
          counter <= 32'd1;
        end else begin
          counter <= 32'd0;
          flashClk <= 1;
          if (bitsToSend == 0)
            state <= returnState;
        end
      end
      STATE_LOAD_ADDRESS_TO_SEND: begin
        dataToSend <= readAddress;
        dataIn[256+:24] <= readAddress;
        bitsToSend <= 24;
        state <= STATE_SEND;
        returnState <= STATE_READ_DATA;
        currentByteNum <= 0;
      end
      STATE_READ_DATA: begin
        if (counter[0] == 1'd0) begin
          flashClk <= 0;
          counter <= counter + 1;
          if (counter[3:0] == 0 && counter > 0) begin
            dataIn[(currentByteNum << 3)+:8] <= currentByteOut;
            currentByteNum <= currentByteNum + 1;
            if (currentByteNum == 31) begin
              state <= STATE_DONE;
            end
          end
        end // counter == 0
        else begin
          flashClk <= 1;
          currentByteOut <= {currentByteOut[6:0], flashMiso};
          counter <= counter + 1;
        end
      end
      STATE_DONE: begin
        if (f_dataAvailable == 0) begin
            flashCs <= 1;
          //  innerDataBuffer <= {readAddress, dataIn};
            f_dataAvailable <= 1; // set DA
        end else if (f_readyToRead == 1) begin // DA and RTR
            f_dataAvailable <= 0; // reset DA
            state <= STATE_LOAD_CMD_TO_SEND;
            counter <= 32'b0;
            currentByteNum <= 0;
            currentByteOut <= 0;
            readAddress <= (readAddress + 24'd32);
        end
      end
    endcase

  end
endmodule