extern "C" {
#include "vice.h"
#include "main.h"
#include "types.h"
#include "mos6510.h"
#include "montypes.h"
#include "attach.h"
#include "keyboard.h"
#include "drivecpu.h"
#include "machine.h"
#include "vsync.h"
#include "interrupt.h"
#include "c64-snapshot.h"
#include "viciitypes.h"
#include "vicii.h"
#include "vicii-mem.h"
#include "drivetypes.h"
#include "drive.h"
#include "cia.h"
#include "c64.h"
#include "sid.h"
#include "sid-resources.h"
#include "drive.h"
#include "c64mem.h"
#include "c64model.h"
#include "ui.h"
#include "resources.h"
#include "ViceWrapper.h"
}

#include "RES_ResourceManager.h"
#include "C64DebugInterfaceVice.h"
#include "CByteBuffer.h"
#include "CSlrString.h"
#include "C64DataAdaptersVice.h"
#include "SYS_CommandLine.h"
#include "CGuiMain.h"
#include "SYS_KeyCodes.h"
#include "SND_SoundEngine.h"
#include "C64Tools.h"
#include "C64KeyMap.h"
#include "C64SettingsStorage.h"
#include "C64SIDFrequencies.h"

extern "C" {
	void vsync_suspend_speed_eval(void);
	void c64d_reset_sound_clk();
	void sound_suspend(void);
	void sound_resume(void);
	int c64d_sound_run_sound_when_paused(void);
	int set_suspend_time(int val, void *param);
	
	void c64d_set_debug_mode(int newMode);
	void c64d_patch_kernal_fast_boot();
	void c64d_init_memory(uint8 *c64memory);
}

void c64d_update_c64_model();
void c64d_update_c64_machine_from_model_type(int modelType);
void c64d_update_c64_screen_height_from_model_type(int modelType);

void ViceWrapperInit(C64DebugInterfaceVice *debugInterface);

C64DebugInterfaceVice *debugInterfaceVice = NULL;

C64DebugInterfaceVice::C64DebugInterfaceVice(CViewC64 *viewC64, uint8 *c64memory, bool patchKernalFastBoot)
: C64DebugInterface(viewC64)
{
	LOGM("C64DebugInterfaceVice: VICE %s init", VERSION);

	screen = new CImageData(512, 512, IMG_TYPE_RGBA);
	screen->AllocImage(false, true);

	viceAudioChannel = NULL;

	ViceWrapperInit(this);
	
	// set patch kernal flag
	//	SetPatchKernalFastBoot(patchKernalFastBoot);
	if (patchKernalFastBoot)
	{
		c64d_patch_kernal_fast_boot_flag = 1;
	}
	else
	{
		c64d_patch_kernal_fast_boot_flag = 0;
	}

	
	// PAL
	screenHeight = 272;
	machineType = C64_MACHINE_PAL;

	// init C64 memory, will be attached to a memmaped file if needed
	if (c64memory == NULL)
	{
		this->c64memory = (uint8 *)malloc(C64_RAM_SIZE);
	}
	else
	{
		this->c64memory = c64memory;
	}

	c64d_init_memory(this->c64memory);
	
	int ret = vice_main_program(sysArgc, sysArgv, c64SettingsC64Model);
	if (ret != 0)
	{
		SYS_FatalExit("Vice failed, err=%d", ret);
	}

	this->dataAdapterC64 = new C64DataAdapterVice(this);
	this->dataAdapterC64DirectRam = new C64DirectRamDataAdapterVice(this);
	this->dataAdapterDrive1541 = new C64DiskDataAdapterVice(this);
	this->dataAdapterDrive1541DirectRam = new C64DiskDirectRamDataAdapterVice(this);
	

	C64KeyMap *keyMap = C64KeyMapGetDefault();
	InitKeyMap(keyMap);
	

	isJoystickEnabled = false;
	joystickPort = 0x03;
}

extern "C" {
	void c64d_patch_kernal_fast_boot();
	void c64d_un_patch_kernal_fast_boot();
	void c64d_update_rom();
};

void C64DebugInterfaceVice::SetPatchKernalFastBoot(bool isPatchKernal)
{
	LOGM("C64DebugInterfaceVice::SetPatchKernalFastBoot: %d", isPatchKernal);

	c64d_un_patch_kernal_fast_boot();
	
	if (isPatchKernal)
	{
		c64d_patch_kernal_fast_boot_flag = 1;
		c64d_patch_kernal_fast_boot();
	}
	else
	{
		c64d_patch_kernal_fast_boot_flag = 0;
	}
	
	c64d_update_rom();
}

void C64DebugInterfaceVice::SetRunSIDWhenInWarp(bool isRunningSIDInWarp)
{
	c64d_setting_run_sid_when_in_warp = isRunningSIDInWarp ? 1 : 0;
}

int C64DebugInterfaceVice::GetEmulatorType()
{
	return C64_EMULATOR_VICE;
}

CSlrString *C64DebugInterfaceVice::GetEmulatorVersionString()
{
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Vice %s by The VICE Team", VERSION);
	CSlrString *versionString = new CSlrString(buf);
	SYS_ReleaseCharBuf(buf);
	
	return versionString;
}

void C64DebugInterfaceVice::RunEmulationThread()
{
	LOGM("C64DebugInterfaceVice::RunEmulationThread");
	
	vice_main_loop_run();
	
	LOGM("C64DebugInterfaceVice::RunEmulationThread: finished");
}

void C64DebugInterfaceVice::InitKeyMap(C64KeyMap *keyMap)
{
	LOGD("C64DebugInterfaceVice::InitKeyMap");
	c64d_keyboard_keymap_clear();
	
	for (std::map<u32, C64KeyCode *>::iterator it = keyMap->keyCodes.begin();
		 it != keyMap->keyCodes.end(); it++)
	{
		C64KeyCode *key = it->second;
		
		if (key->matrixRow < 0)
		{
			// restore, caps lock, ...
			keyboard_parse_set_neg_row(key->keyCode, key->matrixRow, key->matrixCol);
		}
		else
		{
			
			//LOGD("... %04x %3d %3d %d", key->keyCode, key->matrixRow, key->matrixCol, key->shift);
			keyboard_parse_set_pos_row(key->keyCode, key->matrixRow, key->matrixCol, key->shift);
		}
	}
	
	
}

uint8 *C64DebugInterfaceVice::GetCharRom()
{
	return mem_chargen_rom;
}

int C64DebugInterfaceVice::GetC64ScreenSizeX()
{
	return 384;
}

int C64DebugInterfaceVice::GetC64ScreenSizeY()
{
	return screenHeight;
}

CImageData *C64DebugInterfaceVice::GetC64ScreenImageData()
{
	return screen;
}

bool C64DebugInterfaceVice::IsCpuJam()
{
	if (c64d_is_cpu_in_jam_state == 1)
	{
		return true;
	}
	
	return false;
}

void C64DebugInterfaceVice::ForceRunAndUnJamCpu()
{
	c64d_is_cpu_in_jam_state = 0;
	this->SetDebugMode(C64_DEBUG_RUNNING);
}


void C64DebugInterfaceVice::Reset()
{
	vsync_suspend_speed_eval();
	
	keyboard_clear_keymatrix();

	machine_trigger_reset(MACHINE_RESET_MODE_SOFT);
	c64d_update_c64_model();

	if (c64d_is_cpu_in_jam_state == 1)
	{
		this->SetDebugMode(C64_DEBUG_RUNNING);
		c64d_is_cpu_in_jam_state = 0;
	}
}

void C64DebugInterfaceVice::HardReset()
{
	vsync_suspend_speed_eval();
	
	keyboard_clear_keymatrix();

	machine_trigger_reset(MACHINE_RESET_MODE_HARD);
	c64d_update_c64_model();

	if (c64d_is_cpu_in_jam_state == 1)
	{
		this->SetDebugMode(C64_DEBUG_RUNNING);
		c64d_is_cpu_in_jam_state = 0;
	}
}

void C64DebugInterfaceVice::DiskDriveReset()
{
	LOGM("C64DebugInterfaceVice::DiskDriveReset()");
	
	drivecpu_reset(drive_context[0]);
}

extern "C" {
	void c64d_joystick_key_down(int key, unsigned int joyport);
	void c64d_joystick_key_up(int key, unsigned int joyport);
}

#define JOYPAD_FIRE 0x10
#define JOYPAD_E    0x08
#define JOYPAD_W    0x04
#define JOYPAD_S    0x02
#define JOYPAD_N    0x01
#define JOYPAD_SW   (JOYPAD_S | JOYPAD_W)
#define JOYPAD_SE   (JOYPAD_S | JOYPAD_E)
#define JOYPAD_NW   (JOYPAD_N | JOYPAD_W)
#define JOYPAD_NE   (JOYPAD_N | JOYPAD_E)


