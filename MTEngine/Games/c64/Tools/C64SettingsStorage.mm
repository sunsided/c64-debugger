#include "C64SettingsStorage.h"
#include "CViewMemoryMap.h"
#include "CSlrFileFromOS.h"
#include "CByteBuffer.h"
#include "CViewC64.h"
#include "C64DebugInterface.h"
#include "CViewMonitorConsole.h"
#include "SND_SoundEngine.h"
#include "CViewC64Screen.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64VicControl.h"
#include "CViewVicEditor.h"
#include "C64Palette.h"
#include "C64DebugTypes.h"

extern "C" {
#include "sid-resources.h"
}

#define C64DEBUGGER_SETTINGS_FILE_VERSION 0x0002

///
#define C64DEBUGGER_SETTING_BLOCK	0
#define C64DEBUGGER_SETTING_STRING	1
#define C64DEBUGGER_SETTING_U8		2
#define C64DEBUGGER_SETTING_BOOL	3
#define C64DEBUGGER_SETTING_CUSTOM	4
#define C64DEBUGGER_SETTING_U16		5
#define C64DEBUGGER_SETTING_FLOAT	6
#define C64DEBUGGER_SETTING_I32		7

/// blocks
#define C64DEBUGGER_BLOCK_EOF			0

/// settings
int c64SettingsDefaultScreenLayoutId = -1; //C64_SCREEN_LAYOUT_MONITOR_CONSOLE; //C64_SCREEN_LAYOUT_C64_DEBUGGER;
//C64_SCREEN_LAYOUT_C64_DEBUGGER);
//C64_SCREEN_LAYOUT_C64_1541_MEMORY_MAP; //C64_SCREEN_LAYOUT_C64_ONLY //
//C64_SCREEN_LAYOUT_SHOW_STATES; //C64_SCREEN_LAYOUT_C64_DATA_DUMP
//C64_SCREEN_LAYOUT_C64_1541_DEBUGGER

bool c64SettingsIsInVicEditor = false;

bool c64SettingsSkipConfig = false;
bool c64SettingsPassConfigToRunningInstance = false;

uint8 c64SettingsJoystickPort = 0;

bool c64SettingsWindowAlwaysOnTop = false;

bool c64SettingsRenderDisassembleExecuteAware = true;

uint8 c64SettingsMemoryValuesStyle = MEMORY_MAP_VALUES_STYLE_RGB;
uint8 c64SettingsMemoryMarkersStyle = MEMORY_MAP_MARKER_STYLE_DEFAULT;
bool c64SettingsUseMultiTouchInMemoryMap = false;
bool c64SettingsMemoryMapInvertControl = false;
uint8 c64SettingsMemoryMapRefreshRate = 2;
int c64SettingsMemoryMapFadeSpeed = 100;		// percentage

uint8 c64SettingsC64Model = 0;
int c64SettingsEmulationMaximumSpeed = 100;		// percentage
bool c64SettingsFastBootKernalPatch = false;
bool c64SettingsEmulateVSPBug = false;

uint8 c64SettingsSIDEngineModel = 0;	// 4=8580 FastSID
uint8 c64SettingsRESIDSamplingMethod = SID_RESID_SAMPLING_RESAMPLING;
bool c64SettingsRESIDEmulateFilters = true;
uint32 c64SettingsRESIDPassBand = 90;
uint32 c64SettingsRESIDFilterBias = 500;


bool c64SettingsMuteSIDOnPause = false;

uint16 c64SettingsVicPalette = 0;

int c64SettingsWaitOnStartup = 0; //500;

CSlrString *c64SettingsPathToD64 = NULL;
CSlrString *c64SettingsDefaultD64Folder = NULL;

CSlrString *c64SettingsPathToPRG = NULL;
CSlrString *c64SettingsDefaultPRGFolder = NULL;

CSlrString *c64SettingsPathToCartridge = NULL;
CSlrString *c64SettingsDefaultCartridgeFolder = NULL;

CSlrString *c64SettingsPathToSnapshot = NULL;
CSlrString *c64SettingsDefaultSnapshotsFolder = NULL;

CSlrString *c64SettingsDefaultMemoryDumpFolder = NULL;

CSlrString *c64SettingsPathToC64MemoryMapFile = NULL;

CSlrString *c64SettingsPathToSymbols = NULL;
CSlrString *c64SettingsPathToBreakpoints = NULL;
CSlrString *c64SettingsPathToDebugInfo = NULL;

CSlrString *c64SettingsAudioOutDevice = NULL;

float c64SettingsScreenGridLinesAlpha = 0.3f;
uint8 c64SettingsScreenGridLinesColorScheme = 0;	// 0=red, 1=green, 2=blue, 3=black, 4=dark gray 5=light gray 6=white
float c64SettingsScreenRasterViewfinderScale = 1.5f; //5.0f; //1.5f;

