//
// C64 Debugger (C) Marcin Skoczylas, slajerek@gmail.com
//
// created on 2016-02-22

// define also in CGuiMain
//#define DO_NOT_USE_AUDIO_QUEUE

extern "C"{
#include "c64mem.h"
}

#include "CViewC64.h"
#include "CViewC64Screen.h"
#include "VID_GLViewController.h"
#include "VID_Blits.h"
#include "CGuiMain.h"
#include "RES_ResourceManager.h"
#include "CSlrFontProportional.h"
#include "VID_ImageBinding.h"
#include "CByteBuffer.h"
#include "CSlrKeyboardShortcuts.h"
#include "SYS_KeyCodes.h"
#include "C64SettingsStorage.h"
#include "CViewDataDump.h"
#include "CViewMemoryMap.h"
#include "CViewDisassemble.h"
#include "CViewC64StateCIA.h"
#include "CViewC64StateSID.h"
#include "CViewC64StateVIC.h"
#include "CViewDrive1541State.h"
#include "CViewEmulationState.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64VicControl.h"
#include "CViewC64StateCPU.h"
#include "CViewDriveStateCPU.h"
#include "CViewBreakpoints.h"
#include "CViewMainMenu.h"
#include "CViewSettingsMenu.h"
#include "CViewFileD64.h"
#include "CViewC64KeyMap.h"
#include "CViewKeyboardShortcuts.h"
#include "CViewMonitorConsole.h"
#include "CViewSnapshots.h"
#include "CViewAbout.h"
#include "CViewVicEditor.h"
#include "C64FileDataAdapter.h"
#include "C64KeyboardShortcuts.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "C64Symbols.h"
#include "C64Palette.h"
#include "C64KeyMap.h"
#include "C64DebugInterfaceVice.h"
#include "C64CommandLine.h"
#include "C64SharedMemory.h"
#include "C64SIDFrequencies.h"
#include "SND_SoundEngine.h"
#include "CSlrFileFromOS.h"

CViewC64 *viewC64 = NULL;

long c64dStartupTime = 0;

#define TEXT_ADDR	0x0400
#define COLOR_ADDR	0xD800

CViewC64::CViewC64(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{	
	this->name = "CViewC64";
	viewC64 = this;
	
	c64dStartupTime = SYS_GetCurrentTimeInMillis();
	
	C64InitPalette();
	
	isEmulationThreadRunning = false;

	if (c64SettingsDefaultScreenLayoutId < 0)
	{
		c64SettingsDefaultScreenLayoutId = C64_SCREEN_LAYOUT_C64_DATA_DUMP;
		
		LOGD("set c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	}
	
	C64DebuggerInitSharedMemory();
	SYS_SharedMemoryRegisterCallback(viewC64);

	C64DebuggerParseCommandLine1();

	// restore pre-launch settings (paths to D64, PRG, CRT)
	C64DebuggerRestoreSettings(C64DEBUGGER_BLOCK_PRELAUNCH);
	
	
	LOGM("sound engine startup");
#ifndef DO_NOT_USE_AUDIO_QUEUE
	gSoundEngine->StartAudioUnit(true, false, 0);
#endif
	
	SID_FrequenciesInit();

	mappedC64Memory = NULL;
	mappedC64MemoryDescriptor = NULL;
	
	keyboardShortcuts = new C64KeyboardShortcuts();

	// load breakpoints and symbols
	this->symbols = new C64Symbols();
	
	// init default key map
	if (c64SettingsSkipConfig == false)
	{
		C64KeyMapLoadFromSettings();
	}
	else
	{
		C64KeyMapCreateDefault();
	}

	// init the Commodore 64 object
	this->InitViceC64();
	
	// create Commodore 64 fonts from kernal data
	this->CreateFonts();

	this->InitViews();
	this->InitLayouts();
	
	// loop of views for TAB & shift+TAB
	traversalOfViews.push_back(viewC64Screen);
	traversalOfViews.push_back(viewC64Disassemble);
	traversalOfViews.push_back(viewC64MemoryDataDump);
	traversalOfViews.push_back(viewC64MemoryMap);
	traversalOfViews.push_back(viewDrive1541Disassemble);
	traversalOfViews.push_back(viewDrive1541MemoryDataDump);
	traversalOfViews.push_back(viewDrive1541MemoryMap);
	traversalOfViews.push_back(viewMonitorConsole);
	traversalOfViews.push_back(viewC64VicDisplay);
	

	// add views
	guiMain->AddGuiElement(this);

	// other views
	viewC64MainMenu = new CViewMainMenu(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64MainMenu);
	
	viewC64SettingsMenu = new CViewSettingsMenu(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64SettingsMenu);
	
	viewFileD64 = new CViewFileD64(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewFileD64);
	
	viewC64Breakpoints = new CViewBreakpoints(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64Breakpoints);
	
	viewC64Snapshots = new CViewSnapshots(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64Snapshots);

	viewC64KeyMap = new CViewC64KeyMap(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64KeyMap);

	viewKeyboardShortcuts = new CViewKeyboardShortcuts(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewKeyboardShortcuts);

	viewAbout = new CViewAbout(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewAbout);
	
	// open/save file dialogs replacement
	viewSelectFile = new CGuiViewSelectFile(0, 0, posZ, SCREEN_WIDTH-80.0, SCREEN_HEIGHT, false, this);
	viewSelectFile->SetFont(fontCBMShifted, 2.0f);
	guiMain->AddGuiElement(viewSelectFile);

	viewSaveFile = new CGuiViewSaveFile(0, 0, posZ, SCREEN_WIDTH-80.0, SCREEN_HEIGHT, this);
	viewSaveFile->SetFont(fontCBMShifted, 2.0f);
	guiMain->AddGuiElement(viewSaveFile);
	
	//
	viewVicEditor = new CViewVicEditor(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewVicEditor);

	SYS_AddApplicationPauseResumeListener(this);

	
	// settings that need to be set when emulation is initialized
	C64DebuggerRestoreSettings(C64DEBUGGER_BLOCK_POSTLAUNCH);
	
	// do additional parsing
	C64DebuggerParseCommandLine2();

	// memory map colors
	C64DebuggerComputeMemoryMapColorTables(c64SettingsMemoryValuesStyle);
	C64DebuggerSetMemoryMapMarkersStyle(c64SettingsMemoryMarkersStyle);

	bool isInVicEditor = c64SettingsIsInVicEditor;
	
	LOGD("... after parsing c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	if (c64SettingsDefaultScreenLayoutId >= C64_SCREEN_LAYOUT_MAX)
	{
		LOGD("... c64SettingsDefaultScreenLayoutId=%d >= C64_SCREEN_LAYOUT_MAX=%d", c64SettingsDefaultScreenLayoutId, C64_SCREEN_LAYOUT_MAX);
		
		c64SettingsDefaultScreenLayoutId = C64_SCREEN_LAYOUT_C64_DEBUGGER;
		LOGD("... corrected c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	}
	this->SwitchToScreenLayout(c64SettingsDefaultScreenLayoutId);

	c64SettingsIsInVicEditor = isInVicEditor;
	
	// finished starting up
	RES_SetStateIdle();
	VID_SetFPS(FRAMES_PER_SECOND);
	
	// Start emulation thread (emulation should be already initialized, just run the processor)
	SYS_StartThread(this, NULL);

	
	// attach disks, cartridges etc
	C64DebuggerPerformStartupTasks();

	if (c64SettingsSkipConfig == false)
	{
		viewKeyboardShortcuts->RestoreKeyboardShortcuts();
	}
	
	viewKeyboardShortcuts->UpdateQuitShortcut();

	//
	C64SetPaletteNum(c64SettingsVicPalette);

	// start
	ShowMainScreen();	
}

void CViewC64::ShowMainScreen()
{
	if (c64SettingsIsInVicEditor)
	{
		guiMain->SetView(viewVicEditor);
	}
	else
	{
		guiMain->SetView(this);
	}

	//	guiMain->SetView(viewKeyboardShortcuts);
	//	guiMain->SetView(viewC64KeyMap);
	//	guiMain->SetView(viewAbout);
	//	guiMain->SetView(viewC64SettingsMenu);
	//	guiMain->SetView(viewC64MainMenu);
	//	guiMain->SetView(viewC64Breakpoints);
	//	guiMain->SetView(viewVicEditor);

	CheckMouseCursorVisibility();
}

CViewC64::~CViewC64()
{
}

void CViewC64::InitViceC64()
{
	LOGM("CViewC64::InitViceC64");
	
	if (c64SettingsPathToC64MemoryMapFile)
	{
		// Create debug interface and init Vice
		char *asciiPath = c64SettingsPathToC64MemoryMapFile->GetStdASCII();

		this->MapC64MemoryToFile(asciiPath);

		LOGD(".. mapped C64 memory to file '%s'", asciiPath);
		
		delete [] asciiPath;
		
	}
	else
	{
		this->mappedC64Memory = (uint8 *)malloc(C64_RAM_SIZE);
	}
	
	this->debugInterface = new C64DebugInterfaceVice(this, this->mappedC64Memory, c64SettingsFastBootKernalPatch);
	
	LOGM("CViewC64::InitViceC64: done");

}

void CViewC64::InitViews()
{
	// set mouse cursor outside at startup
	mouseCursorX = -SCREEN_WIDTH;
	mouseCursorY = -SCREEN_HEIGHT;
	
	// create views
	viewC64Screen = new CViewC64Screen(0, 0, posZ, sizeX, sizeY, debugInterface);
	this->AddGuiElement(viewC64Screen);
	
	
	// views
	// TODO: use data adapter
	viewC64MemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface, 256, 256, 0x10000, false);	// 256x256 = 64kB
	this->AddGuiElement(viewC64MemoryMap);
	viewDrive1541MemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface, 64, 1024, 0x10000, true);
	this->AddGuiElement(viewDrive1541MemoryMap);
	
	viewC64Disassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
												 debugInterface->dataAdapterC64, viewC64MemoryMap,
												 &(debugInterface->breakpointsC64PC), debugInterface);
	this->AddGuiElement(viewC64Disassemble);
	viewDrive1541Disassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
													debugInterface->dataAdapterDrive1541, viewDrive1541MemoryMap,
													&(debugInterface->breakpointsDrive1541PC), debugInterface);
	this->AddGuiElement(viewDrive1541Disassemble);

	
	viewC64MemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
											  debugInterface->dataAdapterC64, viewC64MemoryMap, viewC64Disassemble, debugInterface);
	this->AddGuiElement(viewC64MemoryDataDump);
	viewDrive1541MemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
													debugInterface->dataAdapterDrive1541, viewDrive1541MemoryMap, viewDrive1541Disassemble,
													debugInterface);
	this->AddGuiElement(viewDrive1541MemoryDataDump);
	
	
	viewC64StateCIA = new CViewC64StateCIA(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64StateCIA);
	viewC64StateSID = new CViewC64StateSID(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64StateSID);
	viewC64StateVIC = new CViewC64StateVIC(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64StateVIC);
	viewC64StateDrive1541 = new CViewDrive1541State(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64StateDrive1541);
	viewEmulationState = new CViewEmulationState(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewEmulationState);
	
	viewC64VicDisplay = new CViewC64VicDisplay(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64VicDisplay);

	viewC64VicControl = new CViewC64VicControl(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, viewC64VicDisplay);
	this->AddGuiElement(viewC64VicControl);
	
	viewMonitorConsole = new CViewMonitorConsole(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewMonitorConsole);
	
	//
	viewC64StateCPU = new CViewC64StateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewC64StateCPU);
	viewDriveStateCPU = new CViewDriveStateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterface);
	this->AddGuiElement(viewDriveStateCPU);


}

