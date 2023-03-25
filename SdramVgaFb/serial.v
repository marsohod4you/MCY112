  
module serial(
	input wire clk, //80MHz or 100MHz, but set RCONST param properly for baudrate
	input wire rx,
	output reg [7:0]rx_byte,
	output reg rbyte_ready,
	output wire [3:0]onum_bits
	);

//parameter RCONST = 694; // 80000000Hz / 115200bps = 694
//parameter RCONST = 902; // 104000000Hz / 115200bps = 902
parameter RCONST = 25;
//parameter RCONST = 29;

reg [1:0]shr;
always @(posedge clk)
	shr <= {shr[0],rx};
wire rxf; assign rxf = shr[1];

reg [15:0]cnt = 0;
reg [3:0]num_bits = 10;
assign onum_bits = num_bits;
wire num_bits10; assign num_bits10 = (num_bits==10);

always @( posedge clk )
begin
	if(cnt == RCONST || num_bits10)
		cnt <= 0;
	else
		cnt <= cnt + 1'b1;
end

reg [7:0]shift_reg = 0;
wire middle; assign middle = (cnt == RCONST/2);

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
end

always @( posedge clk )
	if(num_bits==9 && middle)
		rx_byte <= shift_reg[7:0];

reg [1:0]flag = 0;
always @(posedge clk )
	flag <= {flag[0],num_bits10};

always @( posedge clk )
	rbyte_ready <= (flag==2'b01);
	
endmodule
