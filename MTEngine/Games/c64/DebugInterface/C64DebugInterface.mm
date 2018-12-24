#include "C64DebugInterface.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "CViewMainMenu.h"
#include "CViewC64StateSID.h"
#include "CByteBuffer.h"

C64DebugInterface::C64DebugInterface(CViewC64 *viewC64)
: CDebugInterface(viewC64)
{
	this->viewC64 = viewC64;
	
	emulationSpeed = 0;
	emulationFrameRate = 0;	

	breakOnC64IrqVIC = false;
	breakOnC64IrqCIA = false;
	breakOnC64IrqNMI = false;
	
	breakOnDrive1541IrqVIA1 = false;
	breakOnDrive1541IrqVIA2 = false;
	breakOnDrive1541IrqIEC = false;
	breakOnDrive1541PC = false;
	breakOnDrive1541Memory = false;

	temporaryDrive1541BreakpointPC = -1;

	debugMode = DEBUGGER_MODE_RUNNING;
	isDebugOn = true;
	debugOnDrive1541 = false;
	
	for (int i = 0; i < C64_NUM_DRIVES; i++)
	{
		ledState[i] = 0.0f;
	}
}

C64DebugInterface::~C64DebugInterface()
{
}

int C64DebugInterface::GetEmulatorType()
{
	SYS_FatalExit("C64DebugInterface::GetEmulatorType");
	return -1;
}

CSlrString *C64DebugInterface::GetEmulatorVersionString()
{
	SYS_FatalExit("C64DebugInterface::GetEmulatorVersionString");
	return NULL;
}

CSlrString *C64DebugInterface::GetPlatformNameString()
{
	return new CSlrString("Commodore 64");
}


void C64DebugInterface::InitKeyMap(C64KeyMap *keyMap)
{
	SYS_FatalExit("C64DebugInterface::InitKeyMap");
}

uint8 *C64DebugInterface::GetCharRom()
{
	SYS_FatalExit("C64DebugInterface::GetCharRom");
	return NULL;
}


void C64DebugInterface::RunEmulationThread()
{
	SYS_FatalExit("C64DebugInterface::RunEmulationThread");
}

//
int C64DebugInterface::GetC64ModelType()
{
	return 0;
}

uint8 C64DebugInterface::GetC64MachineType()
{
	return 0;
}

//
void C64DebugInterface::ClearBreakpoints()
{
	CDebugInterface::ClearBreakpoints();
	
	ClearAddrBreakpoints(&(this->breakpointsDrive1541PC));
	ClearMemoryBreakpoints(&(this->breakpointsDrive1541Memory));
}

void C64DebugInterface::AddAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, CAddrBreakpoint *breakpoint)
{
	CDebugInterface::AddAddrBreakpoint(breakpointsMap, breakpoint);

	if (breakpointsMap == &(this->breakpointsDrive1541PC))
	{
		breakOnDrive1541PC = true;
	}
}

void C64DebugInterface::RemoveAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, uint16 addr)
{
	CDebugInterface::RemoveAddrBreakpoint(breakpointsMap, addr);

	if (breakpointsMap->empty())
	{
		if (breakpointsMap == &(this->breakpointsDrive1541PC))
		{
			breakOnDrive1541PC = false;
		}
	}
}


// video

int C64DebugInterface::GetScreenSizeX()
{
	return -1;
}

int C64DebugInterface::GetScreenSizeY()
{
	return -1;
}

void C64DebugInterface::SetDebugOnC64(bool debugOnC64)
{
	this->isDebugOn = debugOnC64;
}

void C64DebugInterface::SetDebugOnDrive1541(bool debugOnDrive1541)
{
	this->debugOnDrive1541 = debugOnDrive1541;
}

void C64DebugInterface::SetTemporaryDrive1541BreakpointPC(int address)
{
	this->temporaryDrive1541BreakpointPC = address;
}

int C64DebugInterface::GetTemporaryDrive1541BreakpointPC()
{
	return this->temporaryDrive1541BreakpointPC;
}

CImageData *C64DebugInterface::GetScreenImageData()
{
	SYS_FatalExit("C64DebugInterface::GetScreenImageData");
	return NULL;
}

void C64DebugInterface::Reset()
{
	SYS_FatalExit("C64DebugInterface::Reset");
}

void C64DebugInterface::HardReset()
{
	SYS_FatalExit("C64DebugInterface::HardReset");
}

