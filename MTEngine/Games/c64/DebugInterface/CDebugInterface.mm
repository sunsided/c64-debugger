#include "CDebugInterface.h"
#include "CViewC64.h"
#include "SYS_Threading.h"
#include "C64SettingsStorage.h"
#include "CDebuggerEmulatorPlugin.h"

CDebugInterface::CDebugInterface(CViewC64 *viewC64)
{
	this->viewC64 = viewC64;

	isRunning = false;
	isSelected = false;
	
	breakpointsMutex = new CSlrMutex();
	renderScreenMutex = new CSlrMutex();
	ioMutex = new CSlrMutex();
	
	breakOnPC = false;
	breakOnMemory = false;
	breakOnRaster = false;

	screenSupersampleFactor = c64SettingsScreenSupersampleFactor;
	
	temporaryBreakpointPC = -1;

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

void CDebugInterface::DoFrame()
{
	for (std::list<CDebuggerEmulatorPlugin *>::iterator it = this->plugins.begin(); it != this->plugins.end(); it++)
	{
		CDebuggerEmulatorPlugin *plugin = *it;
		plugin->DoFrame();
	}
}

void CDebugInterface::CreateScreenData()
{
	screenImage = new CImageData(512 * this->screenSupersampleFactor, 512 * this->screenSupersampleFactor, IMG_TYPE_RGBA);
	screenImage->AllocImage(false, true);
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
void CDebugInterface::RegisterPlugin(CDebuggerEmulatorPlugin *plugin)
{
	this->plugins.push_back(plugin);
}

void CDebugInterface::RemovePlugin(CDebuggerEmulatorPlugin *plugin)
{
	this->plugins.remove(plugin);
}

//
void CDebugInterface::LockMutex()
{
	//	LOGD("CDebugInterface::LockMutex");
	breakpointsMutex->Lock();
}

void CDebugInterface::UnlockMutex()
{
	//	LOGD("CDebugInterface::UnlockMutex");
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
