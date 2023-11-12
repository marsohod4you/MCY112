
module TopModule(
	input wire clk,
	
	//keys & leds
	input wire  [1:0]key,
	output wire [7:0]led,
	//7-Segment Indicator
	output wire seg_a,
	output wire seg_b,
	output wire seg_c,
	output wire seg_d,
	output wire seg_e,
	output wire seg_f,
	output wire seg_g,
	output wire seg_p,
	output wire [3:0]seg_sel,

	//serial
	input  wire serial_rx,
	output wire serial_tx,

	//PCM1801 or PCM 1808 ADC
	output wire pcm_scki,
	output wire pcm_lrck,
	output wire pcm_bck,
	//output wire pcm_cfg_fmt,
	//output wire pcm_cfg_md0,
	//output wire pcm_cfg_md1,
	input wire  pcm_dout,

	//audio output delta-sigma
	output wire sound_out_l,
	output wire sound_out_r,
	
	//serial flash interface
	output wire flash_csb,
	output wire flash_clk,
	inout  wire flash_io0,
	inout  wire flash_io1,
	inout  wire flash_io2,
	inout  wire flash_io3,

	//Raspberry GPIO pins
	//inout wire gpio0, //JTAG TMS
	//inout wire gpio1, //JTAG TDO
	inout wire gpio2,
	inout wire gpio3,
	inout wire gpio4,
	inout wire gpio5,
	inout wire gpio6,
	//inout wire gpio7, //JTAG TCK
	inout wire gpio8,
	inout wire gpio9,
	inout wire gpio10,
	//inout wire gpio11, //JTAG TDI
	inout wire gpio12,
	inout wire gpio13,
	inout wire gpio14,
	inout wire gpio15,
	inout wire gpio16,
	inout wire gpio17,
	inout wire gpio18,
	inout wire gpio19,
	inout wire gpio20,
	inout wire gpio21,
	inout wire gpio22,
	inout wire gpio23,
	inout wire gpio24,
	inout wire gpio25,
	inout wire gpio26,
	inout wire gpio27,
	inout wire [27:0]gpio_a,
	inout wire [22:0]gpio_b,
	input wire [2:0]RESERVE,

	output wire [11:0]mem_a,
	output wire [1:0]mem_ba,
	output wire mem_cs,
	output wire mem_cke,
	output wire mem_clk,
	output wire [3:0]mem_dqm,
	output wire mem_ras,
	output wire mem_cas,
	output wire mem_we,
	inout  wire [31:0]mem_dq
);

wire clk24;
MyPLL mypll_inst(
	.inclk0(clk),
	.c0(clk24)
);

reg [1:0]div_cnt=0;
wire clk6; assign clk6 = div_cnt[1];
always @(posedge clk24)
	div_cnt<=div_cnt+1;

assign pcm_scki = clk24;

wire [15:0]Lchannel;
wire [15:0]Rchannel;
pcm1801 pcm1801_inst(
	.scki(clk24),
	.dout(pcm_dout),
	.lrck(pcm_lrck),
	.bck(pcm_bck),
	.Left(Lchannel),
	.Right(Rchannel)
	);
/*
function [15:0] fbit_reverse ( input [15:0] data );
integer i;
begin
  for ( i=0; i<16; i=i+1 )
    begin
      fbit_reverse[15-i] = data[i];
    end
  end
endfunction

reg [15:0]Lchannel_rev;
reg [15:0]Rchannel_rev;
always @(posedge clk6)
begin
	Lchannel_rev <= fbit_reverse( Lchannel );
	Rchannel_rev <= fbit_reverse( Rchannel );
end
*/

reg [15:0]Lchannel_r;
reg [15:0]Rchannel_r;
always @(posedge clk6)
begin
	Lchannel_r <= Lchannel;
	Rchannel_r <= Rchannel;
end

reg [1:0]lrck_edge_r;
wire lrck_edge; assign lrck_edge = (lrck_edge_r==2'b01);
always @(posedge clk6)
	lrck_edge_r <= {lrck_edge_r[0],pcm_lrck};

reg [49:0]serial;
always @(posedge clk6)
	if(lrck_edge)
		serial <= {
			//stop, flag, body,           start
			1'b1,   1'b0, Rchannel_r[14:8], 1'b0,
			1'b1,   1'b0, Rchannel_r[6 :0], 1'b0,
			1'b1,   1'b0, Lchannel_r[14:8], 1'b0,
			1'b1,   1'b0, Lchannel_r[6 :0], 1'b0,
			1'b1,   1'b1, 3'b000, Rchannel_r[15],Rchannel_r[7],Lchannel_r[15],Lchannel_r[7],1'b0,
			}; //load
	else
		serial <= {1'b1,serial[49:1]}; //shift out LSB first

assign serial_tx = serial[0];

assign led = 8'h55;

/*
assign flash_io0 = 1'b0;
assign flash_io1 = 1'b0;
assign flash_io2 = 1'b0;
assign flash_io3 = 1'b0;
assign flash_clk = 1'b0;

assign seg_sel = 4'b0000;

//	bAfCgD.e  
assign seg_b = 1'b0;
assign seg_a = 1'b0;
assign seg_f = 1'b0;
assign seg_c = 1'b0;
assign seg_g = 1'b0;
assign seg_d = 1'b0;
assign seg_p = 1'b0;
assign seg_e = 1'b0;

assign sound_out_l = 1'b0; 
assign sound_out_r = 1'b0; 
*/

endmodule
