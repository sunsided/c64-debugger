#ifndef _C64SETTINGS_STORAGE_H_
#define _C64SETTINGS_STORAGE_H_

#include "SYS_Defs.h"
#include "SYS_Types.h"
#include "CSlrString.h"

// settings that need to be initialized pre-launch
#define C64DEBUGGER_BLOCK_PRELAUNCH		1

// settings that need to be set when emulation is initialized
#define C64DEBUGGER_BLOCK_POSTLAUNCH	2

enum resetMode : u8
{
	MACHINE_RESET_NONE = 0,
	MACHINE_RESET_SOFT = 1,
	MACHINE_RESET_HARD = 2
};

enum muteSIDMode : u8
{
	MUTE_SID_MODE_ZERO_VOLUME		= 0,
	MUTE_SID_MODE_SKIP_EMULATION	= 1
};

// settings
extern bool c64SettingsSkipConfig;
extern bool c64SettingsPassConfigToRunningInstance;

extern int c64SettingsDefaultScreenLayoutId;
extern bool c64SettingsIsInVicEditor;

extern uint8 c64SettingsMemoryValuesStyle;
extern uint8 c64SettingsMemoryMarkersStyle;
extern bool c64SettingsUseMultiTouchInMemoryMap;
extern bool c64SettingsMemoryMapInvertControl;
extern uint8 c64SettingsMemoryMapRefreshRate;

extern uint8 c64SettingsC64Model;
extern int c64SettingsEmulationMaximumSpeed;
extern bool c64SettingsFastBootKernalPatch;

extern uint8 c64SettingsSIDEngineModel;
extern uint8 c64SettingsRESIDSamplingMethod;
extern bool c64SettingsRESIDEmulateFilters;
extern uint32 c64SettingsRESIDPassBand;
extern uint32 c64SettingsRESIDFilterBias;

extern bool c64SettingsMuteSIDOnPause;

extern int c64SettingsAudioVolume;
extern bool c64SettingsRunSIDEmulation;
extern uint8 c64SettingsMuteSIDMode;

extern bool c64SettingsEmulateVSPBug;

extern uint8 c64SettingsVicStateRecordingMode;
extern uint16 c64SettingsVicPalette;
extern bool c64SettingsRenderScreenNearest;

extern uint8 c64SettingsJoystickPort;

extern bool c64SettingsRenderDisassembleExecuteAware;

extern bool c64SettingsWindowAlwaysOnTop;

//// NEW
extern float c64SettingsScreenGridLinesAlpha;
extern uint8 c64SettingsScreenGridLinesColorScheme;
extern float c64SettingsScreenRasterViewfinderScale;
extern float c64SettingsScreenRasterCrossLinesAlpha;
extern uint8 c64SettingsScreenRasterCrossLinesColorScheme;
extern float c64SettingsScreenRasterCrossAlpha;
extern uint8 c64SettingsScreenRasterCrossExteriorColorScheme;
extern uint8 c64SettingsScreenRasterCrossInteriorColorScheme;
extern uint8 c64SettingsScreenRasterCrossTipColorScheme;

// startup
extern int c64SettingsWaitOnStartup;
extern CSlrString *c64SettingsPathToD64;
extern CSlrString *c64SettingsDefaultD64Folder;
extern CSlrString *c64SettingsPathToPRG;
extern CSlrString *c64SettingsDefaultPRGFolder;
extern CSlrString *c64SettingsPathToCartridge;
extern CSlrString *c64SettingsDefaultCartridgeFolder;
extern CSlrString *c64SettingsPathToSnapshot;
extern CSlrString *c64SettingsDefaultSnapshotsFolder;
extern CSlrString *c64SettingsDefaultMemoryDumpFolder;
extern CSlrString *c64SettingsPathToC64MemoryMapFile;

extern CSlrString *c64SettingsPathToSymbols;
extern CSlrString *c64SettingsPathToBreakpoints;
extern CSlrString *c64SettingsPathToDebugInfo;

extern CSlrString *c64SettingsPathToJukeboxPlaylist;

extern CSlrString *c64SettingsAudioOutDevice;

extern int c64SettingsJmpOnStartupAddr;

extern bool c64SettingsAutoJmp;
extern bool c64SettingsAutoJmpAlwaysToLoadedPRGAddress;
extern bool c64SettingsAutoJmpFromInsertedDiskFirstPrg;
extern u8 c64SettingsAutoJmpDoReset;
extern int c64SettingsAutoJmpWaitAfterReset;
extern bool c64SettingsForceUnpause;

extern bool c64SettingsRunSIDWhenInWarp;

extern u8 c64SettingsVicDisplayBorderType;

extern float c64SettingsPaintGridCharactersColorR;
extern float c64SettingsPaintGridCharactersColorG;
extern float c64SettingsPaintGridCharactersColorB;
extern float c64SettingsPaintGridCharactersColorA;

extern float c64SettingsPaintGridPixelsColorR;
extern float c64SettingsPaintGridPixelsColorG;
extern float c64SettingsPaintGridPixelsColorB;
extern float c64SettingsPaintGridPixelsColorA;

extern float c64SettingsPaintGridShowZoomLevel;
extern float c64SettingsPaintGridShowValuesZoomLevel;

extern bool c64SettingsVicEditorForceReplaceColor;

extern bool c64SettingsUseSystemFileDialogs;

extern int c64SettingsDoubleClickMS;

void C64DebuggerSetSettingInt(char *settingName, int param);
void C64DebuggerSetSettingString(char *settingName, CSlrString *param);

void C64DebuggerClearSettings();
void C64DebuggerStoreSettings();
void C64DebuggerRestoreSettings(uint8 settingsBlockType);
void C64DebuggerReadSettingsValues(CByteBuffer *byteBuffer, uint8 settingsBlockType);

void C64DebuggerReadSettingCustom(char *name, CByteBuffer *byteBuffer);

// set setting
void C64DebuggerSetSetting(char *name, void *value);


#endif
