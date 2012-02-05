//
// Top level of pipeline
// Stages are:
//
//  instruction_fetch_unit -> instruction_decode_unit -> execute_unit -> memory_access_unit -> write_back_unit
//

module pipeline(
	clock_i,
	imem_address_o,
	imem_read_o,
	imem_data_i,
	imem_data_ready_i,
	dmem_address_o,
	dmem_data_i,
	dmem_data_o,
	dmem_write_o,
	dmem_read_o,
	dmem_sel_o,
	dmem_data_ready_i,
	halt_o,
	interrupt_request_i);

	input 			clock_i,
					imem_data_i,
					dmem_data_i,
					imem_data_ready_i,
					dmem_data_ready_i,
					interrupt_request_i;
	output 			imem_address_o,
					imem_read_o,
					dmem_address_o,
					dmem_data_o,
					dmem_write_o,
					dmem_read_o,
					dmem_sel_o;
	output 			halt_o;

	wire[31:0]		reg1_out,
					reg2_out,
					write_reg_in,
					imem_address_o,
					imem_data_i,
					pc1,
					pc2,
					pc3,
					pc4;
	wire[31:0]		operand1,
					operand2,
					exu_result,
					stage3_bypass,
					bypass_instruction3;
	wire[31:0]		operand3,
					operand3_l,
					mem_access_out,
					memory_access_address;
	wire[31:0]		ir1,
					ir2,
					ir3,
					ir4,
					dmem_address_o,
					dmem_data_i,
					dmem_data_o;
	wire[4:0]		select_read_reg1,
					select_read_reg2,
					select_write_reg;
	wire[3:0]		dmem_sel_o;
	wire 			dmem_write_o,
					dmem_read_o,
					dmem_data_ready_i,
					reg_write_enable,
					branch_mispredicted;
	wire 			imem_data_ready_i,
					imem_read_o,
					mau_stall_out,
					eu_stall_out,
					clock_i;
	wire 			branch_predicted1,
					branch_predicted2,
					branch_predicted3,
					branch_predicted4;
	wire 			have_branch_history,
					branch_history_decision,
					interrupt_request_i;

	register_file rf(.clock_i(clock_i),
		.select1_i(select_read_reg1),
		.reg1_o(reg1_out),
		.select2_i(select_read_reg2),
		.reg2_o(reg2_out),
		.select_write_i(select_write_reg),
		.write_enable_i(reg_write_enable),
		.write_value_i(write_reg_in));

	instruction_fetch_unit ifu(.clock_i(clock_i),
		.branch_mispredicted_i(branch_mispredicted),
		.branch_target_i(mem_access_out),
		.imem_address_o(imem_address_o),
		.imem_data_i(imem_data_i),
		.imem_data_ready_i(imem_data_ready_i),
		.imem_read_o(imem_read_o),
		.instruction_o(ir1),
		.stall_i(idu_stall_out),
		.pc_o(pc1),
		.branch_predicted_o(branch_predicted1),
		.have_branch_history_i(have_branch_history),
		.branch_history_address_i(pc3 - 4),
		.branch_history_decision_i(branch_history_decision));

	instruction_decode_unit idu(.clock_i(clock_i),
		.select1_o(select_read_reg1),
		.reg_value1_i(reg1_out),
		.select2_o(select_read_reg2),
		.reg_value2_i(reg2_out),
		.instruction_i(ir1),
		.instruction_o(ir2),
		.operand1_o(operand1),
		.operand2_o(operand2),
		.operand3_o(operand3),
		.ir3_i(bypass_instruction3),
		.ir4_i(ir4),
		.stage2_bypass_i(exu_result),
		.stage3_bypass_i(stage3_bypass),
		.stage4_bypass_i(mem_access_out),
		.pc_i(pc1),
		.pc_o(pc2),
		.flush_i(branch_mispredicted),
		.stall_i(eu_stall_out),
		.stall_o(idu_stall_out),
		.branch_predicted_i(branch_predicted1),
		.branch_predicted_o(branch_predicted2));
		
	execute_unit eu(.clock_i(clock_i),
		.instruction_i(ir2),
		.instruction_o(ir3),
		.flush_i(branch_mispredicted),
		.store_value_i(operand3),
		.store_value_o(operand3_l),
		.operand1_i(operand1),
		.operand2_i(operand2),
		.result_o(exu_result),
		.stall_i(mau_stall_out),
		.stall_o(eu_stall_out),
		.pc_i(pc2),
		.pc_o(pc3),
		.branch_predicted_i(branch_predicted2),
		.branch_predicted_o(branch_predicted3),
		.memory_access_address_o(memory_access_address));

	memory_access_unit mau(.clock_i(clock_i),
		.instruction_i(ir3),
		.instruction_o(ir4),
		.dmem_data_i(dmem_data_i),
		.dmem_data_o(dmem_data_o),
		.dmem_address_o(dmem_address_o),
		.dmem_sel_o(dmem_sel_o),
		.dmem_read_o(dmem_read_o),
		.dmem_write_o(dmem_write_o),
		.dmem_data_ready_i(dmem_data_ready_i),
		.branch_mispredicted_o(branch_mispredicted),
		.result_i(exu_result),
		.result_o(mem_access_out),
		.store_value_i(operand3_l),
		.bypass_instruction_o(bypass_instruction3),
		.bypass_o(stage3_bypass),
		.stall_o(mau_stall_out),
		.flush_i(branch_mispredicted),
		.pc_i(pc3),
		.pc_o(pc4),
		.branch_predicted_i(branch_predicted3),
		.have_branch_history_o(have_branch_history),
		.branch_history_decision_o(branch_history_decision),
		.memory_access_address_i(memory_access_address),
		.interrupt_request_i(interrupt_request_i));

	write_back_unit wbu(.clock_i(clock_i),
		.instruction_i(ir4),
		.write_reg_o(write_reg_in),
		.select_write_reg_o(select_write_reg),
		.reg_write_enable_o(reg_write_enable),
		.write_value_i(mem_access_out),
		.lr_i(pc4),
		.halt_o(halt_o)); 
endmodule
