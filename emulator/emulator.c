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

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "emulator.h"

#define STACK_SIZE 1024
#define MEMORY_SIZE 65536

#define extend16(_val_) (((_val_) & 0x8000) ? ((_val_) | 0xffff0000) : (_val_))

// Convenience macros for accessing parts of instructions
#define opcode(instruction) ((instruction >> 26) & 63)
#define result(instruction) ((instruction >> 21) & 31)
#define op1(instruction) ((instruction >> 16) & 31)
#define op2(instruction) ((instruction >> 11) & 31)
#define imm(instruction) extend16(instruction & 0xffff)
#define address(instruction) (instruction & 0x3ffffff)

unsigned int read_memory_phys(processor_state *state, unsigned int address, int size);
void write_memory_phys(processor_state *state, unsigned int address, unsigned int value, int size);

void debugPrintf(processor_state *state, const char *fmt, ...)
{
	va_list args;
	char tmp[256];
	int i;

	if (state->writeConsoleCallback)
	{
		va_start(args, fmt);
		vsnprintf(tmp, sizeof(tmp), fmt, args);
		va_end(args);
		
		for (i = 0; tmp[i] != '\0'; i++)
			state->writeConsoleCallback(tmp[i]);
	}
}

void init_processor_state(processor_state *state)
{
	state->halted = 0;
	memset(state->r, 0, sizeof(state->r));
	memset(state->controlRegisters, 0, sizeof(state->controlRegisters));
	state->ram = (unsigned char*) malloc(MEMORY_SIZE);
	state->ram_size = MEMORY_SIZE;
}

unsigned int read_memory_mapped(processor_state *state, unsigned int address, int size)
{
	return read_memory_phys(state, address, size);
}

void write_memory_mapped(processor_state *state, unsigned int address, unsigned int value, int size)
{
	write_memory_phys(state, address, value, size);
}

unsigned int read_memory_phys(processor_state *state, unsigned int address, int size)
{
	if (address % size != 0)
	{
		// XXX jump to exception handler
		printf("unaligned memory access\n");
		return 0;
	}

	if (address + size > state->ram_size)
		return 0;

	switch (size)
	{
		case 1:
			return state->ram[address];

		case 2:
			return (state->ram[address] << 8) | state->ram[address + 1];

		case 4:
			return (state->ram[address] << 24) | (state->ram[address + 1] << 16)
				| (state->ram[address + 2] << 8) | (state->ram[address + 3]);

		default:
			assert(0);
	}
}

void write_memory_phys(processor_state *state, unsigned int address, unsigned int value, int size)
{
	if (address % size != 0)
	{
		// XXX jump to exception handler
		printf("unaligned memory access\n");
		return;
	}

	if (address == 0xa0000000)
	{
		state->writeConsoleCallback(value);
		return;
	}

	if (address + size > state->ram_size)
		return;

	switch (size)
	{
		case 1:
			state->ram[address] = value & 0xff;
			break;

		case 2:
			state->ram[address] = (value >> 8) & 0xff;
			state->ram[address + 1] = value & 0xff;
			break;

		case 4:
			state->ram[address] = (value >> 24) & 0xff;
			state->ram[address + 1] = (value >> 16) & 0xff;
			state->ram[address + 2] = (value >> 8) & 0xff;
			state->ram[address + 3] = value & 0xff;
			break;

		default:
			assert(0);
	}
}

