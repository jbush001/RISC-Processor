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
// Top level CPU core.  Includes instruction and data caches and pipline.
//

module cpu(
	clock_i,
	adr_o,
	dat_i,
	dat_o,
	stb_o,
	cyc_o,
	ack_i,
	cti_o,
	bte_o,
	we_o,
	sel_o,
	halt_o,
	interrupt_request_i);

	input 			clock_i,
					dat_i,
					ack_i,
					interrupt_request_i;
	output 			adr_o,
					dat_o,
					stb_o,
					cyc_o,
					cti_o,
					bte_o,
					we_o,
					sel_o,
					halt_o;

	wire[31:0]		d_address,
					d_write_data,
					d_read_data,
					i_address,
					i_read_data;
	wire[31:0]		d_cached_data_out,
					d_uncached_data_out,
					i_cache_adr,
					d_cache_adr;
	wire[31:0]		dat_i,
					dat_o,
					adr_o,
					d_data_out;
	wire[3:0]		d_mem_sel,
					sel_o;
	wire[2:0]		i_cache_cti,
					d_cache_cti,
					cti_o;
	wire[1:0]		bte_o;
	wire 			d_cache_we,
					i_cache_stb,
					i_cache_cyc,
					d_cache_stb,
					d_cache_cyc;
	wire 			d_uncached_ready,
					d_cached_ready,
					i_read;
	wire 			d_is_write,
					d_is_read,
					d_ready,
					i_ready,
					halt_o;
	wire 			clock_i;
	wire[31:0]		d_latched_address;
	wire			interrupt_request_i;
	wire 			enable_uncached;

	assign bte_o = 0;

	cache_control control(
		.clock_i(clock_i),
		.cached_ready_i(d_cached_ready),
		.uncached_ready_i(d_uncached_ready),
		.cached_data_i(d_cached_data_out),
		.uncached_data_i(dat_i),
		.adr_i(d_address),
		.ready_o(d_ready),
		.read_i(d_is_read),
		.dat_o(d_read_data),
		.adr_o(d_latched_address),
		.enable_uncached_o(enable_uncached));
	
	pipeline pipeline(.clock_i(clock_i),
		.imem_address_o(i_address),
		.imem_read_o(i_read),
		.imem_data_i(i_read_data),
		.imem_data_ready_i(i_ready),
		.dmem_address_o(d_address),
		.dmem_data_i(d_read_data),
		.dmem_data_o(d_write_data),
		.dmem_read_o(d_is_read),
		.dmem_write_o(d_is_write),
		.dmem_sel_o(d_mem_sel),
		.dmem_data_ready_i(d_ready),
		.halt_o(halt_o),
		.interrupt_request_i(interrupt_request_i));

	icache icache(.clock_i(clock_i),
		.address_i(i_address),
		.read_enable_i(i_read),
		.ready_o(i_ready),
		.cached_data_o(i_read_data),
		.adr_o(i_cache_adr),
		.dat_i(dat_i),
		.stb_o(i_cache_stb),
		.cyc_o(i_cache_cyc),
		.ack_i(i_cache_ack),
		.cti_o(i_cache_cti));

	dcache dcache(.clock_i(clock_i),
		.address_i(d_address),
		.read_enable_i(d_is_read & ~enable_uncached),
		.write_enable_i(d_is_write & ~enable_uncached),
		.ready_o(d_cached_ready),
		.cached_data_o(d_cached_data_out),
		.cached_data_i(d_write_data),
		.cache_select_i(d_mem_sel),
		.adr_o(d_cache_adr),
		.dat_i(dat_i),
		.dat_o(d_data_out),
		.stb_o(d_cache_stb),
		.cyc_o(d_cache_cyc),
		.ack_i(d_cache_ack),
		.cti_o(d_cache_cti),
		.we_o(d_cache_we));

	arbiter arbiter(
		.clock_i(clock_i),

		// icache interface
		.adr0_i(i_cache_adr),
		.dat0_i(0),
		.cyc0_i(i_cache_cyc),
		.stb0_i(i_cache_stb),
		.ack0_o(i_cache_ack),
		.cti0_i(i_cache_cti),
		.sel0_i(4'b1111),
		.we0_i(0),

		// dcache interface
		.adr1_i(d_cache_adr),
		.dat1_i(d_data_out),
		.cyc1_i(d_cache_cyc),
		.stb1_i(d_cache_stb),
		.ack1_o(d_cache_ack),
		.cti1_i(d_cache_cti),
		.sel1_i(4'b1111),
		.we1_i(d_cache_we),

		// non-cached data interface
		.adr2_i(d_latched_address),
		.dat2_i(d_write_data),
		.cyc2_i(enable_uncached),
		.stb2_i(enable_uncached),
		.ack2_o(d_uncached_ready),
		.cti2_i(0),				// "classic" cycle
		.sel2_i(d_mem_sel),
		.we2_i(d_is_write),
		
		// bus output
		.adr_o(adr_o),
		.dat_o(dat_o),
		.cyc_o(cyc_o),
		.stb_o(stb_o),
		.ack_i(ack_i),
		.cti_o(cti_o),
		.sel_o(sel_o),
		.we_o(we_o));
endmodule
