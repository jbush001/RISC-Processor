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



module memory(
	clock,
	d_address,
	d_data_out,
	d_is_read,
	d_data_in,
	d_is_write,
	d_sel,
	d_ready,
	i_address,
	i_data_out,
		
	i_is_read,
	i_ready);
	parameter SIZE = 'h10000;

	input 			d_address,
					d_data_in,
					d_is_read,
					d_is_write,
					clock,
					d_sel,
					i_address,
					i_is_read;
	output 			d_data_out,
					i_data_out,
					d_ready,
					i_ready;
	
	wire[31:0]		d_address,
					d_data_in,
					i_address;
	reg[31:0]		i_data_out,
					d_data_out;
	reg[31:0]		d_address_latched;
	wire[3:0]		d_sel;
	wire 			d_is_write,
					i_is_read,
					clock,
					d_is_read;
	reg 			i_ready,
					d_ready;

	reg[7:0]		mem[0:SIZE - 1];
	
	integer i;
	initial
	begin
		for (i = 0; i < SIZE; i = i + 1)
			mem[i] <= 0;

		i_data_out <= 0;
		i_ready <= 0;
		d_data_out <= 0;
		d_ready <= 1;	// XXX async tag cache (for now)
	end

	always @(posedge clock)
		i_ready <= i_is_read;

	initial
		d_address_latched <= 0;

	always @(posedge clock)
		d_address_latched <= d_address;

	always @(posedge clock)
	begin
		if (i_is_read)
			i_data_out <= { mem[i_address], mem[i_address + 1], mem[i_address + 2], mem[i_address + 3] };

		if (d_is_read)
			d_data_out <= { mem[d_address], mem[d_address + 1], mem[d_address + 2], mem[d_address + 3] };
	end

	always @(posedge clock)
	begin
		if (d_is_write && d_ready)
		begin
			if (d_address_latched == 'ha0000000)
				$write("%c", d_data_in[31:24]);
			else
			begin
				if (d_sel[3])
					mem[d_address_latched] <= d_data_in[31:24];
	
				if (d_sel[2])
					mem[d_address_latched + 1] <= d_data_in[23:16];
				
				if (d_sel[1])
					mem[d_address_latched + 2] <= d_data_in[15:8];
	
				if (d_sel[0])
					mem[d_address_latched + 3] <= d_data_in[7:0];
			end
		end
	end
endmodule
