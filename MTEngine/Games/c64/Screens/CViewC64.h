#ifndef _GUI_C64_
#define _GUI_C64_

#define C64DEBUGGER_VERSION_STRING	"0.5"

#include "CGuiView.h"
#include "CGuiButton.h"
#include "SYS_Threading.h"
#include "SYS_Defs.h"
#include "SYS_PauseResume.h"
#include "CViewMainMenu.h"
#include "CViewSettingsMenu.h"
#include <list>
#include <vector>
#include <map>

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
class CViewDrive1541State;
class CViewEmulationState;
class CViewMonitorConsole;
class CViewMainMenu;
class CViewSettingsMenu;
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
	C64_SCREEN_LAYOUT_MAX
};


class C64ScreenLayout
{
public:
	C64ScreenLayout();
	bool isAvailable;
	
	bool c64ScreenVisible;
	float c64ScreenX, c64ScreenY;
	float screenSizeX, screenSizeY;
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
	bool c64DisassembleShowHexCodes;
	bool drive1541DisassembleVisible;
	float drive1541DisassembleX, drive1541DisassembleY;
	float drive1541DisassembleSizeX, drive1541DisassembleSizeY;
	float drive1541DisassembleFontSize;
	int drive1541DisassembleNumberOfLines;
	bool drive1541DisassembleShowHexCodes;
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
	int c64DataDumpNumberOfBytesPerLine;
	bool drive1541DataDumpVisible;
	float drive1541DataDumpX, drive1541DataDumpY;
	float drive1541DataDumpSizeX, drive1541DataDumpSizeY;
	float drive1541DataDumpFontSize;
	float drive1541DataDumpGapAddress;
	float drive1541DataDumpGapHexData;
	float drive1541DataDumpGapDataCharacters;
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
	bool c64StateDrive1541Visible;
	float c64StateDrive1541X, c64StateDrive1541Y;
	float c64StateDrive1541FontSize;
	bool c64StateDrive1541RenderVIA1;
	bool c64StateDrive1541RenderVIA2;
	bool c64StateDrive1541RenderDriveLED;
	bool c64StateDrive1541IsVertical;
	
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

class CViewC64 : public CGuiView, CGuiButtonCallback, CSlrThread, CApplicationPauseResumeListener
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
	
	virtual void ActivateView();
	virtual void DeactivateView();

	
	C64DebugInterface *debugInterface;
	
	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);


	CViewMainMenu *viewC64MainMenu;
	CViewSettingsMenu *viewC64SettingsMenu;
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

	CViewMonitorConsole *viewMonitorConsole;
	
	void InitViceC64();

	void InitViews();
	void InitLayouts();
	
	void ThreadRun(void *data);
	
	C64ScreenLayout *screenPositions[C64_SCREEN_LAYOUT_MAX];
	
	int frameCounter;
//	int nextScreenUpdateFrame;
	
	//
	void AddDebugCode();

	CSlrKeyboardShortcuts *keyboardShortcuts;
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
	
	void ClearViewsFocus();
	void SetFocusForView(CGuiView *view);
	CGuiView *focusView;
	
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
};

extern CViewC64 *viewC64;


#endif //_GUI_C64DEMO_
