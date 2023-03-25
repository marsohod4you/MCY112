
module memwriter(
	input wire  reset,
	input wire  mem_clk,
	input wire  mem_idle,
	input wire  mem_ack,
	input wire  mem_data_next,
	output wire [24:0]mem_wr_addr,
	output reg  mem_wr_req,
	output wire [31:0]mem_wr_data,
	
	input wire  sr_data_rdy,	//data arrived from serial port
	input wire  [7:0]sr_data, 	//data from ftdi chip
	output reg dbg
);

localparam CMD_SIGNATURE		= 16'hAA55;
localparam STATE_READ_CMD_BYTE	= 0;
localparam STATE_WAIT_MORE_DATA	= 1;
localparam STATE_READ_ADDR_BYTE	= 2;
localparam STATE_READ_PIX_BYTE 	= 3;
localparam STATE_WAIT_WRWND 	= 4;
localparam STATE_WRITE_PIXEL 	= 5;
localparam STATE_WAIT_WRITTEN 	= 6;

assign mem_wr_addr = addr[24:0];
reg [31:0]pixel = 0;
assign mem_wr_data = pixel;
	
wire [1:0]w_wr_level;

wire [7:0]w_fifo_outdata;
wire w_fifo_empty;
wire [1:0]w_rd_level;
wire w_read_fifo; assign w_read_fifo =  
	(w_read_addr_byte | w_read_pix_byte | w_read_cmd_byte );

//we need fifo for synchronizing FTDI clock to memory clock
`ifdef __ICARUS__	
generic_fifo_sc_a #( .dw(8), .aw(8) ) u_sr_fifo(
	.clk(mem_clk),
	.rst(~reset),
	.clr(),
	.din(sr_data),
	.we(sr_data_rdy),
	.dout(w_fifo_outdata),
	.re(w_read_fifo),
	.full(),
	.empty(),
	.full_r(),
	.empty_r(w_fifo_empty),
	.full_n(),
	.empty_n(),
	.full_n_r(),
	.empty_n_r(),
	.level(w_wr_level)
	);
assign fifo_has_space = (w_wr_level<2'b11);
`else
//Quartus native FIFO;
wire [9:0]w_usedw;
wrfifo u_wrfifo(
	.sclr(reset),
	.clock(mem_clk),
	.data(sr_data),
	.rdreq(w_read_fifo),
	.wrreq(sr_data_rdy),
	.q(w_fifo_outdata),
	.empty(w_fifo_empty),
	.usedw(w_usedw),
	);
assign fifo_has_space = (w_usedw<60);
`endif

reg [7:0]state;

//fetching command (4 bytes) from FIFO
reg  [31:0]cmd=0;
wire w_read_cmd_byte; assign w_read_cmd_byte = ~w_fifo_empty & (state==STATE_READ_CMD_BYTE) & ~sign_ok;
reg  r_read_cmd_byte = 1'b0;
always @(posedge mem_clk)
begin
	r_read_cmd_byte <= w_read_cmd_byte;
	if( r_read_cmd_byte )
		cmd  <= { w_fifo_outdata, cmd[31:8]};
end

wire [15:0]cmd_sign; assign cmd_sign = { w_fifo_outdata,cmd[31:24] }; //expect signature in hi-word
wire sign_ok; assign sign_ok = (cmd_sign==CMD_SIGNATURE && r_read_cmd_byte );
wire [15:0]len; assign len = cmd[15:0];

//fetching address from FIFO
reg [31:0]addr = 0;
wire addr_is_mem = ~addr[31];

//counter of fetched address bytes (need 4 bytes)
reg [1:0]num_addr_bytes = 0;

//fetch address byte
wire w_read_addr_byte; assign w_read_addr_byte = ~w_fifo_empty & (state==STATE_READ_ADDR_BYTE) & ~addr_ok;
reg  r_read_addr_byte = 1'b0;
wire addr_ok; assign addr_ok = (num_addr_bytes==2'b11 && r_read_addr_byte );
always @(posedge mem_clk)
begin
	r_read_addr_byte <= w_read_addr_byte;
	if( state==STATE_READ_CMD_BYTE )
		num_addr_bytes <= 2'b00;
	else
	if( r_read_addr_byte )
	begin
		addr <= { w_fifo_outdata, addr[31:8]};
		num_addr_bytes <= num_addr_bytes + 1;
	end
	else
	if( state==STATE_WAIT_WRITTEN && mem_data_next )
		addr <= addr + 1;
end

//count fetched pixel bytes (need 4 bytes)
reg [1:0]num_pix_bytes = 2'b00;

//fetch pixels byte
wire w_read_pix_byte; assign w_read_pix_byte = ~w_fifo_empty & (state==STATE_READ_PIX_BYTE) & ~pixel_ok;
reg  r_read_pix_byte = 1'b0;
wire pixel_ok; assign pixel_ok = (num_pix_bytes==2'b11 && r_read_pix_byte);
reg r_pixel_ok;
always @(posedge mem_clk)
begin
	r_read_pix_byte <= w_read_pix_byte;
	if( r_read_pix_byte )
		pixel <= { w_fifo_outdata, pixel[31:8]};

	if( r_read_pix_byte )
		num_pix_bytes <= num_pix_bytes + 1;
	else
	if( mem_data_next || state==STATE_READ_CMD_BYTE )
		num_pix_bytes <= 3'b000;
		
	if( pixel_ok)
		r_pixel_ok <=1;
	else
	if( mem_data_next || state==STATE_READ_CMD_BYTE )
		r_pixel_ok <=0;
end

reg [11:0]wr_data_cnt = 0;
always @(posedge mem_clk)
	if( state==STATE_READ_ADDR_BYTE )
		wr_data_cnt <= 0;
	else
	if( mem_data_next )
		wr_data_cnt <= wr_data_cnt + 1;

always @( posedge mem_clk )
	if(reset | mem_ack)
		mem_wr_req  <= 1'b0;
	else
	if( r_pixel_ok & addr_is_mem & state==STATE_WRITE_PIXEL )
		mem_wr_req <= 1'b1;

reg[7:0]num_wait;
always @(posedge mem_clk)
begin
	if( state==STATE_WRITE_PIXEL)
		num_wait<=0;
	else
	if(	state==STATE_WAIT_WRITTEN)
		num_wait<=num_wait+1;
	dbg<=num_wait[7];
end

always @( posedge mem_clk )
	if(reset)
	begin
		state <= STATE_READ_CMD_BYTE;
	end
	else
	case(state)
		STATE_READ_CMD_BYTE: begin
			if(sign_ok)
				state <= STATE_WAIT_MORE_DATA;
			end
		STATE_WAIT_MORE_DATA: begin
				//if( w_usedw>12 )
					state <= STATE_READ_ADDR_BYTE;
			end
		STATE_READ_ADDR_BYTE: begin
			if(addr_ok)
				state <= STATE_READ_PIX_BYTE;
			end
		STATE_READ_PIX_BYTE: begin
			if(pixel_ok & addr_is_mem)
				state <= STATE_WAIT_WRWND;
			end
		STATE_WAIT_WRWND: begin
			if( mem_idle )
				state <= STATE_WRITE_PIXEL;
			end
		STATE_WRITE_PIXEL: begin
			if( mem_ack )
				state <= STATE_WAIT_WRITTEN;
			end
		STATE_WAIT_WRITTEN: begin
			if( mem_data_next )
				state <= (wr_data_cnt==len-1) ? STATE_READ_CMD_BYTE : STATE_READ_PIX_BYTE;
			end
	endcase

endmodule
