#ifndef _CDEBUGGERBREAKPOINTS_H_
#define _CDEBUGGERBREAKPOINTS_H_

#include "SYS_Defs.h"
#include "DebuggerDefs.h"
#include "SYS_Main.h"
#include <map>

#define ADDR_BREAKPOINT_ACTION_STOP				BV01
#define ADDR_BREAKPOINT_ACTION_SET_BACKGROUND	BV02

class CAddrBreakpoint
{
public:
	CAddrBreakpoint(int addr);
	int addr;
	
	u32 actions;
	byte data;
};

class CMemoryBreakpoint : public CAddrBreakpoint
{
public:
	CMemoryBreakpoint(int addr, uint8 breakpointType, int value);
	int value;
	uint8 breakpointType;
};

class CDebuggerAddrBreakpoints
{
public:
	CDebuggerAddrBreakpoints();
	~CDebuggerAddrBreakpoints();

	std::map<int, CAddrBreakpoint *> breakpoints;
	
	virtual void AddBreakpoint(CAddrBreakpoint *addrBreakpoint);
	virtual void DeleteBreakpoint(CAddrBreakpoint *addrBreakpoint);
	virtual void DeleteBreakpoint(int addr);

	virtual CAddrBreakpoint *EvaluateBreakpoint(int addr);
	
	virtual void ClearBreakpoints();
};

class CDebuggerMemoryBreakpoints : public CDebuggerAddrBreakpoints
{
public:
	CDebuggerMemoryBreakpoints();
	~CDebuggerMemoryBreakpoints();

	std::map<int, CMemoryBreakpoint *> breakpoints;
	
	virtual CMemoryBreakpoint *EvaluateBreakpoint(int addr, int value);
};

#endif
