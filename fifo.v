`include "dat.vh"

module fifo #(parameter WIDTH = 72, parameter FWFT = 1, parameter ALFULL = 128, parameter ALEMPTY = 128) (
	input wire rst,
	input wire rdclk,
	input wire rden,
	output wire [WIDTH - 1:0] rddata,
	
	input wire wrclk,
	input wire wren,
	input wire [WIDTH - 1:0] wrdata,
	
	output wire full,
	output wire empty,
	output wire alfull,
	output wire alempty
);

	localparam W = WIDTH <= 9 ? 9 : WIDTH <= 18 ? 18 : WIDTH <= 36 ? 36 : 72;
	localparam W8 = W * 8 / 9;
	
	wire [63:0] din, dout;
	wire [7:0] dinp, doutp;
	
	generate
		if(WIDTH > W8) begin
			assign din = wrdata[W8 - 1:0];
			assign dinp = {{W8 + 8 - WIDTH{1'b0}}, wrdata[WIDTH - 1:W8]};
			assign rddata = {doutp[WIDTH - W8 - 1:0], dout[W8 - 1:0]};
		end else begin
			assign din = {{W8 - WIDTH{1'b0}}, wrdata};
			assign dinp = 8'b0;
			assign rddata = dout[WIDTH-1:0];
		end
	endgenerate

	FIFO36E1 #(
		.DATA_WIDTH(W),
		.FIRST_WORD_FALL_THROUGH(FWFT ? "TRUE" : "FALSE"),
		.FIFO_MODE(W == 72 ? "FIFO36_72" : "FIFO36"),
		.ALMOST_FULL_OFFSET(ALFULL),
		.ALMOST_EMPTY_OFFSET(ALEMPTY)
	) fifo0(
		.RDCLK(rdclk),
		.WRCLK(wrclk),
		.DI(din),
		.DIP(dinp),
		.DO(dout),
		.DOP(doutp),
		.RDEN(rden),
		.WREN(wren),
		.FULL(full),
		.EMPTY(empty),
		.ALMOSTFULL(alfull),
		.ALMOSTEMPTY(alempty),
		.RST(rst)
	);

endmodule
