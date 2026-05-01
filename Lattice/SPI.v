// Simple SPI interface
// Serializer/Deserializer only
// CS/DC/RS/Reset signals are external

module SPI
(
  // main clock
  input clk, // SPI clock freq is clk / 2

  // pin interface
  output reg SPI_CLK = 1,
  input      SPI_MISO,
  output reg SPI_MOSI = 1,

  //axi write to SPI interface
  input       MOSI_dataAvailable,
  output reg  MOSI_readyToRead = 0,
  input [7:0] MOSI_data,

  //axi read from SPI interface
  output reg       MISO_dataAvailable = 0, // when 1 and clock posedge read the content of MISO_data
  input            MISO_readyToRead, // set to 1 to initiate read
  output reg [7:0] MISO_data = 8'b0
);

reg [3:0] bitCounter = 0;
reg [7:0] dataOut;

reg [1:0] state = 0;

localparam STATE_IDLE = 2'd0;
localparam STATE_WRITE = 2'd1;
localparam STATE_READ = 2'd2;
localparam STATE_DONE = 2'd3;

always @(posedge clk) begin
  case (state)

    STATE_IDLE: begin
      SPI_CLK <= 1;

      if (MISO_readyToRead == 1) begin // SPI read
          bitCounter <= 15;
          state <= STATE_READ;
          MOSI_readyToRead <= 0;
      end else if (MOSI_readyToRead == 0) begin // signal ready for SPI write
        MOSI_readyToRead <= 1;
      end else if (MOSI_readyToRead & MOSI_dataAvailable) begin // SPI write
        MOSI_readyToRead <= 0;
        dataOut <= MOSI_data;
        bitCounter <= 15;
        state <= STATE_WRITE;
      end
    end
      
    STATE_WRITE: begin
      if (bitCounter[0] == 1) begin
        SPI_CLK <= 0;
        SPI_MOSI <= dataOut[7];
      end else begin
        SPI_CLK <= 1;
        dataOut <= { dataOut[6:0], 1'b0 };
      end
      if (bitCounter == 0) begin
        state <= STATE_IDLE;
      end else bitCounter <= bitCounter - 1;
    end

    STATE_READ: begin
      if (bitCounter[0] == 1) begin
        SPI_CLK <= 0;
        MISO_data <= { MISO_data[6:0], 1'b0 };
      end else begin
        SPI_CLK <= 1;
        MISO_data[0] <= SPI_MISO;
      end
      if (bitCounter == 0) begin
        state <= STATE_DONE;
      end else bitCounter <= bitCounter - 1;
    end

    STATE_DONE: begin
      if ((MISO_dataAvailable == 1) && (MISO_readyToRead == 1)) begin // wait for read
        state <= STATE_IDLE;
        MISO_dataAvailable <= 0;
      end else MISO_dataAvailable <= 1; // signal data from SPI read
    end

  endcase // state
end // end posedge clk

endmodule