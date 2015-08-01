`include "dat.vh"

module i2ctest(
);

	wire scl, sdaout, ack, err;
	wire [7:0] rddata;
	reg [7:0] addr, wrdata;
	reg clk, sdain, req, last;
	

	initial clk = 0;
	always #0.5 clk = !clk;
	initial begin
		addr = 'h54;
		wrdata = 'h01;
		last = 0;
		req = 0;
		#5 req = 1;
		#1 req = 0;
		@(posedge ack) @(posedge clk) addr = 'h34;
		req = 1;
		@(posedge clk) req = 0;
	end
	
	task readbyte;
	output reg [7:0] sr;
	begin
		repeat(8)
			@(posedge scl)
				sr = {sr[6:0], sdaout};
	end
	endtask
	
	task busack;
	begin
		@(negedge scl) sdain = 0;
		@(negedge scl) sdain = 1;
	end
	endtask
	
	reg [7:0] i2caddr, i2cdata;
	
	initial begin
		sdain = 1;
		@(negedge sdaout);
		while(!scl)
			@(negedge sdaout);
		readbyte(i2caddr);
		if(i2caddr == 'h54) begin
			busack;
			readbyte(i2cdata);
			$display("%x", i2cdata);
			busack;
		end
	end

	i2c i2c0(
		clk,
		scl,
		sdain,
		sdaout,
		
		addr,
		wrdata,
		req,
		last,
		rddata,
		ack,
		err
	);
endmodule
