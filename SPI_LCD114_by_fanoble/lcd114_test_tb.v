module test();
  reg clk = 0;
  wire lcd_clk, lcd_data, lcd_rs, lcd_resetn, lcd_cs;
  top #(32'd10, 32'd12, 32'd20) s(
      clk,
      lcd_resetn,
      lcd_clk,
      lcd_cs,
      lcd_rs,
      lcd_data
  );

  always
    #1  clk=~clk;

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
       $dumpfile("lcd114.vcd");
       $dumpvars(0, test);
      end
endmodule