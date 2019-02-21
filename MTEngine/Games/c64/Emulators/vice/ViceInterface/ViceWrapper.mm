
extern "C" {
#include "ViceWrapper.h"
#include "vice.h"
#include "main.h"
#include "viciitypes.h"
#include "vsync.h"
#include "raster.h"
#include "videoarch.h"
#include "drivetypes.h"
#include "gcr.h"
#include "c64.h"
#include "cia.h"
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
#include "CViewC64StateSID.h"

volatile int c64d_debug_mode = DEBUGGER_MODE_RUNNING;

int c64d_patch_kernal_fast_boot_flag = 0;
int c64d_setting_run_sid_when_in_warp = 1;

int c64d_setting_run_sid_emulation = 1;

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
	if (debugInterfaceVice->audioChannel == NULL)
	{
		debugInterfaceVice->audioChannel = new CViceAudioChannel(debugInterfaceVice);
		SND_AddChannel(debugInterfaceVice->audioChannel);
	}
	
	debugInterfaceVice->audioChannel->bypass = false;
}

void c64d_sound_pause()
{
	debugInterfaceVice->audioChannel->bypass = true;
}

void c64d_sound_resume()
{
	debugInterfaceVice->audioChannel->bypass = false;
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
	
	viewC64->viewC64MemoryMap->CellWrite(addr, value, viceCurrentC64PC, vicii.raster_line, vicii.raster_cycle);
	
	if (debugInterfaceVice->breakOnMemory)
	{
		debugInterfaceVice->LockMutex();
		
		std::map<uint16, CMemoryBreakpoint *>::iterator it = debugInterfaceVice->breakpointsMemory.find(addr);
		if (it != debugInterfaceVice->breakpointsMemory.end())
		{
			CMemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
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
		
		std::map<uint16, CMemoryBreakpoint *>::iterator it = debugInterfaceVice->breakpointsDrive1541Memory.find(addr);
		if (it != debugInterfaceVice->breakpointsDrive1541Memory.end())
		{
			CMemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
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

// C64 frodo color palette (more realistic looking colors)
uint8 c64d_palette_red[16] = {
	0x00, 0xff, 0x99, 0x00, 0xcc, 0x44, 0x11, 0xff, 0xaa, 0x66, 0xff, 0x40, 0x80, 0x66, 0x77, 0xc0
};

uint8 c64d_palette_green[16] = {
	0x00, 0xff, 0x00, 0xff, 0x00, 0xcc, 0x00, 0xff, 0x55, 0x33, 0x66, 0x40, 0x80, 0xff, 0x77, 0xc0
};

uint8 c64d_palette_blue[16] = {
	0x00, 0xff, 0x00, 0xcc, 0xcc, 0x44, 0x99, 0x00, 0x00, 0x00, 0x66, 0x40, 0x80, 0x66, 0xff, 0xc0
};

float c64d_float_palette_red[16];
float c64d_float_palette_green[16];
float c64d_float_palette_blue[16];

void c64d_set_palette(uint8 *palette)
{
	int j = 0;
	for (int i = 0; i < 16; i++)
	{
		c64d_palette_red[i] = palette[j++];
		c64d_palette_green[i] = palette[j++];
		c64d_palette_blue[i] = palette[j++];
		
		c64d_float_palette_red[i] = (float)c64d_palette_red[i] / 255.0f;
		c64d_float_palette_green[i] = (float)c64d_palette_green[i] / 255.0f;
		c64d_float_palette_blue[i] = (float)c64d_palette_blue[i] / 255.0f;
	}
}

// set VICE-style palette
void c64d_set_palette_vice(uint8 *palette)
{
	int j = 0;
	for (int i = 0; i < 16; i++)
	{
		c64d_palette_red[i] = palette[j++];
		c64d_palette_green[i] = palette[j++];
		c64d_palette_blue[i] = palette[j++];
		j++; // just ignore intensity
		
		c64d_float_palette_red[i] = (float)c64d_palette_red[i] / 255.0f;
		c64d_float_palette_green[i] = (float)c64d_palette_green[i] / 255.0f;
		c64d_float_palette_blue[i] = (float)c64d_palette_blue[i] / 255.0f;
	}
}


void c64d_clear_screen()
{
	debugInterfaceVice->LockRenderScreenMutex();
	
	uint8 *destScreenPtr = (uint8 *)debugInterfaceVice->screenImage->resultData;
	
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
	
	volatile int superSample = debugInterfaceVice->screenSupersampleFactor;
	
	if (superSample == 1)
	{
		// dest screen width is 512
		// src  screen width is 384
		//
		// skip 16 top lines
		uint8 *srcScreenPtr = screenBuffer + (16*384);
		uint8 *destScreenPtr = (uint8 *)debugInterfaceVice->screenImage->resultData;
	
		int screenHeight = debugInterfaceVice->GetScreenSizeY();
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
	}
	else
	{
		//	// dest screen width is 512
		//	// src  screen width is 384
		//
		// skip 16 top lines
		uint8 *srcScreenPtr = screenBuffer + (16*384);
		uint8 *destScreenPtr = (uint8 *)debugInterfaceVice->screenImage->resultData;
		
		int screenHeight = debugInterfaceVice->GetScreenSizeY();
		for (int y = 0; y < screenHeight; y++)
		{
			for (int j = 0; j < superSample; j++)
			{
				uint8 *pScreenPtrSrc = srcScreenPtr;
				uint8 *pScreenPtrDest = destScreenPtr;
				for (int x = 0; x < 384; x++)
				{
					byte v = *pScreenPtrSrc++;
					
					for (int i = 0; i < superSample; i++)
					{
						*pScreenPtrDest++ = c64d_palette_red[v];
						*pScreenPtrDest++ = c64d_palette_green[v];
						*pScreenPtrDest++ = c64d_palette_blue[v];
						*pScreenPtrDest++ = 255;
					}
				}
				
				destScreenPtr += (512)*superSample*4;
			}
			
			srcScreenPtr += 384;
		}
	}
	
	debugInterfaceVice->UnlockRenderScreenMutex();
	
	debugInterfaceVice->DoFrame();
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
			
			for (int i = 0; i < debugInterfaceVice->screenSupersampleFactor; i++)
			{
				for (int j = 0; j < debugInterfaceVice->screenSupersampleFactor; j++)
				{
					debugInterfaceVice->screenImage->SetPixelResultRGBA(x * debugInterfaceVice->screenSupersampleFactor + j,
																   y * debugInterfaceVice->screenSupersampleFactor + i,
																   c64d_palette_red[v], c64d_palette_green[v], c64d_palette_blue[v], 255);
				}
			}
		}
	}
	
	debugInterfaceVice->UnlockRenderScreenMutex();
}

void c64d_refresh_dbuf()
{
//	return;
//	LOGD("c64d_refresh_dbuf");
	int rasterY = vicii.raster_line - 16;

	if (rasterY < 0 || rasterY > debugInterfaceVice->GetScreenSizeY())
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
		
		for (int i = 0; i < debugInterfaceVice->screenSupersampleFactor; i++)
		{
			for (int j = 0; j < debugInterfaceVice->screenSupersampleFactor; j++)
			{
				debugInterfaceVice->screenImage->SetPixelResultRGBA(x * debugInterfaceVice->screenSupersampleFactor + j,
															   rasterY * debugInterfaceVice->screenSupersampleFactor + i,
															   c64d_palette_red[v], c64d_palette_green[v], c64d_palette_blue[v], 255);
			}
		}
	}
	
//	LOGD("........ maxX=%d", maxX);

	
	debugInterfaceVice->UnlockRenderScreenMutex();
}

extern "C" {
	void cia_update_ta(cia_context_t *cia_context, CLOCK rclk);
	void cia_update_tb(cia_context_t *cia_context, CLOCK rclk);
}

void c64d_refresh_cia()
{
//	LOGD("c64d_refresh_cia");
	
	cia_update_ta(machine_context.cia1, *(machine_context.cia1->clk_ptr));
	cia_update_tb(machine_context.cia1, *(machine_context.cia1->clk_ptr));
	
	cia_update_ta(machine_context.cia2, *(machine_context.cia2->clk_ptr));
	cia_update_tb(machine_context.cia2, *(machine_context.cia2->clk_ptr));
}

int c64d_is_debug_on_c64()
{
	if (debugInterfaceVice->isDebugOn)
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

	if ((int)pc == debugInterfaceVice->temporaryBreakpointPC)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
		debugInterfaceVice->temporaryBreakpointPC = -1;
	}
	else if (debugInterfaceVice->breakOnPC)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, CAddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsPC.find(pc);
		if (it != debugInterfaceVice->breakpointsPC.end())
		{
			CAddrBreakpoint *addrBreakpoint = it->second;
			
			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_SET_BACKGROUND))
			{
				// VIC can't modify two registers at once
				
				C64StateVIC vicState;
				c64d_get_vic_simple_state(&vicState);
				
				int rasterX = vicState.raster_cycle*8;
				int rasterY = vicState.raster_line;

				// outside screen (in borders)?
				if (rasterY < 0x32 || rasterY > 0xFA
					|| rasterX < 0x88 || rasterX > 0x1C7)
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

			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_STOP))
			{
				debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
			}
		}
		debugInterfaceVice->UnlockMutex();
	}
}