void CViewC64::InitLayouts()
{
	//
	// TODO: this code below was *automagically* generated and will be transformed into 
	//       layout loader/storage from JSON files
	//       and let each view has its own parameters loader. *this below is temporary*
	//       the layout designer is in progress...
	//
	float scale;
	float memMapSize = 200.0f;
	int m;
	
	m = C64_SCREEN_LAYOUT_C64_ONLY;
	screenPositions[m] = new C64ScreenLayout();
	scale = (float)SCREEN_HEIGHT / (float)debugInterface->GetC64ScreenSizeY();
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = ((float)SCREEN_WIDTH-screenPositions[m]->c64ScreenSizeX)/2.0f - 0.78f;
	screenPositions[m]->c64ScreenY = 0.0f;
	
	m = C64_SCREEN_LAYOUT_C64_DEBUGGER;
	screenPositions[m] = new C64ScreenLayout();
///	scale = 1.3f;
	scale = 0.67f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 180.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 181.0f;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 25.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleShowHexCodes = true;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 178.0f;
	screenPositions[m]->c64DataDumpY = 195.0f;
	screenPositions[m]->c64DataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - 195.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 4.0f;
	screenPositions[m]->c64StateVICX = 440.0f;
	screenPositions[m]->c64StateVICY = 0.0f;
	screenPositions[m]->c64StateVICIsVertical = true;

	
	m = C64_SCREEN_LAYOUT_C64_MEMORY_MAP;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.41f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 420.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 78.0f;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 5.0f;
	screenPositions[m]->c64DisassembleX = 0.5f;
	screenPositions[m]->c64DisassembleY = 0.5f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapX = 77.0f;
	screenPositions[m]->c64MemoryMapY = 15.0f;
	screenPositions[m]->c64MemoryMapSizeX = 340.5f;
	screenPositions[m]->c64MemoryMapSizeY = 340.5f;
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 421;
	screenPositions[m]->c64DataDumpY = 125;
	screenPositions[m]->c64DataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - 130.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize*0.7f;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.36f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 8;

	
	m = C64_SCREEN_LAYOUT_C64_1541_DEBUGGER;
	screenPositions[m] = new C64ScreenLayout();
	scale = 1.09f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 80.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 80.0f;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 5.0f;
	screenPositions[m]->c64DisassembleX = 0.5f;
	screenPositions[m]->c64DisassembleY = 0.5f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->drive1541CpuStateVisible = true;
	screenPositions[m]->drive1541CpuStateX = 350.0f;
	screenPositions[m]->drive1541CpuStateY = 0.0f;
	screenPositions[m]->drive1541DisassembleVisible = true;
	screenPositions[m]->drive1541DisassembleFontSize = 5.0f;
	screenPositions[m]->drive1541DisassembleX = 500.0f;
	screenPositions[m]->drive1541DisassembleY = 0.5f;
	screenPositions[m]->drive1541DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->drive1541DisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->debugOnDrive1541 = true;
	screenPositions[m]->c64StateDrive1541Visible = true;
	screenPositions[m]->c64StateDrive1541FontSize = 5.0f;
	screenPositions[m]->c64StateDrive1541X = 342.0f;
	screenPositions[m]->c64StateDrive1541Y = 310.0f;
	screenPositions[m]->c64StateDrive1541RenderVIA1 = true;
	screenPositions[m]->c64StateDrive1541RenderVIA2 = false;
	screenPositions[m]->c64StateDrive1541RenderDriveLED = true;
	screenPositions[m]->c64StateDrive1541IsVertical = true;
	screenPositions[m]->c64StateCIARenderCIA1 = false;
	screenPositions[m]->c64StateCIARenderCIA2 = true;
	memMapSize = 50.0f;
	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapX = -1.0f + ((503.0f-(memMapSize*2.0f)-78.0f)/4.0f);
	screenPositions[m]->c64MemoryMapY = SCREEN_HEIGHT-memMapSize-0.75f;
	screenPositions[m]->c64MemoryMapSizeX = memMapSize;
	screenPositions[m]->c64MemoryMapSizeY = memMapSize;
	screenPositions[m]->drive1541MemoryMapVisible = true;
	screenPositions[m]->drive1541MemoryMapX = 582.0f-memMapSize-3.0f - ((503.0f-(memMapSize*2.0f)-78.0f)/4.0f);
	screenPositions[m]->drive1541MemoryMapY = SCREEN_HEIGHT-memMapSize-0.75f;
	screenPositions[m]->drive1541MemoryMapSizeX = memMapSize;
	screenPositions[m]->drive1541MemoryMapSizeY = memMapSize;
	screenPositions[m]->c64StateCIAVisible = true;
	screenPositions[m]->c64StateCIAFontSize = 5.0f;
	screenPositions[m]->c64StateCIAX = 135.0f;
	screenPositions[m]->c64StateCIAY = 310.0f;


	m = C64_SCREEN_LAYOUT_C64_1541_MEMORY_MAP;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.525f;
	memMapSize = 200.0f;
	
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 190.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 78.0f;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 5.0f;
	screenPositions[m]->c64DisassembleX = 0.5f;
	screenPositions[m]->c64DisassembleY = 0.5f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->drive1541CpuStateVisible = true;
	screenPositions[m]->drive1541CpuStateX = 350.0f;
	screenPositions[m]->drive1541CpuStateY = 0.0f;
	screenPositions[m]->drive1541CpuStateFontSize = 5.0f;
	screenPositions[m]->drive1541DisassembleVisible = true;
	screenPositions[m]->drive1541DisassembleFontSize = 5.0f;
	screenPositions[m]->drive1541DisassembleX = 500.0f;
	screenPositions[m]->drive1541DisassembleY = 0.5f;
	screenPositions[m]->drive1541DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->drive1541DisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->debugOnDrive1541 = true;
	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapX = 78.0f + ((503.0f-(memMapSize*2.0f)-78.0f)/4.0f);
	screenPositions[m]->c64MemoryMapY = SCREEN_HEIGHT-memMapSize-5.0f;
	screenPositions[m]->c64MemoryMapSizeX = memMapSize;
	screenPositions[m]->c64MemoryMapSizeY = memMapSize;
	screenPositions[m]->drive1541MemoryMapVisible = true;
	screenPositions[m]->drive1541MemoryMapX = 503.0f-memMapSize-3.0f - ((503.0f-(memMapSize*2.0f)-78.0f)/4.0f);
	screenPositions[m]->drive1541MemoryMapY = SCREEN_HEIGHT-memMapSize-5.0f;
	screenPositions[m]->drive1541MemoryMapSizeX = memMapSize;
	screenPositions[m]->drive1541MemoryMapSizeY = memMapSize;

	m = C64_SCREEN_LAYOUT_C64_DATA_DUMP;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapX = 112.0f;
	screenPositions[m]->c64MemoryMapY = 1.0f;
	screenPositions[m]->c64MemoryMapSizeX = 199.0f;
	screenPositions[m]->c64MemoryMapSizeY = 192.0f;
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 108.0f;
	screenPositions[m]->c64DataDumpY = 196.0f;
	screenPositions[m]->c64DataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - 198.0f;
	screenPositions[m]->c64DataDumpFontSize = 6.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	
	
	m = C64_SCREEN_LAYOUT_SHOW_STATES;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 5.0f;
	screenPositions[m]->c64StateVICX = 13.0f;
	screenPositions[m]->c64StateVICY = 13.0f;
	screenPositions[m]->c64StateVICIsVertical = false;

	screenPositions[m]->c64StateSIDVisible = true;
	screenPositions[m]->c64StateSIDFontSize = 5.0f;
	screenPositions[m]->c64StateSIDX = 0.0f;
	screenPositions[m]->c64StateSIDY = 195.0f;

	screenPositions[m]->c64StateCIAVisible = true;
	screenPositions[m]->c64StateCIAFontSize = 5.0f;
	screenPositions[m]->c64StateCIAX = 190.0f;
	screenPositions[m]->c64StateCIAY = 200.0f;

	screenPositions[m]->c64StateDrive1541Visible = true;
	screenPositions[m]->c64StateDrive1541FontSize = 5.0f;
	screenPositions[m]->c64StateDrive1541X = 190.0f;
	screenPositions[m]->c64StateDrive1541Y = 265.0f;
	screenPositions[m]->c64StateDrive1541RenderVIA1 = true;
	screenPositions[m]->c64StateDrive1541RenderVIA2 = true;
	screenPositions[m]->c64StateDrive1541RenderDriveLED = true;
	
	screenPositions[m]->c64DataDumpVisible = false;
	screenPositions[m]->drive1541DataDumpVisible = false;
	
	screenPositions[m]->emulationStateVisible = true;
	screenPositions[m]->emulationStateX = 371.0f;
	screenPositions[m]->emulationStateY = 350.0f;
	
	//
	m = C64_SCREEN_LAYOUT_MONITOR_CONSOLE;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->monitorConsoleVisible = true;
	screenPositions[m]->monitorConsoleX = 1.0f;
	screenPositions[m]->monitorConsoleY = 1.0f;
	screenPositions[m]->monitorConsoleFontScale = 1.25f;
	screenPositions[m]->monitorConsoleNumLines = 23;
	screenPositions[m]->monitorConsoleSizeX = 310.0f;
	screenPositions[m]->monitorConsoleSizeY = screenPositions[m]->c64ScreenSizeY + 10.5f;

	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 5.0f;
	screenPositions[m]->c64DisassembleX = 1.0f;
	screenPositions[m]->c64DisassembleY = 195.5f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 25.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-200.5f;
	screenPositions[m]->c64DisassembleNumberOfLines = 31;
	screenPositions[m]->c64DisassembleShowHexCodes = true;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 128.0f;
	screenPositions[m]->c64DataDumpY = 195.5f;
	screenPositions[m]->c64DataDumpSizeX = 252;
	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - 195.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 8;

	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapSizeX = 199.0f;
	screenPositions[m]->c64MemoryMapSizeY = 164.0f;
	screenPositions[m]->c64MemoryMapX = SCREEN_WIDTH-screenPositions[m]->c64MemoryMapSizeX;
	screenPositions[m]->c64MemoryMapY = 195.5f;

	// for replacements
	screenPositions[m]->drive1541DisassembleVisible = false;
	screenPositions[m]->drive1541DisassembleFontSize = 5.0f;
	screenPositions[m]->drive1541DisassembleX = 1.0f;
	screenPositions[m]->drive1541DisassembleY = 195.5f;
	screenPositions[m]->drive1541DisassembleSizeX = screenPositions[m]->drive1541DisassembleFontSize * 25.0f;
	screenPositions[m]->drive1541DisassembleSizeY = SCREEN_HEIGHT-200.5f;
	screenPositions[m]->drive1541DisassembleNumberOfLines = 31;
	screenPositions[m]->drive1541DisassembleShowHexCodes = true;
	screenPositions[m]->drive1541DisassembleShowCodeCycles = true;
	
	screenPositions[m]->drive1541DataDumpVisible = false;
	screenPositions[m]->drive1541DataDumpX = 128.0f;
	screenPositions[m]->drive1541DataDumpY = 195.5f;
	screenPositions[m]->drive1541DataDumpSizeX = 252;
	screenPositions[m]->drive1541DataDumpSizeY = SCREEN_HEIGHT - 195.0f;
	screenPositions[m]->drive1541DataDumpFontSize = 5.0f;
	screenPositions[m]->drive1541DataDumpGapAddress = screenPositions[m]->drive1541DataDumpFontSize;
	screenPositions[m]->drive1541DataDumpGapHexData = screenPositions[m]->drive1541DataDumpFontSize*0.5f;
	screenPositions[m]->drive1541DataDumpGapDataCharacters = screenPositions[m]->drive1541DataDumpFontSize*0.5f;
	screenPositions[m]->drive1541DataDumpNumberOfBytesPerLine = 8;
	
	screenPositions[m]->drive1541MemoryMapVisible = false;
	screenPositions[m]->drive1541MemoryMapSizeX = 199.0f;
	screenPositions[m]->drive1541MemoryMapSizeY = 164.0f;
	screenPositions[m]->drive1541MemoryMapX = SCREEN_WIDTH-screenPositions[m]->drive1541MemoryMapSizeX;
	screenPositions[m]->drive1541MemoryMapY = 195.5f;
	
	//
	m = C64_SCREEN_LAYOUT_CYCLER;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	
	screenPositions[m]->c64ScreenShowGridLines = true;
	screenPositions[m]->c64ScreenShowZoomedScreen = true;
	screenPositions[m]->c64ScreenZoomedX = 317;
	screenPositions[m]->c64ScreenZoomedY = 197;
	screenPositions[m]->c64ScreenZoomedSizeX = 260;
	screenPositions[m]->c64ScreenZoomedSizeY = 130; //108;
	
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 45.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleShowHexCodes = true;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	screenPositions[m]->c64DisassembleShowLabels = true;
	screenPositions[m]->c64DataDumpVisible = false;
//	screenPositions[m]->c64DataDumpX = 178.0f;
//	screenPositions[m]->c64DataDumpY = 195.0f;
//	screenPositions[m]->c64DataDumpSizeX = SCREEN_WIDTH - 110.0f;
//	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - 195.0f;
//	screenPositions[m]->c64DataDumpFontSize = 5.0f;
//	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize;
//	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.5f;
//	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
//	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 4.0f;
	screenPositions[m]->c64StateVICX = 320.0f;
	screenPositions[m]->c64StateVICY = 330.0f; //308.0f;
	screenPositions[m]->c64StateVICIsVertical = true;
	screenPositions[m]->c64StateVICShowSprites = false;

	//
	m = C64_SCREEN_LAYOUT_VIC_DISPLAY;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.35f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-1.0f;
	screenPositions[m]->c64ScreenY = 15.0f;
	
	screenPositions[m]->c64ScreenShowZoomedScreen = false;
	screenPositions[m]->c64ScreenZoomedSizeX = screenPositions[m]->c64ScreenSizeX;
	screenPositions[m]->c64ScreenZoomedSizeY = screenPositions[m]->c64ScreenSizeY;
	screenPositions[m]->c64ScreenZoomedX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64ScreenZoomedY = screenPositions[m]->c64ScreenY;
	
	screenPositions[m]->c64ScreenShowGridLines = false;
	
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-91.0f;
	screenPositions[m]->c64CpuStateY = 2.5f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 25.8f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->c64DisassembleShowHexCodes = false;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	screenPositions[m]->c64DisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->c64DisassembleShowLabels = true;
	screenPositions[m]->c64DisassembleNumberOfLabelCharacters = 10;
	screenPositions[m]->c64DataDumpVisible = false;
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 4.5f;
	screenPositions[m]->c64StateVICX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 11.5f;
	screenPositions[m]->c64StateVICY = 1.0f;
	screenPositions[m]->c64StateVICIsVertical = false;
	screenPositions[m]->c64StateVICShowSprites = true;
	
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 447 + 2.5f;
	screenPositions[m]->c64DataDumpY = 113;
	screenPositions[m]->c64DataDumpSizeX = 125.0f;
	screenPositions[m]->c64DataDumpSizeY = 34.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize*1.3f;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.51f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*2.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 8;

	screenPositions[m]->c64VicDisplayVisible = true;
	screenPositions[m]->c64VicDisplayScale = 1.031250f;
	screenPositions[m]->c64VicDisplayX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->c64VicDisplayY = 150.0f;
	screenPositions[m]->c64VicDisplayCanScrollDisassemble = true;

	screenPositions[m]->c64VicControlVisible = true;
	screenPositions[m]->c64VicControlFontSize = 8.25f;
	screenPositions[m]->c64VicControlX = screenPositions[m]->c64DisassembleFontSize * 73.0f + 10.5f;
	screenPositions[m]->c64VicControlY = 150.0f;

	//
	m = C64_SCREEN_LAYOUT_VIC_DISPLAY_LITE;
	screenPositions[m] = new C64ScreenLayout();
	scale = 0.35f;
	screenPositions[m]->c64ScreenVisible = false;
	
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 25.8f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->c64DisassembleShowHexCodes = false;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	screenPositions[m]->c64DisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->c64DisassembleShowLabels = true;
	screenPositions[m]->c64DisassembleNumberOfLabelCharacters = 10;
	screenPositions[m]->c64DataDumpVisible = false;
	
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->c64CpuStateY = 2.5f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->c64DataDumpY = 260;
	screenPositions[m]->c64DataDumpSizeX = 277.0f;
	screenPositions[m]->c64DataDumpSizeY = 97.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize*0.75f;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.28f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->c64DataDumpShowCharacters = false;
	screenPositions[m]->c64DataDumpShowSprites = false;
	
	screenPositions[m]->c64VicDisplayVisible = true;
	screenPositions[m]->c64VicDisplayScale = 1.23f;
	screenPositions[m]->c64VicDisplayX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->c64VicDisplayY = 13.0f;
	screenPositions[m]->c64VicDisplayCanScrollDisassemble = false;
	
	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapSizeX = 110.0f;
	screenPositions[m]->c64MemoryMapSizeY = 99.0f;
	screenPositions[m]->c64MemoryMapX = SCREEN_WIDTH-screenPositions[m]->c64MemoryMapSizeX-2.5f;
	screenPositions[m]->c64MemoryMapY = 260;
	
	//
	m = C64_SCREEN_LAYOUT_FULL_SCREEN_ZOOM;
	screenPositions[m] = new C64ScreenLayout();
	scale = (float)SCREEN_HEIGHT / (float)debugInterface->GetC64ScreenSizeY();
	screenPositions[m]->c64ScreenVisible = false;
	screenPositions[m]->c64ScreenShowZoomedScreen = true;
	
	screenPositions[m]->c64ScreenZoomedSizeX = (float)debugInterface->GetC64ScreenSizeX() * scale;
	screenPositions[m]->c64ScreenZoomedSizeY = (float)debugInterface->GetC64ScreenSizeY() * scale;
	screenPositions[m]->c64ScreenZoomedX = ((float)SCREEN_WIDTH-screenPositions[m]->c64ScreenZoomedSizeX)/2.0f;
	screenPositions[m]->c64ScreenZoomedY = 0.0f;

	
	frameCounter = 0;
	
	isShowingRasterCross = false;
	fontDisassemble = guiMain->fntConsole;
}

