`include "dat.vh"

module i2carb(
	input wire clk,
	
	output reg [7:0] addr,
	output reg [7:0] wrdata,
	output reg req,
	output reg last,
	input wire [7:0] rddata,
	input wire ack,
	input wire err,
	
	input wire [7:0] hdaddr,
	input wire [7:0] hdwrdata,
	input wire hdreq,
	input wire hdwr,
	input wire hdlast,
	output reg [7:0] hdrddata,
	output reg hdack,
	output reg hderr,
	
	output reg [7:0] gpio
);

	parameter XRAINTERVAL = 1000000;
	parameter XRAADDR = 8'h4E;
	parameter HDBUSADDR = 8'h72;

	reg [2:0] state, state_;
	localparam IDLE = 0;
	localparam HDADDR = 1;
	localparam HDDATA = 2;
	localparam HDWAITREQ = 3;
	localparam XRACMD = 4;
	localparam XRADATA = 5;
	
	reg [31:0] xratimer;
	
	reg sethd, hderr_, sethdrddata, timerstart, setgpio;
	reg [7:0] hdrddatareg;
	
	initial begin
		state = IDLE;
		xratimer = 0;
	end 
	always @(posedge clk) begin
		state <= state_;
		hderr <= hderr_;
		if(sethdrddata)
			hdrddatareg <= rddata;
		if(xratimer > 0)
			xratimer <= xratimer - 1;
		if(timerstart)
			xratimer <= XRAINTERVAL;
		if(setgpio)
			gpio <= rddata;
	end
	
	always @(*) begin
		state_ = state;
		addr = 0;
		wrdata = 0;
		last = 0;
		sethd = 0;
		req = 0;
		hdack = 0;
		setgpio = 0;
		hdrddata = hdrddatareg;
		sethdrddata = 0;
		timerstart = 0;
		hderr_ = hderr;
		case(state)
		IDLE: begin
			if(hdreq) begin
				state_ = HDADDR;
				hderr_ = 0;
			end else if(xratimer == 0)
				state_  = XRACMD;
		end
		HDADDR: begin
			addr = HDBUSADDR;
			wrdata = hdaddr;
			req = 1;
			if(ack)
				if(err) begin
					hderr_ = 1;
					state_ = IDLE;
				end else
					state_ = HDDATA;
		end
		HDDATA: begin
			if(hdwr)
				wrdata = hdwrdata;
			addr = HDBUSADDR | {7'b0, !hdwr};
			last = hdlast;
			req = 1;
			if(ack)
				if(err) begin
					hdack = 1;
					hderr_ = 1;
					state_ = IDLE;
				end else begin
					hdack = 1;
					if(!hdwr) begin
						sethdrddata = 1;
						hdrddata = rddata;
					end
					state_ = hdlast ? IDLE : HDWAITREQ;
				end
					
		end
		HDWAITREQ: begin
			if(hdreq)
				state_ = HDDATA;
		end
		XRACMD: begin
			addr = XRAADDR;
			wrdata = 0;
			req = 1;
			if(ack)
				if(err) begin
					state_ = IDLE;
					timerstart = 1;
				end else
					state_ = XRADATA;
		end
		XRADATA: begin
			addr = XRAADDR | 1;
			last = 1;
			req = 1;
			if(ack) begin
				setgpio = 1;
				state_ = IDLE;
				timerstart = 1;
			end
		end
		endcase
	end
endmodule
