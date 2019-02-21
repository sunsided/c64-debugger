#ifndef _DEBUGTYPES_H_
#define _DEBUGTYPES_H_

#include "SYS_Types.h"

enum EmulatorType
{
	EMULATOR_TYPE_UNKNOWN = 0,
	EMULATOR_TYPE_C64_VICE = 1,
	EMULATOR_TYPE_ATARI800 = 2,
	EMULATOR_TYPE_NESTOPIA = 3
};

#define DEBUGGER_MODE_RUNNING				0x00
#define DEBUGGER_MODE_PAUSED				0x80
#define DEBUGGER_MODE_RUN_ONE_CYCLE			0x81
#define DEBUGGER_MODE_RUN_ONE_INSTRUCTION	0x82
#define DEBUGGER_MODE_SHUTDOWN				0xFF

#define MACHINE_TYPE_UNKNOWN	0
#define MACHINE_TYPE_PAL		1
#define MACHINE_TYPE_NTSC	2
#define MACHINE_TYPE_LOADING_SNAPSHOT	100

#define JOYPAD_SELECT	0x80
#define JOYPAD_START	0x40
#define JOYPAD_FIRE_B	0x20
#define JOYPAD_FIRE		0x10
#define JOYPAD_E		0x08
#define JOYPAD_W		0x04
#define JOYPAD_S		0x02
#define JOYPAD_N		0x01
#define JOYPAD_IDLE		0x00
#define JOYPAD_SW   (JOYPAD_S | JOYPAD_W)
#define JOYPAD_SE   (JOYPAD_S | JOYPAD_E)
#define JOYPAD_NW   (JOYPAD_N | JOYPAD_W)
#define JOYPAD_NE   (JOYPAD_N | JOYPAD_E)


enum MemoryBreakpointType
{
	MEMORY_BREAKPOINT_EQUAL = 0,
	MEMORY_BREAKPOINT_NOT_EQUAL,
	MEMORY_BREAKPOINT_LESS,
	MEMORY_BREAKPOINT_LESS_OR_EQUAL,
	MEMORY_BREAKPOINT_GREATER,
	MEMORY_BREAKPOINT_GREATER_OR_EQUAL,
	
	MEMORY_BREAKPOINT_LAST
};

// below are all ANSI C definitions that belong to a proper *.h file from the interface, keeping here for now due to inconsistency:

//
// C64 Debugger interface definitions go below:

#define C64_NUM_DRIVES 4

enum c64ViciiRecordMode
{
	C64D_VICII_RECORD_MODE_NONE	= 0,
	C64D_VICII_RECORD_MODE_EVERY_LINE,
	C64D_VICII_RECORD_MODE_EVERY_CYCLE
	
};

enum c64PictureMode
{
	C64_PICTURE_MODE_TEXT_HIRES=1,
	C64_PICTURE_MODE_TEXT_MULTI,
	C64_PICTURE_MODE_BITMAP_HIRES,
	C64_PICTURE_MODE_BITMAP_MULTI
};

enum c64CanvasType
{
	C64_CANVAS_TYPE_BLANK	= 0,
	C64_CANVAS_TYPE_BITMAP	= 1,
	C64_CANVAS_TYPE_TEXT	= 2,
};

enum
{
	PAINT_RESULT_ERROR			= 0,
	PAINT_RESULT_OUTSIDE		= 1,
	PAINT_RESULT_BLOCKED		= 2,
	PAINT_RESULT_OK				= 10,
	PAINT_RESULT_REPLACED_COLOR	= 11,
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
	int raster_line;
	int raster_cycle;
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

