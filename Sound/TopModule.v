
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

wire clk60;
wire clk100;
MyPLL mypll_inst(
	.inclk0(clk),
	.c0(clk60),
	.c1(clk100)
);

//Serial
//assign serial_tx = serial_rx;

wire [7:0]rbyte;
wire [3:0]num_bits;
wire rbyte_ready;
serial serial_inst(
	.clk( clk100 ),
	.rx( serial_rx ),
	.rx_byte(rbyte),
	.rbyte_ready(rbyte_ready),
	.onum_bits(num_bits)
);

reg [7:0]rxbyte0;
reg [7:0]rxbyte1;
always @(posedge clk100 )
	if(rbyte_ready)
	begin
		rxbyte0 <= rbyte;
		rxbyte1 <= rxbyte0;
	end

assign led = 8'h00;

wire [7:0]seg;
seg4x7 seg4x7_inst(
	.clk( clk60 ),
	.in( { 8'h00, 8'h00 } ),
	.digit_sel( seg_sel ),
	.out( seg )
);

//	bAfCgD.e  
assign seg_b = seg[7];
assign seg_a = seg[6];
assign seg_f = seg[5];
assign seg_c = seg[4];
assign seg_g = seg[3];
assign seg_d = seg[2];
assign seg_p = seg[1];
assign seg_e = seg[0];

wire audio_out;
AudioDac AudioDac_inst(
	.Clk( clk100 ),
	.DACin( {2'b00,rxbyte0[7:2]} ),
	.DACout(audio_out)
	);

assign sound_out_l = key[0] & audio_out; 
assign sound_out_r = key[1] & audio_out; 

reg [2:0]div_cnt;
reg scki;
always @(posedge clk)
begin
	if(div_cnt==3)
		div_cnt<=0;
	else
		div_cnt<=div_cnt+1;
	scki<=(div_cnt<=1);
end

assign pcm_scki = scki;

wire [15:0]Lchannel;
wire [15:0]Rchannel;
pcm1801 pcm1801_inst(
	.scki(scki),
	.dout(pcm_dout),
	.lrck(pcm_lrck),
	.bck(pcm_bck),
	.Left(Lchannel),
	.Right(Rchannel)
	);

assign flash_io0 = 1'b0;
assign flash_io1 = 1'b0;
assign flash_io2 = 1'b0;
assign flash_io3 = 1'b0;
assign flash_clk = 1'b0;

endmodule
