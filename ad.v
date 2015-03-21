`include "dat.vh"

module ad(
	input wire clk,
	
	output reg [7:0] adaddr,
	output reg [7:0] adwrdata,
	output reg adreq,
	output reg adwr,
	output reg adlast,
	input wire [7:0] adrddata,
	input wire adack,
	input wire aderr,
	
	output wire [7:0] regaddr,
	output wire [7:0] regdata,
	output reg regvalid
);
	localparam INITS = 35;

	reg [15:0] inits [0:INITS];
	initial begin
		inits[0] = 16'h0001;
		inits[1] = 16'h030C;
		inits[2] = 16'h0477;
		inits[3] = 16'h1741;
		inits[4] = 16'h1D47;
		inits[5] = 16'h3102;
		inits[6] = 16'h3A17;
		inits[7] = 16'h3B81;
		inits[8] = 16'h3DA2;
		inits[9] = 16'h3E6A;
		inits[10] = 16'h3FA0;
		inits[11] = 16'h860B;
		inits[12] = 16'hF301;
		inits[13] = 16'hF903;
		inits[14] = 16'h0E80;
		inits[15] = 16'h5246;
		inits[16] = 16'h5400;
		inits[17] = 16'h7FFF;
		inits[18] = 16'h8130;
		inits[19] = 16'h90C9;
		inits[20] = 16'h9140;
		inits[21] = 16'h923C;
		inits[22] = 16'h93CA;
		inits[23] = 16'h94D5;
		inits[24] = 16'hB1FF;
		inits[25] = 16'hB608;
		inits[26] = 16'hC09A;
		inits[27] = 16'hCF50;
		inits[28] = 16'hD04E;
		inits[29] = 16'hD1B9;
		inits[30] = 16'hD6DD;
		inits[31] = 16'hD7E2;
		inits[32] = 16'hE551;
		inits[33] = 16'hF63B;
		inits[34] = 16'h0E00;
		inits[35] = 16'h6903;
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
	
	reg [7:0] ctr;
	reg incctr, clrctr, setact;
	always @(posedge clk) begin
		if(incctr)
			ctr <= ctr + 1;
		if(clrctr)
			ctr <= 0;
	end
	
	reg [2:0] state, state_;
	localparam INIT = 0;
	localparam IDLE = 1;
	localparam CHECK = 2;
	
	always @(posedge clk)
		state <= state_;
	
	always @(*) begin
		state_ = state;
		adaddr = 8'bx;
		adwrdata = 8'bx;
		adreq = 0;
		adwr = 0;
		adlast = 1;
		incctr = 0;
		clrctr = 0;
		setact = 0;
		regvalid = 0;
		case(state)
		INIT: begin
			adaddr = inits[ctr][15:8];
			adwrdata = inits[ctr][7:0];
			adwr = 1;
			adreq = 1;
			if(adack) begin
				incctr = 1;
				if(ctr == INITS)
					state_ = IDLE;
			end
		end
		IDLE:
			if(hpdtick) begin
				clrctr = 1;
				state_ = CHECK;
			end
		CHECK: begin
			adaddr = ctr;
			adlast = ctr == 255;
			adreq = 1;
			if(adack) begin
				regvalid = 1;
				incctr = 1;
				if(ctr == 255)
					state_ = IDLE;
			end
		end
		endcase
	end
	
	assign regaddr = adaddr;
	assign regdata = adrddata;
	
	initial begin
		ctr = 0;
		state = INIT;
	end

endmodule