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

class CDebugInterface;
class C64DebugInterface;
class AtariDebugInterface;
class NesDebugInterface;

class CDebuggerEmulatorPlugin;

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
class CViewC64ScreenWrapper;

class CViewMemoryMap;
class CViewDataDump;
class CViewDataWatch;
class CViewBreakpoints;
class CViewDisassemble;
class CViewSourceCode;
class CViewC64StateCPU;
class CViewC64StateCIA;
class CViewC64StateSID;
class CViewC64StateVIC;
class CViewC64VicDisplay;
class CViewC64VicControl;
class CViewVicEditor;
class CViewDriveStateCPU;
class CViewDrive1541StateVIA;
class CViewC64StateREU;
class CViewC64AllGraphics;
class CViewEmulationState;
class CViewEmulationCounters;
class CViewTimeline;
class CViewMonitorConsole;

class CViewAtariScreen;
class CViewAtariStateCPU;
class CViewAtariStateANTIC;
class CViewAtariStatePIA;
class CViewAtariStateGTIA;
class CViewAtariStatePOKEY;

class CViewNesScreen;
class CViewNesStateCPU;

class CViewJukeboxPlaylist;
class CViewMainMenu;
class CViewSettingsMenu;
class CViewFileD64;
class CViewC64KeyMap;
class CViewKeyboardShortcuts;
class CViewSnapshots;
class CViewColodore;
class CViewAbout;

class CColorsTheme;


enum screenLayouts
{
	// c64
	SCREEN_LAYOUT_C64_ONLY = 0,
	SCREEN_LAYOUT_C64_DATA_DUMP = 1,
	SCREEN_LAYOUT_C64_DEBUGGER = 2,
	SCREEN_LAYOUT_C64_1541_MEMORY_MAP = 3,
	SCREEN_LAYOUT_C64_SHOW_STATES = 4,
	SCREEN_LAYOUT_C64_MEMORY_MAP = 5,
	SCREEN_LAYOUT_C64_1541_DEBUGGER = 6,
	//	SCREEN_LAYOUT_C64_1541_DATA_DUMP,
	SCREEN_LAYOUT_C64_MONITOR_CONSOLE = 7,
	SCREEN_LAYOUT_C64_CYCLER = 8,
	SCREEN_LAYOUT_C64_VIC_DISPLAY = 9,
	SCREEN_LAYOUT_C64_VIC_DISPLAY_LITE = 10,
	SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM = 11,
	SCREEN_LAYOUT_C64_SOURCE_CODE = 12,
	SCREEN_LAYOUT_C64_ALL_GRAPHICS = 13,

	// atari
	SCREEN_LAYOUT_ATARI_ONLY,
	SCREEN_LAYOUT_ATARI_DATA_DUMP,
	SCREEN_LAYOUT_ATARI_DEBUGGER,
	SCREEN_LAYOUT_ATARI_SHOW_STATES,
	SCREEN_LAYOUT_ATARI_MEMORY_MAP,
	SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE,
	SCREEN_LAYOUT_ATARI_CYCLER,
	SCREEN_LAYOUT_ATARI_DISPLAY_LITE,
	SCREEN_LAYOUT_ATARI_SOURCE_CODE,

	// nes
	SCREEN_LAYOUT_NES_ONLY,
	SCREEN_LAYOUT_NES_DATA_DUMP,
	
	// other
	SCREEN_LAYOUT_C64_AND_ATARI,
	
	SCREEN_LAYOUT_MAX
};


class CScreenLayout
{
public:
	CScreenLayout();
	bool isAvailable;
	
	bool debugOnC64;
	bool debugOnDrive1541;

	// move the below to respective classes (CScreenLayoutC64, CScreenLayoutAtari, CScreenLayoutNES)
	// using one interface get layout specs from emulator
	
	bool c64ScreenVisible;
	float c64ScreenX, c64ScreenY;
	float c64ScreenSizeX, c64ScreenSizeY;
	bool c64ScreenShowGridLines;
	bool c64ScreenShowZoomedScreen;
	float c64ScreenZoomedX, c64ScreenZoomedY;
	float c64ScreenZoomedSizeX, c64ScreenZoomedSizeY;
	
