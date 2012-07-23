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


module instruction_decoder_test;

	reg 			clock;
	reg 			reset;
	wire[4:0]		select1,
					select2;
	reg[31:0]		reg_value1,
					reg_value2;
	reg[31:0]		instruction_i;
	wire[31:0]		instruction_o;
	wire[31:0]		operand1,
					operand2,
					operand3;
	reg[31:0]		ir3,
					ir4;
	reg[31:0]		bypass2,
					bypass3,
					bypass4;
	reg[31:0]		pc;
	reg 			flush,
					stall_i;
	wire 			stall_o;

	instruction_decode_unit idu(.clock_i(clock),
		.reset_i(reset),
		.select1_o(select1),
		.reg_value1_i(reg_value1),
		.select2_o(select2),
		.reg_value2_i(reg_value2),
		.instruction_i(instruction_i),
		.instruction_o(instruction_os),
		.operand1_o(operand1),
		.operand2_o(operand2),
		.operand3_o(operand3),
		.ir3_i(ir3),
		.ir4_i(ir4),
		.stage2_bypass_i(bypass2),
		.stage3_bypass_i(bypass3),
		.stage4_bypass_i(bypass4),
		.pc_i(pc),
		.flush_i(flush),
		.stall_i(stall_i),
		.stall_o(stall_o));

	function test_register_operand;
		input[5:0]	opcode;
		
		integer i;
		integer j;
	begin
		reset <= 1;
		#3 reset <= 0;

		reg_value1 <= 'haabbccdd;
		reg_value2 <= 'h12345678;
		ir3 <= `NOP;
		ir4 <= `NOP;

		for (i = 1; i < 30; i = i << 1)
		begin
			for (j = 0; j < 30; j = j << 1)
			begin
				instruction_i <= { opcode, 5'd1, i[4:0], j[4:0], 11'd0 };
				#1 if (operand1 != 'haabbccdd || operand2 != 'h12345678)
				begin
					$display("fail register operand %d", opcode);
					$finish;
				end
				
				if (select1 != i)
				begin
					$display("select1 wrong %d", opcode);
					$finish;
				end
				
				if (select2 != j)
				begin
					$display("select2 wrong operand %d", opcode);
					$finish;
				end
			end
		end
	end
	endfunction 

	function test_immediate_operand;
		input[5:0]	opcode;
		
		integer i;
		integer j;
	begin
		reset <= 1;
		#3 reset <= 0;

		reg_value1 <= 'haabbccdd;
		reg_value2 <= 'h12345678;
		ir3 <= `NOP;
		ir4 <= `NOP;

		for (i = 1; i < 30; i = i << 1)
		begin
			for (j = 0; j < 'h10000; j = j << 1)
			begin
				instruction_i <= { opcode, 5'd1, i[4:0], j[15:0] };
				#1 if (operand1 != 'haabbccdd || operand2 != 'h12345678)
				begin
					$display("fail register operand %d", opcode);
					$finish;
				end
				
				if (select1 != i)
				begin
					$display("select1 wrong %d", opcode);
					$finish;
				end
			end
		end
	end
	endfunction
	
	initial
	begin
		clock <= 0;
		instruction_i <= `NOP;
		ir3 <= `NOP;
		ir4 <= `NOP;
		bypass2 <= 0;
		bypass3 <= 0;
		bypass4 <= 0;
		pc <= 0;
		flush <= 0;
		stall_i <= 0;
		reg_value1 <= 0;
		reg_value2 <= 0;

		// Initialize
		reset <= 1;
		#3 reset <= 0;

		// PC as operand (op1, op2, op3)

		// Basic register instruction test
		//  Test that values are passes through correctly
		//  Test that register selectors are passed through
		
		
		// Basic immediate instruction test
		
		
		// Test bypassing
		// stage1, stage2, stage3 x operand1, operand2, operand3

		// Load interlock
		
		// Flush
		
		// Stall
		
	end
endmodule
