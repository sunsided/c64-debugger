#include "C64DebugInterface.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "CViewMainMenu.h"
#include "CViewC64StateSID.h"
#include "CByteBuffer.h"

C64DebugInterface::C64DebugInterface(CViewC64 *viewC64)
{
	this->viewC64 = viewC64;
	
	emulationSpeed = 0;
	emulationFrameRate = 0;	

	breakpointsMutex = new CSlrMutex();
	renderScreenMutex = new CSlrMutex();
	ioMutex = new CSlrMutex();

	breakOnC64IrqVIC = false;
	breakOnC64IrqCIA = false;
	breakOnC64IrqNMI = false;
	breakOnC64PC = false;
	breakOnC64Memory = false;
	breakOnC64Raster = false;
	
	breakOnDrive1541IrqVIA1 = false;
	breakOnDrive1541IrqVIA2 = false;
	breakOnDrive1541IrqIEC = false;
	breakOnDrive1541PC = false;
	breakOnDrive1541Memory = false;

	temporaryC64BreakpointPC = -1;
	temporaryDrive1541BreakpointPC = -1;

	debugMode = C64_DEBUG_RUNNING;
	debugOnC64 = true;
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

void C64DebugInterface::InitKeyMap(C64KeyMap *keyMap)
{
	SYS_FatalExit("C64DebugInterface::InitKeyMap");
}

uint8 *C64DebugInterface::GetCharRom()
{
	SYS_FatalExit("C64DebugInterface::GetCharRom");
	return NULL;
}

void C64DebugInterface::LockMutex()
{
	breakpointsMutex->Lock();
}

void C64DebugInterface::UnlockMutex()
{
	breakpointsMutex->Unlock();
}

void C64DebugInterface::LockRenderScreenMutex()
{
	renderScreenMutex->Lock();
}

void C64DebugInterface::UnlockRenderScreenMutex()
{
	renderScreenMutex->Unlock();
}

void C64DebugInterface::LockIoMutex()
{
	ioMutex->Lock();
}

void C64DebugInterface::UnlockIoMutex()
{
	ioMutex->Unlock();
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
	ClearAddrBreakpoints(&(this->breakpointsC64PC));
	ClearAddrBreakpoints(&(this->breakpointsC64Raster));
	ClearAddrBreakpoints(&(this->breakpointsDrive1541PC));
	
	ClearMemoryBreakpoints(&(this->breakpointsC64Memory));
	ClearMemoryBreakpoints(&(this->breakpointsDrive1541Memory));
}

void C64DebugInterface::ClearAddrBreakpoints(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap)
{
	while(!breakpointsMap->empty())
	{
		std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->begin();
		C64AddrBreakpoint *breakpoint = it->second;
		
		breakpointsMap->erase(it);
		delete breakpoint;
	}
}

void C64DebugInterface::ClearMemoryBreakpoints(std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap)
{
	while(!breakpointsMap->empty())
	{
		std::map<uint16, C64MemoryBreakpoint *>::iterator it = breakpointsMap->begin();
		C64MemoryBreakpoint *breakpoint = it->second;
		
		breakpointsMap->erase(it);
		delete breakpoint;
	}
}


void C64DebugInterface::AddAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, C64AddrBreakpoint *breakpoint)
{
	(*breakpointsMap)[breakpoint->addr] = breakpoint;
	
	if (breakpointsMap == &(this->breakpointsC64PC))
	{
		breakOnC64PC = true;
	}
	else if (breakpointsMap == &(this->breakpointsC64Raster))
	{
		breakOnC64Raster = true;
	}
	else if (breakpointsMap == &(this->breakpointsDrive1541PC))
	{
		breakOnDrive1541PC = true;
	}
}

void C64DebugInterface::RemoveAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, uint16 addr)
{
	std::map<uint16, C64AddrBreakpoint *>::iterator it = breakpointsMap->find(addr);
	C64AddrBreakpoint *breakpoint = it->second;
	breakpointsMap->erase(it);
	delete breakpoint;
	
	if (breakpointsMap->empty())
	{
		if (breakpointsMap == &(this->breakpointsC64PC))
		{
			breakOnC64PC = false;
		}
		else if (breakpointsMap == &(this->breakpointsC64Raster))
		{
			breakOnC64Raster = false;
		}
		else if (breakpointsMap == &(this->breakpointsDrive1541PC))
		{
			breakOnDrive1541PC = false;
		}
	}
}


// video

int C64DebugInterface::GetC64ScreenSizeX()
{
	return -1;
}

int C64DebugInterface::GetC64ScreenSizeY()
{
	return -1;
}

void C64DebugInterface::SetDebugOnC64(bool debugOnC64)
{
	this->debugOnC64 = debugOnC64;
}

void C64DebugInterface::SetDebugOnDrive1541(bool debugOnDrive1541)
{
	this->debugOnDrive1541 = debugOnDrive1541;
}

