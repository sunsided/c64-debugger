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
#include "datasette.h"
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
#include "CViewC64.h"
#include "CViewC64StateSID.h"
#include "CViceAudioChannel.h"
#include "CDebuggerEmulatorPlugin.h"
#include "CSnapshotsManager.h"

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
	
	int resources_get_int(const char *name, int *value_return);
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

	CreateScreenData();

	audioChannel = NULL;
	snapshotsManager = new CSnapshotsManager(this);

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
	machineType = MACHINE_TYPE_PAL;
	debugInterfaceVice->numEmulationFPS = 50;

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
}

extern "C" {
	void c64d_patch_kernal_fast_boot();
	void c64d_un_patch_kernal_fast_boot();
	void c64d_update_rom();
};

float C64DebugInterfaceVice::GetEmulationFPS()
{
	return this->numEmulationFPS;
}

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

void C64DebugInterfaceVice::SetRunSIDEmulation(bool isSIDEmulationOn)
{
	// this does not stop sound via playback_enable, but just skips the SID emulation
	// thus, the CPU emulation will be in correct sync
	
	LOGD("C64DebugInterfaceVice::SetRunSIDEmulation: %s", STRBOOL(isSIDEmulationOn));
	c64d_setting_run_sid_emulation = isSIDEmulationOn ? 1 : 0;
}

void C64DebugInterfaceVice::SetAudioVolume(float volume)
{
	LOGD("C64DebugInterfaceVice::SetAudioVolume: %f", volume);
	c64d_set_volume(volume);
}

int C64DebugInterfaceVice::GetEmulatorType()
{
	return EMULATOR_TYPE_C64_VICE;
}

CSlrString *C64DebugInterfaceVice::GetEmulatorVersionString()
{
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Vice %s by The VICE Team", VERSION);
	CSlrString *versionString = new CSlrString(buf);
	SYS_ReleaseCharBuf(buf);
	
	return versionString;
}

#if defined(WIN32)
extern "C" {
	int uilib_cpu_is_smp(void);
	int set_single_cpu(int val, void *param);	// 1=set to first CPU, 0=set to all CPUs
}
#endif

void C64DebugInterfaceVice::RunEmulationThread()
{
	LOGM("C64DebugInterfaceVice::RunEmulationThread");
	CDebugInterface::RunEmulationThread();

	this->isRunning = true;

#if defined(WIN32)
	if (c64SettingsUseOnlyFirstCPU)
	{
		if (uilib_cpu_is_smp() == 1)
		{
			LOGD("C64DebugInterfaceVice: set UseOnlyFirstCPU");
			set_single_cpu(1, NULL);
		}
	}
#endif
	
	// vice blocks d64 for read when mounted and does the flush only on disk unmount or quit. this leads to not saved data immediately.
	// thus, we do not block d64 for read and avoid that data is not flushed we check periodically if there's a need to flush data

	this->driveFlushThread = new CViceDriveFlushThread(this, 2500); // every 2.5s
	SYS_StartThread(this->driveFlushThread);
	
	vice_main_loop_run();
	
	audioChannel->Stop();

	LOGM("C64DebugInterfaceVice::RunEmulationThread: finished");
}

void C64DebugInterfaceVice::DoFrame()
{
	CDebugInterface::DoFrame();
}

CViceDriveFlushThread::CViceDriveFlushThread(C64DebugInterfaceVice *debugInterface, int flushCheckIntervalInMS)
{
	this->debugInterface = debugInterface;
	this->flushCheckIntervalInMS = flushCheckIntervalInMS;
}

void CViceDriveFlushThread::ThreadRun(void *data)
{
//	LOGD("CViceDriveFlushThread started");
	while(true)
	{
		SYS_Sleep(this->flushCheckIntervalInMS);
		
		this->debugInterface->LockMutex();
		if (debugInterface->snapshotsManager->snapshotToRestore
			|| debugInterface->snapshotsManager->pauseNumFrame != -1)
		{
			this->debugInterface->UnlockMutex();
			SYS_Sleep(this->flushCheckIntervalInMS * 4);
			continue;
		}

//		LOGD("CViceDriveFlushThread: flushing drive");
		drive_gcr_data_writeback_all();
		this->debugInterface->UnlockMutex();
//		LOGD("CViceDriveFlushThread: flushing drive finished");
		
	}
	
}

