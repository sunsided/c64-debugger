#ifndef _CC64DEBUGDATA_H_
#define _CC64DEBUGDATA_H_

#include "SYS_Defs.h"
#include "C64DebugTypes.h"

class C64AddrBreakpoint
{
public:
	C64AddrBreakpoint(uint16 addr);
	uint16 addr;
};

class C64MemoryBreakpoint : public C64AddrBreakpoint
{
public:
	C64MemoryBreakpoint(uint16 addr, uint8 breakpointType, int value);
	int value;
	uint8 breakpointType;
};




#endif