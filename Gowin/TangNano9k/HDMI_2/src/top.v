module top(
  input clk,
  input resetn,

  output       tmds_clk_n,
  output       tmds_clk_p,
  output [2:0] tmds_d_n,
  output [2:0] tmds_d_p
);

// 27MHz to 371.25MHz // 126MHz
Gowin_rPLL_27_371p25 u_pll (
  .clkin(clk),
  .clkout(clk_p5),
  .lock(pll_lock)
);

// 126MHz to 74.25MHz // 25.2MHz
Gowin_CLKDIV u_div_5 (
    .clkout(clk_p),
    .hclkin(clk_p5),
    .resetn(pll_lock)
);

wire [9:0] video_col, video_line;
reg [7:0] video_r, video_g, video_b;

video_timing_720DMT videoGen (
    .PixelClk(clk_p),
    .Resetn(pll_lock),

    .DE(video_de),
    .HSYNC(video_hs),
    .VSYNC(video_vs),

    .Pixel(video_col),
    .Line(video_line)
);

reg[7:0] out_r, out_g, out_b;
// test pattern
//assign video_r = (((video_col  == 0  ) | (video_col  == 639)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
//assign video_g = (((video_line == 0  ) | (video_line == 359)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
//assign video_b = (((video_col  == 320) | (video_line == 180)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
//assign video_g = (((video_line == 0  ) | (video_line == 479)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
//assign video_b = (((video_col  == 320) | (video_line == 240)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;

reg [1:0] ctrlFF, ctrl_out;
reg de_out, deFF;

