#include "CDebugInterface.h"
#include "CViewC64.h"
#include "SYS_Threading.h"
#include "C64SettingsStorage.h"
#include "CDebuggerEmulatorPlugin.h"

CDebugInterface::CDebugInterface(CViewC64 *viewC64)
{
	this->viewC64 = viewC64;

	snapshotsManager = NULL;
	symbols = NULL;
	codeMonitorCallback = NULL;

	isRunning = false;
	isSelected = false;
	
	breakpointsMutex = new CSlrMutex("CDebugInterface::breakpointsMutex");
	renderScreenMutex = new CSlrMutex("CDebugInterface::renderScreenMutex");
	ioMutex = new CSlrMutex("CDebugInterface::ioMutex");
	
	breakOnPC = false;
	breakOnMemory = false;
	breakOnRaster = false;

	screenSupersampleFactor = c64SettingsScreenSupersampleFactor;
	
	temporaryBreakpointPC = -1;
	
	emulationFrameCounter = 0;
	
	this->debugMode = DEBUGGER_MODE_RUNNING;
}

CDebugInterface::~CDebugInterface()
{
}

void CDebugInterface::Shutdown()
{
	this->SetDebugMode(DEBUGGER_MODE_SHUTDOWN);
}

int CDebugInterface::GetEmulatorType()
{
	return EMULATOR_TYPE_UNKNOWN;
}

CSlrString *CDebugInterface::GetEmulatorVersionString()
{
	return NULL;
}

CSlrString *CDebugInterface::GetPlatformNameString()
{
	return NULL;
}

float CDebugInterface::GetEmulationFPS()
{
	return -1;
}

void CDebugInterface::RunEmulationThread()
{
}

void CDebugInterface::InitPlugins()
{
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		plugin->Init();
	}
}

// all cycles in frame finished, vsync
void CDebugInterface::DoVSync()
{
	emulationFrameCounter++;
	
//	LOGD("DoVSync: frame=%d", emulationFrameCounter);
	
	viewC64->EmulationStartFrameCallback();

}

// frame is painted on canvas and ready to be consumed
void CDebugInterface::DoFrame()
{
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		plugin->DoFrame();
	}
}

unsigned int CDebugInterface::GetMainCpuCycleCounter()
{
	LOGError("CDebugInterface::GetMainCpuCycleCounter: not implemented");
	return 0;
}

void CDebugInterface::ResetMainCpuDebugCycleCounter()
{
	LOGError("CDebugInterface::ResetMainCpuDebugCycleCounter: not implemented");
}

unsigned int CDebugInterface::GetMainCpuDebugCycleCounter()
{
	LOGError("CDebugInterface::GetMainCpuDebugCycleCounter: not implemented");
	return 0;
}

unsigned int CDebugInterface::GetPreviousCpuInstructionCycleCounter()
{
	LOGError("CDebugInterface::GetPreviousCpuInstructionCycleCounter: not implemented");
	return 0;
}

void CDebugInterface::ResetEmulationFrameCounter()
{
	this->emulationFrameCounter = 0;
}


unsigned int CDebugInterface::GetEmulationFrameNumber()
{
	return this->emulationFrameCounter;
}

void CDebugInterface::CreateScreenData()
{
	screenImage = new CImageData(512 * this->screenSupersampleFactor, 512 * this->screenSupersampleFactor, IMG_TYPE_RGBA);
	screenImage->AllocImage(false, true);
}

void CDebugInterface::RefreshScreenNoCallback()
{
	SYS_FatalExit("CDebugInterface::RefreshScreenNoCallback");
}


void CDebugInterface::SetSupersampleFactor(int factor)
{
	LOGM("CDebugInterface::SetSupersampleFactor: %d", factor);
	this->LockRenderScreenMutex();
	
	this->screenSupersampleFactor = factor;
	
	delete screenImage;
	CreateScreenData();
	
	this->UnlockRenderScreenMutex();
}

CImageData *CDebugInterface::GetScreenImageData()
{
//	LOGD("CDebugInterface::GetScreenImageData");
	return this->screenImage;
}

CSlrDataAdapter *CDebugInterface::GetDataAdapter()
{
	SYS_FatalExit("CDebugInterface::GetDataAdapter");
	return NULL;
}

