#ifndef _CDEBUGGERBREAKPOINTS_H_
#define _CDEBUGGERBREAKPOINTS_H_

#include "SYS_Defs.h"
#include "DebuggerDefs.h"
#include "SYS_Main.h"

#define ADDR_BREAKPOINT_ACTION_STOP				BV01
#define ADDR_BREAKPOINT_ACTION_SET_BACKGROUND	BV02

class CAddrBreakpoint
{
public:
	CAddrBreakpoint(uint16 addr);
	uint16 addr;
	
	u32 actions;
	byte data;
};

class CMemoryBreakpoint : public CAddrBreakpoint
{
public:
	CMemoryBreakpoint(uint16 addr, uint8 breakpointType, int value);
	int value;
	uint8 breakpointType;
};




#endif
