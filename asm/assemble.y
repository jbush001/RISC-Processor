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


%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../symbol_table.h"
#include "../output_file.h"

static int line_num = 0;

static int open_include_file(const char *name);

void yyerror (char *error) 
{
	fprintf(stderr, "%d: %s\n", line_num, error);
}

// Formats:
//   0  mnemonic r1, r2, r3
//   1  mnemonic r1, expr(r2)
//   2  mnemonic r1, r2, expr
static int opcode_table[][6] = {
	/* add */		{ 0, -1, 1 },
	/* sub */	  	{ 2, -1, 3 },
	/* and */   	{ 4, -1, 5 },
	/* or */    	{ 6, -1, 7 },
	/* xor */   	{ 8, -1, 9 },
	/* lsl */   	{ 10, -1, 11 },
	/* lsr */   	{ 12, -1, 13 },
	/* asr */   	{ 14, -1, 15 },
	/* loadw */ 	{ -1, 35, -1 },
	/* loads */ 	{ -1, 38, -1 },
	/* loadsu */ 	{ -1, 34, -1 },
	/* loadb */  	{ -1, 37, -1 },
	/* loadbu */ 	{ -1, 33, -1 },
	/* storew */ 	{ -1, 43, -1 },
	/* stores */ 	{ -1, 42, -1 },
	/* storeb */ 	{ -1, 41, -1 },
	/* slt */		{ 16, -1, 17 },
	/* sgt */   	{ 18, -1, 19 },
};

int lookup_opcode(int mnemonic, int format)
{
	return opcode_table[mnemonic][format];
}

int add_fixup_by_name(const char *name, fixup_type type)
{
	symbol *sym = find_symbol(name);
	if (sym == NULL)
	{
		// forward reference
		sym = add_symbol(name, SYM_LABEL, 0);
	}
	else if (sym->type == SYM_CONSTANT)
	{
		yyerror("jump not to label");
		return -1;
	}

	// Label, need a fixup
	add_fixup(sym, type);

	return 0;
}

void unescape_string(char *out, const char *in)
{
	int escaped = 0;

	while (*in)
	{
		if (escaped)
		{
			switch (*in)
			{
				case 't':
					*out++ = 12;
					break;
				case '\\':
					*out++ = '\\';
					break;
				case 'n':
					*out++ = 10;
					break;
				case 'r':
					*out++ = 13;
					break;
				case '\'':
					*out++ = '\'';
					break;
				case '"':
					*out++ = '"';
					break;

				default:
					;	// Ignore unknown escape
			}

			escaped = 0;
		}
		else if (*in == '\\')
			escaped = 1;
		else
			*out++ = *in;

		in++;
	}
}


%}

%union {
	int mnemonic;
	int intval;
	symbol *sym;
	char strval[256];
};

%token TOK_REG TOK_MNEMONIC TOK_HALT TOK_SEGMENT TOK_RFI TOK_CONTROL_REG TOK_WRCTL TOK_RDCTL
%token TOK_DB TOK_DH TOK_DL TOK_DS TOK_LITERAL TOK_EQU TOK_MOVE TOK_INCLUDE TOK_SPACE
%token TOK_LABEL TOK_CONSTANT TOK_STRING TOK_NOP TOK_JUMP TOK_CALL TOK_BEQZ TOK_BNEZ TOK_ALIGN

%type<intval> TOK_REG TOK_BEQZ TOK_BNEZ TOK_NOP TOK_SEGMENT TOK_CONTROL_REG
%type<intval> TOK_DB TOK_DH TOK_DL TOK_DS TOK_LITERAL expr TOK_EQU TOK_CALL
%type<mnemonic> TOK_MNEMONIC
%type<sym> TOK_LABEL TOK_CONSTANT

%type<strval> TOK_STRING

%left '+' '-'
%left '*' '/'
%left '&' '|' 
%left TOK_LSHIFT TOK_RSHIFT

%%

program			:	statement program
				|	statement
				;

statement		:	TOK_LABEL 
					{
						symbol *sym;

						// Label
						align_pc(4);	// Ensure we're aligned

						if ($1->defined)
						{
							char error[128];	
							sprintf(error, "redefined symbol %s\n", $1->name);
							yyerror(error);
							YYABORT;
						}

						$1->value = get_pc();
						$1->defined = 1;
					}
					op 
				|	TOK_LABEL TOK_EQU expr
					{
						if ($1->type != SYM_UNKNOWN)
						{
							char error[128];	
							sprintf(error, "redefined symbol %s\n", $1->name);
							yyerror(error);
							YYABORT;
						}
						else
						{
							$1->type = SYM_CONSTANT;
							$1->value = $3;
						}
					}
				|	op 
				|	TOK_SEGMENT TOK_STRING
					{
						begin_segment($2);
					}
				|	TOK_INCLUDE TOK_STRING
					{
						if (open_include_file($2) < 0)
							YYABORT;
					}
				;

