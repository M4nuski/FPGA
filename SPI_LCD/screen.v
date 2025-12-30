`default_nettype none

module screen
    #(
        parameter STARTUP_WAIT = 32'd2700000, // 100ms * 3 spi_reset line pulse
        parameter RESET_WAIT =   32'd5400000 // 200ms
    )
    (
        input t_clk,

        output reg spi_mclk = 0,
        output reg spi_mosi = 1,
        output reg spi_cs = 1,
        output reg spi_rs = 1,
        output reg spi_reset = 0, 

        input [255:0] buffer,
        input bufferDA,
        output reg bufferRtR = 0
    );

    // state machine constants
    localparam STATE_INIT_POWER = 0;
    localparam STATE_INIT_SEND_RESET = 1;
    localparam STATE_INIT_WAIT = 2;
    localparam STATE_LOAD_INIT_CMD = 3;
    localparam STATE_SEND = 4;
    localparam STATE_CHECK_FINISHED_INIT = 5;
    localparam STATE_LOAD_DATA = 6;
    localparam STATE_STOP = 7;

    reg [ 3:0] state = 0; // 0-15
    reg [31:0] counter = 0; // 0-64K
    reg [15:0] pixelCounter = 0; // 0-64K
    reg [ 5:0] pixelDataCounter = 32; // 0-63

    reg [ 7:0] dataToSend = 0; // 0-255
    reg [ 2:0] bitNumber = 0; // 0-7 

    reg [ 4:0] commandIndex = 0; // 0-31
    localparam SETUP_INSTRUCTIONS = 17;
    wire [ 8:0] startupCommands[SETUP_INSTRUCTIONS-1:0];
    reg [255:0] pixels;

    assign startupCommands[ 0] = 9'h036;  //madctl, with hdmi facing left
    assign startupCommands[ 1] = 9'h1A0; // 100:t-b r-l 120:r-l, t-b, 180:t-b l-r

    assign startupCommands[ 2] = 9'h03A;  //colmod
    assign startupCommands[ 3] = 9'h105; //16bpp

    assign startupCommands[ 4] = 9'h021; // 21:inverted colors
    assign startupCommands[ 5] = 9'h029;  //dispon

    assign startupCommands[ 6] = 9'h02A;  //caset
    assign startupCommands[ 7] = 9'h100;
    assign startupCommands[ 8] = 9'h128;
    assign startupCommands[ 9] = 9'h101;
    assign startupCommands[10] = 9'h117;

    assign startupCommands[11] = 9'h02B;  //raset
    assign startupCommands[12] = 9'h100;
    assign startupCommands[13] = 9'h134;
    assign startupCommands[14] = 9'h100;
    assign startupCommands[15] = 9'h1BE;

    // ramwrite
    assign startupCommands[16] = 9'h02C; //ramr
    //reg [7:0] screenBuffer [64800:0];
    //initial $readmemh("logo.txt", screenBuffer);//, 0, 64800);

// state machine definition
always @(posedge t_clk) begin

  case (state)
    STATE_INIT_POWER: begin
      counter <= counter + 1;
      if (counter < STARTUP_WAIT) begin
      // spi_mclk <= counter[0];
        spi_reset <= 0;
      end else if (counter < STARTUP_WAIT * 2)  begin
      //  spi_mclk <= counter[0];
        spi_reset <= 1;
      end
      else begin
        state <= STATE_INIT_SEND_RESET;
      //  spi_cs <= 0;
        spi_rs <= 0;
        dataToSend <= 8'h11;
        bitNumber <= 7;
        counter <= 0;
      end
    end

    STATE_INIT_SEND_RESET: begin
      spi_cs <= 0;
      if (counter == 0) begin
        spi_mclk <= 0;
        spi_mosi <= dataToSend[bitNumber];
        counter <= 1;
      end
      else begin
        counter <= 0;
        spi_mclk <= 1;
        if (bitNumber == 0) begin
          state <= STATE_INIT_WAIT;
        end else
          bitNumber <= bitNumber - 1;
      end
    end

    STATE_INIT_WAIT: begin
      spi_cs <= 1;
    //  spi_mclk <= counter[0];
      spi_mclk <= 0;
      if (counter == RESET_WAIT) 
          state <= STATE_LOAD_INIT_CMD;
      else 
          counter <= counter + 1;
    end
  
    STATE_LOAD_INIT_CMD: begin
      state <= STATE_SEND; 
      //spi_cs <= 0;
      spi_rs <= startupCommands[commandIndex][8];
      dataToSend <= startupCommands[commandIndex][7:0];
      bitNumber <= 7;
      counter <= 0;
      spi_mclk <= 1;
      commandIndex <= commandIndex + 1;
    end

    STATE_SEND: begin
      spi_cs <= 0;
      if (counter == 0) begin
        counter <= 1;
        spi_mclk <= 0;
        spi_mosi <= dataToSend[bitNumber];
      end
      else begin
        counter <= 0;
        spi_mclk <= 1;
        if (bitNumber == 0)
          state <= STATE_CHECK_FINISHED_INIT;
        else
          bitNumber <= bitNumber - 1;
      end
    end

    STATE_CHECK_FINISHED_INIT: begin
      spi_cs <= 1;
      spi_mclk <= 0;
      if (commandIndex == SETUP_INSTRUCTIONS) begin
        state <= STATE_LOAD_DATA; 
      end else begin
      //  counter <= 0;
        state <= STATE_LOAD_INIT_CMD;
      end
    end

    STATE_LOAD_DATA: begin
      spi_rs <= 1;
      spi_mclk <= 1;

      if (pixelDataCounter == 31) bufferRtR <= 1; // request more data

      if (pixelDataCounter == 32) begin // wait for DA and fill buffer
        if (bufferDA == 1) begin
          pixels <= buffer;
          bufferRtR <= 0;
          pixelDataCounter <= 0;
        end
      end else if (pixelCounter != 64800) begin // 64800 , 30720
        pixelCounter <= pixelCounter + 1;
        pixelDataCounter <= pixelDataCounter + 1;
        bitNumber <= 7;
        counter <= 0;
        state <= STATE_SEND;
        dataToSend <= buffer[(pixelDataCounter*8)+7 -:8];
      end// state <= STATE_LOAD_DATA+1;

    end

  endcase
end

endmodule

