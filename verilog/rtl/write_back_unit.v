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
// Write back stage of pipeline.  Controls writing results into register file
//

`define LINK_INDEX 30
`define PC_INDEX 31

module write_back_unit(
	clock_i,
	write_reg_o,
	select_write_reg_o,
	reg_write_enable_o,
	instruction_i,
	write_value_i,
	lr_i,
	halt_o);
	
	input 			clock_i,
					instruction_i,
					write_value_i,
					lr_i;
	output 			write_reg_o,
					select_write_reg_o,
					reg_write_enable_o,
					halt_o;

	wire[31:0]		lr_i;
	wire[31:0]		write_value_i;
	wire[31:0]		instruction_i;
	wire[31:0]		write_reg_o;
	wire[5:0]		opcode;
	wire[4:0]		select_write_reg_o;
	wire[4:0]		result_register;
	wire 			reg_write_enable_o;
	wire			is_load;
	wire			halt_o;
	wire			is_call;
	wire			clock_i;
	wire			is_crread;

	//////////////////////////////////////////////////////////////
	/// Control
	//////////////////////////////////////////////////////////////
	assign result_register = instruction_i[25:21];
	assign opcode = instruction_i[31:26];
	assign is_load = opcode[5:3] == 3'b100;
	assign halt_o = opcode == 6'b111110;
	assign is_call = opcode[5:1] == 5'b11001;
	assign is_crread = opcode == 6'b110100;
	assign reg_write_enable_o = is_crread | is_call | (result_register != `PC_INDEX & (~opcode[5] | is_load));

	//////////////////////////////////////////////////////////////
	/// Datapath
	//////////////////////////////////////////////////////////////
	mux2 #(32) write_mux(.out(write_reg_o),
		.in0(write_value_i),
		.in1(lr_i),
		.sel(is_call));

	mux2 #(5) select_mux(.out(select_write_reg_o),
		.in0(result_register),
		.in1(`LINK_INDEX),
		.sel(is_call));
endmodule
