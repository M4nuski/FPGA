module test();

    reg clk=0;
    reg resetn=1;

    wire    LCD_HYNC;
   wire     LCD_SYNC;
    wire    LCD_DEN;
	wire	[4:0]	LCD_R;
	wire	[5:0]	LCD_G;
	wire	[4:0]	LCD_B;
    wire [15:0] H;
    wire [15:0] V;


    always begin
        #1 clk <= ~clk;
    end

    VGA_timing t (

     clk,
    resetn,

    LCD_DEN,
    LCD_HSYNC,
    LCD_VSYNC,

	LCD_B,
	LCD_G,
	LCD_R,

    H,
    V
    );
  initial
    begin
      //  $dumpoff;
    //  #4096 
//$dumpon;
#10
resetn <= 1'b0;
#10
resetn <= 1'b1;

      #(800*600*2)
      #4096 

      $finish;
    end
  initial
     begin
       $dumpfile("VGA.vcd");
       $dumpvars(0, test);
      end
endmodule