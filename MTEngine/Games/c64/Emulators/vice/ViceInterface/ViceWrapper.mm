
extern "C" {
#include "ViceWrapper.h"
#include "vice.h"
#include "main.h"
#include "viciitypes.h"
#include "vsync.h"
#include "raster.h"
#include "videoarch.h"
}

#include "C64DebugInterfaceVice.h"
#include "CViceAudioChannel.h"
#include "VID_Main.h"
#include "SND_Main.h"
#include "SYS_Main.h"
#include "SYS_Types.h"
#include "SYS_CommandLine.h"
#include "CGuiMain.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"

volatile int c64d_debug_mode = C64_DEBUG_RUNNING;

uint16 viceCurrentC64PC;
uint16 viceCurrentDiskPC[4];

void ViceWrapperInit(C64DebugInterfaceVice *debugInterface)
{
	LOGM("ViceWrapperInit");
	
	debugInterfaceVice = debugInterface;
	
	viceCurrentC64PC = 0;
	viceCurrentDiskPC[0] = 0;
	viceCurrentDiskPC[1] = 0;
	viceCurrentDiskPC[2] = 0;
	viceCurrentDiskPC[3] = 0;
}

void c64d_sound_init()
{
	if (debugInterfaceVice->viceAudioChannel == NULL)
	{
		debugInterfaceVice->viceAudioChannel = new CViceAudioChannel(debugInterfaceVice);
		SND_AddChannel(debugInterfaceVice->viceAudioChannel);
	}
	
	debugInterfaceVice->viceAudioChannel->bypass = false;
}

void c64d_sound_pause()
{
	debugInterfaceVice->viceAudioChannel->bypass = true;
}

void c64d_sound_resume()
{
	debugInterfaceVice->viceAudioChannel->bypass = false;
}

void mt_SYS_FatalExit(char *text)
{
	SYS_FatalExit(text);
}

long mt_SYS_GetCurrentTimeInMillis()
{
//	LOGD("mt_SYS_GetCurrentTimeInMillis");
	return SYS_GetCurrentTimeInMillis();
}

void mt_SYS_Sleep(long milliseconds)
{
	//LOGD("mt_SYS_Sleep: %d", milliseconds);
	SYS_Sleep(milliseconds);
}

// TODO: memory read breakpoints
void c64d_mark_c64_cell_read(uint16 addr)
{
	//debugInterfaceVice->MarkC64CellRead(addr);
	viewC64->viewC64MemoryMap->CellRead(addr);
}

void c64d_mark_c64_cell_write(uint16 addr, uint8 value)
{
//	debugInterfaceVice->MarkC64CellWrite(addr, value);
	viewC64->viewC64MemoryMap->CellWrite(addr, value);
	
	if (debugInterfaceVice->breakOnC64Memory)
	{
		debugInterfaceVice->LockMutex();
		
		std::map<uint16, C64MemoryBreakpoint *>::iterator it = debugInterfaceVice->breakpointsC64Memory.find(addr);
		if (it != debugInterfaceVice->breakpointsC64Memory.end())
		{
			C64MemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
		}
		
		debugInterfaceVice->UnlockMutex();
	}
}

void c64d_mark_c64_cell_execute(uint16 addr, uint8 opcode)
{
	viewC64->viewC64MemoryMap->CellExecute(addr, opcode);
}

void c64d_mark_disk_cell_read(uint16 addr)
{
//	LOGD("c64d_mark_disk_cell_read: %04x", addr);
//	debugInterfaceVice->MarkDrive1541CellRead(addr);
	viewC64->viewDrive1541MemoryMap->CellRead(addr);
}

void c64d_mark_disk_cell_write(uint16 addr, uint8 value)
{
//	debugInterfaceVice->MarkDrive1541CellWrite(addr, value);
	viewC64->viewDrive1541MemoryMap->CellWrite(addr, value);
	
	if (debugInterfaceVice->breakOnDrive1541Memory)
	{
		debugInterfaceVice->LockMutex();
		
		std::map<uint16, C64MemoryBreakpoint *>::iterator it = debugInterfaceVice->breakpointsDrive1541Memory.find(addr);
		if (it != debugInterfaceVice->breakpointsDrive1541Memory.end())
		{
			C64MemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
				}
			}
		}
		
		debugInterfaceVice->UnlockMutex();
	}
}

