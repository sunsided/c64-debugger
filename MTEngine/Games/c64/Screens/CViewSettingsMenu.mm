#include "CViewC64.h"
#include "CColorsTheme.h"
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
#include "C64Palette.h"

#include "CViewC64StateSID.h"
#include "CViewMemoryMap.h"

#include "CGuiMain.h"
#include "SND_SoundEngine.h"

#if defined(WIN32)
extern "C" {
	int uilib_cpu_is_smp(void);
	int set_single_cpu(int val, void *param);	// 1=set to first CPU, 0=set to all CPUs
}
#endif

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
	tr = viewC64->colorsTheme->colorTextR;
	tg = viewC64->colorsTheme->colorTextG;
	tb = viewC64->colorsTheme->colorTextB;

	float sb = 20;

	/// menu
	viewMenu = new CGuiViewMenu(35, 51, -1, sizeX-70, sizeY-51-sb, this);

	//
	menuItemBack  = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK"),
										 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemBack);

	//
	CViewC64MenuItem *menuItemBackSubMenu;
	
	///
	
	menuItemSubMenuEmulation = new CViewC64MenuItem(fontHeight, new CSlrString("Emulation >>"),
													NULL, tr, tg, tb, viewMenu);
	viewMenu->AddMenuItem(menuItemSubMenuEmulation);
	
	menuItemSubMenuEmulation->DebugPrint();

	
	menuItemBackSubMenu = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK to Settings"),
																 NULL, tr, tg, tb);
	menuItemBackSubMenu->subMenu = viewMenu;
	menuItemSubMenuEmulation->subMenu->AddMenuItem(menuItemBackSubMenu);
	
	menuItemBackSubMenu->DebugPrint();
	
	//

	//
	menuItemSubMenuAudio = new CViewC64MenuItem(fontHeight, new CSlrString("Audio >>"),
													NULL, tr, tg, tb, viewMenu);
	viewMenu->AddMenuItem(menuItemSubMenuAudio);
	
	menuItemSubMenuAudio->DebugPrint();
	
	
	menuItemBackSubMenu = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK to Settings"),
											   NULL, tr, tg, tb);
	menuItemBackSubMenu->subMenu = viewMenu;
	menuItemSubMenuAudio->subMenu->AddMenuItem(menuItemBackSubMenu);
	
	menuItemBackSubMenu->DebugPrint();
	
	//

	//
	menuItemSubMenuMemory = new CViewC64MenuItem(fontHeight, new CSlrString("Memory >>"),
												NULL, tr, tg, tb, viewMenu);
	viewMenu->AddMenuItem(menuItemSubMenuMemory);
	
	menuItemSubMenuMemory->DebugPrint();
	
	
	menuItemBackSubMenu = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("<< BACK to Settings"),
											   NULL, tr, tg, tb);
	menuItemBackSubMenu->subMenu = viewMenu;
	menuItemSubMenuMemory->subMenu->AddMenuItem(menuItemBackSubMenu);
	
	menuItemBackSubMenu->DebugPrint();
	
	//

	//
	menuItemSubMenuUI = new CViewC64MenuItem(fontHeight*2, new CSlrString("UI >>"),
												 NULL, tr, tg, tb, viewMenu);
	viewMenu->AddMenuItem(menuItemSubMenuUI);
	
	menuItemSubMenuUI->DebugPrint();
	
	
	CSlrString *str = new CSlrString("<< BACK to Settings");
	menuItemBackSubMenu = new CViewC64MenuItem(fontHeight*2.0f, str,
											   NULL, tr, tg, tb);
	menuItemBackSubMenu->subMenu = viewMenu;
	menuItemSubMenuUI->subMenu->AddMenuItem(menuItemBackSubMenu);
	
	menuItemBackSubMenu->DebugPrint();
	
	//

	
	///
	
	//
	std::vector<CSlrString *> *options = NULL;
	std::vector<CSlrString *> *optionsYesNo = new std::vector<CSlrString *>();
	optionsYesNo->push_back(new CSlrString("No"));
	optionsYesNo->push_back(new CSlrString("Yes"));

	std::vector<CSlrString *> *optionsColors = new std::vector<CSlrString *>();
	optionsColors->push_back(new CSlrString("red"));
	optionsColors->push_back(new CSlrString("green"));
	optionsColors->push_back(new CSlrString("blue"));
	optionsColors->push_back(new CSlrString("black"));
	optionsColors->push_back(new CSlrString("dark gray"));
	optionsColors->push_back(new CSlrString("light gray"));
	optionsColors->push_back(new CSlrString("white"));
	optionsColors->push_back(new CSlrString("yellow"));
	optionsColors->push_back(new CSlrString("cyan"));
	optionsColors->push_back(new CSlrString("magenta"));

	
	//
	kbsDetachEverything = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Detach Everything", 'd', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDetachEverything);
	menuItemDetachEverything = new CViewC64MenuItem(fontHeight, new CSlrString("Detach everything"),
													kbsDetachEverything, tr, tg, tb);
	menuItemSubMenuEmulation->AddMenuItem(menuItemDetachEverything);
	
	kbsDetachDiskImage = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Detach Disk Image", '8', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDetachDiskImage);
	menuItemDetachDiskImage = new CViewC64MenuItem(fontHeight, new CSlrString("Detach Disk Image"),
													kbsDetachDiskImage, tr, tg, tb);
	menuItemSubMenuEmulation->AddMenuItem(menuItemDetachDiskImage);

	kbsDetachCartridge = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Detach Cartridge", '0', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDetachCartridge);
	menuItemDetachCartridge = new CViewC64MenuItem(fontHeight*2, new CSlrString("Detach Cartridge"),
												   kbsDetachCartridge, tr, tg, tb);
	menuItemSubMenuEmulation->AddMenuItem(menuItemDetachCartridge);
	
	
	//
	
	c64ModelTypeIds = new std::vector<int>();
	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetC64ModelTypes(options, c64ModelTypeIds);
	
	menuItemC64Model = new CViewC64MenuItemOption(fontHeight, new CSlrString("Machine model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	menuItemC64Model->SetSelectedOption(c64SettingsC64Model, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemC64Model);

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
	menuItemSubMenuEmulation->AddMenuItem(menuItemMaximumSpeed);
	
	//
	

	//
	options = new std::vector<CSlrString *>();
	viewC64->debugInterface->GetSidTypes(options);
	menuItemSIDModel = new CViewC64MenuItemOption(fontHeight, new CSlrString("SID model: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	menuItemSIDModel->SetSelectedOption(c64SettingsSIDEngineModel, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemSIDModel);
	
	//
	menuItemAudioOutDevice = new CViewC64MenuItemOption(fontHeight, new CSlrString("Audio Out device: "),
														NULL, tr, tg, tb, NULL, font, fontScale);
	menuItemSubMenuAudio->AddMenuItem(menuItemAudioOutDevice);
	
	//
	menuItemAudioVolume = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Audio volume: "),
																	NULL, tr, tg, tb,
																	0.0f, 100.0f, 1.0f, font, fontScale);
	menuItemAudioVolume->numDecimalsDigits = 0;
	menuItemAudioVolume->SetValue(100.0f, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemAudioVolume);
	
	//
	menuItemMuteSIDOnPause = new CViewC64MenuItemOption(fontHeight, new CSlrString("Mute SID on pause: "),
														NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemMuteSIDOnPause->SetSelectedOption(c64SettingsMuteSIDOnPause ? 1 : 0, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemMuteSIDOnPause);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Zero volume"));
	options->push_back(new CSlrString("Stop SID emulation"));

	menuItemMuteSIDMode = new CViewC64MenuItemOption(fontHeight, new CSlrString("Mute SID mode: "),
														NULL, tr, tg, tb, options, font, fontScale);
	menuItemMuteSIDMode->SetSelectedOption(c64SettingsMuteSIDMode, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemMuteSIDMode);

	//
	menuItemRunSIDEmulation = new CViewC64MenuItemOption(fontHeight, new CSlrString("Run SID emulation: "),
											NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemRunSIDEmulation->SetSelectedOption(c64SettingsRunSIDEmulation ? 1 : 0, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRunSIDEmulation);
	
	//
	
	menuItemRunSIDWhenInWarp = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Run SID emulation in warp: "),
														NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemRunSIDWhenInWarp->SetSelectedOption(c64SettingsRunSIDWhenInWarp ? 1 : 0, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRunSIDWhenInWarp);

	//
	// samplingMethod: Fast=0, Interpolating=1, Resampling=2, Fast Resampling=3
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Fast"));
	options->push_back(new CSlrString("Interpolating"));
	options->push_back(new CSlrString("Resampling"));
	options->push_back(new CSlrString("Fast Resampling"));

	menuItemRESIDSamplingMethod = new CViewC64MenuItemOption(fontHeight, new CSlrString("RESID Sampling method: "),
															 NULL, tr, tg, tb, options, font, fontScale);
	menuItemRESIDSamplingMethod->SetSelectedOption(c64SettingsRESIDSamplingMethod, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRESIDSamplingMethod);

	menuItemRESIDEmulateFilters = new CViewC64MenuItemOption(fontHeight, new CSlrString("RESID Emulate filters: "),
															 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemRESIDEmulateFilters->SetSelectedOption((c64SettingsRESIDEmulateFilters == 1 ? true : false), false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRESIDEmulateFilters);

	//
	menuItemRESIDPassBand = new CViewC64MenuItemFloat(fontHeight, new CSlrString("RESID Pass Band: "),
																	NULL, tr, tg, tb,
																	0.00f, 90.0f, 1.00f, font, fontScale);
	menuItemRESIDPassBand->SetValue(c64SettingsRESIDPassBand, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRESIDPassBand);

	menuItemRESIDFilterBias = new CViewC64MenuItemFloat(fontHeight*2, new CSlrString("RESID Filter Bias: "),
																	NULL, tr, tg, tb,
																	-500.0f, 500.0f, 1.00f, font, fontScale);
	menuItemRESIDFilterBias->SetValue(c64SettingsRESIDFilterBias, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemRESIDFilterBias);

	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("None"));
	options->push_back(new CSlrString("One"));
	options->push_back(new CSlrString("Two"));
	menuItemSIDStereo = new CViewC64MenuItemOption(fontHeight, new CSlrString("SID stereo: "),
												  NULL, tr, tg, tb, options, font, fontScale);
	menuItemSIDStereo->SetSelectedOption(c64SettingsSIDStereo, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemSIDStereo);

	options = GetSidAddressOptions();
	
	menuItemSIDStereoAddress = new CViewC64MenuItemOption(fontHeight, new CSlrString("SID #1 address: "),
												   NULL, tr, tg, tb, options, font, fontScale);
	int optNum = GetOptionNumFromSidAddress(c64SettingsSIDStereoAddress);
	menuItemSIDStereoAddress->SetSelectedOption(optNum, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemSIDStereoAddress);

	menuItemSIDTripleAddress = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("SID #2 address: "),
														  NULL, tr, tg, tb, options, font, fontScale);
	optNum = GetOptionNumFromSidAddress(c64SettingsSIDTripleAddress);
	menuItemSIDTripleAddress->SetSelectedOption(optNum, false);
	menuItemSubMenuAudio->AddMenuItem(menuItemSIDTripleAddress);
	


	//
	kbsSwitchSoundOnOff = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Switch sound mute On/Off", 't', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsSwitchSoundOnOff);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("RGB"));
	options->push_back(new CSlrString("Gray"));
	options->push_back(new CSlrString("None"));
	
	menuItemMemoryCellsColorStyle = new CViewC64MenuItemOption(fontHeight, new CSlrString("Memory map values color: "),
														NULL, tr, tg, tb, options, font, fontScale);
	menuItemMemoryCellsColorStyle->SetSelectedOption(c64SettingsMemoryValuesStyle, false);
	menuItemSubMenuMemory->AddMenuItem(menuItemMemoryCellsColorStyle);
	
	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Default"));
	options->push_back(new CSlrString("ICU"));
	
	menuItemMemoryMarkersColorStyle = new CViewC64MenuItemOption(fontHeight, new CSlrString("Memory map markers color: "),
															   NULL, tr, tg, tb, options, font, fontScale);
	menuItemMemoryMarkersColorStyle->SetSelectedOption(c64SettingsMemoryMarkersStyle, false);
	menuItemSubMenuMemory->AddMenuItem(menuItemMemoryMarkersColorStyle);
	
	//
//	options = new std::vector<CSlrString *>();
//	options->push_back(new CSlrString("No"));
//	options->push_back(new CSlrString("Yes"));
	
	menuItemMemoryMapInvert = new CViewC64MenuItemOption(fontHeight, new CSlrString("Invert memory map zoom: "),
																 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemMemoryMapInvert->SetSelectedOption(c64SettingsMemoryMapInvertControl, false);
	menuItemSubMenuMemory->AddMenuItem(menuItemMemoryMapInvert);

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
	menuItemSubMenuMemory->AddMenuItem(menuItemMemoryMapFadeSpeed);

	
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
	menuItemSubMenuMemory->AddMenuItem(menuItemMemoryMapRefreshRate);
	
	//
#if defined(MACOS)
//	options = new std::vector<CSlrString *>();
//	options->push_back(new CSlrString("No"));
//	options->push_back(new CSlrString("Yes"));
	
	menuItemMultiTouchMemoryMap = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Multi-touch map control: "),
														NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemMultiTouchMemoryMap->SetSelectedOption(c64SettingsUseMultiTouchInMemoryMap, false);
	menuItemSubMenuMemory->AddMenuItem(menuItemMultiTouchMemoryMap);
#endif
	

	//
	menuItemWindowAlwaysOnTop = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Window always on top: "),
																 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemWindowAlwaysOnTop->SetSelectedOption(c64SettingsWindowAlwaysOnTop, false);
	menuItemSubMenuUI->AddMenuItem(menuItemWindowAlwaysOnTop);
	

	menuItemScreenRasterViewfinderScale = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Screen viewfinder scale: "),
																	NULL, tr, tg, tb,
																	0.05f, 25.0f, 0.05f, font, fontScale);
	menuItemScreenRasterViewfinderScale->SetValue(1.5f, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterViewfinderScale);

	
	menuItemScreenGridLinesAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Screen grid lines alpha: "),
															 NULL, tr, tg, tb,
															 0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenGridLinesAlpha->SetValue(0.35f, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenGridLinesAlpha);

///////
	
	menuItemScreenGridLinesColorScheme = new CViewC64MenuItemOption(fontHeight*2.0f, new CSlrString("Grid lines: "),
																			  NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemScreenGridLinesColorScheme->SetSelectedOption(0, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenGridLinesColorScheme);

	menuItemScreenRasterCrossLinesAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Raster cross lines alpha: "),
																	NULL, tr, tg, tb,
																	0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenRasterCrossLinesAlpha->SetValue(0.35f, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossLinesAlpha);
	
	menuItemScreenRasterCrossLinesColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Raster cross lines: "),
																		   NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemScreenRasterCrossLinesColorScheme->SetSelectedOption(6, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossLinesColorScheme);
	
	
	menuItemScreenRasterCrossAlpha = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Raster cross alpha: "),
															   NULL, tr, tg, tb,
															   0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemScreenRasterCrossAlpha->SetValue(0.85f, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossAlpha);
	
	menuItemScreenRasterCrossInteriorColorScheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Raster cross interior: "),
																			  NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemScreenRasterCrossInteriorColorScheme->SetSelectedOption(4, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossInteriorColorScheme);
	
	menuItemScreenRasterCrossExteriorColorScheme = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Raster cross exterior: "),
																			  NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemScreenRasterCrossExteriorColorScheme->SetSelectedOption(0, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossExteriorColorScheme);
	
	menuItemScreenRasterCrossTipColorScheme = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Raster cross tip: "),
																		 NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemScreenRasterCrossTipColorScheme->SetSelectedOption(3, false);
	menuItemSubMenuUI->AddMenuItem(menuItemScreenRasterCrossTipColorScheme);
	
	//
	menuItemVicEditorForceReplaceColor = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Vic Editor always replace color: "),
																	NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemVicEditorForceReplaceColor->SetSelectedOption(c64SettingsVicEditorForceReplaceColor, false);
	menuItemSubMenuUI->AddMenuItem(menuItemVicEditorForceReplaceColor);
	//menuItemSubMenuVicEditor
	

	//
	menuItemDisassemblyExecuteColor = new CViewC64MenuItemOption(fontHeight, new CSlrString("Disassembly execute color: "),
																	NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemDisassemblyExecuteColor->SetSelectedOption(C64D_COLOR_WHITE, false);
	menuItemSubMenuUI->AddMenuItem(menuItemDisassemblyExecuteColor);
	
	menuItemDisassemblyNonExecuteColor = new CViewC64MenuItemOption(fontHeight, new CSlrString("Disassembly non execute color: "),
																	NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemDisassemblyNonExecuteColor->SetSelectedOption(C64D_COLOR_LIGHT_GRAY, false);
	menuItemSubMenuUI->AddMenuItem(menuItemDisassemblyNonExecuteColor);

	menuItemDisassemblyBackgroundColor = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Disassembly background color: "),
																	NULL, tr, tg, tb, optionsColors, font, fontScale);
	menuItemDisassemblyBackgroundColor->SetSelectedOption(C64D_COLOR_BLACK, false);
	menuItemSubMenuUI->AddMenuItem(menuItemDisassemblyBackgroundColor);
	
	//
	options = new std::vector<CSlrString *>();
	C64GetAvailablePalettes(options);
	menuItemVicPalette = new CViewC64MenuItemOption(fontHeight, new CSlrString("VIC palette: "),
													NULL, tr, tg, tb, options, font, fontScale);
	menuItemSubMenuUI->AddMenuItem(menuItemVicPalette);
	
	
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Billinear"));
	options->push_back(new CSlrString("Nearest"));
	
	menuItemRenderScreenNearest = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Screen interpolation: "),
															 NULL, tr, tg, tb, options, font, fontScale);
	menuItemRenderScreenNearest->SetSelectedOption(c64SettingsRenderScreenNearest, false);
	menuItemSubMenuUI->AddMenuItem(menuItemRenderScreenNearest);
	
#if !defined(WIN32)
	menuItemUseSystemDialogs = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Use system dialogs: "),
																 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemUseSystemDialogs->SetSelectedOption(c64SettingsUseSystemFileDialogs, false);
	menuItemSubMenuUI->AddMenuItem(menuItemUseSystemDialogs);
#endif
	
#if defined(WIN32)
	menuItemUseOnlyFirstCPU = new CViewC64MenuItemOption(fontHeight*2, new CSlrString("Use only first CPU: "),
																 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemUseOnlyFirstCPU->SetSelectedOption(c64SettingsUseOnlyFirstCPU, false);
	if (uilib_cpu_is_smp() == 1)
	{
		menuItemSubMenuUI->AddMenuItem(menuItemUseOnlyFirstCPU);
	}
#endif
	
	
	std::vector<CSlrString *> *colorThemeOptions = viewC64->colorsTheme->GetAvailableColorThemes();
	menuItemMenusColorTheme = new CViewC64MenuItemOption(fontHeight, new CSlrString("Menus color theme: "),
														 NULL, tr, tg, tb, colorThemeOptions, font, fontScale);
	menuItemMenusColorTheme->SetSelectedOption(c64SettingsMenusColorTheme, false);
	menuItemSubMenuUI->AddMenuItem(menuItemMenusColorTheme);
	
	//
	menuItemFocusBorderLineWidth = new CViewC64MenuItemFloat(fontHeight*2, new CSlrString("Focus border line width: "),
															 NULL, tr, tg, tb,
															 0.0f, 5.0f, 0.05f, font, fontScale);
	menuItemFocusBorderLineWidth->SetValue(0.7f, false);
	menuItemSubMenuUI->AddMenuItem(menuItemFocusBorderLineWidth);


	//
	menuItemPaintGridShowZoomLevel = new CViewC64MenuItemFloat(fontHeight*2, new CSlrString("Show paint grid from zoom level: "),
															   NULL, tr, tg, tb,
															   1.0f, 50.0f, 0.05f, font, fontScale);
	menuItemPaintGridShowZoomLevel->SetValue(c64SettingsPaintGridShowZoomLevel, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridShowZoomLevel);
	

	menuItemPaintGridCharactersColorR = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid characters Color R: "),
																  NULL, tr, tg, tb,
																  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridCharactersColorR->SetValue(c64SettingsPaintGridCharactersColorR, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridCharactersColorR);
	
	menuItemPaintGridCharactersColorG = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid characters Color G: "),
																  NULL, tr, tg, tb,
																  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridCharactersColorG->SetValue(c64SettingsPaintGridCharactersColorG, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridCharactersColorG);
	
	menuItemPaintGridCharactersColorB = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid characters Color B: "),
																  NULL, tr, tg, tb,
																  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridCharactersColorB->SetValue(c64SettingsPaintGridCharactersColorB, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridCharactersColorB);
	
	menuItemPaintGridCharactersColorA = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid characters Color A: "),
																  NULL, tr, tg, tb,
																  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridCharactersColorA->SetValue(c64SettingsPaintGridCharactersColorA, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridCharactersColorA);
	
	menuItemPaintGridPixelsColorR = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid pixels Color R: "),
															  NULL, tr, tg, tb,
															  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridPixelsColorR->SetValue(c64SettingsPaintGridPixelsColorR, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridPixelsColorR);
	
	menuItemPaintGridPixelsColorG = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid pixels Color G: "),
															  NULL, tr, tg, tb,
															  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridPixelsColorG->SetValue(c64SettingsPaintGridPixelsColorG, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridPixelsColorG);
	
	menuItemPaintGridPixelsColorB = new CViewC64MenuItemFloat(fontHeight, new CSlrString("Paint grid pixels Color B: "),
															  NULL, tr, tg, tb,
															  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridPixelsColorB->SetValue(c64SettingsPaintGridPixelsColorB, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridPixelsColorB);
	
	menuItemPaintGridPixelsColorA = new CViewC64MenuItemFloat(fontHeight*2, new CSlrString("Paint grid pixels Color A: "),
															  NULL, tr, tg, tb,
															  0.0f, 1.0f, 0.05f, font, fontScale);
	menuItemPaintGridPixelsColorA->SetValue(c64SettingsPaintGridPixelsColorA, false);
	menuItemSubMenuUI->AddMenuItem(menuItemPaintGridPixelsColorA);


	//

	

	//
	// memory mapping can be initialised only on startup
	menuItemMapC64MemoryToFile = new CViewC64MenuItem(fontHeight*3, NULL,
													  NULL, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemMapC64MemoryToFile);
	
	UpdateMapC64MemoryToFileLabels();
	
	///
	kbsDumpC64Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Dump C64 memory", 'u', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpC64Memory);
	
	menuItemDumpC64Memory = new CViewC64MenuItem(fontHeight, new CSlrString("Dump C64 memory"),
													kbsDumpC64Memory, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemDumpC64Memory);
	
	menuItemDumpC64MemoryMarkers = new CViewC64MenuItem(fontHeight, new CSlrString("Dump C64 memory markers"),
														NULL, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemDumpC64MemoryMarkers);
	
	kbsDumpDrive1541Memory = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Dump Drive 1541 memory", 'u', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsDumpDrive1541Memory);
	
	menuItemDumpDrive1541Memory = new CViewC64MenuItem(fontHeight, new CSlrString("Dump Disk 1541 memory"),
													   kbsDumpDrive1541Memory, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemDumpDrive1541Memory);
	
	menuItemDumpDrive1541MemoryMarkers = new CViewC64MenuItem(fontHeight*2, new CSlrString("Dump Disk 1541 memory markers"),
															  NULL, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemDumpDrive1541MemoryMarkers);

	//

	kbsClearMemoryMarkers = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Clear Memory markers", MTKEY_BACKSPACE, false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsClearMemoryMarkers);
	menuItemClearMemoryMarkers = new CViewC64MenuItem(fontHeight*2, new CSlrString("Clear Memory markers"),
															  kbsClearMemoryMarkers, tr, tg, tb);
	menuItemSubMenuMemory->AddMenuItem(menuItemClearMemoryMarkers);

	
	//
//	options = new std::vector<CSlrString *>();
//	options->push_back(new CSlrString("No"));
//	options->push_back(new CSlrString("Yes"));

	kbsUseKeboardAsJoystick = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Use keyboard as joystick", 'y', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsUseKeboardAsJoystick);
	menuItemUseKeyboardAsJoystick = new CViewC64MenuItemOption(fontHeight, new CSlrString("Use keyboard as joystick: "),
															   kbsUseKeboardAsJoystick, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemSubMenuEmulation->AddMenuItem(menuItemUseKeyboardAsJoystick);
	///
	
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("both"));
	options->push_back(new CSlrString("1"));
	options->push_back(new CSlrString("2"));
	menuItemJoystickPort = new CViewC64MenuItemOption(fontHeight, new CSlrString("Joystick port: "),
													  NULL, tr, tg, tb, options, font, fontScale);
	menuItemSubMenuEmulation->AddMenuItem(menuItemJoystickPort);
	
	//
	
	kbsIsWarpSpeed = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Warp speed", 'p', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsIsWarpSpeed);
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("Off"));
	options->push_back(new CSlrString("On"));
	menuItemIsWarpSpeed = new CViewC64MenuItemOption(fontHeight, new CSlrString("Warp Speed: "), kbsIsWarpSpeed, tr, tg, tb, options, font, fontScale);
	menuItemSubMenuEmulation->AddMenuItem(menuItemIsWarpSpeed);
	

	kbsCartridgeFreezeButton = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Cartridge freeze", 'f', false, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsCartridgeFreezeButton);
	menuItemCartridgeFreeze = new CViewC64MenuItem(fontHeight*2.0f, new CSlrString("Cartridge freeze"),
												   kbsCartridgeFreezeButton, tr, tg, tb);
	menuItemSubMenuEmulation->AddMenuItem(menuItemCartridgeFreeze);

	//
	
	//
	//
	menuItemAutoJmp = new CViewC64MenuItemOption(fontHeight, new CSlrString("Auto JMP: "),
												 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemAutoJmp->SetSelectedOption(c64SettingsAutoJmp, false);
	//menuItemSubMenuEmulation->AddMenuItem(menuItemAutoJmp);
	
	menuItemAutoJmpAlwaysToLoadedPRGAddress = new CViewC64MenuItemOption(fontHeight, new CSlrString("Always JMP to loaded addr: "),
																		 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemAutoJmpAlwaysToLoadedPRGAddress->SetSelectedOption(c64SettingsAutoJmpAlwaysToLoadedPRGAddress, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemAutoJmpAlwaysToLoadedPRGAddress);
	
	
	kbsAutoJmpFromInsertedDiskFirstPrg = new CSlrKeyboardShortcut(KBZONE_GLOBAL, "Auto load first PRG from D64", 'a', true, false, true);
	viewC64->keyboardShortcuts->AddShortcut(kbsAutoJmpFromInsertedDiskFirstPrg);

	menuItemAutoJmpFromInsertedDiskFirstPrg = new CViewC64MenuItemOption(fontHeight, new CSlrString("Load first PRG from D64: "),
																		 kbsAutoJmpFromInsertedDiskFirstPrg, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemAutoJmpFromInsertedDiskFirstPrg->SetSelectedOption(c64SettingsAutoJmpFromInsertedDiskFirstPrg, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemAutoJmpFromInsertedDiskFirstPrg);
	
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("No"));
	options->push_back(new CSlrString("Soft"));
	options->push_back(new CSlrString("Hard"));
	menuItemAutoJmpDoReset = new CViewC64MenuItemOption(fontHeight, new CSlrString("Reset C64 before PRG load: "),
													  NULL, tr, tg, tb, options, font, fontScale);
	menuItemAutoJmpDoReset->SetSelectedOption(c64SettingsAutoJmpDoReset, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemAutoJmpDoReset);

	menuItemAutoJmpWaitAfterReset = new CViewC64MenuItemFloat(fontHeight * 2.0f, new CSlrString("Wait after Reset: "),
																  NULL, tr, tg, tb,
																  0.0f, 5000.0f, 10.00f, font, fontScale);
	menuItemAutoJmpWaitAfterReset->SetValue(c64SettingsAutoJmpWaitAfterReset, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemAutoJmpWaitAfterReset);


	///
//	options = new std::vector<CSlrString *>();
//	options->push_back(new CSlrString("No"));
//	options->push_back(new CSlrString("Yes"));
	
	menuItemFastBootKernalPatch = new CViewC64MenuItemOption(fontHeight, new CSlrString("Fast boot kernal patch: "),
															 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemFastBootKernalPatch->SetSelectedOption(c64SettingsFastBootKernalPatch, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemFastBootKernalPatch);

	menuItemDisassembleExecuteAware = new CViewC64MenuItemOption(fontHeight, new CSlrString("Execute-aware disassemble: "),
																 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemDisassembleExecuteAware->SetSelectedOption(c64SettingsRenderDisassembleExecuteAware, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemDisassembleExecuteAware);

	menuItemEmulateVSPBug = new CViewC64MenuItemOption(fontHeight, new CSlrString("Emulate VSP bug: "),
															 NULL, tr, tg, tb, optionsYesNo, font, fontScale);
	menuItemEmulateVSPBug->SetSelectedOption(c64SettingsEmulateVSPBug, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemEmulateVSPBug);
	

	//
	options = new std::vector<CSlrString *>();
	options->push_back(new CSlrString("None"));
	options->push_back(new CSlrString("Each raster line"));
	options->push_back(new CSlrString("Each VIC cycle"));
	menuItemVicStateRecordingMode = new CViewC64MenuItemOption(fontHeight, new CSlrString("VIC Display recording: "),
															   NULL, tr, tg, tb, options, font, fontScale);
	menuItemVicStateRecordingMode->SetSelectedOption(c64SettingsVicStateRecordingMode, false);
	menuItemSubMenuEmulation->AddMenuItem(menuItemVicStateRecordingMode);
	
	
	//
	menuItemStartJukeboxPlaylist = new CViewC64MenuItem(fontHeight*2, new CSlrString("Start JukeBox playlist"),
														NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemStartJukeboxPlaylist);
	
	menuItemSetC64KeyboardMapping = new CViewC64MenuItem(fontHeight, new CSlrString("Set C64 keyboard mapping"),
														 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemSetC64KeyboardMapping);
	
	menuItemSetKeyboardShortcuts = new CViewC64MenuItem(fontHeight*2, new CSlrString("Set keyboard shortcuts"),
														NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemSetKeyboardShortcuts);
	
	


	float d = 1.25f;//0.75f;
	menuItemClearSettings = new CViewC64MenuItem(fontHeight*d, new CSlrString("Clear settings to factory defaults"),
															 NULL, tr, tg, tb);
	viewMenu->AddMenuItem(menuItemClearSettings);

}

void CViewSettingsMenu::ToggleAutoLoadFromInsertedDisk()
{
	if (c64SettingsAutoJmpFromInsertedDiskFirstPrg)
	{
		menuItemAutoJmpFromInsertedDiskFirstPrg->SetSelectedOption(0, true);
		guiMain->ShowMessage("Auto load from disk is OFF");
	}
	else
	{
		menuItemAutoJmpFromInsertedDiskFirstPrg->SetSelectedOption(1, true);
		guiMain->ShowMessage("Auto load from disk is ON");
	}
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
	else if (menuItem == menuItemVicPalette)
	{
		C64DebuggerSetSetting("VicPalette", &(menuItemVicPalette->selectedOption));
	}
	else if (menuItem == menuItemRenderScreenNearest)
	{
		bool v = menuItemRenderScreenNearest->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("RenderScreenNearest", &(v));
	}
	else if (menuItem == menuItemSIDModel)
	{
		C64DebuggerSetSetting("SIDEngineModel", &(menuItemSIDModel->selectedOption));
	}
	else if (menuItem == menuItemRESIDSamplingMethod)
	{
		C64DebuggerSetSetting("RESIDSamplingMethod", &(menuItemRESIDSamplingMethod->selectedOption));
	}
	else if (menuItem == menuItemRESIDEmulateFilters)
	{
		C64DebuggerSetSetting("RESIDEmulateFilters", &(menuItemRESIDEmulateFilters->selectedOption));
	}
	else if (menuItem == menuItemRESIDPassBand)
	{
		i32 v = (i32)(menuItemRESIDPassBand->value);
		C64DebuggerSetSetting("RESIDPassBand", &v);
	}
	else if (menuItem == menuItemRESIDFilterBias)
	{
		i32 v = (i32)(menuItemRESIDFilterBias->value);
		C64DebuggerSetSetting("RESIDFilterBias", &v);
	}
	else if (menuItem == menuItemSIDStereo)
	{
		C64DebuggerSetSetting("SIDStereo", &(menuItemSIDStereo->selectedOption));
	}
	else if (menuItem == menuItemSIDStereoAddress)
	{
		uint16 addr = GetSidAddressFromOptionNum(menuItemSIDStereoAddress->selectedOption);
		C64DebuggerSetSetting("SIDStereoAddress", &addr);
	}
	else if (menuItem == menuItemSIDTripleAddress)
	{
		uint16 addr = GetSidAddressFromOptionNum(menuItemSIDTripleAddress->selectedOption);
		C64DebuggerSetSetting("SIDTripleAddress", &addr);
	}
	else if (menuItem == menuItemMuteSIDOnPause)
	{
		bool v = menuItemMuteSIDOnPause->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("MuteSIDOnPause", &(v));
	}
	else if (menuItem == menuItemRunSIDWhenInWarp)
	{
		bool v = menuItemRunSIDWhenInWarp->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("RunSIDWhenWarp", &(v));
	}
	else if (menuItem == menuItemAudioVolume)
	{
		float v = menuItemAudioVolume->value;
		u16 vu16 = ((u16)v);
		C64DebuggerSetSetting("AudioVolume", &(vu16));
	}
	else if (menuItem == menuItemRunSIDEmulation)
	{
		bool v = menuItemRunSIDEmulation->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("RunSIDEmulation", &(v));
	}
	else if (menuItem == menuItemMuteSIDMode)
	{
		int v = menuItemMuteSIDMode->selectedOption;
		C64DebuggerSetSetting("MuteSIDMode", &(v));
	}
	else if (menuItem == menuItemFastBootKernalPatch)
	{
		bool v = menuItemFastBootKernalPatch->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("FastBootPatch", &(v));
		
		viewC64->debugInterface->SetPatchKernalFastBoot(v);
	}
	else if (menuItem == menuItemEmulateVSPBug)
	{
		bool v = menuItemEmulateVSPBug->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("EmulateVSPBug", &(v));
	}
	
	else if (menuItem == menuItemAutoJmp)
	{
		bool v = menuItemAutoJmp->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("AutoJmp", &(v));
	}
	else if (menuItem == menuItemAutoJmpAlwaysToLoadedPRGAddress)
	{
		bool v = menuItemAutoJmpAlwaysToLoadedPRGAddress->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("AutoJmpAlwaysToLoadedPRGAddress", &(v));
	}
	else if (menuItem == menuItemAutoJmpFromInsertedDiskFirstPrg)
	{
		bool v = menuItemAutoJmpFromInsertedDiskFirstPrg->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("AutoJmpFromInsertedDiskFirstPrg", &(v));
	}
	else if (menuItem == menuItemAutoJmpDoReset)
	{
		C64DebuggerSetSetting("AutoJmpDoReset", &(menuItemAutoJmpDoReset->selectedOption));
	}
	else if (menuItem == menuItemAutoJmpWaitAfterReset)
	{
		int v = menuItemAutoJmpWaitAfterReset->value;
		C64DebuggerSetSetting("AutoJmpWaitAfterReset", &v);
	}
	else if (menuItem == menuItemDisassembleExecuteAware)
	{
		bool v = menuItemDisassembleExecuteAware->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("DisassembleExecuteAware", &(v));
	}
	else if (menuItem == menuItemDisassemblyBackgroundColor)
	{
		int v = menuItemDisassemblyBackgroundColor->selectedOption;
		C64DebuggerSetSetting("DisassemblyBackgroundColor", &v);
	}
	else if (menuItem == menuItemDisassemblyExecuteColor)
	{
		int v = menuItemDisassemblyExecuteColor->selectedOption;
		C64DebuggerSetSetting("DisassemblyExecuteColor", &v);
	}
	else if (menuItem == menuItemDisassemblyNonExecuteColor)
	{
		int v = menuItemDisassemblyNonExecuteColor->selectedOption;
		C64DebuggerSetSetting("DisassemblyNonExecuteColor", &v);
	}
	else if (menuItem == menuItemMenusColorTheme)
	{
		int v = menuItemMenusColorTheme->selectedOption;
		C64DebuggerSetSetting("MenusColorTheme", &v);
	}
	else if (menuItem == menuItemWindowAlwaysOnTop)
	{
		bool v = menuItemWindowAlwaysOnTop->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("WindowAlwaysOnTop", &(v));
	}
	else if (menuItem == menuItemUseSystemDialogs)
	{
		bool v = menuItemUseSystemDialogs->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("UseSystemDialogs", &(v));
	}
	else if (menuItem == menuItemUseOnlyFirstCPU)
	{
		bool v = menuItemUseOnlyFirstCPU->selectedOption == 0 ? false : true;
		C64DebuggerSetSetting("UseOnlyFirstCPU", &(v));
		guiMain->ShowMessage("Please restart C64 Debugger to apply configuration.");
	}
	else if (menuItem == menuItemVicStateRecordingMode)
	{
		int sel = menuItemVicStateRecordingMode->selectedOption;
		C64DebuggerSetSetting("VicStateRecording", &sel);
	}
	else if (menuItem == menuItemAudioOutDevice)
	{
		CSlrString *deviceName = (*menuItemAudioOutDevice->options)[menuItemAudioOutDevice->selectedOption];
		C64DebuggerSetSetting("AudioOutDevice", deviceName);
	}
	else if (menuItem == menuItemC64Model)
	{
		int modelId = (*c64ModelTypeIds)[menuItemC64Model->selectedOption];
		C64DebuggerSetSetting("C64Model", &(modelId));
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
	else if (menuItem == menuItemFocusBorderLineWidth)
	{
		float v = menuItemFocusBorderLineWidth->value;
		C64DebuggerSetSetting("FocusBorderWidth", &v);
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
	else if (menuItem == menuItemPaintGridShowZoomLevel)
	{
		float v = menuItemPaintGridShowZoomLevel->value;
		C64DebuggerSetSetting("PaintGridShowZoomLevel", &v);
	}
	
	else if (menuItem == menuItemPaintGridCharactersColorR)
	{
		float v = menuItemPaintGridCharactersColorR->value;
		C64DebuggerSetSetting("PaintGridCharactersColorR", &v);
	}
	else if (menuItem == menuItemPaintGridCharactersColorG)
	{
		float v = menuItemPaintGridCharactersColorG->value;
		C64DebuggerSetSetting("PaintGridCharactersColorG", &v);
	}
	else if (menuItem == menuItemPaintGridCharactersColorB)
	{
		float v = menuItemPaintGridCharactersColorB->value;
		C64DebuggerSetSetting("PaintGridCharactersColorB", &v);
	}
	else if (menuItem == menuItemPaintGridCharactersColorA)
	{
		float v = menuItemPaintGridCharactersColorA->value;
		C64DebuggerSetSetting("PaintGridCharactersColorA", &v);
	}
	
	else if (menuItem == menuItemPaintGridPixelsColorR)
	{
		float v = menuItemPaintGridPixelsColorR->value;
		C64DebuggerSetSetting("PaintGridPixelsColorR", &v);
	}
	else if (menuItem == menuItemPaintGridPixelsColorG)
	{
		float v = menuItemPaintGridPixelsColorG->value;
		C64DebuggerSetSetting("PaintGridPixelsColorG", &v);
	}
	else if (menuItem == menuItemPaintGridPixelsColorB)
	{
		float v = menuItemPaintGridPixelsColorB->value;
		C64DebuggerSetSetting("PaintGridPixelsColorB", &v);
	}
	else if (menuItem == menuItemPaintGridPixelsColorA)
	{
		float v = menuItemPaintGridPixelsColorA->value;
		C64DebuggerSetSetting("PaintGridPixelsColorA", &v);
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

void CViewSettingsMenu::DetachEverything()
{
	void DetachEverything();
	
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

void CViewSettingsMenu::DetachDiskImage()
{
	// detach drive
	viewC64->debugInterface->DetachDriveDisk();
	
	guiMain->LockMutex();
	
	if (viewC64->viewC64MainMenu->menuItemInsertD64->str2 != NULL)
		delete viewC64->viewC64MainMenu->menuItemInsertD64->str2;
	viewC64->viewC64MainMenu->menuItemInsertD64->str2 = NULL;
	
	delete c64SettingsPathToD64;
	c64SettingsPathToD64 = NULL;
	
	guiMain->UnlockMutex();
	
	C64DebuggerStoreSettings();
	
	guiMain->ShowMessage("Detached drive image");
}

void CViewSettingsMenu::DetachCartridge(bool showMessage)
{
	// detach cartridge
	viewC64->debugInterface->DetachCartridge();
	
	guiMain->LockMutex();
	
	if (viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 != NULL)
		delete viewC64->viewC64MainMenu->menuItemInsertCartridge->str2;
	viewC64->viewC64MainMenu->menuItemInsertCartridge->str2 = NULL;
	
	delete c64SettingsPathToCartridge;
	c64SettingsPathToCartridge = NULL;
	
	guiMain->UnlockMutex();
	
	C64DebuggerStoreSettings();
	
	if (showMessage)
	{
		guiMain->ShowMessage("Detached cartridge");
	}
}

void CViewSettingsMenu::MenuCallbackItemEntered(CGuiViewMenuItem *menuItem)
{
	if (menuItem == menuItemDetachEverything)
	{
		DetachEverything();
	}
	if (menuItem == menuItemDetachDiskImage)
	{
		DetachDiskImage();
	}
	if (menuItem == menuItemDetachCartridge)
	{
		DetachCartridge(true);
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
	else if (menuItem == menuItemStartJukeboxPlaylist)
	{
		viewC64->viewC64MainMenu->OpenDialogStartJukeboxPlaylist();
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
	viewC64->ShowDialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpC64MemoryMarkers()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_C64_MEMORY_MARKERS;
	
	CSlrString *defaultFileName = new CSlrString("c64markers");
	
	CSlrString *windowTitle = new CSlrString("Dump C64 memory markers");
	viewC64->ShowDialogSaveFile(this, &csvExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpDrive1541Memory()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY;
	
	CSlrString *defaultFileName = new CSlrString("1541memory");
	
	CSlrString *windowTitle = new CSlrString("Dump Disk 1541 memory");
	viewC64->ShowDialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}

void CViewSettingsMenu::OpenDialogDumpDrive1541MemoryMarkers()
{
	openDialogFunction = VIEWC64SETTINGS_DUMP_DRIVE1541_MEMORY_MARKERS;
	
	CSlrString *defaultFileName = new CSlrString("1541markers");
	
	CSlrString *windowTitle = new CSlrString("Dump Disk 1541 memory markers");
	viewC64->ShowDialogSaveFile(this, &csvExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
	delete windowTitle;
	delete defaultFileName;
}


void CViewSettingsMenu::OpenDialogMapC64MemoryToFile()
{
	openDialogFunction = VIEWC64SETTINGS_MAP_C64_MEMORY_TO_FILE;
	
	CSlrString *defaultFileName = new CSlrString("c64memory");
	
	CSlrString *windowTitle = new CSlrString("Map C64 memory to file");
	viewC64->ShowDialogSaveFile(this, &memoryExtensions, defaultFileName, c64SettingsDefaultMemoryDumpFolder, windowTitle);
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

	BlitFilledRectangle(0, 0, -1, sizeX, sizeY,
						viewC64->colorsTheme->colorBackgroundFrameR,
						viewC64->colorsTheme->colorBackgroundFrameG,
						viewC64->colorsTheme->colorBackgroundFrameB, 1.0);
		
	float sb = 20;
	float gap = 4;
	
	float tr = viewC64->colorsTheme->colorTextR;
	float tg = viewC64->colorsTheme->colorTextG;
	float tb = viewC64->colorsTheme->colorTextB;
	
	float lr = viewC64->colorsTheme->colorHeaderLineR;
	float lg = viewC64->colorsTheme->colorHeaderLineG;
	float lb = viewC64->colorsTheme->colorHeaderLineB;
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
	
	BlitFilledRectangle(scrx, scry, -1, scrsx, scrsy,
						viewC64->colorsTheme->colorBackgroundR,
						viewC64->colorsTheme->colorBackgroundG,
						viewC64->colorsTheme->colorBackgroundB, 1.0);
	
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
	
	if (viewMenu->DoTap(x, y))
		return true;

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

bool CViewSettingsMenu::DoScrollWheel(float deltaX, float deltaY)
{
	return viewMenu->DoScrollWheel(deltaX, deltaY);
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
		viewC64->ShowMainScreen();
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
	
	//
	int modelType = viewC64->debugInterface->GetC64ModelType();
	this->SetOptionC64ModelType(modelType);

	UpdateAudioOutDevices();
}

void CViewSettingsMenu::DeactivateView()
{
	LOGG("CViewSettingsMenu::DeactivateView()");
}

//
void CViewSettingsMenu::SetOptionC64ModelType(int modelTypeId)
{
	int menuOptionNum = 0;
	for(std::vector<int>::iterator it = c64ModelTypeIds->begin(); it != c64ModelTypeIds->end(); it++)
	{
		int menuModelId = *it;
		if (menuModelId == modelTypeId)
		{
			this->menuItemC64Model->SetSelectedOption(menuOptionNum, false);
			return;
		}
		
		menuOptionNum++;
	}
	
	LOGError("CViewSettingsMenu::SetOptionC64ModelType: modelTypeId=%d not found", modelTypeId);
}

std::vector<CSlrString *> *CViewSettingsMenu::GetSidAddressOptions()
{
	std::vector<CSlrString *> *opts = new std::vector<CSlrString *>();
	
	char *buf = SYS_GetCharBuf();

	for (uint16 j = 0x0020; j < 0x0100; j += 0x0020)
	{
		uint16 addr = 0xD400 + j;
		sprintf(buf, "$%04X", addr);
		CSlrString *str = new CSlrString(buf);
		opts->push_back(str);
	}

	for (uint16 i = 0xD500; i < 0xD800; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			sprintf(buf, "$%04X", addr);
			CSlrString *str = new CSlrString(buf);
			opts->push_back(str);
		}
	}

	for (uint16 i = 0xDE00; i < 0xE000; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			sprintf(buf, "$%04X", addr);
			CSlrString *str = new CSlrString(buf);
			opts->push_back(str);
		}
	}
	
	SYS_ReleaseCharBuf(buf);
	
	return opts;
}

uint16 CViewSettingsMenu::GetSidAddressFromOptionNum(int optionNum)
{
	int o = 0;
	
	for (uint16 j = 0x0020; j < 0x0100; j += 0x0020)
	{
		uint16 addr = 0xD400 + j;
		
		if (o == optionNum)
			return addr;
		
		o++;
	}
	
	for (uint16 i = 0xD500; i < 0xD800; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			if (o == optionNum)
				return addr;
			
			o++;
		}
	}
	
	for (uint16 i = 0xDE00; i < 0xE000; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			if (o == optionNum)
				return addr;
			
			o++;
		}
	}
	
	LOGError("CViewSettingsMenu::GetSidAddressFromOptionNum: sid address not correct, option num=%d", optionNum);
	return 0xD420;
}

int CViewSettingsMenu::GetOptionNumFromSidAddress(uint16 sidAddress)
{
	int o = 0;
	
	for (uint16 j = 0x0020; j < 0x0100; j += 0x0020)
	{
		uint16 addr = 0xD400 + j;
		if (sidAddress == addr)
			return o;
		
		o++;
	}
	
	for (uint16 i = 0xD500; i < 0xD800; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			if (sidAddress == addr)
				return o;
			
			o++;
		}
	}
	
	for (uint16 i = 0xDE00; i < 0xE000; i += 0x0100)
	{
		for (uint16 j = 0x0000; j < 0x0100; j += 0x0020)
		{
			uint16 addr = i + j;
			if (sidAddress == addr)
				return o;
			
			o++;
		}
	}
	
	LOGError("CViewSettingsMenu::GetSidAddressFromOptionNum: sid address not correct, sidAddress=%04x", sidAddress);
	return 0;
}

void CViewSettingsMenu::UpdateSidSettings()
{
	int optNum = GetOptionNumFromSidAddress(c64SettingsSIDStereoAddress);
	menuItemSIDStereoAddress->SetSelectedOption(optNum, false);

	optNum = GetOptionNumFromSidAddress(c64SettingsSIDTripleAddress);
	menuItemSIDTripleAddress->SetSelectedOption(optNum, false);
	
	viewC64->viewC64StateSID->UpdateSidButtonsState();
	
}


