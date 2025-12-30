// TangNano9k 1.14 SPI LCD 
// Loads 240x135 RGB565 image from flash memory and display on LCD
// Optional PRNG data and clock divider

`timescale 1ps/1ps
module top
    #(
        parameter CLOCK_DIVIDER = 16'd27 // 100KHz
    )
    (
        // Clock
        input clk,

        // SPI LCD
        output lcd_clk,
        output lcd_mosi,
        output lcd_cs,
        output lcd_rs,
        output lcd_reset,

        // SPI Flash
        output flash_clk,
        input  flash_miso,
        output flash_mosi,
        output flash_cs,

	// Debug
        output reg port11,
        output reg port12,
        output reg port13
    );

    assign port11 = clk2;
    assign port12 = bufferDA;
    assign port13 = bufferRtR;
    
    
// clock divider
   // reg [15:0] clkDiv = 0; 
    //reg clk2 = 0;
/*
    always @(posedge clk) begin // clock prescaler
        if (clkDiv == CLOCK_DIVIDER) begin
            clk2 <= ~clk2;
            clkDiv <= 0;
        end else clkDiv <= clkDiv + 1;

        // PRNG data
      //  buffer <= {buffer[254:0], rbit};
    end
*/

    reg [255:0] buffer;
    wire bufferDA;// = 1;
    wire bufferRtR;
    //wire rbit;

    screen #() scr(
        clk,

        lcd_clk,
        lcd_mosi,
        lcd_cs,
        lcd_rs,
        lcd_reset,

        buffer,
        bufferDA,
        bufferRtR
    );
/*
    lfsr #() gen(
        clk,
        rbit
    );
*/

    flashReader #() pixGen (
        clk,
        flash_clk,
        flash_miso,
        flash_mosi,
        flash_cs,

        buffer,
        bufferDA,
        bufferRtR
    );
endmodule