	bool c64CpuStateVisible;
	float c64CpuStateX, c64CpuStateY;
	float c64CpuStateFontSize;
	bool drive1541CpuStateVisible;
	float drive1541CpuStateX, drive1541CpuStateY;
	float drive1541CpuStateFontSize;
	
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
	bool c64DisassembleShowSourceCode;
	int c64DisassembleNumberOfLabelCharacters;
	
	bool c64SourceCodeVisible;
	float c64SourceCodeX, c64SourceCodeY;
	float c64SourceCodeSizeX, c64SourceCodeSizeY;
	float c64SourceCodeFontSize;

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
	bool drive1541DisassembleShowSourceCode;
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
	bool c64DataDumpShowDataCharacters;
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
	float c64StateVICSizeX, c64StateVICSizeY;
	float c64StateVICFontSize;
	bool c64StateVICIsVertical;
	bool c64StateVICShowSprites;
	int c64StateVICNumValuesPerColumn;
	bool c64StateREUVisible;
	float c64StateREUX, c64StateREUY;
	float c64StateREUFontSize;
	bool c64EmulationCountersVisible;
	float c64EmulationCountersX, c64EmulationCountersY;
	float c64EmulationCountersFontSize;
	
	bool drive1541StateVIAVisible;
	float drive1541StateVIAX, drive1541StateVIAY;
	float drive1541StateVIAFontSize;
	bool drive1541StateVIARenderVIA1;
	bool drive1541StateVIARenderVIA2;
	bool drive1541StateVIARenderDriveLED;
	bool drive1541StateVIAIsVertical;
	
	bool c64VicDisplayVisible;
	float c64VicDisplayX, c64VicDisplayY;
	float c64VicDisplayScale;
	bool c64VicDisplayCanScrollDisassemble;
	
	bool c64VicControlVisible;
	float c64VicControlX, c64VicControlY;
	float c64VicControlFontSize;
	
	bool c64AllGraphicsVisible;
	float c64AllGraphicsX, c64AllGraphicsY;
	
	bool c64MonitorConsoleVisible;
	float c64MonitorConsoleX, c64MonitorConsoleY;
	float c64MonitorConsoleSizeX, c64MonitorConsoleSizeY;
	float c64MonitorConsoleFontScale;
	int c64MonitorConsoleNumLines;
	
	bool emulationStateVisible;
	float emulationStateX, emulationStateY;
	
	///////
	bool debugOnAtari;
	
	bool atariScreenVisible;
	float atariScreenX, atariScreenY;
	float atariScreenSizeX, atariScreenSizeY;
	bool atariScreenShowGridLines;
	bool atariScreenShowZoomedScreen;
	float atariScreenZoomedX, atariScreenZoomedY;
	float atariScreenZoomedSizeX, atariScreenZoomedSizeY;
	
	bool atariCpuStateVisible;
	float atariCpuStateX, atariCpuStateY;
	float atariCpuStateFontSize;

	bool atariDisassembleVisible;
	float atariDisassembleX, atariDisassembleY;
	float atariDisassembleSizeX, atariDisassembleSizeY;
	float atariDisassembleFontSize;
	int atariDisassembleNumberOfLines;
	float atariDisassembleCodeMnemonicsOffset;
	bool atariDisassembleShowHexCodes;
	bool atariDisassembleShowCodeCycles;
	float atariDisassembleCodeCyclesOffset;
	bool atariDisassembleShowLabels;
	int atariDisassembleNumberOfLabelCharacters;

	bool atariSourceCodeVisible;
	float atariSourceCodeX, atariSourceCodeY;
	float atariSourceCodeSizeX, atariSourceCodeSizeY;
	float atariSourceCodeFontSize;

