#ifndef _VICEDEBUGINTERFACE_H_
#define _VICEDEBUGINTERFACE_H_

#include "SYS_Types.h"
#include "C64DebugTypes.h"

#define C64DEBUGGER_VICE_VERSION_STRING		"3.1"

#ifndef VICII_NUM_SPRITES
#define VICII_NUM_SPRITES      8
#endif

#define MAX_NUM_SIDS	3

struct vicii_sprite_state_s {
	uint16 data;
	uint8 mc;
	uint8 mcbase;
	uint8 pointer;
	int exp_flop;
	int x;
};
typedef struct vicii_sprite_state_s vicii_sprite_state_t;

struct vicii_cycle_state_s
{
	uint8 regs[0x40];
	
	unsigned int raster_cycle;
	unsigned int raster_line;
	unsigned int raster_irq_line;
	
	int vbank_phi1;
	int vbank_phi2;
	
	int idle_state;
	int rc;
	int vc;
	int vcbase;
	int vmli;
	
	int bad_line;

	uint8 last_read_phi1;
	uint8 sprite_dma;
	unsigned int sprite_display_bits;
	
	vicii_sprite_state_t sprite[VICII_NUM_SPRITES];
	
	// additional vars
	uint8 exrom, game;
	uint8 export_ultimax_phi1, export_ultimax_phi2;
	uint16 vaddr_mask_phi1;
	uint16 vaddr_mask_phi2;
	uint16 vaddr_offset_phi1;
	uint16 vaddr_offset_phi2;
	
	uint16 vaddr_chargen_mask_phi1;
	uint16 vaddr_chargen_value_phi1;
	uint16 vaddr_chargen_mask_phi2;
	uint16 vaddr_chargen_value_phi2;
	
	// cpu
	uint8 a, x, y;
	uint8 processorFlags, sp;
	uint16 pc;
	//	uint8 intr[4];		// Interrupt state
	uint16 lastValidPC;
	uint8 instructionCycle;
	
	uint8 memory0001;
	
};

typedef struct vicii_cycle_state_s vicii_cycle_state_t;

//


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
void c64d_refresh_cia();

void c64d_c64_set_vicii_record_state_mode(uint8 recordMode);

void c64d_vicii_copy_state(vicii_cycle_state_t *viciiCopy);
void c64d_vicii_copy_state_data(vicii_cycle_state_t *viciiDest, vicii_cycle_state_t *viciiSrc);

vicii_cycle_state_t *c64d_get_vicii_state_for_raster_cycle(int rasterLine, int rasterCycle);
vicii_cycle_state_t *c64d_get_vicii_state_for_raster_line(int rasterLine);
void c64d_c64_vicii_cycle();

void c64d_c64_vicii_start_frame();
void c64d_c64_vicii_start_raster_line(uint16 rasterLine);

void c64d_display_speed(float speed, float frame_rate);
void c64d_display_drive_led(int drive_number, unsigned int pwm1, unsigned int led_pwm2);

extern uint8 c64d_palette_red[16];
extern uint8 c64d_palette_green[16];
extern uint8 c64d_palette_blue[16];

extern float c64d_float_palette_red[16];
extern float c64d_float_palette_green[16];
extern float c64d_float_palette_blue[16];

void c64d_set_palette(uint8 *palette);
void c64d_set_palette_vice(uint8 *palette);

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
extern int c64d_is_receive_channels_data[MAX_NUM_SIDS];
void c64d_sid_receive_channels_data(int sidNum, int isOn);
void c64d_sid_channels_data(int sidNum, int v1, int v2, int v3, short mix);
void c64d_set_volume(float volume);

// VIC
void c64d_set_color_register(uint8 colorRegisterNum, uint8 value);

// ROM patch
extern int c64d_patch_kernal_fast_boot_flag;

// run SID when in warp mode?
extern int c64d_setting_run_sid_when_in_warp;

// run SID emulation at all or always skip?
extern int c64d_setting_run_sid_emulation;


#endif

