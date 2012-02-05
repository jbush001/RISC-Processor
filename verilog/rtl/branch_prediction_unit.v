//
// Predicts whether the conditional branch instruction at a given address will be taken
// or not based on recent branch history.  A 32 entry branch history buffer, keyed off
// the least significant bits of the PC, keeps track of previously taken branches.
//

// If GSHARE isn't enabled, uses bimodal protection
//`define ENABLE_GSHARE

module branch_prediction_unit(
	clock_i,
	have_branch_history_i,
	branch_history_address_i,
	branch_history_decision_i,
	current_pc_i,
	branch_predicted_o,
	is_backward_branch_i);
	
	parameter BRANCH_HISTORY_SIZE = 32;
	
	input 			clock_i,
					have_branch_history_i,
					branch_history_address_i,
					branch_history_decision_i,
					current_pc_i;
	input 			is_backward_branch_i;
	output 			branch_predicted_o;
	
	wire[31:0]		branch_history_address_i,
					current_pc_i;
	wire 			clock_i,
					branch_history_decision_i,
					have_branch_history_i,
					is_backward_branch_i,
					branch_predicted_o;
	reg[1:0]		branch_counters[0:BRANCH_HISTORY_SIZE - 1];
	wire[1:0]		old_branch_counter;
	reg[1:0]		new_branch_counter;
	wire[1:0]		current_branch_counter;

	integer i;
	initial
	begin
		for (i = 0; i < BRANCH_HISTORY_SIZE; i = i + 1)
			branch_counters[i] <= 0;
	end

`ifdef ENABLE_GSHARE
	reg[4:0]		branch_history;

	initial
		branch_history <= 0;

	always @(posedge clock_i)
	begin
		if (have_branch_history_i)
			branch_history <= { branch_history[3:0], branch_history_decision_i };
	end
`else
	wire[4:0]		branch_history = 0;
`endif

	assign old_branch_counter = branch_counters[branch_history_address_i[6:2] ^ branch_history];

	// 2 bit saturating counter.
	// 0 = strongly not taken 1 = not taken 2 = taken 3 = strongly taken
	// decision 0 = not taken 1 = taken
	always @(branch_history_decision_i, old_branch_counter)
	begin
		case ({branch_history_decision_i, old_branch_counter})
			3'b0_00: new_branch_counter = 2'b00;
			3'b0_01: new_branch_counter = 2'b00;
			3'b0_10: new_branch_counter = 2'b01;
			3'b0_11: new_branch_counter = 2'b10;
			3'b1_00: new_branch_counter = 2'b01;
			3'b1_01: new_branch_counter = 2'b10;
			3'b1_10: new_branch_counter = 2'b11;
			3'b1_11: new_branch_counter = 2'b11;
		endcase
	end

	always @(posedge clock_i)
	begin
		if (have_branch_history_i)
			branch_counters[branch_history_address_i[6:2] ^ branch_history] <= new_branch_counter;
	end
	
	assign current_branch_counter = branch_counters[current_pc_i[6:2] ^ branch_history];
	assign branch_predicted_o = current_branch_counter[1];
endmodule
