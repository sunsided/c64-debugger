#include "CViewC64.h"
#include "CViewSettingsMenu.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "SYS_KeyCodes.h"
#include "CSlrKeyboardShortcuts.h"
#include "CSlrFileFromOS.h"
#include "C64SettingsStorage.h"

#include "C64KeyboardShortcuts.h"
#include "CViewBreakpoints.h"
#include "CViewSnapshots.h"
#include "CViewC64KeyMap.h"
#include "CViewKeyboardShortcuts.h"
#include "C64DebugInterface.h"
#include "MTH_Random.h"

#include "CViewMemoryMap.h"

#include "CGuiMain.h"
#include "SND_SoundEngine.h"


#define VIEWC64SETTINGS_DUMP_C64_MEMORY					1
#define VIEWC64SETTINGS_DUMP_C64_MEMORY_MARKERS			2
#define VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY			3
#define VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY_MARKERS	4
#define VIEWC64SETTINGS_MAP_C64_MEMORY_TO_FILE			5

CViewSettingsMenu::CViewSettingsMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewSettingsMenu";

	font = viewC64->fontCBMShifted;
	fontScale = 2.7;
	fontHeight = font->GetCharHeight('@', fontScale) + 3;

	strHeader = new CSlrString("Settings");

	memoryExtensions.push_back(new CSlrString("bin"));
	csvExtensions.push_back(new CSlrString("csv"));

	/// colors
	tr = 0.64; //163/255;
	tg = 0.59; //151/255;
	tb = 1.0; //255/255;

	float sb = 20;

	/// menu
	viewMenu = new CGuiViewMenu(35, 51, -1, sizeX-70, sizeY-51-sb, this);

	//
	menuItemBack  = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK"),
										 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemBack);
	
	//
	std::vector<CSlrString *> *options = NULL;
	
	menuItemDetachEverything = new CViewC64MenuItem(fontHeight*2, new CSlrString("Detach everything"),
													NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDetachEverything);
	//
	

	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetC64ModelTypes(options);
	menuItemC64Model = new CViewC64MenuItemOption(fontHeight, new CSlrString("Machine model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemC64Model);

	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("10"));
	options->push_back(new CSlrString("20"));
	options->push_back(new CSlrString("50"));
	options->push_back(new CSlrString("100"));
	options->push_back(new CSlrString("200"));
	
	kbsSwitchNextMaximumSpeed = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Next maximum speed", ']', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsSwitchNextMaximumSpeed);
	kbsSwitchPrevMaximumSpeed = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Previous maximum speed", '[', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsSwitchPrevMaximumSpeed);

	menuItemMaximumSpeed = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Maximum speed: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	menuItemMaximumSpeed->SetSelectedOption(3, false);
	viewMenu->AddMenuItem(menuItemMaximumSpeed);

	//
	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetSidTypes(options);
	menuItemSIDModel = new CViewC64MenuItemOption(fontHeight, new CSlrString("SID model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemSIDModel);
	
	//
	menuItemAudioOutDevice = new CViewC64MenuItemOption(fontHeight, new CSlrString("Audio Out device: "),
														NULL, tr, tg, tb, NULL, font, fontScale);
	viewMenu->AddMenuItem(menuItemAudioOutDevice);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Yes"));
	
	menuItemMuteSIDOnPause = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Mute SID on pause: "),
														NULL, tr, tg, tb, options, font, fontScale);
	menuItemSIDModel->SetSelectedOption(c64SettingsMuteSIDOnPause, false);
	viewMenu->AddMenuItem(menuItemMuteSIDOnPause);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("RGB"));
	options->push_back(new CSlrString("Gray"));
	options->push_back(new CSlrString("None"));
	
	menuItemMemoryCellsColorStyle = new CViewC64MenuItemOption(fontHeight, new CSlrString("Memory map values color: "),
														NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemMemoryCellsColorStyle);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Default"));
	options->push_back(new CSlrString("ICU"));
	
	menuItemMemoryMarkersColorStyle = new CViewC64MenuItemOption(fontHeight, new CSlrString("Memory map markers color: "),
															   NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemMemoryMarkersColorStyle);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Yes"));
	
	menuItemMemoryMapInvert = new CViewC64MenuItemOption(fontHeight, new CSlrString("Invert memory map zoom: "),
																 NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemMemoryMapInvert);

	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("1"));
	options->push_back(new CSlrString("10"));
	options->push_back(new CSlrString("20"));
	options->push_back(new CSlrString("50"));
	options->push_back(new CSlrString("100"));
	options->push_back(new CSlrString("200"));
	options->push_back(new CSlrString("300"));
	options->push_back(new CSlrString("400"));
	options->push_back(new CSlrString("500"));
	options->push_back(new CSlrString("1000"));
	
	menuItemMemoryMapFadeSpeed = new CViewC64MenuItemOption(fontHeight, new CSlrString("Markers fade out speed: "),
													  NULL, tr, tg, tb, options, font, fontScale);
	menuItemMemoryMapFadeSpeed->SetSelectedOption(5, false);
	viewMenu->AddMenuItem(menuItemMemoryMapFadeSpeed);

	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("1"));
	options->push_back(new CSlrString("2"));
	options->push_back(new CSlrString("4"));
	options->push_back(new CSlrString("10"));
	options->push_back(new CSlrString("20"));

#if defined(MACOS)
	float fh = fontHeight;
#else
	float fh = fontHeight*2;
