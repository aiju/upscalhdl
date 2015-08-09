`include "dat.vh"

module memtest();

	localparam PORTS = 2;

	/*AUTOWIRE*/
	// Beginning of automatic wires (for undeclared instantiated-module outputs)
	wire [12:0]	ddra;			// From mem0 of mem.v
	wire [1:0]	ddrba;			// From mem0 of mem.v
	wire		ddrcas;			// From mem0 of mem.v
	wire		ddrcke;			// From mem0 of mem.v
	wire		ddrcs;			// From mem0 of mem.v
	wire [1:0]	ddrdm;			// From mem0 of mem.v
	wire [15:0]	ddrdqo0;		// From mem0 of mem.v
	wire [15:0]	ddrdqo1;		// From mem0 of mem.v
	wire [1:0]	ddrdqs;			// To/From mem0 of mem.v
	wire		ddrdqt;			// From mem0 of mem.v
	wire		ddrras;			// From mem0 of mem.v
	wire		ddrwe;			// From mem0 of mem.v
	wire [PORTS-1:0] memack;		// From mem0 of mem.v
	wire [31:0]	memrdata;		// From mem0 of mem.v
	wire [PORTS-1:0] memready;		// From mem0 of mem.v
	// End of automatics
	/*AUTOREGINPUT*/
	// Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
	reg		clk;			// To mem0 of mem.v
	reg [15:0]	ddrdqi0;		// To mem0 of mem.v
	reg [15:0]	ddrdqi1;		// To mem0 of mem.v
	reg [23*PORTS-1:0] memaddr;		// To mem0 of mem.v
	reg [2*PORTS-1:0] memlen;		// To mem0 of mem.v
	reg [PORTS-1:0]	memreq;			// To mem0 of mem.v
	reg [32*PORTS-1:0] memwdata;		// To mem0 of mem.v
	reg [PORTS-1:0]	memwr;			// To mem0 of mem.v
	// End of automatics

	parameter MHZ = 100;

	localparam CAS = 2;
	
	localparam tRCDns = 15;
	localparam tRASns = 40;
	localparam tRPns = 15;
	localparam tRRDns = 10;
	localparam tWRns = 15;
	
	localparam BLEN = 4;
	localparam QLEN = CAS + BLEN;
	
	`define ns2MHZ(n) (((n) * MHZ + 999) / 1000)
	localparam tRCD = `ns2MHZ(tRCDns);
	localparam tRAS = `ns2MHZ(tRASns);
	localparam tRP = `ns2MHZ(tRPns);
	localparam tRRD = `ns2MHZ(tRRDns);
	localparam tWR = `ns2MHZ(tWRns);
	localparam tWTR = 2;
	
	localparam N=1;
	reg [58:0] op[0:PORTS-1][0:N-1];
	localparam OPNOP = 0;
	localparam OPRD = 1;
	localparam OPWR = 2;
	integer pc[0:PORTS-1], rpc[0:PORTS-1];
	reg [1:0] bpos[0:PORTS-1];
	reg [15:0] mem[0:16777215];

	
	initial begin
		op[0][0] = {OPRD, 2'd3, 23'h1337, 32'h0};
		op[1][0] = {OPWR, 2'd0, 23'h1337, 32'h0};
	end
	
	initial begin : initpc
		integer i;
		
		for(i = 0; i < PORTS; i = i + 1) begin
			memreq[i] = 0;
			pc[i] = 0;
			rpc[i] = 0;
			bpos[i] = 0;
		end
	end
	
	reg [22:0] maddr[0:PORTS-1];
	reg [31:0] mwdata[0:PORTS-1];
	reg [1:0] mlen[0:PORTS-1];

	initial clk = 0;
	always #0.5 clk = !clk;
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(0, mem0);
		$dumpvars(0, maddr);
		$dumpvars(0, mwdata);
		$dumpvars(0, mlen);
	end
	
	always @(*) begin : reqgen
		integer i;
		
		for(i = 0; i < PORTS; i = i + 1) begin
			maddr[i] = op[i][pc[i]][54:32];
			mwdata[i] = op[i][rpc[i]][31:0];
			mlen[i] = op[i][pc[i]][56:55];
			memwr[i] = op[i][pc[i]][58:57] == OPWR;
			memreq[i] = pc[i] != N && op[i][pc[i]][58:57] != OPNOP;
		end
	end
	
	
	always @(posedge clk) begin : reqgenc
		integer i;
		reg done;
		reg [1:0] rop;
		reg [31:0] d;
		reg [22:0] a;
		
		for(i = 0; i < PORTS; i = i + 1)
			if(pc[i] != N && memready[i])
				pc[i] <= pc[i] + 1;
		done = 1;
		for(i = 0; i < PORTS; i = i + 1) begin
			rop = op[i][rpc[i]][58:57];
			if(rpc[i] != N && (memack[i] || rop == OPNOP)) begin
				if(rop == OPRD) begin
					a = op[i][rpc[i]][54:32] + bpos[i];
					d = {mem[2 * a + 1], mem[2 * a]};
					if(memrdata != d)
						$display("read %h returned wrong data %h != %h", a, memrdata, d);
				end
				bpos[i] <= bpos[i] + 1;
				if(bpos[i] == op[i][rpc[i]][56:55]) begin
					rpc[i] <= rpc[i] + 1;
					bpos[i] <= 0;
				end
			end
			if(rpc[i] != N)
				done = 0;
		end
		if(done)
			$finish;
	end
	
	reg bankact[0:3];
	reg [3:0] banktim[0:3];
	reg [12:0] bankrow[0:3];
	reg [3:0] bankras[0:3];
	reg [3:0] bankwrtim[0:3];
	reg [3:0] rrdtim, wtrtim;
	
	reg [1:0] datq[0:QLEN-1];
	reg [1:0] datqba[0:QLEN-1];
	reg [23:0] addrq[0:QLEN-1];
	localparam DIDLE = 0;
	localparam DREAD = 1;
	localparam DWRITE = 2;
	localparam DDQSZ = 3;

	wire [2:0] ddrcmd = {ddrras, ddrcas, ddrwe};
	localparam [2:0] CMDMODE = 0;
	localparam [2:0] CMDREFR = 1;
	localparam [2:0] CMDPRE = 2;
	localparam [2:0] CMDACT = 3;
	localparam [2:0] CMDWR = 4;
	localparam [2:0] CMDRD = 5;
	localparam [2:0] CMDTERM = 6;
	localparam [2:0] CMDNOP = 7;
	
	initial begin : init
		integer i;
		
		for(i = 0; i < 4; i = i + 1) begin
			bankact[i] = 0;
			banktim[i] = 0;
			bankrow[i] = 0;
			bankras[i] = 0;
			bankwrtim[i] = 0;
		end
		rrdtim = 0;
		for(i = 0; i < QLEN; i = i + 1)
			datq[i] = DIDLE;
		for(i = 0; i < 16777216; i = i + 1)
			mem[i] = $random;
	end
	
	always @(*) begin : packmem
		integer i;
		
		for(i = 0; i < PORTS; i = i + 1) begin
			memaddr[23 * i +: 23] = maddr[i];
			memwdata[32 * i +: 32] = mwdata[i];
			memlen[2 * i +: 2] = mlen[i];
		end
	end
	
	reg [15:0] ddrdq;
	
	assign ddrdqs = datq[0] == DDQSZ ? 2'b00 : datq[0] == DREAD ? {2{!clk}} : 2'bzz;
	
	initial ddrdq = 16'bz;
	reg [15:0] ddrdqo, ddrdqod;
	reg ddrdqtd;
	always @(*) begin
		ddrdqtd <= #0.25 ddrdqt;
		ddrdqod <= #0.25 ddrdqo;
	end
	always @(*) begin
		ddrdq = 16'bz;
		if(datq[0] == DREAD)
			ddrdq = clk ? mem[addrq[0]+1] : mem[addrq[0]];
		if(!ddrdqtd)
			ddrdq = ddrdqod;
	end
	initial $dumpvars(0, ddrdq);
	
	reg [15:0] ddrdqd;
	always @(ddrdq)
		ddrdqd <= #0.25 ddrdq;
	reg [23:0] addrq00;
	reg [1:0] datq00;
	reg [1:0] datqba00;
	reg [15:0] ddrdq0;
	always @(posedge clk) begin
		ddrdqi0 <= ddrdqd;
		ddrdqo <= ddrdqo0;
		if(datq00 == DWRITE && !ddrdm[0]) begin
			$display("write to %h: %h", addrq00[23:1], {ddrdq, ddrdq0});
			mem[addrq00 + 1] <= ddrdq;
			wtrtim <= tWTR;
			bankwrtim[datqba00] <= tWR - 1;
		end
	end
	always @(negedge clk) begin
		ddrdqi1 <= ddrdqd;
		ddrdqo <= ddrdqo1;
		if(datq[0] == DWRITE && !ddrdm[0]) begin
			mem[addrq[0]] <= ddrdq;
			datq00 <= datq[0];
			addrq00 <= addrq[0];
			ddrdq0 <= ddrdq;
			datqba00 <= datqba[0];
		end
	end
	initial $dumpvars(0, datq);
	initial $dumpvars(0, addrq);
	
	always @(negedge clk) begin : cmd
		integer i;
		
		for(i = 0; i < 4; i = i + 1) begin
			if(banktim[i] != 0)
				banktim[i] <= banktim[i] - 1;
			if(bankras[i] != 0)
				bankras[i] <= bankras[i] - 1;
			if(bankwrtim[i] != 0)
				bankwrtim[i] <= bankwrtim[i] - 1;
		end
		for(i = 0; i < QLEN - 1; i = i + 1) begin
			datq[i] <= datq[i + 1];
			datqba[i] <= datqba[i + 1];
			addrq[i] <= addrq[i + 1];
		end
		datq[QLEN - 1] <= DIDLE;
		datqba[QLEN - 1] <= 'bx;
		addrq[QLEN - 1] <= 'bx;
		if(rrdtim != 0)
			rrdtim <= rrdtim - 1;
		if(wtrtim != 0)
			wtrtim <= wtrtim - 1;
		
		if(datq[0] == DREAD)
			$display("read from %h: %h", addrq[0][23:1], {mem[addrq[0]+1], mem[addrq[0]]});
	
		if(!ddrcs)
			case(ddrcmd)
			CMDNOP: ;
			CMDACT: begin
				if(ddrba === 2'bxx)
					$error("ACT: bank xx");
				else if(bankact[ddrba])
					$error("ACT: bank already active");
				else if(banktim[ddrba])
					$error("ACT: bank precharging");
				else if(rrdtim)
					$error("ACT: tRRD not elapsed");
				bankact[ddrba] <= 1;
				bankrow[ddrba] <= ddra;
				banktim[ddrba] <= tRCD - 1;
				bankras[ddrba] <= tRAS - 1;
				rrdtim <= tRRD - 1;
			end
			CMDPRE: begin
				if(ddra[10] === 1'bx)
					$error("PRE: A10 is x");
				else if(ddra[10] === 1'b1) begin
					for(i = 0; i < 4; i = i + 1) begin
						if(banktim[i])
							$error("PRE ALL: bank %d busy", i);
						else if(bankras[i])
							$error("PRE ALL: bank %d tRAS not elapsed", i);
						else if(bankwrtim[i])
							$error("PRE ALL: bank %d tWR not elapsed", i);
					end
				end else begin
					if(ddrba === 2'bxx)
						$error("PRE: bank xx");
					else if(!bankact[ddrba])
						$error("PRE: bank already precharged");
					else if(banktim[ddrba])
						$error("PRE: bank activating");
					else if(bankras[ddrba])
						$error("PRE: tRAS not elapsed");
					else if(bankwrtim[ddrba])
						$error("PRE: tWR not elapsed");
				end
				bankact[ddrba] <= 0;
				banktim[ddrba] <= tRP - 1;
			end
			CMDRD: begin
				if(ddrba === 2'bxx)
					$error("RD: bank xx");
				else if(ddra[10] !== 1'b0)
					$error("RD: A10 not 0");
				else if(!bankact[ddrba])
					$error("RD: bank precharged");
				else if(banktim[ddrba])
					$error("RD: bank activating");
				if(wtrtim != 0)
					$error("RD: tWTR not expired");
				for(i = 0; i < BLEN; i = i + 1) begin
					datq[i + CAS] <= DREAD;
					addrq[i + CAS][23:9] <= {ddrba, bankrow[ddrba]};
					addrq[i + CAS][8:0] <= ddra[8:0] + 2 * i;
					datqba[i + CAS] <= ddrba;
				end
				if(datq[CAS] == DIDLE)
					datq[CAS - 1] <= DDQSZ;
			end
			CMDWR: begin
				if(ddrba === 2'bxx)
					$error("WR: bank xx");
				else if(ddra[10] !== 1'b0)
					$error("WR: A10 not 0");
				else if(!bankact[ddrba])
					$error("WR: bank precharged");
				else if(banktim[ddrba])
					$error("WR: bank activating");
				for(i = 0; i < BLEN; i = i + 1) begin
					if(datq[i+1] == DREAD)
						$error("WR: read in progress");
					datq[i] <= DWRITE;
					addrq[i][23:9] <= {ddrba, bankrow[ddrba]};
					addrq[i][8:0] <= ddra[8:0] + 2 * i;
					datqba[i] <= ddrba;
				end
			end
			CMDTERM: begin
				if(datq[CAS] != DREAD)
					$error("TERM: not a read burst");
				for(i = CAS; i < QLEN; i = i + 1)
					datq[i] <= DIDLE;
			end
			default:
				$error("unknown command %b", ddrcmd);
			endcase
	end
	
	mem #(.PORTS(PORTS)) mem0(/*AUTOINST*/
				  // Outputs
				  .ddra			(ddra[12:0]),
				  .ddrba		(ddrba[1:0]),
				  .ddrdqo0		(ddrdqo0[15:0]),
				  .ddrdqo1		(ddrdqo1[15:0]),
				  .ddrdqt		(ddrdqt),
				  .ddrwe		(ddrwe),
				  .ddrras		(ddrras),
				  .ddrcas		(ddrcas),
				  .ddrcs		(ddrcs),
				  .ddrcke		(ddrcke),
				  .ddrdm		(ddrdm[1:0]),
				  .memrdata		(memrdata[31:0]),
				  .memack		(memack[PORTS-1:0]),
				  .memready		(memready[PORTS-1:0]),
				  // Inouts
				  .ddrdqs		(ddrdqs[1:0]),
				  // Inputs
				  .clk			(clk),
				  .ddrdqi0		(ddrdqi0[15:0]),
				  .ddrdqi1		(ddrdqi1[15:0]),
				  .memaddr		(memaddr[23*PORTS-1:0]),
				  .memwdata		(memwdata[32*PORTS-1:0]),
				  .memlen		(memlen[2*PORTS-1:0]),
				  .memwr		(memwr[PORTS-1:0]),
				  .memreq		(memreq[PORTS-1:0]));

endmodule
// Local Variables:
// verilog-library-flags:("-y ../")
// End:
