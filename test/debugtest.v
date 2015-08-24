`include "dat.vh"

module debugtest();

	localparam N = 32;

	reg clk, trigger, capture, shift, reset, tdi, drck;
	reg [N-1:0] indata;
	wire tdo;
	
	always @(posedge clk)
		if(indata == 'hdeadbeef)
			indata <= 'hcafebabe;
		else
			indata <= 'hdeadbeef;
	
	task scan16(input reg [15:0] addr, input reg [15:0] din, output reg [15:0] dout);
	begin
		drck = 0;
		capture = 1;
		#1 drck = 1;
		#1 drck = 0;
		capture = 0;
		shift = 1;
		
		repeat(16) begin
			tdi = addr[15];
			addr = {addr[14:0], 1'b0};
			#1 drck = 1;
			#1 drck = 0;
		end
		
		repeat(16) begin
			tdi = din[15];
			din = {din[14:0], 1'b0};
			#1 drck = 1;
			dout = {dout[14:0], tdo};
			#1 drck = 0;
		end
		shift = 0;
	end
	endtask
	
	task scandata(input reg [15:0] din, output reg [15:0] dout);
	begin
		shift = 1;
		repeat(16) begin
			tdi = din[15];
			din = {din[14:0], 1'b0};
			#1 drck = 1;
			dout = {dout[14:0], tdo};
			#1 drck = 0;
		end
		shift = 0;
	end
	endtask
	
	reg [15:0] dout;
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();

		clk = 0;
		trigger = 0;
		capture = 0;
		shift = 0;
		reset = 0;
		tdi = 0;
		drck = 0;
		#10 scan16(16'hff01, 16'h0000, dout);
		#30 trigger = 1;
		#34 trigger = 0;
		#10 scan16(16'h0000, 16'h0000, dout);
		scandata(16'h0000, dout);
		#1000 $finish;
	end
	
	always #0.5 clk = !clk;

	debug #(.N(N)) debug0(clk, trigger, indata, capture, shift, drck, reset, tdi, tdo);

endmodule
