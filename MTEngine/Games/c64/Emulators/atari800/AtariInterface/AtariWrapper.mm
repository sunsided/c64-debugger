extern "C" {
#include "AtariWrapper.h"

volatile int atrd_debug_mode;
}

#include "AtariDebugInterface.h"
#include "CAtariAudioChannel.h"
#include "VID_Main.h"
#include "SYS_Main.h"
#include "SND_Main.h"
#include "SYS_Types.h"
#include "SYS_CommandLine.h"
#include "CGuiMain.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "SND_SoundEngine.h"

extern "C" {
char *ATRD_GetPathForRoms()
{
	// TODO: nasty implementation shortcut. needs to be addressed.
	char *buf = viewC64->ATRD_GetPathForRoms_IMPL();
	LOGD("ATRD_GetPathForRoms: %s", buf);
	return buf;
}
	
}



// TODO: memory read breakpoints
void atrd_mark_atari_cell_read(uint16 addr)
{
	viewC64->viewAtariMemoryMap->CellRead(addr);
}

void atrd_mark_atari_cell_write(uint16 addr, uint8 value)
{
	AtariDebugInterface *debugInterface = debugInterfaceAtari;
	
	viewC64->viewAtariMemoryMap->CellWrite(addr, value, -1, -1, -1); //viceCurrentC64PC, vicii.raster_line, vicii.raster_cycle);
	
	if (debugInterface->breakOnMemory)
	{
		debugInterface->LockMutex();
		
		std::map<uint16, CMemoryBreakpoint *>::iterator it = debugInterface->breakpointsMemory.find(addr);
		if (it != debugInterface->breakpointsMemory.end())
		{
			CMemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
		}
		
		debugInterface->UnlockMutex();
	}
}

void atrd_mark_atari_cell_execute(uint16 addr, uint8 opcode)
{
//	LOGD("atrd_mark_atari_cell_execute: %04x %02x", addr, opcode);
	viewC64->viewAtariMemoryMap->CellExecute(addr, opcode);
}

int atrd_is_debug_on_atari()
{
	if (debugInterfaceAtari->isDebugOn)
		return 1;
	
	return 0;
}

void atrd_check_pc_breakpoint(uint16 pc)
{
//	LOGD("atrd_check_pc_breakpoint: pc=%04x", pc);
	
	AtariDebugInterface *debugInterface = debugInterfaceAtari;

	uint8 val;
	
	if ((int)pc == debugInterface->temporaryBreakpointPC)
	{
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		debugInterface->temporaryBreakpointPC = -1;
	}
	else if (debugInterface->breakOnPC)
	{
		debugInterface->LockMutex();
		std::map<uint16, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsPC.find(pc);
		if (it != debugInterface->breakpointsPC.end())
		{
			CAddrBreakpoint *addrBreakpoint = it->second;
			
			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_SET_BACKGROUND))
			{
				// Not supported
			}
			
			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_STOP))
			{
				debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
			}
		}
		debugInterface->UnlockMutex();
	}
}
//


extern "C" {
int Atari800_GetPC();
}

void atrd_debug_pause_check()
{
//	LOGD("atrd_debug_pause_check, atrd_debug_mode=%d", atrd_debug_mode);
	
	if (atrd_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		//		c64d_refresh_previous_lines();
		//		c64d_refresh_dbuf();
		//		c64d_refresh_cia();
		
		while (atrd_debug_mode == DEBUGGER_MODE_PAUSED)
		{
//			LOGD("atrd_debug_pause_check, waiting... PC=%04x atrd_debug_mode=%d", Atari800_GetPC(), atrd_debug_mode);
			mt_SYS_Sleep(10);
			//			vsync_do_vsync(vicii.raster.canvas, 0, 1);
			//mt_SYS_Sleep(50);
		}
		
//		LOGD("atrd_debug_pause_check: new mode is %d PC=%04x", atrd_debug_mode, Atari800_GetPC());
	}
}

//
int atrd_get_joystick_state(int joystickNum)
{
	return debugInterfaceAtari->joystickState[joystickNum];
}

// sound
void atrd_sound_init()
{
	if (debugInterfaceAtari->audioChannel == NULL)
	{
		debugInterfaceAtari->audioChannel = new CAtariAudioChannel(debugInterfaceAtari);
		SND_AddChannel(debugInterfaceAtari->audioChannel);
	}
	
	debugInterfaceAtari->audioChannel->bypass = false;
}

void atrd_sound_pause()
{
	debugInterfaceAtari->audioChannel->bypass = true;
}

void atrd_sound_resume()
{
	debugInterfaceAtari->audioChannel->bypass = false;
}


void atrd_sound_lock()
{
	gSoundEngine->LockMutex("atrd_sound_lock");
}

void atrd_sound_unlock()
{
	gSoundEngine->UnlockMutex("atrd_sound_unlock");
}


