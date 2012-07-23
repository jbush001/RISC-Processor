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
// Data cache
// Direct mapped, write back
// 8k default size, w/ 32 byte lines
//

`define STATE_IDLE 0
`define STATE_STORE1 1
`define STATE_STORE2 2
`define STATE_LOAD1 3
`define STATE_LOAD2 4
`define STATE_LOAD3 5

//
// clock 0: address_i and readEnable_i are set by host
// clock 1: ready_o is set based on address.
//    If this is a write, host sets writeEnable_i, cachedData_o, sel_o
//    If this is a read and is a cache hit (ready_o = 1), cachedData_o is set by cache
// clock 2: cache samples write data
//    If this is a miss, ready_o stays low until data is fetched and...
// clock n: ready_o goes high, cache samples write data or presents read data.
// These phases can be overlapped unless a read occurs after a write, in which case
//   external logic must insert a no-access cycle.
//
module dcache(
	clock_i,
	address_i,
	read_enable_i,
	write_enable_i,
	ready_o,
	cached_data_o,
	cached_data_i,
	cache_select_i,
	adr_o,
	dat_i,
	dat_o,
	stb_o,
	cyc_o,
	ack_i,
	cti_o,
	we_o);

	parameter NUM_LINES = 256;	// 8k cache
	parameter LINE_BITS = 8;
	parameter TAG_BITS = (31 - (LINE_BITS + 5) + 1);
	parameter LINE_OFFSET_BITS = 5;	// Hard coded logic below will not work with other values than this currently

	input 			clock_i,
					address_i,
					dat_i,
					ack_i,
					write_enable_i,
					cached_data_i,
					cache_select_i;
	input 			read_enable_i;
	output 			ready_o,
					cached_data_o,
					adr_o,
					dat_o,
					stb_o,
					cyc_o,
					cti_o,
					we_o;

	wire[TAG_BITS - 1:0] requested_tag,
					latched_tag,
					cached_tag;
	wire[TAG_BITS + 2 - 1:0] tag_data_in;
	wire[LINE_BITS - 1:0] requested_line,
					latched_line;
	wire[LINE_BITS + LINE_OFFSET_BITS - 3:0] cache_data_address;
	wire[31:0]		address_i,
					cached_data_i,
					cached_data_o,
					dat_i,
					dat_o,
					adr_o;
	reg[31:0]		latched_address;
	wire[3:0]		cache_select_i;
	wire[2:0]		requested_line_offset,
					latched_line_offset;
	reg[2:0]		burst_offset;
	reg[2:0]		state; // synthesis attribute init of state is STATE_IDLE
	wire[2:0]		cti_o;
	wire 			write_enable_i,
					cache_line_dirty,
					cache_line_valid,
					ready_o;
	wire 			update_cache_data,
					we_o,
					cyc_o,
					stb_o,
					do_user_write;
	reg 			latched_read_request;
	wire			update_tag_ram;

	initial
	begin
		burst_offset <= 0;
		latched_address <= 0;
		latched_read_request <= 0;
		state <= `STATE_IDLE;
	end

	assign requested_tag = address_i[31:LINE_BITS + LINE_OFFSET_BITS];
	assign requested_line = address_i[LINE_OFFSET_BITS + LINE_BITS - 1:LINE_OFFSET_BITS];
	assign requested_line_offset = address_i[4:2];
	assign we_o = state == `STATE_STORE1 || state == `STATE_STORE2;
	assign adr_o = { (we_o ? cached_tag : latched_tag), latched_line, burst_offset, 2'b00  };
	assign cti_o = (state != `STATE_IDLE && burst_offset != 7) ? 3'b010 : 3'b111;
	assign cyc_o = state != `STATE_IDLE;
	assign stb_o = cyc_o;
	assign dat_o = cached_data_o;
	
	always @(posedge clock_i)
	begin
		if (state == `STATE_IDLE && (ready_o || ~latched_read_request) && read_enable_i)
			latched_address <= address_i;
	end
	
	always @(posedge clock_i)
		latched_read_request <= read_enable_i;

	assign latched_tag = latched_address[31:LINE_BITS + LINE_OFFSET_BITS];
	assign latched_line = latched_address[LINE_OFFSET_BITS + LINE_BITS - 1:LINE_OFFSET_BITS];
	assign latched_line_offset = latched_address[4:2];


	// Tag RAM is updated
	//  1. When a line is written to (dirty bit is set)
	//  2. When a line is written out (dirty bit is cleared)
	//  3. When a line is loaded (valid bit set and tag updated).
	// A read occurs before any of these operations, so the previous bits (which have a
	// latency of one cycle) may be used.
	assign update_tag_ram = write_enable_i || state == `STATE_LOAD1 || state == `STATE_STORE1;
	assign tag_data_in = { (cache_line_dirty && state != `STATE_STORE1) | write_enable_i,
		1'b1, (state == `STATE_LOAD1 ? latched_tag : cached_tag) };
	ssram #(TAG_BITS + 2, NUM_LINES, LINE_BITS) tag_ram(
		.clock(clock_i),
		.address((state == `STATE_IDLE && read_enable_i) ? requested_line : latched_line),
		.data_in(tag_data_in),
		.clock_enable(1),
		.data_out({ cache_line_dirty, cache_line_valid, cached_tag }),
		.write_enable(update_tag_ram));

	// Hit/Miss detection
	assign ready_o = latched_tag == cached_tag && state == `STATE_IDLE && cache_line_valid;

	mux5ps #(11) cache_data_addr_mux(.out(cache_data_address),
		.in0({ latched_line, burst_offset + 1'b1 }),
		.in1({ latched_line, 3'd0 }),
		.in2({ latched_line, burst_offset }),			// During read burst
		.in3({ latched_line, latched_line_offset }),	// Load fetched value at end of line read
		.in4({ requested_line, requested_line_offset}),	// Cache hit read
		.sel0(state == `STATE_STORE2),		
		.sel1(state == `STATE_STORE1),		
		.sel2(state == `STATE_LOAD2),
		.sel3(state == `STATE_LOAD3 || write_enable_i));	
	
	// Use one SRAM for each byte lane
	assign do_user_write = (state != `STATE_LOAD2 && state != `STATE_LOAD1) && write_enable_i;
	assign update_cache_data = state == `STATE_LOAD2 && ack_i;
	ssram #(8, NUM_LINES * 8, LINE_BITS + LINE_OFFSET_BITS - 2) cache_data3(
		.clock(clock_i),
		.clock_enable(1),
		.address(cache_data_address),
		.data_in(do_user_write ? cached_data_i[31:24] : dat_i[31:24]),	// xxx doesn't load on first write
		.data_out(cached_data_o[31:24]),
		.write_enable(update_cache_data || (write_enable_i & cache_select_i[3] & ready_o)));

	ssram #(8, NUM_LINES * 8, LINE_BITS + LINE_OFFSET_BITS - 2) cache_data2(
		.clock(clock_i),
		.clock_enable(1),
		.address(cache_data_address),
		.data_in(do_user_write ? cached_data_i[23:16] : dat_i[23:16]),	// xxx doesn't load on first write
		.data_out(cached_data_o[23:16]),
		.write_enable(update_cache_data || (write_enable_i & cache_select_i[2] & ready_o)));

	ssram #(8, NUM_LINES * 8, LINE_BITS + LINE_OFFSET_BITS - 2) cache_data1(
		.clock(clock_i),
		.clock_enable(1),
		.address(cache_data_address),
		.data_in(do_user_write ? cached_data_i[15:8] : dat_i[15:8]),		// xxx doesn't load on first write
		.data_out(cached_data_o[15:8]),
		.write_enable(update_cache_data || (write_enable_i & cache_select_i[1] & ready_o)));

	ssram #(8, NUM_LINES * 8, LINE_BITS + LINE_OFFSET_BITS - 2) cache_data0(
		.clock(clock_i),
		.clock_enable(1),
		.address(cache_data_address),
		.data_in(do_user_write ? cached_data_i[7:0] : dat_i[7:0]),		// xxx doesn't load on first write
		.data_out(cached_data_o[7:0]),
		.write_enable(update_cache_data || (write_enable_i & cache_select_i[0] & ready_o)));

	// Logic to compute burst offset during load
	always @(posedge clock_i)
	begin
		if (state == `STATE_LOAD2 || state == `STATE_STORE2)
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
				if (~ready_o && latched_read_request)	// latched_read_request implies the result from tag RAM is available
				begin
					if (cache_line_dirty)
						state <= `STATE_STORE1;
					else
						state <= `STATE_LOAD1;
				end
			end

			`STATE_STORE1:
			begin
				if (ack_i)
					state <= `STATE_STORE2;
			end
			
			`STATE_STORE2:
			begin
				if (burst_offset == 7 && ack_i)
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
			
			default: state <= `STATE_IDLE;
		endcase
	end
endmodule