float c64SettingsScreenRasterCrossLinesAlpha = 0.5f;
uint8 c64SettingsScreenRasterCrossLinesColorScheme = 5;	// 0=red, 1=green, 2=blue, 3=black, 4=dark gray 5=light gray 6=white
float c64SettingsScreenRasterCrossAlpha = 0.85f;
uint8 c64SettingsScreenRasterCrossInteriorColorScheme = 6;	// 0=red, 1=green, 2=blue, 3=black, 4=dark gray 5=light gray 6=white
uint8 c64SettingsScreenRasterCrossExteriorColorScheme = 0;	// 0=red, 1=green, 2=blue, 3=black, 4=dark gray 5=light gray 6=white
uint8 c64SettingsScreenRasterCrossTipColorScheme = 3;	// 0=red, 1=green, 2=blue, 3=black, 4=dark gray 5=light gray 6=white

uint8 c64SettingsVicStateRecordingMode = C64D_VICII_RECORD_MODE_EVERY_CYCLE;
bool c64SettingsRenderScreenNearest = true;

int c64SettingsJmpOnStartupAddr = -1;

u8 c64SettingsVicDisplayBorderType = VIC_DISPLAY_SHOW_BORDER_FULL;

bool c64SettingsAutoJmp = false;
bool c64SettingsAutoJmpAlwaysToLoadedPRGAddress = false;	// will jump to loaded address when PRG is loaded from menu
bool c64SettingsAutoJmpFromInsertedDiskFirstPrg = false;	// will load first PRG from attached disk
u8 c64SettingsAutoJmpDoReset = AUTOJMP_RESET_NONE;
int c64SettingsAutoJmpWaitAfterReset = 1300;				// this is to let c64 drive finish reset

bool c64SettingsForceUnpause = false;						// unpause debugger on jmp if code is stopped

bool c64SettingsRunSIDWhenInWarp = true;

float c64SettingsPaintGridCharactersColorR = 0.7f;
float c64SettingsPaintGridCharactersColorG = 0.7f;
float c64SettingsPaintGridCharactersColorB = 0.7f;
float c64SettingsPaintGridCharactersColorA = 1.0f;

float c64SettingsPaintGridPixelsColorR = 0.5f;
float c64SettingsPaintGridPixelsColorG = 0.5f;
float c64SettingsPaintGridPixelsColorB = 0.5f;
float c64SettingsPaintGridPixelsColorA = 0.3f;

float c64SettingsPaintGridShowZoomLevel = 5.0;
float c64SettingsPaintGridShowValuesZoomLevel = 26.0;

bool c64SettingsVicEditorForceReplaceColor = false;

int c64SettingsDoubleClickMS = 600;



void storeSettingBlock(CByteBuffer *byteBuffer, u8 value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_BLOCK);
	byteBuffer->PutU8(value);
}

void storeSettingU8(CByteBuffer *byteBuffer, char *name, u8 value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_U8);
	byteBuffer->PutString(name);
	byteBuffer->PutU8(value);
}

void storeSettingU16(CByteBuffer *byteBuffer, char *name, u16 value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_U16);
	byteBuffer->PutString(name);
	byteBuffer->PutU16(value);
}

void storeSettingI32(CByteBuffer *byteBuffer, char *name, i32 value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_I32);
	byteBuffer->PutString(name);
	byteBuffer->PutI32(value);
}

void storeSettingFloat(CByteBuffer *byteBuffer, char *name, float value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_FLOAT);
	byteBuffer->PutString(name);
	byteBuffer->PutFloat(value);
}

void storeSettingBool(CByteBuffer *byteBuffer, char *name, bool value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_BOOL);
	byteBuffer->PutString(name);
	byteBuffer->PutBool(value);
}

void storeSettingString(CByteBuffer *byteBuffer, char *name, CSlrString *value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_STRING);
	byteBuffer->PutString(name);
	byteBuffer->PutSlrString(value);
}

void storeSettingCustom(CByteBuffer *byteBuffer, char *name)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_CUSTOM);
	byteBuffer->PutString(name);
}

void C64DebuggerClearSettings()
{
	CByteBuffer *byteBuffer = new CByteBuffer();
	byteBuffer->PutU16(C64DEBUGGER_SETTINGS_FILE_VERSION);

	storeSettingBlock(byteBuffer, C64DEBUGGER_BLOCK_EOF);
	
	CSlrString *fileName = new CSlrString("/settings.dat");
	byteBuffer->storeToSettings(fileName);
	delete fileName;
	
	delete byteBuffer;
}

