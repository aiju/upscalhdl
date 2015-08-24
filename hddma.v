`include "dat.vh"

module hddma(
	input wire clk,
	input wire rst,

	output reg [22:0] memaddr,
	output wire [1:0] memlen,
	input wire [31:0] memrdata,
	output wire [31:0] memwdata,
	output reg memreq,
	output wire memwr,
	input wire memack,
	input wire memready,
	
	input wire hdclk,
	input wire [15:0] hdx,
	input wire [15:0] hdy,
	output wire [23:0] hdd
);

	localparam WIDTH = 720;
	localparam HEIGHT = 240;
	
	wire alfull;
	reg [15:0] x, y;
	reg [15:0] hctr;

	initial begin
		memaddr = 0;
		memreq = 1;
		x = 0;
		y = 0;
		hctr = 0;
	end

	assign memlen = 3;
	assign memwr = 0; 
	assign memwdata = 'bx;
	
	always @(posedge clk) begin
		if(memreq && memready) begin
			memreq <= !alfull;
			if(hctr + memlen + 1 == WIDTH)
				memaddr <= memaddr + memlen + 1 - WIDTH;
			else if(memaddr == WIDTH * HEIGHT - memlen - 1)
				memaddr <= 0;
			else
				memaddr <= memaddr + memlen + 1;
			if(hctr + memlen + 1 == 2*WIDTH)
				hctr <= 0;
			else
				hctr <= hctr + memlen + 1;
		end
		if(!alfull) begin
			memreq <= 1;
		end
		if(memack)
			if(x == WIDTH - 1) begin
				x <= 0;
				if(y == 2 * HEIGHT - 1)
					y <= 0;
				else
					y <= y + 1;
			end else
				x <= x + 1;
	end
	
	wire [63:0] fifoin = {x, y, memrdata};
	wire [63:0] fifoout;
	wire rden = fifoout[63:48] + 280 == hdx && fifoout[47:32] + 120 == hdy;
	assign hdd = rden ? fifoout[23:0] : 24'b0;
	
	fifo #(.WIDTH(64), .FWFT(1), .ALFULL(16)) fifo_i(
		.rst(rst),
		.wrclk(clk),
		.wrdata(fifoin),
		.wren(memack),
		.rdclk(hdclk),
		.rddata(fifoout),
		.rden(rden),
		.alfull(alfull),
		.empty(),
		.alempty(),
		.full()
	);

endmodule
