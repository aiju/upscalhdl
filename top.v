`include "dat.vh"

module top(
	input wire clk,
	inout wire scl,
	inout wire sda,
	output reg led0,
	output reg led1,
	output reg led2,
	output reg led3
);

	reg [31:0] ctr;

	always @(posedge clk)
		if(ctr >= 100000000) begin
			led0 <= !led0;
			ctr <= 0;
		end else
			ctr <= ctr + 1;
endmodule