void C64DebugInterfaceVice::Shutdown()
{
	this->LockMutex();
	drive_gcr_data_writeback_all();
	this->UnlockMutex();
	
	C64DebugInterface::Shutdown();
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

int C64DebugInterfaceVice::GetScreenSizeX()
{
	return 384;
}

int C64DebugInterfaceVice::GetScreenSizeY()
{
	return screenHeight;
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
	this->SetDebugMode(DEBUGGER_MODE_RUNNING);
}


void C64DebugInterfaceVice::Reset()
{
	vsync_suspend_speed_eval();
	
	keyboard_clear_keymatrix();

	machine_trigger_reset(MACHINE_RESET_MODE_SOFT);
	this->ResetEmulationFrameCounter();
	c64d_maincpu_clk = 6;

	c64d_update_c64_model();

	if (c64d_is_cpu_in_jam_state == 1)
	{
		this->SetDebugMode(DEBUGGER_MODE_RUNNING);
		c64d_is_cpu_in_jam_state = 0;
	}
}

void C64DebugInterfaceVice::HardReset()
{
	LOGD("C64DebugInterfaceVice::HardReset");
	vsync_suspend_speed_eval();
	
	keyboard_clear_keymatrix();

	machine_trigger_reset(MACHINE_RESET_MODE_HARD);
	this->ResetEmulationFrameCounter();
	c64d_maincpu_clk = 6;

	c64d_update_c64_model();

	if (c64d_is_cpu_in_jam_state == 1)
	{
		this->SetDebugMode(DEBUGGER_MODE_RUNNING);
		c64d_is_cpu_in_jam_state = 0;
	}
}

void C64DebugInterfaceVice::DiskDriveReset()
{
	LOGM("C64DebugInterfaceVice::DiskDriveReset()");
	
	drivecpu_reset(drive_context[0]);
}

void C64DebugInterfaceVice::ResetMainCpuCycleCounter()
{
	c64d_maincpu_clk = 0;
}

unsigned int C64DebugInterfaceVice::GetMainCpuCycleCounter()
{
	return c64d_maincpu_clk;
}

void C64DebugInterfaceVice::ResetEmulationFrameCounter()
{
	this->snapshotsManager->ClearSnapshotsHistory();
	C64DebugInterface::ResetEmulationFrameCounter();
}

unsigned int C64DebugInterfaceVice::GetEmulationFrameNumber()
{
	return C64DebugInterface::GetEmulationFrameNumber();
}

extern "C" {
	void c64d_joystick_key_down(int key, unsigned int joyport);
	void c64d_joystick_key_up(int key, unsigned int joyport);
}

void C64DebugInterfaceVice::KeyboardDown(uint32 mtKeyCode)
{
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		mtKeyCode = plugin->KeyDown(mtKeyCode);
		
		if (mtKeyCode == 0)
			return;
	}
	
	keyboard_key_pressed((unsigned long)mtKeyCode);
}

void C64DebugInterfaceVice::KeyboardUp(uint32 mtKeyCode)
{
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		mtKeyCode = plugin->KeyUp(mtKeyCode);
		
		if (mtKeyCode == 0)
			return;
	}
	
	keyboard_key_released((unsigned long)mtKeyCode);
}

void C64DebugInterfaceVice::JoystickDown(int port, uint32 axis)
{
	c64d_joystick_key_down(axis, port);
}

void C64DebugInterfaceVice::JoystickUp(int port, uint32 axis)
{
	c64d_joystick_key_up(axis, port);
}

int C64DebugInterfaceVice::GetCpuPC()
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

// REU
extern "C" {
	int set_reu_enabled(int value, void *param);
	int set_reu_size(int val, void *param);
	int set_reu_filename(const char *name, void *param);
	int reu_bin_save(const char *filename);
};