void C64DebuggerStoreSettings()
{
	CByteBuffer *byteBuffer = new CByteBuffer();
	byteBuffer->PutU16(C64DEBUGGER_SETTINGS_FILE_VERSION);
	
	storeSettingBlock(byteBuffer, C64DEBUGGER_BLOCK_PRELAUNCH);
	storeSettingString(byteBuffer, "FolderD64", c64SettingsDefaultD64Folder);
	storeSettingString(byteBuffer, "FolderPRG", c64SettingsDefaultPRGFolder);
	storeSettingString(byteBuffer, "FolderCRT", c64SettingsDefaultCartridgeFolder);
	storeSettingString(byteBuffer, "FolderSnaps", c64SettingsDefaultSnapshotsFolder);
	storeSettingString(byteBuffer, "FolderMemDumps", c64SettingsDefaultMemoryDumpFolder);
	
	storeSettingString(byteBuffer, "PathD64", c64SettingsPathToD64);
	storeSettingString(byteBuffer, "PathPRG", c64SettingsPathToPRG);
	storeSettingString(byteBuffer, "PathCRT", c64SettingsPathToCartridge);
	
	storeSettingBool(byteBuffer, "AutoJmp", c64SettingsAutoJmp);
	storeSettingBool(byteBuffer, "AutoJmpAlwaysToLoadedPRGAddress", c64SettingsAutoJmpAlwaysToLoadedPRGAddress);
	storeSettingBool(byteBuffer, "AutoJmpFromInsertedDiskFirstPrg", c64SettingsAutoJmpFromInsertedDiskFirstPrg);
	
	storeSettingString(byteBuffer, "PathMemMapFile", c64SettingsPathToC64MemoryMapFile);

	storeSettingString(byteBuffer, "AudioOutDevice", c64SettingsAudioOutDevice);
	
	storeSettingBool(byteBuffer, "FastBootPatch", c64SettingsFastBootKernalPatch);
	
	storeSettingU8(byteBuffer, "ScreenLayoutId", c64SettingsDefaultScreenLayoutId);
	storeSettingBool(byteBuffer, "IsInVicEditor", c64SettingsIsInVicEditor);
	
	storeSettingBool(byteBuffer, "DisassembleExecuteAware", c64SettingsRenderDisassembleExecuteAware);

	storeSettingBool(byteBuffer, "WindowAlwaysOnTop", c64SettingsWindowAlwaysOnTop);

	storeSettingU8(byteBuffer, "C64Model", c64SettingsC64Model);

	storeSettingBlock(byteBuffer, C64DEBUGGER_BLOCK_POSTLAUNCH);
	storeSettingU8(byteBuffer, "JoystickPort", c64SettingsJoystickPort);
	storeSettingU8(byteBuffer, "MemoryValuesStyle", c64SettingsMemoryValuesStyle);
	storeSettingU8(byteBuffer, "MemoryMarkersStyle", c64SettingsMemoryMarkersStyle);

	storeSettingU8(byteBuffer, "SIDEngineModel", c64SettingsSIDEngineModel);
	storeSettingU8(byteBuffer, "RESIDSamplingMethod", c64SettingsRESIDSamplingMethod);
	storeSettingBool(byteBuffer, "RESIDEmulateFilters", c64SettingsRESIDEmulateFilters);
	storeSettingI32(byteBuffer, "RESIDPassBand", c64SettingsRESIDPassBand);
	storeSettingI32(byteBuffer, "RESIDFilterBias", c64SettingsRESIDFilterBias);

	storeSettingBool(byteBuffer, "MuteSIDOnPause", c64SettingsMuteSIDOnPause);
	storeSettingBool(byteBuffer, "RunSIDWhenWarp", c64SettingsRunSIDWhenInWarp);

	storeSettingU8(byteBuffer, "VicStateRecording", c64SettingsVicStateRecordingMode);
	storeSettingU16(byteBuffer, "VicPalette", c64SettingsVicPalette);
	storeSettingBool(byteBuffer, "RenderScreenNearest", c64SettingsRenderScreenNearest);
	
	storeSettingBool(byteBuffer, "MemMapMultiTouch", c64SettingsUseMultiTouchInMemoryMap);
	storeSettingBool(byteBuffer, "MemMapInvert", c64SettingsMemoryMapInvertControl);
	storeSettingU8(byteBuffer, "MemMapRefresh", c64SettingsMemoryMapRefreshRate);
	storeSettingU16(byteBuffer, "MemMapFadeSpeed", c64SettingsMemoryMapFadeSpeed);

	storeSettingU16(byteBuffer, "EmulationMaximumSpeed", c64SettingsEmulationMaximumSpeed);

	storeSettingBool(byteBuffer, "EmulateVSPBug", c64SettingsEmulateVSPBug);
	
	storeSettingFloat(byteBuffer, "GridLinesAlpha", c64SettingsScreenGridLinesAlpha);
	storeSettingU8(byteBuffer, "GridLinesColor", c64SettingsScreenGridLinesColorScheme);
	storeSettingFloat(byteBuffer, "ViewfinderScale", c64SettingsScreenRasterViewfinderScale);
	storeSettingFloat(byteBuffer, "CrossLinesAlpha", c64SettingsScreenRasterCrossLinesAlpha);
	storeSettingU8(byteBuffer, "CrossLinesColor", c64SettingsScreenRasterCrossLinesColorScheme);
	storeSettingFloat(byteBuffer, "CrossAlpha", c64SettingsScreenRasterCrossAlpha);
	storeSettingU8(byteBuffer, "CrossInteriorColor", c64SettingsScreenRasterCrossInteriorColorScheme);
	storeSettingU8(byteBuffer, "CrossExteriorColor", c64SettingsScreenRasterCrossExteriorColorScheme);
	storeSettingU8(byteBuffer, "CrossTipColor", c64SettingsScreenRasterCrossTipColorScheme);
	
	//
	storeSettingU8(byteBuffer, "AutoJmpDoReset", c64SettingsAutoJmpDoReset);
	storeSettingI32(byteBuffer, "AutoJmpWaitAfterReset", c64SettingsAutoJmpWaitAfterReset);

	storeSettingU8(byteBuffer, "VicDisplayBorder", c64SettingsVicDisplayBorderType);
	
	storeSettingFloat (byteBuffer, "PaintGridCharactersColorR", c64SettingsPaintGridCharactersColorR);
	storeSettingFloat (byteBuffer, "PaintGridCharactersColorG", c64SettingsPaintGridCharactersColorG);
	storeSettingFloat (byteBuffer, "PaintGridCharactersColorB", c64SettingsPaintGridCharactersColorB);
	storeSettingFloat (byteBuffer, "PaintGridCharactersColorA", c64SettingsPaintGridCharactersColorA);
	
	storeSettingFloat (byteBuffer, "PaintGridPixelsColorR", c64SettingsPaintGridPixelsColorR);
	storeSettingFloat (byteBuffer, "PaintGridPixelsColorG", c64SettingsPaintGridPixelsColorG);
	storeSettingFloat (byteBuffer, "PaintGridPixelsColorB", c64SettingsPaintGridPixelsColorB);
	storeSettingFloat (byteBuffer, "PaintGridPixelsColorA", c64SettingsPaintGridPixelsColorA);
	
	storeSettingFloat (byteBuffer, "PaintGridShowZoomLevel", c64SettingsPaintGridShowZoomLevel);
	
	storeSettingBool (byteBuffer, "VicEditorForceReplaceColor", c64SettingsVicEditorForceReplaceColor);
	
	storeSettingBlock(byteBuffer, C64DEBUGGER_BLOCK_EOF);

	CSlrString *fileName = new CSlrString("/settings.dat");
	byteBuffer->storeToSettings(fileName);
	delete fileName;
	
	delete byteBuffer;
}

