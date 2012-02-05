#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "symbol_table.h"

#define HASH_SIZE 37

static symbol *symbol_table[HASH_SIZE];

static int hash(const char *str)
{
	unsigned int hash = 1;
	const unsigned char *c;

	for (c = (const unsigned char*) str; *c; c++)
		hash = (hash << 27) ^ (hash >> 8) ^ *c;

	return hash & 0x7fffffff;
}

symbol *find_symbol(const char *name)
{
	int bucket = hash(name) % HASH_SIZE;
	symbol *sym;

	for (sym = symbol_table[bucket]; sym != NULL; sym = sym->next)
	{
		if (strcmp(sym->name, name) == 0)
			return sym;
	}

	return NULL;
}

symbol *add_symbol(const char *name, symbol_type type, int value)
{
	int bucket = hash(name) % HASH_SIZE;
	symbol *sym;

	sym = (symbol*) malloc(sizeof(symbol) + strlen(name));
	strcpy(sym->name, name);
	sym->value = value;
	sym->next = symbol_table[bucket];
	sym->type = type;
	if (sym->type == SYM_CONSTANT)
		sym->defined = 1;
	else
		sym->defined = 0;

	symbol_table[bucket] = sym;

	return sym;
}

void print_sym_table(void)
{
	int index;
	symbol *sym;

	printf("Symbol Table:\n");
	for (index = 0; index < HASH_SIZE; index++)
	{
		for (sym = symbol_table[index]; sym != NULL; sym = sym->next)
			printf("%08x %15s\n", sym->value, sym->name);
	}
}