bool CDebugInterface::LoadExecutable(char *fullFilePath)
{
	SYS_FatalExit("CDebugInterface::LoadExecutable");
	return false;
}

bool CDebugInterface::MountDisk(char *fullFilePath, int diskNo, bool readOnly)
{
	SYS_FatalExit("CDebugInterface::MountDisk");
	return false;
}

bool CDebugInterface::LoadFullSnapshot(char *filePath)
{
	return false;
}

void CDebugInterface::SaveFullSnapshot(char *filePath)
{
}

bool CDebugInterface::LoadChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
	return false;
}

bool CDebugInterface::SaveChipsSnapshotSynced(CByteBuffer *byteBuffer)
{
	return false;
}

bool CDebugInterface::LoadDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	return false;
}

bool CDebugInterface::SaveDiskDataSnapshotSynced(CByteBuffer *byteBuffer)
{
	return false;
}

bool CDebugInterface::IsDriveDirtyForSnapshot()
{
	SYS_FatalExit("CDebugInterface::IsDriveDirtyForSnapshot");
	return false;
}

void CDebugInterface::ClearDriveDirtyForSnapshotFlag()
{
	SYS_FatalExit("CDebugInterface::ClearDriveDirtyForSnapshotFlag");
}

int CDebugInterface::GetScreenSizeX()
{
	return -1;
}

int CDebugInterface::GetScreenSizeY()
{
	return -1;
}

// keyboard & joystick mapper
void CDebugInterface::KeyboardDown(uint32 mtKeyCode)
{
}

void CDebugInterface::KeyboardUp(uint32 mtKeyCode)
{
}

void CDebugInterface::JoystickDown(int port, uint32 axis)
{
}

void CDebugInterface::JoystickUp(int port, uint32 axis)
{
}

void CDebugInterface::MouseDown(float x, float y)
{
}

void CDebugInterface::MouseMove(float x, float y)
{
}

void CDebugInterface::MouseUp(float x, float y)
{
}

// state
int CDebugInterface::GetCpuPC()
{
	SYS_FatalExit("CDebugInterface::GetCpuPC");
	return -1;
}

void CDebugInterface::GetWholeMemoryMap(uint8 *buffer)
{
	SYS_FatalExit("CDebugInterface::GetWholeMemoryMap");
}

void CDebugInterface::GetWholeMemoryMapFromRam(uint8 *buffer)
{
	SYS_FatalExit("CDebugInterface::GetWholeMemoryMap");
}

//
void CDebugInterface::SetDebugMode(uint8 debugMode)
{
	this->debugMode = debugMode;
}

uint8 CDebugInterface::GetDebugMode()
{
	return this->debugMode;
}

void CDebugInterface::Reset()
{
	SYS_FatalExit("CDebugInterface::Reset");
}

void CDebugInterface::HardReset()
{
	SYS_FatalExit("CDebugInterface::HardReset");
}

void CDebugInterface::SetDebugOn(bool debugOn)
{
	this->isDebugOn = debugOn;
}

bool CDebugInterface::GetSettingIsWarpSpeed()
{
	return false;
}

void CDebugInterface::SetSettingIsWarpSpeed(bool isWarpSpeed)
{
	LOGError("CDebugInterface::SetSettingIsWarpSpeed: not implemented");
}

//
// make jmp without resetting CPU depending on dataAdapter
void CDebugInterface::MakeJmpNoReset(CSlrDataAdapter *dataAdapter, uint16 addr)
{
	SYS_FatalExit("CDebugInterface::MakeJmpNoReset");
}

// make jmp and reset CPU
void CDebugInterface::MakeJmpAndReset(uint16 addr)
{
	SYS_FatalExit("CDebugInterface::MakeJmpAndReset");
}


//
void CDebugInterface::ClearBreakpoints()
{
	ClearAddrBreakpoints(&(this->breakpointsPC));
	ClearMemoryBreakpoints(&(this->breakpointsMemory));
	ClearAddrBreakpoints(&(this->breakpointsRaster));
}

