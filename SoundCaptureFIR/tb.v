`timescale 1ns / 1ps

module tb();

reg reset;

//assume basic clock is 10Mhz
reg clk;
initial clk=0;
always
	#50 clk = ~clk;

//fir clk is sampling freq * 512
//sampling freq is 46875
reg fir_clk;
initial fir_clk=0;
always
	#20.833 fir_clk = ~fir_clk;

//function calculating sinus 
function real sin;
input x;
real x;
real x1,y,y2,y3,y5,y7,sum,sign;
begin
	sign = 1.0;
	x1 = x;
	if (x1<0)
	begin
		x1 = -x1;
		sign = -1.0;
	end
	while (x1 > 3.14159265/2.0)
	begin
		x1 = x1 - 3.14159265;
		sign = -1.0*sign;
	end  
	y = x1*2/3.14159265;
	y2 = y*y;
	y3 = y*y2;
	y5 = y3*y2;
	y7 = y5*y2;
	sum = 1.570794*y - 0.645962*y3 +
		0.079692*y5 - 0.004681712*y7;
	sin = sign*sum;
end
endfunction

//generate requested "freq" digital
integer freq;
reg [31:0]cnt;
reg cnt_edge;
always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		cnt <=0;
		cnt_edge <= 1'b0;
	end
	else
	if( cnt>=(10000000/(freq*64)-1) )
	begin
		cnt<=0;
		cnt_edge <= 1'b1;
	end
	else
	begin
		cnt<=cnt+1;
		cnt_edge <= 1'b0;
	end
end

real my_time;
real sin_real;
reg signed [15:0]sin_val;

//generate requested "freq" sinus
always @(posedge cnt_edge)
begin
	sin_real <= sin(my_time);
	sin_val  <= sin_real*32767; //fit 16bit signed short word
	my_time  <= my_time+3.14159265*2/64;
end

wire signed [47:0]out;
wire out_rdy;
fir_filter fir_(
		.nreset( ~reset ),
		.clk( fir_clk ),
		.idata( sin_val ),
		.out_val( out ),
		.out_ready( out_rdy )
	);

wire signed [15:0]out_val_; assign out_val_ = out[35:20];

initial
begin
	$dumpfile("out.vcd");
		
	$dumpvars(1,
		tb.freq,
		tb.sin_val,
		tb.out_val_
		);

	reset = 1;
	#1000;
	reset = 0;

	read_bp_coeff();
	
	my_time=0;

	for ( freq=300; freq<4000; freq=freq+100 )
	begin
		#20000000;
		if( freq>1000 && freq<2000 )
			freq=freq+200;
	end

	$finish; 
end

integer file_filter;
integer i;
integer scan_result;
reg signed [15:0]coeff;

task read_bp_coeff;
begin
	file_filter = $fopen("python/fir-coeffs.txt", "r");
	if (file_filter == 0) begin
		$display("file bp filter handle was NULL");
		$finish;
	end
	for( i=0; i<512; i=i+1 )
	begin
		scan_result = $fscanf(file_filter, "%d\n", coeff); 
		if ( scan_result!=1 ) 
			coeff = 0;
		//$display("coeff %d = %d",i,coeff);
		fir_.mem_coeff.mem[i] = coeff;
	end
	$fclose(file_filter);
end
endtask

endmodule
