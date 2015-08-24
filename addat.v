`include "dat.vh"

module addat(
	input wire adclk,
	input wire adsfl,
	input wire advs,
	input wire adhs,
	input wire adfield,
	input wire [19:0] addat,
	output reg inde,
	output reg [24:0] indat
);

	reg [39:0] sr;
	reg [1:0] ctr;
	reg act;
	reg start;
	
	initial begin
		start = 0;
	end
	
	always @(posedge adclk) begin
		sr <= {sr[29:0], addat[19:10]};
		if({sr[39:32], sr[29:22], sr[19:12]} == 24'hFF0000) begin
			act <= sr[7:6] == 0;
			ctr <= 0;
		end else
			ctr <= ctr + 1;
	end
	
	reg aact, aact_;
	reg async;
	reg [9:0] ay, ay_, acb, acr;
	always @(posedge adclk) begin
		aact <= 0;
		aact_ <= 0;
		if({sr[39:32], sr[29:22], sr[19:12]} == 24'hFF0000 && sr[7:6] == 2'b11)
			start <= 1;
		if(act && ctr == 3 && {sr[39:32], sr[29:22], sr[19:12]} != 24'hFF0000) begin
			aact <= 1;
			aact_ <= 1;
			ay <= sr[29:20];
			ay_ <= sr[9:0];
			acb <= sr[39:30];
			acr <= sr[19:10];
			async <= start;
			start <= 0;
		end
		if(aact_) begin
			aact <= 1;
			ay <= ay_;
			async <= 0;
		end
	end
	
	reg [35:0] bsy, bscr0, bscb0, bscr1, bscb1;
	reg [37:0] cr, cg, cb;
	reg bact, cact;
	reg bsync, csync;
	
	always @(posedge adclk) begin
		bsy <= 32897 * ay;
		bscr0 <= 46122 * acr;
		bscr1 <= 23492 * acr;
		bscb0 <= 58294 * acb;
		bscb1 <= 11321 * acb;
		bact <= aact;
		bsync <= async;
		cr <= bsy + bscr0 - 23745800 + (1<<16);
		cb <= bsy + bscb0 - 29977900 + (1<<16);
		cg <= bsy - bscr1 - bscb1 + 17693200 + (1<<16);
		cact <= bact;
		csync <= bsync;
		indat[7:0] <= cb[26] ? 0 : cb[25] ? 255 : cb[24:17];
		indat[15:8] <= cg[26] ? 0 : cg[25] ? 255 : cg[24:17];
		indat[23:16] <= cr[26] ? 0 : cr[25] ? 255 : cr[24:17];
		indat[24] <= csync;
		inde <= cact;
	end

	debug #(.N(50)) debug0(adclk, async,
		{adsfl, advs, adhs, adfield, addat[19:0], inde, indat[24:0]}
	);


endmodule
