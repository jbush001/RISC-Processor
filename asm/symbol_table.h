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

#ifndef __SYMBOL_TABLE_H
#define __SYMBOL_TABLE_H

typedef struct symbol symbol;
typedef enum symbol_type symbol_type;

enum symbol_type
{
	SYM_UNKNOWN,
	SYM_CONSTANT,
	SYM_LABEL
};

struct symbol
{
	symbol *next;
	symbol_type type;
	int value;
	int defined;
	char name[1];
};

symbol *find_symbol(const char *name);
symbol *add_symbol(const char *name, symbol_type type, int value);
void print_sym_table(void);

#endif
