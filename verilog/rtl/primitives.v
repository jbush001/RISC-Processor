
`define BUILTIN_BARREL_SHIFTER

module mux2(
	out,
	in0,
	in1,
	sel);

	parameter WIDTH = 1;

	input 			in0,
					in1,
					sel;
	output 			out;

	wire[WIDTH - 1:0] in0,
					in1;
	wire 			sel;
	reg[WIDTH - 1:0] out;

	always @(in0, in1, sel)
	begin
		if (sel)
			out = in1;
		else
			out = in0;
	end
endmodule

// Encoded multiplexers
module mux3es(
	out,
	in0,
	in1,
	in2,
	sel);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					sel;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2;
	wire[1:0]		sel;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, sel)
	begin
		case (sel) // synthesis full_case parallel_case
			0: out = in0;
			1: out = in1;
			2: out = in2;
		endcase
	end
endmodule

module mux4es(
	out,
	in0,
	in1,
	in2,
	in3,
	sel);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					sel;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3;
	wire[1:0]		sel;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, sel)
	begin
		case (sel) // synthesis full_case parallel_case
			0: out = in0;
			1: out = in1;
			2: out = in2;
			3: out = in3;
		endcase
	end
endmodule

module mux5es(
	out,
	in0,
	in1,
	in2,
	in3,
	in4,
	sel);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					in4,
					sel;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3,
					in4;
	wire[2:0]		sel;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, in4, sel)
	begin
		case (sel) // synthesis full_case parallel_case
			0: out = in0;
			1: out = in1;
			2: out = in2;
			3: out = in3;
			4: out = in4;
		endcase
	end
endmodule

module mux6es(
	out,
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	sel);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					in4,
					in5,
					sel;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3,
					in4,
					in5;
	wire[2:0]		sel;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, in4, in5, sel)
	begin
		case (sel) // synthesis full_case parallel_case
			0: out = in0;
			1: out = in1;
			2: out = in2;
			3: out = in3;
			4: out = in4;
			5: out = in5;
		endcase
	end
endmodule

module mux3ps(
	out,
	in0,
	in1,
	in2,
	sel0,
	sel1);
	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					sel0,
					sel1;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2;
	wire 			sel0,
					sel1;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, sel0, sel1)
	begin
		if (sel0)
			out = in0;
		else if (sel1)
			out = in1;
		else
			out = in2;
	end
endmodule

module mux4ps(
	out,
	in0,
	in1,
	in2,
	in3,
	sel0,
	sel1,
	sel2);
	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					sel0,
					sel1,
					sel2;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3;
	wire 			sel0,
					sel1,
					sel2;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, sel0, sel1, sel2)
	begin
		if (sel0)
			out = in0;
		else if (sel1)
			out = in1;
		else if (sel2)
			out = in2;
		else
			out = in3;
	end
endmodule

module mux5ps(
	out,
	in0,
	in1,
	in2,
	in3,
	in4,
	sel0,
	sel1,
	sel2,
	sel3);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					in4,
					sel0,
					sel1,
					sel2,
					sel3;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3,
					in4;
	wire 			sel0,
					sel1,
					sel2,
					sel3;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, in4, sel0, sel1, sel2, sel3)
	begin
		if (sel0)
			out = in0;
		else if (sel1)
			out = in1;
		else if (sel2)
			out = in2;
		else if (sel3)
			out = in3;
		else
			out = in4;
	end
endmodule

module mux6ps(
	out,
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	sel0,
	sel1,
	sel2,
	sel3,
	sel4);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					in4,
					in5,
					sel0,
					sel1,
					sel2,
					sel3,
					sel4;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3,
					in4,
					in5;
	wire 			sel0,
					sel1,
					sel2,
					sel3,
					sel4;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, in4, in5, sel0, sel1, sel2, sel3, sel4)
	begin
		if (sel0)
			out = in0;
		else if (sel1)
			out = in1;
		else if (sel2)
			out = in2;
		else if (sel3)
			out = in3;
		else if (sel4)
			out = in4;
		else
			out = in5;
	end
endmodule

module mux7ps(
	out,
	in0,
	in1,
	in2,
	in3,
	in4,
	in5,
	in6,
	sel0,
	sel1,
	sel2,
	sel3,
	sel4,
	sel5);

	parameter WIDTH = 1;
	
	input 			in0,
					in1,
					in2,
					in3,
					in4,
					in5,
					in6,
					sel0,
					sel1,
					sel2,
					sel3,
					sel4,
					sel5;
	output 			out;

	wire[WIDTH-1 : 0] in0,
					in1,
					in2,
					in3,
					in4,
					in5,
					in6;
	wire 			sel0,
					sel1,
					sel2,
					sel3,
					sel4,
					sel5;
	reg[WIDTH-1 : 0] out;

	always @(in0, in1, in2, in3, in4, in5, in6, sel0, sel1, sel2, sel3, sel4, sel5)
	begin
		if (sel0)
			out = in0;
		else if (sel1)
			out = in1;
		else if (sel2)
			out = in2;
		else if (sel3)
			out = in3;
		else if (sel4)
			out = in4;
		else if (sel5)
			out = in5;
		else
			out = in6;
	end
endmodule

// Without the underscore, conflicts with built-in Altera primitive.
module _dff(
	q,
	d,
	clock,
	clken);
	parameter WIDTH = 1;

	input 			d,
					clock,
					clken;
	output 			q;
	
	wire[WIDTH - 1:0] d;
	wire 			clock,
					clken;
	reg[WIDTH - 1:0] q;

	initial
		q <= {WIDTH{1'b0}};
	
	always @(posedge clock)
	begin
		if (clken)
			q <= d;
	end
endmodule


`ifdef BUILTIN_BARREL_SHIFTER