#endif
	
	menuItemMemoryMapRefreshRate = new CViewC64MenuItemOption(fh, new CSlrString("Memory map refresh rate: "),
														 NULL, tr, tg, tb, options, font, fontScale);
	menuItemMemoryMapRefreshRate->SetSelectedOption(1, false);
	viewMenu->AddMenuItem(menuItemMemoryMapRefreshRate);
	
	//
#if defined(MACOS)
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Yes"));
	
	menuItemMultiTouchMemoryMap = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Multi-touch map control: "),
														NULL, tr, tg, tb, options, font, fontScale);
	menuItemMultiTouchMemoryMap->SetSelectedOption(c64SettingsUseMultiTouchInMemoryMap, false);
	viewMenu->AddMenuItem(menuItemMultiTouchMemoryMap);
#endif

	//
	menuItemScreenRasterViewfinderScale = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Screen viewfinder scale: "),
																	NULL, tr, tg, tb,
																	0.05f, 25.0f, 0.05f, font, fontScale);
	menuItemScreenRasterViewfinderScale->SetValue(1.5f, false);
	viewMenu->AddMenuItem(menuItemScreenRasterViewfinderScale);
	
	menuItemScreenGridLinesAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Screen grid lines alpha: "),
															 NULL, tr, tg, tb,
															 0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenGridLinesAlpha->SetValue(0.35f, false);
	viewMenu->AddMenuItem(menuItemScreenGridLinesAlpha);

	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("red"));
	options->push_back(new CSlrString("green"));
	options->push_back(new CSlrString("blue"));
	options->push_back(new CSlrString("black"));
	options->push_back(new CSlrString("dark gray"));
	options->push_back(new CSlrString("light gray"));
	options->push_back(new CSlrString("white"));
	
	menuItemScreenGridLinesColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Grid lines: "),
																			  NULL, tr, tg, tb, options, font, fontScale);
	menuItemScreenGridLinesColorScheme->SetSelectedOption(0, false);
	viewMenu->AddMenuItem(menuItemScreenGridLinesColorScheme);

	menuItemScreenRasterCrossLinesAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Raster cross lines alpha: "),
																	NULL, tr, tg, tb,
																	0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenRasterCrossLinesAlpha->SetValue(0.35f, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossLinesAlpha);

	menuItemScreenRasterCrossLinesColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Raster cross lines: "),
																	NULL, tr, tg, tb, options, font, fontScale);
	menuItemScreenRasterCrossLinesColorScheme->SetSelectedOption(6, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossLinesColorScheme);
	

	menuItemScreenRasterCrossAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Raster cross alpha: "),
																	NULL, tr, tg, tb,
																	0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenRasterCrossAlpha->SetValue(0.85f, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossAlpha);
	
	menuItemScreenRasterCrossInteriorColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Raster cross interior: "),
																			  NULL, tr, tg, tb, options, font, fontScale);
	menuItemScreenRasterCrossInteriorColorScheme->SetSelectedOption(4, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossInteriorColorScheme);

	menuItemScreenRasterCrossExteriorColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Raster cross exterior: "),
																			  NULL, tr, tg, tb, options, font, fontScale);
	menuItemScreenRasterCrossExteriorColorScheme->SetSelectedOption(0, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossExteriorColorScheme);
	
	menuItemScreenRasterCrossTipColorScheme = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Raster cross tip: "),
																			  NULL, tr, tg, tb, options, font, fontScale);
	menuItemScreenRasterCrossTipColorScheme->SetSelectedOption(3, false);
	viewMenu->AddMenuItem(menuItemScreenRasterCrossTipColorScheme);
	

	//
	// memory mapping can be initialised only on startup
	menuItemMapC64MemoryToFile = new CViewC64MenuItem(fontHeight*3, NULL,
													  NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemMapC64MemoryToFile);
	
	UpdateMapC64MemoryToFileLabels();
	
	///
	kbsDumpC64Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Dump C64 memory", 'u', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpC64Memory);
	
	menuItemDumpC64Memory = new CViewC64MenuItem(fontHeight, new CSlrString("Dump C64 memory"),
													kbsDumpC64Memory, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpC64Memory);
	
	menuItemDumpC64MemoryMarkers = new CViewC64MenuItem(fontHeight, new CSlrString("Dump C64 memory markers"),
														NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpC64MemoryMarkers);
	
	kbsDumpDrive1541Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Dump Drive 1541 memory", 'u', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpDrive1541Memory);
	
	menuItemDumpDrive1541Memory = new CViewC64MenuItem(fontHeight, new CSlrString("Dump Disk 1541 memory"),
													   kbsDumpDrive1541Memory, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpDrive1541Memory);
	
	menuItemDumpDrive1541MemoryMarkers = new CViewC64MenuItem(fontHeight*2, new CSlrString("Dump Disk 1541 memory markers"),
															  NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpDrive1541MemoryMarkers);

	//

	kbsClearMemoryMarkers = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Clear Memory markers", MTKEY_BACKSPACE, false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsClearMemoryMarkers);
	menuItemClearMemoryMarkers = new CViewC64MenuItem(fontHeight*2, new CSlrString("Clear Memory markers"),
															  kbsClearMemoryMarkers, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemClearMemoryMarkers);

	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Yes"));

	kbsUseKeboardAsJoystick = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Use keyboard as joystick", 'y', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsUseKeboardAsJoystick);
	menuItemUseKeyboardAsJoystick = new CViewC64MenuItemOption(fontHeight, new CSlrString("Use keyboard as joystick: "),
															   kbsUseKeboardAsJoystick, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemUseKeyboardAsJoystick);
	///
	
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("both"));
	options->push_back(new CSlrString("1"));
	options->push_back(new CSlrString("2"));
	menuItemJoystickPort = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Joystick port: "),
													  NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemJoystickPort);
	
	
	//
	menuItemSetC64KeyboardMapping = new CViewC64MenuItem(fontHeight, new CSlrString("Set C64 keyboard mapping"),
													NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemSetC64KeyboardMapping);

	menuItemSetKeyboardShortcuts = new CViewC64MenuItem(fontHeight*2, new CSlrString("Set keyboard shortcuts"),
														 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemSetKeyboardShortcuts);


	//

	kbsIsWarpSpeed = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Warp speed", 'p', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsIsWarpSpeed);
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Off"));
	options->push_back(new CSlrString("On"));
	menuItemIsWarpSpeed = new CViewC64MenuItemOption(fontHeight, new CSlrString("Warp Speed: "), kbsIsWarpSpeed, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemIsWarpSpeed);
	
	//
	kbsCartridgeFreezeButton = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Cartridge freeze", 'f', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsCartridgeFreezeButton);
	menuItemCartridgeFreeze = new CViewC64MenuItem(fontHeight, new CSlrString("Cartridge freeze"),
												   kbsCartridgeFreezeButton, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemCartridgeFreeze);
	
	///
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Yes"));
	
	menuItemFastBootKernalPatch = new CViewC64MenuItemOption(fontHeight*2.0f, new CSlrString("Fast boot kernal patch: "),
															 NULL, tr, tg, tb, options, font, fontScale);
	menuItemFastBootKernalPatch->SetSelectedOption(c64SettingsFastBootKernalPatch, false);
	viewMenu->AddMenuItem(menuItemFastBootKernalPatch);

	menuItemDisassembleExecuteAware = new CViewC64MenuItemOption(fontHeight*2.0f, new CSlrString("Execute-aware disassemble: "),
																 NULL, tr, tg, tb, options, font, fontScale);
	menuItemDisassembleExecuteAware->SetSelectedOption(c64SettingsRenderDisassembleExecuteAware, false);
	viewMenu->AddMenuItem(menuItemDisassembleExecuteAware);

	
	menuItemWindowAlwaysOnTop = new CViewC64MenuItemOption(fontHeight*2.0f, new CSlrString("Window always on top: "),
																 NULL, tr, tg, tb, options, font, fontScale);
	menuItemWindowAlwaysOnTop->SetSelectedOption(c64SettingsWindowAlwaysOnTop, false);
	viewMenu->AddMenuItem(menuItemWindowAlwaysOnTop);
	

	float d = 1.25f;//0.75f;
	menuItemClearSettings = new CViewC64MenuItem(fontHeight*d, new CSlrString("Clear settings to factory defaults"),
															 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemClearSettings);

}

