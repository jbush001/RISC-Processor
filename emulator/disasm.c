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

#define opcode(instruction) ((instruction >> 26) & 63)
#define result(instruction) ((instruction >> 21) & 31)
#define op1(instruction) ((instruction >> 16) & 31)
#define op2(instruction) ((instruction >> 11) & 31)
#define imm(instruction) ((short)(instruction & 0xffff))
#define address(instruction) (instruction & 0x3ffffff)

enum instruction_format
{
	IF_R,				// r1, r2, r3
	IF_I,				// r1, r2, n
	IF_I_TWO_INDIRECT,	// r1, n(r2)
	IF_I_ONE_PARAM,		// r1, n
	IF_J,				// n
	IF_R_ONE_INDIRECT,	// (r1)
	IF_R_ONE_PARAM,		// r1
	IF_R_TWO_PARAM,		// r1, r2
	IF_CR_READ,			// r1, cr1
	IF_CR_WRITE,		// cr1, r1
	IF_NONE				// no params
};

const struct {
	const char *name;
	int format;
} instruction_table [] = {
	{ "add", IF_R },
	{ "add", IF_I },
	{ "sub", IF_R },
	{ "sub", IF_I },
	{ "and", IF_R },
	{ "and", IF_I },
	{ "or", IF_R },
	{ "or", IF_I },
	{ "xor", IF_R },
	{ "xor", IF_I },
	{ "lsl", IF_R },
	{ "lsl", IF_I },
	{ "lsr", IF_R },
	{ "lsr", IF_I },
	{ "asr", IF_R },
	{ "asr", IF_I },
	{ "slt", IF_R },
	{ "slt", IF_I },
	{ "sgt", IF_R },
	{ "sgt", IF_I },
	{ 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 },
	{ 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, 
	{ "loadbu", IF_I_TWO_INDIRECT },
	{ "loadsu", IF_I_TWO_INDIRECT },
	{ "loadw", IF_I_TWO_INDIRECT },
	{ 0, 0 },
	{ "loadb", IF_I_TWO_INDIRECT },
	{ "loads", IF_I_TWO_INDIRECT },
	{ 0, 0 }, { 0, 0 },
	{ "storeb", IF_I_TWO_INDIRECT },
	{ "stores", IF_I_TWO_INDIRECT },
	{ "storew", IF_I_TWO_INDIRECT },
	{ 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, 
	{ "beqz", IF_I_ONE_PARAM },
	{ "bnez", IF_I_ONE_PARAM },
	{ "call", IF_J },
	{ "call", IF_R_ONE_PARAM },
	{ "rdctl", IF_CR_READ }, 
	{ "wrctl", IF_CR_WRITE }, 
	{ 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 }, 
	{ 0, 0 }, { 0, 0 },
	{ "halt", IF_NONE },
	{ "nop", IF_NONE }
};

void print_instruction(char *outBuffer, int maxLength, int address, int instruction)
{
	snprintf(outBuffer, maxLength, "%08x: ", address);
	maxLength -= strlen(outBuffer);
	outBuffer += strlen(outBuffer);

	// Special case pseudo ops
	if (opcode(instruction) == 1 && result(instruction) == 31 && op1(instruction) == 31)
	{
		snprintf(outBuffer, maxLength, "jump     %08x", address + 4 + imm(instruction));
		return;
	}

	snprintf(outBuffer, maxLength, "%-8s ", instruction_table[opcode(instruction)].name);
	maxLength -= strlen(outBuffer);
	outBuffer += strlen(outBuffer);

	switch (instruction_table[opcode(instruction)].format)
	{
		case IF_R:				// r1, r2, r3
			snprintf(outBuffer, maxLength, "r%d, r%d, r%d", result(instruction), op1(instruction), op2(instruction));
			break;

		case IF_I:				// r1, r2, n
			snprintf(outBuffer, maxLength, "r%d, r%d, 0x%x", result(instruction), op1(instruction), imm(instruction));
			break;

		case IF_I_TWO_INDIRECT:	// r1, n(r2)
			snprintf(outBuffer, maxLength, "r%d, %d(r%d)", result(instruction), imm(instruction), op1(instruction));
			break;

		case IF_I_ONE_PARAM:		// r1, n
			snprintf(outBuffer, maxLength, "r%d, 0x%x (pc + %d)", result(instruction), address + 4 + 4 
				* imm(instruction), imm(instruction));
			break;

		case IF_J:				// n
			snprintf(outBuffer, maxLength, "0x%x", imm(instruction));
			break;

		case IF_R_ONE_INDIRECT:	// (r1)
			snprintf(outBuffer, maxLength, "(r%d)", result(instruction));
			break;

		case IF_R_ONE_PARAM:
			snprintf(outBuffer, maxLength, "r%d", op1(instruction));
			break;

		case IF_R_TWO_PARAM:
			snprintf(outBuffer, maxLength, "r%d, r%d", op1(instruction), op2(instruction));
			break;
			
		case IF_CR_READ:	// rn, crn
			snprintf(outBuffer, maxLength, "r%d, cr%d", result(instruction), op1(instruction));
			break;
			
		case IF_CR_WRITE:	// crn, rn
			snprintf(outBuffer, maxLength, "cr%d, r%d", result(instruction), op1(instruction));
			break;
			
		case IF_NONE:
			break;
	}	
}
