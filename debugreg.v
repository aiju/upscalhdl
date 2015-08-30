`include "dat.vh"

module debugreg (
	input wire clk,
	output wire [7:0] dbgaddr,
	output wire [7:0] dbgwdata,
	output reg dbgreq,
	input wire dbgack
	

`ifdef SIMULATION
	,
	
	input wire capture,
	input wire shift,
	input wire drck,
	input wire reset,
	input wire tdi,
	output wire tdo
);
`else
	);

	wire capture, shift, drck, reset, tdi;
	wire tdo;
	BSCANE2 #(.JTAG_CHAIN(3)) bscane2(
		.CAPTURE(capture),
		.DRCK(drck),
		.RESET(reset),
		.SHIFT(shift),
		.TDI(tdi),
		.TDO(tdo)
	);
`endif

	assign tdo = 0;

	reg [15:0] sr;
	reg [4:0] ctr;
	reg jreq;
	
	wire [15:0] ssr;
	genvar i;
	generate
		for(i = 0; i < 16; i = i + 1)
			sync sync_i(clk, sr[i], ssr[i]);
	endgenerate
	
	assign dbgaddr = ssr[15:8];
	assign dbgwdata = ssr[7:0];

	always @(posedge drck) begin
		if(capture) begin
			sr <= 16'bx;
			ctr <= 0;
		end
		else if(shift) begin
			if(ctr != 16) begin
				sr <= {tdi, sr[15:1]};
				ctr <= ctr + 1;
			end
			if(ctr == 15)
				jreq <= !jreq;
		end
	end
	
	wire sreq;
	reg sreq0;
	
	sync reqsync(clk, jreq, sreq);
		
	always @(posedge clk) begin
		dbgreq <= (dbgreq || sreq ^ sreq0) && !dbgack;
		sreq0 <= sreq;
	end

endmodule
