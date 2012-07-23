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
// 3-way Wishbone arbiter
// The lower numbered interface always wins.
//
module arbiter(
	clock_i,
		
	adr0_i,
	dat0_o,
	dat0_i,
	cyc0_i,
	stb0_i,
	ack0_o,
	cti0_i,
	sel0_i,
	we0_i,
		
	adr1_i,
	dat1_o,
	dat1_i,
	cyc1_i,
	stb1_i,
	ack1_o,
	cti1_i,
	sel1_i,
	we1_i,
		
	adr2_i,
	dat2_o,
	dat2_i,
	cyc2_i,
	stb2_i,
	ack2_o,
	cti2_i,
	sel2_i,
	we2_i,
		
	adr_o,
	dat_o,
	dat_i,
	cyc_o,
	stb_o,
	ack_i,
	cti_o,
	sel_o,
	we_o);

	input 			clock_i;
	input 			adr0_i,
					dat0_i,
					cyc0_i,
					stb0_i,
					cti0_i,
					sel0_i,
					we0_i;
	input 			adr1_i,
					dat1_i,
					cyc1_i,
					stb1_i,
					cti1_i,
					sel1_i,
					we1_i;
	input 			adr2_i,
					dat2_i,
					cyc2_i,
					stb2_i,
					cti2_i,
					sel2_i,
					we2_i;
	input 			dat_i,
					ack_i;
	output 			dat0_o,
					ack0_o,
					dat1_o,
					ack1_o,
					dat2_o,
					ack2_o;
	output 			dat_o,
					cyc_o,
					stb_o,
					cti_o,
					sel_o,
					we_o,
					adr_o;

	wire[31:0]		adr_o,
					adr0_i,
					adr1_i,
					adr2_i;
	wire[31:0]		dat_o,
					dat0_i,
					dat1_i,
					dat2_i;
	wire[3:0]		sel_o,
					sel0_i,
					sel1_i,
					sel2_i;
	wire[2:0]		cti0_i,
					cti1_i,
					cti2_i,
					cti_o;
	wire[1:0]		unit_select,
					bte_o;
	wire 			stb0_i,
					stb1_i,
					stb2_i;
	wire 			stb_o,
					cyc_o;
	wire 			unit0_selected,
					unit1_selected,
					unit2_selected;
	wire 			unit_selected,
					want_select_unit0,
					want_select_unit1,
					want_select_unit2;
	wire 			ack0_o,
					ack1_o,
					ack2_o;
	
	assign bte_o = 0;
	assign unit_select = (unit1_selected ? 1 : 0) | (unit2_selected ? 2 : 0);
	assign ack0_o = ack_i & unit0_selected;
	assign ack1_o = ack_i & unit1_selected;
	assign ack2_o = ack_i & unit2_selected;
	assign dat0_o = dat_i;
	assign dat1_o = dat_i;
	assign dat2_o = dat_i;

	mux3es #(32) adrmux(.out(adr_o), .in0(adr0_i), .in1(adr1_i), .in2(adr2_i), .sel(unit_select));
	mux3es #(32) datmux(.out(dat_o), .in0(dat0_i), .in1(dat1_i), .in2(dat2_i), .sel(unit_select));
	mux3es #(3) ctimux(.out(cti_o), .in0(cti0_i), .in1(cti1_i), .in2(cti2_i), .sel(unit_select));
	mux3es #(4) selmux(.out(sel_o), .in0(sel0_i), .in1(sel1_i), .in2(sel2_i), .sel(unit_select));
	mux3es wemux(.out(we_o), .in0(we0_i), .in1(we1_i), .in2(we2_i), .sel(unit_select));

	assign stb_o = unit0_selected | unit1_selected | unit2_selected;
	assign cyc_o = unit_selected;

	assign unit_selected = unit0_selected | unit1_selected | unit2_selected;
	assign want_select_unit0 = cyc0_i;
	assign want_select_unit1 = cyc1_i & ~cyc0_i;
	assign want_select_unit2 = cyc2_i & ~cyc1_i & ~cyc0_i;

	_dff unit0_ff(.q(unit0_selected),
		.d((~unit_selected & want_select_unit0) | (unit0_selected & cyc0_i)),
		.clock(clock_i),
		.clken(1));

	_dff unit1_ff(.q(unit1_selected),
		.d((~unit_selected & want_select_unit1) | (unit1_selected & cyc1_i)),
		.clock(clock_i),
		.clken(1));

	_dff unit2_ff(.q(unit2_selected),
		.d((~unit_selected & want_select_unit2) | (unit2_selected & cyc2_i)),
		.clock(clock_i),
		.clken(1));
endmodule