void CViewSettingsMenu::UpdateMapC64MemoryToFileLabels()
{
	guiMain->LockMutex();

	if (c64SettingsPathToC64MemoryMapFile == NULL)
	{
		menuItemMapC64MemoryToFile->SetString(new CSlrString("Map C64 memory to a file"));
		if (menuItemMapC64MemoryToFile->str2 != NULL)
			delete menuItemMapC64MemoryToFile->str2;
		menuItemMapC64MemoryToFile->str2 = NULL;
	}
	else
	{
		menuItemMapC64MemoryToFile->SetString(new CSlrString("Unmap C64 memory from file"));
		
		char *asciiPath = c64SettingsPathToC64MemoryMapFile->GetStdASCII();
		
		// display file name in menu
		char *fname = SYS_GetFileNameFromFullPath(asciiPath);
		
		if (menuItemMapC64MemoryToFile->str2 != NULL)
			delete menuItemMapC64MemoryToFile->str2;
		
		menuItemMapC64MemoryToFile->str2 = new CSlrString(fname);
		delete fname;
	}
	guiMain->UnlockMutex();
}

void CViewSettingsMenu::UpdateAudioOutDevices()
{
	guiMain->LockMutex();
	
	std::list<CSlrString *> *audioDevicesList = NULL;
	audioDevicesList = gSoundEngine->EnumerateAvailableOutputDevices();
	
	std::vector<CSlrString *> *audioDevices = new std::vector<CSlrString *>();
	for (std::list<CSlrString *>::iterator it = audioDevicesList->begin(); it != audioDevicesList->end(); it++)
	{
		CSlrString *str = *it;
		audioDevices->push_back(str);
	}
	delete audioDevicesList;
	
	menuItemAudioOutDevice->SetOptions(audioDevices);
	
	LOGD("CViewSettingsMenu::UpdateAudioOutDevices: selected AudioOut device=%s", gSoundEngine->deviceOutName);

	CSlrString *deviceOutNameStr = new CSlrString(gSoundEngine->deviceOutName);
	
	int i = 0;
	for (std::vector<CSlrString *>::iterator it = audioDevices->begin(); it != audioDevices->end(); it++)
	{
		CSlrString *str = *it;
		if (deviceOutNameStr->CompareWith(str))
		{
			menuItemAudioOutDevice->SetSelectedOption(i, false);
			break;
		}
		
		i++;
	}
	
	guiMain->UnlockMutex();
}

CViewSettingsMenu::~CViewSettingsMenu()
{
}

