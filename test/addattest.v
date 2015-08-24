`include "dat.vh"

module addattest;

	/*AUTOWIRE*/
	// Beginning of automatic wires (for undeclared instantiated-module outputs)
	wire [23:0]	indat;			// From addat0 of addat.v
	wire		inde;			// From addat0 of addat.v
	// End of automatics
	
	/*AUTOREGINPUT*/
	// Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
	reg		adclk;			// To addat0 of addat.v
	reg		adfield;		// To addat0 of addat.v
	reg		adhs;			// To addat0 of addat.v
	reg		adsfl;			// To addat0 of addat.v
	reg		advs;			// To addat0 of addat.v
	// End of automatics
	
	initial adclk = 0;
	localparam N = 100;
	always #0.5 adclk = !adclk;
	reg [9:0] mem[0:4+N*2];
	reg [9:0] y, cb, cr;
	real ry, rcb, rcr, rr, rg, rb;
	reg [7:0] r, g, b;
	reg [23:0] out[0:N-1];
	integer i;
	integer idx, oidx;
	
	initial begin
		mem[0] = {8'hff, 2'b0};
		mem[1] = 0;
		mem[2] = 0;
		mem[3] = 10'b1000000000;
		for(i = 4; i < 4 + N * 2; i = i + 1) begin
			mem[i] = $random;
			while(mem[i] == 0 || mem[i] == 1023)
				mem[i] = $random;
		end
		
		for(i = 0; i < N; i = i + 1) begin
			cb = mem[4 + (i / 2) * 4];
			cr = mem[4 + (i / 2) * 4 + 2];
			y = mem[4 + 2 * i + 1];
			ry = (y - 4.0) / 1016;
			rcb = (cb - 4.0) / 1016 - 0.5;
			rcr = (cr - 4.0) / 1016 - 0.5;
			rr = 1.402 * rcr + ry;
			rg = 1.70358 * (0.587 * ry - 0.419198 * rcr - 0.202008 * rcb);
			rb = 1.772 * rcb + ry;
			r = rr < 0 ? 0 : rr >= 1 ? 255 : 255 * rr;
			g = rg < 0 ? 0 : rg >= 1 ? 255 : 255 * rg;
			b = rb < 0 ? 0 : rb >= 1 ? 255 : 255 * rb;
			out[i] = {r, g, b};
		end
		
		idx = 0;
		oidx = 0;
	end
	wire [19:0] addat = {mem[idx], 10'bx};
	
	always @(posedge adclk) begin
		idx <= idx + 1;
		
		if(inde) begin
			if(indat != out[oidx])
				$display("%d: %x != %x", oidx, indat, out[oidx]);
			oidx <= oidx + 1;
		end
	end
	
	initial #1000 $finish;
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars;
	end

	addat addat0(/*AUTOINST*/
		     // Outputs
		     .inde		(inde),
		     .indat		(indat[23:0]),
		     // Inputs
		     .adclk		(adclk),
		     .adsfl		(adsfl),
		     .advs		(advs),
		     .adhs		(adhs),
		     .adfield		(adfield),
		     .addat		(addat[19:0]));

endmodule
// Local Variables:
// verilog-library-flags:("-y ../")
// End:
