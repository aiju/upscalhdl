`include "dat.vh"

module i2carbtest(
);

	reg clk, ack, err, hdreq, hdwr, hdlast;
	reg [7:0] rddata, hdaddr, hdwrdata;
	wire [7:0] addr, wrdata, gpio, hdrddata;
	wire req, hdack, hderr;
	
	initial clk = 0;
	always #0.5 clk = !clk;
	
	initial begin
		ack = 0;
		err = 0;
		rddata = 0;
		hdaddr = 'h41;
		hdwrdata = 'hAB;
		hdreq = 0;
		hdwr = 0;
		hdlast = 0;
		rddata = 8'h42;
		
		#100 hdreq = 1;
		hdlast = 0;
		hdwr = 1;
		while(!hdack) @(posedge clk);
		hdwr = 0;
		hdlast = 1;
		@(posedge clk);
		while(!hdack) @(posedge clk)
		hdreq = 0;
	end
	
	always @(posedge clk) begin
		if(req) begin
			repeat(10) @(posedge clk);
			ack = 1;
			@(posedge clk) ack = 0;
		end
	end

	i2carb i2carb0(clk,
		addr,
		wrdata,
		req,
		last,
		rddata,
		ack,
		err,
		hdaddr,
		hdwrdata,
		hdreq,
		hdwr,
		hdlast,
		hdrddata,
		hdack,
		hderr,
		gpio
	);
	

endmodule