void c64d_mark_disk_cell_execute(uint16 addr, uint8 opcode)
{
	//LOGD("c64d_mark_disk_cell_execute: %04x %02x", addr, opcode);
	viewC64->viewDrive1541MemoryMap->CellExecute(addr, opcode);
}


void c64d_display_speed(float speed, float frame_rate)
{
	debugInterfaceVice->emulationSpeed = speed;
	debugInterfaceVice->emulationFrameRate = frame_rate;
}

void c64d_display_drive_led(int drive_number, unsigned int pwm1, unsigned int led_pwm2)
{
	//LOGD("c64d_display_drive_led: %d: %d %d", drive_number, pwm1, led_pwm2);
	
	debugInterfaceVice->ledState[drive_number] = (float)pwm1 / 1000.0f;
}

void c64d_show_message(char *message)
{
	guiMain->ShowMessage(message);
}

// C64 color palette (more realistic looking colors)
const uint8 c64d_palette_red[16] = {
	0x00, 0xff, 0x99, 0x00, 0xcc, 0x44, 0x11, 0xff, 0xaa, 0x66, 0xff, 0x40, 0x80, 0x66, 0x77, 0xc0
};

const uint8 c64d_palette_green[16] = {
	0x00, 0xff, 0x00, 0xff, 0x00, 0xcc, 0x00, 0xff, 0x55, 0x33, 0x66, 0x40, 0x80, 0xff, 0x77, 0xc0
};

const uint8 c64d_palette_blue[16] = {
	0x00, 0xff, 0x00, 0xcc, 0xcc, 0x44, 0x99, 0x00, 0x00, 0x00, 0x66, 0x40, 0x80, 0x66, 0xff, 0xc0
};

void c64d_clear_screen()
{
	debugInterfaceVice->LockRenderScreenMutex();
	
	uint8 *destScreenPtr = (uint8 *)debugInterfaceVice->screen->resultData;
	
	for (int y = 0; y < 512; y++)
	{
		for (int x = 0; x < 512; x++)
		{
			*destScreenPtr++ = 0x00;
			*destScreenPtr++ = 0x00;
			*destScreenPtr++ = 0x00;
			*destScreenPtr++ = 0xFF;
		}
	}
	
	uint8 *screenBuffer = vicii.raster.canvas->draw_buffer->draw_buffer;
	uint8 *srcScreenPtr = screenBuffer;
	
	for (int y = 0; y < 100; y++)
	{
		for (int x = 0; x < 384; x++)
		{
			*srcScreenPtr++ = 0x00;
		}
	}
	

	
	debugInterfaceVice->UnlockRenderScreenMutex();

}

void c64d_refresh_screen()
{
	//LOGD("c64d_refresh_screen");
	//raster_t //vicii.raster
	//struct video_canvas_s //raster->canvas
	//canvas->draw_buffer->draw_buffer

	uint8 *screenBuffer = vicii.raster.canvas->draw_buffer->draw_buffer;
	
	debugInterfaceVice->LockRenderScreenMutex();
	
	// dest screen width is 512
	// src  screen width is 384
	
	// skip 16 top lines
	uint8 *srcScreenPtr = screenBuffer + (16*384);
	uint8 *destScreenPtr = (uint8 *)debugInterfaceVice->screen->resultData;
	
	int screenHeight = debugInterfaceVice->GetC64ScreenSizeY();
	for (int y = 0; y < screenHeight; y++)
	{
		for (int x = 0; x < 384; x++)
		{
			byte v = *srcScreenPtr++;
			*destScreenPtr++ = c64d_palette_red[v];
			*destScreenPtr++ = c64d_palette_green[v];
			*destScreenPtr++ = c64d_palette_blue[v];
			*destScreenPtr++ = 255;
		}
		
		destScreenPtr += (512-384)*4;
	}
	
	debugInterfaceVice->UnlockRenderScreenMutex();

}

