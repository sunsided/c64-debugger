#ifndef _VICEDEBUGINTERFACE_H_
#define _VICEDEBUGINTERFACE_H_

#include "SYS_Types.h"
#include "C64DebugTypes.h"

void c64d_sound_init();
void c64d_sound_pause();
void c64d_sound_resume();

extern uint16 viceCurrentC64PC;
extern uint16 viceCurrentDiskPC[4];

long mt_SYS_GetCurrentTimeInMillis();
void mt_SYS_Sleep(long milliseconds);
void mt_SYS_FatalExit(char *text);

void c64d_mark_c64_cell_read(uint16 addr);
void c64d_mark_c64_cell_write(uint16 addr, uint8 value);
void c64d_mark_c64_cell_execute(uint16 addr, uint8 opcode);

// TODO: add device num
void c64d_mark_disk_cell_read(uint16 addr);
void c64d_mark_disk_cell_write(uint16 addr, uint8 value);
void c64d_mark_disk_cell_execute(uint16 addr, uint8 opcode);

void c64d_clear_screen();
void c64d_refresh_screen();
void c64d_refresh_previous_lines();
void c64d_refresh_dbuf();

void c64d_display_speed(float speed, float frame_rate);
void c64d_display_drive_led(int drive_number, unsigned int pwm1, unsigned int led_pwm2);

extern uint8 c64d_palette_red[16];
extern uint8 c64d_palette_green[16];
extern uint8 c64d_palette_blue[16];

void c64d_set_palette(uint8 *palette);

int c64d_is_debug_on_c64();
int c64d_is_debug_on_drive1541();

extern volatile int c64d_debug_mode;
void c64d_c64_check_pc_breakpoint(uint16 pc);
void c64d_c64_check_raster_breakpoint(uint16 rasterLine);
int c64d_c64_is_checking_irq_breakpoints_enabled();
void c64d_drive1541_check_pc_breakpoint(uint16 pc);
int c64d_drive1541_is_checking_irq_breakpoints_enabled();
void c64d_drive1541_check_irqiec_breakpoint();
void c64d_drive1541_check_irqvia1_breakpoint();
void c64d_drive1541_check_irqvia2_breakpoint();

void c64d_c64_check_irqvic_breakpoint();
void c64d_c64_check_irqcia_breakpoint(int ciaNum);
void c64d_debug_pause_check();

void c64d_show_message(char *message);

// SID
extern int c64d_is_receive_channels_data;
void c64d_sid_receive_channels_data(int isOn);
void c64d_sid_channels_data(int v1, int v2, int v3, short mix);

#endif

