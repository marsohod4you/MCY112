/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifdef PICOSOC_V
`error "picorv32soc.v must be read before picosoc.v!"
`endif

module picorv32soc (
	input wire clk,

	input  wire [1:0]key,
	output wire [7:0]led,
	
	//dynamic 7-Segment Indicator
	output wire seg_a,
	output wire seg_b,
	output wire seg_c,
	output wire seg_d,
	output wire seg_e,
	output wire seg_f,
	output wire seg_g,
	output wire seg_p,
	output wire [3:0]seg_sel,
	
	input  wire serial_rx,
	output wire serial_tx,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3
);

// 1024 32bit words = 4096 bytes memory
localparam MEM_WORDS = 1024;

//Clocks and Reset
wire sysclk;
`ifdef IVERILOG
assign sysclk = clk;
`else
wire locked;
MyPLL mypll_inst(
	.inclk0( clk),
	.c0( sysclk ),
	.locked( locked )
	);
`endif

reg [3:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @( posedge sysclk )
	if(key[0]==0)
		resetn_counter<=0;
	else
	if ( !resetn )
		resetn_counter <= resetn_counter + 1;

wire flash_io0_oe, flash_io0_do, flash_io0_di;
wire flash_io1_oe, flash_io1_do, flash_io1_di;
wire flash_io2_oe, flash_io2_do, flash_io2_di;
wire flash_io3_oe, flash_io3_do, flash_io3_di;
	
/*
	SB_IO #(
		.PIN_TYPE(6'b 1010_01),
		.PULLUP(1'b 0)
	) flash_io_buf [3:0] (
		.PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
		.OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
		.D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
		.D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
	);
*/

assign flash_io0_di = flash_io0;
assign flash_io1_di = flash_io1;
assign flash_io2_di = flash_io2;
assign flash_io3_di = flash_io3;

assign flash_io0 = flash_io0_oe ? flash_io0_do : 1'bz;
assign flash_io1 = flash_io1_oe ? flash_io1_do : 1'bz;
assign flash_io2 = flash_io2_oe ? flash_io2_do : 1'bz;
assign flash_io3 = flash_io3_oe ? flash_io3_do : 1'bz;

wire        iomem_valid;
reg         iomem_ready;
wire [3:0]  iomem_wstrb;
wire [31:0] iomem_addr;
wire [31:0] iomem_wdata;
reg  [31:0] iomem_rdata;

reg [7:0]  rled;
reg [15:0] rseg7;

always @(posedge sysclk) begin
	if (!resetn) begin
		rled <= 0;
		rseg7 <=0;
	end else begin
		iomem_ready <= 0;
		if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h03) begin
			iomem_ready <= 1;
			if(iomem_addr[3:0] == 4'h 0) begin
				iomem_rdata <= { 24'h000000, rled };
				if (iomem_wstrb[0]) rled[ 7: 0] <= iomem_wdata[ 7: 0];
			end else
			if(iomem_addr[3:0] == 4'h 4) begin
				iomem_rdata <= { 16'h0000, rseg7 };
				if (iomem_wstrb[0]) rseg7[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) rseg7[15: 8] <= iomem_wdata[15: 8];
			end
		end
	end
end

assign led = rled;

wire [7:0]seg_leds;
seg4x7 seg4x7_inst(
	.clk( clk ),
	.in( rseg7 ),
	.digit_sel( seg_sel ),
	.out( seg_leds )
);

//	bAfCgD.e  
assign seg_b = seg_leds[7];
assign seg_a = seg_leds[6];
assign seg_f = seg_leds[5];
assign seg_c = seg_leds[4];
assign seg_g = seg_leds[3];
assign seg_d = seg_leds[2];
assign seg_p = seg_leds[1];
assign seg_e = seg_leds[0];

picosoc 
	#( .MEM_WORDS(MEM_WORDS) )
	soc (
	.clk          (sysclk      ),
	.resetn       (resetn      ),

	.ser_tx       (serial_tx   ),
	.ser_rx       (serial_rx   ),

	.flash_csb    (flash_csb   ),
	.flash_clk    (flash_clk   ),

	.flash_io0_oe (flash_io0_oe),
	.flash_io1_oe (flash_io1_oe),
	.flash_io2_oe (flash_io2_oe),
	.flash_io3_oe (flash_io3_oe),

	.flash_io0_do (flash_io0_do),
	.flash_io1_do (flash_io1_do),
	.flash_io2_do (flash_io2_do),
	.flash_io3_do (flash_io3_do),

	.flash_io0_di (flash_io0_di),
	.flash_io1_di (flash_io1_di),
	.flash_io2_di (flash_io2_di),
	.flash_io3_di (flash_io3_di),

	.irq_5        (1'b0        ),
	.irq_6        (1'b0        ),
	.irq_7        (1'b0        ),

	.iomem_valid  (iomem_valid ),
	.iomem_ready  (iomem_ready ),
	.iomem_wstrb  (iomem_wstrb ),
	.iomem_addr   (iomem_addr  ),
	.iomem_wdata  (iomem_wdata ),
	.iomem_rdata  (iomem_rdata )
);

endmodule

`ifdef IVERILOG
`else
`define PICOSOC_MEM altera_sram
module altera_sram(
		input wire clk,
		input wire [3:0]wen,
		input wire [15:0]addr,
		input wire [31:0]wdata,
		output wire [31:0]rdata
		);
parameter WORDS = 1024; //unused..

SRAM SRAM_inst (
	.clock ( clk ),
	.address ( addr ),
	.byteena ( wen ),
	.wren ( |wen ),
	.data ( wdata ),
	.q ( rdata )
	);
endmodule

`endif
	