// this is called when debug is paused to refresh only part of screen
void c64d_refresh_previous_lines()
{
//	LOGD("c64d_refresh_previous_lines");
	debugInterfaceVice->LockRenderScreenMutex();
	
	int rasterY = vicii.raster_line - 16;
	
	rasterY--;
	
	// draw previous completed raster lines
	uint8 *screenBuffer = vicii.raster.canvas->draw_buffer->draw_buffer;
	
//	LOGD("..... rasterY=%x", rasterY);
	
	for (int x = 0; x < 384; x++)
	{
		for (int y = 0; y < rasterY; y++)
		{
			int offset = x + ((y+16) * 384);
			
			byte v = screenBuffer[offset];
			
			//LOGD("r=%d g=%d b=%d", r, g, b);
			
			debugInterfaceVice->screen->SetPixelResultRGBA(x, y, c64d_palette_red[v], c64d_palette_green[v], c64d_palette_blue[v], 255);
		}
	}
	
	debugInterfaceVice->UnlockRenderScreenMutex();
}

void c64d_refresh_dbuf()
{
//	return;
//	LOGD("c64d_refresh_dbuf");
	int rasterY = vicii.raster_line - 16;

	if (rasterY < 0 || rasterY > debugInterfaceVice->GetC64ScreenSizeY())
	{
		return;
	}

	if (vicii.raster_cycle > 61)
		return;
	
	if (vicii.raster_cycle == 0 && vicii.dbuf_offset == 504)
		return;
	
	debugInterfaceVice->LockRenderScreenMutex();
	
//	LOGD(".... rasterY=%x vicii.dbuf_offset + 8=%d", rasterY, (vicii.dbuf_offset + 8));
//	LOGD(".... rasterX=%x raster_cycle=%d", vicii.raster_cycle*8, vicii.raster_cycle);

	
	int maxX = 0;
	
	for (int l = 0; l < vicii.dbuf_offset; l++)	//+8
	{
		int x = l - 104;
		if (x < 0 || x > 383)
			continue;
		
		if (maxX < x)
			maxX = x;
		
		byte v = vicii.dbuf[l];
		debugInterfaceVice->screen->SetPixelResultRGBA(x, rasterY, c64d_palette_red[v], c64d_palette_green[v], c64d_palette_blue[v], 255);
	}
	
//	LOGD("........ maxX=%d", maxX);

	
	debugInterfaceVice->UnlockRenderScreenMutex();
}

int c64d_is_debug_on_c64()
{
	if (debugInterfaceVice->debugOnC64)
		return 1;
	
	return 0;
}

int c64d_is_debug_on_drive1541()
{
	if (debugInterfaceVice->debugOnDrive1541)
		return 1;
	
	return 0;
}

extern "C" {
	BYTE c64d_peek_c64(WORD addr);
	void c64d_mem_write_c64_no_mark(unsigned int addr, unsigned char value);
	void c64d_get_vic_simple_state(struct C64StateVIC *simpleStateVic);
};

void c64d_c64_check_pc_breakpoint(uint16 pc)
{
	uint8 val;

	if ((int)pc == debugInterfaceVice->temporaryC64BreakpointPC)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
		debugInterfaceVice->temporaryC64BreakpointPC = -1;
	}
	else if (debugInterfaceVice->breakOnC64PC)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, C64AddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsC64PC.find(pc);
		if (it != debugInterfaceVice->breakpointsC64PC.end())
		{
			C64AddrBreakpoint *addrBreakpoint = it->second;
			
			if (IS_SET(addrBreakpoint->actions, C64_ADDR_BREAKPOINT_ACTION_SET_BACKGROUND))
			{
				// VIC can't modify two registers at once
				
				C64StateVIC vicState;
				c64d_get_vic_simple_state(&vicState);

				// outside screen (in borders)?
				if (vicState.rasterY < 0x32 || vicState.rasterY > 0xFA
					|| vicState.rasterX < 0x88 || vicState.rasterX > 0x1C7)
				{
					c64d_mem_write_c64_no_mark(0xD021, addrBreakpoint->data);
					
					// this will be the real write in this VIC cycle:
					c64d_mem_write_c64_no_mark(0xD020, addrBreakpoint->data);
				}
				else
				{
					c64d_mem_write_c64_no_mark(0xD020, addrBreakpoint->data);
					
					// this will be the real write in this VIC cycle:
					c64d_mem_write_c64_no_mark(0xD021, addrBreakpoint->data);
				}
				
				// alternatively
				// val = c64d_peek_c64(0xD021) + 1;
				// if (val == 0x10)
				//		val = 0x00;
				
			}

			if (IS_SET(addrBreakpoint->actions, C64_ADDR_BREAKPOINT_ACTION_STOP))
			{
				debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
			}
		}
		debugInterfaceVice->UnlockMutex();
	}
}

