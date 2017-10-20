#ifndef _C64DEBUGINTERFACE_H_
#define _C64DEBUGINTERFACE_H_

#include "C64DebugData.h"
#include "CSlrDataAdapter.h"
#include "CByteBuffer.h"
#include "C64DebugTypes.h"

extern "C"
{
#include "ViceWrapper.h"
};

#include <map>

class CViewC64;
class CSlrMutex;
class CSlrString;
class CImageData;
class CSlrImage;
class CSlrFont;
class C64KeyMap;

// abstract class
class C64DebugInterface
{
public:
	C64DebugInterface(CViewC64 *viewC64);
	~C64DebugInterface();
	CViewC64 *viewC64;
	
	virtual int GetEmulatorType();
	
	virtual CSlrString *GetEmulatorVersionString();
	virtual void RunEmulationThread();
	
	virtual void InitKeyMap(C64KeyMap *keyMap);
	
	virtual uint8 *GetCharRom();
	
	float emulationSpeed, emulationFrameRate;
	
	CSlrMutex *breakpointsMutex;
	void LockMutex();
	void UnlockMutex();
	
	CSlrMutex *renderScreenMutex;
	void LockRenderScreenMutex();
	void UnlockRenderScreenMutex();
	
	CSlrMutex *ioMutex;
	void LockIoMutex();
	void UnlockIoMutex();
	
	// c64
	bool debugOnC64;
	bool breakOnC64IrqVIC;
	bool breakOnC64IrqCIA;
	bool breakOnC64IrqNMI;
	
	bool breakOnC64PC;
	std::map<uint16, C64AddrBreakpoint *> breakpointsC64PC;
	bool breakOnC64Memory;
	std::map<uint16, C64MemoryBreakpoint *> breakpointsC64Memory;
	bool breakOnC64Raster;
	std::map<uint16, C64AddrBreakpoint *> breakpointsC64Raster;
	
	// 1541 disk drive
	bool debugOnDrive1541;
	bool breakOnDrive1541IrqVIA1;
	bool breakOnDrive1541IrqVIA2;
	bool breakOnDrive1541IrqIEC;
	bool breakOnDrive1541PC;
	std::map<uint16, C64AddrBreakpoint *> breakpointsDrive1541PC;
	bool breakOnDrive1541Memory;
	std::map<uint16, C64MemoryBreakpoint *> breakpointsDrive1541Memory;
	