void CViewSettingsMenu::MenuCallbackItemChanged(CGuiViewMenuItem *menuItem)
{
	if (menuItem == menuItemIsWarpSpeed)
	{
		if (menuItemIsWarpSpeed->selectedOption == 0)
		{
			viewC64->debugInterface->SetSettingIsWarpSpeed(false);
		}
		else
		{
			viewC64->debugInterface->SetSettingIsWarpSpeed(true);
		}
	}
	else if (menuItem == menuItemUseKeyboardAsJoystick)
	{
		if (menuItemUseKeyboardAsJoystick->selectedOption == 0)
		{
			viewC64->debugInterface->SetSettingUseKeyboardForJoystick(false);
			guiMain->ShowMessage("Joystick is OFF");
		}
		else
		{
			viewC64->debugInterface->SetSettingUseKeyboardForJoystick(true);
			guiMain->ShowMessage("Joystick is ON");
		}
	}
	else if (menuItem == menuItemJoystickPort)
	{
		C64DebuggerSetSetting("JoystickPort", &(menuItemJoystickPort->selectedOption));
	}
	else if (menuItem == menuItemSIDModel)
	{
		C64DebuggerSetSetting("SIDEngineModel", &(menuItemSIDModel->selectedOption));
	}
	else if (menuItem == menuItemMuteSIDOnPause)
	{
		bool v = menuItemMuteSIDOnPause->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("MuteSIDOnPause", &(v));
	}
	else if (menuItem == menuItemFastBootKernalPatch)
	{
		bool v = menuItemFastBootKernalPatch->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("FastBootPatch", &(v));
		
		guiMain->ShowMessage("Please restart debugger to apply ROM changes");
	}
	else if (menuItem == menuItemDisassembleExecuteAware)
	{
		bool v = menuItemDisassembleExecuteAware->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("DisassembleExecuteAware", &(v));
	}
	else if (menuItem == menuItemWindowAlwaysOnTop)
	{
		bool v = menuItemWindowAlwaysOnTop->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("WindowAlwaysOnTop", &(v));
	}
	else if (menuItem == menuItemAudioOutDevice)
	{
		CSlrString *deviceName = (*menuItemAudioOutDevice->options)[menuItemAudioOutDevice->selectedOption];
		C64DebuggerSetSetting("AudioOutDevice", deviceName);
	}
	else if (menuItem == menuItemC64Model)
	{
		C64DebuggerSetSetting("C64Model", &(menuItemC64Model->selectedOption));
	}
	else if (menuItem == menuItemMemoryCellsColorStyle)
	{
		C64DebuggerSetSetting("MemoryValuesStyle", &(menuItemMemoryCellsColorStyle->selectedOption));
	}
	else if (menuItem == menuItemMemoryMarkersColorStyle)
	{
		C64DebuggerSetSetting("MemoryMarkersStyle", &(menuItemMemoryMarkersColorStyle->selectedOption));
	}
#if defined(MACOS)
	else if (menuItem == menuItemMultiTouchMemoryMap)
	{
		bool v = menuItemMultiTouchMemoryMap->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("MemMapMultiTouch", &(v));
	}
#endif
	else if (menuItem == menuItemMemoryMapInvert)
	{
		bool v = menuItemMemoryMapInvert->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("MemMapInvert", &(v));
	}
	else if (menuItem == menuItemMemoryMapRefreshRate)
	{
		int sel = menuItemMemoryMapRefreshRate->selectedOption;
		
		if (sel == 0)
		{
			int v = 1;
			C64DebuggerSetSetting("MemMapRefresh", &v);
		}
		else if (sel == 1)
		{
			int v = 2;
			C64DebuggerSetSetting("MemMapRefresh", &v);
		}
		else if (sel == 2)
		{
			int v = 4;
			C64DebuggerSetSetting("MemMapRefresh", &v);
		}
		else if (sel == 3)
		{
			int v = 10;
			C64DebuggerSetSetting("MemMapRefresh", &v);
		}
		else if (sel == 4)
		{
			int v = 20;
			C64DebuggerSetSetting("MemMapRefresh", &v);
		}
	}
	else if (menuItem == menuItemScreenGridLinesAlpha)
	{
		float v = menuItemScreenGridLinesAlpha->value;
		C64DebuggerSetSetting("GridLinesAlpha", &v);
	}
	else if (menuItem == menuItemScreenGridLinesColorScheme)
	{
		int v = menuItemScreenGridLinesColorScheme->selectedOption;
		C64DebuggerSetSetting("GridLinesColor", &v);
	}
	else if (menuItem == menuItemScreenRasterViewfinderScale)
	{
		float v = menuItemScreenRasterViewfinderScale->value;
		C64DebuggerSetSetting("ViewfinderScale", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossLinesAlpha)
	{
		float v = menuItemScreenRasterCrossLinesAlpha->value;
		C64DebuggerSetSetting("CrossLinesAlpha", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossLinesColorScheme)
	{
		int v = menuItemScreenRasterCrossLinesColorScheme->selectedOption;
		C64DebuggerSetSetting("CrossLinesColor", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossAlpha)
	{
		float v = menuItemScreenRasterCrossAlpha->value;
		C64DebuggerSetSetting("CrossAlpha", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossInteriorColorScheme)
	{
		int v = menuItemScreenRasterCrossInteriorColorScheme->selectedOption;
		C64DebuggerSetSetting("CrossInteriorColor", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossExteriorColorScheme)
	{
		int v = menuItemScreenRasterCrossExteriorColorScheme->selectedOption;
		C64DebuggerSetSetting("CrossExteriorColor", &v);
	}
	else if (menuItem == menuItemScreenRasterCrossTipColorScheme)
	{
		int v = menuItemScreenRasterCrossTipColorScheme->selectedOption;
		C64DebuggerSetSetting("CrossTipColor", &v);
	}
	//
	else if (menuItem == menuItemMemoryMapFadeSpeed)
	{
		int sel = menuItemMemoryMapFadeSpeed->selectedOption;
		
		int newFadeSpeed = 100;
		if (sel == 0)
		{
			newFadeSpeed = 1;
		}
		else if (sel == 1)
		{
			newFadeSpeed = 10;
		}
		else if (sel == 2)
		{
			newFadeSpeed = 20;
		}
		else if (sel == 3)
		{
			newFadeSpeed = 50;
		}
		else if (sel == 4)
		{
			newFadeSpeed = 100;
		}
		else if (sel == 5)
		{
			newFadeSpeed = 200;
		}
		else if (sel == 6)
		{
			newFadeSpeed = 300;
		}
		else if (sel == 7)
		{
			newFadeSpeed = 400;
		}
		else if (sel == 8)
		{
			newFadeSpeed = 500;
		}
		else if (sel == 9)
		{
			newFadeSpeed = 1000;
		}
		
		C64DebuggerSetSetting("MemMapFadeSpeed", &newFadeSpeed);
	}
	else if (menuItem == menuItemMaximumSpeed)
	{
		int sel = menuItemMaximumSpeed->selectedOption;
		
		int newMaximumSpeed = 100;
		if (sel == 0)
		{
			newMaximumSpeed = 10;
		}
		else if (sel == 1)
		{
			newMaximumSpeed = 20;
		}
		else if (sel == 2)
		{
			newMaximumSpeed = 50;
		}
		else if (sel == 3)
		{
			newMaximumSpeed = 100;
		}
		else if (sel == 4)
		{
			newMaximumSpeed = 200;
		}
		
		SetEmulationMaximumSpeed(newMaximumSpeed);
	}
	
	C64DebuggerStoreSettings();
}

void CViewSettingsMenu::SwitchNextMaximumSpeed()
{
	int newMaximumSpeed = 100;
	switch(c64SettingsEmulationMaximumSpeed)
	{
		case 10:
			newMaximumSpeed = 20;
			break;
		case 20:
			newMaximumSpeed = 50;
			break;
		case 50:
			newMaximumSpeed = 100;
			break;
		case 100:
			newMaximumSpeed = 200;
			break;
		case 200:
			newMaximumSpeed = 10;
			break;
		default:
			newMaximumSpeed = 100;
			break;
	}
	
	SetEmulationMaximumSpeed(newMaximumSpeed);
}

void CViewSettingsMenu::SwitchPrevMaximumSpeed()
{
	int newMaximumSpeed = 100;
	switch(c64SettingsEmulationMaximumSpeed)
	{
		case 10:
			newMaximumSpeed = 200;
			break;
		case 20:
			newMaximumSpeed = 10;
			break;
		case 50:
			newMaximumSpeed = 20;
			break;
		case 100:
			newMaximumSpeed = 50;
			break;
		case 200:
			newMaximumSpeed = 100;
			break;
		default:
			newMaximumSpeed = 100;
			break;
	}
	
	SetEmulationMaximumSpeed(newMaximumSpeed);
	
}

void CViewSettingsMenu::SetEmulationMaximumSpeed(int maximumSpeed)
{
	C64DebuggerSetSetting("EmulationMaximumSpeed", &maximumSpeed);
	
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Emulation speed set to %d", maximumSpeed);
	guiMain->ShowMessage(buf);
	SYS_ReleaseCharBuf(buf);
}


void CViewSettingsMenu::MenuCallbackItemEntered(CGuiViewMenuItem *menuItem)
{
	if (menuItem == menuItemDetachEverything)
	{
		// detach drive & cartridge
		viewC64->debugInterface->DetachCartridge();
		viewC64->debugInterface->DetachDriveDisk();
		
		guiMain->LockMutex();
		
		if (viewC64->viewC64MainMenu->menuItemInsertD64->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemInsertD64->str2;
		viewC64->viewC64MainMenu->menuItemInsertD64->str2 = NULL;
		
		delete c64SettingsPathToD64;
		c64SettingsPathToD64 = NULL;
		
		if (viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemInsertCartridge->str2;
		viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 = NULL;
		
		delete c64SettingsPathToCartridge;
		c64SettingsPathToCartridge = NULL;

		if (viewC64->viewC64MainMenu->menuItemLoadPRG->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemLoadPRG->str2;
		viewC64->viewC64MainMenu->menuItemLoadPRG->str2 = NULL;
		
		delete c64SettingsPathToPRG;
		c64SettingsPathToPRG = NULL;
		
		
		guiMain->UnlockMutex();
		
		C64DebuggerStoreSettings();

		guiMain->ShowMessage("Detached everything");
	}
	else if (menuItem == menuItemDumpC64Memory)
	{
		OpenDialogDumpC64Memory();
	}
	else if (menuItem == menuItemDumpC64MemoryMarkers)
	{
		OpenDialogDumpC64MemoryMarkers();
	}
	else if (menuItem == menuItemDumpDrive1541Memory)
	{
		OpenDialogDumpDrive1541Memory();
	}
	else if (menuItem == menuItemDumpDrive1541MemoryMarkers)
	{
		OpenDialogDumpDrive1541MemoryMarkers();
	}
	else if (menuItem == menuItemMapC64MemoryToFile)
	{
		if (c64SettingsPathToC64MemoryMapFile == NULL)
		{
			OpenDialogMapC64MemoryToFile();
		}
		else
		{
			guiMain->LockMutex();
			delete c64SettingsPathToC64MemoryMapFile;
			c64SettingsPathToC64MemoryMapFile = NULL;
			guiMain->UnlockMutex();
			
			C64DebuggerStoreSettings();
			
			UpdateMapC64MemoryToFileLabels();
			guiMain->ShowMessage("Please restart debugger to unmap file");
		}
	}
	else if (menuItem == menuItemSetC64KeyboardMapping)
	{
		guiMain->SetView(viewC64->viewC64KeyMap);
	}
	else if (menuItem == menuItemSetKeyboardShortcuts)
	{
		guiMain->SetView(viewC64->viewKeyboardShortcuts);
	}
	else if (menuItem == menuItemClearMemoryMarkers)
	{
		ClearMemoryMarkers();
	}
	else if (menuItem == menuItemClearSettings)
	{
		CByteBuffer *byteBuffer = new CByteBuffer();
		byteBuffer->PutU16(0xFFFF);
		CSlrString *fileName = new CSlrString("/settings.dat");
		byteBuffer->storeToSettings(fileName);
		
		fileName->Set("/shortcuts.dat");
		byteBuffer->storeToSettings(fileName);
		
		fileName->Set("/keymap.dat");
		byteBuffer->storeToSettings(fileName);
		
		delete fileName;
		delete byteBuffer;
		
		guiMain->ShowMessage("Settings cleared, please restart C64 debugger");
		return;
	}
	else if (menuItem == menuItemBack)
	{
		guiMain->SetView(viewC64->viewC64MainMenu);
	}
}

void CViewSettingsMenu::ClearMemoryMarkers()
{
	viewC64->viewC64MemoryMap->ClearExecuteMarkers();
	viewC64->viewDrive1541MemoryMap->ClearExecuteMarkers();
	
	guiMain->ShowMessage("Memory markers cleared");
}

void CViewSettingsMenu::OpenDialogDumpC64Memory()
{
	//c64SettingsDefaultMemoryDumpFolder->DebugPrint("c64SettingsDefaultMemoryDumpFolder=");
	
	openDialogFunction = VIEWC64SETTINGS_DUMP_C64_MEMORY;
	
	CSlrString *defaultFileName = new CSlrString("c64memory");
	
	CSlrString *windowTitle = new CSlrString("Dump C64 memory");
	SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpC64MemoryMarkers()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_C64_MEMORY_MARKERS;
	
	CSlrString *defaultFileName = new CSlrString("c64markers");
	
	CSlrString *windowTitle = new CSlrString("Dump C64 memory markers");
	SYS_DialogSaveFile(this, &csvExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpDrive1541Memory()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY;
	
	CSlrString *defaultFileName = new CSlrString("1541memory");
	
	CSlrString *windowTitle = new CSlrString("Dump Disk 1541 memory");
	SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpDrive1541MemoryMarkers()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY_MARKERS;
	
	CSlrString *defaultFileName = new CSlrString("1541markers");
	
	CSlrString *windowTitle = new CSlrString("Dump Disk 1541 memory markers");
	SYS_DialogSaveFile(this, &csvExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}


void CViewSettingsMenu::OpenDialogMapC64MemoryToFile()
{
	openDialogFunction = VIEWC64SETTINGS_MAP_C64_MEMORY_TO_FILE;
	
	CSlrString *defaultFileName = new CSlrString("c64memory");
	
	CSlrString *windowTitle = new CSlrString("Map C64 memory to file");
	SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::SystemDialogFileSaveSelected(CSlrString *path)
{
	if (openDialogFunction == VIEWC64SETTINGS_DUMP_C64_MEMORY)
	{
		DumpC64Memory(path);
		C64DebuggerStoreSettings();
	}
	else if (openDialogFunction == VIEWC64SETTINGS_DUMP_C64_MEMORY_MARKERS)
	{
		DumpC64MemoryMarkers(path);
		C64DebuggerStoreSettings();
	}
	else if (openDialogFunction == VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY)
	{
		DumpDisk1541Memory(path);
		C64DebuggerStoreSettings();
	}
	else if (openDialogFunction == VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY_MARKERS)
	{
		DumpDisk1541MemoryMarkers(path);
		C64DebuggerStoreSettings();
	}
	else if (openDialogFunction == VIEWC64SETTINGS_MAP_C64_MEMORY_TO_FILE)
	{
		MapC64MemoryToFile(path);
		C64DebuggerStoreSettings();
	}
	
	delete path;
}

void CViewSettingsMenu::SystemDialogFileSaveCancelled()
{
	
}

void CViewSettingsMenu::DumpC64Memory(CSlrString *path)
{
	//path->DebugPrint("CViewSettingsMenu::DumpC64Memory, path=");

	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = path->GetFilePathWithoutFileNameComponentFromPath();

	char *asciiPath = path->GetStdASCII();
	
	// local copy of memory
	uint8 *memoryBuffer = new uint8[0x10000];
	
//	if (viewC64->viewC64MemoryMap->isDataDirectlyFromRAM)
	{
		viewC64->debugInterface->GetWholeMemoryMapFromRamC64(memoryBuffer);
	}
//	else
//	{
//		viewC64->debugInterface->GetWholeMemoryMapC64(memoryBuffer);
//	}

	memoryBuffer[0x0000] = viewC64->debugInterface->GetByteFromRamC64(0x0000);
	memoryBuffer[0x0001] = viewC64->debugInterface->GetByteFromRamC64(0x0001);

	FILE *fp = fopen(asciiPath, "wb");
	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory dump failed");
		return;
	}
	
	fwrite(memoryBuffer, 0x10000, 1, fp);
	fclose(fp);
	
	delete [] memoryBuffer;
	delete [] asciiPath;
	
	guiMain->ShowMessage("C64 memory dumped");
}

void CViewSettingsMenu::DumpDisk1541Memory(CSlrString *path)
{
	//path->DebugPrint("CViewSettingsMenu::DumpDisk1541Memory, path=");
	
	char *asciiPath = path->GetStdASCII();

	// local copy of memory
	uint8 *memoryBuffer = new uint8[0x10000];
	
//	if (viewC64->viewC64MemoryMap->isDataDirectlyFromRAM)
	{
		viewC64->debugInterface->GetWholeMemoryMapFromRam1541(memoryBuffer);
	}
//	else
//	{
//		viewC64->debugInterface->GetWholeMemoryMap1541(memoryBuffer);
//	}
	
	memoryBuffer[0x0000] = viewC64->debugInterface->GetByteFromRam1541(0x0000);
	memoryBuffer[0x0001] = viewC64->debugInterface->GetByteFromRam1541(0x0001);
	
	FILE *fp = fopen(asciiPath, "wb");
	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory dump failed");
		return;
	}
	
//	fwrite(memoryBuffer, 0x10000, 1, fp);
	fwrite(memoryBuffer, 0x0800, 1, fp);
	
	fclose(fp);

	delete [] memoryBuffer;
	delete [] asciiPath;
	
	guiMain->ShowMessage("Drive 1541 memory dumped");
}


void CViewSettingsMenu::DumpC64MemoryMarkers(CSlrString *path)
{
	//path->DebugPrint("CViewSettingsMenu::DumpC64MemoryMarkers, path=");
	
	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = path->GetFilePathWithoutFileNameComponentFromPath();
	
	char *asciiPath = path->GetStdASCII();
	
	FILE *fp = fopen(asciiPath, "wb");
	delete [] asciiPath;

	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory markers failed");
		return;
	}
	
	viewC64->debugInterface->LockMutex();
	
	// local copy of memory
	uint8 *memoryBuffer = new uint8[0x10000];
	
	if (viewC64->viewC64MemoryMap->isDataDirectlyFromRAM)
	{
		viewC64->debugInterface->GetWholeMemoryMapFromRamC64(memoryBuffer);
	}
	else
	{
		viewC64->debugInterface->GetWholeMemoryMapC64(memoryBuffer);
	}

	memoryBuffer[0x0000] = viewC64->debugInterface->GetByteFromRamC64(0x0000);
	memoryBuffer[0x0001] = viewC64->debugInterface->GetByteFromRamC64(0x0001);

	fprintf(fp, "Address,Value,Read,Write,Execute,Argument\n");
	
	for (int i = 0; i < 0x10000; i++)
	{
		CViewMemoryMapCell *cell = viewC64->viewC64MemoryMap->memoryCells[i];
		
		fprintf(fp, "%04x,%02x,%s,%s,%s,%s\n", i, memoryBuffer[i],
				cell->isRead ? "read" : "",
				cell->isWrite ? "write" : "",
				cell->isExecuteCode ? "execute" : "",
				cell->isExecuteArgument ? "argument" : "");
	}
	
	fclose(fp);

	delete [] memoryBuffer;

	viewC64->debugInterface->UnlockMutex();

	guiMain->ShowMessage("C64 memory markers saved");
}

void CViewSettingsMenu::DumpDisk1541MemoryMarkers(CSlrString *path)
{
	//path->DebugPrint("CViewSettingsMenu::DumpDisk1541MemoryMarkers, path=");
	
	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = path->GetFilePathWithoutFileNameComponentFromPath();
	
	char *asciiPath = path->GetStdASCII();
	
	FILE *fp = fopen(asciiPath, "wb");
	delete [] asciiPath;
	
	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory markers failed");
		return;
	}
	
	viewC64->debugInterface->LockMutex();
	
	// local copy of memory
	uint8 *memoryBuffer = new uint8[0x10000];
	
	if (viewC64->viewDrive1541MemoryMap->isDataDirectlyFromRAM)
	{
		for (int addr = 0; addr < 0x10000; addr++)
		{
			memoryBuffer[addr] = viewC64->debugInterface->GetByteFromRam1541(addr);
		}
	}
	else
	{
		for (int addr = 0; addr < 0x10000; addr++)
		{
			memoryBuffer[addr] = viewC64->debugInterface->GetByte1541(addr);
		}
	}
	
	memoryBuffer[0x0000] = viewC64->debugInterface->GetByteFromRam1541(0x0000);
	memoryBuffer[0x0001] = viewC64->debugInterface->GetByteFromRam1541(0x0001);
	
	fprintf(fp, "Address,Value,Read,Write,Execute,Argument\n");
	
	for (int i = 0; i < 0x10000; i++)
	{
		CViewMemoryMapCell *cell = viewC64->viewDrive1541MemoryMap->memoryCells[i];
		
		fprintf(fp, "%04x,%02x,%s,%s,%s,%s\n", i, memoryBuffer[i],
				cell->isRead ? "read" : "",
				cell->isWrite ? "write" : "",
				cell->isExecuteCode ? "execute" : "",
				cell->isExecuteArgument ? "argument" : "");
	}
	
	fclose(fp);
	
	delete [] memoryBuffer;
	
	viewC64->debugInterface->UnlockMutex();
	
	guiMain->ShowMessage("Drive 1541 memory markers saved");
}




void CViewSettingsMenu::MapC64MemoryToFile(CSlrString *path)
{
	//path->DebugPrint("CViewSettingsMenu::MapC64MemoryToFile, path=");
	
	if (c64SettingsPathToC64MemoryMapFile != path)
	{
		if (c64SettingsPathToC64MemoryMapFile != NULL)
			delete c64SettingsPathToC64MemoryMapFile;
		c64SettingsPathToC64MemoryMapFile = new CSlrString(path);
	}
	
	if (c64SettingsDefaultMemoryDumpFolder != NULL)
		delete c64SettingsDefaultMemoryDumpFolder;
	c64SettingsDefaultMemoryDumpFolder = path->GetFilePathWithoutFileNameComponentFromPath();
	
	UpdateMapC64MemoryToFileLabels();
	
	guiMain->ShowMessage("Please restart debugger to map memory");
}


void CViewSettingsMenu::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewSettingsMenu::Render()
{
//	guiMain->fntConsole->BlitText("CViewSettingsMenu", 0, 0, 0, 11, 1.0);

	BlitFilledRectangle(0, 0, -1, sizeX, sizeY, 0.5, 0.5, 1.0, 1.0);
		
	float sb = 20;
	float gap = 4;
	
	float tr = 0.64; //163/255;
	float tg = 0.59; //151/255;
	float tb = 1.0; //255/255;
	
	float lr = 0.64;
	float lg = 0.65;
	float lb = 0.65;
	float lSizeY = 3;
	
	float ar = lr;
	float ag = lg;
	float ab = lb;
	
	float scrx = sb;
	float scry = sb;
	float scrsx = sizeX - sb*2.0f;
	float scrsy = sizeY - sb*2.0f;
	float cx = scrsx/2.0f + sb;
	float ax = scrx + scrsx - sb;
	
	BlitFilledRectangle(scrx, scry, -1, scrsx, scrsy, 0, 0, 1.0, 1.0);
	
	float px = scrx + gap;
	float py = scry + gap;
	
	font->BlitTextColor(strHeader, cx, py, -1, fontScale, tr, tg, tb, 1, FONT_ALIGN_CENTER);
	py += fontHeight;
//	font->BlitTextColor(strHeader2, cx, py, -1, fontScale, tr, tg, tb, 1, FONT_ALIGN_CENTER);
//	py += fontHeight;
	py += 4.0f;
	
	BlitFilledRectangle(scrx, py, -1, scrsx, lSizeY, lr, lg, lb, 1);
	
	py += lSizeY + gap + 4.0f;

	viewMenu->Render();
	
//	font->BlitTextColor("1541 Device 8...", px, py, -1, fontScale, tr, tg, tb, 1);
//	font->BlitTextColor("Alt+8", ax, py, -1, fontScale, tr, tg, tb, 1);
	
	CGuiView::Render();
}

void CViewSettingsMenu::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CViewSettingsMenu::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewSettingsMenu::ButtonPressed(CGuiButton *button)
{
	/*
	if (button == btnDone)
	{
		guiMain->SetView((CGuiView*)guiMain->viewMainEditor);
		GUI_SetPressConsumed(true);
		return true;
	}
	*/
	return false;
}

//@returns is consumed
bool CViewSettingsMenu::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSettingsMenu::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CViewSettingsMenu::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSettingsMenu::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewSettingsMenu::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSettingsMenu::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewSettingsMenu::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewSettingsMenu::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewSettingsMenu::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewSettingsMenu::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewSettingsMenu::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewSettingsMenu::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewSettingsMenu::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewSettingsMenu::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewSettingsMenu::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewSettingsMenu::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CViewSettingsMenu::SwitchMainMenuScreen()
{
	if (guiMain->currentView == this)
	{
		guiMain->SetView(viewC64);
	}
	else
	{
		guiMain->SetView(this);
	}
}

bool CViewSettingsMenu::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (keyCode == MTKEY_BACKSPACE)
	{
		guiMain->SetView(viewC64->viewC64MainMenu);
		return true;
	}
	
	if (viewMenu->KeyDown(keyCode, isShift, isAlt, isControl))
		return true;

	if (viewC64->ProcessGlobalKeyboardShortcut(keyCode, isShift, isAlt, isControl))
	{
		return true;
	}

	if (keyCode == MTKEY_ESC)
	{
		SwitchMainMenuScreen();
		return true;
	}


	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewSettingsMenu::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (viewMenu->KeyUp(keyCode, isShift, isAlt, isControl))
		return true;
	
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewSettingsMenu::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewSettingsMenu::ActivateView()
{
	LOGG("CViewSettingsMenu::ActivateView()");
	
	UpdateAudioOutDevices();
}

void CViewSettingsMenu::DeactivateView()
{
	LOGG("CViewSettingsMenu::DeactivateView()");
}