void c64d_drive1541_check_pc_breakpoint(uint16 pc)
{
	if ((int)pc == debugInterfaceVice->temporaryDrive1541BreakpointPC)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
		debugInterfaceVice->temporaryDrive1541BreakpointPC = -1;
		viceCurrentDiskPC[0] = pc;
	}
	else if (debugInterfaceVice->breakOnDrive1541PC)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, C64AddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsDrive1541PC.find(pc);
		if (it != debugInterfaceVice->breakpointsDrive1541PC.end())
		{
			debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
		}
		debugInterfaceVice->UnlockMutex();
	}
	
}

void c64d_c64_check_raster_breakpoint(uint16 rasterLine)
{
//	LOGD("c64d_c64_check_raster_breakpoint rasterLine=%d", rasterLine);
	if (debugInterfaceVice->breakOnC64Raster)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, C64AddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsC64Raster.find(rasterLine);
		if (it != debugInterfaceVice->breakpointsC64Raster.end())
		{
			debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
			//			TheCPU->lastValidPC = TheCPU->pc;
		}
		debugInterfaceVice->UnlockMutex();
	}
}

int c64d_drive1541_is_checking_irq_breakpoints_enabled()
{
	if (debugInterfaceVice->breakOnDrive1541IrqIEC || debugInterfaceVice->breakOnDrive1541IrqVIA1 || debugInterfaceVice->breakOnDrive1541IrqVIA2)
		return 1;
	
	return 0;
}

void c64d_drive1541_check_irqiec_breakpoint()
{
	if (debugInterfaceVice->breakOnDrive1541IrqIEC)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
	}
}

void c64d_drive1541_check_irqvia1_breakpoint()
{
	if (debugInterfaceVice->breakOnDrive1541IrqVIA1)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
	}
}


void c64d_drive1541_check_irqvia2_breakpoint()
{
	if (debugInterfaceVice->breakOnDrive1541IrqVIA2)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
	}
}


int c64d_c64_is_checking_irq_breakpoints_enabled()
{
	if (debugInterfaceVice->breakOnC64IrqVIC || debugInterfaceVice->breakOnC64IrqCIA || debugInterfaceVice->breakOnC64IrqNMI)
		return 1;
	
	return 0;
}

void c64d_c64_check_irqvic_breakpoint()
{
	if (debugInterfaceVice->breakOnC64IrqVIC)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_RUN_ONE_INSTRUCTION);
	}
}

void c64d_c64_check_irqcia_breakpoint(int ciaNum)
{
	if (debugInterfaceVice->breakOnC64IrqCIA)
	{
		debugInterfaceVice->SetDebugMode(C64_DEBUG_PAUSED);
	}
}

void c64d_debug_pause_check()
{
	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	{
		c64d_refresh_previous_lines();
		c64d_refresh_dbuf();
		
		while (c64d_debug_mode == C64_DEBUG_PAUSED)
		{
			vsync_do_vsync(vicii.raster.canvas, 0, 1);
			//mt_SYS_Sleep(50);
		}
	}
}

////////////

// sid
int c64d_is_receive_channels_data = 0;

void c64d_sid_receive_channels_data(int isOn)
{
	c64d_is_receive_channels_data = isOn;
}

void c64d_sid_channels_data(int v1, int v2, int v3, short mix)
{
//	LOGD("c64d_sid_channels_data: %d %d %d %d", v1, v2, v3, mix);
	
	debugInterfaceVice->AddSIDWaveformData(v1, v2, v3, mix);
}










