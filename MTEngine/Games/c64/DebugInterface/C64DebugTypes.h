#ifndef _C64DEBUGTYPES_H_
#define _C64DEBUGTYPES_H_

#include "SYS_Types.h"

enum c64EmulatorType
{
	C64_EMULATOR_VICE = 1
};

#define C64_DEBUG_RUNNING				0x00
#define C64_DEBUG_PAUSED				0x80
#define C64_DEBUG_RUN_ONE_CYCLE			0x81
#define C64_DEBUG_RUN_ONE_INSTRUCTION	0x82
#define C64_DEBUG_SHUTDOWN				0xFF

#define C64_NUM_DRIVES 4

#define C64_MACHINE_UNKNOWN	0
#define C64_MACHINE_PAL		1
#define C64_MACHINE_NTSC	2

enum c64MemoryBreakpointType
{
	C64_MEMORY_BREAKPOINT_EQUAL = 0,
	C64_MEMORY_BREAKPOINT_NOT_EQUAL,
	C64_MEMORY_BREAKPOINT_LESS,
	C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL,
	C64_MEMORY_BREAKPOINT_GREATER,
	C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL,
	
	C64_MEMORY_BREAKPOINT_LAST
};

struct C64StateCPU
{
	uint8 a, x, y;
	uint8 processorFlags, sp;
	uint16 pc;
	//	uint8 intr[4];		// Interrupt state
	uint16 lastValidPC;
	uint8 instructionCycle;
	
	uint8 memory0001;
};

struct C64StateVIC
{
	int rasterY;
	int rasterX;
	int cycle;
};


struct C64StateDrive1541
{
	int headTrackPosition;
};

struct C64StateCartridge
{
	uint8 exrom;
	uint8 game;
};


#endif

