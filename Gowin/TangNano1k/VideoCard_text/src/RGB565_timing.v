// RGB565 interface timing
// 480x272 pixels

module RGB565_timing
(
    input PixelClk,
    input nRST,

    output LCD_DE,
    output LCD_HSYNC,
    output LCD_VSYNC,

    output [9:0] H, //todo switch to 10 bit : max is 1023 (640x480)
    output [9:0] V
);
    parameter H_BackPorch   = 10'd2;// 1 27 50;
    parameter H_Pixel_Valid = 10'd480;
    parameter H_FrontPorch  = 10'd2;// 1  5 10;
    parameter H_Total       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter V_BackPorch   = 10'd2;// 1 15 30;    
    parameter V_Lines_Valid = 10'd272; 
    parameter V_FrontPorch  = 10'd2;// 1  6 10;  
    parameter V_Total       = V_Lines_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg [9:0] H_PixelCount;
    reg [9:0] V_LinesCount;

    assign H = LCD_DE ? (H_PixelCount - H_BackPorch) : 10'd0; // +1 to allow DFF sync through memories
    assign V = LCD_DE ? (V_LinesCount - V_BackPorch) : 10'd0;

    always @(  posedge PixelClk or negedge nRST  )begin
        if( !nRST ) begin
            H_PixelCount      <=  10'b0;
            V_LinesCount      <=  10'b0;   
            end
        else if(  H_PixelCount == H_Total ) begin
            H_PixelCount      <=  10'b0;
            V_LinesCount      <=  V_LinesCount + 1'b1;
            end
        else if(  V_LinesCount == V_Total ) begin
            H_PixelCount      <=  10'b0;
            V_LinesCount      <=  10'b0;
            end
        else begin
            H_PixelCount      <=  H_PixelCount + 1'b1;
            V_LinesCount      <=  V_LinesCount ;
        end
    end

    assign LCD_HSYNC = (H_PixelCount == H_Total) ? 1'b1 : 1'b0;
	assign LCD_VSYNC = (V_LinesCount == V_Total) ? 1'b1 : 1'b0;

    assign LCD_DE = (H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                       ( V_LinesCount >= V_BackPorch ) && ( V_LinesCount <= V_Lines_Valid + V_BackPorch );

endmodule
