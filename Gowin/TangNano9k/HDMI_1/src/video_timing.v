// VGA video interface timing
// 640x480 pixels

module video_timing (
    input PixelClk,
    input Resetn,

    output DE,
    output HSYNC,
    output VSYNC,

    output wire [9:0] Pixel,
    output wire [9:0] Line
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

    wire V_DE;
    wire H_DE;
    assign DE = H_DE && V_DE;   

// 1 1, 3 3 almost
    parameter H_mode = 2'd0;
    parameter V_mode = 2'd0;

    // Vertical timing
  //  `define V_BVFS

    case (V_mode)
  //  `ifdef V_SBVF
    0: begin
     assign VSYNC = (V_Count < V_Sync) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count >= (V_Sync + V_BackPorch)) && (V_Count < (V_Sync + V_BackPorch + V_Valid));
     assign Line  = DE ? (V_Count - (V_Sync + V_BackPorch)) : 10'd0;
end
    1:begin
   //`elsif V_FSBV
     assign VSYNC = (V_Count >= V_FrontPorch) && (V_Count < (V_FrontPorch + V_Sync)) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count >= (V_FrontPorch + V_Sync + V_BackPorch));
     assign Line  = DE ? (V_Count - (V_FrontPorch + V_Sync + V_BackPorch)) : 10'd0;
end
    2:begin
 //  `elsif V_VFSB
     assign VSYNC = (V_Count >= (V_Valid + V_FrontPorch)) && (V_Count < (V_Valid + V_FrontPorch + V_Sync)) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count < V_Valid);
     assign Line  = DE ? (V_Count) : 10'd0;
end
    3:begin
  // `elsif V_BVFS
     assign VSYNC = (V_Count >= (V_BackPorch + V_Valid + V_FrontPorch)) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count >= V_BackPorch) && (V_Count < (V_BackPorch + V_Valid));
     assign Line  = DE ? (V_Count - V_BackPorch) : 10'd0;
end
 //   `endif
    endcase

    // Horizontal timing
   // `define H_BVFS
    case (H_mode)
    0:begin
  //  `ifdef H_SBVF
    //  S B V F - fine on all except small monitor
     assign HSYNC = (H_Count < H_Sync) ? ~H_Idle : H_Idle;
     assign H_DE =  (H_Count >= (H_Sync + H_BackPorch)) && (H_Count < (H_Sync + H_BackPorch + H_Valid));
     assign Pixel = DE ? (H_Count - (H_Sync + H_BackPorch) ) : 10'd0;
end
    1:begin
  //  `elsif H_FSBV
    //  F S B V - fine on all except small monitor
     assign HSYNC = (H_Count >= H_FrontPorch) && (H_Count < (H_FrontPorch + H_Sync)) ? ~H_Idle : H_Idle;
	 assign H_DE =  (H_Count >= (H_FrontPorch + H_Sync + H_BackPorch));
     assign Pixel = DE ? (H_Count - (H_FrontPorch + H_Sync + H_BackPorch)) : 10'd0;
end
    2:begin
   // `elsif H_VFSB
    //  V F S B - fine on all except small monitor
     assign HSYNC = (H_Count >= (H_Valid + H_FrontPorch)) && (H_Count < (H_Valid + H_FrontPorch + H_Sync)) ? ~H_Idle : H_Idle;
	 assign H_DE =  (H_Count < H_Valid);
     assign Pixel = DE ? (H_Count) : 10'd0;
end
    3:begin
  //  `elsif H_BVFS
    //  B V F S - fine on all except small monitor
     assign HSYNC = (H_Count >= H_BackPorch + H_Valid + H_FrontPorch) ? ~H_Idle : H_Idle;
	 assign H_DE =  (H_Count >= H_BackPorch) && (H_Count < (H_BackPorch + H_Valid));
     assign Pixel = DE ? (H_Count - H_BackPorch) : 10'd0;
end
 //   `endif
    endcase

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

