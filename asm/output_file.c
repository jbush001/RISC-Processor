#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "output_file.h"

typedef struct fixup fixup;

struct fixup
{
	fixup *next;
	symbol *sym;
	int address;
	fixup_type type;
};

void write_byte(unsigned char byte);

static int program_counter;
static FILE *output_file;
static fixup *fixup_list;
static char *file_data;
static int file_offset;

int open_output_file(const char *name)
{
	file_data = (char*) malloc(65536);
	file_offset = 0;

	output_file = fopen(name, "w");
	if (output_file == NULL)
		return -1;
	else
		return 0;
}

void close_output_file()
{
	fwrite(file_data, file_offset, 1, output_file);
	fclose(output_file);
}

void align_pc(int align)
{
	while (program_counter % align != 0)
	{
		write_byte(0);
		program_counter++;
	}
}

int get_pc()
{
	return program_counter;
}

void set_pc(int pc)
{
	program_counter = pc;
}

void begin_segment(const char *section_name)
{
	printf("begin segment %s\n", section_name);
}

void write_byte(unsigned char byte)
{
	file_data[file_offset++] = byte;
}

void write_short(unsigned short s)
{
	write_byte((s >> 8) & 0xff);
	write_byte(s & 0xff);
}

void write_long(unsigned int i)
{
	write_byte((i >> 24) & 0xff);
	write_byte((i >> 16) & 0xff);
	write_byte((i >> 8) & 0xff);
	write_byte(i & 0xff);
}

void emit_r(int opcode, int result, int op1, int op2)
{
	int value;

	align_pc(4);

	value = (opcode << 26) | (result << 21) | (op1 << 16) | (op2 << 11);
	write_long(value);
	program_counter += 4;
}

void emit_i(int opcode, int result, int op1, int immediate)
{
	int value;

	align_pc(4);
	value = (opcode << 26) | (result << 21) | (op1 << 16) | (immediate & 0xffff);
	write_long(value);
	program_counter += 4;
}

void emit_j(int opcode, int address)
{
	int value;

	align_pc(4);
	value = (opcode << 26) | (address & 0x3ffffff);
	write_long(value);

	program_counter += 4;
}

void emit_byte(int value)
{
	write_byte(value);
	program_counter++;
}

void emit_long(int value)
{
	align_pc(4);
	write_long(value);
	program_counter += 4;
}

void emit_half_word(int value)
{
	align_pc(2);
	write_short(value);
	program_counter += 2;
}

// Strings are written as ASCIIZ
void emit_string(const char *string)
{
	const char *c;

	for (c = string; *c != 0; c++)
		write_byte(*c);

	program_counter += strlen(string);
}

void emit_space(int length, int value)
{
	int i;

	for (i = 0; i < length; i++)
		emit_byte(value);
}

void add_fixup(symbol *sym, fixup_type type)
{
	fixup *fu;

	assert(sym != NULL);
	
	fu = (fixup*) malloc(sizeof(fixup));
	fu->next = fixup_list;
	fixup_list = fu;
	fu->sym = sym;
	fu->address = program_counter;
	fu->type = type;
}

void print_fixup_list(void)
{
	fixup *fu;
	const char *fu_types[] = { 
		"FIXUP_RELATIVE_I",
		"FIXUP_ABSOLUTE_J",
		"FIXUP_ABSOLUTE_DATA"
	};

	printf("Fixup table:\n");
	for (fu = fixup_list; fu != NULL; fu = fu->next)
		printf("%08x %15s %s\n", fu->address, fu->sym->name, fu_types[fu->type]);
}

int perform_fixups(void)
{
	fixup *fu;
	int old_val;
	int new_val;
	unsigned char *data;

	for (fu = fixup_list; fu != NULL; fu = fu->next)
	{
		if (!fu->sym->defined)
		{
			printf("undefined symbol %s\n", fu->sym->name);
			return -1;
		}

		data = (unsigned char*) file_data + fu->address;
		
		old_val = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
		switch (fu->type)
		{
			case FIXUP_RELATIVE_I:
			{
				int new_i = fu->sym->value - (fu->address + 4);
				if (new_i > 32768 || new_i < -32767)
				{
					printf("relative access at %x to %s is out of range", fu->address, 
						fu->sym->name);
					return -1;
				}
				
				new_val = (old_val & 0xffff0000) | (new_i & 0xffff);
				break;
			}

			case FIXUP_ABSOLUTE_J:
			{
				int new_j = fu->sym->value;
				new_val = (old_val & 0xfc000000) | (new_j & 0x3ffffff);
				break;
			}

			case FIXUP_ABSOLUTE_DATA:
			{
				new_val = fu->sym->value;
				break;
			}
		}

		// write new val
		data[0] = (new_val >> 24) & 0xff;
		data[1] = (new_val >> 16) & 0xff;
		data[2] = (new_val >> 8) & 0xff;
		data[3] = new_val & 0xff;
	}

	return 0;
}

