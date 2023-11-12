module AudioDac(
	input wire Clk,
	input wire [7:0]DACin,
	output reg DACout
	);

reg [9:0] DeltaAdder; // Output of Delta adder
reg [9:0] SigmaAdder; // Output of Sigma adder
reg [9:0] SigmaLatch; // Latches output of Sigma adder
reg [9:0] DeltaB; // B input of Delta adder

always @(SigmaLatch)
	DeltaB = {SigmaLatch[9], SigmaLatch[9]} << (8);

always @(DACin or DeltaB)
	DeltaAdder = DACin + DeltaB;

always @(DeltaAdder or SigmaLatch)
	SigmaAdder = DeltaAdder + SigmaLatch;

always @(posedge Clk)
begin
	SigmaLatch <= SigmaAdder;
	DACout <=  SigmaLatch[9];
end

endmodule
