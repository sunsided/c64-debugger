#ifndef _C64DEBUGINTERFACE_H_
#define _C64DEBUGINTERFACE_H_

#include "CDebugInterface.h"
#include "CDebuggerBreakpoints.h"
#include "CSlrDataAdapter.h"
#include "CByteBuffer.h"
#include "DebuggerDefs.h"





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
class C64DebugInterface : public CDebugInterface
{
public:
	C64DebugInterface(CViewC64 *viewC64);
	~C64DebugInterface();
	CViewC64 *viewC64;
	
	virtual int GetEmulatorType();
	virtual CSlrString *GetEmulatorVersionString();
	virtual CSlrString *GetPlatformNameString();

	virtual float GetEmulationFPS();

	// this is main emulation cpu cycle counter
	virtual unsigned int GetMainCpuCycleCounter();
	virtual unsigned int GetPreviousCpuInstructionCycleCounter();
	
	// resettable counters for debug purposes
	virtual void ResetMainCpuDebugCycleCounter();
	virtual unsigned int GetMainCpuDebugCycleCounter();
	virtual void ResetEmulationFrameCounter();
	virtual unsigned int GetEmulationFrameNumber();

	virtual void RefreshScreenNoCallback();

	virtual void RunEmulationThread();
	
	virtual void InitKeyMap(C64KeyMap *keyMap);
	
	virtual uint8 *GetCharRom();
	
	float emulationSpeed, emulationFrameRate;
	
	// additional breakpoints, c64
	bool breakOnC64IrqVIC;
	bool breakOnC64IrqCIA;
	bool breakOnC64IrqNMI;
	
	// 1541 disk drive
	bool debugOnDrive1541;
	bool breakOnDrive1541IrqVIA1;
	bool breakOnDrive1541IrqVIA2;
	bool breakOnDrive1541IrqIEC;
	bool breakOnDrive1541PC;
	std::map<uint16, CAddrBreakpoint *> breakpointsDrive1541PC;
	bool breakOnDrive1541Memory;
	std::map<uint16, CMemoryBreakpoint *> breakpointsDrive1541Memory;
	