	bool atariDataDumpVisible;
	float atariDataDumpX, atariDataDumpY;
	float atariDataDumpSizeX, atariDataDumpSizeY;
	float atariDataDumpFontSize;
	float atariDataDumpGapAddress;
	float atariDataDumpGapHexData;
	float atariDataDumpGapDataCharacters;
	bool atariDataDumpShowDataCharacters;
	bool atariDataDumpShowCharacters;
	bool atariDataDumpShowSprites;
	int atariDataDumpNumberOfBytesPerLine;
	
	bool atariMemoryMapVisible;
	float atariMemoryMapX, atariMemoryMapY;
	float atariMemoryMapSizeX, atariMemoryMapSizeY;

	bool atariStateANTICVisible;
	float atariStateANTICX, atariStateANTICY;
	float atariStateANTICFontSize;

	bool atariStateGTIAVisible;
	float atariStateGTIAX, atariStateGTIAY;
	float atariStateGTIAFontSize;

	bool atariStatePIAVisible;
	float atariStatePIAX, atariStatePIAY;
	float atariStatePIAFontSize;

	bool atariStatePOKEYVisible;
	float atariStatePOKEYX, atariStatePOKEYY;
	float atariStatePOKEYFontSize;

	bool atariMonitorConsoleVisible;
	float atariMonitorConsoleX, atariMonitorConsoleY;
	float atariMonitorConsoleSizeX, atariMonitorConsoleSizeY;
	float atariMonitorConsoleFontScale;
	int atariMonitorConsoleNumLines;

	bool atariEmulationCountersVisible;
	float atariEmulationCountersX, atariEmulationCountersY;
	float atariEmulationCountersFontSize;

	///////
	bool debugOnNes;
	
	bool nesScreenVisible;
	float nesScreenX, nesScreenY;
	float nesScreenSizeX, nesScreenSizeY;
	bool nesScreenShowGridLines;
	bool nesScreenShowZoomedScreen;
	float nesScreenZoomedX, nesScreenZoomedY;
	float nesScreenZoomedSizeX, nesScreenZoomedSizeY;

	bool nesCpuStateVisible;
	float nesCpuStateX, nesCpuStateY;
	float nesCpuStateFontSize;
	
	bool nesDisassembleVisible;
	float nesDisassembleX, nesDisassembleY;
	float nesDisassembleSizeX, nesDisassembleSizeY;
	float nesDisassembleFontSize;
	int nesDisassembleNumberOfLines;
	float nesDisassembleCodeMnemonicsOffset;
	bool nesDisassembleShowHexCodes;
	bool nesDisassembleShowCodeCycles;
	float nesDisassembleCodeCyclesOffset;
	bool nesDisassembleShowLabels;
	bool nesDisassembleShowSourceCode;
	int nesDisassembleNumberOfLabelCharacters;

	bool nesDataDumpVisible;
	float nesDataDumpX, nesDataDumpY;
	float nesDataDumpSizeX, nesDataDumpSizeY;
	float nesDataDumpFontSize;
	float nesDataDumpGapAddress;
	float nesDataDumpGapHexData;
	float nesDataDumpGapDataCharacters;
	bool nesDataDumpShowCharacters;
	bool nesDataDumpShowSprites;
	int nesDataDumpNumberOfBytesPerLine;
	
	bool nesMemoryMapVisible;
	float nesMemoryMapX, nesMemoryMapY;
	float nesMemoryMapSizeX, nesMemoryMapSizeY;
};

class CEmulationThreadC64 : public CSlrThread
{
	void ThreadRun(void *data);
};

class CEmulationThreadAtari : public CSlrThread
{
	void ThreadRun(void *data);
};

class CEmulationThreadNes : public CSlrThread
{
	void ThreadRun(void *data);
};