void c64d_drive1541_check_pc_breakpoint(uint16 pc)
{
	if ((int)pc == debugInterfaceVice->temporaryDrive1541BreakpointPC)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
		debugInterfaceVice->temporaryDrive1541BreakpointPC = -1;
		viceCurrentDiskPC[0] = pc;
	}
	else if (debugInterfaceVice->breakOnDrive1541PC)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, CAddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsDrive1541PC.find(pc);
		if (it != debugInterfaceVice->breakpointsDrive1541PC.end())
		{
			debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
		}
		debugInterfaceVice->UnlockMutex();
	}
	
}

// copy of vic state registers for VIC Display
//vicii_cycle_state_t viciiStateForCycle[312];	//Lines: PAL 312, NTSC 263
vicii_cycle_state_t viciiStateForCycle[312][64];	//Cycles: PAL 19655, NTSC 17095

extern "C"
{
	void c64d_get_maincpu_regs(uint8 *a, uint8 *x, uint8 *y, uint8 *p, uint8 *sp, uint16 *pc,
							   uint8 *instructionCycle);
	void c64d_get_exrom_game(BYTE *exrom, BYTE *game);
	void c64d_get_ultimax_phi(BYTE *ultimax_phi1, BYTE *ultimax_phi2);
};

vicii_cycle_state_t *c64d_get_vicii_state_for_raster_cycle(int rasterLine, int rasterCycle)
{
	return &(viciiStateForCycle[rasterLine][rasterCycle]);
}

