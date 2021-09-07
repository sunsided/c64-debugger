#include "CDebuggerBreakpoints.h"
#include "SYS_Defs.h"

CAddrBreakpoint::CAddrBreakpoint(int addr)
{
	this->addr = addr;
	this->actions = ADDR_BREAKPOINT_ACTION_STOP;
	this->data = 0x00;
}

CMemoryBreakpoint::CMemoryBreakpoint(int addr, uint8 breakpointType, int value)
: CAddrBreakpoint(addr)
{
	this->value = value;
	this->breakpointType = breakpointType;
}

//std::map<int, CMemoryBreakpoint *> memoryBreakpoints;

CDebuggerAddrBreakpoints::CDebuggerAddrBreakpoints()
{
}


void CDebuggerAddrBreakpoints::ClearBreakpoints()
{
	while(!breakpoints.empty())
	{
		std::map<int, CAddrBreakpoint *>::iterator it = breakpoints.begin();
		CAddrBreakpoint *breakpoint = it->second;
		
		breakpoints.erase(it);
		delete breakpoint;
	}
}

CDebuggerMemoryBreakpoints::CDebuggerMemoryBreakpoints()
{
}

void CDebuggerAddrBreakpoints::AddBreakpoint(CAddrBreakpoint *breakpoint)
{
	// check if breakpoint is already in the map and remove it, can be with other addr so we can't use find
//	std::map<int, CAddrBreakpoint *> breakpoints;   auto does not work with this compiler here yet :)
	for (std::map<int, CAddrBreakpoint *>::iterator it = breakpoints.begin(); it != breakpoints.end(); it++)
	{
		CAddrBreakpoint *existingBreakpoint = it->second;
		
		if (existingBreakpoint == breakpoint)
		{
			breakpoints.erase(it);
			break;
		}
	}
	
	// check if there's a breakpoint with the same address and delete it (we are replacing it)
	std::map<int, CAddrBreakpoint *>::iterator it = breakpoints.find(breakpoint->addr);
	if (it != breakpoints.end())
	{
		CAddrBreakpoint *existingBreakpoint = it->second;
		breakpoints.erase(it);
		delete existingBreakpoint;
	}
	
	// add a breakpoint
	breakpoints[breakpoint->addr] = breakpoint;
}

void CDebuggerAddrBreakpoints::DeleteBreakpoint(int addr)
{
	std::map<int, CAddrBreakpoint *>::iterator it = breakpoints.find(addr);
	if (it != breakpoints.end())
	{
		CAddrBreakpoint *breakpoint = it->second;
		breakpoints.erase(it);
		delete breakpoint;
	}
}

void CDebuggerAddrBreakpoints::DeleteBreakpoint(CAddrBreakpoint *breakpoint)
{
	this->DeleteBreakpoint(breakpoint->addr);
}

// TODO: create a tree for condition and parse the condition text
CAddrBreakpoint *CDebuggerAddrBreakpoints::EvaluateBreakpoint(int addr)
{
	std::map<int, CAddrBreakpoint *>::iterator it = breakpoints.find(addr);
	if (it != breakpoints.end())
	{
		CAddrBreakpoint *breakpoint = it->second;
		return breakpoint;
	}
	
	return NULL;
}

CMemoryBreakpoint *CDebuggerMemoryBreakpoints::EvaluateBreakpoint(int addr, int value)
{
	std::map<int, CMemoryBreakpoint *>::iterator it = breakpoints.find(addr);
	if (it != breakpoints.end())
	{
		CMemoryBreakpoint *memoryBreakpoint = it->second;
		
		if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_EQUAL)
		{
			if (value == memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
		else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_NOT_EQUAL)
		{
			if (value != memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
		else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS)
		{
			if (value < memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
		else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS_OR_EQUAL)
		{
			if (value <= memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
		else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER)
		{
			if (value > memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
		else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
		{
			if (value >= memoryBreakpoint->value)
			{
				return memoryBreakpoint;
			}
		}
	}
	
	return NULL;
}

CDebuggerAddrBreakpoints::~CDebuggerAddrBreakpoints()
{
	ClearBreakpoints();
}

CDebuggerMemoryBreakpoints::~CDebuggerMemoryBreakpoints()
{
	ClearBreakpoints();
}
		