class CViewC64 : public CGuiView, CGuiButtonCallback, CApplicationPauseResumeListener,
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

	CDebugInterface *selectedDebugInterface;
	
	C64DebugInterface *debugInterfaceC64;
	CEmulationThreadC64 *emulationThreadC64;

	AtariDebugInterface *debugInterfaceAtari;
	CEmulationThreadAtari *emulationThreadAtari;

	NesDebugInterface *debugInterfaceNes;
	CEmulationThreadNes *emulationThreadNes;

	//
	CDebugInterface *GetDebugInterface(u8 emulatorType);

	CColorsTheme *colorsTheme;
	
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
	CViewColodore *viewColodore;
	CViewAbout *viewAbout;

	int currentScreenLayoutId;
	
	CSlrFont *fontDisassemble;
	
	CViewC64Screen *viewC64Screen;
	CViewC64ScreenWrapper *viewC64ScreenWrapper;
	
	CViewMemoryMap *viewC64MemoryMap;
	CViewMemoryMap *viewDrive1541MemoryMap;
	
	CViewDataDump *viewC64MemoryDataDump;
	CViewDataWatch *viewC64MemoryDataWatch;
	CViewDataDump *viewDrive1541MemoryDataDump;
	CViewDataWatch *viewDrive1541MemoryDataWatch;
	
	CViewDisassemble *viewC64Disassemble;
	CViewDisassemble *viewDrive1541Disassemble;
	
	CViewSourceCode *viewC64SourceCode;
	
	CViewC64StateCIA *viewC64StateCIA;
	CViewC64StateSID *viewC64StateSID;
	CViewC64StateVIC *viewC64StateVIC;
	CViewDrive1541StateVIA *viewDrive1541StateVIA;
	CViewC64StateREU *viewC64StateREU;
	CViewEmulationCounters *viewC64EmulationCounters;

	CViewEmulationState *viewEmulationState;

	CViewTimeline *viewC64Timeline;
	CViewTimeline *viewAtariTimeline;
	
	CViewC64VicDisplay *viewC64VicDisplay;
	CViewC64VicControl *viewC64VicControl;
	
	CViewC64AllGraphics *viewC64AllGraphics;

	CViewMonitorConsole *viewC64MonitorConsole;
	
	CViewC64StateCPU *viewC64StateCPU;
	CViewDriveStateCPU *viewDriveStateCPU;
	
	// VIC Editor
	CViewVicEditor *viewVicEditor;
	
	// Atari
	CViewAtariScreen *viewAtariScreen;
	CViewDisassemble *viewAtariDisassemble;
	CViewDataDump *viewAtariMemoryDataDump;
	CViewDataWatch *viewAtariMemoryDataWatch;
	CViewMemoryMap *viewAtariMemoryMap;
	CViewBreakpoints *viewAtariBreakpoints;
	CViewAtariStateCPU *viewAtariStateCPU;
	CViewAtariStateANTIC *viewAtariStateANTIC;
	CViewAtariStatePIA *viewAtariStatePIA;
	CViewAtariStateGTIA *viewAtariStateGTIA;
	CViewAtariStatePOKEY *viewAtariStatePOKEY;
	CViewMonitorConsole *viewAtariMonitorConsole;
	CViewEmulationCounters *viewAtariEmulationCounters;
	CViewSnapshots *viewAtariSnapshots;

	// NES
	CViewNesScreen *viewNesScreen;
	CViewNesStateCPU *viewNesStateCPU;
	CViewDisassemble *viewNesDisassemble;
	CViewSourceCode *viewAtariSourceCode;
	CViewDataDump *viewNesMemoryDataDump;
	CViewMemoryMap *viewNesMemoryMap;
	CViewBreakpoints *viewNesBreakpoints;
	CViewSnapshots *viewNesSnapshots;

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
	
	void UpdateViciiColors();
	
	// JukeBox playlist
	CViewJukeboxPlaylist *viewJukeboxPlaylist;
	
	//
	void InitViceC64();
	void InitAtari800();
	void InitNestopia();

	void InitViews();
	void InitLayouts();
	
	void InitJukebox(CSlrString *jukeboxJsonFilePath);
	
	CScreenLayout *screenPositions[SCREEN_LAYOUT_MAX];
	
	int guiRenderFrameCounter;