vicii_cycle_state_t *c64d_get_vicii_state_for_raster_line(int rasterLine)
{
	return &(viciiStateForCycle[rasterLine][0]);
}

extern "C" {
	BYTE c64d_peek_memory0001();
};

void c64d_vicii_copy_state(vicii_cycle_state_t *viciiCopy)
{
	memcpy(viciiCopy->regs, vicii.regs, 64);
	
	viciiCopy->raster_line = vicii.raster_line;
	viciiCopy->raster_cycle = vicii.raster_cycle;
	
	viciiCopy->raster_irq_line = vicii.raster_irq_line;
	
	viciiCopy->vbank_phi1 = vicii.vbank_phi1;
	viciiCopy->vbank_phi2 = vicii.vbank_phi2;
	
	viciiCopy->idle_state = vicii.idle_state;
	viciiCopy->rc = vicii.rc;
	viciiCopy->vc = vicii.vc;
	viciiCopy->vcbase = vicii.vcbase;
	viciiCopy->vmli = vicii.vmli;
	
	viciiCopy->bad_line = vicii.bad_line;
	
	viciiCopy->last_read_phi1 = vicii.last_read_phi1;
	viciiCopy->sprite_dma = vicii.sprite_dma;
	viciiCopy->sprite_display_bits = vicii.sprite_display_bits;
	
	for (int i = 0; i < VICII_NUM_SPRITES; i++)
	{
		viciiCopy->sprite[i].data = vicii.sprite[i].data;
		viciiCopy->sprite[i].mc = vicii.sprite[i].mc;
		viciiCopy->sprite[i].mcbase = vicii.sprite[i].mcbase;
		viciiCopy->sprite[i].pointer = vicii.sprite[i].pointer;
		viciiCopy->sprite[i].exp_flop = vicii.sprite[i].exp_flop;
		viciiCopy->sprite[i].x = vicii.sprite[i].x;
	}
	
	
	// additional vars
	c64d_get_exrom_game(&(viciiCopy->exrom), &(viciiCopy)->game);
	c64d_get_ultimax_phi(&(viciiCopy->export_ultimax_phi1), &(viciiCopy->export_ultimax_phi2));

	viciiCopy->vaddr_mask_phi1 = vicii.vaddr_mask_phi1;
	viciiCopy->vaddr_mask_phi2 = vicii.vaddr_mask_phi2;
	viciiCopy->vaddr_offset_phi1 = vicii.vaddr_offset_phi1;
	viciiCopy->vaddr_offset_phi2 = vicii.vaddr_offset_phi2;
	viciiCopy->vaddr_chargen_mask_phi1 = vicii.vaddr_chargen_mask_phi1;
	viciiCopy->vaddr_chargen_value_phi1 = vicii.vaddr_chargen_value_phi1;
	viciiCopy->vaddr_chargen_mask_phi2 = vicii.vaddr_chargen_mask_phi2;
	viciiCopy->vaddr_chargen_value_phi2 = vicii.vaddr_chargen_value_phi2;
	
	// CPU
	c64d_get_maincpu_regs(&(viciiCopy->a), &(viciiCopy->x), &(viciiCopy->y), &(viciiCopy->processorFlags), &(viciiCopy->sp), &(viciiCopy->pc),
						  &(viciiCopy->instructionCycle));

	// TODO: DO WE STILL NEED THIS?
	viciiCopy->lastValidPC = viciiCopy->pc;
	
	//LOGD("mem01=%02x", c64d_peek_memory0001());
	viciiCopy->memory0001 = c64d_peek_memory0001();

	
}