// These synthesize better on FPGAs
module left_barrel_shifter(
	result,
	in,
	shift_amount);
	output 			result;
	input 			in,
					shift_amount;

	wire[31:0]		result,
					in;
	wire[4:0]		shift_amount;
	
	assign result = in << shift_amount;
endmodule


module right_barrel_shifter(
	result,
	in,
	shift_amount,
	sign_extend);
	output 			result;
	input 			in,
					shift_amount,
					sign_extend;

	wire[31:0]		result,
					in;
	wire[4:0]		shift_amount;
	wire 			sign_extend;
	wire 			sign;
	
	assign sign = in[31] & sign_extend;
	
	assign result = { {32{sign}}, in } >> shift_amount;
endmodule

`else

module left_barrel_shifter(
	result,
	in,
	shift_amount);

	input 			in,
					shift_amount;
	output 			result;
	
	wire[31:0]		result,
					in;
	reg[31:0]		out1;
	wire[4:0]		shift_amount;

	always @(in, shift_amount)
	begin
		case (shift_amount[2:0])	// synthesis full_case parallel_case
			0: out1 = in;
			1: out1 = in << 1;
			2: out1 = in << 2;
			3: out1 = in << 3;
			4: out1 = in << 4;
			5: out1 = in << 5;
			6: out1 = in << 6;
			7: out1 = in << 7;
		endcase
	end	

	mux4es #(32) shift2(.out(result),
		.in0(out1),
		.in1(out1 << 8),
		.in2(out1 << 16),
		.in3(out1 << 24),
		.sel(shift_amount[4:3]));
endmodule

module right_barrel_shifter(
	result,
	in,
	shift_amount,
	sign_extend);

	input 			in,
					shift_amount,
					sign_extend;
	output 			result;
	
	wire[31:0]		result,
					in;
	reg[31:0]		out1;
	wire[4:0]		shift_amount;
	wire 			sign_extend,
					sign;
	
	assign sign = in[31] & sign_extend;

	always @(in, shift_amount, sign)
	begin
		case (shift_amount[2:0])	// synthesis full_case parallel_case
			0: out1 = in;
			1: out1 = { {1{sign}}, in[31:1] };
			2: out1 = { {2{sign}}, in[31:2] };
			3: out1 = { {3{sign}}, in[31:3] };
			4: out1 = { {4{sign}}, in[31:4] };
			5: out1 = { {5{sign}}, in[31:5] };
			6: out1 = { {6{sign}}, in[31:6] };
			7: out1 = { {7{sign}}, in[31:7] };
		endcase
	end	

	mux4es #(32) shift2(.out(result),
		.in0(out1),
		.in1({ {8{sign}}, out1[31:8] }),
		.in2({ {16{sign}}, out1[31:16] }),
		.in3({ {24{sign}}, out1[31:24] }),
		.sel(shift_amount[4:3]));
endmodule

`endif

// SRAM with asynchronous read
module asram(
	clock,
	address,
	data_in,
	data_out,
	write_enable);
	input 			clock,
					address,
					data_in,
					write_enable;
	output 			data_out;

	parameter WIDTH=32;
	parameter SIZE=1024;
	parameter ADDRESS_SIZE = 11;

	wire[WIDTH - 1:0] data_in,
					data_out;
	wire[ADDRESS_SIZE - 1:0] address;	
	reg[WIDTH-1:0]	data[0:SIZE - 1];

	integer i;
	initial
	begin
		for (i = 0; i < SIZE; i = i + 1)
			data[i] <= 0;
	end	
	
	assign data_out = data[address];

	always @(posedge clock)
	begin
		if (write_enable)
			data[address] <= data_in;
	end
endmodule

// SRAM with synchronous read
module ssram(
	clock,
	address,
	data_in,
	data_out,
	write_enable,
	clock_enable);
	input 			clock,
					address,
					data_in,
					write_enable,
					clock_enable;
	output 			data_out;

	parameter WIDTH=32;
	parameter SIZE=1024;
	parameter ADDRESS_SIZE = 11;

	wire[WIDTH - 1:0] data_in;
	wire[ADDRESS_SIZE - 1:0] address;	
	reg[WIDTH-1:0]	data[0:SIZE - 1];
	reg[WIDTH-1:0]	data_out;
	wire 			clock_enable;
	integer i;

	initial
	begin
		data_out <= 0;
		for (i = 0; i < SIZE; i = i + 1)
			data[i] <= 0;
	end

	always @(posedge clock)
	begin
		if (clock_enable)
			data_out <= data[address];
	end

	always @(posedge clock)
	begin
		if (clock_enable && write_enable)
			data[address] <= data_in;
	end
endmodule
