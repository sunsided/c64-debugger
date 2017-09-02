/*
 *  C64 Debugger
 *
 *  Created by Marcin Skoczylas on 16-02-22.
 *  Copyright 2016 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_C64_
#define _GUI_C64_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "SYS_Threading.h"
#include "SYS_Defs.h"
#include "SYS_PauseResume.h"
#include "CViewMainMenu.h"
#include "CViewSettingsMenu.h"
#include "SYS_SharedMemory.h"
#include "CGuiViewSaveFile.h"
#include "CGuiViewSelectFile.h"

extern "C"
{
#include "ViceWrapper.h"
};

#include <list>
#include <vector>
#include <map>

class C64KeyboardShortcuts;
class CSlrFontProportional;
class CSlrKeyboardShortcut;
class CSlrKeyboardShortcuts;
class CC64DataAdapter;
class CC64DirectRamDataAdapter;
class CC64DiskDataAdapter;
class CC64DiskDirectRamDataAdapter;
class C64Symbols;

class CViewC64Screen;
class CViewMemoryMap;
class CViewDataDump;
class CViewBreakpoints;
class CViewDisassemble;
class CViewC64StateCIA;
class CViewC64StateSID;
class CViewC64StateVIC;
class CViewC64VicDisplay;
class CViewC64VicControl;
class CViewVicEditor;
class CViewDrive1541State;
class CViewEmulationState;
class CViewMonitorConsole;
class CViewMainMenu;
class CViewSettingsMenu;
class CViewFileD64;
class CViewC64KeyMap;
class CViewKeyboardShortcuts;
class CViewSnapshots;
class CViewAbout;

class C64DebugInterface;


enum c64ScreenLayouts
{
	C64_SCREEN_LAYOUT_C64_ONLY = 0,
	C64_SCREEN_LAYOUT_C64_DATA_DUMP = 1,
	C64_SCREEN_LAYOUT_C64_DEBUGGER = 2,
	C64_SCREEN_LAYOUT_C64_1541_MEMORY_MAP = 3,
	C64_SCREEN_LAYOUT_SHOW_STATES = 4,
	C64_SCREEN_LAYOUT_C64_MEMORY_MAP = 5,
	C64_SCREEN_LAYOUT_C64_1541_DEBUGGER = 6,
	//	C64_SCREEN_LAYOUT_C64_1541_DATA_DUMP,
	C64_SCREEN_LAYOUT_MONITOR_CONSOLE = 7,
	C64_SCREEN_LAYOUT_CYCLER = 8,
	C64_SCREEN_LAYOUT_VIC_DISPLAY = 9,
	C64_SCREEN_LAYOUT_VIC_DISPLAY_LITE = 10,
	C64_SCREEN_LAYOUT_FULL_SCREEN_ZOOM = 11,
	C64_SCREEN_LAYOUT_MAX
};


class C64ScreenLayout
{
public:
	C64ScreenLayout();
	bool isAvailable;
	
	bool c64ScreenVisible;
	float c64ScreenX, c64ScreenY;
	float c64ScreenSizeX, c64ScreenSizeY;
	bool c64ScreenShowGridLines;
	bool c64ScreenShowZoomedScreen;
	float c64ScreenZoomedX, c64ScreenZoomedY;
	float c64ScreenZoomedSizeX, c64ScreenZoomedSizeY;
	
	bool c64StateVisible;
	float c64StateX, c64StateY;
	float c64StateFontSize;
	bool drive1541StateVisible;
	float drive1541StateX, drive1541StateY;
	float drive1541StateFontSize;
	bool c64DisassembleVisible;
	float c64DisassembleX, c64DisassembleY;
	float c64DisassembleSizeX, c64DisassembleSizeY;
	float c64DisassembleFontSize;
	int c64DisassembleNumberOfLines;
	float c64DisassembleCodeMnemonicsOffset;
	bool c64DisassembleShowHexCodes;
	bool c64DisassembleShowCodeCycles;
	float c64DisassembleCodeCyclesOffset;
	bool c64DisassembleShowLabels;
	int c64DisassembleNumberOfLabelCharacters;

	bool drive1541DisassembleVisible;
	float drive1541DisassembleX, drive1541DisassembleY;
	float drive1541DisassembleSizeX, drive1541DisassembleSizeY;
	float drive1541DisassembleFontSize;
	int drive1541DisassembleNumberOfLines;
	float drive1541DisassembleCodeMnemonicsOffset;
	bool drive1541DisassembleShowHexCodes;
	bool drive1541DisassembleShowCodeCycles;
	float drive1541DisassembleCodeCyclesOffset;
	bool drive1541DisassembleShowLabels;
	int drive1541DisassembleNumberOfLabelCharacters;

	bool c64MemoryMapVisible;
	float c64MemoryMapX, c64MemoryMapY;
	float c64MemoryMapSizeX, c64MemoryMapSizeY;
	bool drive1541MemoryMapVisible;
	float drive1541MemoryMapX, drive1541MemoryMapY;
	float drive1541MemoryMapSizeX, drive1541MemoryMapSizeY;
	bool c64DataDumpVisible;
	float c64DataDumpX, c64DataDumpY;
	float c64DataDumpSizeX, c64DataDumpSizeY;
	float c64DataDumpFontSize;
	float c64DataDumpGapAddress;
	float c64DataDumpGapHexData;
	float c64DataDumpGapDataCharacters;
	bool c64DataDumpShowCharacters;
	bool c64DataDumpShowSprites;
	int c64DataDumpNumberOfBytesPerLine;
	bool drive1541DataDumpVisible;
	float drive1541DataDumpX, drive1541DataDumpY;
	float drive1541DataDumpSizeX, drive1541DataDumpSizeY;
	float drive1541DataDumpFontSize;
	float drive1541DataDumpGapAddress;
	float drive1541DataDumpGapHexData;
	float drive1541DataDumpGapDataCharacters;
	bool drive1541DataDumpShowCharacters;
	bool drive1541DataDumpShowSprites;
	int drive1541DataDumpNumberOfBytesPerLine;
	
	bool c64StateCIAVisible;
	float c64StateCIAX, c64StateCIAY;
	float c64StateCIAFontSize;
	bool c64StateCIARenderCIA1;
	bool c64StateCIARenderCIA2;
	bool c64StateSIDVisible;
	float c64StateSIDX, c64StateSIDY;
	float c64StateSIDFontSize;
	bool c64StateVICVisible;
	float c64StateVICX, c64StateVICY;
	float c64StateVICFontSize;
	bool c64StateVICIsVertical;
	bool c64StateVICShowSprites;
	
	bool c64StateDrive1541Visible;
	float c64StateDrive1541X, c64StateDrive1541Y;
	float c64StateDrive1541FontSize;
	bool c64StateDrive1541RenderVIA1;
	bool c64StateDrive1541RenderVIA2;
	bool c64StateDrive1541RenderDriveLED;
	bool c64StateDrive1541IsVertical;
	
	bool c64VicDisplayVisible;
	float c64VicDisplayX, c64VicDisplayY;
	float c64VicDisplayScale;
	bool c64VicDisplayCanScrollDisassemble;
	
	bool c64VicControlVisible;
	float c64VicControlX, c64VicControlY;
	float c64VicControlFontSize;
	
	bool monitorConsoleVisible;
	float monitorConsoleX, monitorConsoleY;
	float monitorConsoleSizeX, monitorConsoleSizeY;
	float monitorConsoleFontScale;
	int monitorConsoleNumLines;
	
	bool emulationStateVisible;
	float emulationStateX, emulationStateY;
	
	bool debugOnC64;
	bool debugOnDrive1541;
};

class CViewC64 : public CGuiView, CGuiButtonCallback, CSlrThread, CApplicationPauseResumeListener,
				 public CSharedMemorySignalCallback, public CGuiViewSelectFileCallback, public CGuiViewSaveFileCallback
{
public:
	CViewC64(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewC64();

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
	
	virtual bool DoScrollWheel(float deltaX, float deltaY);
	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	virtual void ActivateView();
	virtual void DeactivateView();

	
	C64DebugInterface *debugInterface;
	
	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);


	CViewMainMenu *viewC64MainMenu;
	CViewSettingsMenu *viewC64SettingsMenu;
	CViewFileD64 *viewFileD64;
	CViewC64KeyMap *viewC64KeyMap;
	CViewKeyboardShortcuts *viewKeyboardShortcuts;
	CViewBreakpoints *viewC64Breakpoints;
	CViewSnapshots *viewC64Snapshots;
	CViewAbout *viewAbout;

	int currentScreenLayoutId;
	
	CSlrFont *fontDisassemble;
	
	CViewC64Screen *viewC64Screen;
	
	CViewMemoryMap *viewC64MemoryMap;
	CViewMemoryMap *viewDrive1541MemoryMap;
	
	CViewDataDump *viewC64MemoryDataDump;
	CViewDataDump *viewDrive1541MemoryDataDump;
	
	CViewDisassemble *viewC64Disassemble;
	CViewDisassemble *viewDrive1541Disassemble;
	
	CViewC64StateCIA *viewC64StateCIA;
	CViewC64StateSID *viewC64StateSID;
	CViewC64StateVIC *viewC64StateVIC;
	CViewDrive1541State *viewC64StateDrive1541;
	
	CViewEmulationState *viewEmulationState;
	
	CViewC64VicDisplay *viewC64VicDisplay;
	CViewC64VicControl *viewC64VicControl;

	CViewMonitorConsole *viewMonitorConsole;
	
	// VIC Editor
	CViewVicEditor *viewVicEditor;
	
	// updated every render frame
	vicii_cycle_state_t currentViciiState;
	
	// state to show
	vicii_cycle_state_t viciiStateToShow;
	
	// current colors D020-D02E for displaying states
	u8 colorsToShow[0x0F];
	u8 colorToShowD800;
	
	int rasterToShowX;
	int rasterToShowY;
	int rasterCharToShowX;
	int rasterCharToShowY;
	
	//
	void InitViceC64();

	void InitViews();
	void InitLayouts();
	
	void ThreadRun(void *data);
	
	C64ScreenLayout *screenPositions[C64_SCREEN_LAYOUT_MAX];
	
	int frameCounter;
//	int nextScreenUpdateFrame;
	
	//
	void AddDebugCode();

	C64KeyboardShortcuts *keyboardShortcuts;
	bool ProcessGlobalKeyboardShortcut(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	void SwitchIsWarpSpeed();
	void SwitchScreenLayout();
	void SwitchToScreenLayout(int newScreenLayoutId);
	void SwitchUseKeyboardAsJoystick();
	void SwitchIsMulticolorDataDump();
	void SwitchIsShowRasterBeam();
	
	void StepOverInstruction();
	void StepOneCycle();
	void RunContinueEmulation();
	
	void SwitchIsDataDirectlyFromRam();
	
	// fonts
	CSlrFont *fontCBM1;
	CSlrFont *fontCBM2;
	CSlrFont *fontCBMShifted;
	
	std::vector<CGuiView *> traversalOfViews;
	bool CanSelectView(CGuiView *view);
	void MoveFocusToNextView();
	void MoveFocusToPrevView();
	
	
	void CreateFonts();
	
	volatile bool isShowingRasterCross;
	
	
	//
	C64Symbols *symbols;
	
	virtual void ApplicationEnteredBackground();
	virtual void ApplicationEnteredForeground();

	//
	bool isEmulationThreadRunning;
	
	void MapC64MemoryToFile(char *filePath);
	void UnMapC64MemoryFromFile();
	uint8 *mappedC64Memory;
	void *mappedC64MemoryDescriptor;
	
	//
	std::list<u32> keyDownCodes;
	
	// mouse cursor for scrolling where cursor is
	float mouseCursorX, mouseCursorY;
	
	//
	virtual void SharedMemorySignalCallback(CByteBuffer *sharedMemoryData);

	void InitRasterColors();
	
	void CheckMouseCursorVisibility();
	void ShowMouseCursor();

	//
	void ShowMainScreen();
	
	// open/save dialogs
	void ShowDialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
							CSlrString *defaultFolder,
							CSlrString *windowTitle);

	void ShowDialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
							CSlrString *defaultFileName, CSlrString *defaultFolder,
							CSlrString *windowTitle);
	
	CGuiViewSaveFile *viewSaveFile;
	CGuiViewSelectFile *viewSelectFile;
	CGuiView *fileDialogPreviousView;
	CSystemFileDialogCallback *systemFileDialogCallback;
	
	virtual void FileSelected(UTFString *filePath);
	virtual void FileSelectionCancelled();
	
	virtual void SaveFileSelected(UTFString *fullFilePath, char *fileName);
	virtual void SaveFileSelectionCancelled();

};

extern CViewC64 *viewC64;

// drag & drop callbacks
extern long c64dStartupTime;

void C64D_DragDropCallback(char *filePath);
void C64D_DragDropCallback(CSlrString *filePath);
void C64D_DragDropCallbackPRG(CSlrString *filePath);
void C64D_DragDropCallbackD64(CSlrString *filePath);
void C64D_DragDropCallbackCRT(CSlrString *filePath);
void C64D_DragDropCallbackSNAP(CSlrString *filePath);

#endif //_GUI_C64DEMO_