void c64d_vicii_copy_state_data(vicii_cycle_state_t *viciiDest, vicii_cycle_state_t *viciiSrc)
{
	memcpy(viciiDest->regs, viciiSrc->regs, 64);
	
	viciiDest->raster_line = viciiSrc->raster_line;
	viciiDest->raster_cycle = viciiSrc->raster_cycle;
	
	viciiDest->raster_irq_line = viciiSrc->raster_irq_line;
	
	viciiDest->vbank_phi1 = viciiSrc->vbank_phi1;
	viciiDest->vbank_phi2 = viciiSrc->vbank_phi2;
	
	viciiDest->idle_state = viciiSrc->idle_state;
	viciiDest->rc = viciiSrc->rc;
	viciiDest->vc = viciiSrc->vc;
	viciiDest->vcbase = viciiSrc->vcbase;
	viciiDest->vmli = viciiSrc->vmli;
	
	viciiDest->bad_line = viciiSrc->bad_line;
	
	viciiDest->last_read_phi1 = viciiSrc->last_read_phi1;
	viciiDest->sprite_dma = viciiSrc->sprite_dma;
	viciiDest->sprite_display_bits = viciiSrc->sprite_display_bits;
	
	for (int i = 0; i < VICII_NUM_SPRITES; i++)
	{
		viciiDest->sprite[i].data = viciiSrc->sprite[i].data;
		viciiDest->sprite[i].mc = viciiSrc->sprite[i].mc;
		viciiDest->sprite[i].mcbase = viciiSrc->sprite[i].mcbase;
		viciiDest->sprite[i].pointer = viciiSrc->sprite[i].pointer;
		viciiDest->sprite[i].exp_flop = viciiSrc->sprite[i].exp_flop;
		viciiDest->sprite[i].x = viciiSrc->sprite[i].x;
	}
	
	viciiDest->exrom = viciiSrc->exrom;
	viciiDest->game = viciiSrc->game;
	
	viciiDest->export_ultimax_phi1 = viciiSrc->export_ultimax_phi1;
	viciiDest->export_ultimax_phi2 = viciiSrc->export_ultimax_phi2;
	
	
	viciiDest->vaddr_mask_phi1 = viciiSrc->vaddr_mask_phi1;
	viciiDest->vaddr_mask_phi2 = viciiSrc->vaddr_mask_phi2;
	viciiDest->vaddr_offset_phi1 = viciiSrc->vaddr_offset_phi1;
	viciiDest->vaddr_offset_phi2 = viciiSrc->vaddr_offset_phi2;
	viciiDest->vaddr_chargen_mask_phi1 = viciiSrc->vaddr_chargen_mask_phi1;
	viciiDest->vaddr_chargen_value_phi1 = viciiSrc->vaddr_chargen_value_phi1;
	viciiDest->vaddr_chargen_mask_phi2 = viciiSrc->vaddr_chargen_mask_phi2;
	viciiDest->vaddr_chargen_value_phi2 = viciiSrc->vaddr_chargen_value_phi2;
	
	// CPU
	viciiDest->a = viciiSrc->a;
	viciiDest->x = viciiSrc->x;
	viciiDest->y = viciiSrc->y;
	viciiDest->processorFlags = viciiSrc->processorFlags;
	viciiDest->sp = viciiSrc->sp;
	viciiDest->pc = viciiSrc->pc;
	viciiDest->instructionCycle = viciiSrc->instructionCycle;
	
	
	// TODO: DO WE STILL NEED THIS?
	viciiDest->lastValidPC = viciiSrc->lastValidPC;
	
	// TODO: ???
	viciiDest->memory0001 = viciiSrc->memory0001;
	
}


//uint32 viciiFrameCycleNum = 0;