void C64DebuggerRestoreSettings(uint8 settingsBlockType)
{
	LOGD("C64DebuggerRestoreSettings: settingsBlockType=%d", settingsBlockType);
	
	if (c64SettingsSkipConfig)
	{
		LOGD("... skipping loading config and clearing settings");
		C64DebuggerClearSettings();
		return;
	}
	
	CByteBuffer *byteBuffer = new CByteBuffer();

	CSlrString *fileName = new CSlrString("/settings.dat");
	byteBuffer->loadFromSettings(fileName);
	delete fileName;
	
	if (byteBuffer->length == 0)
	{
		LOGD("... no stored settings found");
		delete byteBuffer;
		return;
	}
	
	u16 version = byteBuffer->GetU16();
	if (version > C64DEBUGGER_SETTINGS_FILE_VERSION)
	{
		LOGError("C64DebuggerReadSettings: incompatible version %04x", version);
		delete byteBuffer;
		return;
	}

	C64DebuggerReadSettingsValues(byteBuffer, settingsBlockType);
	
	delete byteBuffer;
}

void C64DebuggerReadSettingsValues(CByteBuffer *byteBuffer, uint8 settingsBlockType)
{
	u8 blockType = 0xFF;
	
	int valueInt;
	bool valueBool;
	float valueFloat;
	
	// read block
	while (blockType != C64DEBUGGER_BLOCK_EOF)
	{
		u8 dataType = byteBuffer->GetU8();
		
		if (dataType == C64DEBUGGER_SETTING_BLOCK)
		{
			blockType = byteBuffer->GetU8();
			continue;
		}
		
		char *name = byteBuffer->GetString();
		
		LOGD("readed setting '%s'", name);
		
		void *value = NULL;
		
		if (dataType == C64DEBUGGER_SETTING_U8)
		{
			valueInt = byteBuffer->GetU8();
			value = &valueInt;
		}
		else if (dataType == C64DEBUGGER_SETTING_U16)
		{
			valueInt = byteBuffer->GetU16();
			value = &valueInt;
		}
		else if (dataType == C64DEBUGGER_SETTING_I32)
		{
			valueInt = byteBuffer->GetI32();
			value = &valueInt;
		}
		else if (dataType == C64DEBUGGER_SETTING_FLOAT)
		{
			valueFloat = byteBuffer->GetFloat();
			value = &valueFloat;
		}
		else if (dataType == C64DEBUGGER_SETTING_BOOL)
		{
			valueBool = byteBuffer->GetBool();
			value = &valueBool;
		}
		else if (dataType == C64DEBUGGER_SETTING_STRING)
		{
			value = byteBuffer->GetSlrString();
		}
		else
		{
			LOGError("C64DebuggerReadSettingsValues: unknown dataType=%d", dataType);
		}
		
		if (blockType == settingsBlockType)
		{
			if (dataType == C64DEBUGGER_SETTING_CUSTOM)
			{
				CByteBuffer *byteBufferCustom = byteBuffer->getByteBuffer();
				C64DebuggerReadSettingCustom(name, byteBufferCustom);
				delete byteBufferCustom;
			}
			else
			{
				if (value != NULL)
					C64DebuggerSetSetting(name, value);
			}
		}
		
		free(name);
		
		if (dataType == C64DEBUGGER_SETTING_STRING)
		{
			delete (CSlrString*)value;
		}
	}
}

