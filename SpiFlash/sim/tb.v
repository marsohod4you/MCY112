
`timescale 1 ns / 1 ps

module testbench;
	reg clk = 1'b0;
	always #5 clk = ~clk;

	reg reset = 1'b1;
	
	reg [7:0]byte4send = 8'h00;
	reg send = 1'b0;

	wire serial_rx, serial_tx;
	wire tx_busy;
	wire [7:0]rx_byte;
	wire rx_byte_ready;
	serial sr_inst(
		.reset( reset ),
		.clk100( clk ),
		.rx( serial_rx ),
		.tx( serial_tx ),
		.sbyte( byte4send ),
		.send( send ),
		.busy(tx_busy), 
		.rx_byte( rx_byte ),
		.rbyte_ready( rx_byte_ready )
	);

	wire spi_csb, spi_clk, spi_do, spi_di;
	serial2spi #(.RCONST(64) ) sr2spi(
		.reset( reset ),
		.clk( clk ),	//100MHz
	
		//serial interface to PC
		.rx( serial_tx ),
		.tx( serial_rx ),
		//spi interface to flash
		.spi_csb( spi_csb ),
		.spi_clk( spi_clk ),
		.spi_do( spi_do ),
		.spi_di( spi_di )
	);
	
	wire io2,io3;
	/*
	spiflash spiflash_(
		.csb(spi_csb),
		.clk(spi_clk),
		.io0(spi_do),
		.io1(spi_di),
		.io2(io2),
		.io3(io3)
	);
	*/
	
	P25Q32H P25Q32H_( 
		.SCLK(spi_clk),
        .CSb(spi_csb), 
        .SI(spi_do), 
        .SO(spi_di), 
        .WPb(io2), 
        .SIO3(io3)
		); 

	assign io2 = 1'b1;
	assign io3 = 1'b1;

	initial begin
		$dumpfile("testbench.vcd");
		$dumpvars(0, testbench);

		#50;
		reset = 1'b0;
		#50;

		send_uart( 8'hAB );
		send_uart( 8'h00 );
		send_uart( 8'h00 );
		send_uart( 8'h00 );
		send_uart( 8'h00 );
		#30000;
		send_uart( 8'h9F );
		send_uart( 8'h00 );
		send_uart( 8'h00 );
		send_uart( 8'h00 );
		#20000;
		$finish;
	end

task send_uart(input [7:0] txdata);
begin
    @(posedge clk);
    if (tx_busy) @(negedge tx_busy);

    @(posedge clk);
	byte4send = {txdata[0],txdata[1],txdata[2],txdata[3],txdata[4],txdata[5],txdata[6],txdata[7]};
	send = 1'b1;
    @(posedge clk);
	send = 1'b0;
end endtask
	
endmodule
