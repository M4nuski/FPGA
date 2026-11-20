// VGA video interface timing
// 640x480 pixels
module video_timing_480DMT (
    input PixelClk,
    input Resetn,

    output DE,
    output reg HSYNC,
    output reg VSYNC
);
    parameter H_Idle        = 1'b1;     // neg
    parameter H_Sync        = 10'd96;
    parameter H_BackPorch   = 10'd48;   // 40BackPorch + 8LeftBlank
    parameter H_Valid       = 10'd640;
    parameter H_FrontPorch  = 10'd16;   // 8RightBlank + 8FrontPorch
    parameter H_Total       = H_Sync + H_BackPorch + H_Valid + H_FrontPorch - 10'd1; // 800-1

    parameter V_Idle        = 1'b1;     // neg
    parameter V_Sync        = 10'd2;
    parameter V_BackPorch   = 10'd33;   // 25BackPorch + 8TopBlank
    parameter V_Valid       = 10'd480; 
    parameter V_FrontPorch  = 10'd10;   // 8BottomBlank + 2FrontPorch  
    parameter V_Total       = V_Sync + V_BackPorch + V_Valid + V_FrontPorch - 10'd1; // 525-1

    reg [9:0] H_Count;
    reg [9:0] V_Count;

    wire H_DE =  (H_Count >= (H_Sync + H_BackPorch)) & (H_Count < (H_Sync + H_BackPorch + H_Valid));
   // assign Pixel = DE ? (H_Count - (H_Sync + H_BackPorch) ) : 10'd0;

    wire V_DE  = (V_Count >= (V_Sync + V_BackPorch)) & (V_Count < (V_Sync + V_BackPorch + V_Valid));
    //assign Line  = DE ? (V_Count - (V_Sync + V_BackPorch)) : 10'd0;

    assign DE = H_DE && V_DE;

    always @( posedge PixelClk or negedge Resetn ) begin
        if (!Resetn) begin
            H_Count <= 10'b0;
            V_Count <= 10'b0;
            VSYNC <= V_Idle;
            HSYNC <= H_Idle;
        end else begin
            H_Count <= ( H_Count != H_Total ) ? H_Count + 10'b1 : 10'b0;
            V_Count <= ( H_Count != H_Total ) ? V_Count : (( V_Count != V_Total ) ? V_Count + 10'b1 : 10'b0);       
            VSYNC <= (V_Count < V_Sync) ? ~V_Idle : V_Idle;
            HSYNC <= (H_Count < H_Sync) ? ~H_Idle : H_Idle;
        end
    end

endmodule



// VGA video interface timing
// 1280x720 pixels
module video_timing_720DMT (
    input PixelClk,
    input Resetn,

    output DE,
    output reg HSYNC,
    output reg VSYNC
);
    parameter H_Idle        = 1'b0;     // pos
    parameter H_Sync        = 11'd40;
    parameter H_BackPorch   = 11'd220;   // BackPorch + LeftBlank
    parameter H_Valid       = 11'd1280;
    parameter H_FrontPorch  = 11'd110;   // RightBlank + FrontPorch
    parameter H_Total       = H_Sync + H_BackPorch + H_Valid + H_FrontPorch - 10'd1;

    parameter V_Idle        = 1'b1;     // neg
    parameter V_Sync        = 10'd5;
    parameter V_BackPorch   = 10'd20;   // BackPorch + TopBlank
    parameter V_Valid       = 10'd720; 
    parameter V_FrontPorch  = 10'd5;    // BottomBlank + FrontPorch  
    parameter V_Total       = V_Sync + V_BackPorch + V_Valid + V_FrontPorch - 10'd1;

    reg [10:0] H_Count;
    reg [ 9:0] V_Count;
    
    wire H_DE =  (H_Count >= (H_Sync + H_BackPorch)) & (H_Count < (H_Sync + H_BackPorch + H_Valid));
    //assign Pixel = DE ? (H_Count - (H_Sync + H_BackPorch))>>1 : 10'd0;

    wire V_DE  = (V_Count >= (V_Sync + V_BackPorch)) & (V_Count < (V_Sync + V_BackPorch + V_Valid));
    //assign Line  = DE ? (V_Count - (V_Sync + V_BackPorch))>>1 : 10'd0;

    assign DE = H_DE && V_DE;

    always @( posedge PixelClk or negedge Resetn ) begin
        if (!Resetn) begin
            H_Count <= 11'b0;
            V_Count <= 10'b0;
            VSYNC <= V_Idle;
            HSYNC <= H_Idle;
        end else begin
            H_Count <= ( H_Count != H_Total ) ? H_Count + 11'b1 : 10'b0;
            V_Count <= ( H_Count != H_Total ) ? V_Count : (( V_Count != V_Total ) ? V_Count + 10'b1 : 10'b0);       
            VSYNC <= (V_Count < V_Sync) ? ~V_Idle : V_Idle;
            HSYNC <= (H_Count < H_Sync) ? ~H_Idle : H_Idle;
        end
    end

endmodule