void C64DebuggerReadSettingCustom(char *name, CByteBuffer *byteBuffer)
{
//	if (!strcmp(name, "MonitorHistory"))
//	{
//		int historySize = byteBuffer->GetByte();
//		for (int i = 0; i < historySize; i++)
//		{
//			char *cmd = byteBuffer->GetString();
//			viewC64->viewMonitorConsole->viewConsole->commandLineHistory.push_back(cmd);
//		}
//		viewC64->viewMonitorConsole->viewConsole->commandLineHistoryIt = viewC64->viewMonitorConsole->viewConsole->commandLineHistory.end();
//	}
}


void C64DebuggerSetSetting(char *name, void *value)
{
	LOGD("C64DebuggerSetStartupSetting: name='%s'", name);
		
	if (!strcmp(name, "FolderD64"))
	{
		if (c64SettingsDefaultD64Folder != NULL)
			delete c64SettingsDefaultD64Folder;
		
		c64SettingsDefaultD64Folder = new CSlrString((CSlrString*)value);
	}
	else if (!strcmp(name, "FolderPRG"))
	{
		if (c64SettingsDefaultPRGFolder != NULL)
			delete c64SettingsDefaultPRGFolder;
		
		c64SettingsDefaultPRGFolder = new CSlrString((CSlrString*)value);
	}
	else if (!strcmp(name, "FolderCRT"))
	{
		if (c64SettingsDefaultCartridgeFolder != NULL)
			delete c64SettingsDefaultCartridgeFolder;
		
		c64SettingsDefaultCartridgeFolder = new CSlrString((CSlrString*)value);
	}
	else if (!strcmp(name, "FolderSnaps"))
	{
		if (c64SettingsDefaultSnapshotsFolder != NULL)
			delete c64SettingsDefaultSnapshotsFolder;
		
		c64SettingsDefaultSnapshotsFolder = new CSlrString((CSlrString*)value);
	}
	else if (!strcmp(name, "FolderMemDumps"))
	{
		if (c64SettingsDefaultMemoryDumpFolder != NULL)
			delete c64SettingsDefaultMemoryDumpFolder;
		
		c64SettingsDefaultMemoryDumpFolder = new CSlrString((CSlrString*)value);
	}

	else if (!strcmp(name, "PathD64"))
	{
		if (c64SettingsPathToD64 != NULL)
			delete c64SettingsPathToD64;
		
		c64SettingsPathToD64 = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->InsertD64(c64SettingsPathToD64, false);
		}
	}
	else if (!strcmp(name, "PathPRG"))
	{
		if (c64SettingsPathToPRG != NULL)
			delete c64SettingsPathToPRG;
		
		c64SettingsPathToPRG = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->LoadPRG(c64SettingsPathToPRG, false, false);
		}
	}
	else if (!strcmp(name, "PathCRT"))
	{
		if (c64SettingsPathToCartridge != NULL)
			delete c64SettingsPathToCartridge;
		
		c64SettingsPathToCartridge = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->InsertCartridge(c64SettingsPathToCartridge, false);
		}
	}
	else if (!strcmp(name, "PathMemMapFile"))
	{
		if (c64SettingsPathToC64MemoryMapFile != NULL)
			delete c64SettingsPathToC64MemoryMapFile;
		
		c64SettingsPathToC64MemoryMapFile = new CSlrString((CSlrString*)value);
	}
	else if (!strcmp(name, "FastBootPatch"))
	{
		bool v = *((bool*)value);
		c64SettingsFastBootKernalPatch = v;
	}
	else if (!strcmp(name, "DisassembleExecuteAware"))
	{
		bool v = *((bool*)value);
		c64SettingsRenderDisassembleExecuteAware = v;
	}
	else if (!strcmp(name, "WindowAlwaysOnTop"))
	{
		bool v = *((bool*)value);
		c64SettingsWindowAlwaysOnTop = v;
		
		VID_SetWindowAlwaysOnTop(c64SettingsWindowAlwaysOnTop);
	}
	else if (!strcmp(name, "VicStateRecording"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemVicStateRecordingMode->SetSelectedOption(v, false);
		
		c64SettingsVicStateRecordingMode = v;
		viewC64->debugInterface->SetVicRecordStateMode(v);
	}
	else if (!strcmp(name, "VicPalette"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemVicPalette->SetSelectedOption(v, false);
		
		c64SettingsVicPalette = v;
		C64SetPaletteNum(v);
	}
	else if (!strcmp(name, "ScreenLayoutId"))
	{
		int v = *((int*)value);
		c64SettingsDefaultScreenLayoutId = v;
	}
	else if (!strcmp(name, "IsInVicEditor"))
	{
		bool v = *((bool*)value);
		c64SettingsIsInVicEditor = v;
	}
	else if (!strcmp(name, "JoystickPort"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemJoystickPort->SetSelectedOption(v, false);
		c64SettingsJoystickPort = v;
		viewC64->debugInterface->SetKeyboardJoystickPort(v);		
	}
	else if (!strcmp(name, "MemoryValuesStyle"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemMemoryCellsColorStyle->SetSelectedOption(v, false);
		c64SettingsMemoryValuesStyle = v;
		C64DebuggerComputeMemoryMapColorTables(v);
	}
	else if (!strcmp(name, "MemoryMarkersStyle"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemMemoryMarkersColorStyle->SetSelectedOption(v, false);
		
		c64SettingsMemoryMarkersStyle = v;
		C64DebuggerSetMemoryMapMarkersStyle(v);
	}
	else if (!strcmp(name, "SIDEngineModel"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemSIDModel->SetSelectedOption(v, false);
		c64SettingsSIDEngineModel = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetSidType(c64SettingsSIDEngineModel);
		}
	}
	else if (!strcmp(name, "RESIDSamplingMethod"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemRESIDSamplingMethod->SetSelectedOption(v, false);
		c64SettingsRESIDSamplingMethod = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetSidSamplingMethod(c64SettingsRESIDSamplingMethod);
		}
	}
	else if (!strcmp(name, "RESIDEmulateFilters"))
	{
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemRESIDEmulateFilters->SetSelectedOption(1, false);
			c64SettingsRESIDEmulateFilters = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemRESIDEmulateFilters->SetSelectedOption(0, false);
			c64SettingsRESIDEmulateFilters = false;
		}

		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetSidEmulateFilters(c64SettingsRESIDEmulateFilters);
		}
	}
	else if (!strcmp(name, "RESIDPassBand"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemRESIDPassBand->SetValue(v, false);
		c64SettingsRESIDPassBand = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetSidPassBand(c64SettingsRESIDPassBand);
		}
	}
	else if (!strcmp(name, "RESIDFilterBias"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemRESIDFilterBias->SetValue(v, false);
		c64SettingsRESIDFilterBias = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetSidFilterBias(c64SettingsRESIDFilterBias);
		}
	}
	else if (!strcmp(name, "MuteSIDOnPause"))
	{
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemMuteSIDOnPause->SetSelectedOption(1, false);
			c64SettingsMuteSIDOnPause = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemMuteSIDOnPause->SetSelectedOption(0, false);
			c64SettingsMuteSIDOnPause = false;
		}
	}
	else if (!strcmp(name, "RunSIDWhenWarp"))
	{
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemRunSIDWhenInWarp->SetSelectedOption(1, false);
			c64SettingsRunSIDWhenInWarp = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemRunSIDWhenInWarp->SetSelectedOption(0, false);
			c64SettingsRunSIDWhenInWarp = false;
		}
		viewC64->debugInterface->SetRunSIDWhenInWarp(c64SettingsRunSIDWhenInWarp);

	}

	else if (!strcmp(name, "AudioOutDevice"))
	{
		if (c64SettingsAudioOutDevice != NULL)
			delete c64SettingsAudioOutDevice;
		
		c64SettingsAudioOutDevice = new CSlrString((CSlrString*)value);
		
		gSoundEngine->SetOutputAudioDevice(c64SettingsAudioOutDevice);
	}
	else if (!strcmp(name, "C64Model"))
	{
		int v = *((int*)value);
		//viewC64->viewC64SettingsMenu->SetOptionC64ModelType(v);
		c64SettingsC64Model = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetC64ModelType(c64SettingsC64Model);
		}
	}
	else if (!strcmp(name, "RenderScreenNearest"))
	{
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemRenderScreenNearest->SetSelectedOption(1, false);
			c64SettingsRenderScreenNearest = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemRenderScreenNearest->SetSelectedOption(0, false);
			c64SettingsRenderScreenNearest = false;
		}
	}
	
	else if (!strcmp(name, "MemMapMultiTouch"))
	{
#if defined(MACOS)
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemMultiTouchMemoryMap->SetSelectedOption(1, false);
			c64SettingsUseMultiTouchInMemoryMap = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemMultiTouchMemoryMap->SetSelectedOption(0, false);
			c64SettingsUseMultiTouchInMemoryMap = false;
		}
