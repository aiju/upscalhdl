`include "dat.vh"

module hdmi(
	input wire clk,
	
	output reg [7:0] hdaddr,
	output reg [7:0] hdwrdata,
	output reg hdreq,
	output reg hdwr,
	output reg hdlast,
	input wire [7:0] hdrddata,
	input wire hdack,
	input wire hderr,
	
	input wire hdclk,
	output wire hdde,
	output wire hdvs,
	output wire hdhs,
	output wire [15:0] hdx,
	output wire [15:0] hdy,
	
	output wire hdmclk,
	output wire hdsclk,
	output wire hdlrclk,
	output wire hdi2s,
	input wire hdint,
	
	output reg hdmiactive,
	input wire [7:0] gpio,
	output reg [7:0] debug
);

	localparam INITS = 12;

	reg [15:0] inits [0:INITS];
	initial begin
		inits[0] = 16'h4110;
		inits[1] = 16'h0A00;
		inits[2] = 16'h9807;
		inits[3] = 16'h9C38;
		inits[4] = 16'h9D61;
		inits[5] = 16'hA287;
		inits[6] = 16'hA387;
		inits[7] = 16'hBBFF;
		inits[8] = 16'h150A;
		inits[9] = 16'h1600;
		inits[10] = 16'h1702;
		inits[11] = 16'hAF04;
		inits[12] = 16'hBA60;
	end
	
	localparam HPDPERIOD = 1000000;
	reg [31:0] hpdtimer;
	reg hpdtick;
	always @(posedge clk) begin
		hpdtick <= 0;
		if(hpdtimer == 0) begin
			hpdtick <= 1;
			hpdtimer <= HPDPERIOD;
		end else
			hpdtimer <= hpdtimer - 1;
	end
	
	reg [3:0] ctr;
	reg resetctr, incctr, setact;
	reg loaddebug;
	always @(posedge clk) begin
		if(incctr)
			ctr <= ctr + 1;
		if(resetctr)
			ctr <= 0;
		if(setact)
			hdmiactive <= hdrddata[6];
		if(loaddebug)
			debug <= hdrddata;
	end
	
	reg [2:0] state, state_;
	localparam PDOWN = 0;
	localparam HPDCHECK = 1;
	localparam INIT = 2;
	localparam IDLE = 3;
	localparam CHECK = 4;
	
	always @(posedge clk)
		state <= state_;
	
	always @(*) begin
		state_ = state;
		hdaddr = 8'bx;
		hdwrdata = 8'bx;
		hdreq = 0;
		hdwr = 0;
		hdlast = 1;
		resetctr = 0;
		incctr = 0;
		setact = 0;
		loaddebug = 0;
		case(state)
		PDOWN:
			if(hpdtick)
				state_ = HPDCHECK;
		HPDCHECK: begin
			hdaddr = 8'h42;
			hdreq = 1;
			if(hdack) begin
				setact = 1;
				if(hdrddata[6])
					if(hdmiactive)
						state_ = CHECK;
					else begin
						state_ = INIT;
						resetctr = 1;
					end
				else
					state_ = PDOWN;
			end
		end
		INIT: begin
			hdaddr = inits[ctr][15:8];
			hdwrdata = inits[ctr][7:0];
			hdwr = 1;
			hdreq = 1;
			if(hdack) begin
				incctr = 1;
				if(ctr == INITS)
					state_ = IDLE;
			end
		end
		IDLE:
			if(hpdtick)
				state_ = HPDCHECK;
		CHECK: begin
			hdaddr = {1'b0, gpio[1], gpio[2], gpio[3], gpio[4], gpio[5], gpio[6], gpio[7]};
			hdreq = 1;
			if(hdack) begin
				loaddebug = 1;
				state_ = IDLE;
			end
		end
		endcase
	end
	
	reg [15:0] x, y;

	localparam HACT = 1280;
	localparam HFRONT = 72;
	localparam HSYNC = 80;
	localparam HBACK = 216;
	localparam VACT = 720;
	localparam VFRONT = 3;
	localparam VSYNC = 5;
	localparam VBACK = 22;

/*
	localparam HACT = 640;
	localparam HFRONT = 16;
	localparam HSYNC = 96;
	localparam HBACK = 48;
	localparam VACT = 480;
	localparam VFRONT = 10;
	localparam VSYNC = 2;
	localparam VBACK = 33;
*/
	
	localparam HSYNCON = HACT+HFRONT;
	localparam HSYNCOFF = HACT+HFRONT+HSYNC;
	localparam HTOT = HACT+HFRONT+HSYNC+HBACK;
	localparam VSYNCON = VACT+VFRONT;
	localparam VSYNCOFF = VACT+VFRONT+VSYNC;
	localparam VTOT = VACT+VFRONT+VSYNC+VBACK;
	
	
	always @(posedge hdclk)
		if(x == HTOT-1) begin
			x <= 0;
			if(y == VTOT-1)
				y <= 0;
			else
				y <= y + 1;
		end else
			x <= x + 1;
	assign hdhs = x >= HSYNCON && x < HSYNCOFF;
	assign hdvs = y >= VSYNCON && y < VSYNCOFF;
	assign hdde = x < HACT && y < HACT;
	assign hdx = x;
	assign hdy = y;
	
	assign hdmclk = 0;
	assign hdsclk = 0;
	assign hdi2s = 0;
	assign hdlrclk = 0;

endmodule