	//
	void ClearAddrBreakpoints(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap);
	void AddAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, C64AddrBreakpoint *breakpoint);
	void RemoveAddrBreakpoint(std::map<uint16, C64AddrBreakpoint *> *breakpointsMap, uint16 addr);

	void ClearMemoryBreakpoints(std::map<uint16, C64MemoryBreakpoint *> *breakpointsMap);

	void ClearBreakpoints();

	// data adapters
	CSlrDataAdapter *dataAdapterC64;
	CSlrDataAdapter *dataAdapterC64DirectRam;
	CSlrDataAdapter *dataAdapterDrive1541;
	CSlrDataAdapter *dataAdapterDrive1541DirectRam;
	
	virtual int GetC64ModelType();
	virtual uint8 GetC64MachineType();
	
	virtual int GetC64ScreenSizeX();
	virtual int GetC64ScreenSizeY();
	
	virtual CImageData *GetC64ScreenImageData();
	
	virtual void Reset();
	virtual void HardReset();
	virtual void DiskDriveReset();
	
	// C64 keyboard mapper
	virtual void KeyboardDown(uint32 mtKeyCode);
	virtual void KeyboardUp(uint32 mtKeyCode);
	
	// debugger control
	virtual void SetDebugOnC64(bool debugOnC64);
	virtual void SetDebugOnDrive1541(bool debugOnDrive1541);
	
	virtual void SetDebugMode(uint8 debugMode);
	virtual uint8 GetDebugMode();

	int temporaryC64BreakpointPC;
	virtual int GetTemporaryC64BreakpointPC();
	virtual void SetTemporaryC64BreakpointPC(int address);

	int temporaryDrive1541BreakpointPC;
	virtual int GetTemporaryDrive1541BreakpointPC();
	virtual void SetTemporaryDrive1541BreakpointPC(int address);
	
	// circuitry states
	virtual int GetC64CpuPC();
	virtual int GetDrive1541PC();
	virtual void GetC64CpuState(C64StateCPU *state);
	virtual void GetDrive1541CpuState(C64StateCPU *state);
	virtual void GetVICState(C64StateVIC *state);
	virtual void GetDrive1541State(C64StateDrive1541 *state);
	
	// preferences
	virtual void InsertD64(CSlrString *path);
	virtual void DetachDriveDisk();
	
	virtual bool GetSettingIsWarpSpeed();
	virtual void SetSettingIsWarpSpeed(bool isWarpSpeed);
	virtual bool GetSettingUseKeyboardForJoystick();
	virtual void SetSettingUseKeyboardForJoystick(bool isJoystickOn);
	virtual void SetKeyboardJoystickPort(uint8 joystickPort);

	virtual void GetSidTypes(std::vector<CSlrString *> *sidTypes);
	virtual void SetSidType(int sidType);
	
	// samplingMethod: Fast=0, Interpolating=1, Resampling=2, Fast Resampling=3
	virtual void SetSidSamplingMethod(int samplingMethod);
	// emulateFilters: no=0, yes=1
	virtual void SetSidEmulateFilters(int emulateFilters);
	// passband: 0-90
	virtual void SetSidPassBand(int passband);
	// filterBias: -500 500
	virtual void SetSidFilterBias(int filterBias);

	//
	virtual void GetC64ModelTypes(std::vector<CSlrString *> *modelTypeNames, std::vector<int> *modelTypeIds);
	virtual void SetC64ModelType(int modelType);
	
	virtual void SetEmulationMaximumSpeed(int maximumSpeed);
	
	virtual void SetVSPBugEmulation(bool isVSPBugEmulation);

	// memory access
	virtual void SetByteC64(uint16 addr, uint8 val);
	virtual void SetByteToRamC64(uint16 addr, uint8 val);
	virtual uint8 GetByteC64(uint16 addr);
	virtual uint8 GetByteFromRamC64(uint16 addr);
	
	// make jmp without resetting CPU depending on dataAdapter
	virtual void MakeJmpNoReset(CSlrDataAdapter *dataAdapter, uint16 addr);

	// make jmp and reset CPU
	virtual void MakeJmpC64(uint16 addr);
	
	// make jmp without resetting CPU
	virtual void MakeJmpNoResetC64(uint16 addr);
	
	// make jsr (push PC to stack)
	virtual void MakeJsrC64(uint16 addr);
	
	//
	virtual void SetStackPointerC64(uint8 val);
	virtual void SetRegisterAC64(uint8 val);
	virtual void SetRegisterXC64(uint8 val);
	virtual void SetRegisterYC64(uint8 val);
	virtual void SetRegisterPC64(uint8 val);
	
	///
	virtual void SetStackPointer1541(uint8 val);
	virtual void SetRegisterA1541(uint8 val);
	virtual void SetRegisterX1541(uint8 val);
	virtual void SetRegisterY1541(uint8 val);
	virtual void SetRegisterP1541(uint8 val);
	
	virtual void SetByte1541(uint16 addr, uint8 val);
	virtual void SetByteToRam1541(uint16 addr, uint8 val);
	virtual uint8 GetByte1541(uint16 addr);
	virtual uint8 GetByteFromRam1541(uint16 addr);
	virtual void MakeJmp1541(uint16 addr);
	virtual void MakeJmpNoReset1541(uint16 addr);
	
	// memory access for memory map
	virtual void GetWholeMemoryMapC64(uint8 *buffer);
	virtual void GetWholeMemoryMapFromRamC64(uint8 *buffer);
	virtual void GetWholeMemoryMap1541(uint8 *buffer);
	virtual void GetWholeMemoryMapFromRam1541(uint8 *buffer);

	// memory access
	virtual void GetMemoryC64(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRamC64(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryDrive1541(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRamDrive1541(uint8 *buffer, int addrStart, int addrEnd);
	
	//
	virtual void FillC64Ram(uint16 addr, uint16 size, uint8 value);
	
	//
	virtual void GetVICColors(uint8 *cD021, uint8 *cD022, uint8 *cD023, uint8 *cD025, uint8 *cD026, uint8 *cD027, uint8 *cD800);
	virtual void GetVICSpriteColors(uint8 *cD021, uint8 *cD025, uint8 *cD026, uint8 *spriteColors);
	
	virtual void GetCBMColor(uint8 colorNum, uint8 *r, uint8 *g, uint8 *b);
	virtual void GetFloatCBMColor(uint8 colorNum, float *r, float *g, float *b);

	// cartridge
	virtual void AttachCartridge(CSlrString *filePath);
	virtual void DetachCartridge();
	virtual void CartridgeFreezeButtonPressed();
	virtual void GetC64CartridgeState(C64StateCartridge *cartridgeState);

	
	// snapshots
	virtual bool LoadFullSnapshot(CByteBuffer *snapshotBuffer);
	virtual void SaveFullSnapshot(CByteBuffer *snapshotBuffer);
	virtual bool LoadFullSnapshot(char *filePath);
	virtual void SaveFullSnapshot(char *filePath);

	// from emulator to debugger
	virtual void MarkC64CellRead(uint16 addr);
	virtual void MarkC64CellWrite(uint16 addr, uint8 value);
	virtual void MarkDrive1541CellRead(uint16 addr);
	virtual void MarkDrive1541CellWrite(uint16 addr, uint8 value);
	
	virtual void UiInsertD64(CSlrString *path);
	
	virtual bool IsCpuJam();
	virtual void ForceRunAndUnJamCpu();

	// state rendering
	virtual void RenderStateVIC(vicii_cycle_state_t *viciiState,
								float posX, float posY, float posZ, bool isVertical, bool showSprites, CSlrFont *fontBytes, float fontSize,
								std::vector<CImageData *> *spritesImageData, std::vector<CSlrImage *> *spritesImages, bool renderDataWithColors);
	virtual void RenderStateDrive1541(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize,
									  bool renderVia1, bool renderVia2, bool renderDriveLed, bool isVertical);
	virtual void RenderStateCIA(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId);
	virtual void RenderStateSID(uint16 sidBase, float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize);

	// state recording
	virtual void SetVicRecordStateMode(uint8 recordMode);
	
	// VIC
	virtual void SetVicRegister(uint8 registerNum, uint8 value);
	virtual u8 GetVicRegister(uint8 registerNum);

	// SID
	virtual void SetSIDMuteChannels(bool mute1, bool mute2, bool mute3, bool muteExt);
	virtual void SetSIDReceiveChannelsData(bool isReceiving);
	void AddSIDWaveformData(int v1, int v2, int v3, short mix);
	
	// drive leds
	float ledState[C64_NUM_DRIVES];
	
	virtual void SetPalette(uint8 *palette);
	
	virtual void SetPatchKernalFastBoot(bool isPatchKernal);
	virtual void SetRunSIDWhenInWarp(bool isRunningSIDInWarp);
	
private:
	volatile int debugMode;

};

#endif