#endif
	}
	else if (!strcmp(name, "MemMapInvert"))
	{
		bool v = *((bool*)value);
		
		if (v)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapInvert->SetSelectedOption(1, false);
			c64SettingsMemoryMapInvertControl = true;
		}
		else
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapInvert->SetSelectedOption(0, false);
			c64SettingsMemoryMapInvertControl = false;
		}
	}
	else if (!strcmp(name, "MemMapRefresh"))
	{
		int v = *((int*)value);
		if (v == 1)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapRefreshRate->SetSelectedOption(0, false);
		}
		else if (v == 2)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapRefreshRate->SetSelectedOption(1, false);
		}
		else if (v == 4)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapRefreshRate->SetSelectedOption(2, false);
		}
		else if (v == 10)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapRefreshRate->SetSelectedOption(3, false);
		}
		else if (v == 20)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapRefreshRate->SetSelectedOption(4, false);
		}

		c64SettingsMemoryMapRefreshRate = v;
	}
	else if (!strcmp(name, "MemMapFadeSpeed"))
	{
		int v = *((int*)value);
		if (v == 1)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(0, false);
		}
		else if (v == 10)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(1, false);
		}
		else if (v == 20)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(2, false);
		}
		else if (v == 50)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(3, false);
		}
		else if (v == 100)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(4, false);
		}
		else if (v == 200)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(5, false);
		}
		else if (v == 300)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(6, false);
		}
		else if (v == 400)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(7, false);
		}
		else if (v == 500)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(8, false);
		}
		else if (v == 1000)
		{
			viewC64->viewC64SettingsMenu->menuItemMemoryMapFadeSpeed->SetSelectedOption(9, false);
		}
		
		c64SettingsMemoryMapFadeSpeed = v;
		
		float fadeSpeed = v / 100.0f;
		C64DebuggerSetMemoryMapCellsFadeSpeed(fadeSpeed);
	}
	else if (!strcmp(name, "EmulationMaximumSpeed"))
	{
		int v = *((int*)value);
		if (v == 10)
		{
			viewC64->viewC64SettingsMenu->menuItemMaximumSpeed->SetSelectedOption(0, false);
		}
		else if (v == 20)
		{
			viewC64->viewC64SettingsMenu->menuItemMaximumSpeed->SetSelectedOption(1, false);
		}
		else if (v == 50)
		{
			viewC64->viewC64SettingsMenu->menuItemMaximumSpeed->SetSelectedOption(2, false);
		}
		else if (v == 100)
		{
			viewC64->viewC64SettingsMenu->menuItemMaximumSpeed->SetSelectedOption(3, false);
		}
		else if (v == 200)
		{
			viewC64->viewC64SettingsMenu->menuItemMaximumSpeed->SetSelectedOption(4, false);
		}
		
		c64SettingsEmulationMaximumSpeed = v;
		
		viewC64->debugInterface->SetEmulationMaximumSpeed(v);
	}
	else if (!strcmp(name, "GridLinesAlpha"))
	{
		float v = *((float*)value);
		c64SettingsScreenGridLinesAlpha = v;
		viewC64->viewC64SettingsMenu->menuItemScreenGridLinesAlpha->SetValue(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "GridLinesColor"))
	{
		u8 v = *((u8*)value);
		c64SettingsScreenGridLinesColorScheme = v;
		viewC64->viewC64SettingsMenu->menuItemScreenGridLinesColorScheme->SetSelectedOption(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
		viewC64->viewC64VicDisplay->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "ViewfinderScale"))
	{
		float v = *((float*)value);
		c64SettingsScreenRasterViewfinderScale = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterViewfinderScale->SetValue(v, false);
		viewC64->viewC64Screen->SetZoomedScreenLevel(v);
	}
	else if (!strcmp(name, "CrossLinesAlpha"))
	{
		float v = *((float*)value);
		c64SettingsScreenRasterCrossLinesAlpha = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossLinesAlpha->SetValue(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "CrossLinesColor"))
	{
		u8 v = *((u8*)value);
		c64SettingsScreenRasterCrossLinesColorScheme = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossLinesColorScheme->SetSelectedOption(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "CrossAlpha"))
	{
		float v = *((float*)value);
		c64SettingsScreenRasterCrossAlpha = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossAlpha->SetValue(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "CrossInteriorColor"))
	{
		u8 v = *((u8*)value);
		c64SettingsScreenRasterCrossInteriorColorScheme = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossInteriorColorScheme->SetSelectedOption(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "CrossExteriorColor"))
	{
		u8 v = *((u8*)value);
		c64SettingsScreenRasterCrossExteriorColorScheme = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossExteriorColorScheme->SetSelectedOption(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}
	else if (!strcmp(name, "CrossTipColor"))
	{
		u8 v = *((u8*)value);
		c64SettingsScreenRasterCrossTipColorScheme = v;
		viewC64->viewC64SettingsMenu->menuItemScreenRasterCrossTipColorScheme->SetSelectedOption(v, false);
		viewC64->viewC64Screen->InitRasterColorsFromScheme();
	}

	else if (!strcmp(name, "PaintGridCharactersColorR"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridCharactersColorR = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridCharactersColorR->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridCharactersColorG"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridCharactersColorG = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridCharactersColorG->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridCharactersColorB"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridCharactersColorB = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridCharactersColorB->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridCharactersColorA"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridCharactersColorA = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridCharactersColorA->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridPixelsColorR"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridPixelsColorR = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridPixelsColorR->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridPixelsColorG"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridPixelsColorG = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridPixelsColorG->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridPixelsColorB"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridPixelsColorB = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridPixelsColorB->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridPixelsColorA"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridPixelsColorA = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridPixelsColorA->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridColors();
	}
	else if (!strcmp(name, "PaintGridShowZoomLevel"))
	{
		float v = *((float*)value);
		c64SettingsPaintGridShowZoomLevel = v;
		viewC64->viewC64SettingsMenu->menuItemPaintGridShowZoomLevel->SetValue(v, false);
		viewC64->viewVicEditor->InitPaintGridShowZoomLevel();
	}

	else if (!strcmp(name, "EmulateVSPBug"))
	{
		bool v = *((bool*)value);
		c64SettingsEmulateVSPBug = v;
		viewC64->debugInterface->SetVSPBugEmulation(c64SettingsEmulateVSPBug);
	}
	else if (!strcmp(name, "AutoJmp"))
	{
		bool v = *((bool*)value);
		c64SettingsAutoJmp = v;
	}
	else if (!strcmp(name, "AutoJmpAlwaysToLoadedPRGAddress"))
	{
		bool v = *((bool*)value);
		c64SettingsAutoJmpAlwaysToLoadedPRGAddress = v;
	}
	else if (!strcmp(name, "AutoJmpFromInsertedDiskFirstPrg"))
	{
		bool v = *((bool*)value);
		c64SettingsAutoJmpFromInsertedDiskFirstPrg = v;
	}
	else if (!strcmp(name, "AutoJmpDoReset"))
	{
		int v = *((int*)value);
		viewC64->viewC64SettingsMenu->menuItemAutoJmpDoReset->SetSelectedOption(v, false);
		c64SettingsAutoJmpDoReset = v;
	}
	else if (!strcmp(name, "AutoJmpWaitAfterReset"))
	{
		int v = *((int*)value);
		c64SettingsAutoJmpWaitAfterReset = v;
		viewC64->viewC64SettingsMenu->menuItemAutoJmpWaitAfterReset->SetValue(v, false);
	}
	
	else if (!strcmp(name, "VicDisplayBorder"))
	{
		u8 v = *((u8*)value);
		c64SettingsVicDisplayBorderType = v;
		viewC64->viewC64VicControl->SetBorderType(c64SettingsVicDisplayBorderType);
	}
	else if (!strcmp(name, "VicEditorForceReplaceColor"))
	{
		bool v = *((bool*)value);
		c64SettingsVicEditorForceReplaceColor = v;
	}
	else
	{
		LOGError("C64DebuggerSetSetting: unknown setting '%s'", name);
	}
}


