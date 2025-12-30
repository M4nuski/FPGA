module flashReader
  #(
    parameter STARTUP_WAIT = 32'd2700000
  )
  (
    input clk,
    output reg flashClk,
    input flashMiso,
    output reg flashMosi = 0,
    output reg flashCs = 1,

    output [255:0] f_dataBuffer, // 32 bytes
    output reg f_dataAvailable = 0,
    input f_readyToRead
  );

  reg [23:0] readAddress = 0;
  reg [7:0] command = 8'h03; // read
  reg [7:0] currentByteOut = 0;
  reg [7:0] currentByteNum = 0;
  reg [255:0] dataIn = 0;

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
           // innerDataBuffer <= dataIn;
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