#include "NstApiMachine.hpp"
#include "NstMachine.hpp"
#include "NstApiEmulator.hpp"
#include "NstApiVideo.hpp"
#include "NstApiCheats.hpp"
#include "NstApiSound.hpp"
#include "NstApiInput.hpp"
#include "NstApiCartridge.hpp"
#include "NstApiUser.hpp"
#include "NstApiFds.hpp"
#include "NstMachine.hpp"
#include "NstPpu.hpp"
#include "NstCpu.hpp"

#include "NesPpuNmtDataAdapter.h"

#include "C64D_Version.h"
#include "NesDebugInterface.h"
#include "NesDebugInterfaceTasks.h"
#include "RES_ResourceManager.h"
#include "CByteBuffer.h"
#include "CSlrString.h"
#include "SYS_CommandLine.h"
#include "CGuiMain.h"
#include "SYS_KeyCodes.h"
#include "SND_SoundEngine.h"
#include "CSnapshotsManager.h"
#include "C64Tools.h"
#include "C64KeyMap.h"
#include "C64SettingsStorage.h"
#include "CViewC64.h"
#include "SND_Main.h"
#include "CSlrFileFromOS.h"
#include "CDebuggerEmulatorPlugin.h"

#include "NesRamDataAdapter.h"
#include "NesWrapper.h"
#include "CNesAudioChannel.h"

NesDebugInterface *debugInterfaceNes;
extern Nes::Api::Emulator nesEmulator;


NesDebugInterface::NesDebugInterface(CViewC64 *viewC64) //, uint8 *memory)
: CDebugInterface(viewC64)
{
	LOGM("NesDebugInterface: NestopiaUE v%s init", NST_VERSION);
	
	debugInterfaceNes = this;
	isInitialised = false;
	
	CreateScreenData();
	
	audioChannel = NULL;
	snapshotsManager = new CSnapshotsManager(this);

	dataAdapter = new NesRamDataAdapter(this);
	dataAdapterPpuNmt = new NesPpuNmtDataAdapter(this);
	
	isDebugOn = true;
	
	if (NestopiaUE_Initialize())
	{
		isInitialised = true;
	}
}

NesDebugInterface::~NesDebugInterface()
{
	debugInterfaceNes = NULL;
	if (screenImage)
	{
		delete screenImage;
	}
	
	if (dataAdapter)
	{
		delete dataAdapter;
	}
	
	if (audioChannel)
	{
		SND_RemoveChannel(audioChannel);
		delete audioChannel;
	}
	
//	Atari800_Exit_Internal(0);
//	
//	SYS_Sleep(100);
}

void NesDebugInterface::RestartEmulation()
{
//	NES_Exit_Internal(0);

	if (audioChannel)
	{
		SND_RemoveChannel(audioChannel);
		delete audioChannel;
	}
	
//	int ret = NES_Initialise(&sysArgc, sysArgv);
//	if (ret != 1)
//	{
//		SYS_FatalExit("NES restart failed, err=%d", ret);
//	}

}

int NesDebugInterface::GetEmulatorType()
{
	return EMULATOR_TYPE_NESTOPIA;
}

CSlrString *NesDebugInterface::GetEmulatorVersionString()
{
	return new CSlrString("NestopiaUE v" NST_VERSION);
}

CSlrString *NesDebugInterface::GetPlatformNameString()
{
	return new CSlrString("NES");
}

bool NesDebugInterface::IsPal()
{
	return nesd_is_pal();
}

float NesDebugInterface::GetEmulationFPS()
{
	if (IsPal())
		return 50.0f;
	
	return 60.0f;
}


double NesDebugInterface::GetCpuClockFrequency()
{
	return nesd_get_cpu_clock_frquency();
}

