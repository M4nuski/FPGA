// init and fill Nokia 5110 LCD

module top
# (
  parameter RESET_DELAY = 16'd64000
)
(
    input clk,

    output SPI_CLK,
    input SPI_MISO,
    output SPI_MOSI,
    output reg CSn = 1,
    output reg DC = 0, // 1:data 0:command
    output reg RSTn = 0
);

reg MOSI_dataAvailable = 0;
wire MOSI_readyToRead;
reg [7:0] MOSI_data;

wire [7:0] MISO_data;
wire MISO_dataAvailable;
wire MISO_readyToRead = 0;

SPI spi (
    clk,

    SPI_CLK,
    SPI_MISO,
    SPI_MOSI,

  //axis write to SPI interface
    MOSI_dataAvailable,
    MOSI_readyToRead,
    MOSI_data,

  //axis read from SPI interface
    MISO_dataAvailable, // when 1 and clock posedge read the content of MISO_data
    MISO_readyToRead, // set to 1 to initiate read
    MISO_data
);

// reset a few ms
wire [7:0] command [4];
// send 4 commands
assign command[0] = 8'b00100000;
assign command[1] = 8'b00001100;
assign command[2] = 8'b01000000;
assign command[3] = 8'b10000000;
wire [7:0] data [8];
// send 8 data
assign data[0] = 8'b00000001;
assign data[1] = 8'b00000010;
assign data[2] = 8'b00000100;
assign data[3] = 8'b00001000;
assign data[4] = 8'b00010000;
assign data[5] = 8'b00100000;
assign data[6] = 8'b01000000;
assign data[7] = 8'b10000000;

// state machine to init and load data
localparam STATE_RESET = 0;
localparam STATE_INIT = 1;
localparam STATE_DATA = 2;
localparam STATE_SEND = 3;
localparam STATE_WAIT = 4;
localparam STATE_IDLE = 5;

reg [2:0] state = 0;
reg [2:0] nextState = 0;
reg [15:0] count = 0;

always @(posedge clk) begin
  case (state)

    STATE_RESET: begin
      if (count != RESET_DELAY) count <= count + 1; else begin
        count <= 0;
        state <= STATE_INIT;
        RSTn <= 1;
        CSn <= 0;
        DC <= 0;
      end
    end

    STATE_INIT : begin
      if (count < 4) begin
        MOSI_data <= command[count];
        count <= count + 1;
        state <= STATE_SEND;
        nextState <= STATE_INIT;
      end else begin
        count <= 0;
        state <= STATE_DATA;
        DC <= 1;
      end
    end

    STATE_DATA : begin
      if (count < 8) begin
        MOSI_data <= data[count];
        count <= count + 1;
        state <= STATE_SEND;
        nextState <= STATE_DATA;
      end else begin
        count <= 0;
        state <= STATE_IDLE;
      end
    end

    STATE_SEND : begin
      MOSI_dataAvailable <= 1;
      if (MOSI_dataAvailable & MOSI_readyToRead) begin
        MOSI_dataAvailable <= 0;
        state <= STATE_WAIT;
      end
    end

    STATE_WAIT : begin
      if (MOSI_readyToRead) state <= nextState;
    end

    STATE_IDLE : begin
      CSn <= 1;
    end

  endcase
end


endmodule