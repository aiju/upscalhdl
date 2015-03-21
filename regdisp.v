`include "dat.vh"

module regdisp(
	input wire clk,

	input wire [7:0] regaddr,
	input wire [7:0] regdata,
	input wire regvalid,
	
	input wire hdclk,
	input wire hddein,
	output reg hdde,
	input wire [15:0] hdx,
	input wire [15:0] hdy,
	output wire [23:0] hdd
);

	wire [15:0] x = hdx - 384;
	wire [15:0] y = hdy - 104;

	reg [7:0] regmem[0:255];
	(* ram_style = "block" *) reg [127:0] font[0:255];
	
	initial $readmemh("vga.dat", font);

	always @(posedge clk)
		if(regvalid)
			regmem[regaddr] <= regdata;
	
	reg [15:0] x0, y0;
	reg dig, equal;
	reg [3:0] val;
	wire [7:0] addr = {x[8:6], y[8:4]};
	reg [7:0] data;
	
	always @(*) begin
		dig = 0;
		equal = 0;
		val = 4'bx;
		if(x < 512 && y < 512) begin
			case(x[5:3])
			0: begin
				dig = 1;
				val = addr[7:4];
			end
			1: begin
				dig = 1;
				val = addr[3:0];
			end
			2:
				equal = 1;
			3: begin
				dig = 1;
				val = data[7:4];
			end
			4: begin
				dig = 1;
				val = data[3:0];
			end
			endcase
		end
	end
	
	reg [7:0] char;
	
	always @(*) begin
		char = 0;
		if(dig)
			if(val >= 10)
				char = 8'd55 + {4'd0, val};
			else
				char = 8'd48 + {4'd0, val};
		if(equal)
			char = 8'h3d;
	end

	reg [127:0] bits;
	assign hdd = {24{bits[~{y0[3:0], x0[2:0]}]}};
	
	always @(posedge hdclk) begin
		data <= regmem[addr];
		bits <= font[char];
		hdde <= hddein;
		x0 <= x;
		y0 <= y;
	end

endmodule