// TODO: add setting in settings
uint8 c64d_vicii_record_state_mode = C64D_VICII_RECORD_MODE_EVERY_CYCLE; //C64D_VICII_RECORD_MODE_NONE;

void c64d_c64_set_vicii_record_state_mode(uint8 recordMode)
{
	c64d_vicii_record_state_mode = recordMode;
}

//unsigned int viciiFrameCycleNum = 0;

void c64d_c64_vicii_start_frame()
{
	//LOGD("c64d_c64_vicii_start_frame, viciiFrameCycleNum=%d", viciiFrameCycleNum);
	
	//viciiFrameCycleNum = 0;
	
	// TODO: frame counter + breakpoint on defined frame
	
	viewC64->EmulationStartFrameCallback();
}

void c64d_c64_vicii_cycle()
{
//	LOGD("line=%04x / cycle=%04x  start=%d", vicii.raster_line, vicii.raster_cycle, vicii.start_of_frame);
//	LOGD("viciiFrameCycleNum=%5d line=%04x / cycle=%04x  start=%d", viciiFrameCycleNum, vicii.raster_line, vicii.raster_cycle, vicii.start_of_frame);
	//viciiFrameCycleNum++;
	
	if (c64d_vicii_record_state_mode == C64D_VICII_RECORD_MODE_EVERY_CYCLE)
	{
		// correct the raster line on start frame
		unsigned int rasterLine = vicii.raster_line;
		unsigned int rasterCycle = vicii.raster_cycle;
		
		if (vicii.start_of_frame == 1)
		{
			rasterLine = 0;
		}

		vicii_cycle_state_t *viciiCopy = &viciiStateForCycle[rasterLine][rasterCycle];
		c64d_vicii_copy_state(viciiCopy);
	}
}

void c64d_c64_vicii_start_raster_line(uint16 rasterLine)
{
	// copy VIC state
//	LOGD("c64d_c64_vicii_start_raster_line: rasterLine=%d cycle=%d", rasterLine, vicii.raster_cycle);

	if (c64d_vicii_record_state_mode == C64D_VICII_RECORD_MODE_EVERY_LINE)
	{
		vicii_cycle_state_t *viciiCopy = &viciiStateForCycle[rasterLine][0];
		c64d_vicii_copy_state(viciiCopy);
	}
	
	c64d_c64_check_raster_breakpoint(rasterLine);
}

void c64d_c64_check_raster_breakpoint(uint16 rasterLine)
{
//	LOGD("c64d_c64_check_raster_breakpoint rasterLine=%d", rasterLine);
	if (debugInterfaceVice->breakOnRaster)
	{
		debugInterfaceVice->LockMutex();
		std::map<uint16, CAddrBreakpoint *>::iterator it = debugInterfaceVice->breakpointsRaster.find(rasterLine);
		if (it != debugInterfaceVice->breakpointsRaster.end())
		{
			debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
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
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
	}
}

void c64d_drive1541_check_irqvia1_breakpoint()
{
	if (debugInterfaceVice->breakOnDrive1541IrqVIA1)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
	}
}


void c64d_drive1541_check_irqvia2_breakpoint()
{
	if (debugInterfaceVice->breakOnDrive1541IrqVIA2)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
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
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED); //C64_DEBUG_RUN_ONE_INSTRUCTION);
	}
}

void c64d_c64_check_irqcia_breakpoint(int ciaNum)
{
	if (debugInterfaceVice->breakOnC64IrqCIA)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
	}
}

void c64d_c64_check_irqnmi_breakpoint()
{
	if (debugInterfaceVice->breakOnC64IrqNMI)
	{
		debugInterfaceVice->SetDebugMode(DEBUGGER_MODE_PAUSED);
	}
}

void c64d_debug_pause_check()
{
	if (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
	{		
		c64d_refresh_previous_lines();
		c64d_refresh_dbuf();
		c64d_refresh_cia();
		
		while (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
		{
			vsync_do_vsync(vicii.raster.canvas, 0, 1);
			//mt_SYS_Sleep(50);
		}
	}
}

////////////

// sid
int c64d_is_receive_channels_data[MAX_NUM_SIDS] = { 0, 0, 0 };

void c64d_sid_receive_channels_data(int sidNum, int isOn)
{
	c64d_is_receive_channels_data[sidNum] = isOn;
}

void c64d_sid_channels_data(int sidNumber, int v1, int v2, int v3, short mix)
{
//	LOGD("c64d_sid_channels_data: sid#%d, %d %d %d %d", sidNumber, v1, v2, v3, mix);
	
	viewC64->viewC64StateSID->AddWaveformData(sidNumber, v1, v2, v3, mix);
}

