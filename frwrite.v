`include "dat.vh"

module frwrite(
	input wire clk,
	
	output reg [22:0] memaddr,
	output wire [31:0] memwdata,
	output reg memreq,
	output wire memwr,
	output wire [1:0] memlen,
	input wire memack,
	input wire memready
);

	localparam W = 720;
	localparam H = 480;

	reg [11:0] x, y;
	
	initial begin
		x = 0;
		y = 0;
		memaddr = 0;
		memreq = 1;
	end
	assign memwr = 1;
	assign memlen = 3;
	assign memwdata = x < 180 ? 32'h00000000 : x < 360 ? 32'h00aa0000 : x < 540 ? 32'h0000cc00 : 32'h000000ff;
//	wire [15:0] x16 = x;
//	assign memwdata = {~x16, x16};

	always @(posedge clk) begin
		if(memreq && memready) begin
			memaddr <= memaddr + 4;
			if(memaddr == W * H - 4) begin
				memaddr <= 0;
				memreq <= 0;
			end
		end
	
		if(memack) begin
			if(x == W - 1) begin
				x <= 0;
				if(y == H - 1)
					y <= 0;
				else
					y <= y + 1;
			end else
				x <= x + 1;
		end
		
	end

endmodule
