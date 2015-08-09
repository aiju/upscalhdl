`include "dat.vh"

module mem #(parameter PORTS = 4) (
	input wire clk,
	
	output reg [12:0] ddra,
	output reg [1:0] ddrba,
	input wire [15:0] ddrdqi0,
	input wire [15:0] ddrdqi1,
	output wire [15:0] ddrdqo0,
	output reg [15:0] ddrdqo1,
	output wire ddrdqt,
	inout wire [1:0] ddrdqs,
	output wire ddrwe,
	output wire ddrras,
	output wire ddrcas,
	output wire ddrcs,
	output wire ddrcke,
	output wire [1:0] ddrdm,
	
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
	
	localparam tRCDns = 15;
	localparam tRASns = 40;
	localparam tRPns = 15;
	localparam tRRDns = 10;
	localparam tWRns = 15;
	
	localparam BLEN = 4;
	localparam QLEN = CAS + BLEN + 1;
	
	`define ns2MHZ(n) (((n) * MHZ + 999) / 1000)
	localparam tRCD = `ns2MHZ(tRCDns);
	localparam tRAS = `ns2MHZ(tRASns);
	localparam tRP = `ns2MHZ(tRPns);
	localparam tRRD = `ns2MHZ(tRRDns);
	localparam tWR = `ns2MHZ(tWRns);
	localparam tWTR = 2;

	reg [3:0] bankact;
	reg [3:0] banktim[0:3];
	reg [12:0] bankrow[0:3];
	reg [3:0] bankras[0:3];
	reg [3:0] rrdtim, wtrtim;
	
	reg [22:0] maddr[0:PORTS-1];
	reg [1:0] mbank[0:PORTS-1];
	reg [12:0] mrow[0:PORTS-1];
	reg [8:0] mcol[0:PORTS-1];
	reg [2:0] mlen[0:PORTS-1];
	reg [PORTS-1:0] mwr;
	reg [PORTS-1:0] mready;
	reg [PORTS-1:0] mactive;
	reg [PORTS-1:0] missued;
	
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
	
	reg [2:0] idx;
	reg nop;
	
	always @(*) begin : ready
		integer i, j;
		
		for(i = 0; i < PORTS; i = i + 1) begin
			maddr[i] = memaddr[23 * i +: 23];
			if(!mactive[i])
				mready[i] = 0;
			else if(banktim[mbank[i]] != 0)
				mready[i] = 0;
			else if(!bankact[mbank[i]])
				mready[i] = rrdtim == 0;
			else if(bankrow[mbank[i]] != mrow[i]) begin
				mready[i] = 1;
				for(j = CAS; j < QLEN; j = j + 1)
					if(datq[j] == DREAD || datq[j] == DWRITE)
						mready[i] = 0;
				if(bankras[mbank[i]] != 0 || datq[0] == DWRITE && datqba[0] == i)
					mready[i] = 0;
			end else begin
				mready[i] = 1;
				for(j = 0; j < BLEN; j = j + 1)
					if(mwr[i]) begin
						if(datq[2 + j] == DREAD || datq[2 + j] == DWRITE || datq[2 + j] == DNREAD)
							mready[i] = 0;
					end else
						if(datq[1 + CAS + j] == DREAD || datq[1 + CAS + j] == DWRITE)
							mready[i] = 0;
				if(!mwr[i] && wtrtim != 0)
					mready[i] = 0;
				if(mwr[i] && datq[1] == DREAD)
					mready[i] = 0;
				if(mwr[i] && datq[CAS] == DNREAD)
					mready[i] = 1;
			end
		end
	end

	always @(*) begin : nopidx
		integer i;
		
		nop = 1;
		idx = 'bx;
		for(i = 0; i < PORTS; i = i + 1) 
			if(mready[i]) begin
				nop = 0;
				idx = i;
			end
	end

	reg [2:0] ddrcmd;
	assign ddrcs = 0;
	assign ddrcke = 1;
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
	assign ddrdqs = datq[0] == DWRITE || datq[0] == DNWRITE ? {2{!clk}} : datq[0] == DDQSZ && clk ? 2'b00 : 2'bzz;
	assign ddrdm = datq[0] == DWRITE ? 2'b00 : 2'b11;
	wire [3:0] port1 = datqport[1];
	assign ddrdqo0 = memwdata[port1 * 32 +: 16];
	always @(posedge clk)
		ddrdqo1 <= memwdata[port1 * 32 + 16 +: 16];
	
	reg rd;
	reg [3:0] rdport;
	
	initial begin : init
		integer i;
		
		for(i = 0; i < 4; i = i + 1) begin
			bankact[i] = 0;
			banktim[i] = 0;
			bankras[i] = 0;
		end
		for(i = 0; i < QLEN; i = i + 1) begin
			datq[i] = DIDLE;
		end
		missued = 0;
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
		if(rrdtim != 0)
			rrdtim <= rrdtim - 1;
		if(datq[0] == DWRITE) begin
			wtrtim <= tWTR - 1;
			if(bankras[datqba[0]] <= tWR - 1)
				bankras[datqba[0]] <= tWR - 1;
		end else if(wtrtim != 0)
			wtrtim <= wtrtim - 1;
		
		memack <= 0;
		
		if(nop) begin
			if(datq[CAS+1] == DNREAD) begin
				ddrcmd <= CMDTERM;
				for(j = CAS; j < QLEN; j = j + 1)
					datq[j] <= DIDLE;
			end
		end else if(!bankact[mbank[idx]]) begin
			ddrcmd <= CMDACT;
			ddra <= mrow[idx];
			ddrba <= mbank[idx];
			bankrow[mbank[idx]] <= mrow[idx];
			banktim[mbank[idx]] <= tRCD - 1;
			bankras[mbank[idx]] <= tRAS - 1;
			rrdtim <= tRRD - 1;
			bankact[mbank[idx]] <= 1;
		end else if(bankrow[mbank[idx]] != mrow[idx]) begin
			ddrcmd <= CMDPRE;
			ddrba <= mbank[idx];
			ddra[10] <= 0;
			banktim[mbank[idx]] <= tRP - 1;
			bankact[mbank[idx]] <= 0;
		end else if(mwr[idx] && datq[CAS] == DNREAD) begin
			ddrcmd <= CMDTERM;
			for(j = CAS; j < QLEN; j = j + 1)
				datq[j] <= DIDLE;
		end else begin
			ddrba <= mbank[idx];
			ddra[10] <= 0;
			ddra[8:0] <= mcol[idx];
			if(mwr[idx]) begin
				memack[idx] <= 1;
				ddrcmd <= CMDWR;
				for(j = 0; j < BLEN; j = j + 1) begin
					datq[1+j] <= j <= mlen[idx] ? DWRITE : DNWRITE;
					datqba[1+j] <= mbank[idx];
					datqport[1+j] <= idx;
					datqfin[1+j] <= j == mlen[idx];
				end
				datq[1+BLEN] <= DDQSZ;
			end
			else begin
				ddrcmd <= CMDRD;
				for(j = 0; j < BLEN; j = j + 1) begin
					datq[CAS+j] <= j <= mlen[idx] ? DREAD : DNREAD;
					datqba[CAS+j] <= mbank[idx];
					datqport[CAS+j] <= idx;
					datqfin[CAS+j] <= j == mlen[idx];
				end
			end
			memready[idx] <= 1;
			mactive[idx] <= 0;
		end

		memready <= memready | ~mactive;
		for(j = 0; j < PORTS; j = j + 1) begin
			if(memready[j] && memreq[j]) begin
				mcol[j] <= {maddr[j][7:0], 1'b0};
				mrow[j] <= maddr[j][20:8];
				mbank[j] <= maddr[j][22:21];
				mlen[j] <= memlen[2 * j +: 2];
				mwr[j] <= memwr[j];
				mactive[j] <= 1;
				memready[j] <= 0;
			end
		end
		rd <= datq[0] == DREAD;
		rdport <= datqport[0];
		if(rd) begin
			memrdata <= {ddrdqi1, ddrdqi0};
			memack[rdport] <= 1;
		end else
			memrdata <= 'bx;
		if(datq[2] == DWRITE)
			memack[datqport[1]] <= 1;
	end
endmodule
