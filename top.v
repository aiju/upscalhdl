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
	
	input wire adclk,
	input wire adsfl,
	input wire advs,
	input wire adhs,
	input wire adfield,
	input wire [19:0] addat,
	output wire adreset,
	
	output wire ddrckp,
	output wire ddrckn,
	inout wire [15:0] ddrdq,
	output wire [1:0] ddrdm,
	output wire [12:0] ddra,
	output wire [1:0] ddrba,
	inout wire [1:0] ddrdqs,
	output wire ddrwe,
	output wire ddrras,
	output wire ddrcas,
	output wire ddrcs,
	output wire ddrcke,
	
	output wire [11:0] ext
);

	localparam MEMPORTS = 2;

	wire sdain0, sdaout, i2creq, i2cack, i2cerr, hdreq, hdwr, hdlast, hdack, hderr, i2clast, hdmiactive;
	wire adreq, adwr, adlast, adack, aderr, regvalid, hddein, hddeout;
	wire adinde, adrden, adempty;
	wire [7:0] i2caddr, i2crddata, i2cwrdata, hdaddr, hdwrdata, hdrddata, gpio, adaddr, adwrdata, adrddata, regaddr, regdata, debug;
	wire [15:0] hdx, hdy;
	wire [23:0] hdd0, hdd1;
	wire [24:0] adindat, adoutdat;
	reg sdain1, sdain;
	wire [31:0] ddrdqi, ddrdqo;
	wire ddrdqt;
	wire [1:0] ddrdmo;
	wire [31:0] memrdata;
	wire [MEMPORTS-1:0] memreq, memready, memack, memwr;
	wire [2*MEMPORTS-1:0] memlen;
	wire [23*MEMPORTS-1:0] memaddr;
	wire [32*MEMPORTS-1:0] memwdata;
	wire ddrdqsclk, ddrdqszero;
	reg rst;
	reg [7:0] ctr;
	wire hdclk90;
	
	initial begin
		rst = 1;
		ctr = -1;
	end
	always @(posedge clk) begin
		rst <= ctr != 0;
		if(ctr != 0)
			ctr <= ctr - 1;
	end
	
	IOBUF sdabuf(.IO(sda), .O(sdain0), .I(0), .T(sdaout));
	always @(posedge clk) begin
		sdain1 <= sdain0;
		sdain <= sdain1;
	end

	wire trigger = memreq[gpio[7]];
	debug #(.N(234)) debug0(clk, trigger,
		{ddrdqi[31:0], ddrdqo[31:0], ddrdm[1:0], ddra[12:0], ddrba[1:0], 
		ddrdqs[1:0], ddrwe, ddrras, ddrcas, ddrcs, ddrcke, memaddr[45:0], 
		memrdata[31:0], memwdata[63:0], memreq[1:0], memack[1:0]}
	);
	
	mem #(.PORTS(MEMPORTS)) mem0(clk, ddra, ddrba, ddrdqi, ddrdqo, ddrdqt, ddrdqsclk, ddrdqszero, ddrwe, ddrras, ddrcas,
		ddrcs, ddrcke, ddrdmo, memaddr, memwdata, memrdata, memlen, memwr, memreq,
		memack, memready);
	memphy memphy0(clk, ddrdqi, ddrdqo, ddrdqt, ddrdmo, ddrckp, ddrckn, ddrdq, ddrdm, ddrdqsclk, ddrdqszero, ddrdqs);
	i2c i2c0(clk, scl, sdain, sdaout, i2caddr, i2cwrdata, i2creq, i2clast, i2crddata, i2cack, i2cerr);
	i2carb i2carb0(clk, i2caddr, i2cwrdata, i2creq, i2clast, i2crddata, i2cack, i2cerr, hdaddr, hdwrdata,
		hdreq, hdwr, hdlast, hdrddata, hdack, hderr, adaddr, adwrdata, adreq, adwr, adlast, adrddata,
		adack, aderr, gpio);
	hdmi hdmi0(clk, hdaddr, hdwrdata, hdreq, hdwr, hdlast, hdrddata, hdack, hderr, hdclk, hddein, hdvs, hdhs,
		hdx, hdy, hdmclk, hdsclk, hdlrclk, hdi2s, hdint, hdmiactive, gpio, debug);
	hddma hddma0(clk, rst, memaddr[22:0], memlen[1:0], memrdata, memwdata[31:0], memreq[0], memwr[0],
		memack[0], memready[0], hdclk, hdx, hdy, hdd1);
	ad ad0(clk, adaddr, adwrdata, adreq, adwr, adlast, adrddata, adack, aderr, regaddr, regdata, regvalid, adreset);
	addat addat0(adclk, adsfl, advs, adhs, adfield, addat, adinde, adindat);
	fifo #(.WIDTH(25), .ALEMPTY(16)) adfifo(.rst(rst), .wrclk(adclk), .wren(adinde), .wrdata(adindat),
		.rdclk(clk), .rden(adrden), .rddata(adoutdat), .empty(adempty));
	addma addma0(clk, adoutdat, adrden, adempty, memaddr[45:23], memrdata, memwdata[63:32], memlen[3:2], memreq[1], memwr[1],
		memready[1], memack[1]);
	regdisp regdisp0(clk, regaddr, regdata, regvalid, hdclk, hddein, hddeout, hdx, hdy, hdd0);
//	frwrite frwrite0(clk, memaddr[45:23], memwdata[63:32], memreq[1], memwr[1], memlen[3:2], memack[1], memready[1]);
	reg [23:0] hdd;
	wire gpios;
	sync gpio0sync(hdclk, gpio[0], gpios);
	always @(posedge hdclk) begin
		hdde <= hddeout;
		hdd <= gpios && hdd0 != 0 ? hdd0 : hdd1;
	end
	genvar i;
	generate
		for(i = 0; i < 12; i = i + 1)
			ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) U(.C(hdclk90), .R(0), .S(0), .CE(1), .Q(hddat[i]), .D1(hdd[i]), .D2(hdd[i+12]));
	endgenerate

	wire pllfb;
	PLLE2_BASE #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT(14),
		.CLKOUT0_DIVIDE(19),
		.CLKOUT1_DIVIDE(19),
		.CLKOUT1_PHASE(90),
		
		//.CLKFBOUT_MULT(8),
		//.CLKOUT0_DIVIDE(30),
		.CLKIN1_PERIOD(10.000),
		.DIVCLK_DIVIDE(1)
	) pll(
		.CLKIN1(clk),
		.CLKOUT0(hdclk),
		.CLKOUT1(hdclk90),
		.CLKFBOUT(pllfb),
		.CLKFBIN(pllfb),
		.PWRDWN(0),
		.RST(0)
	);
endmodule
