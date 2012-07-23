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
