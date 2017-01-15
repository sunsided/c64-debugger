#ifndef _C64SETTINGS_STORAGE_H_
#define _C64SETTINGS_STORAGE_H_

#include "SYS_Defs.h"
#include "SYS_Types.h"
#include "CSlrString.h"

// settings that need to be initialized pre-launch
#define C64DEBUGGER_BLOCK_PRELAUNCH		1

// settings that need to be set when emulation is initialized
#define C64DEBUGGER_BLOCK_POSTLAUNCH	2

// settings
extern bool c64SettingsSkipConfig;
extern bool c64SettingsPassConfigToRunningInstance;

extern int c64SettingsDefaultScreenLayoutId;

extern uint8 c64SettingsMemoryValuesStyle;
extern uint8 c64SettingsMemoryMarkersStyle;
extern bool c64SettingsUseMultiTouchInMemoryMap;
extern bool c64SettingsMemoryMapInvertControl;
extern uint8 c64SettingsMemoryMapRefreshRate;

extern uint8 c64SettingsC64Model;
extern int c64SettingsEmulationMaximumSpeed;
extern bool c64SettingsFastBootKernalPatch;

extern uint8 c64SettingsSIDEngineModel;
extern bool c64SettingsMuteSIDOnPause;

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

extern CSlrString *c64SettingsAudioOutDevice;

extern int c64SettingsJmpOnStartupAddr;
extern bool c64SettingsAutoJmp;

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