void C64DebugInterfaceVice::SetReuEnabled(bool isEnabled)
{
	LOGD("C64DebugInterfaceVice::SetReuEnabled: %s", STRBOOL(isEnabled));
	set_reu_enabled((isEnabled ? 1:0), NULL);
}

void C64DebugInterfaceVice::SetReuSize(int reuSize)
{
	snapshotsManager->LockMutex();
	set_reu_size(reuSize, NULL);
	snapshotsManager->UnlockMutex();
}

bool C64DebugInterfaceVice::LoadReu(char *filePath)
{
	resources_set_string("REUfilename", filePath);

//	if (set_reu_filename(filePath, NULL) == 0)
//		return true;
//	return false;
	
	return true;
}

bool C64DebugInterfaceVice::SaveReu(char *filePath)
{
	snapshotsManager->LockMutex();
	if (reu_bin_save(filePath) == 0)
	{
		snapshotsManager->UnlockMutex();
		return true;
	}
	
	snapshotsManager->UnlockMutex();
	return false;
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
	snapshotsManager->LockMutex();
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
	snapshotsManager->UnlockMutex();
}

// samplingMethod: Fast=0, Interpolating=1, Resampling=2, Fast Resampling=3
void C64DebugInterfaceVice::SetSidSamplingMethod(int samplingMethod)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_sampling_method(samplingMethod);
	snapshotsManager->UnlockMutex();
}

// emulateFilters: no=0, yes=1
void C64DebugInterfaceVice::SetSidEmulateFilters(int emulateFilters)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_emulate_filters(emulateFilters);
	snapshotsManager->UnlockMutex();
}

// passband: 0-90
void C64DebugInterfaceVice::SetSidPassBand(int passband)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_passband(passband);
	snapshotsManager->UnlockMutex();
}

// filterBias: -500 500
void C64DebugInterfaceVice::SetSidFilterBias(int filterBias)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_filter_bias(filterBias);
	snapshotsManager->UnlockMutex();
}

// 0=none, 1=stereo, 2=triple
void C64DebugInterfaceVice::SetSidStereo(int stereoMode)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_stereo(stereoMode);
	snapshotsManager->UnlockMutex();
}

void C64DebugInterfaceVice::SetSidStereoAddress(uint16 sidAddress)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_stereo_address(sidAddress);
	snapshotsManager->UnlockMutex();
}