void C64DebugInterface::DiskDriveReset()
{
	SYS_FatalExit("C64DebugInterface::DiskDriveReset");
}

void C64DebugInterface::KeyboardDown(uint32 mtKeyCode)
{
	SYS_FatalExit("C64DebugInterface::KeyboardDown");
}

void C64DebugInterface::KeyboardUp(uint32 mtKeyCode)
{
	SYS_FatalExit("C64DebugInterface::KeyboardUp");
}

void C64DebugInterface::JoystickDown(int port, uint32 axis)
{
	SYS_FatalExit("C64DebugInterface::JoystickDown");
}

void C64DebugInterface::JoystickUp(int port, uint32 axis)
{
	SYS_FatalExit("C64DebugInterface::JoystickUp");
}

int C64DebugInterface::GetCpuPC()
{
	SYS_FatalExit("C64DebugInterface::GetCpuPC");
	return 0;
}

int C64DebugInterface::GetDrive1541PC()
{
	SYS_FatalExit("C64DebugInterface::GetDrive1541PC");
	return 0;
}

void C64DebugInterface::GetC64CpuState(C64StateCPU *state)
{
	SYS_FatalExit("C64DebugInterface::GetC64CpuState");
}

void C64DebugInterface::GetDrive1541CpuState(C64StateCPU *state)
{
	SYS_FatalExit("C64DebugInterface::GetDrive1541CpuState");
}

void C64DebugInterface::GetVICState(C64StateVIC *state)
{
	SYS_FatalExit("C64DebugInterface::GetVICState");
}

void C64DebugInterface::GetDrive1541State(C64StateDrive1541 *state)
{
	SYS_FatalExit("C64DebugInterface::GetDrive1541State");
}

//
void C64DebugInterface::SetStackPointerC64(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetStackPointerC64");
}

void C64DebugInterface::SetRegisterAC64(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterAC64");
}

void C64DebugInterface::SetRegisterXC64(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterXC64");
}

void C64DebugInterface::SetRegisterYC64(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterYC64");
}

void C64DebugInterface::SetRegisterPC64(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterPC64");
}

void C64DebugInterface::SetStackPointer1541(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetStackPointer1541");
}

void C64DebugInterface::SetRegisterA1541(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterA1541");
}

void C64DebugInterface::SetRegisterX1541(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterX1541");
}

void C64DebugInterface::SetRegisterY1541(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterY1541");
}

void C64DebugInterface::SetRegisterP1541(uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetRegisterP1541");
}

void C64DebugInterface::InsertD64(CSlrString *path)
{
	SYS_FatalExit("C64DebugInterface::InsertD64");
}

void C64DebugInterface::DetachDriveDisk()
{
	SYS_FatalExit("C64DebugInterface::DetachDriveDisk");
}

void C64DebugInterface::MakeBasicRunC64()
{
	SYS_FatalExit("C64DebugInterface::MakeBasicRunC64");
}

bool C64DebugInterface::GetSettingIsWarpSpeed()
{
	SYS_FatalExit("C64DebugInterface::GetSettingIsWarpSpeed");
	return false;
}

void C64DebugInterface::SetSettingIsWarpSpeed(bool isWarpSpeed)
{
	SYS_FatalExit("C64DebugInterface::SetSettingIsWarpSpeed");
}

void C64DebugInterface::GetSidTypes(std::vector<CSlrString *> *sidTypes)
{
	SYS_FatalExit("C64DebugInterface::GetSidTypes");
}

void C64DebugInterface::SetSidType(int sidType)
{
	SYS_FatalExit("C64DebugInterface::SetSidType");
}

// samplingMethod: Fast=0, Interpolating=1, Resampling=2, Fast Resampling=3
void C64DebugInterface::SetSidSamplingMethod(int samplingMethod)
{
	SYS_FatalExit("C64DebugInterface::SetSidSamplingMethod");
}

// emulateFilters: no=0, yes=1
void C64DebugInterface::SetSidEmulateFilters(int emulateFilters)
{
	SYS_FatalExit("C64DebugInterface::SetSidEmulateFilters");
}

// passband: 0-90
void C64DebugInterface::SetSidPassBand(int passband)
{
	SYS_FatalExit("C64DebugInterface::SetSidPassBand");
}