void CViewC64::SwitchToScreenLayout(int newScreenLayoutId)
{
	LOGD("SWITCH to screen layout id #%d", newScreenLayoutId);
	
	guiMain->LockMutex();

	if (c64SettingsIsInVicEditor)
	{
		viewVicEditor->DeactivateView();
		c64SettingsIsInVicEditor = false;
	}
	
	if (this->currentScreenLayoutId == C64_SCREEN_LAYOUT_VIC_DISPLAY)
	{
		viewC64->viewC64VicDisplay->DeactivateView();
	}
	
	this->currentScreenLayoutId = newScreenLayoutId;
	c64SettingsDefaultScreenLayoutId = newScreenLayoutId;
	
	
	C64ScreenLayout *screenLayout = screenPositions[currentScreenLayoutId];
	
	
	debugInterface->SetDebugOnC64(screenLayout->debugOnC64);
	debugInterface->SetDebugOnDrive1541(screenLayout->debugOnDrive1541);

	// screen
	viewC64Screen->SetVisible(screenLayout->c64ScreenVisible);
	viewC64Screen->SetPosition(screenLayout->c64ScreenX,
							   screenLayout->c64ScreenY, posZ,
							   screenLayout->c64ScreenSizeX,
							   screenLayout->c64ScreenSizeY);
	viewC64Screen->showGridLines = screenLayout->c64ScreenShowGridLines;
	
	// zoomed screen
	viewC64Screen->showZoomedScreen = screenLayout->c64ScreenShowZoomedScreen;
	viewC64Screen->SetZoomedScreenPos(screenLayout->c64ScreenZoomedX, screenLayout->c64ScreenZoomedY,
									  screenLayout->c64ScreenZoomedSizeX, screenLayout->c64ScreenZoomedSizeY);
	
	// disassemble
	viewC64Disassemble->SetVisible(screenLayout->c64DisassembleVisible);
	viewC64Disassemble->SetViewParameters(screenLayout->c64DisassembleX,
									screenLayout->c64DisassembleY, posZ,
									screenLayout->c64DisassembleSizeX, screenLayout->c64DisassembleSizeY,
									this->fontDisassemble,
									screenLayout->c64DisassembleFontSize,
									screenLayout->c64DisassembleNumberOfLines,
									screenLayout->c64DisassembleCodeMnemonicsOffset,
									screenLayout->c64DisassembleShowHexCodes,
									screenLayout->c64DisassembleShowCodeCycles,
									screenLayout->c64DisassembleCodeCyclesOffset,
									screenLayout->c64DisassembleShowLabels,
									screenLayout->c64DisassembleNumberOfLabelCharacters);
	
	viewDrive1541Disassemble->SetVisible(screenLayout->drive1541DisassembleVisible);
	viewDrive1541Disassemble->SetViewParameters(screenLayout->drive1541DisassembleX,
									screenLayout->drive1541DisassembleY, posZ,
									screenLayout->drive1541DisassembleSizeX, screenLayout->drive1541DisassembleSizeY,
									this->fontDisassemble,
									screenLayout->drive1541DisassembleFontSize,
									screenLayout->drive1541DisassembleNumberOfLines,
									screenLayout->drive1541DisassembleCodeMnemonicsOffset,
									screenLayout->drive1541DisassembleShowHexCodes,
									screenLayout->drive1541DisassembleShowCodeCycles,
									screenLayout->drive1541DisassembleCodeCyclesOffset,
									screenLayout->drive1541DisassembleShowLabels,
									screenLayout->drive1541DisassembleNumberOfLabelCharacters);
		
	// memory map
	viewC64MemoryMap->SetVisible(screenLayout->c64MemoryMapVisible);
	viewC64MemoryMap->SetPosition(screenLayout->c64MemoryMapX,
								  screenLayout->c64MemoryMapY, posZ,
								  screenLayout->c64MemoryMapSizeX,
								  screenLayout->c64MemoryMapSizeY);

	viewDrive1541MemoryMap->SetVisible(screenLayout->drive1541MemoryMapVisible);
	viewDrive1541MemoryMap->SetPosition(screenLayout->drive1541MemoryMapX,
									   screenLayout->drive1541MemoryMapY, posZ,
									   screenLayout->drive1541MemoryMapSizeX,
									   screenLayout->drive1541MemoryMapSizeY);
	
	// data dump
	viewC64MemoryDataDump->SetVisible(screenLayout->c64DataDumpVisible);
	viewC64MemoryDataDump->fontSize = screenLayout->c64DataDumpFontSize;
	viewC64MemoryDataDump->numberOfBytesPerLine = screenLayout->c64DataDumpNumberOfBytesPerLine;
	viewC64MemoryDataDump->SetPosition(screenLayout->c64DataDumpX,
									   screenLayout->c64DataDumpY, posZ,
									   screenLayout->c64DataDumpSizeX,
									   screenLayout->c64DataDumpSizeY);
	viewC64MemoryDataDump->gapAddress = screenLayout->c64DataDumpGapAddress;
	viewC64MemoryDataDump->gapHexData = screenLayout->c64DataDumpGapHexData;
	viewC64MemoryDataDump->gapDataCharacters = screenLayout->c64DataDumpGapDataCharacters;
	viewC64MemoryDataDump->showCharacters = screenLayout->c64DataDumpShowCharacters;
	viewC64MemoryDataDump->showSprites = screenLayout->c64DataDumpShowSprites;

	viewDrive1541MemoryDataDump->SetVisible(screenLayout->drive1541DataDumpVisible);
	viewDrive1541MemoryDataDump->fontSize = screenLayout->drive1541DataDumpFontSize;
	viewDrive1541MemoryDataDump->numberOfBytesPerLine = screenLayout->drive1541DataDumpNumberOfBytesPerLine;
	viewDrive1541MemoryDataDump->SetPosition(screenLayout->drive1541DataDumpX,
									   screenLayout->drive1541DataDumpY, posZ,
									   screenLayout->drive1541DataDumpSizeX,
									   screenLayout->drive1541DataDumpSizeY);
	viewDrive1541MemoryDataDump->gapAddress = screenLayout->drive1541DataDumpGapAddress;
	viewDrive1541MemoryDataDump->gapHexData = screenLayout->drive1541DataDumpGapHexData;
	viewDrive1541MemoryDataDump->gapDataCharacters = screenLayout->drive1541DataDumpGapDataCharacters;
	viewDrive1541MemoryDataDump->showCharacters = screenLayout->drive1541DataDumpShowCharacters;
	viewDrive1541MemoryDataDump->showSprites = screenLayout->drive1541DataDumpShowSprites;
	
	viewC64StateCIA->SetVisible(screenLayout->c64StateCIAVisible);
	viewC64StateCIA->SetPosition(screenLayout->c64StateCIAX, screenLayout->c64StateCIAY, posZ, 100, 100);
	viewC64StateCIA->fontSize = screenLayout->c64StateCIAFontSize;
	viewC64StateCIA->renderCIA1 = screenLayout->c64StateCIARenderCIA1;
	viewC64StateCIA->renderCIA2 = screenLayout->c64StateCIARenderCIA2;

	viewC64StateSID->SetVisible(screenLayout->c64StateSIDVisible);
	viewC64StateSID->SetPosition(screenLayout->c64StateSIDX, screenLayout->c64StateSIDY, posZ, 100, 100);
	viewC64StateSID->fontSize = screenLayout->c64StateSIDFontSize;

	viewC64StateVIC->SetVisible(screenLayout->c64StateVICVisible);
	viewC64StateVIC->SetPosition(screenLayout->c64StateVICX, screenLayout->c64StateVICY);
	viewC64StateVIC->fontSize = screenLayout->c64StateVICFontSize;
	viewC64StateVIC->isVertical = screenLayout->c64StateVICIsVertical;
	viewC64StateVIC->showSprites = screenLayout->c64StateVICShowSprites;

	viewC64StateDrive1541->SetVisible(screenLayout->c64StateDrive1541Visible);
	viewC64StateDrive1541->SetPosition(screenLayout->c64StateDrive1541X, screenLayout->c64StateDrive1541Y, posZ, 100, 100);
	viewC64StateDrive1541->fontSize = screenLayout->c64StateDrive1541FontSize;
	viewC64StateDrive1541->renderVIA1 = screenLayout->c64StateDrive1541RenderVIA1;
	viewC64StateDrive1541->renderVIA2 = screenLayout->c64StateDrive1541RenderVIA2;
	viewC64StateDrive1541->renderDriveLED = screenLayout->c64StateDrive1541RenderDriveLED;
	viewC64StateDrive1541->isVertical = screenLayout->c64StateDrive1541IsVertical;

	viewC64VicDisplay->SetVisible(screenLayout->c64VicDisplayVisible);
	viewC64VicDisplay->SetDisplayPosition(screenLayout->c64VicDisplayX,
										   screenLayout->c64VicDisplayY,
										   screenLayout->c64VicDisplayScale, false);
	viewC64VicDisplay->canScrollDisassemble = screenLayout->c64VicDisplayCanScrollDisassemble;
	
	viewC64VicControl->SetVisible(screenLayout->c64VicControlVisible);
	viewC64VicControl->fontSize = screenLayout->c64VicControlFontSize;
	viewC64VicControl->SetPosition(screenLayout->c64VicControlX,
								   screenLayout->c64VicControlY);
	
	
	viewEmulationState->SetVisible(screenLayout->emulationStateVisible);
	viewEmulationState->SetPosition(screenLayout->emulationStateX, screenLayout->emulationStateY, posZ, 100, 100);
	
	viewMonitorConsole->SetVisible(screenLayout->monitorConsoleVisible);
	viewMonitorConsole->SetPosition(screenLayout->monitorConsoleX, screenLayout->monitorConsoleY, posZ,
									screenLayout->monitorConsoleSizeX, screenLayout->monitorConsoleSizeY,
									screenLayout->monitorConsoleFontScale, screenLayout->monitorConsoleNumLines);
	
	// cpu state
	viewC64StateCPU->SetVisible(screenLayout->c64CpuStateVisible);
	viewC64StateCPU->SetPosition(screenLayout->c64CpuStateX, screenLayout->c64CpuStateY);
	viewC64StateCPU->SetFont(this->fontDisassemble, screenLayout->c64CpuStateFontSize);
	
	viewDriveStateCPU->SetVisible(screenLayout->drive1541CpuStateVisible);
	viewDriveStateCPU->SetPosition(screenLayout->drive1541CpuStateX, screenLayout->drive1541CpuStateY);
	viewDriveStateCPU->SetFont(this->fontDisassemble, screenLayout->drive1541CpuStateFontSize);
	
	//
	// bunch of workarounds must be here, as always
	//
	
//	SetFocus(viewMonitorConsole);
	SetFocus(viewC64Screen);
	
	if (newScreenLayoutId == C64_SCREEN_LAYOUT_VIC_DISPLAY)
	{
		viewC64->viewC64VicDisplay->ActivateView();
	}
	
	CheckMouseCursorVisibility();
	
	// end of workarounds

	if (guiMain->currentView != this)
		guiMain->SetView(this);
	
	
	guiMain->UnlockMutex();
}