void C64DebugInterfaceVice::SetSidTripleAddress(uint16 sidAddress)
{
	snapshotsManager->LockMutex();
	c64d_sid_set_triple_address(sidAddress);
	snapshotsManager->UnlockMutex();
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
	
	debugInterfaceVice->ResetEmulationFrameCounter();

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
	snapshotsManager->LockMutex();
	int model = c64model_get();
	snapshotsManager->UnlockMutex();
	return model;
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
	void c64d_mem_write_c64_no_mark(unsigned int addr, unsigned char value);
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

//
extern "C" {
	cia_context_t *c64d_get_cia_context(int ciaId);
	BYTE c64d_ciacore_peek(cia_context_t *cia_context, WORD addr);
	void ciacore_store(cia_context_t *cia_context, WORD addr, BYTE value);
}

void C64DebugInterfaceVice::SetCiaRegister(uint8 ciaId, uint8 registerNum, uint8 value)
{
	cia_context_t *cia_context = c64d_get_cia_context(ciaId);
	ciacore_store(cia_context, registerNum, value);
}

u8 C64DebugInterfaceVice::GetCiaRegister(uint8 ciaId, uint8 registerNum)
{
	cia_context_t *cia_context = c64d_get_cia_context(ciaId);	
	return c64d_ciacore_peek(cia_context, registerNum);
}

extern "C" {
	BYTE sid_peek_chip(WORD addr, int chipno);
	void sid_store_chip(WORD addr, BYTE value, int chipno);
}

struct SetSidRegisterData {
	WORD registerNum;
	BYTE value;
	int sidId;
};

static void c64_set_sid_register_trap(WORD addr, void *v)
{
	guiMain->LockMutex();
	debugInterfaceVice->LockMutex();
	gSoundEngine->LockMutex("C64DebugInterfaceVice::SetSidRegister");
	
	SetSidRegisterData *setSidRegisterData = (SetSidRegisterData *)v;
	
	sid_store_chip(setSidRegisterData->registerNum, setSidRegisterData->value, setSidRegisterData->sidId);
	delete setSidRegisterData;
	
	gSoundEngine->UnlockMutex("C64DebugInterfaceVice::SetSidRegister");
	debugInterfaceVice->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64DebugInterfaceVice::SetSidRegister(uint8 sidId, uint8 registerNum, uint8 value)
{
	snapshotsManager->LockMutex();

	this->LockMutex();
	
	if (this->GetDebugMode() == DEBUGGER_MODE_PAUSED)
	{ 
		this->LockIoMutex();
		sid_store_chip(registerNum, value, sidId);
		this->UnlockIoMutex();
	}
	else
	{
		SetSidRegisterData *setSidRegisterData = new SetSidRegisterData();
		setSidRegisterData->sidId = sidId;
		setSidRegisterData->registerNum = registerNum;
		setSidRegisterData->value = value;
		interrupt_maincpu_trigger_trap(c64_set_sid_register_trap, setSidRegisterData);
	}

	this->UnlockMutex();
	
	snapshotsManager->UnlockMutex();
}

u8 C64DebugInterfaceVice::GetSidRegister(uint8 sidId, uint8 registerNum)
{
	return sid_peek_chip(registerNum, sidId);
}

extern "C" {
	void via1d1541_store(drive_context_t *ctxptr, WORD addr, BYTE data);
	BYTE c64d_via1d1541_peek(drive_context_t *ctxptr, WORD addr);
	void via2d_store(drive_context_t *ctxptr, WORD addr, BYTE data);
	BYTE c64d_via2d_peek(drive_context_t *ctxptr, WORD addr);
}
void C64DebugInterfaceVice::SetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum, uint8 value)
{
	drive_context_t *drivectx = drive_context[driveId];
	
	if (viaId == 1)
	{
		via1d1541_store(drivectx, registerNum, value);
	}
	else
	{
		via2d_store(drivectx, registerNum, value);
	}

}

u8 C64DebugInterfaceVice::GetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum)
{
	drive_context_t *drivectx = drive_context[driveId];
	
	if (viaId == 1)
	{
		return c64d_via1d1541_peek(drivectx, registerNum);
	}
	
	return c64d_via2d_peek(drivectx, registerNum);
}



