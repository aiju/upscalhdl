`include "dat.vh"

module memtest();

	localparam PORTS = 1;

	/*AUTOWIRE*/
	// Beginning of automatic wires (for undeclared instantiated-module outputs)
	wire [12:0]	ddra;			// From mem0 of mem.v
	wire [1:0]	ddrba;			// From mem0 of mem.v
	wire		ddrcas;			// From mem0 of mem.v
	wire		ddrcke;			// From mem0 of mem.v
	wire		ddrcs;			// From mem0 of mem.v
	wire [1:0]	ddrdm;			// From mem0 of mem.v
	wire [15:0]	ddrdq;			// To/From mem0 of mem.v
	wire [1:0]	ddrdqs;			// To/From mem0 of mem.v
	wire		ddrras;			// From mem0 of mem.v
	wire		ddrwe;			// From mem0 of mem.v
	wire [PORTS-1:0] memack;		// From mem0 of mem.v
	wire [31:0]	memrdata;		// From mem0 of mem.v
	// End of automatics
	/*AUTOREGINPUT*/
	// Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
	reg		clk;			// To mem0 of mem.v
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

	initial clk = 0;
	always #0.5 clk = !clk;
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars;
	end
	
	initial begin
		memaddr = 23'h2DBEEF;
		memlen = 3'd4;
		memreq = 1;
		memwr = 0;
		#1000 $finish;
	end
	
	reg bankact[0:3];
	reg [3:0] banktim[0:3];
	reg [12:0] bankrow[0:3];
	reg [3:0] bankras[0:3];
	reg [3:0] rrdtim;

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
		end
		rrdtim = 0;
	end
	
	always @(posedge clk) begin : cmd
		integer i;
	
		if(!ddrcs)
			case(ddrcmd)
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
				banktim[ddrba] <= tRCD;
				bankras[ddrba] <= tRAS;
				rrdtim <= tRRD;
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
				end
			end
			CMDRD, CMDWR: begin

			end
			endcase
	end
	
	mem #(.PORTS(PORTS)) mem0(/*AUTOINST*/
				  // Outputs
				  .ddra			(ddra[12:0]),
				  .ddrba		(ddrba[1:0]),
				  .ddrwe		(ddrwe),
				  .ddrras		(ddrras),
				  .ddrcas		(ddrcas),
				  .ddrcs		(ddrcs),
				  .ddrcke		(ddrcke),
				  .ddrdm		(ddrdm[1:0]),
				  .memrdata		(memrdata[31:0]),
				  .memack		(memack[PORTS-1:0]),
				  // Inouts
				  .ddrdq		(ddrdq[15:0]),
				  .ddrdqs		(ddrdqs[1:0]),
				  // Inputs
				  .clk			(clk),
				  .memaddr		(memaddr[23*PORTS-1:0]),
				  .memwdata		(memwdata[32*PORTS-1:0]),
				  .memlen		(memlen[2*PORTS-1:0]),
				  .memwr		(memwr[PORTS-1:0]),
				  .memreq		(memreq[PORTS-1:0]));

endmodule
// Local Variables:
// verilog-library-flags:("-y ../")
// End:
