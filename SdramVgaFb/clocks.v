
///////////////////////////////////////////////////////////////
//module which generates all necessary clocks in system
///////////////////////////////////////////////////////////////

module clocks (
	input wire clk_100Mhz,
	output reg reset,
	output reg mem_clk = 0,
	output reg mem_clkx = 0,
	output reg video_clk = 0
	);
	
`ifdef __ICARUS__ 
//simplified reset and clock generation for simulator
reg [3:0]rst_delay = 0;
always @(posedge clk_100Mhz)
	rst_delay <= { rst_delay[2:0], 1'b1 };

always @*
	reset = ~rst_delay[3];

always @*
begin
	//# 3.38 mem_clk = ~mem_clk;
	mem_clk  = clk_100Mhz;
	mem_clkx = clk_100Mhz;
end
	
always
	#6.7 video_clk = ~video_clk;

	
`else

//use Quartus PLLs for real clock and reset synthesis
wire w_locked;
wire w_video_clk;
wire w_mem_clk;
wire w_mem_clkx;
CPLL u_pll(
	.inclk0(clk_100Mhz),
	.c0(w_video_clk),
	.c1(w_mem_clk),
	.e0(w_mem_clkx),
	.locked(w_locked)
	);
	
always @*
begin
	reset = ~w_locked;
	mem_clk    = w_mem_clk;
	mem_clkx   = w_mem_clkx;
	video_clk  = w_video_clk;
end

`endif

endmodule

