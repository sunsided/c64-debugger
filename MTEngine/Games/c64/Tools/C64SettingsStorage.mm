#include "C64SettingsStorage.h"
#include "CViewMemoryMap.h"
#include "CSlrFileFromOS.h"
#include "CByteBuffer.h"
#include "CViewC64.h"
#include "C64DebugInterface.h"
#include "CViewMonitorConsole.h"
#include "SND_SoundEngine.h"

#define C64DEBUGGER_SETTINGS_FILE_VERSION 0x0001

///
#define C64DEBUGGER_SETTING_BLOCK	0
#define C64DEBUGGER_SETTING_STRING	1
#define C64DEBUGGER_SETTING_U8		2
#define C64DEBUGGER_SETTING_BOOL	3
#define C64DEBUGGER_SETTING_CUSTOM	4
#define C64DEBUGGER_SETTING_U16		5

/// blocks
#define C64DEBUGGER_BLOCK_EOF			0

/// settings
uint8 c64SettingsDefaultScreenLayoutId = C64_SCREEN_LAYOUT_MONITOR_CONSOLE; //C64_SCREEN_LAYOUT_C64_DEBUGGER;
//C64_SCREEN_LAYOUT_C64_DEBUGGER);
//C64_SCREEN_LAYOUT_C64_1541_MEMORY_MAP; //C64_SCREEN_LAYOUT_C64_ONLY //
//C64_SCREEN_LAYOUT_SHOW_STATES; //C64_SCREEN_LAYOUT_C64_DATA_DUMP
//C64_SCREEN_LAYOUT_C64_1541_DEBUGGER

bool c64SettingsSkipConfig = false;

uint8 c64SettingsJoystickPort = 0;

uint8 c64SettingsMemoryValuesStyle = MEMORY_MAP_VALUES_STYLE_RGB;
uint8 c64SettingsMemoryMarkersStyle = MEMORY_MAP_MARKER_STYLE_DEFAULT;
bool c64SettingsUseMultiTouchInMemoryMap = false;
bool c64SettingsMemoryMapInvertControl = false;
uint8 c64SettingsMemoryMapRefreshRate = 2;

uint8 c64SettingsC64Model = 0;
int c64SettingsEmulationMaximumSpeed = 100;
bool c64SettingsFastBootKernalPatch = false;

uint8 c64SettingsSIDEngineModel = 0;
bool c64SettingsMuteSIDOnPause = false;

int c64SettingsWaitOnStartup = 0; //500;

CSlrString *c64SettingsPathD64 = NULL;
CSlrString *c64SettingsDefaultD64Folder = NULL;

CSlrString *c64SettingsPathPRG = NULL;
CSlrString *c64SettingsDefaultPRGFolder = NULL;

CSlrString *c64SettingsPathCartridge = NULL;
CSlrString *c64SettingsDefaultCartridgeFolder = NULL;

CSlrString *c64SettingsPathSnapshot = NULL;
CSlrString *c64SettingsDefaultSnapshotsFolder = NULL;

CSlrString *c64SettingsDefaultMemoryDumpFolder = NULL;

CSlrString *c64SettingsPathToC64MemoryMapFile = NULL;

CSlrString *c64SettingsAudioOutDevice = NULL;


int c64SettingsJmpOnStartupAddr = -1;

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

void storeSettingU16(CByteBuffer *byteBuffer, char *name, u8 value)
{
	byteBuffer->PutU8(C64DEBUGGER_SETTING_U16);
	byteBuffer->PutString(name);
	byteBuffer->PutU16(value);
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
	
	storeSettingString(byteBuffer, "PathD64", c64SettingsPathD64);
	storeSettingString(byteBuffer, "PathPRG", c64SettingsPathPRG);
	storeSettingString(byteBuffer, "PathCRT", c64SettingsPathCartridge);
	
	storeSettingString(byteBuffer, "PathMemMapFile", c64SettingsPathToC64MemoryMapFile);

	storeSettingString(byteBuffer, "AudioOutDevice", c64SettingsAudioOutDevice);
	
	storeSettingBool(byteBuffer, "FastBootPatch", c64SettingsFastBootKernalPatch);
	
	storeSettingU8(byteBuffer, "ScreenLayoutId", c64SettingsDefaultScreenLayoutId);
	
	storeSettingBlock(byteBuffer, C64DEBUGGER_BLOCK_POSTLAUNCH);
	storeSettingU8(byteBuffer, "JoystickPort", c64SettingsJoystickPort);
	storeSettingU8(byteBuffer, "MemoryValuesStyle", c64SettingsMemoryValuesStyle);
	storeSettingU8(byteBuffer, "MemoryMarkersStyle", c64SettingsMemoryMarkersStyle);

	storeSettingU8(byteBuffer, "C64Model", c64SettingsC64Model);

	storeSettingU8(byteBuffer, "SIDEngineModel", c64SettingsSIDEngineModel);
	storeSettingBool(byteBuffer, "MuteSIDOnPause", c64SettingsMuteSIDOnPause);

	storeSettingBool(byteBuffer, "MemMapMultiTouch", c64SettingsUseMultiTouchInMemoryMap);
	storeSettingBool(byteBuffer, "MemMapInvert", c64SettingsMemoryMapInvertControl);
	storeSettingU8(byteBuffer, "MemMapRefresh", c64SettingsMemoryMapRefreshRate);

	storeSettingU16(byteBuffer, "EmulationMaximumSpeed", c64SettingsEmulationMaximumSpeed);
	
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
	if (version != C64DEBUGGER_SETTINGS_FILE_VERSION)
	{
		LOGError("C64DebuggerReadSettings: incompatible version %04x", version);
		delete byteBuffer;
		return;
	}
	
	u8 blockType = 0xFF;

	int valueInt;
	bool valueBool;
	
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
		else if (dataType == C64DEBUGGER_SETTING_BOOL)
		{
			valueBool = byteBuffer->GetBool();
			value = &valueBool;
		}
		else if (dataType == C64DEBUGGER_SETTING_STRING)
		{
			value = byteBuffer->GetSlrString();
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
	
	delete byteBuffer;
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
		if (c64SettingsPathD64 != NULL)
			delete c64SettingsPathD64;
		
		c64SettingsPathD64 = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->InsertD64(c64SettingsPathD64);
		}
	}
	else if (!strcmp(name, "PathPRG"))
	{
		if (c64SettingsPathPRG != NULL)
			delete c64SettingsPathPRG;
		
		c64SettingsPathPRG = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->LoadPRG(c64SettingsPathD64, false);
		}
	}
	else if (!strcmp(name, "PathCRT"))
	{
		if (c64SettingsPathCartridge != NULL)
			delete c64SettingsPathCartridge;
		
		c64SettingsPathCartridge = new CSlrString((CSlrString*)value);
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->viewC64MainMenu->InsertCartridge(c64SettingsPathCartridge);
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
	else if (!strcmp(name, "ScreenLayoutId"))
	{
		int v = *((int*)value);
		c64SettingsDefaultScreenLayoutId = v;
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
		viewC64->viewC64SettingsMenu->menuItemC64Model->SetSelectedOption(v, false);
		c64SettingsC64Model = v;
		
		if (viewC64->isEmulationThreadRunning)
		{
			viewC64->debugInterface->SetC64ModelType(c64SettingsC64Model);
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
	
}


