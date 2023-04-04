
module top 
		(
		input wire clk,
		output wire [7:0]led,

		output wire [27:0]gpio_a,
			
		/* Interface to SDRAM chip  */
		output wire mem_clk,
		output wire mem_cke,		// SDRAM CKE
		output wire mem_cs,			// SDRAM Chip Select

		output wire mem_ras,		// SDRAM ras
		output wire mem_cas,		// SDRAM cas
		output wire mem_we,			// SDRAM write enable
		output wire [3:0]mem_dqm, 	// SDRAM Data Mask
		output wire [1:0]mem_ba,	// SDRAM Bank Enable
		output wire [11:0]mem_a,	// SDRAM Address
		inout  wire [31:0]mem_dq, 	// SDRAM Data Input/output		            
		
		input wire [1:0]key,
		input wire serial_rx,
		output wire serial_tx
	   );

//--------------------------------------------
// appliciation to SDRAM controller Interface 
//--------------------------------------------
wire app_rd_req;				// SDRAM request
wire [24:0]app_req_addr;		// SDRAM Request Address
wire [31:0]app_wr_data;			// sdr write data
wire app_req_ack;				// SDRAM request Accepted
wire app_busy_n;				// 0 -> sdr busy
wire app_wr_next_req;			// Ready to accept the next write
wire app_rd_valid;				// sdr read valid
wire app_last_rd;				// Indicate last Read of Burst Transfer
wire app_last_wr;				// Indicate last Write of Burst Transfer
wire [31:0]app_rd_data;			// sdr read data
wire w_wr_req;
wire [24:0]w_wr_addr;

wire [3:0]sdr_dqm;
assign mem_dqm = sdr_dqm;

