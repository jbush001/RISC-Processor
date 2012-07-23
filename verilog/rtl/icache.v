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

//
// Instruction cache
// Direct mapped, read only cache with 32 byte line size
// Default size is 8k
//

`define STATE_IDLE 0
`define STATE_LOAD1 1
`define STATE_LOAD2 2
`define STATE_LOAD3 3

module icache(
	clock_i,
	address_i,
	read_enable_i,
	ready_o,
	cached_data_o,
	adr_o,
	dat_i,
	stb_o,
	cyc_o,
	ack_i,
	cti_o);

	parameter NUM_LINES = 256;	// 8k cache
	parameter LINE_BITS = 8;

	// do not modify (update automatically)
	parameter TAG_BITS = (31 - (LINE_BITS + 5) + 1);
	parameter LINE_OFFSET_BITS = 5;

	input 			clock_i,
					address_i,
					dat_i,
					ack_i,
					read_enable_i;
	output 			ready_o,
					cached_data_o,
					adr_o,
					stb_o,
					cyc_o,
					cti_o;

	wire[TAG_BITS - 1:0] requested_tag,
					cached_tag,
					load_tag;
	reg[TAG_BITS - 1:0] requested_tag_latched;
	wire[LINE_BITS - 1:0] requested_line,
					load_line;
	wire[LINE_BITS + LINE_OFFSET_BITS - 3:0] cache_data_address;
	wire[31:0]		address_i,
					cached_data_o,
					dat_i,
					adr_o;
	wire[2:0]		requested_line_offset;
	reg[2:0]		burst_offset;
	reg[1:0]		state;	// synthesis attribute init of state is STATE_IDLE
	wire[2:0]		cti_o;
	wire 			cache_load_needed,
					cache_line_valid,
					ready_o;
	wire 			update_cache_data,
					cyc_o,
					stb_o;

	assign requested_tag = address_i[31:LINE_BITS + LINE_OFFSET_BITS];
	assign requested_line = address_i[LINE_OFFSET_BITS + LINE_BITS - 1:LINE_OFFSET_BITS];
	assign requested_line_offset = address_i[4:2];
	assign adr_o = { load_tag, load_line, burst_offset, 2'b00  };
	assign cti_o = (state != `STATE_IDLE && burst_offset != 7) ? 3'b010 : 3'b111;
	assign cyc_o = state != `STATE_IDLE;
	assign stb_o = cyc_o;
	assign cache_load_needed = ~ready_o & read_enable_i;

	_dff #(TAG_BITS) load_tag_ff(.q(load_tag),
		.d(requested_tag),
		.clken(cache_load_needed && state == `STATE_IDLE),
		.clock(clock_i));
	_dff #(LINE_BITS) load_line_ff(.q(load_line),
		.d(requested_line),
		.clken(cache_load_needed && state == `STATE_IDLE),
		.clock(clock_i));

	ssram #(TAG_BITS + 1, NUM_LINES, LINE_BITS) tag_ram(
		.clock(clock_i),
		.clock_enable(1),
		.address((state == `STATE_IDLE || state == `STATE_LOAD3) ? requested_line : load_line),
		.data_in({ 1'b1, load_tag }),
		.data_out({ cache_line_valid, cached_tag }),
		.write_enable(state == `STATE_LOAD1));

	// Hit/Miss detection
	always @(posedge clock_i)
		requested_tag_latched <= requested_tag;
	
	assign ready_o = requested_tag_latched == cached_tag && state == `STATE_IDLE && cache_line_valid;
	assign cache_data_address = (state == `STATE_IDLE || state == `STATE_LOAD3)
		? { requested_line, requested_line_offset }
		: { load_line, burst_offset };

	// Cache data
	assign update_cache_data = state == `STATE_LOAD2 && ack_i;
	ssram #(32, NUM_LINES * 8, LINE_BITS + LINE_OFFSET_BITS - 2) cache_data(
		.clock(clock_i),
		.address(cache_data_address),
		.data_in(dat_i),
		.data_out(cached_data_o),
		.write_enable(update_cache_data),
		.clock_enable(read_enable_i | update_cache_data));

	// Logic to compute burst offset during load
	initial
	begin
		burst_offset <= 0;
		state <= `STATE_IDLE;
	end
	
	always @(posedge clock_i)
	begin
		if (state == `STATE_LOAD2)
		begin
			if (ack_i)
				burst_offset <= burst_offset + 1;
		end
		else
			burst_offset <= 0;
	end

	// Next state logic
	always @(posedge clock_i)
	begin
		case (state)
			`STATE_IDLE:
			begin
				if (cache_load_needed)
					state <= `STATE_LOAD1;
			end
			
			`STATE_LOAD1:
			begin
				if (ack_i)
					state <= `STATE_LOAD2;
			end
			
			`STATE_LOAD2:
			begin
				if (burst_offset == 7 && ack_i)
					state <= `STATE_LOAD3;
			end
			
			`STATE_LOAD3:
				state <= `STATE_IDLE;
		endcase
	end
endmodule