void NesDebugInterface::RunEmulationThread()
{
	LOGM("NesDebugInterface::RunEmulationThread");
	CDebugInterface::RunEmulationThread();

	this->isRunning = true;

	while (isInitialised == false)
	{
		if (NestopiaUE_Initialize())
		{
			isInitialised = true;
			guiMain->ShowMessage("disksys.rom missing");
		}
		else
		{
			SYS_Sleep(1000);
		}
	}
	
#if defined(RUN_NES)
	NestopiaUE_PostInitialize();
	NestopiaUE_Run();
	audioChannel->Stop();
#endif
	
}

void NesDebugInterface::DoFrame()
{
	// perform async tasks
	
	this->LockMutex();
	this->ExecuteVSyncTasks();
	this->UnlockMutex();
	
	CDebugInterface::DoFrame();
}

//	UBYTE MEMORY_mem[65536 + 2];

void NesDebugInterface::SetByte(uint16 addr, uint8 val)
{
//	u8 *nesRam = nesd_get_ram();
//	nesRam[addr] = val;
	
	Nes::Core::Machine& machine = nesEmulator;
	machine.cpu.map.Poke8_NoMarking(addr, val);
}

uint8 NesDebugInterface::GetByte(uint16 addr)
{
	u8 v;
	
//	u8 *nesRam = nesd_get_ram();
//	v = nesRam[addr];
	
//
//	v = nesd_peek_io(addr);
	
//	LockRenderScreenMutex();
//	LockMutex();
	v = nesd_peek_safe_io(addr);
//	UnlockMutex();
//	UnlockRenderScreenMutex();
	
	return v;
}

void NesDebugInterface::GetMemory(uint8 *buffer, int addrStart, int addrEnd)
{
//	u8 *nesRam = nesd_get_ram();
//
	int addr;
	u8 *bufPtr = buffer + addrStart;
	for (addr = addrStart; addr < addrEnd; addr++)
	{
		*bufPtr++ = GetByte(addr);
	}
}

int NesDebugInterface::GetCpuPC()
{
	return nesd_get_cpu_pc();
}

void NesDebugInterface::GetWholeMemoryMap(uint8 *buffer)
{
//	u8 *nesRam = nesd_get_ram();
//	for (int addr = 0; addr < 0x10000; addr++)
//	{
//		buffer[addr] = nesRam[addr];
//	}

	LockMutex();
	int addr;
	u8 *bufPtr = buffer;
	for (addr = 0; addr < 0x10000; addr++)
	{
		*bufPtr++ = GetByte(addr);
	}
	UnlockMutex();
}

void NesDebugInterface::GetWholeMemoryMapFromRam(uint8 *buffer)
{
	return GetWholeMemoryMap(buffer);
}

void NesDebugInterface::GetCpuRegs(u16 *PC,
				u8 *A,
				u8 *X,
				u8 *Y,
				u8 *P,						/* Processor Status Byte (Partial) */
				u8 *S,
				u8 *IRQ)
{
	return nesd_get_cpu_regs(PC, A, X, Y, P, S, IRQ);
}

void NesDebugInterface::GetPpuClocks(u32 *hClock, u32 *vClock, u32 *cycle)
{
	nesd_get_ppu_clocks(hClock, vClock, cycle);
}

//
int NesDebugInterface::GetScreenSizeX()
{
	return 256;
}

int NesDebugInterface::GetScreenSizeY()
{
	return 240;
}

//
void NesDebugInterface::RefreshScreenNoCallback()
{
	nesd_update_screen(false);
}

//
void NesDebugInterface::SetDebugMode(uint8 debugMode)
{
	LOGD("NesDebugInterface::SetDebugMode: debugMode=%d", debugMode);
	nesd_debug_mode = debugMode;
	
	nesd_reset_sync();
	
	CDebugInterface::SetDebugMode(debugMode);
}

uint8 NesDebugInterface::GetDebugMode()
{
	this->debugMode = nesd_debug_mode;
	return debugMode;
}

CSlrDataAdapter *NesDebugInterface::GetDataAdapter()
{
	return this->dataAdapter;
}


