#!/bin/sh

#flex scan.l
#bison assemble.y
#gcc assemble.tab.c -o asm
#gcc disasm.c -o disasm
gcc emulator.c ui.c disasm.c main.c -lcurses -o emulate