op				:	op_three_reg
				|	op_immediate
				| 	op_move
				|	op_load_store
				|	op_nop
				|	op_call
				|	op_call_reg
				|	op_jump
				|	op_jump_reg
				|	op_beqz
				|	op_bnez
				|	op_halt
				|	op_rdctl
				|	op_wrctl
				|	op_rfi
				|	data
				|	align
				;


op_three_reg	:	TOK_MNEMONIC TOK_REG ',' TOK_REG ',' TOK_REG
					{
						int opcode = lookup_opcode($1, 0);
						if (opcode == -1)
						{
							yyerror("invalidate addressing mode");
							YYABORT;
						}
						else
							emit_r(opcode, $2, $4, $6);
					}
				;

op_immediate 	:	TOK_MNEMONIC TOK_REG ',' TOK_REG ',' expr
					{
						int opcode = lookup_opcode($1, 2);
						if (opcode == -1)
						{
							yyerror("invalidate addressing mode");
							YYABORT;
						}
						else
						{
							if ($6 & 0xffff0000)
							{
								yyerror("immediate constant out of range");
								YYABORT;
							}
							else
								emit_i(opcode, $2, $4, $6);
						}
					}
				;

op_move			:	TOK_MOVE TOK_REG ',' TOK_REG
					{
						// pseudo op.  Translate to add r1, r2, 0
						emit_i(1, $2, $4, 0);
					}

op_load_store	:	TOK_MNEMONIC TOK_REG ',' TOK_LITERAL '(' TOK_REG ')'
					{
						int opcode = lookup_opcode($1, 1);
						if (opcode == -1)
						{
							yyerror("invalid addressing mode");
							YYABORT;
						}
						else
							emit_i(opcode, $2, $6, $4);
					}
				|	TOK_MNEMONIC TOK_REG ',' '(' TOK_REG ')'
					{
						int opcode = lookup_opcode($1, 1);
						if (opcode == -1)
						{
							yyerror("invalid addressing mode");
							YYABORT;
						}
						else
							emit_i(opcode, $2, $5, 0);
					}
				|	TOK_MNEMONIC TOK_REG ',' '=' TOK_LABEL
					{
						// PC relative load
						int opcode = lookup_opcode($1, 1);	// Is this load/store?
						if (opcode == -1)
							opcode = lookup_opcode($1, 2);	// No, is it load effective address?

						if (opcode == -1)
						{
							yyerror("invalid addressing mode");
							YYABORT;
						}
						else
						{
							$5->type = SYM_LABEL;
							add_fixup_by_name($5->name, FIXUP_RELATIVE_I);
							emit_i(opcode, $2, 31, 0);
						}
					}
				;

op_jump			:	TOK_JUMP TOK_LABEL
					{
						$2->type = SYM_LABEL;
						add_fixup_by_name($2->name, FIXUP_RELATIVE_I);

						// pseudo instruction: convert to add pc, pc, offset
						emit_i(1, 31, 31, 0);
					}
				;

op_jump_reg		:	TOK_JUMP '(' TOK_REG ')'
					{
						// pseudo instruction: convert to add pc, rn, 0
						emit_r(1, 31, $3, 0);
					}
				;

op_beqz			:	TOK_BEQZ TOK_REG ',' TOK_LABEL
					{
						$4->type = SYM_LABEL;
						add_fixup_by_name($4->name, FIXUP_RELATIVE_I);
						emit_i(48, $2, 0, 0);
					}
				;

op_bnez			:	TOK_BNEZ TOK_REG ',' TOK_LABEL
					{	
						$4->type = SYM_LABEL;
						add_fixup_by_name($4->name, FIXUP_RELATIVE_I);
						emit_i(49, $2, 0, 0);
					}
				;

op_call			:	TOK_CALL TOK_LABEL
					{
						$2->type = SYM_LABEL;
						add_fixup_by_name($2->name, FIXUP_ABSOLUTE_J);
						emit_j(50, 0);
					}
				;

op_call_reg		:	TOK_CALL '(' TOK_REG ')'
					{
						emit_r(51, 0, $3, 0);
					}
				;


op_halt			:	TOK_HALT
					{
						emit_r(62, 0, 0, 0);
					}
				;

