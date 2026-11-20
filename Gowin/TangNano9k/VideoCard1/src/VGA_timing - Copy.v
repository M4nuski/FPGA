// VGA interface timing
// 640x480 pixels

module VGA_timing
(
    input PixelClk,
    input Resetn,

    output DE,
    output HSYNC,
    output VSYNC,

    output wire [9:0] Pixel,
    output wire [9:0] Line
);
    parameter H_Pol         = 1'b1;     // neg
    parameter H_Sync        = 10'd96;
    parameter H_BackPorch   = 10'd48;   // 40BP + 8LB
    parameter H_Valid       = 10'd640;
    parameter H_FrontPorch  = 10'd16;   // 8RB + 8FP
    parameter H_Total       = H_Sync + H_BackPorch + H_Valid + H_FrontPorch - 10'd1; // 800

    parameter V_Pol         = 1'b1;     // neg
    parameter V_Sync        = 10'd2;
    parameter V_BackPorch   = 10'd33;   // 25BP + 8TB
    parameter V_Valid       = 10'd480; 
    parameter V_FrontPorch  = 10'd10;   // 8BB + 2FP  
    parameter V_Total       = V_Sync + V_BackPorch + V_Valid + V_FrontPorch - 10'd1; // 525

    reg [9:0] H_Count;
    reg [9:0] V_Count;

    assign HSYNC = (H_Count >= (H_BackPorch + H_Valid + H_FrontPorch)) ? ~H_Pol : H_Pol;
	assign VSYNC = (V_Count < V_Sync) ? ~V_Pol : V_Pol;

    assign DE = (H_Count >= H_BackPorch) && (H_Count < (H_BackPorch + H_Valid)) &&
                (V_Count >= (V_Sync + V_BackPorch)) && (V_Count < (V_Sync + V_BackPorch + V_Valid));

    assign Pixel = DE ? (H_Count - H_BackPorch) : 10'd0;
    assign Line  = DE ? (V_Count - V_Sync - V_BackPorch) : 10'd0;

    always @( posedge PixelClk or negedge Resetn ) begin
        if( !Resetn ) begin
            H_Count      <=  10'b0;
            V_Count      <=  10'b0;   
            end
        else if( H_Count == H_Total ) begin
            H_Count      <=  10'b0;
            V_Count      <=  V_Count + 10'b1;
            end
        else if( V_Count == V_Total ) begin
            H_Count      <=  10'b0;
            V_Count      <=  10'b0;
            end
        else begin
            H_Count      <=  H_Count + 10'b1;
            V_Count      <=  V_Count ;
        end
    end

endmodule
