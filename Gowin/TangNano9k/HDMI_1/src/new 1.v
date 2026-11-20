
// 1 1, 3 3 almost
    parameter H_mode = 2'd0;
    parameter V_mode = 2'd0;

    // Vertical timing
  //  `define V_BVFS

    case (V_mode)
  //  `ifdef V_SBVF
    0: begin
     assign VSYNC = (V_Count < V_Sync) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count >= (V_Sync + V_BackPorch)) & (V_Count < (V_Sync + V_BackPorch + V_Valid));
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
     assign HSYNC = (H_Count >= (H_BackPorch + H_Valid + H_FrontPorch)) ? ~H_Idle : H_Idle;
	 assign H_DE =  (H_Count >= H_BackPorch) & (H_Count < (H_BackPorch + H_Valid));
     assign Pixel = DE ? (H_Count - H_BackPorch) : 10'd0;
end
 //   `endif
    endcase
