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
