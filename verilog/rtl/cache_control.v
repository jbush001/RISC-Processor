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
// Determines if an access is cached or uncached
// Routes request to proper interface.
//

module cache_control(
	clock_i,
	cached_ready_i,
	uncached_ready_i,
	cached_data_i,
	uncached_data_i,
	read_i,
	dat_o,
	adr_i,
	ready_o,
	adr_o,
	enable_uncached_o);

	input clock_i;
	input cached_ready_i;
	input uncached_ready_i;
	input cached_data_i;
	input uncached_data_i;
	input adr_i;
	input read_i;
	output ready_o;
	output dat_o;
	output adr_o;
	output enable_uncached_o;

	wire			clock_i;
	wire			cached_ready_i;
	wire			uncached_ready_i;
	wire[31:0]		cached_data_i;
	wire[31:0]		uncached_data_i;
	wire[31:0]		adr_i;
	wire			ready_o;
	wire			read_i;
	wire[31:0]		dat_o;
	wire[31:0]		adr_o;
	reg[31:0]		latched_address;
	wire 			uncached_address_request;
	wire			enable_uncached_o;
	reg				in_uncached_access_cycle;

	initial
	begin
		in_uncached_access_cycle <= 0;
		latched_address <= 0;
	end

	assign uncached_address_request = adr_i[31] && read_i;
	assign enable_uncached_o = in_uncached_access_cycle | uncached_address_request;	
	assign adr_o = latched_address;

	always @(posedge clock_i)
		in_uncached_access_cycle <= in_uncached_access_cycle ? ~uncached_ready_i : uncached_address_request;

	always @(posedge clock_i)
	begin
		if (~in_uncached_access_cycle & uncached_address_request)
			latched_address <= adr_i;
	end

	mux2 dready_mux(.out(ready_o),
		.in0(cached_ready_i),
		.in1(uncached_ready_i),
		.sel(in_uncached_access_cycle));
	
	mux2 #(32) data_mux(.out(dat_o),
		.in0(cached_data_i),
		.in1(uncached_data_i),
		.sel(in_uncached_access_cycle));	

endmodule
