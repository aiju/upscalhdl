`include "dat.vh"

module memphy(
	input wire clk,
	
	output reg [31:0] ddrdqi,
	input wire [31:0] ddrdqo,
	input wire ddrdqt,
	input wire [1:0] ddrdmo,
	
	output wire ddrckp,
	output wire ddrckn,
	inout wire [15:0] ddrdq,
	output reg [1:0] ddrdm,
	
	input wire ddrdqsclk,
	input wire ddrdqszero,
	inout wire [1:0] ddrdqs
);

	wire clk90;

	genvar i;
	reg ddrdqtd;
	wire [15:0] ddrdqi0n, ddrdqi1n, iddrdq, oddrdq;
	
	assign ddrdqs = ddrdqsclk || ddrdqszero && !ddrckn ? {2{ddrckn}} : 2'bz;

	wire rdclk;
	generate
		for(i = 0; i < 16; i = i + 1) begin
			IDDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) iddr_i(
				.C(rdclk),
				.CE(1),
				.Q1(ddrdqi0n[i]),
				.Q2(ddrdqi1n[i]),
				.D(iddrdq[i]),
				.R(0),
				.S(0)
			);
			ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) oddr_i(
				.C(clk90),
				.CE(1),
				.D1(ddrdqo[i+16]),
				.D2(ddrdqo[i]),
				.Q(oddrdq[i]),
				.R(0),
				.S(0)
			);
			IOBUF iobuf_i(
				.IO(ddrdq[i]),
				.I(oddrdq[i]),
				.O(iddrdq[i]),
				.T(ddrdqtd)
			);
		end
	endgenerate
	
	always @(posedge clk90) begin
		ddrdm <= ddrdmo;
		ddrdqtd <= ddrdqt;
	end
	
	always @(posedge ddrckn)
		ddrdqi <= {ddrdqi0n, ddrdqi1n};
	
	wire pllfb;
	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT(8),
		.CLKOUT0_DIVIDE(8),
		.CLKOUT1_DIVIDE(8),
		.CLKOUT2_DIVIDE(8),
		.CLKOUT3_DIVIDE(8),
		.CLKOUT0_PHASE(0),
		.CLKOUT1_PHASE(90),
		.CLKOUT2_PHASE(180),
		.CLKOUT3_PHASE(-30),

		.CLKIN1_PERIOD(10.000),
		.DIVCLK_DIVIDE(1)
	) pll(
		.CLKIN1(clk),
		.CLKOUT0(ddrckn),
		.CLKOUT1(clk90),
		.CLKOUT2(ddrckp),
		.CLKOUT3(rdclk),
		
		.CLKFBOUT(pllfb),
		.CLKFBIN(pllfb),
		.PWRDWN(0),
		.RST(0)
	);

endmodule