op_rdctl		:	TOK_RDCTL TOK_REG ',' TOK_CONTROL_REG
					{
						emit_r(52, $2, $4, 0);
					}
				;

op_wrctl		:	TOK_WRCTL TOK_CONTROL_REG ',' TOK_REG
					{
						emit_r(53, $2, $4, 0);
					}
				;

op_nop			:	TOK_NOP
					{
						emit_r(63, 0, 0, 0);
					}
				;

op_rfi			:	TOK_RFI
					{
						emit_r(56, 0, 0, 0);
					}
				;

expr			:	expr '+' expr
					{
						$$ = $1 + $3;
					}
				|	expr '-' expr
					{
						$$ = $1 - $3;
					}
				|	expr '*' expr
					{
						$$ = $1 * $3;
					}
				|	expr '/' expr
					{
						$$ = $1 / $3;
					}
				|	'(' expr ')'
					{
						$$ = $2;
					}
				|	'~' expr
					{
						$$ = ~$2;
					}
				|	expr '&' expr
					{
						$$ = $1 & $3;
					}
				|	expr '|' expr
					{
						$$ = $1 | $3;
					}
				|	expr '^' expr
					{
						$$ = $1 ^ $3;
					}
				|	expr TOK_LSHIFT expr
					{
						$$ = $1 << $3;
					}
				|	expr TOK_RSHIFT expr
					{
						$$ = $1 >> $3;
					}
				|	TOK_CONSTANT
					{
						$$ = $1->value;
					}
				|	TOK_LITERAL
					{
						$$ = $1;
					}
				|	'.'
					{
						$$ = get_pc();
					}
				;


data			:	TOK_DB byte_value_list
				|	TOK_DH half_value_list
				|	TOK_DL long_value_list
				|	TOK_DS TOK_STRING
					{
						emit_string($2);
					}
				|	space
				;

byte_value_list	:	byte_value_list ',' expr
					{
						emit_byte($3);
					}
				|	expr
					{	
						emit_byte($1);
					}
				;

half_value_list	:	half_value_list ',' expr
					{
						emit_half_word($3);
					}
				|	expr
					{		
						emit_half_word($1);
					}
				;

long_value		:	expr
					{
						// Emit a constant immediately
						emit_long($1);
					}
				|	TOK_LABEL
					{
						add_fixup($1, FIXUP_ABSOLUTE_DATA);
						emit_long(0);
					}
				;

long_value_list	:	long_value_list ',' long_value
				|	long_value
				;

space			:	TOK_SPACE expr
					{
						emit_space($2, 0);
					}
				|	TOK_SPACE expr ',' expr
					{
						emit_space($2, $4);
					}
				;

align			:	TOK_ALIGN expr
					{
						align_pc($2);
					}
				;

%%

#include "_scan.c"

typedef struct IncludeStackEntry IncludeStackEntry;

struct IncludeStackEntry
{
	IncludeStackEntry *next;
	FILE *file;
	int lineNum;
};

static IncludeStackEntry *includeStack;

static int open_include_file(const char *name)
{
	IncludeStackEntry *entry;
	FILE *file;

	file = fopen(name, "rb");
	if (file == NULL)
	{
		yyerror("Cannot open include file");
		return -1;
	}
	
	entry = (IncludeStackEntry*) malloc(sizeof(IncludeStackEntry));
	entry->file = yyin;
	entry->lineNum = line_num;
	entry->next = includeStack;
	includeStack = entry;

	yyin = file;
	line_num = 1;
	return 0;
}

int yywrap(void)
{
	IncludeStackEntry *entry;
	
	if (includeStack == NULL)
		return 1;

	entry = includeStack;
	includeStack = includeStack->next;
		
	fclose(yyin);
	yyin = entry->file;
	line_num = entry->lineNum;
	free(entry);
	
	return 0;
}

int main(int argc, const char *argv[])
{
	FILE *input_file;

	if (argc != 3)
	{
		printf("assemble <input_file> <output_file>\n");
		return 1;
	}

	input_file = fopen(argv[1], "rb");
	if (input_file == NULL)
	{
		perror("opening file");
		return 1;
	}

	if (open_output_file(argv[2]) < 0)
	{
		perror("opening output file");
		return 1;
	}

	line_num = 1;
	yyin = input_file;
	if (yyparse() != 0)
		return 1;

	fclose(input_file);

	if (perform_fixups() < 0)
		return 1;

	close_output_file();

	print_fixup_list();
	print_sym_table();

	return 0;
}
