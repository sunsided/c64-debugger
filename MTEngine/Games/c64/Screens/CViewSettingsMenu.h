#ifndef _VIEW_C64SETTINGSMENU_
#define _VIEW_C64SETTINGSMENU_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;

extern int settingsReuSizes[8];

class CViewSettingsMenu : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback
{
public:
	CViewSettingsMenu(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewSettingsMenu();

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	// multi touch
	virtual bool DoMultiTap(COneTouchData *touch, float x, float y);
	virtual bool DoMultiMove(COneTouchData *touch, float x, float y);
	virtual bool DoMultiFinishTap(COneTouchData *touch, float x, float y);

	virtual void FinishTouches();

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
	
	virtual void ActivateView();
	virtual void DeactivateView();

	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float tr;
	float tg;
	float tb;
	
	CSlrString *strHeader;
	CSlrString *strHeader2;
	CSlrString *strHeader3;
	
	CGuiViewMenu *viewMenu;
	virtual void MenuCallbackItemEntered(CGuiViewMenuItem *menuItem);
	virtual void MenuCallbackItemChanged(CGuiViewMenuItem *menuItem);
	
	CViewC64MenuItem *menuItemSubMenuEmulation;
	CViewC64MenuItem *menuItemSubMenuAudio;
	CViewC64MenuItem *menuItemSubMenuMemory;
	CViewC64MenuItem *menuItemSubMenuTape;
	CViewC64MenuItem *menuItemSubMenuReu;
	CViewC64MenuItem *menuItemSubMenuUI;

	CSlrKeyboardShortcut *kbsDetachEverything;
	CViewC64MenuItem *menuItemDetachEverything;
	void DetachEverything(bool showMessage, bool storeSettings);
	void DetachCartridge(bool showMessage);
	void DetachDiskImage();
	void DetachTape(bool showMessage);

	CSlrKeyboardShortcut *kbsDetachDiskImage;
	CViewC64MenuItem *menuItemDetachDiskImage;
	
	CSlrKeyboardShortcut *kbsDetachCartridge;
	CViewC64MenuItem *menuItemDetachCartridge;
	
	CSlrKeyboardShortcut *kbsIsWarpSpeed;
	CViewC64MenuItemOption *menuItemIsWarpSpeed;
	
	CSlrKeyboardShortcut *kbsUseKeboardAsJoystick;
	CViewC64MenuItemOption *menuItemUseKeyboardAsJoystick;
	CViewC64MenuItemOption *menuItemJoystickPort;
	

	//
	CViewC64MenuItem *menuItemStartJukeboxPlaylist;
	
	CViewC64MenuItem *menuItemSetC64KeyboardMapping;
	CViewC64MenuItem *menuItemSetKeyboardShortcuts;

	CSlrKeyboardShortcut *kbsCartridgeFreezeButton;
	CViewC64MenuItem *menuItemCartridgeFreeze;

	//
	CSlrKeyboardShortcut *kbsResetCpuCycleAndFrameCounters;
	CViewC64MenuItem *menuItemResetCpuCycleAndFrameCounters;
	void ResetMainCpuCycleAndFrameCounters();
	void ResetMainCpuCycleCounter();
	void ResetEmulationFrameCounter();

	CSlrKeyboardShortcut *kbsDumpC64Memory;
	CViewC64MenuItem *menuItemDumpC64Memory;
	CSlrKeyboardShortcut *kbsDumpDrive1541Memory;
	CViewC64MenuItem *menuItemDumpDrive1541Memory;
	CViewC64MenuItem *menuItemDumpC64MemoryMarkers;
	CViewC64MenuItem *menuItemDumpDrive1541MemoryMarkers;

	CSlrKeyboardShortcut *kbsClearMemoryMarkers;
	CViewC64MenuItem *menuItemClearMemoryMarkers;
	void ClearMemoryMarkers();

	CViewC64MenuItem *menuItemMapC64MemoryToFile;
	void UpdateMapC64MemoryToFileLabels();

	CViewC64MenuItemOption *menuItemC64SnapshotsManagerIsActive;
	CViewC64MenuItemFloat *menuItemC64SnapshotsManagerStoreInterval;
	CViewC64MenuItemFloat *menuItemC64SnapshotsManagerLimit;
	CViewC64MenuItemOption *menuItemC64TimelineIsActive;
	
	CViewC64MenuItem *menuItemC64ProfilerFilePath;
	CViewC64MenuItemOption *menuItemC64ProfilerDoVic;
	void UpdateC64ProfilerFilePath();
	CSlrKeyboardShortcut *kbsC64ProfilerStartStop;
	CViewC64MenuItem *menuItemC64ProfilerStartStop;
	void OpenDialogSetC64ProfilerFileOutputPath();
	void SetC64ProfilerOutputFile(CSlrString *path);
	void C64ProfilerStartStop();
	bool isProfilingC64;

	//
	
	CViewC64MenuItemOption *menuItemMemoryCellsColorStyle;
	CViewC64MenuItemOption *menuItemMemoryMarkersColorStyle;
	CViewC64MenuItemOption *menuItemMultiTouchMemoryMap;
	CViewC64MenuItemOption *menuItemMemoryMapInvert;
	CViewC64MenuItemOption *menuItemMemoryMapRefreshRate;
	CViewC64MenuItemOption *menuItemMemoryMapFadeSpeed;
	
	
	//
	CViewC64MenuItemOption *menuItemAutoJmp;
	CSlrKeyboardShortcut *kbsAutoJmpAlwaysToLoadedPRGAddress;
	CViewC64MenuItemOption *menuItemAutoJmpAlwaysToLoadedPRGAddress;
	CSlrKeyboardShortcut *kbsAutoJmpFromInsertedDiskFirstPrg;
	CViewC64MenuItemOption *menuItemAutoJmpFromInsertedDiskFirstPrg;
	CSlrKeyboardShortcut *kbsAutoJmpDoReset;
	CViewC64MenuItemOption *menuItemAutoJmpDoReset;
	CViewC64MenuItemFloat  *menuItemAutoJmpWaitAfterReset;

	// atari
	CViewC64MenuItemOption *menuItemAtariVideoSystem;
	CViewC64MenuItemOption *menuItemAtariMachineType;
	std::vector<CSlrString *> *optionsAtariMachineTypes;
	CViewC64MenuItemOption *menuItemAtariRamSize;
	std::vector<CSlrString *> *optionsAtariRamSize800;
	std::vector<CSlrString *> *optionsAtariRamSizeXL;
	std::vector<CSlrString *> *optionsAtariRamSize5200;
	void UpdateAtariRamSizeOptions();

	void ToggleAutoLoadFromInsertedDisk();
	void ToggleAutoJmpAlwaysToLoadedPRGAddress();
	void ToggleAutoJmpDoReset();
	
	// tape
	CSlrKeyboardShortcut *kbsTapeAttach;
	CViewC64MenuItem *menuItemTapeAttach;
	CSlrKeyboardShortcut *kbsTapeDetach;
	CViewC64MenuItem *menuItemTapeDetach;
	CViewC64MenuItem *menuItemTapeCreate;

	CSlrKeyboardShortcut *kbsTapeStop;
	CViewC64MenuItem *menuItemTapeStop;
	CSlrKeyboardShortcut *kbsTapePlay;
	CViewC64MenuItem *menuItemTapePlay;
	CSlrKeyboardShortcut *kbsTapeForward;
	CViewC64MenuItem *menuItemTapeForward;
	CSlrKeyboardShortcut *kbsTapeRewind;
	CViewC64MenuItem *menuItemTapeRewind;
	CSlrKeyboardShortcut *kbsTapeRecord;
	CViewC64MenuItem *menuItemTapeRecord;
	CViewC64MenuItem *menuItemTapeReset;

	CViewC64MenuItemFloat *menuItemDatasetteSpeedTuning;
	CViewC64MenuItemFloat *menuItemDatasetteZeroGapDelay;
	CViewC64MenuItemFloat *menuItemDatasetteTapeWobble;
	CViewC64MenuItemOption *menuItemDatasetteResetWithCPU;
	
	// REU
	CViewC64MenuItemOption *menuItemReuEnabled;
	CSlrKeyboardShortcut *kbsReuAttach;
	CViewC64MenuItem *menuItemReuAttach;
	CViewC64MenuItem *menuItemReuSave;
	CViewC64MenuItemOption *menuItemReuSize;

	
	//
	CViewC64MenuItemFloat *menuItemScreenGridLinesAlpha;
	CViewC64MenuItemOption *menuItemScreenGridLinesColorScheme;
	CViewC64MenuItemFloat *menuItemScreenRasterViewfinderScale;
	CViewC64MenuItemFloat *menuItemScreenRasterCrossLinesAlpha;
	CViewC64MenuItemOption *menuItemScreenRasterCrossLinesColorScheme;
	CViewC64MenuItemFloat *menuItemScreenRasterCrossAlpha;
	CViewC64MenuItemOption *menuItemScreenRasterCrossInteriorColorScheme;
	CViewC64MenuItemOption *menuItemScreenRasterCrossExteriorColorScheme;
	CViewC64MenuItemOption *menuItemScreenRasterCrossTipColorScheme;
	
	CViewC64MenuItemOption *menuItemMenusColorTheme;
	
	CViewC64MenuItemFloat *menuItemPaintGridCharactersColorR;
	CViewC64MenuItemFloat *menuItemPaintGridCharactersColorG;
	CViewC64MenuItemFloat *menuItemPaintGridCharactersColorB;
	CViewC64MenuItemFloat *menuItemPaintGridCharactersColorA;

	CViewC64MenuItemFloat *menuItemPaintGridPixelsColorR;
	CViewC64MenuItemFloat *menuItemPaintGridPixelsColorG;
	CViewC64MenuItemFloat *menuItemPaintGridPixelsColorB;
	CViewC64MenuItemFloat *menuItemPaintGridPixelsColorA;

	CViewC64MenuItemFloat *menuItemPaintGridShowZoomLevel;

	CViewC64MenuItemOption *menuItemVicEditorForceReplaceColor;

	CViewC64MenuItemOption *menuItemSIDModel;
	CViewC64MenuItemOption *menuItemRESIDEmulateFilters;
	CViewC64MenuItemOption *menuItemRESIDSamplingMethod;
	CViewC64MenuItemFloat *menuItemRESIDPassBand;
	CViewC64MenuItemFloat *menuItemRESIDFilterBias;

	CViewC64MenuItemOption *menuItemSIDStereo;
	CViewC64MenuItemOption *menuItemSIDStereoAddress;
	CViewC64MenuItemOption *menuItemSIDTripleAddress;

	CViewC64MenuItemOption *menuItemMuteSIDOnPause;
	CViewC64MenuItemOption *menuItemRunSIDWhenInWarp;
	CViewC64MenuItemOption *menuItemAudioOutDevice;
	void UpdateAudioOutDevices();

	CViewC64MenuItemOption *menuItemRunSIDEmulation;
	CViewC64MenuItemFloat *menuItemAudioVolume;
	CViewC64MenuItemOption *menuItemMuteSIDMode;
	CViewC64MenuItemOption *menuItemSIDImportMode;
	
	CSlrKeyboardShortcut *kbsSwitchSoundOnOff;  // mojzesh
	
	
	CViewC64MenuItemOption *menuItemC64Model;
	CViewC64MenuItemOption *menuItemFastBootKernalPatch;
	CViewC64MenuItemOption *menuItemEmulateVSPBug;
	
	CViewC64MenuItemFloat *menuItemFocusBorderLineWidth;

	CViewC64MenuItemOption *menuItemDisassembleExecuteAware;
	
	CViewC64MenuItemOption *menuItemDisassemblyBackgroundColor;
	CViewC64MenuItemOption *menuItemDisassemblyExecuteColor;
	CViewC64MenuItemOption *menuItemDisassemblyNonExecuteColor;

	CViewC64MenuItemOption *menuItemVicPalette;
	CViewC64MenuItemOption *menuItemRenderScreenInterpolation;
	CViewC64MenuItemOption *menuItemRenderScreenSupersample;

	
	CViewC64MenuItemOption *menuItemMaximumSpeed;
	CSlrKeyboardShortcut *kbsSwitchNextMaximumSpeed;
	CSlrKeyboardShortcut *kbsSwitchPrevMaximumSpeed;
	void SwitchNextMaximumSpeed();
	void SwitchPrevMaximumSpeed();
	void SetEmulationMaximumSpeed(int maximumSpeed);

	CViewC64MenuItemOption *menuItemWindowAlwaysOnTop;
	CViewC64MenuItemOption *menuItemUseSystemDialogs;
	
	CViewC64MenuItemOption *menuItemUseOnlyFirstCPU;
	
	CViewC64MenuItemOption *menuItemVicStateRecordingMode;
	
	CViewC64MenuItem *menuItemClearSettings;
	
	CViewC64MenuItem *menuItemBack;

	void SwitchMainMenuScreen();
	
	std::list<CSlrString *> memoryExtensions;
	std::list<CSlrString *> csvExtensions;
	std::list<CSlrString *> profilerExtensions;
	
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();

	void OpenDialogDumpC64Memory();
	void OpenDialogDumpC64MemoryMarkers();
	void OpenDialogDumpDrive1541Memory();
	void OpenDialogDumpDrive1541MemoryMarkers();
	void OpenDialogMapC64MemoryToFile();
	
	void DumpC64Memory(CSlrString *path);
	void DumpC64MemoryMarkers(CSlrString *path);
	void DumpDisk1541Memory(CSlrString *path);
	void DumpDisk1541MemoryMarkers(CSlrString *path);
	void MapC64MemoryToFile(CSlrString *path);
	
	byte openDialogFunction;
	
	//
	std::vector<int> *c64ModelTypeIds;
	
	void SetOptionC64ModelType(int modelTypeId);
	
	std::vector<CSlrString *> *GetSidAddressOptions();
	uint16 GetSidAddressFromOptionNum(int optionNum);
	int GetOptionNumFromSidAddress(uint16 sidAddress);
	void UpdateSidSettings();
	
};


#endif //_VIEW_C64SETTINGSMENU_