// make jmp without resetting CPU depending on dataAdapter
void NesDebugInterface::MakeJmpNoReset(CSlrDataAdapter *dataAdapter, uint16 addr)
{
	this->LockMutex();
	
//	c64d_atari_set_cpu_pc(addr);
	
	this->UnlockMutex();
}

// make jmp and reset CPU
void NesDebugInterface::MakeJmpAndReset(uint16 addr)
{
	LOGTODO("NesDebugInterface::MakeJmpAndReset");
}

// keyboard & joystick mapper
void NesDebugInterface::KeyboardDown(uint32 mtKeyCode)
{
	LOGI("NesDebugInterface::KeyboardDown: mtKeyCode=%04x", mtKeyCode);

	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		mtKeyCode = plugin->KeyDown(mtKeyCode);
		
		if (mtKeyCode == 0)
			return;
	}
}

void NesDebugInterface::KeyboardUp(uint32 mtKeyCode)
{
	LOGI("NesDebugInterface::KeyboardUp: mtKeyCode=%04x", mtKeyCode);
	
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		mtKeyCode = plugin->KeyUp(mtKeyCode);
		
		if (mtKeyCode == 0)
			return;
	}
	
}

void NesDebugInterface::JoystickDown(int port, uint32 axis)
{
//	LOGD("NesDebugInterface::JoystickDown: %d %d", port, axis);
	nesd_joystick_down(port, axis);
}

void NesDebugInterface::JoystickUp(int port, uint32 axis)
{
//	LOGD("NesDebugInterface::JoystickUp: %d %d", port, axis);
	nesd_joystick_up(port, axis);
}

void NesDebugInterface::Reset()
{
	LOGM("NesDebugInterface::Reset");
	NesDebugInterfaceTaskReset *task = new NesDebugInterfaceTaskReset(this);
	this->AddCpuDebugInterruptTask(task);
}

void NesDebugInterface::HardReset()
{
	LOGM("NesDebugInterface::HardReset");
	NesDebugInterfaceTaskHardReset *task = new NesDebugInterfaceTaskHardReset(this);
	this->AddCpuDebugInterruptTask(task);
}

void NesDebugInterface::ResetClockCounters()
{
	Nes::Core::Machine& machine = nesEmulator;
	machine.cpu.nesdMainCpuCycle = 0;
	machine.cpu.nesdMainCpuDebugCycle = 0;
	machine.cpu.nesdMainCpuPreviousInstructionCycle = 0;
}

bool NesDebugInterface::LoadExecutable(char *fullFilePath)
{
	LOGM("NesDebugInterface::LoadExecutable: %s", fullFilePath);
	return true;
}

bool NesDebugInterface::MountDisk(char *fullFilePath, int diskNo, bool readOnly)
{
	return true;
}

bool NesDebugInterface::InsertCartridge(char *fullFilePath)
{
	LOGM("NesDebugInterface::InsertCartridge: %s", fullFilePath);
	
	this->LockMutex();
	
	CSlrString *str = new CSlrString(fullFilePath);
	NesDebugInterfaceTaskInsertCartridge *task = new NesDebugInterfaceTaskInsertCartridge(this, str);
	this->AddVSyncTask(task);
	delete str;

	this->UnlockMutex();
	
	return true;
}

bool NesDebugInterface::AttachTape(char *fullFilePath, bool readOnly)
{
	return true;
}

// this is main emulation cpu cycle counter
u64 NesDebugInterface::GetMainCpuCycleCounter()
{
	Nes::Core::Machine& machine = nesEmulator;
	return machine.cpu.nesdMainCpuCycle;
}

u64 NesDebugInterface::GetPreviousCpuInstructionCycleCounter()
{
	Nes::Core::Machine& machine = nesEmulator;
	return machine.cpu.nesdMainCpuPreviousInstructionCycle;
}

// resettable counters for debug purposes
void NesDebugInterface::ResetMainCpuDebugCycleCounter()
{
	Nes::Core::Machine& machine = nesEmulator;
	machine.cpu.nesdMainCpuDebugCycle = 0;
}

