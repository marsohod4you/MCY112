  
module serial2spi(
	input wire reset,
	input wire clk,	//100MHz
	
	//serial interface to PC
	input wire rx,
	output reg tx,
	
	output reg [7:0]rx_byte,
	output reg rbyte_ready,

	//spi interface to flash
	output reg spi_csb = 1'b1,
	output reg spi_clk = 1'b0,
	output reg spi_do,
	input  wire spi_di
	);
	
//parameter RCONST = 868; // 100000000Hz / 115200bps = 868
parameter RCONST = 16; // 6Mbit

wire [7:0]sbyte;
reg busy;

reg [1:0]shr;
always @(posedge clk)
	shr <= {shr[0],rx};
wire rxf; assign rxf = shr[1];

reg [15:0]cnt;
reg [15:0]cnt_end_csb;

reg [3:0]num_bits = 10;
assign onum_bits = num_bits;
wire num_bits10; assign num_bits10 = (num_bits==10);
reg endpkt=1'b0;
reg [1:0]csbfix=2'b00;
reg final_send_imp;

always @( posedge clk )
begin
	if(num_bits<10)
	begin
		cnt_end_csb <= 0;
		endpkt <= 1'b0;
	end
	else
	if(cnt_end_csb<RCONST*4)
	begin
		cnt_end_csb <= cnt_end_csb + 1'b1;
		endpkt <= 1'b0;
	end
	else
		endpkt <= 1'b1 & (~busy);
	csbfix <= {csbfix[0],spi_csb};
	final_send_imp <= (csbfix==2'b01);
end

always @( posedge clk )
begin
	if(cnt == RCONST || num_bits10)
		cnt <= 0;
	else
		cnt <= cnt + 1'b1;
end

reg [7:0]shift_reg = 0;
wire middle;  assign middle  = (cnt == RCONST/2);
reg csb = 1'b1;

always @( posedge clk )
begin
	if(num_bits10 && rxf==1'b0)
		num_bits <= 0;
	else
	if(middle)
	begin
		num_bits <= num_bits + 1'b1;
		shift_reg <= {rxf,shift_reg[7:1]};
	end
	
	csb <= ~(num_bits>0 && num_bits<10);
	if(num_bits==1 )
		spi_csb <= 1'b0;
	else
	if(endpkt)
		spi_csb <= 1'b1;
	
	if(cnt == RCONST/4)
		spi_clk <= 1'b1 & (~csb) & (num_bits<9);
	else
	if(cnt == RCONST*3/4)
		spi_clk <= 1'b0;
	spi_do <= rxf;
end

//catch spi data
reg [1:0]spi_clk_r;
reg [7:0]spi_data;
reg send_imp = 1'b0;
always @( posedge clk )
begin
	spi_clk_r <= {spi_clk_r[0],spi_clk};
	send_imp <= (spi_clk_r==2'b01)&(num_bits==8) | final_send_imp;
	if(spi_clk_r==2'b01)
		spi_data <= { spi_data[6:0],spi_di };
end
assign sbyte = spi_data;

always @( posedge clk )
	if(num_bits==9 && middle)
		rx_byte <= shift_reg[7:0];

reg [1:0]flag = 0;
always @(posedge clk )
	flag <= {flag[0],num_bits10};

always @( posedge clk )
	rbyte_ready <= (flag==2'b01);

reg [8:0]send_reg;
reg [3:0]send_num;
reg [15:0]send_cnt;

wire send_time; assign send_time = send_cnt == RCONST;

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		send_reg <= 9'h1FF;
		send_num <= 10;
		send_cnt <= 0;
	end
	else
	begin
		if(send_imp)
			send_cnt <= 0;
		else
			if(send_time)
				send_cnt <= 0;
			else
				send_cnt <= send_cnt + 1'b1;
		
		if(send_imp)
		begin
			send_reg <= {sbyte,1'b0};
			send_num <= 0;
		end
		else
		if(send_time && send_num!=10)
		begin
			send_reg <= {1'b1,send_reg[8:1]};
			send_num <= send_num + 1'b1;
		end
	end
end

always @*
begin
	busy = send_num!=10;
	tx = send_reg[0];
end
	
endmodule