	// TODO: make new debug interface solely for Drive1541 and do not override this:
	virtual void ClearBreakpoints();
	virtual void AddAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, CAddrBreakpoint *breakpoint);
	virtual void RemoveAddrBreakpoint(std::map<uint16, CAddrBreakpoint *> *breakpointsMap, uint16 addr);

	// data adapters
	CSlrDataAdapter *dataAdapterC64;
	CSlrDataAdapter *dataAdapterC64DirectRam;
	CSlrDataAdapter *dataAdapterDrive1541;
	CSlrDataAdapter *dataAdapterDrive1541DirectRam;
	
	virtual int GetC64ModelType();
	virtual uint8 GetC64MachineType();
	
	virtual int GetScreenSizeX();
	virtual int GetScreenSizeY();
	
	virtual void Reset();
	virtual void HardReset();
	virtual void DiskDriveReset();
	
	// C64 keyboard & joystick mapper
	virtual void KeyboardDown(uint32 mtKeyCode);
	virtual void KeyboardUp(uint32 mtKeyCode);

	virtual void JoystickDown(int port, uint32 axis);
	virtual void JoystickUp(int port, uint32 axis);

	// debugger control
	virtual void SetDebugOnC64(bool debugOnC64);
	virtual void SetDebugOnDrive1541(bool debugOnDrive1541);
	
	int temporaryDrive1541BreakpointPC;
	virtual int GetTemporaryDrive1541BreakpointPC();
	virtual void SetTemporaryDrive1541BreakpointPC(int address);
	
	// circuitry states
	virtual int GetCpuPC();
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
	// 0=none, 1=stereo, 2=triple
	virtual void SetSidStereo(int stereoMode);
	virtual void SetSidStereoAddress(uint16 sidAddress);
	virtual void SetSidTripleAddress(uint16 sidAddress);
	virtual int GetNumSids();

	virtual void UpdateSidDataHistory();

	//
	virtual void GetC64ModelTypes(std::vector<CSlrString *> *modelTypeNames, std::vector<int> *modelTypeIds);
	virtual void SetC64ModelType(int modelType);
	
	virtual void SetEmulationMaximumSpeed(int maximumSpeed);
	
	virtual void SetVSPBugEmulation(bool isVSPBugEmulation);

	virtual void SetSkipDrawingSprites(bool isSkipDrawingSprites);

	// memory access
	virtual void SetByteC64(uint16 addr, uint8 val);
	virtual void SetByteToRamC64(uint16 addr, uint8 val);
	virtual uint8 GetByteC64(uint16 addr);
	virtual uint8 GetByteFromRamC64(uint16 addr);
	
	// make jmp without resetting CPU depending on dataAdapter
	virtual void MakeJmpNoReset(CSlrDataAdapter *dataAdapter, uint16 addr);

	// make jmp and reset CPU
	virtual void MakeJmpAndReset(uint16 addr);
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
	virtual void GetWholeMemoryMap(uint8 *buffer);
	virtual void GetWholeMemoryMapFromRam(uint8 *buffer);
	virtual void GetWholeMemoryMap1541(uint8 *buffer);
	virtual void GetWholeMemoryMapFromRam1541(uint8 *buffer);

	// memory access
	virtual void GetMemory(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRam(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryDrive1541(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRamDrive1541(uint8 *buffer, int addrStart, int addrEnd);
	
	//
	virtual void FillC64Ram(uint16 addr, uint16 size, uint8 value);
	
	//
	virtual void MakeBasicRunC64();

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

	// tape
	virtual void AttachTape(CSlrString *filePath);
	virtual void DetachTape();
	virtual void DatasettePlay();
	virtual void DatasetteStop();
	virtual void DatasetteForward();
	virtual void DatasetteRewind();
	virtual void DatasetteRecord();
	virtual void DatasetteReset();
	virtual void DatasetteSetSpeedTuning(int speedTuning);
	virtual void DatasetteSetZeroGapDelay(int zeroGapDelay);
	virtual void DatasetteSetResetWithCPU(bool resetWithCPU);
	virtual void DatasetteSetTapeWobble(int tapeWobble);

	// reu
	virtual void SetReuEnabled(bool isEnabled);
	virtual void SetReuSize(int reuSize);
	virtual bool LoadReu(char *filePath);
	virtual bool SaveReu(char *filePath);

	//
	virtual void DetachEverything();

	// snapshots
	virtual bool LoadFullSnapshot(CByteBuffer *snapshotBuffer);
	virtual void SaveFullSnapshot(CByteBuffer *snapshotBuffer);
	virtual bool LoadFullSnapshot(char *filePath);
	virtual void SaveFullSnapshot(char *filePath);

	// these calls should be synced with CPU IRQ so snapshot store or restore is allowed
	// store CHIPS only snapshot, not including DISK DATA
	virtual bool LoadChipsSnapshotSynced(CByteBuffer *byteBuffer);
	virtual bool SaveChipsSnapshotSynced(CByteBuffer *byteBuffer);
	// store DISK DATA only snapshot, without CHIPS
	virtual bool LoadDiskDataSnapshotSynced(CByteBuffer *byteBuffer);
	virtual bool SaveDiskDataSnapshotSynced(CByteBuffer *byteBuffer);

	virtual bool IsDriveDirtyForSnapshot();
	virtual void ClearDriveDirtyForSnapshotFlag();

//	virtual void UiInsertD64(CSlrString *path);
	
	virtual bool IsCpuJam();
	virtual void ForceRunAndUnJamCpu();

	// state recording
	virtual void SetVicRecordStateMode(uint8 recordMode);
	
	// VIC
	virtual void SetVicRegister(uint8 registerNum, uint8 value);
	virtual u8 GetVicRegister(uint8 registerNum);
	virtual u8 GetVicRegister(vicii_cycle_state_t *viciiState, uint8 registerNum);

	// CIA
	virtual void SetCiaRegister(uint8 ciaId, uint8 registerNum, uint8 value);
	virtual u8 GetCiaRegister(uint8 ciaId, uint8 registerNum);
	
	// SID
	virtual void SetSidRegister(uint8 sidId, uint8 registerNum, uint8 value);
	virtual u8 GetSidRegister(uint8 sidId, uint8 registerNum);
	virtual void SetSIDMuteChannels(int sidNumber, bool mute1, bool mute2, bool mute3, bool muteExt);
	virtual void SetSIDReceiveChannelsData(int sidNumber, bool isReceiving);

	// VIA
	virtual void SetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum, uint8 value);
	virtual u8 GetViaRegister(uint8 driveId, uint8 viaId, uint8 registerNum);

	// drive leds
	float ledState[C64_NUM_DRIVES];
	
	virtual void SetPalette(uint8 *palette);
	
	virtual void SetPatchKernalFastBoot(bool isPatchKernal);
	virtual void SetRunSIDWhenInWarp(bool isRunningSIDInWarp);
	
	//
	virtual void SetRunSIDEmulation(bool isSIDEmulationOn);
	virtual void SetAudioVolume(float volume);
	
	//
	virtual CSlrDataAdapter *GetDataAdapter();

	virtual CViewDisassemble *GetViewMainCpuDisassemble();
	virtual CViewDisassemble *GetViewDriveDisassemble(int driveNo);	// TODO: make drive cpu generic (create specific debug interface for drive?)
	virtual CViewBreakpoints *GetViewBreakpoints();
	virtual CViewDataWatch *GetViewMemoryDataWatch();

	//
	// @returns NULL when monitor is not supported
	virtual bool IsCodeMonitorSupported();
	virtual CSlrString *GetCodeMonitorPrompt();
	virtual bool ExecuteCodeMonitorCommand(CSlrString *commandStr);

	//
	virtual void Shutdown();
	
	// profiler
	// if fileName is NULL no file will be created, if runForNumCycles is -1 it will run till ProfilerDeactivate
	virtual void ProfilerActivate(char *fileName, int runForNumCycles, bool pauseCpuWhenFinished);
	virtual void ProfilerDeactivate();

};

#endif