void CViewC64::ThreadRun(void *data)
{
	ThreadSetName("c64");

	LOGD("CViewC64::ThreadRun");
	
	isEmulationThreadRunning = true;
	this->debugInterface->RunEmulationThread();
	
	LOGD("CViewC64::ThreadRun: finished");
}

void CViewC64::DoLogic()
{
//	viewC64MemoryMap->DoLogic();
//	viewDrive1541MemoryMap->DoLogic();
	
//	if (nextScreenUpdateFrame < frameCounter)
//	{
//		//RefreshScreen();
//
//		nextScreenUpdateFrame = frameCounter;
//		
//	}

//	CGuiView::DoLogic();
	
}

void CViewC64::Render()
{
//	guiMain->fntConsole->BlitText("CViewC64", 0, 0, 0, 31, 1.0);
//	Blit(guiMain->imgConsoleFonts, 50, 50, -1, 200, 200);
//	BlitRectangle(50, 50, -1, 200, 200, 1, 0, 0, 1);
	
	viewC64MemoryMap->CellsAnimationLogic();
	viewDrive1541MemoryMap->CellsAnimationLogic();

	// workaround
	if (viewDrive1541MemoryDataDump->visible)
	{
		// TODO: this is a workaround, we need to store memory cells state in different object than a memory map view!
		// and run it once per frame if needed!!
		// workaround: run logic for cells in drive ROM area because it is not done by memory map view because it is not being displayed
		viewC64->viewDrive1541MemoryMap->DriveROMCellsAnimationLogic();
	}
	

	frameCounter++;
	
//	if (frameCounter % 2 == 0)
	{
		//if (viewC64Screen->visible)   always do this anyway
		{
			viewC64Screen->RefreshScreen();
		}
	}
	
	//////////

	// copy current state of VIC
	c64d_vicii_copy_state(&(this->currentViciiState));

	viewC64VicDisplay->UpdateViciiState();
	
	int rasterX = viciiStateToShow.raster_cycle*8;
	int rasterY = viciiStateToShow.raster_line;
	
	// update current colors for rendering states
	
	this->rasterToShowX = rasterX;
	this->rasterToShowY = rasterY;
	this->rasterCharToShowX = (viewC64->viciiStateToShow.raster_cycle - 0x11);
	this->rasterCharToShowY = (viewC64->viciiStateToShow.raster_line - 0x32) / 8;
	
	//LOGD("       |   rasterCharToShowX=%3d rasterCharToShowY=%3d", rasterCharToShowX, rasterCharToShowY);
	
	if (rasterCharToShowX < 0)
	{
		rasterCharToShowX = 0;
	}
	else if (rasterCharToShowX > 39)
	{
		rasterCharToShowX = 39;
	}
	
	if (rasterCharToShowY < 0)
	{
		rasterCharToShowY = 0;
	}
	else if (rasterCharToShowY > 24)
	{
		rasterCharToShowY = 24;
	}
	
	// get current VIC State's pointers and colors
	u8 *screen_ptr;
	u8 *color_ram_ptr;
	u8 *chargen_ptr;
	u8 *bitmap_low_ptr;
	u8 *bitmap_high_ptr;
	
	viewC64->viewC64VicDisplay->GetViciiPointers(&(viewC64->viciiStateToShow),
												 &screen_ptr, &color_ram_ptr, &chargen_ptr, &bitmap_low_ptr, &bitmap_high_ptr,
												 this->colorsToShow);

	if (viewC64StateVIC->forceColorD800 == -1)
	{
		this->colorToShowD800 = color_ram_ptr[ rasterCharToShowY * 40 + rasterCharToShowX ] & 0x0F;
	}
	else
	{
		this->colorToShowD800 = viewC64StateVIC->forceColorD800;
	}

	// force D020-D02E colors?
	for (int i = 0; i < 0x0F; i++)
	{
		if (viewC64StateVIC->forceColors[i] != -1)
		{
			colorsToShow[i] = viewC64StateVIC->forceColors[i];
			viewC64->viciiStateToShow.regs[0x20 + i] = viewC64StateVIC->forceColors[i];
		}
	}
	
	//////////
	
	if (viewC64VicDisplay->canScrollDisassemble)
	{
		viewC64Disassemble->SetCurrentPC(viciiStateToShow.lastValidPC);
	}
	else
	{
		viewC64Disassemble->SetCurrentPC(this->currentViciiState.lastValidPC);
	}
	
	/// 1541 CPU
	C64StateCPU diskCpuState;
	debugInterface->GetDrive1541CpuState(&diskCpuState);
	
	viewDrive1541Disassemble->SetCurrentPC(diskCpuState.lastValidPC);
	
	//
	// now render all visible views
	//
	//
	
	CGuiView::Render();

	//
	// and stuff what is left to render:
	//
	
	if (isShowingRasterCross && viewC64->viewC64Screen->visible)
	{
		viewC64Screen->RenderRaster(rasterX, rasterY);
	}
	
	if (viewC64Screen->showZoomedScreen)
	{
		viewC64Screen->RenderZoomedScreen(rasterX, rasterY);
	}

	// render focus border
	if (focusElement != NULL && currentScreenLayoutId != C64_SCREEN_LAYOUT_C64_ONLY)
	{
		focusElement->RenderFocusBorder();
	}
	
//	// debug render fps
//	char buf[128];
//	sprintf(buf, "%-6.2f %-6.2f", debugInterface->emulationSpeed, debugInterface->emulationFrameRate);
//	
//	guiMain->fntConsole->BlitText(buf, 0, 0, -1, 15);

	
}

