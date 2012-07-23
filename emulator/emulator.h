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

#ifndef __INTERPRETER_H
#define __INTERPRETER_H

#define NUM_REGISTERS 32

// register offsets
#define PC 31
#define LINK 30
#define SP 29

typedef struct processor_state processor_state;

struct processor_state
{
	int halted;
	unsigned int r[NUM_REGISTERS];
	unsigned int controlRegisters[NUM_REGISTERS];
	unsigned char *ram;
	int ram_size;
	void (*writeConsoleCallback)(char c);
};

void init_processor_state(processor_state *state);
unsigned int read_memory_mapped(processor_state *state, unsigned int address, int size);
void write_memory_mapped(processor_state *state, unsigned int address, unsigned int value, int size);
int load_binary(const char *name, processor_state *state);
void do_instruction(processor_state *state);
void do_interrupt(processor_state *state);

#endif
