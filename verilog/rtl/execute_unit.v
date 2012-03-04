//
// Execute Stage of pipeline
// Performs arithmetic
//

`define NOP 0

module execute_unit(
	clock_i,
	instruction_i,
	instruction_o,
	flush_i,
	store_value_i,
	store_value_o,
	operand1_i,
	operand2_i,
	result_o,
	stall_i,
	stall_o,
	pc_i,
	pc_o,
	branch_predicted_i,
	branch_predicted_o,
	memory_access_address_o);

	input 			clock_i,
					instruction_i,
					operand1_i,
					operand2_i,
					flush_i,
					store_value_i,
					stall_i,
					pc_i;
	input 			branch_predicted_i;
	output 			instruction_o,
					store_value_o,
					result_o,
					stall_o,
					pc_o,
					branch_predicted_o,
					memory_access_address_o;
	
	wire[31:0]		store_value_i,
					instruction_i,
					operand1_i,
					operand2_i,
					pc_i,
					pc_o;
	wire[31:0]		instruction_sel,
					instruction_o,
					store_value_o,
					result_o,
					memory_access_address_o;
	wire[31:0]		immediate_value;
	wire[3:0]		alu_op;
	wire 			stall_i,
					stall_o,
					branch_predicted_i,
					branch_predicted_o;
	wire			branch_predicted_latch_enable;
	wire			store_value_latch_enable;
	wire			pc_latch_enable;


	//////////////////////////////////////////////////////////////
	/// Control
	//////////////////////////////////////////////////////////////

	assign stall_o = stall_i;
	assign alu_op = ~instruction_i[31] ? instruction_i[30:27] : 0;
	assign branch_predicted_latch_enable = ~stall_i | flush_i;
	assign store_value_latch_enable = ~stall_i;
	assign pc_latch_enable = ~stall_i;

	//////////////////////////////////////////////////////////////
	/// Datapath
	//////////////////////////////////////////////////////////////

	assign immediate_value = { {16{instruction_i[15]}}, instruction_i[15:0] };	// sign extended
	assign memory_access_address_o = operand1_i + immediate_value;

	alu alu(alu_op, result_o, operand1_i, operand2_i);

	_dff #(32) pc_ff(.q(pc_o),
		.d(pc_i),
		.clock(clock_i),
		.clken(pc_latch_enable));

	_dff bp_ff(.q(branch_predicted_o),
		.d(branch_predicted_i & ~flush_i),
		.clock(clock_i),
		.clken(branch_predicted_latch_enable));
	
	_dff #(32) store_value_ff(.q(store_value_o),
		.d(store_value_i),
		.clock(clock_i),
		.clken(store_value_latch_enable));

	assign instruction_o = instruction_i;
endmodule
