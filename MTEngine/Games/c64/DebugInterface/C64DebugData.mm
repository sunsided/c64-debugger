#include "C64DebugData.h"
#include "SYS_Defs.h"

C64AddrBreakpoint::C64AddrBreakpoint(uint16 addr)
{
	this->addr = addr;
}

C64MemoryBreakpoint::C64MemoryBreakpoint(uint16 addr, uint8 breakpointType, int value)
: C64AddrBreakpoint(addr)
{
	this->value = value;
	this->breakpointType = breakpointType;
}
