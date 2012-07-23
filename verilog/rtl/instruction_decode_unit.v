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
// Instruction Decode pipeline stage
// - Responsible for fetching register/immediate operands
// - Performs register bypassing (forwarding)
// - Detects memory RAW hazards and inserts NOPs in pipeline to avoid them.
//

`define PC_INDEX 31
`define NOP 0

module instruction_decode_unit(
	clock_i,
	select1_o,
	reg_value1_i,
	select2_o,
	reg_value2_i,
	instruction_i,
	instruction_o,
	operand1_o,
	operand2_o,
	operand3_o,
	ir3_i,
	ir4_i,
	stage2_bypass_i,
	stage3_bypass_i,
	stage4_bypass_i,
	pc_i,
	pc_o,
	flush_i,
	stall_i,
	stall_o,
	branch_predicted_i,
	branch_predicted_o);

	input 			clock_i,
					reg_value1_i,
					reg_value2_i,
					instruction_i,
					stage2_bypass_i,
					ir3_i,
					ir4_i;
	input 			stage3_bypass_i,
					stage4_bypass_i,
					pc_i,
					flush_i,
					stall_i,
					branch_predicted_i;
	output 			select1_o,
					select2_o,
					instruction_o,
					operand1_o,
					operand2_o,
					stall_o,
					operand3_o;
	output 			branch_predicted_o,
					pc_o;
	
	wire[31:0]		ir3_i,
					ir4_i,
					reg_value1_i,
					reg_value2_i,
					stage2_bypass_i,
					stage3_bypass_i,
					stage4_bypass_i;
	wire[31:0]		pc_o,
					pc_i,
					instruction_i,
					instruction_o,
					next_instr;
	wire[31:0]		operand1muxout,
					operand2muxout,
					operand3muxout,
					operand1_o,
					operand2_o,
					operand3_o;
	wire[31:0]		immediate_value;
	wire[5:0]		opcode;
	wire[4:0]		bypass1_result_reg,
					bypass2_result_reg,
					bypass3_result_reg;
	wire[4:0]		result_register,
					op1_register,
					op2_register,
					select1_o,
					select2_o;
	wire 			clock_i,
					stall_i,
					stall_o;
	wire 			op1_bypass1,
					op1_bypass2,
					op1_bypass3;
	wire 			op2_bypass1,
					op2_bypass2,
					op2_bypass3,
					op2_select_pc;
	wire 			op3_bypass1,
					op3_bypass2,
					op3_bypass3,
					op3_select_pc;
	wire 			is_load,
					is_store,
					is_call,
					is_conditional_branch,
					op2_select_immediate_field;
	wire 			has_op1,
					has_op2,
					load_interlock,
					load_interlock1,
					load_interlock2,
					flush_i;
	wire 			bypass1_has_result,
					bypass2_has_result,
					bypass3_has_result;
	wire 			branch_predicted_i,
					branch_predicted_o,
					control_register_interlock;
	wire 			write_back_enable_o,
					load_store_interlock;
	wire			op2_is_result_field;
	wire			op1_select_pc;
	wire			operand1_is_zero;
	wire			operand2_is_zero;
	wire			operand3_is_zero;
	wire 			next_instruction_latch_enable;
	wire 			instruction_o_latch_enable;
	wire 			branch_predict_o_latch_enable;
	wire			operand_latch_enable;
	wire			operand3_pc_select;
	wire			pc_o_latch_enable;

	//////////////////////////////////////////////////////////////
	/// Control
	//////////////////////////////////////////////////////////////

	// Instruction fields
	assign opcode = instruction_i[31:26];
	assign result_register = instruction_i[25:21];
	assign op1_register = instruction_i[20:16];
	assign op2_register = instruction_i[15:11];

	// Decode instruction types
	assign is_load = opcode[5:3] == 3'b100;
	assign is_store = opcode[5:2] == 4'b1010;
	assign is_call = opcode[5:1] == 5'b11001;
	assign is_conditional_branch = opcode[5:1] == 5'b11000;
	assign op2_select_immediate_field = (~opcode[5] && opcode[0]) || is_load || is_store || is_conditional_branch;
	assign has_op1 = ~opcode[5] || is_load || is_store || is_conditional_branch;
	assign has_op2 = ~opcode[5] && ~opcode[0];

	// Result bypassing information.  An instruction has a result if it is an arithmetic expression,
	// it is a load operation.
	assign bypass1_result_reg = instruction_o[25:21];
	assign bypass2_result_reg = ir3_i[25:21];
	assign bypass3_result_reg = ir4_i[25:21];
	assign bypass1_has_result = ~instruction_o[31] || instruction_o[31:29] == 3'b100;	
	assign bypass2_has_result = ~ir3_i[31] || ir3_i[31:29] == 3'b100;
	assign bypass3_has_result = ~ir4_i[31] || ir4_i[31:29] == 3'b100;

	// Load interlock handling
	assign load_interlock = load_interlock1 | load_interlock2 | load_store_interlock | control_register_interlock;
	assign load_interlock1 = (instruction_o[31:29] == 3'b100 &&	// prev instruction is load
			((bypass1_result_reg == op1_register && has_op1)	// param1 interlock
			|| (bypass1_result_reg == op2_register && has_op2)	// param2 interlock
			|| (bypass1_result_reg == result_register && (is_store || is_conditional_branch)))); // result (store) interlock
	assign load_interlock2 = (ir3_i[31:29] == 3'b100 &&	// prev instruction is load
			((bypass2_result_reg == op1_register && has_op1)	// param1 interlock
			|| (bypass2_result_reg == op2_register && has_op2)	// param2 interlock
			|| (bypass2_result_reg == result_register && (is_store || is_conditional_branch)))); // result (store) interlock
	assign load_store_interlock = instruction_o[31:28] == 4'b1010 && is_load;	// prev is store, this is load

	// This is a little lazy: any control register move automatically flushes the pipeline after it to
	// ensure no hazards.  Since these aren't really speed critical registers, this is probably adequate.
	assign control_register_interlock = instruction_o[31:27] == 5'b11010 || ir3_i[31:27] == 5'b11010 || ir4_i[31:27] == 5'b11010;

	assign stall_o = stall_i | load_interlock;

	// Operand 1 select
	assign op1_bypass1 = bypass1_has_result & bypass1_result_reg == op1_register;
	assign op1_bypass2 = bypass2_has_result & bypass2_result_reg == op1_register;
	assign op1_bypass3 = bypass3_has_result & bypass3_result_reg == op1_register;
	assign op1_select_pc = is_conditional_branch | op1_register == `PC_INDEX;
	assign operand1_is_zero = select1_o == 0 && ~is_conditional_branch;

	// Operand2 select
	assign op2_bypass1 = bypass1_has_result & bypass1_result_reg == op2_register;
	assign op2_bypass2 = bypass2_has_result & bypass2_result_reg == op2_register;
	assign op2_bypass3 = bypass3_has_result & bypass3_result_reg == op2_register;
	assign op2_select_pc = op2_register == `PC_INDEX;
	assign op2_is_result_field = is_store | is_conditional_branch;
	assign operand2_is_zero = select2_o == 0 && ~op2_select_immediate_field;
	
	// Operand3 select
	assign op3_bypass1 = bypass1_has_result & bypass1_result_reg == result_register;
	assign op3_bypass2 = bypass2_has_result & bypass2_result_reg == result_register;
	assign op3_bypass3 = bypass3_has_result & bypass3_result_reg == result_register;
	assign op3_select_pc = is_call || result_register == `PC_INDEX;
	assign operand3_is_zero = (is_store | is_conditional_branch) & select2_o == 0;
	
	// Latch enables	
	assign next_instruction_latch_enable = load_interlock | flush_i;
	assign branch_predict_o_latch_enable = ~stall_i | flush_i;
	assign pc_o_latch_enable = ~stall_i & ~load_interlock;
	assign instruction_o_latch_enable = ~stall_i;
	assign operand_latch_enable = ~stall_i;

	//////////////////////////////////////////////////////////////
	/// Datapath
	//////////////////////////////////////////////////////////////

	assign immediate_value = { {16{instruction_i[15]}}, instruction_i[15:0] };	// sign extended

	// Register select logic
	assign select1_o = op1_register;
	mux2 #(5) select2mux(.out(select2_o),
		.in0(op2_register),
		.in1(result_register),
		.sel(op2_is_result_field));

	// Operand 1 select
	mux5ps #(32) operand1mux(.out(operand1muxout),
		.in0(pc_i),
		.in1(stage2_bypass_i),
		.in2(stage3_bypass_i),
		.in3(stage4_bypass_i),
		.in4(reg_value1_i),
		.sel0(op1_select_pc),
		.sel1(op1_bypass1),
		.sel2(op1_bypass2),
		.sel3(op1_bypass3));
	
	_dff #(32) operand1_reg(.q(operand1_o),
		.d(operand1_is_zero ? 0 : operand1muxout),	// AND
		.clock(clock_i),
		.clken(operand_latch_enable));

	// Operand2 select
	mux6ps #(32) operand2mux(.out(operand2muxout),
		.in0(immediate_value),
		.in1(pc_i),
		.in2(stage2_bypass_i),
		.in3(stage3_bypass_i),
		.in4(stage4_bypass_i),
		.in5(reg_value2_i),
		.sel0(op2_select_immediate_field),
		.sel1(op2_select_pc),
		.sel2(op2_bypass1),
		.sel3(op2_bypass2),
		.sel4(op2_bypass3));
	
	_dff #(32) operand2_reg(.q(operand2_o),
		.d(operand2_is_zero ? 0 : operand2muxout),	// AND
		.clock(clock_i),
		.clken(operand_latch_enable));	

	// Operand3 select
	mux5ps #(32) operand3mux(.out(operand3muxout),
		.in0(pc_i),
		.in1(stage2_bypass_i),
		.in2(stage3_bypass_i),
		.in3(stage4_bypass_i),
		.in4(reg_value2_i),
		.sel0(op3_select_pc),
		.sel1(op3_bypass1),
		.sel2(op3_bypass2),
		.sel3(op3_bypass3));

	_dff #(32) operand3_reg(.q(operand3_o),
		.d(operand3_is_zero ? 0 : operand3muxout),	// AND
		.clock(clock_i),
		.clken(operand_latch_enable));

	// Latched outputs
	_dff #(32) pc_ff(.q(pc_o),
		.d(pc_i),
		.clock(clock_i),
		.clken(pc_o_latch_enable));	// Be sure not to push PC if we are pushing NOP

	mux2 #(32) instructionoutmux(.out(next_instr),
		.in0(instruction_i),
		.in1(`NOP),
		.sel(next_instruction_latch_enable));

	_dff #(32) instruction_reg(.q(instruction_o),
		.d(next_instr),
		.clock(clock_i),
		.clken(instruction_o_latch_enable));

	_dff predicted_ff(.q(branch_predicted_o),
		.d(branch_predicted_i & ~flush_i & ~load_interlock),	// Note: if we are putting a NOP, send non-predict bit
		.clock(clock_i),
		.clken(branch_predict_o_latch_enable));
endmodule
