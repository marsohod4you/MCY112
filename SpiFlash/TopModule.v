
module TopModule(
	input wire clk, //100MHz on MCY112 FPGA board
	
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

	//SDRAM
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

wire clk50;
wire clk100;
MyPLL mypll_inst(
	.inclk0(clk),
	.c0(clk50),
	.c1(clk100)
);

reg [3:0]rst_cnt = 0;
always @(posedge clk100)
	if(rst_cnt!=4'hF)
		rst_cnt<=rst_cnt+1;
wire reset; assign reset = ~(rst_cnt==4'hF);

wire [7:0]rbyte;
wire [3:0]num_bits;
wire rbyte_ready;
serial2spi serial2spi_inst(
	.reset(reset),
	.clk(clk100),	//100MHz
	
	//serial interface to PC
	.rx(serial_rx),
	.tx(serial_tx),
	
	.rx_byte(rbyte),
	.rbyte_ready(rbyte_ready),

	//spi interface to flash
	.spi_csb(flash_csb),
	.spi_clk(flash_clk),
	.spi_do(flash_io0),
	.spi_di(flash_io1)
	);
	
assign flash_io2 = 1'b1;
assign flash_io3 = 1'b1;

reg [7:0]rxbyte;
always @(posedge clk100 )
	if( key[0]==1'b0 ) //reset
		rxbyte <= 0;
	else
	if(rbyte_ready)
		rxbyte <= rbyte;

//KEYs & LEDs
reg [31:0]counter=32'hF0F0F0F0;
always @(posedge clk50)
	if( key[0]==1'b0 ) //reset
		counter <= 32'h0;
	else
	if( key[1]==1'b0 ) //count backward
		counter <= counter-1;
	else
		counter <= counter+1;

assign led = {
			counter[24],
			counter[25],
			counter[26],
			counter[27],
			counter[28],
			counter[29],
			counter[30],
			counter[31]
			};

// 7-Segment Dynamic display
wire [7:0]seg;
seg4x7 seg4x7_inst(
	.clk( clk50 ),
	.in( { counter[31:24], rxbyte } ),
	.digit_sel( seg_sel ),
	.out( seg )
);

//	7-Segment pins: bAfCgD.e  
assign seg_b = seg[7];
assign seg_a = seg[6];
assign seg_f = seg[5];
assign seg_c = seg[4];
assign seg_g = seg[3];
assign seg_d = seg[2];
assign seg_p = seg[1];
assign seg_e = seg[0];

endmodule