// filterBias: -500 500
void C64DebugInterface::SetSidFilterBias(int filterBias)
{
	SYS_FatalExit("C64DebugInterface::SetSidFilterBias");
}

void C64DebugInterface::SetSidStereo(int stereoMode)
{
	SYS_FatalExit("C64DebugInterface::SetSidStereo");
}

void C64DebugInterface::SetSidStereoAddress(uint16 sidAddress)
{
	SYS_FatalExit("C64DebugInterface::SetSidStereoAddress");
}

void C64DebugInterface::SetSidTripleAddress(uint16 sidAddress)
{
	SYS_FatalExit("C64DebugInterface::SetSidTripleAddress");
}

void C64DebugInterface::GetC64ModelTypes(std::vector<CSlrString *> *modelTypeNames, std::vector<int> *modelTypeIds)
{
	SYS_FatalExit("C64DebugInterface::GetC64ModelTypes");
}

void C64DebugInterface::SetC64ModelType(int modelType)
{
	SYS_FatalExit("C64DebugInterface::SetC64ModelType");
}

void C64DebugInterface::SetPatchKernalFastBoot(bool isPatchKernal)
{
	SYS_FatalExit("C64DebugInterface::SetPatchKernalFastBoot");
}

void C64DebugInterface::SetRunSIDWhenInWarp(bool isRunningSIDInWarp)
{
	SYS_FatalExit("C64DebugInterface::SetRunSIDWhenInWarp");
}

void C64DebugInterface::SetEmulationMaximumSpeed(int maximumSpeed)
{
	SYS_FatalExit("C64DebugInterface::SetEmulationMaximumSpeed");
}

void C64DebugInterface::SetVSPBugEmulation(bool isVSPBugEmulation)
{
	SYS_FatalExit("C64DebugInterface::SetVSPBugEmulation");
}

void C64DebugInterface::SetByteC64(uint16 addr, uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetByteC64");
}

void C64DebugInterface::SetByteToRamC64(uint16 addr, uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetByteToRamC64");
}

uint8 C64DebugInterface::GetByteC64(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::GetByteC64");
	return 0;
}

uint8 C64DebugInterface::GetByteFromRamC64(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::GetByteFromRamC64");
	return 0;
}

void C64DebugInterface::MakeJmpNoReset(CSlrDataAdapter *dataAdapter, uint16 addr)
{
	if (dataAdapter == this->dataAdapterC64 || dataAdapter == this->dataAdapterC64DirectRam)
	{
		this->MakeJmpNoResetC64(addr);
	}
	else
	{
		this->MakeJmpNoReset1541(addr);
	}
}

void C64DebugInterface::MakeJmpAndReset(uint16 addr)
{
	this->MakeJmpC64(addr);
}

void C64DebugInterface::MakeJmpC64(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::MakeJmpC64");
}

void C64DebugInterface::MakeJmpNoResetC64(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::MakeJmpNoResetC64");
}

void C64DebugInterface::MakeJsrC64(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::MakeJsrC64");
}

void C64DebugInterface::MakeJmpNoReset1541(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::MakeJmpNoReset1541");
}

void C64DebugInterface::SetByte1541(uint16 addr, uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetByte1541");
}

void C64DebugInterface::SetByteToRam1541(uint16 addr, uint8 val)
{
	SYS_FatalExit("C64DebugInterface::SetByteToRam1541");
}

uint8 C64DebugInterface::GetByte1541(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::GetByte1541");
	return 0;
}

uint8 C64DebugInterface::GetByteFromRam1541(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::GetByteFromRam1541");
	return 0;
}

void C64DebugInterface::MakeJmp1541(uint16 addr)
{
	SYS_FatalExit("C64DebugInterface::MakeJmp1541");
}

void C64DebugInterface::GetWholeMemoryMap(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMap");
}

void C64DebugInterface::GetWholeMemoryMapFromRam(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMapFromRam");
}

void C64DebugInterface::GetWholeMemoryMap1541(uint8 *buffer)
{	
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMap1541");
}

void C64DebugInterface::GetWholeMemoryMapFromRam1541(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMapFromRam1541");
}

void C64DebugInterface::GetMemory(uint8 *buffer, int addrStart, int addrEnd)
{
	SYS_FatalExit("C64DebugInterface::GetMemory");
}