void C64DebugInterfaceVice::MakeJmpC64(uint16 addr)
{
	LOGD("C64DebugInterfaceVice::MakeJmpC64: %04x", addr);
	
	if (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		c64d_set_c64_pc(addr);
		c64d_set_debug_mode(DEBUGGER_MODE_PAUSED);
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

extern "C" {
	void c64d_maincpu_make_basic_run();
};

void C64DebugInterfaceVice::MakeBasicRunC64()
{
	LOGD("C64DebugInterfaceVice::MakeBasicRunC64");
	
	c64d_maincpu_make_basic_run();
}


extern "C" {
	void c64d_set_maincpu_regs(uint8 *a, uint8 *x, uint8 *y, uint8 *p, uint8 *sp);
	void c64d_set_maincpu_set_sp(uint8 *sp);
	void c64d_set_maincpu_set_a(uint8 *a);
	void c64d_set_maincpu_set_x(uint8 *x);
	void c64d_set_maincpu_set_y(uint8 *y);
	void c64d_set_maincpu_set_p(uint8 *p);

}

void C64DebugInterfaceVice::SetStackPointerC64(uint8 val)
{
	LOGD("C64DebugInterfaceVice::SetStackPointerC64: val=%x", val);
	
	this->LockMutex();
	
	uint8 sp = val;
	c64d_set_maincpu_set_sp(&sp);

	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterAC64(uint8 val)
{
	LOGD("C64DebugInterfaceVice::SetRegisterAC64: val=%x", val);
	
	this->LockMutex();
	
	uint8 a = val;
	c64d_set_maincpu_set_a(&a);

	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterXC64(uint8 val)
{
	LOGD("C64DebugInterfaceVice::SetRegisterXC64: val=%x", val);
	
	this->LockMutex();
	
	uint8 x = val;
	c64d_set_maincpu_set_x(&x);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterYC64(uint8 val)
{
	LOGD("C64DebugInterfaceVice::SetRegisterYC64: val=%x", val);
	
	this->LockMutex();
	
	uint8 y = val;
	c64d_set_maincpu_set_y(&y);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterPC64(uint8 val)
{
	LOGD("C64DebugInterfaceVice::SetRegisterPC64: val=%x", val);
	
	this->LockMutex();
	
	uint8 p = val;
	c64d_set_maincpu_set_p(&p);
	
	this->UnlockMutex();
}

extern "C" {
	void c64d_set_drive_register_a(int driveNr, uint8 a);
	void c64d_set_drive_register_x(int driveNr, uint8 x);
	void c64d_set_drive_register_y(int driveNr, uint8 y);
	void c64d_set_drive_register_p(int driveNr, uint8 p);
	void c64d_set_drive_register_sp(int driveNr, uint8 sp);
}

void C64DebugInterfaceVice::SetRegisterA1541(uint8 val)
{
	this->LockMutex();
	
	c64d_set_drive_register_a(0, val);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterX1541(uint8 val)
{
	this->LockMutex();
	
	c64d_set_drive_register_x(0, val);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterY1541(uint8 val)
{
	this->LockMutex();
	
	c64d_set_drive_register_y(0, val);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetRegisterP1541(uint8 val)
{
	this->LockMutex();
	
	c64d_set_drive_register_p(0, val);
	
	this->UnlockMutex();
}

void C64DebugInterfaceVice::SetStackPointer1541(uint8 val)
{
	this->LockMutex();
	
	c64d_set_drive_register_sp(0, val);
	
	this->UnlockMutex();
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
	if (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		c64d_set_drive_pc(0, addr);
		//c64d_set_debug_mode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
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


void C64DebugInterfaceVice::GetWholeMemoryMap(uint8 *buffer)
{
	c64d_peek_whole_map_c64(buffer);
}

void C64DebugInterfaceVice::GetWholeMemoryMapFromRam(uint8 *buffer)
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

void C64DebugInterfaceVice::GetMemoryFromRam(uint8 *buffer, int addrStart, int addrEnd)
{
	c64d_copy_ram_memory_c64(buffer, addrStart, addrEnd);
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
	LOGD("C64DebugInterfaceVice::SetDebugMode: %d", debugMode);
	
	c64d_set_debug_mode(debugMode);
	
}

uint8 C64DebugInterfaceVice::GetDebugMode()
{
	return c64d_debug_mode;
}

// tape
extern "C" {
	int tape_image_attach(unsigned int unit, const char *name);
	int tape_image_detach(unsigned int unit);
	void datasette_control(int command);
}

static void tape_attach_trap(WORD addr, void *v)
{
	char *filePath = (char*)v;
	tape_image_attach(1, filePath);

	SYS_ReleaseCharBuf(filePath);
}

static void tape_detach_trap(WORD addr, void *v)
{
	tape_image_detach(1);
}

void C64DebugInterfaceVice::AttachTape(CSlrString *filePath)
{
	char *asciiPath = filePath->GetStdASCII();
	
	FixFileNameSlashes(asciiPath);
	
	char *buf = SYS_GetCharBuf();
	strcpy(buf, asciiPath);

	interrupt_maincpu_trigger_trap(tape_attach_trap, asciiPath);
}

void C64DebugInterfaceVice::DetachTape()
{
	interrupt_maincpu_trigger_trap(tape_detach_trap, NULL);
}

void C64DebugInterfaceVice::DatasettePlay()
{
	datasette_control(DATASETTE_CONTROL_START);
}

void C64DebugInterfaceVice::DatasetteStop()
{
	datasette_control(DATASETTE_CONTROL_STOP);
}

void C64DebugInterfaceVice::DatasetteForward()
{
	datasette_control(DATASETTE_CONTROL_FORWARD);
}

void C64DebugInterfaceVice::DatasetteRewind()
{
	datasette_control(DATASETTE_CONTROL_REWIND);
}

void C64DebugInterfaceVice::DatasetteRecord()
{
	datasette_control(DATASETTE_CONTROL_RECORD);
}

void C64DebugInterfaceVice::DatasetteReset()
{
	datasette_control(DATASETTE_CONTROL_RESET);
}

void C64DebugInterfaceVice::DatasetteSetSpeedTuning(int speedTuning)
{
	resources_set_int("DatasetteSpeedTuning", speedTuning);
}

void C64DebugInterfaceVice::DatasetteSetZeroGapDelay(int zeroGapDelay)
{
	resources_set_int("DatasetteZeroGapDelay", zeroGapDelay);
}

void C64DebugInterfaceVice::DatasetteSetResetWithCPU(bool resetWithCPU)
{
	resources_set_int("DatasetteResetWithCPU", resetWithCPU ? 1:0);
}

void C64DebugInterfaceVice::DatasetteSetTapeWobble(int tapeWobble)
{
	resources_set_int("DatasetteTapeWobble", tapeWobble);
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

	debugInterfaceVice->ResetEmulationFrameCounter();
}

static void cartridge_detach_trap(WORD addr, void *v)
{
	// -1 means all slots
	cartridge_detach_image(-1);
	machine_trigger_reset(MACHINE_RESET_MODE_HARD);
	debugInterfaceVice->ResetEmulationFrameCounter();
	c64d_maincpu_clk = 6;
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
	
	debugInterfaceVice->ResetEmulationFrameCounter();
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

static void trap_detach_everything(WORD addr, void *v)
{
	// -1 means all slots
	cartridge_detach_image(-1);
	machine_trigger_reset(MACHINE_RESET_MODE_HARD);
	debugInterfaceVice->ResetEmulationFrameCounter();
	c64d_maincpu_clk = 6;

	tape_image_detach(1);
	
	file_system_detach_disk(8);
}


void C64DebugInterfaceVice::DetachEverything()
{
	interrupt_maincpu_trigger_trap(trap_detach_everything, NULL);
}


extern "C" {
	void c64d_c64_set_vicii_record_state_mode(uint8 recordMode);
}

void C64DebugInterfaceVice::SetVicRecordStateMode(uint8 recordMode)
{
	c64d_c64_set_vicii_record_state_mode(recordMode);
}


void C64DebugInterfaceVice::SetSIDMuteChannels(int sidNumber, bool mute1, bool mute2, bool mute3, bool muteExt)
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

	sid_set_voice_mask(sidNumber, sidVoiceMask);

}

void C64DebugInterfaceVice::SetSIDReceiveChannelsData(int sidNumber, bool isReceiving)
{
	if (isReceiving)
	{
		c64d_sid_receive_channels_data(sidNumber, 1);
	}
	else
	{
		c64d_sid_receive_channels_data(sidNumber, 0);
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
			debugInterfaceVice->machineType = MACHINE_TYPE_PAL;
			debugInterfaceVice->numEmulationFPS = 50;
			break;
		case 3:
		case 4:
		case 5:
		case 8:
		case 12:
			// NTSC, 275 lines
			debugInterfaceVice->machineType = MACHINE_TYPE_NTSC;
			debugInterfaceVice->numEmulationFPS = 60;
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
	
	debugInterfaceVice->LockMutex();
	
	char *filePath = (char*)v;
	//int ret =

	FILE *fp = fopen(filePath, "rb");
	if (!fp)
	{
		guiMain->ShowMessage("Snapshot not found");
		debugInterfaceVice->UnlockMutex();
		return;
	}
	fclose(fp);
	
	gSoundEngine->LockMutex("load_snapshot_trap");

	if (c64_snapshot_read(filePath, 0, 1, 1, 1, 1) < 0)
	{
		guiMain->ShowMessage("Snapshot loading failed");
		
		debugInterfaceVice->machineType = MACHINE_TYPE_UNKNOWN;
		debugInterfaceVice->numEmulationFPS = 1;
		debugInterfaceVice->screenHeight = 0;
		
		c64d_clear_screen();
	}
	else
	{
		// if CPU is in JAM then un-jam and continue
		if (c64d_is_cpu_in_jam_state == 1)
		{
			c64d_is_cpu_in_jam_state = 0;
			c64d_set_debug_mode(DEBUGGER_MODE_RUNNING);
		}
	}
	
	c64d_update_c64_model();
	
	debugInterfaceVice->SetSidType(c64SettingsSIDEngineModel);
	debugInterfaceVice->SetSidSamplingMethod(c64SettingsRESIDSamplingMethod);
	debugInterfaceVice->SetSidEmulateFilters(c64SettingsRESIDEmulateFilters);
	debugInterfaceVice->SetSidPassBand(c64SettingsRESIDPassBand);
	debugInterfaceVice->SetSidFilterBias(c64SettingsRESIDFilterBias);
	
	int val;
	resources_get_int("SidStereo", &val);
	c64SettingsSIDStereo = val;

	resources_get_int("SidStereoAddressStart", &val);
	c64SettingsSIDStereoAddress = val;

	resources_get_int("SidTripleAddressStart", &val);
	c64SettingsSIDTripleAddress = val;

	gSoundEngine->UnlockMutex("load_snapshot_trap");
	
	SYS_ReleaseCharBuf(filePath);
	
	viewC64->viewC64SettingsMenu->UpdateSidSettings();

	debugInterfaceVice->snapshotsManager->ClearSnapshotsHistory();

	debugInterfaceVice->UnlockMutex();
}


bool C64DebugInterfaceVice::LoadFullSnapshot(char *filePath)
{
	char *buf = SYS_GetCharBuf();
	strcpy(buf, filePath);
	
	this->machineType = MACHINE_TYPE_LOADING_SNAPSHOT;
	debugInterfaceVice->numEmulationFPS = 1;

	interrupt_maincpu_trigger_trap(load_snapshot_trap, buf);
	
	if (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		c64d_set_debug_mode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
	}
	
	return true;
}

static void save_snapshot_trap(WORD addr, void *v)
{
	LOGD("save_snapshot_trap");
	
	debugInterfaceVice->LockMutex();

	char *filePath = (char*)v;
	
	gSoundEngine->LockMutex("save_snapshot_trap");
	
	c64_snapshot_write(filePath, 0, 1, 0, 1, 1, 1);
	
	gSoundEngine->UnlockMutex("save_snapshot_trap");
	
	SYS_ReleaseCharBuf(filePath);
	
	debugInterfaceVice->UnlockMutex();	
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
	
	if (c64d_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		c64d_set_debug_mode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
	}
}

// these calls should be synced with CPU IRQ so snapshot store or restore is allowed
bool C64DebugInterfaceVice::LoadChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
//	extern int c64_snapshot_read_from_memory(int event_mode, int read_roms, int read_disks, int read_reu_data,
//											 unsigned char *snapshot_data, int snapshot_size);

	LOGD("LoadChipsSnapshotSynced");
	debugInterfaceVice->LockMutex();
	gSoundEngine->LockMutex("LoadChipsSnapshotSynced");

	int ret = c64_snapshot_read_from_memory(1, 0, 0, 0, 0, 0, byteBuffer->data, byteBuffer->length);
	if (ret != 0)
	{
		LOGError("C64DebugInterfaceVice::LoadFullSnapshotSynced: failed");

		debugInterfaceVice->UnlockMutex();
		gSoundEngine->UnlockMutex("LoadChipsSnapshotSynced");
		return false;
	}
	
	debugInterfaceVice->UnlockMutex();
	gSoundEngine->UnlockMutex("LoadChipsSnapshotSynced");
	return true;
}

bool C64DebugInterfaceVice::SaveChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
	// TODO: check if data changed and store snapshot with data accordingly
	return this->SaveFullSnapshotSynced(byteBuffer, true, false, false, false, false, false, true);
}

bool C64DebugInterfaceVice::LoadDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	//	extern int c64_snapshot_read_from_memory(int event_mode, int read_roms, int read_disks, int read_reu_data,
	//											 unsigned char *snapshot_data, int snapshot_size);
	
	LOGD("LoadDiskDataSnapshotSynced");
	debugInterfaceVice->LockMutex();
	gSoundEngine->LockMutex("LoadDiskDataSnapshotSynced");
	
//	int ret = c64_snapshot_read_from_memory(0, 0, 1, 0, 0, byteBuffer->data, byteBuffer->length);
	int ret = c64_snapshot_read_from_memory(0, 0, 1, 0, 0, 1, byteBuffer->data, byteBuffer->length);
	if (ret != 0)
	{
		LOGError("C64DebugInterfaceVice::LoadFullSnapshotSynced: failed");
		
		debugInterfaceVice->UnlockMutex();
		gSoundEngine->UnlockMutex("LoadDiskDataSnapshotSynced");
		return false;
	}
	
	debugInterfaceVice->UnlockMutex();
	gSoundEngine->UnlockMutex("LoadDiskDataSnapshotSynced");
	return true;
}

bool C64DebugInterfaceVice::SaveDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	// TODO: check if data changed and store snapshot with data accordingly
	return this->SaveFullSnapshotSynced(byteBuffer,
										true, false, true, false, false, true, false);
}

bool C64DebugInterfaceVice::SaveFullSnapshotSynced(CByteBuffer *byteBuffer,
												   bool saveChips, bool saveRoms, bool saveDisks, bool eventMode,
												   bool saveReuData, bool saveCartRoms, bool saveScreen)
{
	int snapshotSize = 0;
	u8 *snapshotData = NULL;

	debugInterfaceVice->LockMutex();
	gSoundEngine->LockMutex("SaveFullSnapshotSynced");

	// TODO: reuse byteBuffer->data
	int ret = c64_snapshot_write_in_memory(saveChips ? 1:0, saveRoms ? 1:0, saveDisks ? 1:0, eventMode ? 1:0,
										   saveReuData ? 1:0, saveCartRoms ? 1:0, saveScreen ? 1:0,
										   &snapshotSize, &snapshotData);

	gSoundEngine->UnlockMutex("SaveFullSnapshotSynced");
	debugInterfaceVice->UnlockMutex();

//	LOGD("C64DebugInterfaceVice::SaveFullSnapshotSynced: snapshotData=%x snapshotSize=%d", snapshotData, snapshotSize);
	
	if (ret == 0)
	{
		byteBuffer->SetData(snapshotData, snapshotSize);
		return true;
	}
	
	if (snapshotData != NULL)
	{
		lib_free(snapshotData);
	}
	
	LOGError("C64DebugInterfaceVice::SaveFullSnapshotSynced: failed");
	return false;
}

bool C64DebugInterfaceVice::IsDriveDirtyForSnapshot()
{
	return c64d_is_drive_dirty_for_snapshot() == 0 ? false : true;
}

void C64DebugInterfaceVice::ClearDriveDirtyForSnapshotFlag()
{
	c64d_clear_drive_dirty_for_snapshot();
}

// Profiler
extern "C"
{
	void c64d_profiler_activate(char *fileName, int runForNumCycles, int pauseCpuWhenFinished);
	void c64d_profiler_deactivate();	
}

// if fileName is NULL no file will be created, if runForNumCycles is -1 it will run till ProfilerDeactivate
// TODO: select c64 cpu or disk drive cpu
void C64DebugInterfaceVice::ProfilerActivate(char *fileName, int runForNumCycles, bool pauseCpuWhenFinished)
{
	c64d_profiler_activate(fileName, runForNumCycles, pauseCpuWhenFinished ? 1:0);
}

void C64DebugInterfaceVice::ProfilerDeactivate()
{
	c64d_profiler_deactivate();
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