//	int nextScreenUpdateFrame;
	
	//
	void EmulationStartFrameCallback();
	
	//
	void AddC64DebugCode();

	C64KeyboardShortcuts *keyboardShortcuts;
	bool ProcessGlobalKeyboardShortcut(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	void SwitchIsWarpSpeed();
	
	void SwitchScreenLayout();
	void SetLayout(int newScreenLayoutId);
	void RefreshLayout();
	void SwitchToScreenLayout(int newScreenLayoutId);
	void SwitchUseKeyboardAsJoystick();
	void SwitchIsMulticolorDataDump();
	void SetIsMulticolorDataDump(bool isMultiColor);
	void SwitchIsShowRasterBeam();
	
	void StepOverInstruction();
	void StepOneCycle();
	void RunContinueEmulation();
	void HardReset();
	void SoftReset();
	
	void SwitchIsDataDirectlyFromRam();
	void SwitchIsDataDirectlyFromRam(bool setIsDirectlyFromRam);

	//
	CViewDisassemble *GetActiveDisassembleView();
	
	// fonts
	CSlrFont *fontCBM1;
	CSlrFont *fontCBM2;
	CSlrFont *fontCBMShifted;
	
	CSlrFont *fontAtari;
	
	std::vector<CGuiView *> traversalOfViews;
	bool CanSelectView(CGuiView *view);
	void MoveFocusToNextView();
	void MoveFocusToPrevView();
	
	
	void CreateFonts();
	
	volatile bool isShowingRasterCross;
	
	virtual void ApplicationEnteredBackground();
	virtual void ApplicationEnteredForeground();
	virtual void ApplicationShutdown();

	
	// TODO: move this below to proper debug interfaces:
	void MapC64MemoryToFile(char *filePath);
	void UnMapC64MemoryFromFile();
	uint8 *mappedC64Memory;
	void *mappedC64MemoryDescriptor;

	//
//	void MapAtariMemoryToFile(char *filePath);
//	void UnMapAtariMemoryFromFile();
//	uint8 *mappedAtariMemory;
//	void *mappedAtariMemoryDescriptor;

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
	
	bool isSoundMuted;
	void ToggleSoundMute();
	void SetSoundMute(bool isMuted);
	void UpdateSIDMute();
	
	//
	volatile bool isVisibleWatch;
	void SetWatchVisible(bool isVisibleWatch);
	void UpdateWatchVisible();
	
	//
	void CreateEmulatorPlugins();
	void RegisterEmulatorPlugin(CDebuggerEmulatorPlugin *emuPlugin);
	
	void RenderPlugins();
	//
	
	char *ATRD_GetPathForRoms_IMPL();

};

extern CViewC64 *viewC64;

// drag & drop callbacks
extern long c64dStartupTime;

void C64D_DragDropCallback(char *filePath);
void C64D_DragDropCallback(CSlrString *filePath);

// c64
void C64D_DragDropCallbackPRG(CSlrString *filePath);
void C64D_DragDropCallbackD64(CSlrString *filePath);
void C64D_DragDropCallbackTAP(CSlrString *filePath);
void C64D_DragDropCallbackCRT(CSlrString *filePath);
void C64D_DragDropCallbackSID(CSlrString *filePath);
void C64D_DragDropCallbackSNAP(CSlrString *filePath);
void C64D_DragDropCallbackVCE(CSlrString *filePath);
void C64D_DragDropCallbackPNG(CSlrString *filePath);

// atari
void C64D_DragDropCallbackXEX(CSlrString *filePath);
void C64D_DragDropCallbackATR(CSlrString *filePath);
void C64D_DragDropCallbackCAS(CSlrString *filePath);
void C64D_DragDropCallbackCAR(CSlrString *filePath);
void C64D_DragDropCallbackA8S(CSlrString *filePath);

// nes
void C64D_DragDropCallbackNES(CSlrString *filePath);

// jukebox
void C64D_DragDropCallbackJukeBox(CSlrString *filePath);



#endif //_GUI_C64DEMO_