///////////////





void CViewC64::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CViewC64::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewC64::ButtonPressed(CGuiButton *button)
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

bool CViewC64::ProcessGlobalKeyboardShortcut(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	keyCode = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	std::list<u32> zones;
	zones.push_back(KBZONE_GLOBAL);
	CSlrKeyboardShortcut *shortcut = this->keyboardShortcuts->FindShortcut(zones, keyCode, isShift, isAlt, isControl);
	
	if (shortcut != NULL)
	{
		//shortcut->DebugPrint();
		
		viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		
		if (viewC64Snapshots->ProcessKeyboardShortcut(shortcut))
			return true;
		
		if (shortcut == viewC64MainMenu->kbsMainMenuScreen)
		{
			viewC64MainMenu->SwitchMainMenuScreen();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout1)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_ONLY);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout2)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_DATA_DUMP);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout3)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_DEBUGGER);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout4)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_1541_MEMORY_MAP);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout5)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_SHOW_STATES);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout6)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_MEMORY_MAP);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout7)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_C64_1541_DEBUGGER);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout8)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_MONITOR_CONSOLE);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout9)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_FULL_SCREEN_ZOOM);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout10)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_CYCLER);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout11)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_VIC_DISPLAY_LITE);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout12)
		{
			SwitchToScreenLayout(C64_SCREEN_LAYOUT_VIC_DISPLAY);
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsVicEditorScreen)
		{
			viewVicEditor->SwitchToVicEditor();
			c64SettingsIsInVicEditor = true;
			C64DebuggerStoreSettings();
		}
		else if (shortcut == viewC64MainMenu->kbsInsertD64)
		{
			viewC64MainMenu->OpenDialogInsertD64();
		}
		else if (shortcut == viewC64MainMenu->kbsInsertCartridge)
		{
			viewC64MainMenu->OpenDialogInsertCartridge();
		}
		else if (shortcut == viewC64MainMenu->kbsLoadPRG)
		{
			viewC64MainMenu->OpenDialogLoadPRG();
		}
		else if (shortcut == viewC64MainMenu->kbsReloadAndRestart
				 || shortcut == viewC64MainMenu->kbsRestartPRG)
		{
			viewC64MainMenu->ReloadAndRestartPRG();
		}
		else if (shortcut == viewC64SettingsMenu->kbsDumpC64Memory)
		{
			viewC64SettingsMenu->OpenDialogDumpC64Memory();
		}
		else if (shortcut == viewC64SettingsMenu->kbsDumpDrive1541Memory)
		{
			viewC64SettingsMenu->OpenDialogDumpDrive1541Memory();
		}
		else if (shortcut == viewC64SettingsMenu->kbsSwitchNextMaximumSpeed)
		{
			viewC64SettingsMenu->SwitchNextMaximumSpeed();
		}
		else if (shortcut == viewC64SettingsMenu->kbsSwitchPrevMaximumSpeed)
		{
			viewC64SettingsMenu->SwitchPrevMaximumSpeed();
		}
		else if (shortcut == viewC64SettingsMenu->kbsIsWarpSpeed)
		{
			SwitchIsWarpSpeed();
		}
		else if (shortcut == viewC64MainMenu->kbsDiskDriveReset)
		{
			debugInterface->DiskDriveReset();
		}
		else if (shortcut == viewC64MainMenu->kbsSoftReset)
		{
			debugInterface->Reset();
		}
		else if (shortcut == viewC64MainMenu->kbsHardReset)
		{
			debugInterface->HardReset();
			viewC64MemoryMap->ClearExecuteMarkers();
			viewC64->viewDrive1541MemoryMap->ClearExecuteMarkers();
		}
		else if (shortcut == viewC64MainMenu->kbsBreakpoints)
		{
			viewC64Breakpoints->SwitchBreakpointsScreen();
		}
		else if (shortcut == viewC64MainMenu->kbsSnapshots)
		{
			viewC64Snapshots->SwitchSnapshotsScreen();
		}
		else if (shortcut == viewC64SettingsMenu->kbsUseKeboardAsJoystick)
		{
			SwitchUseKeyboardAsJoystick();
		}
		else if (shortcut == viewC64MainMenu->kbsStepOverInstruction)
		{
			StepOverInstruction();
		}
		else if (shortcut == viewC64MainMenu->kbsStepOneCycle)
		{
			StepOneCycle();
		}
		else if (shortcut == viewC64MainMenu->kbsRunContinueEmulation)
		{
			RunContinueEmulation();
		}
		else if (shortcut == viewC64MainMenu->kbsIsDataDirectlyFromRam)
		{
			SwitchIsDataDirectlyFromRam();
		}
		else if (shortcut == viewC64MainMenu->kbsToggleMulticolorImageDump)
		{
			SwitchIsMulticolorDataDump();
		}
		else if (shortcut == viewC64MainMenu->kbsShowRasterBeam)
		{
			SwitchIsShowRasterBeam();
		}
		else if (shortcut == viewC64MainMenu->kbsMoveFocusToNextView)
		{
			MoveFocusToNextView();
		}
		else if (shortcut == viewC64MainMenu->kbsMoveFocusToPreviousView)
		{
			MoveFocusToPrevView();
		}
		else if (shortcut == viewC64SettingsMenu->kbsCartridgeFreezeButton)
		{
			debugInterface->CartridgeFreezeButtonPressed();
		}
		else if (shortcut == viewC64SettingsMenu->kbsClearMemoryMarkers)
		{
			viewC64SettingsMenu->ClearMemoryMarkers();
		}
		else if (shortcut == viewC64MainMenu->kbsBrowseD64)
		{
			viewFileD64->StartBrowsingD64(0);
		}
		else if (shortcut == viewC64MainMenu->kbsStartFromDisk)
		{
			viewFileD64->StartFirstDiskPRGEntry();
		}
		else if (shortcut == viewC64MainMenu->kbsSaveScreenImageAsPNG)
		{
			viewVicEditor->SaveScreenshotAsPNG();
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachEverything)
		{
			viewC64SettingsMenu->DetachEverything();
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachCartridge)
		{
			viewC64SettingsMenu->DetachCartridge();
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachDiskImage)
		{
			viewC64SettingsMenu->DetachDiskImage();
		}
		else if (shortcut == viewC64SettingsMenu->kbsAutoJmpFromInsertedDiskFirstPrg)
		{
			viewC64SettingsMenu->ToggleAutoLoadFromInsertedDisk();
		}
		
		return true;
	}
	
	return false;
}