void C64DebugInterface::GetMemoryFromRam(uint8 *buffer, int addrStart, int addrEnd)
{
	SYS_FatalExit("C64DebugInterface::GetMemoryFromRam");
}

void C64DebugInterface::GetMemoryDrive1541(uint8 *buffer, int addrStart, int addrEnd)
{
	SYS_FatalExit("C64DebugInterface::GetMemoryDrive1541");
}

void C64DebugInterface::GetMemoryFromRamDrive1541(uint8 *buffer, int addrStart, int addrEnd)
{	
	SYS_FatalExit("C64DebugInterface::GetMemoryFromRamDrive1541");
}

void C64DebugInterface::FillC64Ram(uint16 addr, uint16 size, uint8 value)
{
	SYS_FatalExit("C64DebugInterface::FillC64Ram");
}

bool C64DebugInterface::LoadFullSnapshot(CByteBuffer *snapshotBuffer)
{
	SYS_FatalExit("C64DebugInterface::LoadFullSnapshot");
	return false;
}

void C64DebugInterface::SaveFullSnapshot(CByteBuffer *snapshotBuffer)
{
	SYS_FatalExit("C64DebugInterface::SaveFullSnapshot");
}

bool C64DebugInterface::LoadFullSnapshot(char *filePath)
{
	SYS_FatalExit("C64DebugInterface::LoadFullSnapshot");
	return false;
}

void C64DebugInterface::SaveFullSnapshot(char *filePath)
{
	SYS_FatalExit("C64DebugInterface::SaveFullSnapshot");	
}

void C64DebugInterface::GetVICColors(uint8 *cD021, uint8 *cD022, uint8 *cD023, uint8 *cD025, uint8 *cD026, uint8 *cD027, uint8 *cD800)
{
	SYS_FatalExit("C64DebugInterface::GetVICColors");
}

void C64DebugInterface::GetVICSpriteColors(uint8 *cD021, uint8 *cD025, uint8 *cD026, uint8 *spriteColors)
{
	SYS_FatalExit("C64DebugInterface::GetVICSpriteColors");
}

void C64DebugInterface::GetCBMColor(uint8 colorNum, uint8 *r, uint8 *g, uint8 *b)
{
	SYS_FatalExit("C64DebugInterface::GetCBMColor");
}

void C64DebugInterface::GetFloatCBMColor(uint8 colorNum, float *r, float *g, float *b)
{
	SYS_FatalExit("C64DebugInterface::GetFloatCBMColor");
}

//

void C64DebugInterface::MarkC64CellRead(uint16 addr)
{
	viewC64->viewC64MemoryMap->CellRead(addr);
}

void C64DebugInterface::MarkC64CellWrite(uint16 addr, uint8 value)
{
	viewC64->viewC64MemoryMap->CellWrite(addr, value);
}

void C64DebugInterface::MarkDrive1541CellRead(uint16 addr)
{
	viewC64->viewDrive1541MemoryMap->CellRead(addr);
}

void C64DebugInterface::MarkDrive1541CellWrite(uint16 addr, uint8 value)
{
	viewC64->viewDrive1541MemoryMap->CellWrite(addr, value);
}

//

//void C64DebugInterface::UiInsertD64(CSlrString *path)
//{
//	SYS_FatalExit("C64DebugInterface::UiInsertD64");
////	LOGTODO("C64DebugInterface::UiInsertD64: shall we update Folder path to D64?");
////	viewC64->viewC64MainMenu->InsertD64(path, false, c64SettingsAutoJmpFromInsertedDiskFirstPrg, 0);
//}

//
void C64DebugInterface::SetVicRegister(uint8 registerNum, uint8 value)
{
	SYS_FatalExit("C64DebugInterface::SetVicRegister");
}

u8 C64DebugInterface::GetVicRegister(uint8 registerNum)
{
	SYS_FatalExit("C64DebugInterface::GetVicRegister");
	return 0;
}

u8 C64DebugInterface::GetVicRegister(vicii_cycle_state_t *viciiState, uint8 registerNum)
{
	return viciiState->regs[registerNum];
}


void C64DebugInterface::SetCiaRegister(uint8 ciaId, uint8 registerNum, uint8 value)
{
	SYS_FatalExit("C64DebugInterface::SetCiaRegister");
}

u8 C64DebugInterface::GetCiaRegister(uint8 ciaId, uint8 registerNum)
{
	SYS_FatalExit("C64DebugInterface::GetCiaRegister");
	return 0;
}

