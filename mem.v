`include "dat.vh"

module mem #(parameter PORTS = 4) (
	input wire clk,
	
	output reg [12:0] ddra,
	output reg [1:0] ddrba,
	input wire [31:0] ddrdqi,
	output reg [31:0] ddrdqo,
	output wire ddrdqt,
	output wire ddrdqsclk,
	output wire ddrdqszero,
	output wire ddrwe,
	output wire ddrras,
	output wire ddrcas,
	output wire ddrcs,
	output reg ddrcke,
	output wire [1:0] ddrdmo,
	
	input wire [23*PORTS-1:0] memaddr,
	input wire [32*PORTS-1:0] memwdata,
	output reg [31:0] memrdata,
	input wire [2*PORTS-1:0] memlen,
	input wire [PORTS-1:0] memwr,
	input wire [PORTS-1:0] memreq,
	output reg [PORTS-1:0] memack,
	output reg [PORTS-1:0] memready
);

	parameter MHZ = 100;

	localparam CAS = 2;
	localparam BLEN = 4;

	localparam [12:0] MRS = 13'b0000_10_010_0_011;
	localparam [12:0] EMRS = 13'b00000_0_0000_0_1;

	localparam tRCDns = 15;
	localparam tRASns = 40;
	localparam tRPns = 15;
	localparam tRRDns = 10;
	localparam tWRns = 15;
	localparam tREFIns = 7800;
	localparam tRFCns = 72;
	localparam tINITns = 200000;
	localparam tINIT2 = 200;
	localparam tMRDns = 10;
	localparam tWTR = 2;
	localparam REFMAX = 4;
	
	`define ns2MHZ(n) (((n) * MHZ + 999) / 1000)
	localparam tRCD = `ns2MHZ(tRCDns);
	localparam tRAS = `ns2MHZ(tRASns);
	localparam tRP = `ns2MHZ(tRPns);
	localparam tRRD = `ns2MHZ(tRRDns);
	localparam tWR = `ns2MHZ(tWRns);
	localparam tREFI = `ns2MHZ(tREFIns);
	localparam tRFC = `ns2MHZ(tRFCns);
	localparam tINIT = `ns2MHZ(tINITns);
	localparam tMRD = `ns2MHZ(tMRDns);
	
	localparam QLEN = CAS + BLEN + 1;

	reg [3:0] bankact;
	reg [3:0] banktim[0:3];
	reg [12:0] bankrow[0:3];
	reg [3:0] bankras[0:3];
	reg [3:0] rrdtim, wtrtim;
	reg [15:0] refitim;
	reg [3:0] refctr;
	
	reg [22:0] maddr[0:PORTS-1];
	reg [1:0] mbank[0:PORTS-1];
	reg [12:0] mrow[0:PORTS-1];
	reg [8:0] mcol[0:PORTS-1];
	reg [2:0] mlen[0:PORTS-1];
	reg [2:0] mcmd[0:PORTS-1];
	reg [PORTS-1:0] mwr;
	reg [PORTS-1:0] mready;
	reg [PORTS-1:0] mactive;
	reg refready;
	
	reg [9:0] mage[0:PORTS-1];
	reg [PORTS-1:0] murg;
	reg [PORTS-1:0] msame;
	
	reg [2:0] datq[0:QLEN - 1];
	reg [1:0] datqba[0:QLEN - 1];
	reg [3:0] datqport[0:QLEN - 1];
	reg [QLEN - 1:0] datqfin;
	localparam DIDLE = 0;
	localparam DREAD = 1;
	localparam DNREAD = 2;
	localparam DWRITE = 3;
	localparam DNWRITE = 4;
	localparam DDQSZ = 5;
	
	always @(*) begin : ready
		integer i, j;
		
		for(i = 0; i < PORTS; i = i + 1) begin
			maddr[i] = memaddr[23 * i +: 23];
			mcmd[i] = 'bx;
			msame[i] = 0;
			if(!mactive[i])
				mready[i] = 0;
			else if(banktim[mbank[i]] != 0)
				mready[i] = 0;
			else if(!bankact[mbank[i]]) begin
				mcmd[i] = CMDACT;
				mready[i] = rrdtim == 0;
			end else if(bankrow[mbank[i]] != mrow[i]) begin
				mcmd[i] = CMDPRE;
				mready[i] = 1;
				for(j = CAS; j < QLEN; j = j + 1)
					if(datq[j] == DREAD || datq[j] == DWRITE)
						mready[i] = 0;
				if(bankras[mbank[i]] != 0 || (datq[0] == DWRITE || datq[1] == DWRITE) && datqba[0] == i)
					mready[i] = 0;
			end else if(mwr[i]) begin
				mcmd[i] = CMDWR;
				mready[i] = 1;
				for(j = 0; j < BLEN; j = j + 1)
					if(datq[2 + j] == DREAD || datq[2 + j] == DWRITE || datq[2 + j] == DNREAD)
						mready[i] = 0;
				if(datq[1] == DREAD)
					mready[i] = 0;
				if(datq[CAS] == DNREAD) begin
					mready[i] = 1;
					mcmd[i] = CMDTERM;
				end
			end else begin
				mcmd[i] = CMDRD;
				mready[i] = 1;
				for(j = 0; j < BLEN; j = j + 1)
					if(datq[1 + CAS + j] == DREAD || datq[1 + CAS + j] == DWRITE)
						mready[i] = 0;
				if(wtrtim != 0 || datq[0] == DWRITE || datq[1] == DWRITE)
					mready[i] = 0;
			end
		end
		
		refready = 1;
		for(i = 0; i < PORTS; i = i + 1)
			if(banktim[i] != 0)
				refready = 0;
		if(bankact != 0) begin
			for(i = 0; i < PORTS; i = i + 1)
				if(bankras[i] != 0)
					refready = 0;
			if(datq[0] == DWRITE)
				refready = 0;
		end
	end
	
	reg [3:0] robin;
	initial robin = 0;
	always @(posedge clk)
		robin <= robin + 1;
	reg [PORTS-1:0] mask;

	always @(*)
		case(1'b1)
		|(mready & murg): mask = mready & murg;
		|(mready & msame): mask = mready & msame;
		1'b1: mask = mready;
		endcase
	
	reg [3:0] idx;
	generate
	case(PORTS)
	2: always @(*)
		casez({robin[0], mask})
		3'b0z1: idx = 0;
		3'b010: idx = 1;
		3'b11z: idx = 1;
		3'b101: idx = 0;
		default: idx = 'bx;
		endcase
	4: always @(*)
		casez({robin[1:0], mask})
		6'b00zzz1: idx = 0;
		6'b00zz10: idx = 1;
		6'b00z100: idx = 2;
		6'b001000: idx = 3;
		6'b01zz1z: idx = 1;
		6'b01z10z: idx = 2;
		6'b01100z: idx = 3;
		6'b010001: idx = 0;
		6'b10z1zz: idx = 2;
		6'b1010zz: idx = 3;
		6'b1000z1: idx = 0;
		6'b100010: idx = 1;
		6'b111zzz: idx = 3;
		6'b110zz1: idx = 0;
		6'b110z10: idx = 1;
		6'b110100: idx = 2;
		default: idx = 'bx;
		endcase
	endcase
	endgenerate
	
	reg [2:0] cmd_;
	
	always @(*) begin
		cmd_ = CMDNOP;
		if(refctr != 0 && refready)
			cmd_ = CMDREFR;
		if(mready != 0 && refctr < REFMAX)
			cmd_ = mcmd[idx];
		if(init)
			cmd_ = CMDMODE;
	end

	reg [2:0] ddrcmd, initcmd;
	reg [12:0] inita;
	reg [1:0] initba;
	reg initcke;
	reg init, initdone;
	assign ddrcs = 0;
	assign ddrras = ddrcmd[2];
	assign ddrcas = ddrcmd[1];
	assign ddrwe = ddrcmd[0];
	localparam [2:0] CMDMODE = 0;
	localparam [2:0] CMDREFR = 1;
	localparam [2:0] CMDPRE = 2;
	localparam [2:0] CMDACT = 3;
	localparam [2:0] CMDWR = 4;
	localparam [2:0] CMDRD = 5;
	localparam [2:0] CMDTERM = 6;
	localparam [2:0] CMDNOP = 7;
	
	assign ddrdqt = datq[0] != DWRITE;
	assign ddrdqsclk = datq[0] == DWRITE || datq[0] == DNWRITE;
	assign ddrdqszero = datq[0] == DDQSZ;
	assign ddrdmo = datq[0] == DWRITE ? 2'b00 : 2'b11;
	wire [3:0] port1 = datqport[1];
	always @(posedge clk)
		ddrdqo <= memwdata[port1 * 32 +: 32];
	
	reg rd;
	reg [3:0] rdport;
	
	initial begin : initregs
		integer i;
		
		for(i = 0; i < 4; i = i + 1) begin
			bankact[i] = 0;
			banktim[i] = 0;
			bankras[i] = 0;
		end
		for(i = 0; i < QLEN; i = i + 1) begin
			datq[i] = DIDLE;
		end
		memready = 0;
		memack = 0;
		mactive = 0;
		rrdtim = 0;
		wtrtim = 0;
		rd = 0;
		
		ddrcmd = CMDNOP;
	end
	
	always @(posedge clk) begin : cmd
		integer j;
	
		ddrcmd <= CMDNOP;
		ddra <= 'bx;
		ddrba <= 'bx;
		
		for(j = 0; j < QLEN - 1; j = j + 1) begin
			datq[j] <= datq[j + 1];
			datqba[j] <= datqba[j + 1];
			datqport[j] <= datqport[j + 1];
			datqfin[j] <= datqfin[j + 1];
		end
		datq[QLEN - 1] <= DIDLE;
		datqba[QLEN - 1] <= 2'bx;
		datqport[QLEN - 1] <= 'bx;
		datqfin[QLEN - 1] <= 'bx;
		
		for(j = 0; j < 4; j = j + 1) begin
			if(banktim[j] != 0)
				banktim[j] <= banktim[j] - 1;
			if(bankras[j] != 0)
				bankras[j] <= bankras[j] - 1;
		end
		for(j = 0; j < PORTS; j = j + 1) begin
			if(mage[j] != 0)
				mage[j] <= mage[j] - 1;
			murg[j] <= mage[j] <= 1;
		end
		if(rrdtim != 0)
			rrdtim <= rrdtim - 1;
		if(datq[0] == DWRITE) begin
			wtrtim <= tWTR - 1;
			if(bankras[datqba[0]] <= tWR - 1)
				bankras[datqba[0]] <= tWR - 1;
		end else if(wtrtim != 0)
			wtrtim <= wtrtim - 1;
		
		memack <= 0;
		
		ddrcmd <= cmd_;
		ddrcke <= initcke;
		case(cmd_)
		CMDNOP:
			if(datq[CAS+1] == DNREAD) begin
				ddrcmd <= CMDTERM;
				for(j = CAS; j < QLEN; j = j + 1)
					datq[j] <= DIDLE;
			end
		CMDMODE: begin
			ddrcmd <= initcmd;
			ddra <= inita;
			ddrba <= initba;
		end
		CMDREFR:
			if(bankact != 0) begin
				ddrcmd <= CMDPRE;
				ddra[10] <= 1;
				for(j = 0; j < 4; j = j + 4) begin
					banktim[j] <= tRP - 1;
					bankact[j] <= 0;
				end
			end else
				for(j = 0; j < 4; j = j + 1)
					banktim[j] <= tRFC - 1;
		CMDTERM:
			for(j = CAS; j < QLEN; j = j + 1)
				datq[j] <= DIDLE;
		CMDACT: begin
			ddra <= mrow[idx];
			ddrba <= mbank[idx];
			bankrow[mbank[idx]] <= mrow[idx];
			banktim[mbank[idx]] <= tRCD - 1;
			bankras[mbank[idx]] <= tRAS - 1;
			rrdtim <= tRRD - 1;
			bankact[mbank[idx]] <= 1;
		end
		CMDPRE: begin
			ddrba <= mbank[idx];
			ddra[10] <= 0;
			banktim[mbank[idx]] <= tRP - 1;
			bankact[mbank[idx]] <= 0;
		end
		CMDWR: begin
			ddrba <= mbank[idx];
			ddra[10] <= 0;
			ddra[8:0] <= mcol[idx];
			memack[idx] <= 1;
			for(j = 0; j < BLEN; j = j + 1) begin
				datq[1+j] <= j <= mlen[idx] ? DWRITE : DNWRITE;
				datqba[1+j] <= mbank[idx];
				datqport[1+j] <= idx;
				datqfin[1+j] <= j == mlen[idx];
			end
			datq[1+BLEN] <= DDQSZ;
			memready[idx] <= 1;
			mactive[idx] <= 0;
		end
		CMDRD: begin
			ddrba <= mbank[idx];
			ddra[10] <= 0;
			ddra[8:0] <= mcol[idx];
			for(j = 0; j < BLEN; j = j + 1) begin
				datq[CAS+j] <= j <= mlen[idx] ? DREAD : DNREAD;
				datqba[CAS+j] <= mbank[idx];
				datqport[CAS+j] <= idx;
				datqfin[CAS+j] <= j == mlen[idx];
			end
			memready[idx] <= 1;
			mactive[idx] <= 0;
		end
		endcase

		if(initdone)
			memready <= -1;
		for(j = 0; j < PORTS; j = j + 1) begin
			if(memready[j] && memreq[j]) begin
				mcol[j] <= {maddr[j][7:0], 1'b0};
				mrow[j] <= maddr[j][20:8];
				mbank[j] <= maddr[j][22:21];
				mlen[j] <= memlen[2 * j +: 2];
				mwr[j] <= memwr[j];
				mage[j] <= -1;
				mactive[j] <= 1;
				memready[j] <= 0;
			end
		end
		rd <= datq[0] == DREAD;
		rdport <= datqport[0];
		if(rd) begin
			memrdata <= ddrdqi;
			memack[rdport] <= 1;
		end else
			memrdata <= 'bx;
		if(datq[2] == DWRITE)
			memack[datqport[1]] <= 1;
	end
	
	wire refup = refitim == 0 && refctr != 15 && !init;
	wire refdown = cmd_ == CMDREFR && bankact == 0;
	initial begin
		refitim = 0;
		refctr = 0;
	end
	always @(posedge clk) begin
		if(refitim != 0)
			refitim <= refitim - 1;
		else
			refitim <= tREFI;
		if(0 && refup && !refdown)
			refctr <= refctr + 1;
		if(refdown && !refup)
			refctr <= refctr - 1;
	end
	
	reg [9:0] initstate;
	reg [19:0] initctr;
	
	initial begin
		ddrcke = 0;
		initctr = tINIT;
		initstate = 0;
		init = 1;
		/*
		`ifdef SIMULATION
		memready = -1;
		init = 0;
		`endif
		*/
	end
	
	always @(posedge clk) begin
		if(initctr != 0)
			initctr <= initctr - 1;
		else if(init)
			initstate <= initstate + 1;
		if(initdone)
			init <= 0;
	end
	
	always @(*) begin
		initcke = 1;
		initcmd = CMDNOP;
		inita = 'bx;
		initba = 'bx;
		initdone = 0;
		case(initstate)
		0: initcke = initctr == 0;
		1, 2+2*tMRD: begin
			initcmd = CMDPRE;
			inita[10] = 1;
		end
		2: begin
			initcmd = CMDMODE;
			inita = EMRS;
			initba = 2'b01;
		end
		2+tMRD: begin
			initcmd = CMDMODE;
			inita = MRS;
			initba = 2'b00;
		end
		2+2*tMRD+tRP, 2+2*tMRD+tRP+tRFC: initcmd = CMDREFR;
		2+2*tMRD+tRP+2*tRFC: begin
			initcmd = CMDMODE;
			inita = MRS;
			initba = 2'b00;
		end
		2+2*tMRD+tRP+2*tRFC+tINIT2: initdone = 1;
		endcase
	end
endmodule