wire [31:0]sdr_dout;
wire [3:0]sdr_den_n;
assign mem_dq[ 7: 0] = (sdr_den_n[0] == 1'b0) ? sdr_dout[ 7: 0] : 8'hZZ;
assign mem_dq[15: 8] = (sdr_den_n[1] == 1'b0) ? sdr_dout[15: 8] : 8'hZZ; 
assign mem_dq[23:16] = (sdr_den_n[2] == 1'b0) ? sdr_dout[23:16] : 8'hZZ;
assign mem_dq[31:24] = (sdr_den_n[3] == 1'b0) ? sdr_dout[31:24] : 8'hZZ;

wire [31:0]pad_sdr_din; assign pad_sdr_din = mem_dq;

wire w_sdr_init_done;
wire w_reset;
wire w_video_clk;
wire w_mem_clk;
wire w_mem_clkx;

//instance of clock generator
clocks u_clocks(
	.clk_100Mhz(clk),
	.reset(w_reset),
	.mem_clk(w_mem_clk),
	.mem_clkx(w_mem_clkx),
	.video_clk(w_video_clk)
	);

//output memory clock	
assign mem_clk = w_mem_clk;

wire [1:0]w_mem_ba;
assign mem_ba[0] = w_mem_ba[0]; 
assign mem_ba[1] = w_mem_ba[1];

//instance of SDR controller core
sdrc_core #( .APP_AW(25), .APP_DW(32), .APP_BW(4), .SDR_DW(32), .SDR_BW(4) )
	u_sdrc_core (
		.clk                (w_mem_clk		),
		.reset_n            (~w_reset		),
		.pad_clk            (w_mem_clk		),

		/* Request from app */
		.app_req            (app_rd_req | w_wr_req ),// Transfer Request
		.app_req_addr       (app_rd_req ? app_req_addr : w_wr_addr ), // SDRAM Address
		.app_req_len        (app_rd_req ? 9'd008 : 9'd001		   ), // Burst Length
		.app_req_wrap       (1'b1				),// Wrap mode request 
		.app_req_wr_n       (app_rd_req 		),// 0 => Write request, 1 => read req
		.app_req_ack        (app_req_ack		),// Request has been accepted
 		
		.app_wr_data        (app_wr_data		),
		.app_wr_en_n        ( 4'b0000 ),
		.app_rd_data        (app_rd_data		),
		.app_rd_valid       (app_rd_valid		),
		.app_last_rd        (app_last_rd		),
		.app_last_wr        (app_last_wr		),
		.app_wr_next_req    (app_wr_next_req),
		.app_req_dma_last   (app_rd_req		),
 
		/* Interface to SDRAMs */
		.sdr_cs_n           (mem_cs			),
		.sdr_cke            (mem_cke		),

		.sdr_ras_n          (mem_ras		),
		.sdr_cas_n          (mem_cas		),
		.sdr_we_n           (mem_we		    ),
		.sdr_dqm            (sdr_dqm		),
		.sdr_ba             (w_mem_ba  		),
		.sdr_addr           (mem_a		    ),
		.pad_sdr_din        (pad_sdr_din	),
		.sdr_dout           (sdr_dout		),
		.sdr_den_n          (sdr_den_n		),
 
		.sdr_init_done      (w_sdr_init_done),

		/* Parameters */
		.sdr_width			(2'b00 ),
		.cfg_colbits        (2'b00              ), //2'b00 means 8 Bit Column Address
		.cfg_req_depth      (2'h2               ), //how many req. buffer should hold
		.cfg_sdr_en         (1'b1               ),
		.cfg_sdr_mode_reg   (12'h233            ), //single location write, 8 words read
		.cfg_sdr_tras_d     (4'h4               ), //SDRAM active to precharge, specified in clocks
		.cfg_sdr_trp_d      (4'h2               ), //SDRAM precharge command period (tRP), specified in clocks.
		.cfg_sdr_trcd_d     (4'h2               ), //SDRAM active to read or write delay (tRCD), specified in clocks.
		.cfg_sdr_cas        (3'h3               ), //cas latency in clocks, depends on mode reg
		.cfg_sdr_trcar_d    (4'h7               ), //SDRAM active to active / auto-refresh command period (tRC), specified in clocks.
		.cfg_sdr_twr_d      (4'h3               ), //SDRAM write recovery time (tWR), specified in clocks
		.cfg_sdr_rfsh       (12'h800            ), //Period between auto-refresh commands issued by the controller, specified in clocks.
		.cfg_sdr_rfmax      (3'h7               )  //Maximum number of rows to be refreshed at a time(tRFSH)
	);

wire w_hsync;
wire w_vsync;
wire w_active;
wire [11:0]w_pixel_count;
wire [11:0]w_line_count;

hvsync u_hvsync(
	.reset(~w_sdr_init_done), //start video synch only when memory is ready
	.pixel_clock(w_video_clk),

	.hsync(w_hsync),
	.vsync(w_vsync),
	.active(w_active),

	.pixel_count(w_pixel_count),
	.line_count(w_line_count),
	.dbg( )
	);

wire w_rbyte_ready;
wire [7:0]rbyte;
reg  [7:0]rbyte_;

serial serial0(
	.clk( w_mem_clk ), //80MHz or 100MHz, but set RCONST param properly for baudrate
	.rx( serial_rx ),
	.rx_byte( rbyte ),
	.rbyte_ready( w_rbyte_ready ),
	.onum_bits()
	);

always @(posedge w_mem_clk)
	if(w_rbyte_ready)
		rbyte_ <= rbyte;

assign led = rbyte_;

wire [1:0]w_wr_level;

memrw memwr_(
	.reset(~w_sdr_init_done),
	.mem_clk(w_mem_clk),

	.mem_ack(app_req_ack),
	.mem_wr_req(w_wr_req),
	.mem_wr_data_next(app_wr_next_req),
	.mem_wr_addr(w_wr_addr),
	.mem_wr_data(app_wr_data),
	
	.fifo_level(w_wr_level),
	
	.mem_rd_req(app_rd_req),
	.read_addr(app_req_addr),
	
	.sr_data_rdy(w_rbyte_ready),	//data arrived from serial port
	.sr_data(rbyte),
	.dbg()
);

wire [31:0]w_fifo_out;
wire w_fifo_empty;
wire w_fifo_read; assign w_fifo_read = w_active & ~w_fifo_empty;
reg read_video_fifo;
reg read_video_fifo_;
reg [31:0]vfifo_out;
always @(posedge w_video_clk)
begin
	if(w_hsync)
		read_video_fifo <= 1'b0;
	else
	if(w_fifo_read)
		read_video_fifo <= ~read_video_fifo;
	read_video_fifo_ <= read_video_fifo;
end

reg app_rd_valid_;
always @(posedge w_mem_clk)
	app_rd_valid_ <= app_rd_valid;

`ifdef __ICARUS__ 
generic_fifo_dc_gray #( .dw(32), .aw(8) ) u_generic_fifo_dc_gray (
	.rd_clk(w_video_clk),
	.wr_clk(w_mem_clk),
	.rst(~w_reset),
	.clr(),
	.din(app_rd_data),
	.we(app_rd_valid_),
	.dout(w_fifo_out),
	.rd(read_video_fifo),
	.full(),
	.empty(w_fifo_empty),
	.wr_level(w_wr_level),
	.rd_level()
	);
`else
//Quartus native FIFO;
wire [7:0]usedw;
ViFifo u_vfifo(
	.aclr(w_reset),
	.data(app_rd_data),
	.rdclk(w_video_clk),
	.rdreq(read_video_fifo),
	.wrclk(w_mem_clk),
	.wrreq(app_rd_valid_),
	.q(w_fifo_out),
	.rdempty(w_fifo_empty),
	.wrusedw(usedw)
	);

assign w_wr_level = (usedw>=224) ? 2'b11 :
							(usedw>=196) ? 2'b10 :
							(usedw>=128)  ? 2'b01 : 2'b00;
`endif

reg [15:0]out_word;
always @(posedge w_video_clk)
begin
	if(read_video_fifo_)
		vfifo_out <= w_fifo_out;
	if(d_active)
		out_word <= ~read_video_fifo ? vfifo_out[31:16] : vfifo_out[15:0];
	else
		out_word <= 16'h0;
end

reg r_fifo_empty;
reg d_active;
reg r_hsync;
reg r_vsync;
always @(posedge w_video_clk)
begin
	r_fifo_empty <= w_fifo_empty;
	r_hsync <= w_hsync;
	r_vsync <= w_vsync;
	d_active  <= w_active;
end

//VGA signals
wire VGA_HSYNC;
wire VGA_VSYNC;
wire [4:0]VGA_BLUE;
wire [5:0]VGA_GREEN;
wire [4:0]VGA_RED;

assign VGA_BLUE = out_word[4 : 0];
assign VGA_GREEN= out_word[10: 5];
assign VGA_RED  = out_word[15:11];
assign VGA_HSYNC = r_hsync;
assign VGA_VSYNC = r_vsync;

//assign VGA_BLUE  = 0; //d_active ? (w_pixel_count[6] ? w_pixel_count[4:0] : 0) : 0;
//assign VGA_GREEN = d_active ? (w_pixel_count[7] ? w_pixel_count[5:0] : 0) : 0;
//assign VGA_RED   = d_active ? (w_pixel_count[8] ? w_pixel_count[4:0] : 0) : 0;

assign gpio_a[21:16] = {VGA_RED,1'b0};
assign gpio_a[15:10] =  VGA_GREEN;
assign gpio_a[ 9: 4] = {VGA_BLUE,1'b0};
assign gpio_a[2] = VGA_VSYNC;
assign gpio_a[3] = VGA_HSYNC;
assign gpio_a[1:0] = 0;
assign gpio_a[27:22] = 0;

endmodule