u64 NesDebugInterface::GetMainCpuDebugCycleCounter()
{
	Nes::Core::Machine& machine = nesEmulator;
	return machine.cpu.nesdMainCpuDebugCycle;
}

bool NesDebugInterface::LoadFullSnapshot(char *filePath)
{
	guiMain->LockMutex();
	this->LockMutex();
	
	bool ret = false;
	CSlrFileFromOS *file = new CSlrFileFromOS(filePath, SLR_FILE_MODE_READ);
	if (file->Exists())
	{
		CByteBuffer *byteBuffer = new CByteBuffer(file, false);
		if (nesd_restore_state(byteBuffer))
		{
			ret = true;
		}
		
		delete byteBuffer;
	}
	
	delete file;
	
	this->UnlockMutex();
	guiMain->UnlockMutex();
	return ret;
}

void NesDebugInterface::SaveFullSnapshot(char *filePath)
{
	LOGD("NesDebugInterface::SaveFullSnapshot: %s", filePath);
	guiMain->LockMutex();
	this->LockMutex();

	CByteBuffer *byteBuffer = nesd_store_state();
	byteBuffer->storeToFileNoHeader(filePath);
	
	delete byteBuffer;

	this->UnlockMutex();
	guiMain->UnlockMutex();
}

// these calls should be synced with CPU IRQ so snapshot store or restore is allowed
bool NesDebugInterface::LoadChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
	LOGD("NesDebugInterface::LoadChipsSnapshotSynced");
	debugInterfaceNes->LockMutex();
	gSoundEngine->LockMutex("NesDebugInterface::LoadChipsSnapshotSynced");
	
	bool ret = nesd_restore_nesd_state_from_bytebuffer(byteBuffer);
	
	if (ret == false)
	{
		LOGError("NesDebugInterface::LoadChipsSnapshotSynced: failed");

		debugInterfaceNes->UnlockMutex();
		gSoundEngine->UnlockMutex("NesDebugInterface::LoadChipsSnapshotSynced");
		return false;
	}
	
	debugInterfaceNes->UnlockMutex();
	gSoundEngine->UnlockMutex("NesDebugInterface::LoadChipsSnapshotSynced");
	return true;
}

bool NesDebugInterface::SaveChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
	// TODO: check if data changed and store snapshot with data accordingly
	return nesd_store_nesd_state_to_bytebuffer(byteBuffer);
}

bool NesDebugInterface::LoadDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	return true;
}

bool NesDebugInterface::SaveDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	// TODO: check if data changed and store snapshot with data accordingly
	return true;
}

bool NesDebugInterface::IsDriveDirtyForSnapshot()
{
	// TODO: check if data on disk/cart changed
	return false;
}

void NesDebugInterface::ClearDriveDirtyForSnapshotFlag()
{
	//c64d_clear_drive_dirty_for_snapshot();
}


///

void NesDebugInterface::SetVideoSystem(u8 videoSystem)
{
	LOGD("NesDebugInterface::SetVideoSystem: %d", videoSystem);
}


void NesDebugInterface::SetMachineType(u8 machineType)
{
}

void NesDebugInterface::SetApuMuteChannels(int apuNumber, bool muteSquare1, bool muteSquare2, bool muteTriangle, bool muteNoise, bool muteDmc, bool muteExt)
{
	nesd_mute_channels(muteSquare1, muteSquare2, muteTriangle, muteNoise, muteDmc, muteExt);
}

void NesDebugInterface::SetApuReceiveChannelsData(int apuNumber, bool isReceiving)
{
	LOGD("SetApuReceiveChannelsData: isReceiving=%s", STRBOOL(isReceiving));
	nesd_isReceiveChannelsData = isReceiving;
}

u8 NesDebugInterface::GetApuRegister(u16 addr)
{
	return nesd_get_apu_register(addr);
}

u8 NesDebugInterface::GetPpuRegister(u16 addr)
{
	Nes::Core::Machine& machine = nesEmulator;
	return machine.ppu.registers[addr & 0x0F];
}
