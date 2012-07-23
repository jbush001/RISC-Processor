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

#include <stdio.h>
#include <string.h>
#include "disasm.h"
#include "emulator.h"

void nullWriteConsoleCallback(char value)
{
}

void printExecutionTrace(processor_state *state)
{
	char line[256];
	unsigned int inst;
	int oldRegisterState[NUM_REGISTERS];
	int reg;

	state->writeConsoleCallback = nullWriteConsoleCallback;

	memset(oldRegisterState, 0, sizeof(int) * NUM_REGISTERS);
	
	while (!state->halted)
	{
		inst = read_memory_mapped(state, state->r[PC], 4);
		print_instruction(line, sizeof(line), state->r[PC],  inst);
		printf("%s\n", line);
		do_instruction(state);
		for (reg = 0; reg < NUM_REGISTERS - 1; reg++)
		{
			if (state->r[reg] != oldRegisterState[reg])
			{
				printf("r%d <= 0x%x\n", reg, state->r[reg]);
				oldRegisterState[reg] = state->r[reg];
			}
		}
	}
}

void rawWriteConsoleCallback(char value)
{
	printf("%c", value);
	fflush(stdout);
}

void executeRaw(processor_state *state)
{
	int timerCount = 0;

	state->writeConsoleCallback = rawWriteConsoleCallback;
	while (!state->halted)
	{
		do_instruction(state);
		if (timerCount == 0)
		{
			timerCount = 50;
			do_interrupt(state);
		}
		else
			timerCount--;
	}
}

int main(int argc, const char *argv[])
{
	processor_state state;

	if (argc != 2)
	{
		printf("enter filename\n");
		return 1;
	}

	init_processor_state(&state);
	if (load_binary(argv[1], &state) < 0)
		return -1;

//	runDebugger(&state);
//	printExecutionTrace(&state);
	executeRaw(&state);

	return 0;
}
