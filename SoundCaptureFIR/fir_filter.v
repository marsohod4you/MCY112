`timescale 1ns/1ps

module fir_filter(
		input wire nreset,
		input wire clk,						//idata sampling frequency
		input wire [15:0]idata,				//samples unsigned
		output reg signed [47:0]out_val,
		output reg out_ready
	);

reg  [8:0]rd_addr;
reg  [8:0]wr_addr;

//read samples from cyclic buffer
always @(posedge clk or negedge nreset)
	if( ~nreset )
		rd_addr <= 0;
	else
		rd_addr <= rd_addr + 1;

//"wr" signal -> writes new sample to cyclic buffer
reg wr;
always @(posedge clk or negedge nreset)
	if( ~nreset )
		wr <= 1'b0;
	else
		wr <= (rd_addr==9'h1ff);

always @(posedge clk or negedge nreset)
	if( ~nreset )
		wr_addr <= 0;
	else
	if( rd_addr==9'h1ff )
		wr_addr <= wr_addr + 1;

wire signed [15:0]odata;

//cyclic buffer for samples
`ifdef ICARUS
dp_mem_1clk_p #( .DATA_WIDTH(16), .ADDR_WIDTH(9), .RAM_DEPTH(1 << 9) )mem_samples
	(
	.Clk( clk ),
	.Reset_N( nreset ),
	.we( wr ),
	.rd( nreset ),
	.wr_addr( wr_addr ),
	.rd_addr( rd_addr ),
	.data_in( idata ),
	.data_out( odata )
	);
`else
fir_ram	fir_ram_inst (
	.clock ( clk ),
	.data ( idata ),
	.rdaddress ( rd_addr ),
	.wraddress ( wr_addr ),
	.wren ( wr ),
	.q ( odata )
	);
`endif

//fir coefficients contiguously extracted from filter embeddef memory
wire [8:0]rd_addr_coeff; 
assign rd_addr_coeff = 512 - rd_addr + wr_addr;
wire signed [15:0]fir_coeff;

`ifdef ICARUS
dp_mem_1clk_p #( .DATA_WIDTH(16), .ADDR_WIDTH(9), .RAM_DEPTH(1 << 9) )mem_coeff
	(
	.Clk( clk ),
	.Reset_N( nreset ),
	.we( 1'b0 ),
	.rd( nreset ),
	.wr_addr( 9'd0 ),
	.rd_addr( rd_addr_coeff ),
	.data_in( 16'd0 ),
	.data_out( fir_coeff )
	);
`else
fir_rom fir_rom_inst (
	.address ( rd_addr_coeff ),
	.clock ( clk ),
	.q ( fir_coeff )
	);
`endif

reg signed [47:0]filter_val_acc;
always @(posedge clk or negedge nreset)
	if( ~nreset )
	begin
		out_val <= 0;
		filter_val_acc <=0;
	end
	else
	if( wr )
	begin
		out_val <= filter_val_acc;
		filter_val_acc <= fir_coeff * odata;
	end
	else
	begin
		filter_val_acc <= filter_val_acc + fir_coeff * odata;
	end

always @( posedge clk or negedge nreset )
	if( ~nreset )
		out_ready <= 0;
	else
		out_ready <= wr;

endmodule
