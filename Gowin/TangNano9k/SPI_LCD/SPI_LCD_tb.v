module test();
  reg clk = 0;
  wire lcd_clk, lcd_mosi, lcd_cs, lcd_rs, lcd_reset;

reg [255:0] buffer = 0;
wire bufferDA = 1;
wire bufferRtR;
wire rbit;
reg clk2 = 0;

      screen #(32'd10, 32'd10) scr(
        clk2,

        lcd_clk,
        lcd_mosi,
        lcd_cs,
        lcd_rs,
        lcd_reset,

        buffer,
        bufferDA,
        bufferRtR
    );

    lfsr #() gen(
        clk,
        rbit
    );


  always begin
    #1  
    clk = ~clk;
    if (clk == 0) clk2 = ~clk2;
    // data
    buffer <= {buffer[254:0], rbit};
  end
  initial
    begin
      //  $dumpoff;
    //  #4096 
//$dumpon;
      #2048 
      #4096 

      $finish;

    end
  initial
     begin
       $dumpfile("SPI_LCD.vcd");
       $dumpvars(0, test);
      end
endmodule