void C64DebugInterfaceVice::KeyboardDown(uint32 mtKeyCode)
{
	LOGI("C64DebugInterfaceVice::KeyboardDown: %d", mtKeyCode);
	if (isJoystickEnabled)
	{
		if (mtKeyCode == MTKEY_ARROW_LEFT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_down(JOYPAD_W, 1);
			
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_down(JOYPAD_W, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_RIGHT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_down(JOYPAD_E, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_down(JOYPAD_E, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_UP)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_down(JOYPAD_N, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_down(JOYPAD_N, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_DOWN)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_down(JOYPAD_S, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_down(JOYPAD_S, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_RALT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_down(JOYPAD_FIRE, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_down(JOYPAD_FIRE, 2);
			return;
		}
	}
	
	keyboard_key_pressed((unsigned long)mtKeyCode);
}

void C64DebugInterfaceVice::KeyboardUp(uint32 mtKeyCode)
{
	LOGI("C64DebugInterfaceVice::KeyboardUp: %d", mtKeyCode);
	if (isJoystickEnabled)
	{
		if (mtKeyCode == MTKEY_ARROW_LEFT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_up(JOYPAD_W, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_up(JOYPAD_W, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_RIGHT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_up(JOYPAD_E, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_up(JOYPAD_E, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_UP)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_up(JOYPAD_N, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_up(JOYPAD_N, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_ARROW_DOWN)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_up(JOYPAD_S, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_up(JOYPAD_S, 2);
			return;
		}
		else if (mtKeyCode == MTKEY_RALT)
		{
			if ((joystickPort & 0x01) == 0x01)
				c64d_joystick_key_up(JOYPAD_FIRE, 1);
			if ((joystickPort & 0x02) == 0x02)
				c64d_joystick_key_up(JOYPAD_FIRE, 2);
			return;
		}
	}

	keyboard_key_released((unsigned long)mtKeyCode);
}

int C64DebugInterfaceVice::GetC64CpuPC()
{
	return viceCurrentC64PC;
}

int C64DebugInterfaceVice::GetDrive1541PC()
{
	return viceCurrentDiskPC[0];
}

extern "C" {
// from c64cpu.c
	void c64d_get_maincpu_regs(uint8 *a, uint8 *x, uint8 *y, uint8 *p, uint8 *sp, uint16 *pc,
							   uint8 *instructionCycle);
	void c64d_get_drivecpu_regs(int driveNum, uint8 *a, uint8 *x, uint8 *y, uint8 *p, uint8 *sp, uint16 *pc);
}

void C64DebugInterfaceVice::GetC64CpuState(C64StateCPU *state)
{
	c64d_get_maincpu_regs(&(state->a), &(state->x), &(state->y), &(state->processorFlags), &(state->sp), &(state->pc),
						  &(state->instructionCycle));
	
	state->lastValidPC = state->pc;
}

void C64DebugInterfaceVice::GetDrive1541CpuState(C64StateCPU *state)
{
	c64d_get_drivecpu_regs(0, &(state->a), &(state->x), &(state->y), &(state->processorFlags), &(state->sp), &(state->pc));
	
	state->lastValidPC = viceCurrentDiskPC[0];
	
	//LOGD("drive pc: %04x", state->pc);
}

extern "C" {
	void c64d_get_vic_simple_state(struct C64StateVIC *simpleStateVic);
}

void C64DebugInterfaceVice::GetVICState(C64StateVIC *state)
{
	c64d_get_vic_simple_state(state);
}

void C64DebugInterfaceVice::GetDrive1541State(C64StateDrive1541 *state)
{
	drive_t *drive = drive_context[0]->drive;
	state->headTrackPosition = drive->current_half_track + drive->side * 70;

}

void C64DebugInterfaceVice::InsertD64(CSlrString *path)
{
	char *asciiPath = path->GetStdASCII();
	
	FixFileNameSlashes(asciiPath);

	int rc = file_system_attach_disk(8, asciiPath);
	
	if (rc == -1)
	{
		guiMain->ShowMessage("Inserting disk failed");
	}
	
	delete asciiPath;
}

void C64DebugInterfaceVice::DetachDriveDisk()
{
	file_system_detach_disk(8);
}

extern "C" {
	int c64d_get_warp_mode();
	int set_warp_mode(int val, void *param);
}

bool C64DebugInterfaceVice::GetSettingIsWarpSpeed()
{
	return c64d_get_warp_mode() == 0 ? false : true;
}

void C64DebugInterfaceVice::SetSettingIsWarpSpeed(bool isWarpSpeed)
{
	set_warp_mode(isWarpSpeed ? 1 : 0, NULL);
}

bool C64DebugInterfaceVice::GetSettingUseKeyboardForJoystick()
{
	return isJoystickEnabled;
}

void C64DebugInterfaceVice::SetSettingUseKeyboardForJoystick(bool isJoystickOn)
{
	this->isJoystickEnabled = isJoystickOn;
}

void C64DebugInterfaceVice::SetKeyboardJoystickPort(uint8 joystickPort)
{
	switch(joystickPort)
	{
		case 0:
			this->joystickPort = 0x03;
			break;
		case 1:
			this->joystickPort = 0x01;
			break;
		case 2:
			this->joystickPort = 0x02;
			break;
	}
}

///

void C64DebugInterfaceVice::GetSidTypes(std::vector<CSlrString *> *sidTypes)
{
	// 0-2
	sidTypes->push_back(new CSlrString("6581 (ReSID)"));
	sidTypes->push_back(new CSlrString("8580 (ReSID)"));
	sidTypes->push_back(new CSlrString("8580 + digi boost (ReSID)"));

	// 3-4
	sidTypes->push_back(new CSlrString("6581 (FastSID)"));
	sidTypes->push_back(new CSlrString("8580 (FastSID)"));

	// 5-14
	sidTypes->push_back(new CSlrString("6581R3 4885 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("6581R3 0486S (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("6581R3 3984 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("6581R4AR 3789 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("6581R3 4485 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("6581R4 1986S (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("8580R5 3691 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("8580R5 3691 + digi (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("8580R5 1489 (ReSID-fp)"));
	sidTypes->push_back(new CSlrString("8580R5 1489 + digi (ReSID-fp)"));
}

void C64DebugInterfaceVice::SetSidType(int sidType)
{
	switch(sidType)
	{
		default:
		case 0:
			sid_set_engine_model(SID_ENGINE_RESID, SID_MODEL_6581);
			break;
		case 1:
			sid_set_engine_model(SID_ENGINE_RESID, SID_MODEL_8580);
			break;
		case 2:
			sid_set_engine_model(SID_ENGINE_RESID, SID_MODEL_8580D);
			break;
		case 3:
			sid_set_engine_model(SID_ENGINE_FASTSID, SID_MODEL_6581);
			break;
		case 4:
			sid_set_engine_model(SID_ENGINE_FASTSID, SID_MODEL_8580);
			break;
		case 5:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R3_4885);
			break;
		case 6:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R3_0486S);
			break;
		case 7:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R3_3984);
			break;
		case 8:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R4AR_3789);
			break;
		case 9:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R3_4485);
			break;
		case 10:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_6581R4_1986S);
			break;
		case 11:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_8580R5_3691);
			break;
		case 12:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_8580R5_3691D);
			break;
		case 13:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_8580R5_1489);
			break;
		case 14:
			sid_set_engine_model(SID_ENGINE_RESID_FP, SID_MODEL_8580R5_1489D);
			break;

	}
}

// samplingMethod: Fast=0, Interpolating=1, Resampling=2, Fast Resampling=3
void C64DebugInterfaceVice::SetSidSamplingMethod(int samplingMethod)
{
	c64d_sid_set_sampling_method(samplingMethod);
}

// emulateFilters: no=0, yes=1
void C64DebugInterfaceVice::SetSidEmulateFilters(int emulateFilters)
{
	c64d_sid_set_emulate_filters(emulateFilters);
}

// passband: 0-90
void C64DebugInterfaceVice::SetSidPassBand(int passband)
{
	c64d_sid_set_passband(passband);
}

// filterBias: -500 500
void C64DebugInterfaceVice::SetSidFilterBias(int filterBias)
{
	c64d_sid_set_filter_bias(filterBias);
}


///// c64model.c
//#define C64MODEL_C64_PAL 0
//#define C64MODEL_C64C_PAL 1
//#define C64MODEL_C64_OLD_PAL 2
//
//#define C64MODEL_C64_NTSC 3
//#define C64MODEL_C64C_NTSC 4
//#define C64MODEL_C64_OLD_NTSC 5
//
//#define C64MODEL_C64_PAL_N 6
//
///* SX-64 */
//#define C64MODEL_C64SX_PAL 7
//#define C64MODEL_C64SX_NTSC 8
//
//#define C64MODEL_C64_JAP 9
//#define C64MODEL_C64_GS 10
//
//#define C64MODEL_PET64_PAL 11
//#define C64MODEL_PET64_NTSC 12
///* max machine */
//#define C64MODEL_ULTIMAX 13

void C64DebugInterfaceVice::GetC64ModelTypes(std::vector<CSlrString *> *modelTypeNames, std::vector<int> *modelTypeIds)
{
	modelTypeNames->push_back(new CSlrString("C64 PAL"));
	modelTypeIds->push_back(0);
	modelTypeNames->push_back(new CSlrString("C64C PAL"));
	modelTypeIds->push_back(1);
	modelTypeNames->push_back(new CSlrString("C64 old PAL"));
	modelTypeIds->push_back(2);
	modelTypeNames->push_back(new CSlrString("C64 NTSC"));
	modelTypeIds->push_back(3);
	modelTypeNames->push_back(new CSlrString("C64C NTSC"));
	modelTypeIds->push_back(4);
	modelTypeNames->push_back(new CSlrString("C64 old NTSC"));
	modelTypeIds->push_back(5);
	// crashes: modelTypeNames->push_back(new CSlrString("C64 PAL N (Drean)"));
	// crashes: modelTypeIds->push_back(6);
	modelTypeNames->push_back(new CSlrString("C64 SX PAL"));
	modelTypeIds->push_back(7);
	modelTypeNames->push_back(new CSlrString("C64 SX NTSC"));
	modelTypeIds->push_back(8);
	// no ROM: modelTypeNames->push_back(new CSlrString("Japanese"));
	// no ROM: modelTypeIds->push_back(9);
	// no ROM: modelTypeNames->push_back(new CSlrString("C64 GS"));
	// no ROM: modelTypeIds->push_back(10);
	modelTypeNames->push_back(new CSlrString("PET64 PAL"));
	modelTypeIds->push_back(11);
	modelTypeNames->push_back(new CSlrString("PET64 NTSC"));
	modelTypeIds->push_back(12);
	// no ROM: modelTypeNames->push_back(new CSlrString("MAX Machine"));
	// no ROM: modelTypeIds->push_back(13);
}


int c64_change_model_type;

static void c64_change_model_trap(WORD addr, void *v)
{
	guiMain->LockMutex();
	debugInterfaceVice->LockRenderScreenMutex();
	
	LOGD("c64_change_model_trap: model=%d", c64_change_model_type);
	
	//c64_change_model_type = 0;
	
	c64model_set(c64_change_model_type);
	
	debugInterfaceVice->modelType = c64_change_model_type;
	
	c64d_update_c64_machine_from_model_type(c64_change_model_type);
	c64d_update_c64_screen_height_from_model_type(c64_change_model_type);
	
	c64d_clear_screen();
	
	SYS_Sleep(100);
	
	c64d_clear_screen();
	
	debugInterfaceVice->UnlockRenderScreenMutex();
	guiMain->UnlockMutex();
}

void C64DebugInterfaceVice::SetC64ModelType(int modelType)
{
	LOGM("C64DebugInterfaceVice::SetC64ModelType: %d", modelType);
	
	// blank screen when machine type is changed
	this->screenHeight = 0;
	
	c64d_clear_screen();
	
	c64d_update_c64_machine_from_model_type(c64_change_model_type);

	c64_change_model_type = modelType;
	interrupt_maincpu_trigger_trap(c64_change_model_trap, NULL);
}

uint8 C64DebugInterfaceVice::GetC64MachineType()
{
	return machineType;
}

int C64DebugInterfaceVice::GetC64ModelType()
{
	return c64model_get();
}

void C64DebugInterfaceVice::SetEmulationMaximumSpeed(int maximumSpeed)
{
	resources_set_int("Speed", maximumSpeed);
	
	if (maximumSpeed < 20)
	{
		resources_set_int("Sound", 0);
	}
	else
	{
		resources_set_int("Sound", 1);
	}
}

extern "C" {
	int set_vsp_bug_enabled(int val, void *param);
}

void C64DebugInterfaceVice::SetVSPBugEmulation(bool isVSPBugEmulation)
{
	if (isVSPBugEmulation)
	{
		set_vsp_bug_enabled(1, NULL);
	}
	else
	{
		set_vsp_bug_enabled(0, NULL);
	}
}


///
///

extern "C" {
	void c64d_mem_write_c64(unsigned int addr, unsigned char value);
	void c64d_mem_ram_write_c64(WORD addr, BYTE value);
	void c64d_mem_ram_fill_c64(WORD addr, WORD size, BYTE value);
}

void C64DebugInterfaceVice::SetByteC64(uint16 addr, uint8 val)
{
	c64d_mem_write_c64(addr, val);
}

void C64DebugInterfaceVice::SetByteToRamC64(uint16 addr, uint8 val)
{
	c64d_mem_ram_write_c64(addr, val);
}

///////

extern "C" {
	//BYTE mem_bank_peek(int bank, WORD addr, void *context); // can't be used, because reading affects/changes state
	BYTE c64d_peek_c64(WORD addr);
	BYTE c64d_mem_ram_read_c64(WORD addr);
	void c64d_peek_memory_c64(BYTE *buffer, int addrStart, int addrEnd);
	void c64d_copy_ram_memory_c64(BYTE *buffer, int addrStart, int addrEnd);
	void c64d_copy_whole_mem_ram_c64(BYTE *destBuf);
	void c64d_peek_whole_map_c64(BYTE *memoryBuffer);
}

/***********/
uint8 C64DebugInterfaceVice::GetByteC64(uint16 addr)
{
	return c64d_peek_c64(addr);
}


uint8 C64DebugInterfaceVice::GetByteFromRamC64(uint16 addr)
{
	return c64d_mem_ram_read_c64(addr);
}


///

extern "C" {
	void mon_jump(MON_ADDR addr);
	void c64d_set_c64_pc(uint16 pc);
	void c64d_mem_ram_write_drive(int driveNum, uint16 addr, uint8 value);
	void c64d_drive_poke(int driveNum, uint16 addr, uint8 value);
	void c64d_set_drive_pc(int driveNr, uint16 pc);

}

void C64DebugInterfaceVice::SetVicRegister(uint8 registerNum, uint8 value)
{
	vicii_store(registerNum, value);
	
	if (registerNum >= 0x20 && registerNum <= 0x2E)
	{
		c64d_set_color_register(registerNum, value);
	}
}

u8 C64DebugInterfaceVice::GetVicRegister(uint8 registerNum)
{
	BYTE v = vicii_peek(registerNum);
	return v;
}

void C64DebugInterfaceVice::MakeJmpC64(uint16 addr)
{
	LOGD("C64DebugInterfaceVice::MakeJmpC64: %04x", addr);
	
	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	{
		c64d_set_c64_pc(addr);
		c64d_set_debug_mode(C64_DEBUG_PAUSED);
	}
	else
	{
		c64d_set_c64_pc(addr);
	}
}

void C64DebugInterfaceVice::MakeJmpNoResetC64(uint16 addr)
{
	LOGTODO("C64DebugInterfaceVice::MakeJmpNoResetC64");
	// TODO:
	this->MakeJmpC64(addr);
}

void C64DebugInterfaceVice::MakeJsrC64(uint16 addr)
{
	LOGTODO("C64DebugInterfaceVice::MakeJsrC64");
	// TODO:
	this->MakeJmpC64(addr);
}

void C64DebugInterfaceVice::SetByte1541(uint16 addr, uint8 val)
{
	c64d_drive_poke(0, addr, val);
}

void C64DebugInterfaceVice::SetByteToRam1541(uint16 addr, uint8 val)
{
	c64d_mem_ram_write_drive(0, addr, val);
}

extern "C" {
	uint8 c64d_peek_drive(int driveNum, uint16 addr);
	uint8 c64d_mem_ram_read_drive(int driveNum, uint16 addr);
	void c64d_peek_memory_drive(int driveNum, BYTE *buffer, uint16 addrStart, uint16 addrEnd);
	void c64d_copy_ram_memory_drive(int driveNum, BYTE *buffer, uint16 addrStart, uint16 addrEnd);
	void c64d_peek_whole_map_drive(int driveNum, uint8 *memoryBuffer);
	void c64d_copy_mem_ram_drive(int driveNum, uint8 *memoryBuffer);
}

uint8 C64DebugInterfaceVice::GetByte1541(uint16 addr)
{
	return c64d_peek_drive(0, addr); 
}

uint8 C64DebugInterfaceVice::GetByteFromRam1541(uint16 addr)
{
	return c64d_mem_ram_read_drive(0, addr);
}

void C64DebugInterfaceVice::MakeJmp1541(uint16 addr)
{
	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	{
		c64d_set_drive_pc(0, addr);
		//c64d_set_debug_mode(C64_DEBUG_RUN_ONE_INSTRUCTION);
	}
	else
	{
		c64d_set_drive_pc(0, addr);
	}
}

void C64DebugInterfaceVice::MakeJmpNoReset1541(uint16 addr)
{
	this->MakeJmp1541(addr);
}


void C64DebugInterfaceVice::GetWholeMemoryMapC64(uint8 *buffer)
{
	c64d_peek_whole_map_c64(buffer);
}

void C64DebugInterfaceVice::GetWholeMemoryMapFromRamC64(uint8 *buffer)
{
	c64d_copy_whole_mem_ram_c64(buffer);
}

void C64DebugInterfaceVice::GetWholeMemoryMap1541(uint8 *buffer)
{
	c64d_peek_whole_map_drive(0, buffer);
}

void C64DebugInterfaceVice::GetWholeMemoryMapFromRam1541(uint8 *buffer)
{
	c64d_copy_mem_ram_drive(0, buffer);
}


void C64DebugInterfaceVice::GetMemoryC64(uint8 *buffer, int addrStart, int addrEnd)
{
	c64d_peek_memory_c64(buffer, addrStart, addrEnd);
}

void C64DebugInterfaceVice::GetMemoryFromRamC64(uint8 *buffer, int addrStart, int addrEnd)
{
	c64d_copy_ram_memory_c64(buffer, addrStart, addrEnd);
}

void C64DebugInterfaceVice::GetMemoryDrive1541(uint8 *buffer, int addrStart, int addrEnd)
{
	c64d_peek_memory_drive(0, buffer, addrStart, addrEnd);
}

void C64DebugInterfaceVice::GetMemoryFromRamDrive1541(uint8 *buffer, int addrStart, int addrEnd)
{
	c64d_copy_ram_memory_drive(0, buffer, addrStart, addrEnd);
}

void C64DebugInterfaceVice::FillC64Ram(uint16 addr, uint16 size, uint8 value)
{
	c64d_mem_ram_fill_c64(addr, size, value);
}


///

extern "C" {
	void c64d_get_vic_colors(uint8 *cD021, uint8 *cD022, uint8 *cD023, uint8 *cD025, uint8 *cD026, uint8 *cD027, uint8 *cD800);
}

void C64DebugInterfaceVice::GetVICColors(uint8 *cD021, uint8 *cD022, uint8 *cD023, uint8 *cD025, uint8 *cD026, uint8 *cD027, uint8 *cD800)
{
	c64d_get_vic_colors(cD021, cD022, cD023, cD025, cD026, cD027, cD800);
}


void C64DebugInterfaceVice::GetVICSpriteColors(uint8 *cD021, uint8 *cD025, uint8 *cD026, uint8 *spriteColors)
{
	SYS_FatalExit("C64DebugInterfaceVice::GetVICSpriteColors: not implemented");
}

void C64DebugInterfaceVice::GetCBMColor(uint8 colorNum, uint8 *r, uint8 *g, uint8 *b)
{
	*r = c64d_palette_red[colorNum];
	*g = c64d_palette_green[colorNum];
	*b = c64d_palette_blue[colorNum];
}

void C64DebugInterfaceVice::GetFloatCBMColor(uint8 colorNum, float *r, float *g, float *b)
{
	*r = c64d_float_palette_red[colorNum];
	*g = c64d_float_palette_green[colorNum];
	*b = c64d_float_palette_blue[colorNum];
}



void C64DebugInterfaceVice::SetDebugMode(uint8 debugMode)
{
	//LOGD("C64DebugInterfaceVice::SetDebugMode: %d", debugMode);
	
	c64d_set_debug_mode(debugMode);
	
}

uint8 C64DebugInterfaceVice::GetDebugMode()
{
	return c64d_debug_mode;
}


// http://www.lemon64.com/?mainurl=http%3A//www.lemon64.com/apps/list.php%3FGenre%3Dcarts

extern "C" {
	int cartridge_attach_image(int type, const char *filename);
	void cartridge_detach_image(int type);
	void cartridge_trigger_freeze(void);
}

static void cartridge_attach_trap(WORD addr, void *v)
{
	char *filePath = (char*)v;
	cartridge_attach_image(0, filePath);
	
	SYS_ReleaseCharBuf(filePath);

}

static void cartridge_detach_trap(WORD addr, void *v)
{
	// -1 means all slots
	cartridge_detach_image(-1);
}


void C64DebugInterfaceVice::AttachCartridge(CSlrString *filePath)
{
	char *asciiPath = filePath->GetStdASCII();
	
	FixFileNameSlashes(asciiPath);

//	this->SetDebugMode(C64_DEBUG_RUN_ONE_INSTRUCTION);
//	SYS_Sleep(5000);
	
//	gSoundEngine->LockMutex("C64DebugInterfaceVice::CartridgeAttach");
//	debugInterfaceVice->LockMutex();
//	guiMain->LockMutex();

	
	cartridge_attach_image(0, asciiPath);

	
//	guiMain->UnlockMutex();
//	debugInterfaceVice->UnlockMutex();
//	gSoundEngine->UnlockMutex("C64DebugInterfaceVice::CartridgeAttach");


//	char *buf = SYS_GetCharBuf();
//	strcpy(buf, filePath);
//	interrupt_maincpu_trigger_trap(cartridge_attach_trap, buf);
	
//	SYS_Sleep(1000);
//	this->SetDebugMode(C64_DEBUG_RUNNING);
}

void C64DebugInterfaceVice::DetachCartridge()
{
	interrupt_maincpu_trigger_trap(cartridge_detach_trap, NULL);
}

void C64DebugInterfaceVice::CartridgeFreezeButtonPressed()
{
	keyboard_clear_keymatrix();
	cartridge_trigger_freeze();
}

extern "C" {
	void c64d_get_exrom_game(BYTE *exrom, BYTE *game);
}

void C64DebugInterfaceVice::GetC64CartridgeState(C64StateCartridge *cartridgeState)
{
	c64d_get_exrom_game(&(cartridgeState->exrom), &(cartridgeState)->game);
}

extern "C" {
	void c64d_c64_set_vicii_record_state_mode(uint8 recordMode);
}

void C64DebugInterfaceVice::SetVicRecordStateMode(uint8 recordMode)
{
	c64d_c64_set_vicii_record_state_mode(recordMode);
}

/// render states
extern "C" {
	const char *fetch_phi1_type(int addr);
	BYTE c64d_ciacore_peek(cia_context_t *cia_context, WORD addr);
}

// TODO: change all %02x %04x into sprintfHexCode8WithoutZeroEnding(bufPtr, ...);

void C64DebugInterfaceVice::RenderStateVIC(vicii_cycle_state_t *viciiState,
										   float posX, float posY, float posZ, bool isVertical, bool showSprites, CSlrFont *fontBytes, float fontSize,
										   std::vector<CImageData *> *spritesImageData,
										   std::vector<CSlrImage *> *spritesImages, bool renderDataWithColors)
{
	static const char *mode_name[] =
	{
		"Standard Text",
		"Multicolor Text",
		"Hires Bitmap",
		"Multicolor Bitmap",
		"Extended Text",
		"Illegal Text",
		"Invalid Bitmap 1",
		"Invalid Bitmap 2"
	};

	char buf[256];
	char buf2[256];
	float px = posX;
	float py = posY;

	int video_mode, m_mcm, m_bmm, m_ecm, v_bank, v_vram;
	int i, bits, bits2;
	
	video_mode = ((viciiState->regs[0x11] & 0x60) | (viciiState->regs[0x16] & 0x10)) >> 4;
	
	m_ecm = (video_mode & 4) >> 2;  /* 0 standard, 1 extended */
	m_bmm = (video_mode & 2) >> 1;  /* 0 text, 1 bitmap */
	m_mcm = video_mode & 1;         /* 0 hires, 1 multi */
	
	v_bank = viciiState->vbank_phi1;
	
//	sprintf(buf, "Raster cycle/line: %d/%d IRQ: %d", viciiState->raster_cycle, viciiState->raster_line, viciiState->raster_irq_line);
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	if (isVertical == false)
	{
		sprintf(buf, "Raster line       : %04x", viciiState->raster_line);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	}

	sprintf(buf, "IRQ raster line   : %04x", viciiState->raster_irq_line);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
//	if (isVertical == false)
//	{
//		uint8 irqFlags = viciiState->irq_status;// | 0x70;
//		sprintf(buf, "Interrupt status  : "); PrintVicInterrupts(irqFlags, buf);
//		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	}
	uint8 irqMask = viciiState->regs[0x1a];
	sprintf(buf, "Enabled interrupts: "); PrintVicInterrupts(irqMask, buf);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

//	sprintf(buf, "Scroll X/Y: %d/%d, RC %d, Idle: %d, %dx%d", viciiState->regs[0x16] & 0x07, viciiState->regs[0x11] & 0x07,
//			viciiState->rc, viciiState->idle_state,
//			39 + ((viciiState->regs[0x16] >> 3) & 1), 24 + ((viciiState->regs[0x11] >> 3) & 1));
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	

	sprintf(buf, "X scroll          : %d", viciiState->regs[0x16] & 0x07);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, "Y scroll          : %d", viciiState->regs[0x11] & 0x07);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "Border            : %dx%d", 39 + ((viciiState->regs[0x16] >> 3) & 1), 24 + ((viciiState->regs[0x11] >> 3) & 1));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	if (showSprites == true)
	{
		py += fontSize * 0.5f;
	}
	else
	{
		py = posY;
		px = posX + fontSize * 29.0f;
	}
	
	
	sprintf(buf, "Display mode      : %s", mode_name[video_mode]);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	sprintf(buf, "Mode: %s (ECM/BMM/MCM=%d/%d/%d)", mode_name[video_mode], m_ecm, m_bmm, m_mcm);
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "Sequencer state   : %s", viciiState->idle_state ? "Display" : "Idle");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "Row counter       : %d", viciiState->rc);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	const int FIRST_DMA_LINE = 0x30;
	const int LAST_DMA_LINE = 0xf7;
	uint8 yScroll = viciiState->regs[0x11] & 0x07;
	bool isBadLine = viciiState->raster_line >= FIRST_DMA_LINE && viciiState->raster_line <= LAST_DMA_LINE && ((viciiState->raster_line & 7) == yScroll);

	
	sprintf(buf, "Bad line state    : %s", isBadLine ? "Yes" : "No");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "VC %03x VCBASE %03x VMLI %2d Phi1 %02x", viciiState->vc, viciiState->vcbase, viciiState->vmli, viciiState->last_read_phi1);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

//	sprintf(buf, "Colors: Border: %x BG: %x ", viciiState->regs[0x20], viciiState->regs[0x21]);
//	if (m_ecm)
//	{
//		sprintf(buf2, "BG1: %x BG2: %x BG3: %x\n", viciiState->regs[0x22], viciiState->regs[0x23], viciiState->regs[0x24]);
//		strcat(buf, buf2);
//	}
//	else if (m_mcm && !m_bmm)
//	{
//		sprintf(buf2, "MC1: %x MC2: %x\n", viciiState->regs[0x22], viciiState->regs[0x23]);
//		strcat(buf, buf2);
//	}
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	
	v_vram = ((viciiState->regs[0x18] >> 4) * 0x0400) + viciiState->vbank_phi2;
	
	if (isVertical == false)
	{
		sprintf(buf, "Video base        : %04x, ", v_vram);
		if (m_bmm)
		{
			i = ((viciiState->regs[0x18] >> 3) & 1) * 0x2000 + v_bank;
			sprintf(buf2, "Bitmap  %04x (%s)", i, fetch_phi1_type(i));
			strcat(buf, buf2);
		}
		else
		{
			i = (((viciiState->regs[0x18] >> 1) & 0x7) * 0x0800) + v_bank;
			sprintf(buf2, "Charset %04x (%s)", i, fetch_phi1_type(i));
			strcat(buf, buf2);
		}
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	}
	else
	{
		sprintf(buf, "Video base        : %04x", v_vram);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		if (m_bmm)
		{
			i = ((viciiState->regs[0x18] >> 3) & 1) * 0x2000 + v_bank;
			sprintf(buf, "            Bitmap: %04x (%s)", i, fetch_phi1_type(i));
		}
		else
		{
			i = (((viciiState->regs[0x18] >> 1) & 0x7) * 0x800) + v_bank;
			sprintf(buf, "           Charset: %04x (%s)", i, fetch_phi1_type(i));
		}
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	}
	
	py += fontSize * 0.5f;

	
	if (showSprites)
	{
		/// sprites
		int numPasses = 1;
		int step = 8;
		
		if (isVertical)
		{
			numPasses = 2;
			step = 4;
		}
		
	 // get VIC sprite colors
		uint8 cD021 = viciiState->regs[0x21];
		uint8 cD025 = viciiState->regs[0x25];
		uint8 cD026 = viciiState->regs[0x26];
		
		float fss = fontSize * 0.25f;
		
		//bool isEnabled[8] = { false };
		for (int passNum = 0; passNum < numPasses; passNum++)
		{
			int startId = passNum * step;
			int endId = (passNum+1) * step;
			
			sprintf(buf, "         ");
			
			if (isVertical)
			{
				for (int z = startId; z < endId; z++)
				{
					sprintf(buf2, "#%d    ", z);
					strcat(buf, buf2);
				}
				fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			}
			else
			{
				for (int z = startId; z < endId; z++)
				{
					sprintf(buf2, "%d     ", z);
					strcat(buf, buf2);
				}
				fontBytes->BlitText(buf, px, py-fss, posZ, fontSize); py += fontSize;
			}
			
			sprintf(buf, "Enabled: ");
			bits = viciiState->regs[0x15];
			for (i = startId; i < endId; i++)
			{
				/*
				if (((bits >> i) & 1))
				{
					isEnabled[i] = true;
				}
				else
				{
					isEnabled[i] = false;
				}
				*/
				
				sprintf(buf2, "%s", ((bits >> i) & 1) ? "Yes   " : "No    ");
				strcat(buf, buf2);
			}
			
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			/////////////"         "
			sprintf(buf, "DMA/dis: ");
			bits = viciiState->sprite_dma;
			bits2 = viciiState->sprite_display_bits;
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%c/%c   ", ((bits >> i) & 1) ? 'D' : ' ', ((bits2 >> i) & 1) ? 'd' : ' ');
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			/////////////"         "
			sprintf(buf, "Pointer: ");
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%02x    ", viciiState->sprite[i].pointer);
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			
			/////////////"         "
			sprintf(buf, "MC:      ");
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%02x    ", viciiState->sprite[i].mc);
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			/////////////"         "
			if (isVertical == false)
			{
				sprintf(buf, "MCBASE:  ");
				for (i = startId; i < endId; i++)
				{
					sprintf(buf2, "%02x    ", viciiState->sprite[i].mcbase);
					strcat(buf, buf2);
				}
				fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			}
			
			/////////////"         "
			sprintf(buf, "X-Pos:   ");
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%-4d  ", viciiState->sprite[i].x);
				
				/*
				int x = viciiState->regs[0 + (i << 1)];
				
				bits = viciiState->regs[0x10];
				int e = ((bits >> i) & 1);
				
				if (e != 0)
				{
					x += 256;
				}
				LOGD(" .. #%d s.x=%d x=%d", i, viciiState->sprite[i].x, x);
				*/
				
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			
			/////////////"         "
			sprintf(buf, "Y-Pos:   ");
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%-4d  ", viciiState->regs[1 + (i << 1)]);
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			/////////////"         "
			sprintf(buf, "X-Exp:   ");
			bits = viciiState->regs[0x1d];
			
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%s", ((bits >> i) & 1) ? "Yes   " : "No    ");
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			/////////////"         "
			sprintf(buf, "Y-Exp:   ");
			bits = viciiState->regs[0x17];
			
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%s", ((bits >> i) & 1) ? (viciiState->sprite[i].exp_flop ? "YES*  " : "Yes   ") : "No    ");
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			sprintf(buf, "Mode   : ");
			bits = viciiState->regs[0x1c];
			for (i = startId; i < endId; i++)
			{
				sprintf(buf2, "%s", ((bits >> i) & 1) ? "Multi " : "Std.  ");
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			sprintf(buf, "Prio.  : ");
			bits = viciiState->regs[0x1b];
			for (int z = startId; z < endId; z++)
			{
				sprintf(buf2, "%s", ((bits >> i) & 1) ? "Back  " : "Fore  ");
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			sprintf(buf, "Data   : ");
			for (int z = startId; z < endId; z++)
			{
				int addr = v_bank + viciiState->sprite[z].pointer * 64;
				sprintf(buf2, "%04x  ", addr);
				strcat(buf, buf2);
			}
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			py += fontSize * 0.25f;
			
			
			//
			// draw sprites
			//
			px += 9*fontSize;
			
			const float spriteSizeX = 6*fontSize;
			const float spriteSizeY = (21.0f * spriteSizeX) / 24.0f;
			
			// sprites are rendered upside down
			const float spriteTexStartX = 4.0/32.0;
			const float spriteTexStartY = (32.0-4.0)/32.0;
			const float spriteTexEndX = (4.0+24.0)/32.0;
			const float spriteTexEndY = (32.0-(4.0+21.0))/32.0;
			
			//
			
			for (int zi = startId; zi < endId; zi++)
			{
				CSlrImage *image = (*spritesImages)[zi];
				CImageData *imageData = (*spritesImageData)[zi];
				
				int addr = v_bank + viciiState->sprite[zi].pointer * 64;
				
				//LOGD("sprite#=%d dataAddr=%04x", zi, addr);
				uint8 spriteData[63];
				
				for (int i = 0; i < 63; i++)
				{
					uint8 v;
					this->dataAdapterC64DirectRam->AdapterReadByte(addr, &v);
					spriteData[i] = v;
					addr++;
				}
				
				bool isColor = false;
				if (viciiState->regs[0x1c] & (1<<zi))
				{
					isColor = true;
				}
				if (isColor == false)
				{
					if (renderDataWithColors)
					{
						uint8 spriteColor = viciiState->regs[0x27+zi];
						ConvertSpriteDataToImage(spriteData, imageData, cD021, spriteColor, this, 4);
					}
					else
					{
						ConvertSpriteDataToImage(spriteData, imageData, 4);
					}
				}
				else
				{
					uint8 spriteColor = viciiState->regs[0x27+zi];
					ConvertColorSpriteDataToImage(spriteData, imageData, cD021, cD025, cD026, spriteColor, this, 4);
				}
				
				// re-bind image
				image->ReplaceImageData(imageData);
				
				// render image
				//BlitRectangle(px, py, posZ, 32, 32, 0.5, 0.5, 1.0f, 1.0f);
				
				Blit(image, px, py, posZ, spriteSizeX, spriteSizeY, spriteTexStartX, spriteTexStartY, spriteTexEndX, spriteTexEndY);
				px += spriteSizeX;
			}
			
			px = posX;
			py += 5.5f*fontSize;
		}
	}	
}

void C64DebugInterfaceVice::PrintVicInterrupts(uint8 flags, char *buf)
{
	if (flags & 0x1F)
	{
		if (flags & 0x01) strcat(buf, "Raster ");
		if (flags & 0x02) strcat(buf, "Spr-Data ");
		if (flags & 0x04) strcat(buf, "Spr-Spr ");
		if (flags & 0x08) strcat(buf, "Lightpen");
	}
	else
	{
		strcat(buf, "None");
	}
}

void C64DebugInterfaceVice::UpdateVICSpritesImages(vicii_cycle_state_t *viciiState,
										   std::vector<CImageData *> *spritesImageData,
										   std::vector<CSlrImage *> *spritesImages, bool renderDataWithColors)
{
	int v_bank = viciiState->vbank_phi1;
	uint8 cD021 = viciiState->regs[0x21];
	uint8 cD025 = viciiState->regs[0x25];
	uint8 cD026 = viciiState->regs[0x26];

	for (int zi = 0; zi < 8; zi++)
	{
		CSlrImage *image = (*spritesImages)[zi];
		CImageData *imageData = (*spritesImageData)[zi];
		
		int addr = v_bank + viciiState->sprite[zi].pointer * 64;
		
		//LOGD("sprite#=%d dataAddr=%04x", zi, addr);
		uint8 spriteData[63];
		
		for (int i = 0; i < 63; i++)
		{
			uint8 v;
			this->dataAdapterC64DirectRam->AdapterReadByte(addr, &v);
			spriteData[i] = v;
			addr++;
		}
		
		bool isColor = false;
		if (viciiState->regs[0x1c] & (1<<zi))
		{
			isColor = true;
		}
		if (isColor == false)
		{
			if (renderDataWithColors)
			{
				uint8 spriteColor = viciiState->regs[0x27+zi];
				ConvertSpriteDataToImage(spriteData, imageData, cD021, spriteColor, this, 4);
			}
			else
			{
				ConvertSpriteDataToImage(spriteData, imageData, 4);
			}
		}
		else
		{
			uint8 spriteColor = viciiState->regs[0x27+zi];
			ConvertColorSpriteDataToImage(spriteData, imageData, cD021, cD025, cD026, spriteColor, this, 4);
		}
		
		// re-bind image
		image->ReplaceImageData(imageData);		
	}
}

void C64DebugInterfaceVice::RenderStateCIA(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId)
{
	char buf[256];
	cia_context_t *cia_context;
	
	if (ciaId == 1)
	{
		cia_context = machine_context.cia1;
	}
	else
	{
		cia_context = machine_context.cia2;
	}
	
	uint8 cra = c64d_ciacore_peek(cia_context, 0x0e);

	sprintf(buf, "CIA %d:", ciaId);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "ICR: %02x CTRLA: %02x CTRLB: %02x",
			c64d_ciacore_peek(cia_context, 0x0d), c64d_ciacore_peek(cia_context, 0x0e), c64d_ciacore_peek(cia_context, 0x0f));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	sprintf(buf, "Port A:  %02x DDR: %02x", c64d_ciacore_peek(cia_context, 0x00), c64d_ciacore_peek(cia_context, 0x02));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, "Port B:  %02x DDR: %02x", c64d_ciacore_peek(cia_context, 0x01), c64d_ciacore_peek(cia_context, 0x03));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	sprintf(buf, "Serial data : %02x %s", c64d_ciacore_peek(cia_context, 0x0c), cra & 0x40 ? "Output" : "Input");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	sprintf(buf, "Timer A  : %s", cra & 1 ? "On" : "Off");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Counter : %04x", c64d_ciacore_peek(cia_context, 0x04) + (c64d_ciacore_peek(cia_context, 0x05) << 8));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Run mode: %s", cra & 8 ? "One-shot" : "Continuous");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Input   : %s", cra & 0x20 ? "CNT" : "Phi2");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Output  : ");
	if (cra & 2)
		if (cra & 4)
			strcat(buf, "PB6 Toggle");
		else
			strcat(buf, "PB6 Pulse");
		else
			strcat(buf, "None");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	//py+=fontSize;
	
	
//	sprintf(buf, "Timer B  : %s", crb & 1 ? "On" : "Off");
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	sprintf(buf, " Counter : %04x", c64d_ciacore_peek(cia_context, 0x06) + (c64d_ciacore_peek(cia_context, 0x07) << 8));
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	sprintf(buf, " Run mode: %s", crb & 8 ? "One-shot" : "Continuous");
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	sprintf(buf, " Input   : ");
//	if (crb & 0x40)
//		if (crb & 0x20)
//			strcat(buf, "Timer A underflow (CNT high)");
//		else
//			strcat(buf, "Timer A underflow");
//		else
//			if (crb & 0x20)
//				strcat(buf, "CNT");
//			else
//				strcat(buf, "Phi2");
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
//	
//	sprintf(buf, " Output  : ");
//	if (crb & 2)
//		if (crb & 4)
//			strcat(buf, "PB7 Toggle");
//		else
//			strcat(buf, "PB7 Pulse");
//		else
//			strcat(buf, "None");
//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

	
	uint8 tod_hr = c64d_ciacore_peek(cia_context, 0x0b);
	uint8 tod_min = c64d_ciacore_peek(cia_context, 0x0a);
	uint8 tod_sec = c64d_ciacore_peek(cia_context, 0x09);
	uint8 tod_10ths = c64d_ciacore_peek(cia_context, 0x08);
	
	sprintf(buf, "TOD      : %1.1x%1.1x:%1.1x%1.1x:%1.1x%1.1x.%1.1x %s",
			(tod_hr >> 4) & 1, tod_hr & 0x0f,
			(tod_min >> 4) & 7, tod_min & 0x0f,
			(tod_sec >> 4) & 7, tod_sec & 0x0f,
			tod_10ths & 0x0f, tod_hr & 0x80 ? "PM" : "AM");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	
	py += fontSize;

}

void C64DebugInterfaceVice::RenderStateSID(uint16 sidBase, float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize)
{
	char buf[256];
	float px = posX;
	float py = posY;
	
	uint8 reg_freq_lo, reg_freq_hi, reg_pw_lo, reg_pw_hi, reg_ad, reg_sr, reg_ctrl, reg_res_filter, reg_volume, reg_filter_lo, reg_filter_hi;
	
	reg_res_filter = sid_peek(sidBase + 0x17);
	reg_volume  = sid_peek(sidBase + 0x18);
	reg_filter_lo = sid_peek(sidBase + 0x15);
	reg_filter_hi = sid_peek(sidBase + 0x16);
	
	
	for (int voice = 0; voice < 3; voice++)
	{
		uint16 voiceBase = sidBase + voice * 0x07;
		
		reg_freq_lo = sid_peek(voiceBase + 0x00);
		reg_freq_hi = sid_peek(voiceBase + 0x01);
		reg_pw_lo = sid_peek(voiceBase + 0x02);
		reg_pw_hi = sid_peek(voiceBase + 0x03);
		reg_ctrl = sid_peek(voiceBase + 0x04);
		reg_ad = sid_peek(voiceBase + 0x05);
		reg_sr = sid_peek(voiceBase + 0x06);
		
		uint16 freq = (reg_freq_hi << 8) | reg_freq_lo;
		
		const sid_frequency_t *sidFrequencyData = SidValueToNote(freq);
		
		
		sprintf(buf, "Voice #%d", (voice+1));
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		sprintf(buf, " Frequency  : %04x %s", freq, sidFrequencyData->name);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		sprintf(buf, " Pulse Width: %04x", ((reg_pw_hi & 0x0f) << 8) | reg_pw_lo);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		sprintf(buf, " Env. (ADSR): %1.1x %1.1x %1.1x %1.1x",
				reg_ad >> 4, reg_ad & 0x0f,
				reg_sr >> 4, reg_sr & 0x0f);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		sprintf(buf, " Waveform   : ");
		PrintSidWaveform(reg_ctrl, buf);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		sprintf(buf, " Gate       : %s  Ring mod.: %s", reg_ctrl & 0x01 ? "On " : "Off", reg_ctrl & 0x04 ? "On" : "Off");
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		sprintf(buf, " Test bit   : %s  Synchron.: %s", reg_ctrl & 0x08 ? "On " : "Off", reg_ctrl & 0x02 ? "On" : "Off");
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		if (voice == 2)
		{
			sprintf(buf, " Filter     : %s  Mute     : %s", reg_res_filter & (1 << voice) ? "On" : "Off", reg_volume & 0x80 ? "Yes" : "No");
		}
		else
		{
			sprintf(buf, " Filter     : %s", reg_res_filter & (1 << voice) ? "On " : "Off");
		}
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		py += fontSize;
	}
	
	sprintf(buf, "Filters/Volume");
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Frequency: %04x", (reg_filter_hi << 3) | (reg_filter_lo & 0x07));
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Resonance: %1.1x", reg_res_filter >> 4);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Mode     : ");
	if (reg_volume & 0x70)
	{
		if (reg_volume & 0x10) strcat(buf, "LP ");
		if (reg_volume & 0x20) strcat(buf, "BP ");
		if (reg_volume & 0x40) strcat(buf, "HP");
	}
	else
	{
		strcat(buf, "None");
	}
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
	sprintf(buf, " Volume   : %1.1x", reg_volume & 0x0f);
	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
}

void C64DebugInterfaceVice::PrintSidWaveform(uint8 wave, char *buf)
{
	if (wave & 0xf0) {
		if (wave & 0x10) strcat(buf, "Triangle ");
		if (wave & 0x20) strcat(buf, "Sawtooth ");
		if (wave & 0x40) strcat(buf, "Rectangle ");
		if (wave & 0x80) strcat(buf, "Noise");
	} else
		strcat(buf, "None");
}

void C64DebugInterfaceVice::SetSIDMuteChannels(bool mute1, bool mute2, bool mute3, bool muteExt)
{
	uint8 sidVoiceMask = 0xF0;
	
	if (mute1 == false)
	{
		sidVoiceMask |= 0x01;
	}
	if (mute2 == false)
	{
		sidVoiceMask |= 0x02;
	}
	if (mute3 == false)
	{
		sidVoiceMask |= 0x04;
	}
	if (muteExt == false)
	{
		sidVoiceMask |= 0x08;
	}

	sid_set_voice_mask(0, sidVoiceMask);

}

void C64DebugInterfaceVice::SetSIDReceiveChannelsData(bool isReceiving)
{
	if (isReceiving)
	{
		c64d_sid_receive_channels_data(1);
	}
	else
	{
		c64d_sid_receive_channels_data(0);
	}
}



// snapshots
bool C64DebugInterfaceVice::LoadFullSnapshot(CByteBuffer *snapshotBuffer)
{
	SYS_FatalExit("C64DebugInterfaceVice::LoadFullSnapshot: not implemented");
	return true;
}

void C64DebugInterfaceVice::SaveFullSnapshot(CByteBuffer *snapshotBuffer)
{
	SYS_FatalExit("C64DebugInterfaceVice::LoadFullSnapshot: not implemented");
}

void c64d_update_c64_model()
{
	int modelType = c64model_get();
	c64d_update_c64_machine_from_model_type(modelType);
	c64d_update_c64_screen_height_from_model_type(modelType);

}

void c64d_update_c64_machine_from_model_type(int modelType)
{
	switch(c64_change_model_type)
	{
		default:
		case 0:
		case 1:
		case 2:
		case 6:
		case 7:
		case 11:
			// PAL, 312 lines
			debugInterfaceVice->machineType = C64_MACHINE_PAL;
			break;
		case 3:
		case 4:
		case 5:
		case 8:
		case 12:
			// NTSC, 275 lines
			debugInterfaceVice->machineType = C64_MACHINE_NTSC;
			break;
	}
	
}

void c64d_update_c64_screen_height_from_model_type(int modelType)
{
	switch(c64_change_model_type)
	{
		default:
		case 0:
		case 1:
		case 2:
		case 6:
		case 7:
		case 11:
			// PAL, 312 lines
			debugInterfaceVice->screenHeight = 272;
			break;
		case 3:
		case 4:
		case 5:
		case 8:
		case 12:
			// NTSC, 275 lines
			debugInterfaceVice->screenHeight = 259;
			break;
	}
	
}

static void load_snapshot_trap(WORD addr, void *v)
{
	LOGD("load_snapshot_trap");
	
	char *filePath = (char*)v;
	//int ret =

	FILE *fp = fopen(filePath, "rb");
	if (!fp)
	{
		guiMain->ShowMessage("Snapshot not found");
		return;
	}
	fclose(fp);
	
	gSoundEngine->LockMutex("load_snapshot_trap");

	if (c64_snapshot_read(filePath, 0) < 0)
	{
		guiMain->ShowMessage("Snapshot loading failed");
		
		debugInterfaceVice->machineType = C64_MACHINE_UNKNOWN;
		debugInterfaceVice->screenHeight = 0;
		
		c64d_clear_screen();
	}
	else
	{
		// if CPU is in JAM then un-jam and continue
		if (c64d_is_cpu_in_jam_state == 1)
		{
			c64d_is_cpu_in_jam_state = 0;
			c64d_set_debug_mode(C64_DEBUG_RUNNING);
		}
	}
	
	debugInterfaceVice->SetSidType(c64SettingsSIDEngineModel);
	debugInterfaceVice->SetSidSamplingMethod(c64SettingsRESIDSamplingMethod);
	debugInterfaceVice->SetSidEmulateFilters(c64SettingsRESIDEmulateFilters);
	debugInterfaceVice->SetSidPassBand(c64SettingsRESIDPassBand);
	debugInterfaceVice->SetSidFilterBias(c64SettingsRESIDFilterBias);

	gSoundEngine->UnlockMutex("load_snapshot_trap");
	
	SYS_ReleaseCharBuf(filePath);
}


bool C64DebugInterfaceVice::LoadFullSnapshot(char *filePath)
{
	char *buf = SYS_GetCharBuf();
	strcpy(buf, filePath);
	
	this->machineType = C64_MACHINE_LOADING_SNAPSHOT;
	
	interrupt_maincpu_trigger_trap(load_snapshot_trap, buf);
	
	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	{
		c64d_set_debug_mode(C64_DEBUG_RUN_ONE_INSTRUCTION);
	}
	
	return true;
}

static void save_snapshot_trap(WORD addr, void *v)
{
	LOGD("save_snapshot_trap");
	
	char *filePath = (char*)v;
	
	gSoundEngine->LockMutex("save_snapshot_trap");
	
	c64_snapshot_write(filePath, 0, 1, 0);
	
	gSoundEngine->UnlockMutex("save_snapshot_trap");
	
	SYS_ReleaseCharBuf(filePath);
}

void C64DebugInterfaceVice::SaveFullSnapshot(char *filePath)
{
	//	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	//	{
	//		// can we?
	//		c64_snapshot_write(filePath, 0, 1, 0);
	//	}
	//	else
	{
		char *buf = SYS_GetCharBuf();
		strcpy(buf, filePath);
		interrupt_maincpu_trigger_trap(save_snapshot_trap, buf);
	}
	
	if (c64d_debug_mode == C64_DEBUG_PAUSED)
	{
		c64d_set_debug_mode(C64_DEBUG_RUN_ONE_INSTRUCTION);
	}
}





extern "C" {
	BYTE c64d_via1d1541_peek(drive_context_t *ctxptr, WORD addr);
	BYTE c64d_via2d_peek(drive_context_t *ctxptr, WORD addr);
};

#define VIA_PRB         0  /* Port B */
#define VIA_PRA         1  /* Port A */
#define VIA_DDRB        2  /* Data direction register for port B */
#define VIA_DDRA        3  /* Data direction register for port A */

#define VIA_T1CL        4  /* Timer 1 count low */
#define VIA_T1CH        5  /* Timer 1 count high */
#define VIA_T1LL        6  /* Timer 1 latch low */
#define VIA_T1LH        7  /* Timer 1 latch high */
#define VIA_T2CL        8  /* Timer 2 count low - read only */
#define VIA_T2LL        8  /* Timer 2 latch low - write only */
#define VIA_T2CH        9  /* Timer 2 latch/count high */

#define VIA_SR          10 /* Serial port shift register */
#define VIA_ACR         11 /* Auxiliary control register */
#define VIA_PCR         12 /* Peripheral control register */

#define VIA_IFR         13 /* Interrupt flag register */
#define VIA_IER         14 /* Interrupt control register */

void C64DebugInterfaceVice::RenderStateDrive1541(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize,
												 bool renderVia1, bool renderVia2, bool renderDriveLed,
												 bool isVertical)
{
	char buf[256];
	float px = posX;
	float py = posY;
	byte v1, v2;
	byte counterlo;
	byte counterhi;
	byte latchlo;
	byte latchhi;
	
	if (renderVia1)
	{
		sprintf(buf, "VIA 1:");
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		v1 = c64d_via1d1541_peek(drive_context[0], 0x1800);
		v2 = c64d_via1d1541_peek(drive_context[0], 0x1801);
		sprintf(buf, " PRB: %02x PRA: %02x", v1, v2);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		
		counterlo = c64d_via1d1541_peek(drive_context[0], 0x1804);
		counterhi = c64d_via1d1541_peek(drive_context[0], 0x1805);
		latchlo = c64d_via1d1541_peek(drive_context[0], 0x1806);
		latchhi = c64d_via1d1541_peek(drive_context[0], 0x1807);
		sprintf(buf, " Timer Counter: %02x%02x", counterhi, counterlo); // Latch: %02x%02x", counterhi, counterlo, latchlo, latchhi);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		//	counterlo = c64d_via1d1541_peek(drive_context[0], 0x1804);
		//	counterhi = c64d_via1d1541_peek(drive_context[0], 0x1805);
		//	sprintf(buf, " Timer 2 Counter: %02x%02x", counterhi, counterlo);
		//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;

		v1 = c64d_via1d1541_peek(drive_context[0], 0x180B);
		v2 = c64d_via1d1541_peek(drive_context[0], 0x180C);
		
		if (isVertical)
		{
			sprintf(buf, " ACR: %02x PCR: %02x", v1, v2);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		}
		else
		{
			sprintf(buf, " ACR: %02x", v1);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			sprintf(buf, " PCR: %02x", v2);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		}
		
		v1 = c64d_via1d1541_peek(drive_context[0], 0x180D);
		v2 = c64d_via1d1541_peek(drive_context[0], 0x180E);
		sprintf(buf, " IFR: %02x IER: %02x", v1, v2);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		
		//	TODO: pending interrupts & enabled interrupts
		
		
		if (isVertical)
		{
		}
		else
		{
			py = posY;
			px = posX + 120;
		}
	}
	
	if (renderVia2)
	{
		sprintf(buf, "VIA 2:");
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		v1 = c64d_via2d_peek(drive_context[0], 0x1C00);
		v2 = c64d_via2d_peek(drive_context[0], 0x1C01);
		sprintf(buf, " PRB: %02x PRA: %02x", v1, v2);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		
		counterlo = c64d_via2d_peek(drive_context[0], 0x1C04);
		counterhi = c64d_via2d_peek(drive_context[0], 0x1C05);
		latchlo = c64d_via2d_peek(drive_context[0], 0x1C06);
		latchhi = c64d_via2d_peek(drive_context[0], 0x1C07);
		sprintf(buf, " Timer Counter: %02x%02x", counterhi, counterlo); // Latch: %02x%02x", counterhi, counterlo, latchlo, latchhi);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		//	counterlo = c64d_via2d_peek(drive_context[0], 0x1C04);
		//	counterhi = c64d_via2d_peek(drive_context[0], 0x1C05);
		//	sprintf(buf, " Timer 2 Counter: %02x%02x", counterhi, counterlo);
		//	fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
		v1 = c64d_via2d_peek(drive_context[0], 0x1C0B);
		v2 = c64d_via2d_peek(drive_context[0], 0x1C0C);

		if (isVertical)
		{
			sprintf(buf, " ACR: %02x PCR: %02x", v1, v2);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		}
		else
		{
			sprintf(buf, " ACR: %02x", v1);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
			
			sprintf(buf, " PCR: %02x", v2);
			fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		}
		
		
		v1 = c64d_via2d_peek(drive_context[0], 0x1C0D);
		v2 = c64d_via2d_peek(drive_context[0], 0x1C0E);
		sprintf(buf, " IFR: %02x IER: %02x", v1, v2);
		fontBytes->BlitText(buf, px, py, posZ, fontSize); py += fontSize;
		
	}
	
	if (renderDriveLed)
	{
		px = posX;
		py += fontSize;
		fontBytes->BlitText("Drive LED: ", px, py, posZ, fontSize);
		
		float ledSizeX = fontSize*4.0f;
		float gap = fontSize * 0.1f;
		float ledSizeY = fontSize + gap + gap;

		float ledX = px + fontSize * 12.0f;
		float ledY = py - gap;

		float color = this->ledState[0];
		
		BlitFilledRectangle(ledX, ledY, posZ, ledSizeX, ledSizeY,
							0.0f, color, 0.0f, 1.0f);
		BlitRectangle(ledX, py - gap, posZ, ledSizeX, ledSizeY,
					  0.3f, 0.3f, 0.3f, 1.0f, gap);
	}
	
}

/// default keymap
void ViceKeyMapInitDefault()
{
	SYS_FatalExit("ViceKeyMapInitDefault");
	
	
//	 C64 keyboard matrix:
//	 
//	 Bit   7   6   5   4   3   2   1   0
//	 0    CUD  F5  F3  F1  F7 CLR RET DEL
//	 1    SHL  E   S   Z   4   A   W   3
//	 2     X   T   F   C   6   D   R   5
//	 3     V   U   H   B   8   G   Y   7
//	 4     N   O   K   M   0   J   I   9
//	 5     ,   @   :   .   -   L   P   +
//	 6     /   ^   =  SHR HOM  ;   *   £
//	 7    R/S  Q   C= SPC  2  CTL  <-  1
	
	// MATRIX (row, column)
	
	// http://classiccmp.org/dunfield/c64/h/front.jpg
	
	//	keyboard_parse_set_pos_row('a', int row, int col, int shift);
	
	/*
	
	keyboard_parse_set_pos_row(MTKEY_F5, 0, 6, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F6, 0, 6, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F3, 0, 5, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F4, 0, 5, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F1, 0, 4, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F2, 0, 4, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F7, 0, 3, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_F8, 0, 3, LEFT_SHIFT);
	
	keyboard_parse_set_pos_row(MTKEY_ENTER, 0, 1, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_BACKSPACE, 0, 0, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_LSHIFT, 1, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('e', 1, 6, NO_SHIFT);
	keyboard_parse_set_pos_row('s', 1, 5, NO_SHIFT);
	keyboard_parse_set_pos_row('z', 1, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('4', 1, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('a', 1, 2, NO_SHIFT);
	keyboard_parse_set_pos_row('w', 1, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('3', 1, 0, NO_SHIFT);
	keyboard_parse_set_pos_row('x', 2, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('t', 2, 6, NO_SHIFT);
	keyboard_parse_set_pos_row('f', 2, 5, NO_SHIFT);
	keyboard_parse_set_pos_row('c', 2, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('6', 2, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('d', 2, 2, NO_SHIFT);
	keyboard_parse_set_pos_row('r', 2, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('5', 2, 0, NO_SHIFT);
	keyboard_parse_set_pos_row('v', 3, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('u', 3, 6, NO_SHIFT);
	keyboard_parse_set_pos_row('h', 3, 5, NO_SHIFT);
	keyboard_parse_set_pos_row('b', 3, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('8', 3, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('g', 3, 2, NO_SHIFT);
	keyboard_parse_set_pos_row('y', 3, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('7', 3, 0, NO_SHIFT);
	keyboard_parse_set_pos_row('n', 4, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('o', 4, 6, NO_SHIFT);
	keyboard_parse_set_pos_row('k', 4, 5, NO_SHIFT);
	keyboard_parse_set_pos_row('m', 4, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('0', 4, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('j', 4, 2, NO_SHIFT);
	keyboard_parse_set_pos_row('i', 4, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('9', 4, 0, NO_SHIFT);
	keyboard_parse_set_pos_row(',', 5, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('[', 5, 6, NO_SHIFT);
	keyboard_parse_set_pos_row(';', 5, 5, NO_SHIFT);
	keyboard_parse_set_pos_row('.', 5, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('-', 5, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('l', 5, 2, NO_SHIFT);
	keyboard_parse_set_pos_row('p', 5, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('=', 5, 0, NO_SHIFT);
	keyboard_parse_set_pos_row('/', 6, 7, NO_SHIFT);
	//	keyboard_parse_set_pos_row('^', 6, 6, NO_SHIFT);
	//	keyboard_parse_set_pos_row('@', 6, 5, DESHIFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_RSHIFT, 6, 4, NO_SHIFT);
	//	keyboard_parse_set_pos_row('', 6, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('\'', 6, 2, NO_SHIFT);
	keyboard_parse_set_pos_row(']', 6, 1, NO_SHIFT);
	//	keyboard_parse_set_pos_row('', 6, 0, NO_SHIFT);
	
	keyboard_parse_set_pos_row('`', 7, 7, NO_SHIFT);
	keyboard_parse_set_pos_row('q', 7, 6, NO_SHIFT);
	//	keyboard_parse_set_pos_row('', 7, 5, NO_SHIFT);
	keyboard_parse_set_pos_row(' ', 7, 4, NO_SHIFT);
	keyboard_parse_set_pos_row('2', 7, 3, NO_SHIFT);
	keyboard_parse_set_pos_row('@', 7, 3, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_LCONTROL, 7, 2, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_LALT, 7, 5, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_ESC, 7, 1, NO_SHIFT);
	keyboard_parse_set_pos_row('1', 7, 0, NO_SHIFT);
	
	keyboard_parse_set_pos_row(MTKEY_ARROW_UP, 0, 7, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_ARROW_DOWN, 0, 7, NO_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_ARROW_LEFT, 0, 2, LEFT_SHIFT);
	keyboard_parse_set_pos_row(MTKEY_ARROW_RIGHT, 0, 2, NO_SHIFT);
	
	*/

	
//	 C64 keyboard matrix:
//	 
//	 Bit   7   6   5   4   3   2   1   0
//	 0    CUD  F5  F3  F1  F7 CLR RET DEL
//	 1    SHL  E   S   Z   4   A   W   3
//	 2     X   T   F   C   6   D   R   5
//	 3     V   U   H   B   8   G   Y   7
//	 4     N   O   K   M   0   J   I   9
//	 5     ,   @   :   .   -   L   P   +
//	 6     /   ^   =  SHR HOM  ;   *   £
//	 7    R/S  Q   C= SPC  2  CTL  <-  1

}

