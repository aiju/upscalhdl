`include "dat.vh"

module addat(
	input wire adclk,
	input wire adsfl,
	input wire advs,
	input wire adhs,
	input wire adfield,
	input wire [19:0] addat,
	output reg inde,
	output reg [25:0] indat
);

	reg [39:0] sr;
	reg [1:0] ctr;
	reg [2:0] act;

	always @(posedge adclk) begin
		sr <= {sr[29:0], addat[19:10]};
		inrst <= 0;
		if({sr[39:32], sr[29:22], sr[19:12]} == 24'hFF0000) begin
			act <= {sr[7:6] == 0;
			ctr <= 0;
		end else
			ctr <= ctr + 1;
	end
	
	reg aact, aact_;
	reg [9:0] ay, ay_, acb, acr;
	always @(posedge adclk) begin
		aact <= 0;
		aact_ <= 0;
		if(act && ctr == 3 && {sr[39:32], sr[29:22], sr[19:12]} != 24'hFF0000) begin
			aact <= 1;
			aact_ <= 1;
			ay <= sr[29:20];
			ay_ <= sr[9:0];
			acb <= sr[39:30];
			acr <= sr[19:10];
		end
		if(aact_) begin
			aact <= 1;
			ay <= ay_;
		end
	end
	
	reg [35:0] bsy, bscr0, bscb0, bscr1, bscb1;
	reg [37:0] cr, cg, cb;
	reg bact, cact;
	
	always @(posedge adclk) begin
		bsy <= 32897 * ay;
		bscr0 <= 46122 * acr;
		bscr1 <= 23492 * acr;
		bscb0 <= 58294 * acb;
		bscb1 <= 11321 * acb;
		bact <= aact;
		cr <= bsy + bscr0 - 23745800 + (1<<18);
		cb <= bsy + bscb0 - 29977900 + (1<<18);
		cg <= bsy - bscr1 - bscb1 + 17693200 + (1<<18);
		cact <= bact;
		indat <= {cr[37] ? 0 : cr[36] ? 255 : cr[35:19], cg[37] ? 0 : cg[36] ? 255 : cg[35:19], cb[37] ? 0 : cb[36] ? 255 : cb[35:19]};
		inde <= cact;
	end

endmodule
