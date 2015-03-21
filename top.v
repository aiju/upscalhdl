`include "dat.vh"

module top(
	input wire clk,
	output wire scl,
	inout wire sda,
	output reg led0,
	output reg led1,
	output reg led2,
	output reg led3,
	output wire hdclk,
	output reg hdde,
	output wire hdvs,
	output wire hdhs,
	output wire [11:0] hddat,
	output wire hdmclk,
	output wire hdsclk,
	output wire hdlrclk,
	output wire hdi2s,
	input wire hdint,
	output wire [11:0] ext,
	output wire adreset
);

	wire sdain0, sdaout, i2creq, i2cack, i2cerr, hdreq, hdwr, hdlast, hdack, hderr, i2clast, hdmiactive;
	wire adreq, adwr, adlast, adack, aderr, regvalid, hddein, hddeout;
	wire [7:0] i2caddr, i2crddata, i2cwrdata, hdaddr, hdwrdata, hdrddata, gpio, adaddr, adwrdata, adrddata, regaddr, regdata, debug;
	wire [15:0] hdx, hdy;
	wire [23:0] hdd;
	reg sdain1, sdain;
	
	IOBUF sdabuf(.IO(sda), .O(sdain0), .I(0), .T(sdaout));
	always @(posedge clk) begin
		sdain1 <= sdain0;
		sdain <= sdain1;
	end 
	
	assign ext[4:0] = {hdde, adreq, adack, sdain0, scl};
	ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) ODDR1(.C(hdclk), .R(0), .S(0), .CE(1), .Q(ext[5]), .D1(hdd[0]), .D2(hdd[12]));
	assign adreset = 1;

	i2c i2c0(clk, scl, sdain, sdaout, i2caddr, i2cwrdata, i2creq, i2clast, i2crddata, i2cack, i2cerr);
	i2carb i2carb0(clk, i2caddr, i2cwrdata, i2creq, i2clast, i2crddata, i2cack, i2cerr, hdaddr, hdwrdata,
		hdreq, hdwr, hdlast, hdrddata, hdack, hderr, adaddr, adwrdata, adreq, adwr, adlast, adrddata,
		adack, aderr, gpio);
	hdmi hdmi0(clk, hdaddr, hdwrdata, hdreq, hdwr, hdlast, hdrddata, hdack, hderr, hdclk, hddein, hdvs, hdhs,
		hdx, hdy, hdmclk, hdsclk, hdlrclk, hdi2s, hdint, hdmiactive, gpio, debug);
	ad ad0(clk, adaddr, adwrdata, adreq, adwr, adlast, adrddata, adack, aderr, regaddr, regdata, regvalid);
	regdisp regdisp0(clk, regaddr, regdata, regvalid, hdclk, hddein, hddeout, hdx, hdy, hdd);
	always @(posedge hdclk) hdde <= hddeout;
	genvar i;
	generate
		for(i = 0; i < 12; i = i + 1)
			ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) U(.C(hdclk), .R(0), .S(0), .CE(1), .Q(hddat[i]), .D1(hdd[i]), .D2(hdd[i+12]));
	endgenerate
	
	always @(*) begin
		if(!gpio[0]) begin
			led0 = debug[0];
			led1 = debug[1];
			led2 = debug[2];
			led3 = debug[3];
		end else begin
			led0 = debug[4];
			led1 = debug[5];
			led2 = debug[6];
			led3 = debug[7];
		end
	end
	
	wire pllfb;
	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT(11),
		.CLKOUT0_DIVIDE(15),
		
		//.CLKFBOUT_MULT(8),
		//.CLKOUT0_DIVIDE(30),
		.CLKIN1_PERIOD(10.000),
		.DIVCLK_DIVIDE(1)
	) pll(
		.CLKIN1(clk),
		.CLKOUT0(hdclk),
		.CLKFBOUT(pllfb),
		.CLKFBIN(pllfb),
		.PWRDWN(0),
		.RST(0)
	);
endmodule