void CViewC64::SwitchIsMulticolorDataDump()
{
	viewC64MemoryDataDump->renderDataWithColors = !viewC64MemoryDataDump->renderDataWithColors;
}

void CViewC64::SwitchIsShowRasterBeam()
{
	this->isShowingRasterCross = !this->isShowingRasterCross;
}

void CViewC64::StepOverInstruction()
{
	if (debugInterface->GetDebugMode() == C64_DEBUG_RUNNING)
	{
		debugInterface->SetTemporaryC64BreakpointPC(false);
		debugInterface->SetTemporaryDrive1541BreakpointPC(false);
	}
	
	debugInterface->SetDebugMode(C64_DEBUG_RUN_ONE_INSTRUCTION);
}

void CViewC64::StepOneCycle()
{
	if (debugInterface->GetDebugMode() == C64_DEBUG_RUNNING)
	{
		debugInterface->SetTemporaryC64BreakpointPC(false);
		debugInterface->SetTemporaryDrive1541BreakpointPC(false);
	}
	
	debugInterface->SetDebugMode(C64_DEBUG_RUN_ONE_CYCLE);
}

void CViewC64::RunContinueEmulation()
{
	debugInterface->SetTemporaryC64BreakpointPC(false);
	debugInterface->SetTemporaryDrive1541BreakpointPC(false);
	debugInterface->SetDebugMode(C64_DEBUG_RUNNING);
}

void CViewC64::SwitchIsWarpSpeed()
{
	viewC64SettingsMenu->menuItemIsWarpSpeed->SwitchToNext();
}

void CViewC64::SwitchScreenLayout()
{
	int newScreenLayoutId = currentScreenLayoutId + 1;
	if (newScreenLayoutId == C64_SCREEN_LAYOUT_MAX)
	{
		newScreenLayoutId = C64_SCREEN_LAYOUT_C64_ONLY;
	}
	
	SwitchToScreenLayout(newScreenLayoutId);
}

void CViewC64::SwitchUseKeyboardAsJoystick()
{
	viewC64SettingsMenu->menuItemUseKeyboardAsJoystick->SwitchToNext();
}

void CViewC64::SwitchIsDataDirectlyFromRam()
{
	if (viewC64MemoryMap->isDataDirectlyFromRAM == false)
	{
		viewC64MemoryMap->isDataDirectlyFromRAM = true;
		viewC64MemoryDataDump->SetDataAdapter(debugInterface->dataAdapterC64DirectRam);
		viewDrive1541MemoryMap->isDataDirectlyFromRAM = true;
		viewDrive1541MemoryDataDump->SetDataAdapter(debugInterface->dataAdapterDrive1541DirectRam);
	}
	else
	{
		viewC64MemoryMap->isDataDirectlyFromRAM = false;
		viewC64MemoryDataDump->SetDataAdapter(debugInterface->dataAdapterC64);
		viewDrive1541MemoryMap->isDataDirectlyFromRAM = false;
		viewDrive1541MemoryDataDump->SetDataAdapter(debugInterface->dataAdapterDrive1541);
	}
}

bool CViewC64::CanSelectView(CGuiView *view)
{
	if (view->visible && view != viewC64MemoryMap && view != viewDrive1541MemoryMap)
		return true;
	
	return false;
}


void CViewC64::MoveFocusToNextView()
{
	if (focusElement == NULL)
	{
		SetFocus(traversalOfViews[0]);
		return;
	}
	
	int selectedViewNum = -1;
	
	for (int i = 0; i < traversalOfViews.size(); i++)
	{
		CGuiView *view = traversalOfViews[i];
		if (view == focusElement)
		{
			selectedViewNum = i;
			break;
		}
	}
	
	CGuiView *newView = NULL;
	for (int z = 0; z < traversalOfViews.size(); z++)
	{
		selectedViewNum++;
		if (selectedViewNum == traversalOfViews.size())
		{
			selectedViewNum = 0;
		}

		newView = traversalOfViews[selectedViewNum];
		if (CanSelectView(newView))
			break;
	}
	
	if (CanSelectView(newView))
	{
		SetFocus(traversalOfViews[selectedViewNum]);
	}
	else
	{
		LOGError("CViewC64::MoveFocusToNextView: no visible views");
	}
	
}

void CViewC64::MoveFocusToPrevView()
{
	if (focusElement == NULL)
	{
		SetFocus(traversalOfViews[0]);
		return;
	}
	
	int selectedViewNum = -1;
	
	for (int i = 0; i < traversalOfViews.size(); i++)
	{
		CGuiView *view = traversalOfViews[i];
		if (view == focusElement)
		{
			selectedViewNum = i;
			break;
		}
	}
	
	if (selectedViewNum == -1)
	{
		LOGError("CViewC64::MoveFocusToPrevView: selected view not found");
		return;
	}
	
	CGuiView *newView = NULL;
	for (int z = 0; z < traversalOfViews.size(); z++)
	{
		selectedViewNum--;
		if (selectedViewNum == -1)
		{
			selectedViewNum = traversalOfViews.size()-1;
		}
		
		newView = traversalOfViews[selectedViewNum];
		if (CanSelectView(newView))
			break;
	}
	
	if (CanSelectView(newView))
	{
		SetFocus(traversalOfViews[selectedViewNum]);
	}
	else
	{
		LOGError("CViewC64::MoveFocusToNextView: no visible views");
	}
}


bool CViewC64::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CViewC64::KeyDown, keyCode=%4.4x (%d) %c", keyCode, keyCode, keyCode);
	
//	if (keyCode == MTKEY_F2)
//	{
//		LOGD("@");
//		((C64DebugInterfaceVice *)viewC64->debugInterface)->MakeBasicRunC64();
////		((C64DebugInterfaceVice *)viewC64->debugInterface)->SetStackPointerC64(0xFF);
////		((C64DebugInterfaceVice *)viewC64->debugInterface)->SetRegisterA1541(0xFF);
//	}
	
//	// debug only
//	if (keyCode == MTKEY_F7 && isShift)
//	{
//		debugInterface->MakeJmpC64(0x2000);
//		return true;
//	}
//	
//	if (keyCode == MTKEY_F8 && isShift)
//	{
//		AddDebugCode();
//		return true;
//	}
//
//	
//	if (keyCode == MTKEY_F8 && isShift)
//	{
////		debugInterface->SetC64ModelType(4);
//		
//		MapC64MemoryToFile ("/Users/mars/memorymap");
//		guiMain->ShowMessage("mapped");
//		return true;
//	}

	
	//
	// this is very nasty UX workaround just for now only
	//
	if (this->currentScreenLayoutId == C64_SCREEN_LAYOUT_VIC_DISPLAY)
	{
		if (this->focusElement == NULL)
		{
			if (viewC64VicDisplay->KeyDown(keyCode, isShift, isAlt, isControl))
				return true;
		}
	}
	
	//
	// another nasty UX workaround
	//
	if (viewC64MemoryMap->visible)
	{
		if (keyCode == MTKEY_SPACEBAR && !isShift && !isAlt && !isControl)
		{
			if (viewC64MemoryMap->IsInside(guiMain->mousePosX, guiMain->mousePosY))
			{
				this->SetFocus(viewC64MemoryMap);
				if (viewC64MemoryMap->KeyDown(keyCode, isShift, isAlt, isControl))
					return true;
			}
		}
	}
	
	///
	
	
	if (keyCode >= MTKEY_F1 && keyCode <= MTKEY_F8 && !isControl)
	{
		if (viewC64Screen->hasFocus)
		{
			return viewC64Screen->KeyDown(keyCode, isShift, isAlt, isControl);
		}
	}

	if (viewC64->ProcessGlobalKeyboardShortcut(keyCode, isShift, isAlt, isControl))
	{
		// when global key shortcut is detected
		// send key up for shift/alt/ctrl to the c64
		viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		
		keyDownCodes.push_back(keyCode);
		
		return true;
	}
	
	// TODO: this is a temporary UX workaround for step over jsr
	CSlrKeyboardShortcut *shortcut = this->keyboardShortcuts->FindShortcut(KBZONE_DISASSEMBLE, keyCode, isShift, isAlt, isControl);

	if (shortcut == keyboardShortcuts->kbsStepOverJsr)
	{
		if (focusElement != viewDrive1541Disassemble && viewC64Disassemble->visible)
		{
			viewC64Disassemble->StepOverJsr();
			return true;
		}
		if (focusElement != viewC64Disassemble && viewDrive1541Disassemble->visible)
		{
			viewDrive1541Disassemble->StepOverJsr();
			return true;
		}
	}
	
	//
	// end of UX workarounds
	//
	
	if (focusElement != NULL)
	{
		if (focusElement->KeyDown(keyCode, isShift, isAlt, isControl))
		{
			keyDownCodes.push_back(keyCode);
			return true;
		}
	}

	if (viewC64Screen->hasFocus)
	{
		return viewC64Screen->KeyDown(keyCode, isShift, isAlt, isControl);
	}
	
	return true; //CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CViewC64::KeyUp, keyCode=%d isShift=%d isAlt=%d isControl=%d", keyCode, isShift, isAlt, isControl);

	if (keyCode >= MTKEY_F1 && keyCode <= MTKEY_F8 && !guiMain->isControlPressed)
	{
		return viewC64Screen->KeyUp(keyCode, isShift, isAlt, isControl);
	}

	// check if shortcut
	std::list<u32> zones;
	zones.push_back(KBZONE_GLOBAL);
	CSlrKeyboardShortcut *shortcut = this->keyboardShortcuts->FindShortcut(zones, keyCode, isShift, isAlt, isControl);
	if (shortcut != NULL)
		return true;

	if (focusElement != NULL)
	{
		if (focusElement->KeyUp(keyCode, isShift, isAlt, isControl))
		{
			keyDownCodes.remove(keyCode);
			return true;
		}
	}

	for (std::list<u32>::iterator it = keyDownCodes.begin(); it != keyDownCodes.end(); it++)
	{
		if (keyCode == *it)
		{
			keyDownCodes.remove(keyCode);
			return true;
		}
	}
	
	viewC64Screen->KeyUp(keyCode, isShift, isAlt, isControl);
	
	return true; //CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}



