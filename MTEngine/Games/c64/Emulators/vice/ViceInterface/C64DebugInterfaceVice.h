#ifndef _C64DEBUGINTERFACEVICE_H_
#define _C64DEBUGINTERFACEVICE_H_

#include "C64DebugInterface.h"
#include "ViceWrapper.h"

//HAVE_NETWORK  ?

class CViceAudioChannel;

class C64DebugInterfaceVice : public C64DebugInterface
{
public:
	C64DebugInterfaceVice(CViewC64 *viewC64, uint8 *c64memory, bool patchKernalFastBoot);
	~C64DebugInterfaceVice();
	
	virtual void InitKeyMap(C64KeyMap *keyMap);

	CImageData *screen;
	
	CViceAudioChannel *viceAudioChannel;
	
	int screenHeight;
	
	int modelType;
	virtual int GetC64ModelType();

	virtual int GetEmulatorType();
	virtual CSlrString *GetEmulatorVersionString();
	virtual void RunEmulationThread();
	
	virtual uint8 *GetCharRom();

	uint8 machineType;
	virtual uint8 GetC64MachineType();

	virtual int GetC64ScreenSizeX();
	virtual int GetC64ScreenSizeY();
	
	virtual CImageData *GetC64ScreenImageData();

	virtual void Reset();
	virtual void HardReset();

	virtual void KeyboardDown(uint32 mtKeyCode);
	virtual void KeyboardUp(uint32 mtKeyCode);

	virtual int GetC64CpuPC();
	virtual int GetDrive1541PC();
	virtual void GetC64CpuState(C64StateCPU *state);
	virtual void GetDrive1541CpuState(C64StateCPU *state);
	virtual void GetVICState(C64StateVIC *state);

	virtual void GetDrive1541State(C64StateDrive1541 *state);

	virtual void InsertD64(CSlrString *path);
	virtual void DetachDriveDisk();

	virtual bool GetSettingIsWarpSpeed();
	virtual void SetSettingIsWarpSpeed(bool isWarpSpeed);
	virtual bool GetSettingUseKeyboardForJoystick();
	virtual void SetSettingUseKeyboardForJoystick(bool isJoystickOn);
	virtual void SetKeyboardJoystickPort(uint8 joystickPort);

	virtual void GetSidTypes(std::vector<CSlrString *> *sidTypes);
	virtual void SetSidType(int sidType);

	virtual void GetC64ModelTypes(std::vector<CSlrString *> *modelTypes);
	virtual void SetC64ModelType(int modelType);
	virtual void SetEmulationMaximumSpeed(int maximumSpeed);

	bool isJoystickEnabled;
	uint8 joystickPort;

	virtual void SetByteC64(uint16 addr, uint8 val);
	virtual void SetByteToRamC64(uint16 addr, uint8 val);
	virtual uint8 GetByteC64(uint16 addr);
	virtual uint8 GetByteFromRamC64(uint16 addr);
	virtual void MakeJmpC64(uint16 addr);
	virtual void MakeJmpNoResetC64(uint16 addr);
	virtual void MakeJsrC64(uint16 addr);
	
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

	virtual void GetMemoryC64(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRamC64(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryDrive1541(uint8 *buffer, int addrStart, int addrEnd);
	virtual void GetMemoryFromRamDrive1541(uint8 *buffer, int addrStart, int addrEnd);

	virtual void FillC64Ram(uint16 addr, uint16 size, uint8 value);

	virtual void GetVICColors(uint8 *cD021, uint8 *cD022, uint8 *cD023, uint8 *cD025, uint8 *cD026, uint8 *cD027, uint8 *cD800);
	virtual void GetVICSpriteColors(uint8 *cD021, uint8 *cD025, uint8 *cD026, uint8 *spriteColors);
	virtual void GetCBMColor(uint8 colorNum, uint8 *r, uint8 *g, uint8 *b);
	
	virtual bool LoadFullSnapshot(CByteBuffer *snapshotBuffer);
	virtual void SaveFullSnapshot(CByteBuffer *snapshotBuffer);
	
	virtual bool LoadFullSnapshot(char *filePath);
	virtual void SaveFullSnapshot(char *filePath);

	virtual void SetDebugMode(uint8 debugMode);
	virtual uint8 GetDebugMode();
	
	virtual void AttachCartridge(CSlrString *filePath);
	virtual void DetachCartridge();
	virtual void CartridgeFreezeButtonPressed();
	virtual void GetC64CartridgeState(C64StateCartridge *cartridgeState);

	// render states
	virtual void RenderStateVIC(float posX, float posY, float posZ, bool isVertical, CSlrFont *fontBytes, float fontSize, std::vector<CImageData *> *spritesImageData, std::vector<CSlrImage *> *spritesImages, bool renderDataWithColors);
	void PrintVicInterrupts(uint8 flags, char *buf);
	virtual void RenderStateDrive1541(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize,
									  bool renderVia1, bool renderVia2, bool renderDriveLed, bool isVertical);
	virtual void RenderStateCIA(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int ciaId);
	virtual void RenderStateSID(uint16 sidBase, float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize);
	void PrintSidWaveform(uint8 wave, char *buf);
	
	// SID
	virtual void SetSIDMuteChannels(bool mute1, bool mute2, bool mute3, bool muteExt);
	virtual void SetSIDReceiveChannelsData(bool isReceiving);

	// memory
	uint8 *c64memory;
};

extern C64DebugInterfaceVice *debugInterfaceVice;

void ViceKeyMapInitDefault();

#endif

