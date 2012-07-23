// 
// Copyright 2008-2012 Jeff Bush
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 

//`define TRACE

module pipeline_test_bench;

	reg 			clock;
	wire[31:0]		d_address;
	wire[31:0]		i_address;
	wire[31:0]		i_read_data;
	wire[31:0]		d_read_data;
	wire[31:0]		d_write_data;
	wire[3:0]		d_mem_sel;
	wire 			i_ready,
					d_ready;
	wire 			d_is_read,
					d_is_write,
					i_is_read;
	wire 			halt;
	
	memory mem(.clock(clock),
		.d_address(d_address),
		.d_data_out(d_read_data),
		.d_data_in(d_write_data),
		.d_is_read(d_is_read),
		.d_is_write(d_is_write),
		.d_sel(d_mem_sel),
		.d_ready(d_ready),
		.i_address(i_address),
		.i_data_out(i_read_data),
		.i_is_read(i_is_read),
		.i_ready(i_ready));
		
	pipeline p(.clock_i(clock),
		.imem_address_o(i_address),
		.imem_read_o(i_is_read),
		.imem_data_i(i_read_data),
		.imem_data_ready_i(i_ready),
		.dmem_address_o(d_address),
		.dmem_data_i(d_read_data),
		.dmem_data_o(d_write_data),
		.dmem_write_o(d_is_write),
		.dmem_read_o(d_is_read),
		.dmem_sel_o(d_mem_sel),
		.dmem_data_ready_i(d_ready),
		.halt_o(halt),
		.interrupt_request_i(terminal_count));

	// Timer
	reg[5:0]		timer_count;
	wire 			terminal_count;

	assign terminal_count = timer_count == 0;
	
	initial
		timer_count <= 0;

	always @(posedge clock)
	begin
		if (terminal_count)
			timer_count <= 50;
		else
			timer_count <= timer_count - 1;
	end

	reg[4:0]		i;	
	reg[1000:0]	code_filename;

	initial
	begin
		#5 clock = 0;

		if ($value$plusargs("bin=%s", code_filename))
			$readmemh(code_filename, mem.mem);
		else
		begin
			$display("error opening file");
			$finish;
		end

`ifdef TRACE
		$dumpfile("trace.vcd");
		$dumpvars(100, p);
`endif

		while (~halt)
		begin
			#5 clock = 0;
			#5 clock = 1;
		end
	end
endmodule