void do_instruction(processor_state *state)
{
	int instruction = read_memory_mapped(state, state->r[PC], 4);
	int value;

	if (state->halted)
		return;

	state->r[PC] += 4;
	state->r[0] = 0;

	switch (opcode(instruction))
	{
		// Arithmetic
#define do_register_op(_op_) \
	state->r[result(instruction)] = state->r[op1(instruction)] _op_ state->r[op2(instruction)]

#define do_immediate_op(_op_) \
	state->r[result(instruction)] = state->r[op1(instruction)] _op_ imm(instruction);

		case 0:	do_register_op(+); break;
		case 1:	do_immediate_op(+); break;
		case 2:	do_register_op(-); break;
		case 3:	do_immediate_op(-); break;
		case 4:	do_register_op(&); break;
		case 5:	do_immediate_op(&); break;
		case 6:	do_register_op(|); break;
		case 7:	do_immediate_op(|); break;
		case 8:	do_register_op(^); break;
		case 9:	do_immediate_op(^); break;
		case 10: do_register_op(<<); break;
		case 11: do_immediate_op(<<); break;
		case 12: do_register_op(>>); break;
		case 13: do_immediate_op(>>); break;
		case 14:	// asr R
			state->r[result(instruction)] = ((int)state->r[op1(instruction)]) >> state->r[op2(instruction)];
			break;

		case 15:	// asr I		
			state->r[result(instruction)] = ((int)state->r[op1(instruction)]) >> imm(instruction);
			break;

		case 16: do_register_op(<); break;
		case 17: do_immediate_op(<); break;
		case 18: do_register_op(>); break;
		case 19: do_immediate_op(>); break;

		// Load/Store
		case 35: // loadw
			state->r[result(instruction)] = read_memory_mapped(state, state->r[op1(instruction)] 
				+ imm(instruction), 4);
			break;

		case 38: // loads
			value = extend16(read_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 2));
			state->r[result(instruction)] = value;
			break;
			
		case 34: // loadsu
			state->r[result(instruction)] = read_memory_mapped(state, state->r[op1(instruction)] 
				+ imm(instruction), 2);
			break;

		case 37: // loadb
			value = read_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 1);
			if (value & 0x80)
				value |= 0xffffff00;	// Sign extend

			state->r[result(instruction)] = value;
			break;

		case 33:	// loadbu
			value = read_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 1);
			state->r[result(instruction)] = value;
			break;

		case 43:	// storew
			write_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 
				state->r[result(instruction)], 4);
			break;

		case 42:	// stores
			write_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 
				state->r[result(instruction)] & 0xffff, 2);
			break;

		case 41:	// storeb
			write_memory_mapped(state, state->r[op1(instruction)] + imm(instruction), 
				state->r[result(instruction)] & 0xff, 1);
			break;

		case 48:	// beqz
			if (state->r[result(instruction)] == 0)
				state->r[PC] += imm(instruction);
			
			break;

		case 49:	// bnez
			if (state->r[result(instruction)] != 0)
				state->r[PC] += imm(instruction);
			
			break;
		
		case 50:	// call addr
			state->r[LINK] = state->r[PC];
			state->r[PC] = address(instruction);
			break;

		case 51:	// call reg
			state->r[LINK] = state->r[PC];
			state->r[PC] = state->r[op1(instruction)];
			break;

		case 52:	// read control register
			state->r[result(instruction)] = state->controlRegisters[op1(instruction)];
			break;
			
		case 53:	// write control register
			state->controlRegisters[result(instruction)] = state->r[op1(instruction)];
			break;
			
		case 56:	// rfi (return from interrupt)
			state->r[PC] = state->controlRegisters[1];
			state->controlRegisters[0] |= 1;
			break;

		case 62:	// halt
			state->halted = 1;
			break;
		
		case 63:	// nop
			break;
			
		default:
			printf("unknown instruction %d\n", opcode(instruction));
			exit(1);
	}
}

void do_interrupt(processor_state *state)
{
	if (!(state->controlRegisters[0] & 1))
		return;	// Interrupts masked
		
	state->controlRegisters[0] &= ~1;
	state->controlRegisters[1] = state->r[PC];
	state->r[PC] = 4;
}

int load_binary(const char *name, processor_state *state)
{
	FILE *f = fopen(name, "rb");
	if (f == NULL) 
	{
		perror("opening file");
		return -1;
	}
	
	fread(state->ram, state->ram_size, 1, f);
	fclose(f);
	
	return 0;
}