void C64DebugInterface::SetSidRegister(uint8 sidId, uint8 registerNum, uint8 value)
{
	SYS_FatalExit("C64DebugInterface::SetSidRegister");
}

u8 C64DebugInterface::GetSidRegister(uint8 sidId, uint8 registerNum)
{
	SYS_FatalExit("C64DebugInterface::GetSidRegister");
	return 0;
}

void C64DebugInterface::SetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum, uint8 value)
{
	SYS_FatalExit("C64DebugInterface::SetViaRegister");
}

u8 C64DebugInterface::GetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum)
{
	SYS_FatalExit("C64DebugInterface::GetViaRegister");
	return 0;
}


void C64DebugInterface::SetSIDMuteChannels(int sidNumber, bool mute1, bool mute2, bool mute3, bool muteExt)
{
	SYS_FatalExit("C64DebugInterface::SetSIDMuteChannels");
}

void C64DebugInterface::SetSIDReceiveChannelsData(int sidNumber, bool isReceiving)
{
	SYS_FatalExit("C64DebugInterface::SetSIDReceiveChannelsData");
}

void C64DebugInterface::SetVicRecordStateMode(uint8 recordMode)
{
	SYS_FatalExit("C64DebugInterface::SetVicRecordStateMode");
}

bool C64DebugInterface::IsCpuJam()
{
	SYS_FatalExit("C64DebugInterface::IsCpuJam");
	return false;
}

void C64DebugInterface::ForceRunAndUnJamCpu()
{
	SYS_FatalExit("C64DebugInterface::ForceRunAndUnJamCpu");
}


//
void C64DebugInterface::AttachTape(CSlrString *filePath)
{
	SYS_FatalExit("C64DebugInterface::AttachTape");
}

void C64DebugInterface::DetachTape()
{
	SYS_FatalExit("C64DebugInterface::DetachTape");
}

void C64DebugInterface::DatasettePlay()
{
	SYS_FatalExit("C64DebugInterface::DatasettePlay");
}

void C64DebugInterface::DatasetteStop()
{
	SYS_FatalExit("C64DebugInterface::DatasetteStop");
}

void C64DebugInterface::DatasetteForward()
{
	SYS_FatalExit("C64DebugInterface::DatasetteForward");
}

void C64DebugInterface::DatasetteRewind()
{
	SYS_FatalExit("C64DebugInterface::DatasetteRewind");
}

void C64DebugInterface::DatasetteRecord()
{
	SYS_FatalExit("C64DebugInterface::DatasetteRecord");
}

void C64DebugInterface::DatasetteReset()
{
	SYS_FatalExit("C64DebugInterface::DatasetteReset");
}

void C64DebugInterface::DatasetteSetSpeedTuning(int speedTuning)
{
}

void C64DebugInterface::DatasetteSetZeroGapDelay(int zeroGapDelay)
{
}

void C64DebugInterface::DatasetteSetResetWithCPU(bool resetWithCPU)
{
}

void C64DebugInterface::DatasetteSetTapeWobble(int tapeWobble)
{
}

void C64DebugInterface::AttachCartridge(CSlrString *filePath)
{
	SYS_FatalExit("C64DebugInterface::AttachCartridge");
}

void C64DebugInterface::DetachCartridge()
{
	SYS_FatalExit("C64DebugInterface::DetachCartridge");
}

void C64DebugInterface::CartridgeFreezeButtonPressed()
{
	SYS_FatalExit("C64DebugInterface::CartridgeFreezeButtonPressed");
}

void C64DebugInterface::GetC64CartridgeState(C64StateCartridge *cartridgeState)
{
	SYS_FatalExit("C64DebugInterface::GetC64CartridgeState");
}

void C64DebugInterface::SetPalette(uint8 *palette)
{
	SYS_FatalExit("C64DebugInterface::SetPalette");
}

void C64DebugInterface::SetRunSIDEmulation(bool isSIDEmulationOn)
{
	SYS_FatalExit("C64DebugInterface::SetRunSIDEmulation");
}

void C64DebugInterface::SetAudioVolume(float volume)
{
	SYS_FatalExit("C64DebugInterface::SetAudioVolume");
}

CSlrDataAdapter *C64DebugInterface::GetDataAdapter()
{
	return this->dataAdapterC64;
}

