/**********************************************************************
      Module:            dp_mem_1clk_p
      Description: This module contains a flip flop based dual port memory array.
                   pipelined output
*								Its width, depth and address width are configurable.
==============================================================================*/
`timescale 1ns/1ps

module dp_mem_1clk_p #( parameter DATA_WIDTH = 16, ADDR_WIDTH = 5, RAM_DEPTH = (1 << ADDR_WIDTH))  (
	input Clk,
	input Reset_N,
	input we,
	input rd,
	input [ADDR_WIDTH-1 : 0] wr_addr,
	input [ADDR_WIDTH-1 : 0] rd_addr,
	input [DATA_WIDTH-1 : 0] data_in,
	output reg [DATA_WIDTH-1 : 0] data_out 
	);


	integer i,j;
	
	reg [DATA_WIDTH-1 : 0] mem [RAM_DEPTH-1 : 0];
	
	
	// data-out
	always@(posedge Clk or negedge Reset_N)
		begin
			if(!Reset_N) 
                data_out <= 0;
			else if (rd) 
                data_out <= mem[rd_addr];
		end
	
	// memory array
	always@(posedge Clk or negedge Reset_N)
		begin
			if(!Reset_N)
				begin
					for(i = 0; i<RAM_DEPTH; i=i+1)
						mem[i] <= 0;
				end
			else if (we)
				begin
						mem[wr_addr] <= data_in;
				end
		end //always


endmodule
