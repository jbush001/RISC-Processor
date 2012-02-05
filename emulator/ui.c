#include <signal.h>
#include <string.h>
#include <curses.h>
#include "disasm.h"
#include "emulator.h"

#define REGISTER_WINDOW_WIDTH 32
#define REGISTER_WINDOW_HEIGHT 22

static int firstAddrInDisasm;
static int disassemblyWindowHeight;
static WINDOW *disassemblyWindow;
static WINDOW *registerWindow;
static WINDOW *consoleWindow;
static int oldRegisterState[NUM_REGISTERS];
static volatile int interrupted;

void drawRegisterWindow(WINDOW *window, processor_state *state)
{
	int i;

	wclear(window);
	wborder(window, 0, 0, 0, 0, 0, 0, 0, 0);
	for (i = 0; i < NUM_REGISTERS; i++)
	{
		if (state->r[i] != oldRegisterState[i])
			wcolor_set(window, 2, NULL);
	
		mvwprintw(window, i / 2 + 1, 1 + (i % 2) * 15 + (i < 10), "r%d: %08x", i, state->r[i]);
		if (state->r[i] != oldRegisterState[i])
			wcolor_set(window, 1, NULL);
	}
	
	wrefresh(window);
	memcpy(oldRegisterState, state->r, sizeof(int) * NUM_REGISTERS);

}

void drawDisassemblyWindow(WINDOW *window, processor_state *state)
{
	int row;
	char buf[256];
	int inst;
	int address;
	
	wclear(window);
	wborder(window, 0, 0, 0, 0, 0, 0, 0, 0);
	for (row = 0; row < disassemblyWindowHeight - 2; row++)
	{
		address = firstAddrInDisasm + row * 4;
		inst = read_memory_mapped(state, address, 4);
		print_instruction(buf, sizeof(buf), address, inst);
		if (address == state->r[31])
			wattron(window, WA_REVERSE);

		mvwprintw(window, row + 1, 1, "%s", buf);
		if (address == state->r[31])
			wattroff(window, WA_REVERSE);
	}

	wrefresh(window);
}

void redrawWindows(processor_state *state, WINDOW *registerWindow, WINDOW *disassemblyWindow)
{
	drawRegisterWindow(registerWindow, state);
	if (state->r[31] < firstAddrInDisasm || state->r[31] >= firstAddrInDisasm + (disassemblyWindowHeight * 4) - 8)
	{
		firstAddrInDisasm = state->r[31] - (disassemblyWindowHeight * 4) + (disassemblyWindowHeight / 2 * 4);
		if (firstAddrInDisasm < 0)
			firstAddrInDisasm = 0;
	}
	
	drawDisassemblyWindow(disassemblyWindow, state);
}

void writeConsole(char c)
{
	waddch(consoleWindow, c);
	wrefresh(consoleWindow);
}

void handleInterrupt()
{
	interrupted = 1;
}

void runDebugger(processor_state *state)
{	
	WINDOW *consoleBorder;
	WINDOW *mainWindow;
	int width, height;
	int finished = 0;
	struct sigaction action;

	action.sa_handler = handleInterrupt;
	action.sa_mask = 0;
	action.sa_flags = 0;
	action.sa_sigaction = 0;
	
	sigaction(SIGINT, &action, NULL);

	state->writeConsoleCallback = writeConsole;

	mainWindow = initscr();
	start_color();
	init_pair(1, COLOR_WHITE, COLOR_BLACK);
	init_pair(2, COLOR_RED, COLOR_BLACK );

	getmaxyx(mainWindow, height, width);

	disassemblyWindowHeight = height;
	
	registerWindow = subwin(mainWindow, REGISTER_WINDOW_HEIGHT, REGISTER_WINDOW_WIDTH, 0, 0);
	disassemblyWindow = subwin(mainWindow, disassemblyWindowHeight, width - REGISTER_WINDOW_WIDTH - 1, 0, 
		REGISTER_WINDOW_WIDTH + 1);
	consoleBorder = subwin(mainWindow, height - REGISTER_WINDOW_HEIGHT, REGISTER_WINDOW_WIDTH, 
		REGISTER_WINDOW_HEIGHT, 0);
	wborder(consoleBorder, 0, 0, 0, 0, 0, 0, 0, 0);
	wrefresh(consoleBorder);
	consoleWindow = derwin(consoleBorder, height - REGISTER_WINDOW_HEIGHT - 2, REGISTER_WINDOW_WIDTH - 2, 1, 1);
	scrollok(consoleWindow, TRUE);

	wcolor_set(mainWindow, 1, NULL);
	wcolor_set(registerWindow, 1, NULL);
	wcolor_set(disassemblyWindow, 1, NULL);
	wcolor_set(consoleWindow, 1, NULL);

	cbreak();
	noecho();

	redrawWindows(state, registerWindow, disassemblyWindow);

	while (!finished)
	{
		interrupted = 0;
		char d = getch();
		switch (d)
		{
			case 'q':
				finished = 1;
				break;
				
			case 's':
				do_instruction(state);
				redrawWindows(state, registerWindow, disassemblyWindow);
				break;
				
			case 'r':
				while (!state->halted && !interrupted)
					do_instruction(state);
					
				redrawWindows(state, registerWindow, disassemblyWindow);
				break;
		}
	}

	endwin();
}
