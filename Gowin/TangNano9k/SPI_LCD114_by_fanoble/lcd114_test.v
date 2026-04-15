// 1.14 inch 240x135 SPI LCD TEST for TANG NANO 9K
// by fanoble, QQ:87430545
// 27/6/2022

//`timescale 1ps/1ps

module top #(
	parameter CNT_100MS = 32'd10000,//2700000,
	parameter CNT_120MS = 32'd12000,//3240000,
	parameter CNT_200MS = 32'd20000 //5400000
)
(
	input clk, // 27M

	output reg lcd_resetn = 0,
	output lcd_clk,
	output reg lcd_cs = 1,
	output reg lcd_rs = 1,
	output lcd_data
);

reg clk2 = 0;
reg [8:0] clkDiv;
    always @(posedge clk) begin // clock prescaler
        clkDiv <= clkDiv + 1;
        if (clkDiv == 27) begin
            clk2 <= ~clk2;
            clkDiv <= 0;
        end
        // PRNG data
       // buffer <= {buffer[254:0], rbit};
    end

localparam MAX_CMDS = 16;

wire [8:0] init_cmd[MAX_CMDS:0];

assign init_cmd[ 0] = 9'h036;
assign init_cmd[ 1] = 9'h100;

assign init_cmd[ 2] = 9'h03A;
assign init_cmd[ 3] = 9'h105;

assign init_cmd[ 4] = 9'h021;

assign init_cmd[ 5] = 9'h029;

assign init_cmd[ 6] = 9'h02A; // column
assign init_cmd[ 7] = 9'h100;
assign init_cmd[ 8] = 9'h134; //52
assign init_cmd[ 9] = 9'h100;
assign init_cmd[10] = 9'h1BA; //52 + 135 - 1 = 186

assign init_cmd[11] = 9'h02B; // row
assign init_cmd[12] = 9'h100;
assign init_cmd[13] = 9'h128; //40
assign init_cmd[14] = 9'h101;
assign init_cmd[15] = 9'h117; //40 + 240 - 1 = 279

assign init_cmd[16] = 9'h02C; // start

localparam INIT_RESET   = 4'b0000; // delay 100ms while reset
localparam INIT_PREPARE = 4'b0001; // delay 200ms after reset
localparam INIT_WAKEUP  = 4'b0010; // write cmd 0x11 MIPI_DCS_EXIT_SLEEP_MODE
localparam INIT_SNOOZE  = 4'b0011; // delay 120ms after wakeup
localparam INIT_WORKING = 4'b0100; // write command & data
localparam INIT_DONE    = 4'b0101; // all done



reg [ 3:0] init_state = INIT_RESET;
reg [ 6:0] cmd_index = 0;
reg [31:0] clk_cnt = 0;
reg [ 4:0] bit_loop = 0;
reg [24:0] pixel_cnt = 0;
reg [7:0] spi_data = 8'hFF;

wire rbit;
lfsr #(
	.SEED(10'd1),
    .TAPS(10'h240),
    .NUM_BITS(10)
	) rgen(clk, rbit);

assign lcd_clk  = ~clk2;
assign lcd_data = spi_data[7]; // MSB

// gen color bar
wire [15:0] pixel = (pixel_cnt >= 21600) ? 16'hF800 :
					(pixel_cnt >= 10800) ? 16'h07EF : 16'h001F;

always@(posedge clk2) case (init_state)

	INIT_RESET : begin
		if (clk_cnt == CNT_100MS) begin
			clk_cnt <= 0;
			init_state <= INIT_PREPARE;
			lcd_resetn <= 1;
		end else begin
			clk_cnt <= clk_cnt + 1;
		end
	end

	INIT_PREPARE : begin
		if (clk_cnt == CNT_200MS) begin
			clk_cnt <= 0;
			init_state <= INIT_WAKEUP;
		end else begin
			clk_cnt <= clk_cnt + 1;
		end
	end

	INIT_WAKEUP : begin
		if (bit_loop == 0) begin
			// start
			lcd_cs <= 0;
			lcd_rs <= 0;
			spi_data <= 8'h11; // exit sleep
			bit_loop <= bit_loop + 1;
		end else if (bit_loop == 8) begin
			// end
			lcd_cs <= 1;
			lcd_rs <= 1;
			bit_loop <= 0;
			init_state <= INIT_SNOOZE;
		end else begin
			// loop
			spi_data <= { spi_data[6:0], 1'b1 };
			bit_loop <= bit_loop + 1;
		end
	end

	INIT_SNOOZE : begin
		if (clk_cnt == CNT_120MS) begin
			clk_cnt <= 0;
			init_state <= INIT_WORKING;
		end else begin
			clk_cnt <= clk_cnt + 1;
		end
	end

	INIT_WORKING : begin
		if (cmd_index == MAX_CMDS + 1) begin
			init_state <= INIT_DONE;
		end else begin
			if (bit_loop == 0) begin
				// start
				lcd_cs <= 0;
				lcd_rs <= init_cmd[cmd_index][8];
				spi_data <= init_cmd[cmd_index][7:0];
				bit_loop <= bit_loop + 1;
			end else if (bit_loop == 8) begin
				// end
				lcd_cs <= 1;
				lcd_rs <= 1;
				bit_loop <= 0;
				cmd_index <= cmd_index + 1; // next command
			end else begin
				// loop
				spi_data <= { spi_data[6:0], 1'b1 };
				bit_loop <= bit_loop + 1;
			end
		end
	end

	INIT_DONE : begin
		//if (pixel_cnt == 32400) begin
		//	; // stop
		//end else begin
		begin//
			spi_data[7] <= rbit;
			if (bit_loop == 0) begin
				// start
				lcd_cs <= 0;
				lcd_rs <= 1;
				//spi_data <= pixel_cnt[7:0];
				bit_loop <= bit_loop + 1;
			end else if (bit_loop == 8) begin
				// next byte
				//spi_data <= pixel_cnt[15:8];
				bit_loop <= bit_loop + 1;
			end else if (bit_loop == 16) begin
				// end
				lcd_cs <= 1;
				lcd_rs <= 1;
				bit_loop <= 0;//*/
				pixel_cnt <= pixel_cnt + 1; // next pixel
			end else begin
				//loop
				//spi_data <= { spi_data[6:0], 1'b1 };

				bit_loop <= bit_loop + 1;
			end
		end
	end

endcase
endmodule

module lfsr
#(
  parameter SEED = 5'd1,
  parameter TAPS = 5'h1B,
  parameter NUM_BITS = 5
)
(
    input clk,
    output reg randomBit
);
  reg [NUM_BITS-1:0] sr = SEED;

  genvar i;
  generate
    for (i = 0; i < NUM_BITS; i = i + 1) begin: lf
      wire feedback;
      if (i == 0)
        assign feedback = sr[i] & TAPS[i];
      else
       assign feedback = lf[i-1].feedback ^ (sr[i] & TAPS[i]);
    end
  endgenerate

  wire finalFeedback;
  assign finalFeedback = lf[NUM_BITS-1].feedback;

  always @(posedge clk) begin
    sr <= {sr[NUM_BITS-2:0],finalFeedback};
    randomBit <= sr[NUM_BITS-1];
  end
endmodule