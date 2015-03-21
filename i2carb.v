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
	
	input wire [7:0] adaddr,
	input wire [7:0] adwrdata,
	input wire adreq,
	input wire adwr,
	input wire adlast,
	output reg [7:0] adrddata,
	output reg adack,
	output reg aderr,
	
	output reg [7:0] gpio
);

	parameter XRAINTERVAL = 1000000;
	parameter XRAADDR = 8'h4E;
	parameter HDBUSADDR = 8'h72;
	parameter ADBUSADDR = 8'h40;

	reg [3:0] state, state_;
	localparam IDLE = 0;
	localparam HDADDR = 1;
	localparam HDDATA = 2;
	localparam HDWAITREQ = 3;
	localparam XRACMD = 4;
	localparam XRADATA = 5;
	localparam ADADDR = 6;
	localparam ADDATA = 7;
	localparam ADWAITREQ = 8;
	
	reg [31:0] xratimer;
	
	reg hderr_, sethdrddata, aderr_, setadrddata, timerstart, setgpio;
	reg [7:0] hdrddatareg, adrddatareg;
	
	initial begin
		state = IDLE;
		xratimer = 0;
	end 
	always @(posedge clk) begin
		state <= state_;
		hderr <= hderr_;
		aderr <= aderr_;
		if(sethdrddata)
			hdrddatareg <= rddata;
		if(setadrddata)
			adrddatareg <= rddata;
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
		req = 0;
		hdack = 0;
		adack = 0;
		setgpio = 0;
		hdrddata = hdrddatareg;
		sethdrddata = 0;
		adrddata = adrddatareg;
		setadrddata = 0;
		timerstart = 0;
		hderr_ = hderr;
		aderr_ = aderr;
		case(state)
		IDLE: begin
			if(hdreq) begin
				state_ = HDADDR;
				hderr_ = 0;
			end else if(adreq) begin
				state_ = ADADDR;
				aderr_ = 0;
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
		ADADDR: begin
			addr = ADBUSADDR;
			wrdata = adaddr;
			req = 1;
			if(ack)
				if(err) begin
					adack = 1;
					aderr_ = 1;
					state_ = IDLE;
				end else
					state_ = ADDATA;
		end
		ADDATA: begin
			if(adwr)
				wrdata = adwrdata;
			addr = ADBUSADDR | {7'b0, !adwr};
			last = hdlast;
			req = 1;
			if(ack)
				if(err) begin
					adack = 1;
					aderr_ = 1;
					state_ = IDLE;
				end else begin
					adack = 1;
					if(!hdwr) begin
						setadrddata = 1;
						adrddata = rddata;
					end
					state_ = adlast ? IDLE : ADWAITREQ;
				end
					
		end
		ADWAITREQ: begin
			if(adreq)
				state_ = ADDATA;
		end
		endcase
	end
endmodule
