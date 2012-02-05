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
