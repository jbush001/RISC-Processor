#ifndef __OUTPUT_FILE_H
#define __OUTPUT_FILE_H

#include "symbol_table.h"

typedef enum fixup_type fixup_type;

enum fixup_type
{
	FIXUP_RELATIVE_I,
	FIXUP_ABSOLUTE_J,
	FIXUP_ABSOLUTE_DATA
};

int open_output_file(const char *name);
void close_output_file();
void align_pc(int align);
int get_pc();
void set_pc(int pc);
void begin_section(const char *section_name);
void emit_r(int opcode, int result, int op1, int op2);
void emit_i(int opcode, int result, int op1, int immediate);
void emit_j(int opcode, int address);
void emit_byte(int value);
void emit_long(int value);
void emit_half_word(int value);
void emit_string(const char *string);
void emit_space(int length, int value);
void add_fixup(symbol *sym, fixup_type type);
int perform_fixups();
void print_fixup_list(void);

#endif
