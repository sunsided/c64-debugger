#include "CDebuggerBreakpoints.h"
#include "SYS_Defs.h"

CAddrBreakpoint::CAddrBreakpoint(uint16 addr)
{
	this->addr = addr;
	this->actions = ADDR_BREAKPOINT_ACTION_STOP;
	this->data = 0x00;
}

CMemoryBreakpoint::CMemoryBreakpoint(uint16 addr, uint8 breakpointType, int value)
: CAddrBreakpoint(addr)
{
	this->value = value;
	this->breakpointType = breakpointType;
}
