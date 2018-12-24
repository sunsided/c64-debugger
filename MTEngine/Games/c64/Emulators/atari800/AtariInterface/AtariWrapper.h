#ifndef _ATARI_INTERFACE_H_
#define _ATARI_INTERFACE_H_

#include "SYS_Types.h"
#include "DebuggerDefs.h"

#define ATARI_AUDIO_BUFFER_FRAMES	512

void mt_SYS_FatalExit(char *text);
long mt_SYS_GetCurrentTimeInMillis();
void mt_SYS_Sleep(long milliseconds);

char *ATRD_GetPathForRoms();

extern volatile int atrd_debug_mode;

void atrd_mark_atari_cell_read(uint16 addr);
void atrd_mark_atari_cell_write(uint16 addr, uint8 value);
void atrd_mark_atari_cell_execute(uint16 addr, uint8 opcode);
void atrd_check_pc_breakpoint(uint16 pc);
void atrd_debug_pause_check();

void atrd_async_check();

void atrd_async_load_snapshot(char *filePath);
void atrd_async_save_snapshot(char *filePath);

void atrd_sound_init();
void atrd_sound_pause();
void atrd_sound_resume();

void atrd_sound_lock();
void atrd_sound_unlock();

void atrd_mutex_lock();
void atrd_mutex_unlock();

int atrd_is_debug_on_atari();

int atrd_get_joystick_state(int port);

#endif