void CDebugInterface::ClearAddrBreakpoints(std::map<uint16, CAddrBreakpoint *> *breakpointsMap)
{
	while(!breakpointsMap->empty())
	{
		std::map<uint16, CAddrBreakpoint *>::iterator it = breakpointsMap->begin();
		CAddrBreakpoint *breakpoint = it->second;
		
		breakpointsMap->erase(it);
		delete breakpoint;
	}
}

void CDebugInterface::ClearMemoryBreakpoints(std::map<uint16, CMemoryBreakpoint *> *breakpointsMap)
{
	while(!breakpointsMap->empty())
	{
		std::map<uint16, CMemoryBreakpoint *>::iterator it = breakpointsMap->begin();
		CMemoryBreakpoint *breakpoint = it->second;
		
		breakpointsMap->erase(it);
		delete breakpoint;
	}
}


void CDebugInterface::AddAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, CAddrBreakpoint *breakpoint)
{
	(*breakpointsMap)[breakpoint->addr] = breakpoint;
	
	if (breakpointsMap == &(this->breakpointsPC))
	{
		breakOnPC = true;
	}
	else if (breakpointsMap == &(this->breakpointsRaster))
	{
		breakOnRaster = true;
	}
}

void CDebugInterface::RemoveAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, uint16 addr)
{
	std::map<uint16, CAddrBreakpoint *>::iterator it = breakpointsMap->find(addr);
	CAddrBreakpoint *breakpoint = it->second;
	breakpointsMap->erase(it);
	delete breakpoint;
	
	if (breakpointsMap->empty())
	{
		if (breakpointsMap == &(this->breakpointsPC))
		{
			breakOnPC = false;
		}
		else if (breakpointsMap == &(this->breakpointsRaster))
		{
			breakOnRaster = false;
		}
	}
}

// address -1 means no breakpoint
void CDebugInterface::SetTemporaryBreakpointPC(int address)
{
	this->temporaryBreakpointPC = address;
}

int CDebugInterface::GetTemporaryBreakpointPC()
{
	return this->temporaryBreakpointPC;
}

//
CViewDisassemble *CDebugInterface::GetViewMainCpuDisassemble()
{
	return NULL;
}

CViewDisassemble *CDebugInterface::GetViewDriveDisassemble(int driveNo)
{
	return NULL;
}

CViewBreakpoints *CDebugInterface::GetViewBreakpoints()
{
	return NULL;
}

CViewDataWatch *CDebugInterface::GetViewMemoryDataWatch()
{
	return NULL;
}

//
void CDebugInterface::RegisterPlugin(CDebuggerEmulatorPlugin *plugin)
{
	this->plugins.push_back(plugin);
}

void CDebugInterface::RemovePlugin(CDebuggerEmulatorPlugin *plugin)
{
	this->plugins.remove(plugin);
}

//
bool CDebugInterface::IsCodeMonitorSupported()
{
	return false;
}

void CDebugInterface::SetCodeMonitorCallback(CDebugInterfaceCodeMonitorCallback *callback)
{
	this->codeMonitorCallback = callback;	
}

CSlrString *CDebugInterface::GetCodeMonitorPrompt()
{
	// monitor is not supported
	return NULL;
}

bool CDebugInterface::ExecuteCodeMonitorCommand(CSlrString *commandStr)
{
	// monitor is not supported
	return false;
}

// TODO: ADD "#define DEBUGMUTEX" and push/pull names of locks here, list to be displayed when this locks here again
void CDebugInterface::LockMutex()
{
//		LOGD("CDebugInterface::LockMutex");
	breakpointsMutex->Lock();
}

void CDebugInterface::UnlockMutex()
{
//		LOGD("CDebugInterface::UnlockMutex");
	breakpointsMutex->Unlock();
}

void CDebugInterface::LockRenderScreenMutex()
{
	renderScreenMutex->Lock();
}

void CDebugInterface::UnlockRenderScreenMutex()
{
	renderScreenMutex->Unlock();
}

void CDebugInterface::LockIoMutex()
{
	ioMutex->Lock();
}

void CDebugInterface::UnlockIoMutex()
{
	ioMutex->Unlock();
}

void CDebugInterfaceCodeMonitorCallback::CodeMonitorCallbackPrintLine(CSlrString *printLine)
{
	LOGError("CDebugInterfaceCodeMonitorCallback::CodeMonitorCallbackPrintLine: not implemented callback");
}

