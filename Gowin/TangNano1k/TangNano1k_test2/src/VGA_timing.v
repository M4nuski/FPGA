module VGA_timing
(
    input PixelClk,
    input nRST,

    output LCD_DE,
    output LCD_HSYNC,
    output LCD_VSYNC,

	output [4:0] LCD_B,
	output [5:0] LCD_G,
	output [4:0] LCD_R,

    output [15:0] H,
    output [15:0] V
);
    parameter H_BackPorch   = 16'd1;// 1 20 50;
    parameter H_Pixel_Valid = 16'd480;
    parameter H_FrontPorch  = 16'd1;// 1  5 10;
    parameter H_Total       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter V_BackPorch   = 16'd30;// 1 10 30;    
    parameter V_Lines_Valid = 16'd272; 
    parameter V_FrontPorch  = 16'd10;// 1  5 10;  
    parameter V_Total       = V_Lines_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg [15:0] H_PixelCount;
    reg [15:0] V_LinesCount;

    assign H = LCD_DE ? (H_PixelCount - H_BackPorch+1) : 16'd0; // +1 to allow DFF sync through memories
    assign V = LCD_DE ? (V_LinesCount - V_BackPorch) : 16'd0;

    always @(  posedge PixelClk or negedge nRST  )begin
        if( !nRST ) begin
            H_PixelCount      <=  16'b0;
            V_LinesCount      <=  16'b0;    
            end
        else if(  H_PixelCount == H_Total ) begin
            H_PixelCount      <=  16'b0;
            V_LinesCount      <=  V_LinesCount + 1'b1;
            end
        else if(  V_LinesCount == V_Total ) begin
            H_PixelCount      <=  16'b0;
            V_LinesCount      <=  16'b0;
            end
        else begin
            H_PixelCount      <=  H_PixelCount + 1'b1;
            V_LinesCount      <=  V_LinesCount ;
        end
    end
// 42 48 1875
    // SYNC-DE MODE
   // assign LCD_HSYNC = H_PixelCount <= (H_Total - 1) ? 1'b0 : 1'b1;
	//assign LCD_VSYNC = V_LinesCount <= (V_Total - 1) ? 1'b0 : 1'b1;
// 41 46 1815
    assign LCD_HSYNC = (H_PixelCount == H_Total) ? 1'b1 : 1'b0;
	assign LCD_VSYNC = (V_LinesCount == V_Total) ? 1'b1 : 1'b0;

    assign LCD_DE = (H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                       ( V_LinesCount >= V_BackPorch ) && ( V_LinesCount <= V_Lines_Valid + V_BackPorch );

    // color bar
    localparam          Colorbar_width   =   H_Pixel_Valid / 16;

    assign  LCD_R     = ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 0  )) ? 5'b00000 :
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 1  )) ? 5'b00001 : 
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 2  )) ? 5'b00011 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 3  )) ? 5'b00111 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 4  )) ? 5'b01111 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 5  )) ? 5'b11111 :  5'b00000;

    assign  LCD_G    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 6  )) ? 6'b000001: 
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 7  )) ? 6'b000011:    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 8  )) ? 6'b000111:    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 9  )) ? 6'b001111:    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 10 )) ? 6'b011111:    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 11 )) ? 6'b111111:  6'b000000;

    assign  LCD_B    =  ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 12 )) ? 5'b00001 : 
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 13 )) ? 5'b00011 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 14 )) ? 5'b00111 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 15 )) ? 5'b01111 :    
                        ( H_PixelCount < ( H_BackPorch +  Colorbar_width * 16 )) ? 5'b11111 :  5'b00000;

endmodule
