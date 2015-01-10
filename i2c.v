`include "dat.vh"

module i2c(
	input wire clk,
	inout reg scl,
	inout reg sda,
	
	input wire [7:0] addr,
	input wire [7:0] wrdata,
	input wire req,
	input wire last,
	output reg [7:0] rddata,
	output reg ack,
	output reg err
);

	parameter STARTTIME = 1000;
	parameter QUARTBIT = 500;

	reg [2:0] state, state_;
	localparam IDLE = 0;
	localparam START = 1;
	localparam ADDR = 2;
	localparam ADDRACK = 3;
	localparam DATA = 4;
	localparam DATAACK = 5;
	localparam WAITREQ = 6;
	
	reg [7:0] curaddr;
	reg [7:0] sr;
	reg [15:0] timer;
	reg [2:0] ctr;
	reg starttime, bittime, startbit, clrctr, loadaddr, loadrdata, loaddata, shift, err_;
	
	always @(posedge clk) begin
		state <= state_;
		err <= err_;
		if(timer > 0)
			timer <= timer - 1;
		if(starttime)
			timer <= STARTTIME;
		if(bittime)
			timer <= 4*QUARTBIT;
		if(clrctr)
			ctr <= 0;
		if(incctr)
			ctr <= ctr + 1;
		if(loadaddr) begin
			curaddr <= addr;
			sr <= addr;
		end
		if(loaddata && !curaddr[0])
			sr <= wrdata;
		if(shift)
			sr <= {sr[6:0], sda};
	end
	
	always @(*) begin
		state_ = state;
		err_ = err;
		scl = 1;
		sda = 1'bz;
		starttime = 0;
		bittime = 0;
		ack = 0;
		err = 0;
		clrctr = 0;
		incctr = 0;
		loadaddr = 0;
		loaddata = 0;
		shift = 0;
		case(state)
		IDLE:
			if(req) begin
				err_ = 0;
				state_ = START;
				starttime = 1;
			end
		START: begin
			sda = 0;
			if(timer == 0) begin
				state_ = ADDR;
				loadaddr = 1;
				clrctr = 0;
				bittime = 1;
			end
		end
		ADDR: begin
			sda = sr[7] ? 1'bz : 0;
			shift = timer == 3*QUARTBIT;
			scl = timer < 2*QUARTBIT;
			if(timer == 0) begin
				if(ctr == 7)
					state_ = ADDRACK;
				incctr = 1;
				bittime = 1;
			end
		end
		ADDRACK: begin
			scl = timer < 2*QUARTBIT;
			if(timer == 0) begin
				if(sda) begin
					starttime = 1;
					state_ = STOP;
					err_ = 1;
				end else begin
					state_ = DATA;
					loaddata = 1;
					bittime = 1;
				end
			end
		end
		DATA: begin
			if(curaddr[0])
				shift = timer == QUARTBIT
			else begin
				sda = sr[7] ? 1'bz : 0;
				shift = timer == 3*QUARTBIT;
			end
			if(timer == 0) begin
				bittime = 1;
				incctr = 1;
				if(ctr == 7)
					state_ = DATAACK;
			end 
		end
		DATAACK: begin
			scl = timer < 2*QUARTBIT;
			if(curaddr[0])
				sda = 0;
			if(timer == 0) begin
				if(!curaddr[0] && sda || last) begin
					err_ = !curaddr[0] && sda;
					starttime = 1;
					state_ = STOP;
				end else begin
					ack = 1;
					state_ = WAITREQ;
				end
			end
		end
		WAITREQ:
			if(req) begin
				if(addr != curaddr) begin
					starttime = 1;
					state_ = START;
				end else begin
					bittime = 1;
					loaddata = 1;
					state_ = DATA;
				end
			end
		endcase
	end
endmodule
