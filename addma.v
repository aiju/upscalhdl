`include "dat.vh"

module addma(
	input wire clk,
	
	input wire [24:0] outdat,
	output wire rden,
	input wire empty,
	
	output reg [22:0] memaddr,
	input wire [31:0] memrdata,
	output wire [31:0] memwdata,
	output wire [1:0] memlen,
	output reg memreq,
	output wire memwr,
	input wire memready,
	input wire memack
);

	reg [31:0] dat[0:3];
	reg [1:0] ctr;
	reg [2:0] state;
	
	localparam FILL = 0;
	localparam REQ = 1;
	localparam DAT = 2;
	assign memwdata = dat[ctr];
	assign rden = state == FILL && !empty && (ctr == 0 || !outdat[24]);
	
	assign memwr = 1;
	assign memlen = 3;
	always @(posedge clk)
		case(state)
		FILL:
			if(!empty) begin
				dat[ctr] <= {8'h0, outdat[23:0]};
				if(outdat[24])
					memaddr <= 0;
				ctr <= ctr + 1;
				if(ctr == 3) begin
					memreq <= 1;
					state <= REQ;
				end
			end
		REQ:
			if(memready) begin
				memreq <= 0;
				memaddr <= memaddr + 4;
				state <= DAT;
			end
		DAT:
			if(memack) begin
				ctr <= ctr + 1;
				if(ctr == 3)
					state <= FILL;
			end
		endcase

endmodule
