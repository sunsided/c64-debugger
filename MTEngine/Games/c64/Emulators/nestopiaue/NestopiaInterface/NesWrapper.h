#ifndef _NES_INTERFACE_H_
#define _NES_INTERFACE_H_

#include "SYS_Types.h"
#include "DebuggerDefs.h"

class CByteBuffer;

extern volatile int nesd_debug_mode;

void NestopiaUE_Initialize();
void NestopiaUE_Run();

bool nesd_insert_cartridge(char *filePath);

void nesd_reset();
unsigned char *nesd_get_ram();
unsigned int nesd_get_cpu_pc();
unsigned char nesd_peek_io(unsigned short addr);
void nesd_get_cpu_regs(unsigned short *pc, unsigned char *a, unsigned char *x, unsigned char *y, unsigned char *p, unsigned char *s, unsigned char *irq);

CByteBuffer *nesd_store_state();
bool nesd_restore_state(CByteBuffer *byteBuffer);
unsigned char nesd_peek_io(unsigned short addr);
unsigned char nesd_peek_safe_io(unsigned short addr);


//void nesd_mark_atari_cell_read(uint16 addr);
//void nesd_mark_atari_cell_write(uint16 addr, uint8 value);
//void nesd_mark_atari_cell_execute(uint16 addr, uint8 opcode);
//void nesd_check_pc_breakpoint(uint16 pc);
//void nesd_debug_pause_check();
//
//void nesd_async_check();
//
//void nesd_async_load_snapshot(char *filePath);
//void nesd_async_save_snapshot(char *filePath);
//
void nesd_sound_init();
void nesd_sound_pause();
void nesd_sound_resume();

void nesd_joystick_down(int port, uint32 axis);
void nesd_joystick_up(int port, uint32 axis);

void nesd_audio_callback(uint8 *stream, int numSamples);
void nesd_sound_lock();
void nesd_sound_unlock();

//void nesd_mutex_lock();
//void nesd_mutex_unlock();
//
//int nesd_is_debug_on_atari();
//
//int nesd_get_joystick_state(int port);

#endif