always @(posedge clk_p) begin
    ctrlFF <= {video_vs, video_hs};
    ctrl_out <= ctrlFF;
    deFF <= video_de;
    de_out <= deFF;
    video_r <= (((video_col  == 0  ) | (video_col  == 639)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
    video_g <= (((video_line == 0  ) | (video_line == 359)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
    video_b <= (((video_col  == 320) | (video_line == 180)) ? 8'hFF : 8'h00) | (video_col[4] ^ video_line[4])<<6;
    out_r <= video_r;
    out_g <= video_g;
    out_b <= video_b;
end
// DVI/HDMI tmds encoder

	wire [2:0] tmds_d0, tmds_d1, tmds_d2, tmds_d3, tmds_d4;
	wire [2:0] tmds_d5, tmds_d6, tmds_d7, tmds_d8, tmds_d9;
    wire [2:0] tmds_d;

	svo_tmds svo_tmds_0 (
		.clk(clk_p),
		.resetn(pll_lock),
		.de(de_out),
		.ctrl(ctrl_out),
		.din(out_b),
		.dout({tmds_d9[0], tmds_d8[0], tmds_d7[0], tmds_d6[0], tmds_d5[0],
		       tmds_d4[0], tmds_d3[0], tmds_d2[0], tmds_d1[0], tmds_d0[0]})
	);

	svo_tmds svo_tmds_1 (
		.clk(clk_p),
		.resetn(pll_lock),
		.de(de_out),
		.ctrl(2'b0),
		.din(out_g),
		.dout({tmds_d9[1], tmds_d8[1], tmds_d7[1], tmds_d6[1], tmds_d5[1],
		       tmds_d4[1], tmds_d3[1], tmds_d2[1], tmds_d1[1], tmds_d0[1]})
	);

	svo_tmds svo_tmds_2 (
		.clk(clk_p),
		.resetn(pll_lock),
		.de(de_out),
		.ctrl(2'b0),
		.din(out_r),
		.dout({tmds_d9[2], tmds_d8[2], tmds_d7[2], tmds_d6[2], tmds_d5[2],
		       tmds_d4[2], tmds_d3[2], tmds_d2[2], tmds_d1[2], tmds_d0[2]})
	);
    
	OSER10 tmds_serdes [2:0] (
		.Q(tmds_d),
		.D0(tmds_d0),
		.D1(tmds_d1),
		.D2(tmds_d2),
		.D3(tmds_d3),
		.D4(tmds_d4),
		.D5(tmds_d5),
		.D6(tmds_d6),
		.D7(tmds_d7),
		.D8(tmds_d8),
		.D9(tmds_d9),
		.PCLK(clk_p),
		.FCLK(clk_p5),
		.RESET(~pll_lock)
	);
	
	ELVDS_OBUF tmds_bufds [3:0] (
		.I({clk_p, tmds_d}),
		.O({tmds_clk_p, tmds_d_p}),
		.OB({tmds_clk_n, tmds_d_n})
	);




endmodule


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
    parameter H_Idle        = 1'b0;     // neg
    parameter H_Sync        = 10'd96;
    parameter H_BackPorch   = 10'd48;   // 40BackPorch + 8LeftBlank
    parameter H_Valid       = 10'd640;
    parameter H_FrontPorch  = 10'd16;   // 8RightBlank + 8FrontPorch
    parameter H_Total       = H_Sync + H_BackPorch + H_Valid + H_FrontPorch - 10'd1; // 800-1

    parameter V_Idle        = 1'b0;     // neg
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
    parameter H_mode = 2'd3;
    parameter V_mode = 2'd3;

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
 // NOT GOOD DO NOT USE
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



// VGA video interface timing
// 640x480 pixels
module video_timing_720DMT (
    input PixelClk,
    input Resetn,

    output DE,
    output HSYNC,
    output VSYNC,

    output wire [9:0] Pixel, // bin 2
    output wire [9:0] Line // bin 2
);
    parameter H_Idle        = 1'b0;     // pos
    parameter H_Sync        = 11'd40;
    parameter H_BackPorch   = 11'd220;   // 40BackPorch + 8LeftBlank
    parameter H_Valid       = 11'd1280;
    parameter H_FrontPorch  = 11'd110;   // 8RightBlank + 8FrontPorch
    parameter H_Total       = H_Sync + H_BackPorch + H_Valid + H_FrontPorch - 11'd1; // 800-1

    parameter V_Idle        = 1'b0;     // pos
    parameter V_Sync        = 11'd5;
    parameter V_BackPorch   = 11'd20;   // 25BackPorch + 8TopBlank
    parameter V_Valid       = 11'd720; 
    parameter V_FrontPorch  = 11'd5;   // 8BottomBlank + 2FrontPorch  
    parameter V_Total       = V_Sync + V_BackPorch + V_Valid + V_FrontPorch - 11'd1; // 525-1

    reg [10:0] H_Count;
    reg [10:0] V_Count;

    wire V_DE;
    wire H_DE;
    assign DE = H_DE && V_DE;

     // V_BVFS
     assign VSYNC = (V_Count >= (V_BackPorch + V_Valid + V_FrontPorch)) ? ~V_Idle : V_Idle;
     assign V_DE  = (V_Count >= V_BackPorch) && (V_Count < (V_BackPorch + V_Valid));
     assign Line  = DE ? (V_Count - V_BackPorch)>>1 : 10'd0;

     // H_BVFS
     assign HSYNC = (H_Count >= H_BackPorch + H_Valid + H_FrontPorch) ? ~H_Idle : H_Idle;
	 assign H_DE =  (H_Count >= H_BackPorch) && (H_Count < (H_BackPorch + H_Valid));
     assign Pixel = DE ? (H_Count - H_BackPorch)>>1 : 10'd0;

   // NOT GOOD DO NOT USE
    always @( posedge PixelClk or negedge Resetn ) begin
        if( !Resetn ) begin
            H_Count      <=  11'b0;
            V_Count      <=  11'b0;   
            end
        else if( H_Count == H_Total ) begin
            H_Count      <=  11'b0;
            V_Count      <=  V_Count + 11'b1;
            end
        else if( V_Count == V_Total ) begin
            H_Count      <=  11'b0;
            V_Count      <=  11'b0;
            end
        else begin
            H_Count      <=  H_Count + 11'b1;
            V_Count      <=  V_Count ;
        end
    end

endmodule

module svo_tmds (
	input clk, resetn, de,
	input [1:0] ctrl,
	input [7:0] din,
	output reg [9:0] dout
);
   // assign dout = q_out;

	// Variable and function names below match the spec names for
	// better readability when comparing to spec encoder flow diagram.
	wire [7:0] D = din;

	function [3:0] N1;
		// Count the number of '1' bits.
		input [7:0] bits;
		integer i;
		begin
			N1 = 0;
			for (i = 0; i < 8; i = i+1)
				N1 = N1 + bits[i];
		end
	endfunction

	function [3:0] N0;
		// Count the number of '0' bits.
		input [7:0] bits;
		integer i;
		begin
			N0 = 0;
			for (i = 0; i < 8; i = i+1)
				N0 = N0 + !bits[i];
		end
	endfunction

	reg [9:0] dout_buf2, q_out, q_out_next;
	reg [3:0] N0_q_m, N1_q_m;
	reg signed [7:0] cnt, cnt_next, cnt_tmp;
	reg [8:0] q_m;

	always @(posedge clk) begin
		if (!resetn) begin
			cnt   <= 0; // Data stream disparity count used for DC balance
			q_out <= 0;
		end else if (!de) begin
			cnt   <= 0; // Reset disaprity when not actively displaying
			case (ctrl) // See spec section "Control Period Coding"
				2'b00: q_out <= 10'b1101010100;
				2'b01: q_out <= 10'b0010101011;
				2'b10: q_out <= 10'b0101010100;
				2'b11: q_out <= 10'b1010101011;
			endcase
		end else begin
			// See spec flow diagram in section "Video Data Coding"
			if ((N1(D) > 4) | ((N1(D) == 4) & (D[0] == 0))) begin
				q_m[0] =           D[0];
				q_m[1] = q_m[0] ^~ D[1];
				q_m[2] = q_m[1] ^~ D[2];
				q_m[3] = q_m[2] ^~ D[3];
				q_m[4] = q_m[3] ^~ D[4];
				q_m[5] = q_m[4] ^~ D[5];
				q_m[6] = q_m[5] ^~ D[6];
				q_m[7] = q_m[6] ^~ D[7];
				q_m[8] = 1'b0;
			end
			else begin
				q_m[0] =          D[0];
				q_m[1] = q_m[0] ^ D[1];
				q_m[2] = q_m[1] ^ D[2];
				q_m[3] = q_m[2] ^ D[3];
				q_m[4] = q_m[3] ^ D[4];
				q_m[5] = q_m[4] ^ D[5];
				q_m[6] = q_m[5] ^ D[6];
				q_m[7] = q_m[6] ^ D[7];
				q_m[8] = 1'b1;
			end

			N0_q_m = N0(q_m[7:0]);
			N1_q_m = N1(q_m[7:0]);

			if ((cnt == 0) | (N1_q_m == N0_q_m)) begin
				q_out_next[9]    = ~q_m[8];
				q_out_next[8]    =  q_m[8];
				q_out_next[7:0]  = (q_m[8] ? q_m[7:0] : ~q_m[7:0]);
				if (q_m[8] == 0) begin
					cnt_next = cnt + (N0_q_m - N1_q_m);
				end else begin
					cnt_next = cnt + (N1_q_m - N0_q_m);
				end
			end else if (((cnt > 0) & (N1_q_m > N0_q_m)) | (((cnt < 0) & (N0_q_m > N1_q_m)))) begin
				q_out_next[9]    =  1'b1;
				q_out_next[8]    =  q_m[8];
				q_out_next[7:0]  = ~q_m[7:0];
				cnt_tmp          = cnt + (N0_q_m - N1_q_m);
				if (q_m[8]) begin
					cnt_next = cnt_tmp + 2'h2;
				end else begin
					cnt_next = cnt_tmp;
				end
			end else begin
				q_out_next[9]    =  1'b0;
				q_out_next[8]    =  q_m[8];
				q_out_next[7:0]  =  q_m[7:0];
				cnt_tmp          = cnt + (N1_q_m - N0_q_m);
				if (q_m[8]) begin
					cnt_next = cnt_tmp;
				end else begin
					cnt_next = cnt_tmp - 2'h2;
				end
			end
			cnt   <= cnt_next;
			q_out <= q_out_next;
		end

		// add two additional ff stages, give synthesis retime some slack to work with
		dout_buf2 <= q_out;
		dout <= dout_buf2;

	end
endmodule
