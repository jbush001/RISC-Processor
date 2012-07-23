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
// Memory Access pipeline stage
// - Performs data memory reads and writes
// - Detects branch mispredictions
// - Handles control register reads and writes
// - Detects and dispatches interrupts

`define NOP 0
`define PC_INDEX 31

module memory_access_unit(
	clock_i,
	instruction_i,
	instruction_o,
	dmem_data_i,
	dmem_data_o,
	dmem_address_o,
	dmem_sel_o,
	dmem_read_o,
	dmem_write_o,
	dmem_data_ready_i,
	branch_mispredicted_o,
	result_i,
	result_o,
	store_value_i,
	bypass_o,
	bypass_instruction_o,
	stall_o,
	flush_i,
	pc_i,
	pc_o,
	branch_predicted_i,
	have_branch_history_o,
	branch_history_decision_o,
	memory_access_address_i,
	interrupt_request_i);

	input 			clock_i,
					instruction_i,
					dmem_data_i,
					result_i,
					store_value_i,
					dmem_data_ready_i,
					flush_i;
	input 			pc_i,
					branch_predicted_i,
					memory_access_address_i,
					interrupt_request_i;
	output 			dmem_data_o,
					dmem_address_o,
					instruction_o,
					branch_mispredicted_o,
					result_o,
					dmem_sel_o;
	output 			bypass_o,
					dmem_write_o,
					stall_o,
					dmem_read_o,
					pc_o,
					have_branch_history_o,
					branch_history_decision_o;
	output 			bypass_instruction_o;	

	wire[31:0]		instruction_i,
					dmem_data_i,
					result_i,
					store_value_i,
					bypass_o,
					mem_access_mux,
					instruction_sel;
	wire[31:0]		result_o,
					instruction_o,
					half_word_store,
					byte_store,
					dmem_data_o,
					pc_i,
					pc_o;
	wire[31:0]		dmem_address_o,
					instruction_latched,
					bypass_instruction_o,
					memory_access_address_i;
	wire[31:0]		memory_address_latched,
					load_value,
					control_register_value;
	reg[31:0]		result_in_latched;
	reg[31:0]		cr1;
	wire[5:0]		opcode_latched;
	wire[15:0]		half_word_select;
	wire[7:0]		byte_read_select;
	wire[5:0]		opcode;
	wire[3:0]		dmem_sel_o;
	wire[1:0]		access_size;
	wire 			is_word_access,
					is_half_word_access,
					is_byte_access,
					dmem_write_o,
					dmem_read_o;
	wire 			sel0,
					sel1,
					sel2,
					sel3,
					is_load,
					is_store,
					sign_extend,
					branch_mispredicted_o;	
	wire 			should_take_branch,
					stall_o,
					clock_i,
					flush_i,
					dmem_data_ready_i,
					branch_predicted_i;
	wire 			have_branch_history_o,
					branch_history_decision_o,
					is_crread,
					is_crwrite,
					take_interrupt,
					is_rti;
	wire 			next_is_store,
					next_is_load,
					branch_mispredict_internal,
					cache_request_pending;
	reg 			cache_request_sent,
					int_enable;
	wire			push_nop;
	wire			instruction_o_latch_enable;
	wire			result_o_latch_enable;
	wire			mem_access_mux_select_pc;
	wire			is_j_instruction;
	wire			mem_access_mux_select_interrupt;

	initial
	begin
		result_in_latched <= 0;
		int_enable <= 0;
		cr1 <= 0;
		cache_request_sent <= 0;
	end

	//////////////////////////////////////////////////////////////
	/// Control
	//////////////////////////////////////////////////////////////

	assign take_interrupt = int_enable & interrupt_request_i;

	// Keep track of whether there is a pending cache request or not.  If the pipeline is flushed,
	// the cache won't necessarily know that, so it will still return data at some point down the line.
	// This does not get cleared during a flush; only when the previous cache request is fulfilled.
	always @(posedge clock_i)
	begin
		if (dmem_read_o)
			cache_request_sent <= 1;
		else if (dmem_data_ready_i)
			cache_request_sent <= 0;
	end

	assign cache_request_pending = cache_request_sent & ~dmem_data_ready_i;

	assign opcode = instruction_i[31:26];

	// Control register handling
	assign is_crread = opcode_latched == 6'b110100;
	assign is_crwrite = opcode_latched == 6'b110101;

	// Instruction decoding
	assign bypass_instruction_o = instruction_latched;
	assign opcode_latched = instruction_latched[31:26];
	assign is_load = opcode_latched[5:3] == 3'b100;
	assign is_store = opcode_latched[5:2] == 4'b1010;
	assign is_rti = opcode_latched == 6'b111000;
	assign sign_extend = opcode_latched[2];
	assign access_size = opcode_latched[1:0];
	assign is_word_access = access_size == 2'b11;
	assign is_half_word_access = access_size == 2'b10;
	assign is_byte_access = access_size == 2'b01;

	assign next_is_load = opcode[5:3] == 3'b100;
	assign next_is_store = opcode[5:2] == 4'b1010;

	// Present address to dcache one cycle early
	assign dmem_write_o = is_store & ~flush_i;
	assign dmem_read_o = (next_is_store | next_is_load) & ~flush_i & ~branch_mispredict_internal & ~cache_request_pending;		// Use non-latched version
	
	// Byte lane selection (read & write).  These are set on the second cycle of the write (data phase)
	assign sel0 = (is_word_access | (is_half_word_access & ~memory_address_latched[1]) | (is_byte_access & memory_address_latched[1:0] == 0));
	assign sel1 = (is_word_access | (is_half_word_access & ~memory_address_latched[1]) | (is_byte_access & memory_address_latched[1:0] == 1));
	assign sel2 = (is_word_access | (is_half_word_access & memory_address_latched[1]) | (is_byte_access & memory_address_latched[1:0] == 2));
	assign sel3 = (is_word_access | (is_half_word_access & memory_address_latched[1]) | (is_byte_access & memory_address_latched[1:0] == 3));
	assign dmem_sel_o = { sel0, sel1, sel2, sel3 };

	// Note: don't stall if this instruction is being flushed anyway
	assign stall_o = ~flush_i && cache_request_pending;
	assign bypass_o = result_in_latched;

	// Branch logic.  Detect if a branch was mispredicted by instruction fetch unit
	// and signal if so.
	assign branch_mispredict_internal = branch_predicted_i ^ should_take_branch;
	assign have_branch_history_o = opcode_latched[5:1] == 5'b11000;	// BNEZ or BEQZ
	assign branch_history_decision_o = should_take_branch;
	assign should_take_branch = ((opcode_latched == 6'b110000 && store_value_i == 0)	// beqz
		|| (opcode_latched == 6'b110001 && store_value_i != 0)			// bnez
		|| (~opcode_latched[5] && instruction_latched[25:21] == `PC_INDEX)	// arithmetic with PC as result
		|| opcode_latched[5:1] == 5'b11001	// Call
		|| (is_load && instruction_latched[25:21] == `PC_INDEX && dmem_data_ready_i));	// Load with PC as result
	_dff branch_mispredicted_ff(.q(branch_mispredicted_o),
		.d((~branch_mispredicted_o & branch_mispredict_internal) | take_interrupt | is_rti),	
		.clock(clock_i),
		.clken((~stall_o & ~flush_i) | branch_mispredicted_o | take_interrupt | is_rti));

	assign push_nop = stall_o || flush_i || take_interrupt || is_rti;
	assign instruction_o_latch_enable = ~stall_o | flush_i;
	assign result_o_latch_enable = (~stall_o & ~flush_i) | take_interrupt | is_rti;
	assign mem_access_mux_select_pc = ~should_take_branch & branch_predicted_i;
	assign is_j_instruction = opcode_latched == 50;
	assign mem_access_mux_select_interrupt = take_interrupt | is_rti;

	//////////////////////////////////////////////////////////////
	/// Datapath
	//////////////////////////////////////////////////////////////

	assign dmem_address_o = { memory_access_address_i[31:2], 2'b00 };	// Use non-latched version

	// Instruction out logic
	mux2 #(32) instruction_mux(.out(instruction_sel),
		.in0(instruction_latched),
		.in1(`NOP),
		.sel(push_nop));

	_dff #(32) instruction_ff(.q(instruction_o),
		.d(instruction_sel),
		.clock(clock_i),
		.clken(instruction_o_latch_enable));

	_dff #(32) pco_ff(.q(pc_o),
		.d(pc_i),
		.clock(clock_i),
		.clken(~stall_o));

	// Result output
	_dff #(32) result_off(.q(result_o),
		.d(mem_access_mux),
		.clock(clock_i),
		.clken(result_o_latch_enable));

	// Read alignment/sign extension
	mux4es #(8) byte_read_select_mux(.out(byte_read_select),
		.in0(dmem_data_i[31:24]),
		.in1(dmem_data_i[23:16]),
		.in2(dmem_data_i[15:8]),
		.in3(dmem_data_i[7:0]),
		.sel(memory_address_latched[1:0]));
		
	mux2 #(16) half_word_select_mux(.out(half_word_select),
		.in0(dmem_data_i[31:16]),
		.in1(dmem_data_i[15:0]),
		.sel(memory_address_latched[1]));	

	mux3es #(32) load_value_mux(.out(load_value),
		.in0({ {24{byte_read_select[7] & sign_extend}}, byte_read_select }),
		.in1({ {16{half_word_select[15] & sign_extend}}, half_word_select }),
		.in2(dmem_data_i),
		.sel(opcode_latched[1:0] - 1));

	mux6ps #(32) mem_access_select_mux(.out(mem_access_mux),
		.in0(is_rti ? cr1 : 4),	// Interrupt vector location
		.in1(pc_i),	// Rollback location
		.in2(load_value),	// Load Value
		.in3(control_register_value),	// Control register value
		.in4({ 6'b000000, instruction_latched[25:0] }),	// J format (XXX should * 4)
		.in5(result_in_latched),	// pass thru previous result
		.sel0(mem_access_mux_select_interrupt),
		.sel1(mem_access_mux_select_pc),	// Roll back pipeline if we mispredicted
		.sel2(is_load),	// Word
		.sel3(is_crread),
		.sel4(is_j_instruction));		// Is J format

	// Write value alignment
	mux2 #(32) half_word_out_select(.out(half_word_store),
		.in0({ store_value_i[15:0], 16'd0 }),
		.in1({ 16'd0, store_value_i[15:0] }),
		.sel(memory_address_latched[1]));

	mux4es #(32) byte_word_out_select(.out(byte_store),
		.in0({ store_value_i[7:0], 24'd0 }),	
		.in1({ 8'd0, store_value_i[7:0], 16'd0 }),	
		.in2({ 16'd0, store_value_i[7:0], 8'd0 }),	
		.in3({ 24'd0, store_value_i[7:0] }),	
		.sel(memory_address_latched[1:0]));
		
	mux3ps #(32) data_out_mux(.out(dmem_data_o),
		.in0(store_value_i),		// word
		.in1(half_word_store),	// half word
		.in2(byte_store),		// byte
		.sel0(is_word_access),
		.sel1(is_half_word_access));

	mux3es #(32) cr_out_mux(.out(control_register_value),
		.in0({31'd0, int_enable}),
		.in1(cr1),
		.in2(0),
		.sel(instruction_latched[17:16]));

	_dff #(32) instruction_ff1(.q(instruction_latched),
		.d((stall_o || flush_i) ? `NOP : instruction_i),
		.clock(clock_i),
		.clken(~stall_o));

	_dff #(32) address_ff(.q(memory_address_latched),
		.d(memory_access_address_i),
		.clock(clock_i),
		.clken(~stall_o));

	always @(posedge clock_i)
	begin
		if (~stall_o)
			result_in_latched <= result_i;
	end

	// XXX break into control and datapath
	always @(posedge clock_i)
	begin
		if (is_rti)
			int_enable <= 1;
		else if (take_interrupt)
		begin
			int_enable <= 0;
			cr1 <= pc_i - 4;
		end
		else if (is_crwrite)
		begin
			case (instruction_latched[25:21])
				0:	// CR0
				begin
					int_enable <= result_in_latched[0];
				end
			
				1: cr1 <= result_i;
			endcase
		end
	end
endmodule