//@returns is consumed
bool CViewC64::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64::DoTap:  x=%f y=%f", x, y);

	// TODO: this is a crude workaround to fix problem that c64 zoomed screen is the same instance of the c64 screen, which must be split
	//       do not ever do this at home kids
	
	if (viewC64Screen->showZoomedScreen)
	{
		if (viewC64Screen->IsInsideViewNonVisible(x, y))
		{
			guiMain->SetFocus(viewC64Screen);
			this->focusElement = viewC64Screen;
			return viewC64Screen->DoTap(x, y);
		}
		else
		{
			viewC64Screen->hasFocus = false;
			if (guiMain->focusElement == viewC64Screen)
			{
				guiMain->focusElement = NULL;
				this->focusElement = NULL;
			}
		}
	}
	else
	{
		if (viewC64Screen->IsInsideView(x, y) == false && viewC64Screen->hasFocus == true)
		{
			viewC64Screen->hasFocus = false;
			if (guiMain->focusElement == viewC64Screen
				|| this->focusElement == viewC64Screen)
			{
				guiMain->focusElement = NULL;
				this->focusElement = NULL;
			}
		}
	}
	
	// TODO: end of crude workaround
	//
	
	
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		LOGG("check inside=%s", guiElement->name);
		
		if (guiElement->IsInside(x, y))
		{
			LOGG("... is inside=%s", guiElement->name);

			// let view decide what to do even if it does not have focus
			guiElement->DoTap(x, y);

			if (guiElement->hasFocus == false)
			{
				SetFocus((CGuiView *)guiElement);
			}
		}
	}

	return true;
	
	//return CGuiView::DoTap(x, y);
}

// scroll only where cursor is moving
bool CViewC64::DoNotTouchedMove(GLfloat x, GLfloat y)
{
//	LOGG("CViewC64::DoNotTouchedMove, mouseCursor=%f %f", mouseCursorX, mouseCursorY);

	mouseCursorX = x;
	mouseCursorY = y;
	return CGuiView::DoNotTouchedMove(x, y);
}

bool CViewC64::DoScrollWheel(float deltaX, float deltaY)
{
//	LOGG("CViewC64::DoScrollWheel, mouseCursor=%f %f", mouseCursorX, mouseCursorY);

	// first scroll if mouse cursor is on element
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->IsInside(mouseCursorX, mouseCursorY))
		{
			guiElement->DoScrollWheel(deltaX, deltaY);
			return true;
		}
	}
	
	// if not then by focus
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
	
		if (guiElement->hasFocus == false)
			continue;
		
		if (guiElement->DoScrollWheel(deltaX, deltaY))
			return true;
	}
	
	return false;
}


bool CViewC64::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewC64::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewC64::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewC64::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewC64::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewC64::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewC64::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewC64::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewC64::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewC64::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewC64::ActivateView()
{
	LOGG("CViewC64::ActivateView()");
}

void CViewC64::DeactivateView()
{
	LOGG("CViewC64::DeactivateView()");
}

void CViewC64::ApplicationEnteredBackground()
{
	LOGD("CViewC64::ApplicationEnteredBackground");
	viewC64Screen->KeyUpModifierKeys(true, true, true);
}

void CViewC64::ApplicationEnteredForeground()
{
	LOGD("CViewC64::ApplicationEnteredForeground");
	viewC64Screen->KeyUpModifierKeys(true, true, true);
}

void CViewC64::CreateFonts()
{
//	u64 t1 = SYS_GetCurrentTimeInMillis();

	uint8 *charRom = debugInterfaceVice->GetCharRom();
	
	uint8 *charData;
	
	charData = charRom;
	fontCBM1 = ProcessCBMFonts(charData, true);

	charData = charRom + 0x0800;
	fontCBM2 = ProcessCBMFonts(charData, true);

	fontCBMShifted = ProcessCBMFonts(charData, false);

//	u64 t2 = SYS_GetCurrentTimeInMillis();
//	LOGD("time=%u", t2-t1);
	
}

///
void CViewC64::MapC64MemoryToFile(char *filePath)
{
	mappedC64Memory = SYS_MapMemoryToFile(C64_RAM_SIZE, filePath, (void**)&mappedC64MemoryDescriptor);
}

void CViewC64::UnMapC64MemoryFromFile()
{
	SYS_UnMapMemoryFromFile(mappedC64Memory, C64_RAM_SIZE, (void**)&mappedC64MemoryDescriptor);
	mappedC64Memory = NULL;
	mappedC64MemoryDescriptor = NULL;
}

void CViewC64::SharedMemorySignalCallback(CByteBuffer *sharedMemoryData)
{
	C64DebuggerReceivedConfiguration(sharedMemoryData);
}

void CViewC64::InitRasterColors()
{
	viewC64VicDisplay->InitRasterColorsFromScheme();
	viewC64Screen->InitRasterColorsFromScheme();
	viewVicEditor->viewVicDisplayMain->InitGridLinesColorFromSettings();
}

void CViewC64::CheckMouseCursorVisibility()
{
	if (guiMain->currentView == this
		&& this->currentScreenLayoutId == C64_SCREEN_LAYOUT_C64_ONLY
		&& VID_IsWindowFullScreen())
	{
		VID_HideMouseCursor();
	}
	else
	{
		VID_ShowMouseCursor();
	}
}

void CViewC64::ShowMouseCursor()
{
	VID_ShowMouseCursor();
}

void CViewC64::ShowDialogOpenFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFolder,
						CSlrString *windowTitle)
{
	if (c64SettingsUseSystemFileDialogs)
	{
		SYS_DialogOpenFile(callback, extensions, defaultFolder, windowTitle);
	}
	else
	{
		fileDialogPreviousView = guiMain->currentView;
		systemFileDialogCallback = callback;
		
		char *cDirectoryPath;
		if (defaultFolder != NULL)
		{
			cDirectoryPath = defaultFolder->GetStdASCII();
		}
		else
		{
			cDirectoryPath = UTFALLOC("/");
		}
		
		std::list<char *> *cExtensions = new std::list<char *>();
		for (std::list<CSlrString *>::iterator it = extensions->begin(); it != extensions->end(); it++)
		{
			CSlrString *ext = *it;
			char *cExt = ext->GetStdASCII();
			cExtensions->push_back(cExt);
		}
		
		viewSelectFile->Init(cDirectoryPath, cExtensions);
		guiMain->SetView(viewSelectFile);
	}
}

void CViewC64::FileSelected(UTFString *filePath)
{
	CSlrString *file = new CSlrString(filePath);
	
	systemFileDialogCallback->SystemDialogFileOpenSelected(file);
	guiMain->SetView(fileDialogPreviousView);
}

void CViewC64::FileSelectionCancelled()
{
	systemFileDialogCallback->SystemDialogFileOpenCancelled();
	guiMain->SetView(fileDialogPreviousView);
}

void CViewC64::ShowDialogSaveFile(CSystemFileDialogCallback *callback, std::list<CSlrString *> *extensions,
						CSlrString *defaultFileName, CSlrString *defaultFolder,
						CSlrString *windowTitle)
{
	if (c64SettingsUseSystemFileDialogs)
	{
		SYS_DialogSaveFile(callback, extensions, defaultFileName, defaultFolder, windowTitle);
	}
	else
	{
		fileDialogPreviousView = guiMain->currentView;
		systemFileDialogCallback = callback;
	
		char *cDirectoryPath;
		if (defaultFolder != NULL)
		{
			cDirectoryPath = defaultFolder->GetStdASCII();
		}
		else
		{
			cDirectoryPath = UTFALLOC("/");
		}
		
		CSlrString *firstExtension = extensions->front();
		char *cSaveExtension = firstExtension->GetStdASCII();
		
		char *cDefaultFileName = defaultFileName->GetStdASCII();
		
		viewSaveFile->Init(cDefaultFileName, cSaveExtension, cDirectoryPath);
		guiMain->SetView(viewSaveFile);
	}
}

void CViewC64::SaveFileSelected(UTFString *fullFilePath, char *fileName)
{
	CSlrString *file = new CSlrString(fullFilePath);
	
	systemFileDialogCallback->SystemDialogFileSaveSelected(file);
	guiMain->SetView(fileDialogPreviousView);

}

void CViewC64::SaveFileSelectionCancelled()
{
	systemFileDialogCallback->SystemDialogFileSaveCancelled();
	guiMain->SetView(fileDialogPreviousView);
}