void C64DebugInterface::SetDebugMode(uint8 debugMode)
{
	this->debugMode = debugMode;
}

uint8 C64DebugInterface::GetDebugMode()
{
	return this->debugMode;
}

// address -1 means no breakpoint
void C64DebugInterface::SetTemporaryC64BreakpointPC(int address)
{
	this->temporaryC64BreakpointPC = address;
}

int C64DebugInterface::GetTemporaryC64BreakpointPC()
{
	return this->temporaryC64BreakpointPC;
}

void C64DebugInterface::SetTemporaryDrive1541BreakpointPC(int address)
{
	this->temporaryDrive1541BreakpointPC = address;
}

int C64DebugInterface::GetTemporaryDrive1541BreakpointPC()
{
	return this->temporaryDrive1541BreakpointPC;
}

CImageData *C64DebugInterface::GetC64ScreenImageData()
{
	SYS_FatalExit("C64DebugInterface::GetC64ScreenImageData");
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

int C64DebugInterface::GetC64CpuPC()
{
	SYS_FatalExit("C64DebugInterface::GetC64CpuPC");
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

bool C64DebugInterface::GetSettingUseKeyboardForJoystick()
{
	SYS_FatalExit("C64DebugInterface::GetSettingUseKeyboardForJoystick");
	return false;
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

void C64DebugInterface::SetSettingUseKeyboardForJoystick(bool isJoystickOn)
{
	SYS_FatalExit("C64DebugInterface::SetSettingUseKeyboardForJoystick");
}

void C64DebugInterface::SetKeyboardJoystickPort(uint8 joystickPort)
{
	SYS_FatalExit("C64DebugInterface::SetKeyboardJoystickPort");
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

void C64DebugInterface::GetWholeMemoryMapC64(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMapC64");
}

void C64DebugInterface::GetWholeMemoryMapFromRamC64(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMapFromRamC64");
}

void C64DebugInterface::GetWholeMemoryMap1541(uint8 *buffer)
{	
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMap1541");
}

void C64DebugInterface::GetWholeMemoryMapFromRam1541(uint8 *buffer)
{
	SYS_FatalExit("C64DebugInterface::GetWholeMemoryMapFromRam1541");
}

void C64DebugInterface::GetMemoryC64(uint8 *buffer, int addrStart, int addrEnd)
{
	SYS_FatalExit("C64DebugInterface::GetMemoryC64");
}

void C64DebugInterface::GetMemoryFromRamC64(uint8 *buffer, int addrStart, int addrEnd)
{
	SYS_FatalExit("C64DebugInterface::GetMemoryFromRamC64");
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

void C64DebugInterface::UiInsertD64(CSlrString *path)
{
	LOGTODO("C64DebugInterface::UiInsertD64: shall we update Folder path to D64?");
	viewC64->viewC64MainMenu->InsertD64(path, false);
}

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


void C64DebugInterface::RenderStateVIC(vicii_cycle_state_t *viciiState,
									   float posX, float posY, float posZ, bool isVertical, bool showSprites, CSlrFont *fontBytes, float fontSize,
									   std::vector<CImageData *> *spritesImageData, std::vector<CSlrImage *> *spritesImages, bool renderDataWithColors)
{
	SYS_FatalExit("C64DebugInterface::RenderStateVIC");
}

void C64DebugInterface::RenderStateDrive1541(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize,
											 bool renderVia1, bool renderVia2, bool renderDriveLed,
											 bool isVertical)
{
	SYS_FatalExit("C64DebugInterface::RenderStateDrive1541");
}

void C64DebugInterface::RenderStateCIA(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId)
{
	SYS_FatalExit("C64DebugInterface::RenderStateCIA");
}

void C64DebugInterface::RenderStateSID(uint16 sidBase, float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize)
{
	SYS_FatalExit("C64DebugInterface::RenderStateSID");	
}

void C64DebugInterface::SetSIDMuteChannels(bool mute1, bool mute2, bool mute3, bool muteExt)
{
	SYS_FatalExit("C64DebugInterface::SetSIDMuteChannels");
}

void C64DebugInterface::SetSIDReceiveChannelsData(bool isReceiving)
{
	SYS_FatalExit("C64DebugInterface::SetSIDReceiveChannelsData");
}

void C64DebugInterface::AddSIDWaveformData(int v1, int v2, int v3, short mix)
{
	this->viewC64->viewC64StateSID->AddWaveformData(v1, v2, v3, mix);
}

void C64DebugInterface::SetVicRecordStateMode(uint8 recordMode)
{
	SYS_FatalExit("C64DebugInterface::SetVicRecordStateMode");
}

bool C64DebugInterface::IsCpuJam()
{
	SYS_FatalExit("C64DebugInterface::IsCpuJam");
}

void C64DebugInterface::ForceRunAndUnJamCpu()
{
	SYS_FatalExit("C64DebugInterface::ForceRunAndUnJamCpu");
}


//


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


