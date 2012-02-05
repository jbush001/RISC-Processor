#!/bin/sh

if [ ! -d OBJ ];
then
	mkdir OBJ
fi

flex -o OBJ/_scan.c scan.l
bison -o OBJ/_assemble.c assemble.y
gcc -g OBJ/_assemble.c symbol_table.c output_file.c -o asm