C64ScreenLayout::C64ScreenLayout()
{
	c64ScreenVisible = false;
	c64CpuStateVisible = false;
	drive1541CpuStateVisible = false;
	c64DisassembleVisible = false;
	drive1541DisassembleVisible = false;
	c64MemoryMapVisible = false;
	drive1541MemoryMapVisible = false;
	c64DataDumpVisible = false;
	drive1541DataDumpVisible = false;
	c64StateCIAVisible = false;
	c64StateSIDVisible = false;
	c64StateVICVisible = false;
	c64StateDrive1541Visible = false;
	monitorConsoleVisible = false;
	emulationStateVisible = false;
	
	c64ScreenX = c64ScreenY = c64ScreenSizeX = c64ScreenSizeY = c64CpuStateX = c64CpuStateY = drive1541CpuStateX = drive1541CpuStateY = c64DisassembleX = c64DisassembleY = drive1541DisassembleX = drive1541DisassembleY = c64MemoryMapX = c64MemoryMapY = c64MemoryMapSizeX = c64MemoryMapSizeY = drive1541MemoryMapX = drive1541MemoryMapY = drive1541MemoryMapSizeX = drive1541MemoryMapSizeY = c64DataDumpX = c64DataDumpY = c64DataDumpSizeX = c64DataDumpSizeY = c64StateCIAX = c64StateCIAY = c64StateSIDX = c64StateSIDY = c64StateVICX = c64StateVICY = c64StateDrive1541X = c64StateDrive1541Y = c64VicDisplayX = c64VicDisplayY = monitorConsoleX = monitorConsoleY = emulationStateX = emulationStateY = 0;

	c64ScreenShowGridLines = false;
	c64ScreenShowZoomedScreen = false;
	c64ScreenZoomedX = c64ScreenZoomedY = c64ScreenZoomedSizeX = c64ScreenZoomedSizeY = 0;
	
	c64CpuStateFontSize = 5.0f;
	drive1541CpuStateFontSize = 5.0f;

	c64DataDumpFontSize = 5.0f;
	c64DataDumpGapAddress = c64DataDumpFontSize;
	c64DataDumpGapHexData = c64DataDumpFontSize*0.5f;
	c64DataDumpGapDataCharacters = c64DataDumpFontSize*0.5f;
	c64DataDumpNumberOfBytesPerLine = 8;
	c64DataDumpShowCharacters = true;
	c64DataDumpShowSprites = true;

	drive1541DataDumpFontSize = 5.0f;
	drive1541DataDumpGapAddress = drive1541DataDumpFontSize;
	drive1541DataDumpGapHexData = drive1541DataDumpFontSize*0.5f;
	drive1541DataDumpGapDataCharacters = drive1541DataDumpFontSize*0.5f;
	drive1541DataDumpNumberOfBytesPerLine = 8;
	drive1541DataDumpShowCharacters = true;
	drive1541DataDumpShowSprites = true;
	
	c64DisassembleNumberOfLines = 62;
	drive1541DisassembleNumberOfLines = 62;
	c64DisassembleNumberOfLabelCharacters = 20;
	drive1541DisassembleNumberOfLabelCharacters = 20;
	
	c64DisassembleCodeMnemonicsOffset = 0.0f;
	c64DisassembleShowHexCodes = false;
	c64DisassembleShowCodeCycles = false;
	c64DisassembleCodeCyclesOffset = -1.5f;
	c64DisassembleShowLabels = false;
	drive1541DisassembleCodeMnemonicsOffset = 0.0f;
	drive1541DisassembleShowHexCodes = false;
	drive1541DisassembleShowCodeCycles = false;
	drive1541DisassembleCodeCyclesOffset = -1.5f;

	drive1541DisassembleShowLabels = false;
	
	c64StateCIAFontSize = c64StateSIDFontSize = c64StateVICFontSize = c64StateDrive1541FontSize = 5.0f;
	
	c64StateCIARenderCIA1 = true;
	c64StateCIARenderCIA2 = true;
	
	c64StateVICIsVertical = false;
	c64StateVICShowSprites = true;

	c64StateDrive1541RenderVIA1 = true;
	c64StateDrive1541RenderVIA2 = true;
	c64StateDrive1541RenderDriveLED = true;
	c64StateDrive1541IsVertical = false;
	
	c64VicDisplayVisible = false;
	c64VicDisplayScale = 1.0f;
	c64VicDisplayCanScrollDisassemble = true;
	
	c64VicControlVisible = false;
	c64VicControlFontSize = 8.0f;

	monitorConsoleFontScale = 1.5f;
	monitorConsoleNumLines = 20;

	
	debugOnC64 = true;
	debugOnDrive1541 = false;
}

// drag & drop callbacks
void C64D_DragDropCallback(char *filePath)
{
	CSlrString *slrPath = new CSlrString(filePath);
	C64D_DragDropCallback(slrPath);
	delete slrPath;
}

void C64D_DragDropCallback(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallback, c64dStartupTime=%d", c64dStartupTime);
	
	CSlrString *ext = filePath->GetFileExtensionComponentFromPath();
	//ext->DebugPrint("ext=");
	
	if (SYS_GetCurrentTimeInMillis() - c64dStartupTime < 500)
	{
		LOGD("C64D_DragDropCallback: sleep 500ms");
		SYS_Sleep(500);
	}
	
	if (ext->CompareWith("prg") || ext->CompareWith("PRG"))
	{
		C64D_DragDropCallbackPRG(filePath);
	}
	else if (ext->CompareWith("d64") || ext->CompareWith("D64"))
	{
		C64D_DragDropCallbackD64(filePath);
	}
	else if (ext->CompareWith("crt") || ext->CompareWith("CRT"))
	{
		C64D_DragDropCallbackCRT(filePath);
	}
	else if (ext->CompareWith("snap") || ext->CompareWith("SNAP")
			 || ext->CompareWith("vsf") || ext->CompareWith("VSF"))
	{
		C64D_DragDropCallbackSNAP(filePath);
	}

	
	delete ext;
}

void C64D_DragDropCallbackPRG(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackPRG");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadPRG(filePath, true, false);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackD64(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackD64");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->InsertD64(filePath, false);
	
	CSlrString *fileName = filePath->GetFileNameComponentFromPath();
	char *fn = fileName->GetStdASCII();
	
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Inserted %s", fn);
	
	guiMain->ShowMessage(buf);
	
	SYS_ReleaseCharBuf(buf);
	delete [] fn;
	delete fileName;
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackCRT(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackCRT");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->InsertCartridge(filePath, false);

	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackSNAP(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackSNAP");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64Snapshots->LoadSnapshot(filePath, false);
}


void CViewC64::AddDebugCode()
{
	//debugInterface->Reset();
	
	debugInterfaceVice->LockMutex();
	int rasterNum = 0x45;
	C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(rasterNum);
	debugInterfaceVice->breakpointsC64Raster[rasterNum] = addrBreakpoint;
	debugInterfaceVice->breakOnC64Raster = true;
	debugInterfaceVice->UnlockMutex();
	
	isShowingRasterCross = true;
	
	SYS_Sleep(500);
	
	
	u16 addr = 0x1000;

	debugInterface->FillC64Ram(0x0800, 0x4000, 0x00);
	
	debugInterface->SetByteC64(addr++, 0x78);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xEA);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x01);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x21);
	debugInterface->SetByteC64(addr++, 0xD0);
	debugInterface->SetByteC64(addr++, 0xCE);
	debugInterface->SetByteC64(addr++, 0x21);
	debugInterface->SetByteC64(addr++, 0xD0);
//	debugInterface->SetByteC64(addr++, 0x4C);
//	debugInterface->SetByteC64(addr  , (addr-1)&0x00FF); addr++;
//	debugInterface->SetByteC64(addr++, 0x10);
	
	
	
	for (int i = 0; i < 100; i++)
	{
		debugInterface->SetByteC64(addr++, 0xEE);
		debugInterface->SetByteC64(addr++, 0x21);
		debugInterface->SetByteC64(addr++, 0xD0);
		//			debugInterface->SetByteC64(addr++, 0xEE);
		//			debugInterface->SetByteC64(addr++, 0x20);
		//			debugInterface->SetByteC64(addr++, 0xD0);
	}
	
	debugInterface->SetByteC64(addr++, 0x4C);
	debugInterface->SetByteC64(addr++, 0x00);
	debugInterface->SetByteC64(addr++, 0x10);
	
	
	addr = 0x2000;
	
	//
	// generate sound
	//
	debugInterface->SetByteC64(addr++, 0xA2);
	debugInterface->SetByteC64(addr++, 0x18);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x00);
	debugInterface->SetByteC64(addr++, 0x9D);
	debugInterface->SetByteC64(addr++, 0x00);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xCA);
	debugInterface->SetByteC64(addr++, 0xD0);
	debugInterface->SetByteC64(addr++, 0xFA);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x09);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x05);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x00);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x06);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x1F);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x18);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x19);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x01);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0xB1);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x00);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x21);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x04);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0xA2);
	debugInterface->SetByteC64(addr++, 0xA0);
	debugInterface->SetByteC64(addr++, 0xA0);
	debugInterface->SetByteC64(addr++, 0xFF);
	debugInterface->SetByteC64(addr++, 0x88);
	debugInterface->SetByteC64(addr++, 0xD0);
	debugInterface->SetByteC64(addr++, 0xFD);
	debugInterface->SetByteC64(addr++, 0xCA);
	debugInterface->SetByteC64(addr++, 0xD0);
	debugInterface->SetByteC64(addr++, 0xF8);
	debugInterface->SetByteC64(addr++, 0xA9);
	debugInterface->SetByteC64(addr++, 0x20);
	debugInterface->SetByteC64(addr++, 0x8D);
	debugInterface->SetByteC64(addr++, 0x04);
	debugInterface->SetByteC64(addr++, 0xD4);
	debugInterface->SetByteC64(addr++, 0x4C);
	debugInterface->SetByteC64(addr++, 0x23);
	debugInterface->SetByteC64(addr++, 0x20);
	
	debugInterface->MakeJmpC64(0x1000);
}


////
// TODO: move it from here and create callbacks

void SYS_PrepareShutdown()
{
	guiMain->RemoveAllViews();
	viewC64->debugInterface->SetDebugMode(C64_DEBUG_SHUTDOWN);
	SYS_Sleep(100);
}

