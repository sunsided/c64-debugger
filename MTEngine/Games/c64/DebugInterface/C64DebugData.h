#ifndef _CC64DEBUGDATA_H_
#define _CC64DEBUGDATA_H_

#include "SYS_Defs.h"
#include "C64DebugTypes.h"
#include "SYS_Main.h"

#define C64_ADDR_BREAKPOINT_ACTION_STOP				BV01
#define C64_ADDR_BREAKPOINT_ACTION_SET_BACKGROUND	BV02

class C64AddrBreakpoint
{
public:
	C64AddrBreakpoint(uint16 addr);
	uint16 addr;
	
	u32 actions;
	byte data;
};

class C64MemoryBreakpoint : public C64AddrBreakpoint
{
public:
	C64MemoryBreakpoint(uint16 addr, uint8 breakpointType, int value);
	int value;
	uint8 breakpointType;
};




#endif