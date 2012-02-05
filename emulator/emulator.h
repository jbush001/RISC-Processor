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
