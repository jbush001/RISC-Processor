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
// Instruction Fetch pipeline stage
// Requests instructions from icache, predicts branches, handles branch mispredictions
//

`define BRANCH_PREDICT_DYNAMIC
`define LATCH_IFU_OUTPUTS

`define NOP 0
`define PC_INDEX 31

module instruction_fetch_unit(
	clock_i,
	branch_mispredicted_i,
	branch_target_i,
	imem_address_o,
	imem_data_i,
	imem_data_ready_i,
	imem_read_o,
	instruction_o,
	stall_i,
	pc_o,
	branch_predicted_o,
	have_branch_history_i,
	branch_history_address_i,
	branch_history_decision_i);

	input 			clock_i,
					branch_mispredicted_i,
					branch_target_i,
					stall_i,
					imem_data_i,
					imem_data_ready_i;
	input 			have_branch_history_i,
					branch_history_address_i,
					branch_history_decision_i;
	output 			pc_o,
					instruction_o,
					imem_read_o,
					branch_predicted_o,
					imem_address_o;

	wire[31:0]		branch_target_i,
					imem_data_i,
					pc_o,
					next_pc;
	wire[31:0]		pc_plus_4,
					current_instruction,
					instruction_o,
					branch_history_address_i;
	wire[31:0]		predicted_branch_target,
					immediate_value,
					imem_address_o;
	reg[31:0]		current_pc;
	wire[5:0]		opcode;
	wire 			stall_i,
					clock_i,
					branch_mispredicted_i,
					imem_data_ready_i,
					is_backward_branch;
	wire 			imem_read_o,
					branch_predicted_o,
					is_unconditional_branch,
					is_conditional_branch,
					branch_predicted;
	wire 			conditional_branch_predicted;
	reg 			instruction_requested;
	wire			target_mux_select;
	wire			is_first_load;
	wire			push_nop;
	wire			instruction_latch_enable;
	wire			pc_out_latch_enable;

	initial
	begin
		current_pc <= 0;
		instruction_requested <= 0;
	end

	//////////////////////////////////////////////////////////////
	/// Control
	//////////////////////////////////////////////////////////////

	assign opcode = current_instruction[31:26];
	assign immediate_value = { {16{current_instruction[15]}}, current_instruction[15:0] };	// sign extended

	// Note that this doesn't include all possible branch instructions, only ones that we can
	// predict in this stage.  We do not predict calls because we cannot forward LR correctly.
	assign is_unconditional_branch = (opcode == 6'b000001 && current_instruction[25:21] == `PC_INDEX
		&& current_instruction[20:16] == `PC_INDEX);	// ADD PC, PC, x
	assign is_conditional_branch = opcode[5:1] == 5'b11000;	// BNEZ or BEQZ
	assign is_backward_branch = immediate_value[31];

`ifdef BRANCH_PREDICT_NEVER
	assign branch_predicted = 0;
`endif
`ifdef BRANCH_PREDICT_ALWAYS
	assign branch_predicted = is_unconditional_branch | is_conditional_branch;
`endif
`ifdef BRANCH_PREDICT_STATIC
	assign branch_predicted = is_unconditional_branch | (is_conditional_branch & is_backward_branch);
`endif
`ifdef BRANCH_PREDICT_DYNAMIC
	assign branch_predicted = is_unconditional_branch | (is_conditional_branch & conditional_branch_predicted);
`endif

	assign target_mux_select = opcode[5:1] == 5'b11001;
	assign is_first_load = ~instruction_requested | (instruction_requested & ~imem_data_ready_i) | stall_i;
	assign push_nop = (~imem_data_ready_i & instruction_requested) | ~instruction_requested | branch_mispredicted_i;
	assign imem_read_o = ~stall_i;
	assign instruction_latch_enable = ~stall_i | branch_mispredicted_i;
	assign pc_out_latch_enable = ~stall_i;

	//////////////////////////////////////////////////////////////
	/// Datapath
	//////////////////////////////////////////////////////////////

	assign pc_plus_4 = current_pc + 4;

	branch_prediction_unit bpu(.clock_i(clock_i),
		.have_branch_history_i(have_branch_history_i),
		.branch_history_address_i(branch_history_address_i),
		.branch_history_decision_i(branch_history_decision_i),
		.current_pc_i(current_pc),
		.branch_predicted_o(conditional_branch_predicted),
		.is_backward_branch_i(is_backward_branch));

	mux2 #(32) target_mux(.out(predicted_branch_target),
		.in0(pc_plus_4 + immediate_value),				// Relative branch
		.in1({ 6'b000000, current_instruction[25:0] }),	// J format
		.sel(target_mux_select));

	assign imem_address_o = next_pc;

	mux4ps #(32) next_pc_mux(.out(next_pc),
		.in0(branch_target_i),
		.in1(current_pc),				// first load 
		.in2(predicted_branch_target),	// Predict taken
		.in3(pc_plus_4),				// Predict not taken
		.sel0(branch_mispredicted_i),
		.sel1(is_first_load),
		.sel2(branch_predicted));

	// Current PC latches either the PC for the instruction that is currently presented
	// or, if there is a stall or wait state of instruction cache, the branch target.
	always @(posedge clock_i)
		current_pc <= next_pc;

	always @(posedge clock_i)
		instruction_requested <= imem_read_o;
	
	mux2 #(32) instruction_mux(.out(current_instruction),
		.in0(imem_data_i),
		.in1(`NOP),
		.sel(push_nop));

`ifdef LATCH_IFU_OUTPUTS
	_dff #(32) pc_ff(.q(pc_o),
		.d(pc_plus_4),
		.clock(clock_i),
		.clken(pc_out_latch_enable));

	_dff bpff(.q(branch_predicted_o),
		.d(branch_predicted & imem_data_ready_i & ~branch_mispredicted_i),
		.clock(clock_i),
		.clken(instruction_latch_enable));
		
	_dff #(32) instruction_ff(.q(instruction_o),
		.d(current_instruction),
		.clock(clock_i),
		.clken(instruction_latch_enable));
`else
	assign pc_o = pc_plus_4;
	assign branch_predicted_o = branch_predicted & imem_data_ready_i;
	assign instruction_o = current_instruction;
`endif

endmodule
