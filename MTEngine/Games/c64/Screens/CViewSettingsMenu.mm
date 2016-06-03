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
#include "C64DebugInterface.h"
#include "MTH_Random.h"

#include "CViewMemoryMap.h"

#include "CGuiMain.h"

#define VIEWC64SETTINGS_DUMP_C64		1
#define VIEWC64SETTINGS_DUMP_DRIVE1541	2

CViewSettingsMenu::CViewSettingsMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewSettingsMenu";

	font = viewC64->fontCBMShifted;
	fontScale = 2.7;
	fontHeight = font->GetCharHeight('@', fontScale) + 2;

	strHeader = new CSlrString("Settings");

	memoryExtensions.push_back(new CSlrString("bin"));

	/// colors
	tr = 0.64; //163/255;
	tg = 0.59; //151/255;
	tb = 1.0; //255/255;
	
	/// menu
	viewMenu = new CGuiViewMenu(35, 53, -1, sizeX-70, sizeY-74, this);

	//
	menuItemBack  = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK"),
										 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemBack);

	//
	std::vector<CSlrString *> *options = NULL;
	
	menuItemDetachEverything = new CViewC64MenuItem(fontHeight*2, new CSlrString("Detach everything"),
												   NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDetachEverything);

	kbsDumpC64Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, KBFUN_LIMIT_SPEED, 'u', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpC64Memory);

	/*
	menuItemDumpC64Memory = new CViewC64MenuItem(fontHeight, new CSlrString("Dump C64 memory"),
													kbsDumpC64Memory, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpC64Memory);
	 */

	kbsDumpDrive1541Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, KBFUN_LIMIT_SPEED, 'u', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpDrive1541Memory);
	
	/*
	menuItemDumpDrive1541Memory = new CViewC64MenuItem(fontHeight*2, new CSlrString("Dump Disk 1541 memory"),
													kbsDumpDrive1541Memory, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemDumpDrive1541Memory);
	 */
	
	///
	kbsIsWarpSpeed = new CSlrKeyboardShortcut(KBZONE_GLOBAL, KBFUN_LIMIT_SPEED, 'p', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsIsWarpSpeed);
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Off"));
	options->push_back(new CSlrString("On"));
	menuItemIsWarpSpeed = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Warp Speed: "), kbsIsWarpSpeed, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemIsWarpSpeed);
	
	///
	
	kbsUseKeboardAsJoystick = new CSlrKeyboardShortcut(KBZONE_GLOBAL, KBFUN_USE_KEYBOARD_AS_JOYSTICK, 'y', false, false, true);
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
	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetC64ModelTypes(options);
	menuItemC64Model = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Machine model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemC64Model);

	//
	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetSidTypes(options);
	menuItemSIDModel = new CViewC64MenuItemOption(fontHeight, new CSlrString("SID model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	viewMenu->AddMenuItem(menuItemSIDModel);
	
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
	options->push_back(new CSlrString("2"));
	options->push_back(new CSlrString("4"));
	options->push_back(new CSlrString("10"));
	options->push_back(new CSlrString("20"));

#if defined(MACOS)
	float fh = fontHeight;
#else
	float fh = fontHeight*2.0f;
#endif
	
	menuItemMemoryMapRefreshRate = new CViewC64MenuItemOption(fh, new CSlrString("Memory map refresh rate: "),
														 NULL, tr, tg, tb, options, font, fontScale);
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
	kbsCartridgeFreezeButton = new CSlrKeyboardShortcut(KBZONE_GLOBAL, KBFUN_CARTRIDGE_FREEZE_BUTTON, 'f', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsCartridgeFreezeButton);
	menuItemCartridgeFreeze = new CViewC64MenuItem(fontHeight, new CSlrString("Cartridge freeze"),
												   kbsCartridgeFreezeButton, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemCartridgeFreeze);
	



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
	
	C64DebuggerStoreSettings();
}

void CViewSettingsMenu::MenuCallbackItemEntered(CGuiViewMenuItem *menuItem)
{
	if (menuItem == menuItemDetachEverything)
	{
		// detach drive & cartridge
		viewC64->debugInterface->DetachCartridge();
		viewC64->debugInterface->DetachDriveDisk();
		
		viewMenu->mutex->Lock();

		
		if (viewC64->viewC64MainMenu->menuItemInsertD64->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemInsertD64->str2;
		viewC64->viewC64MainMenu->menuItemInsertD64->str2 = NULL;
		
		delete c64SettingsPathD64;
		c64SettingsPathD64 = NULL;
		
		if (viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemInsertCartridge->str2;
		viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 = NULL;
		
		delete c64SettingsPathCartridge;
		c64SettingsPathCartridge = NULL;

		if (viewC64->viewC64MainMenu->menuItemLoadPRG->str2 != NULL)
			delete viewC64->viewC64MainMenu->menuItemLoadPRG->str2;
		viewC64->viewC64MainMenu->menuItemLoadPRG->str2 = NULL;
		
		delete c64SettingsPathPRG;
		c64SettingsPathPRG = NULL;
		
		
		viewMenu->mutex->Unlock();
		
		C64DebuggerStoreSettings();

		guiMain->ShowMessage("Detached everything");
	}
	else if (menuItem == menuItemDumpC64Memory)
	{
		OpenDialogDumpC64Memory();
	}
	else if (menuItem == menuItemDumpDrive1541Memory)
	{
		OpenDialogDumpDrive1541Memory();
	}
	else if (menuItem == menuItemBack)
	{
		guiMain->SetView(viewC64->viewC64MainMenu);
	}
	

}

void CViewSettingsMenu::OpenDialogDumpC64Memory()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_C64;
	
	CSlrString *defaultFileName = new CSlrString("c64memory");
	
	CSlrString *windowTitle = new CSlrString("Dump C64 memory");
	SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpDrive1541Memory()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_DRIVE1541;
	
	CSlrString *defaultFileName = new CSlrString("1541memory");
	
	CSlrString *windowTitle = new CSlrString("Dump Disk 1541 memory");
	SYS_DialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::SystemDialogFileSaveSelected(CSlrString *path)
{
	if (openDialogFunction == VIEWC64SETTINGS_DUMP_C64)
	{
		DumpC64Memory(path);
		C64DebuggerStoreSettings();
	}
	else if (openDialogFunction == VIEWC64SETTINGS_DUMP_DRIVE1541)
	{
		DumpDisk1541Memory(path);
		C64DebuggerStoreSettings();
	}
	
	delete path;
}

void CViewSettingsMenu::SystemDialogFileSaveCancelled()
{
	
}

void CViewSettingsMenu::DumpC64Memory(CSlrString *path)
{
	path->DebugPrint("CViewSnapshots::DumpC64Memory, path=");
	
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

	FILE *fp = fopen(asciiPath, "wb");
	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory dump failed");
	}
	
	fwrite(memoryBuffer, 0x10000, 1, fp);
	fclose(fp);
	
	delete memoryBuffer;
	
	delete asciiPath;
	
	guiMain->ShowMessage("C64 memory dumped");
}

void CViewSettingsMenu::DumpDisk1541Memory(CSlrString *path)
{
	path->DebugPrint("CViewSnapshots::DumpDisk1541Memory, path=");
	
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
	
	FILE *fp = fopen(asciiPath, "wb");
	if (fp == NULL)
	{
		guiMain->ShowMessage("Saving memory dump failed");
	}
	
//	fwrite(memoryBuffer, 0x10000, 1, fp);
	fwrite(memoryBuffer, 0x0800, 1, fp);
	
	fclose(fp);

	delete asciiPath;
	
	guiMain->ShowMessage("Disk 1541 memory dumped");
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

void CViewSettingsMenu::SwitchSettingsScreen()
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
		SwitchSettingsScreen();
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
}

void CViewSettingsMenu::DeactivateView()
{
	LOGG("CViewSettingsMenu::DeactivateView()");
}

