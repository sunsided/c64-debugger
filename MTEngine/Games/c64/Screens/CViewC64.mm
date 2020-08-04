//
// C64 Debugger (C) Marcin Skoczylas, slajerek@gmail.com
//
// created on 2016-02-22

// define also in CGuiMain
//#define DO_NOT_USE_AUDIO_QUEUE

// TODO: move me ..
#define MAX_BUFFER 2048

extern "C"{
#include "c64mem.h"
}

#include "CViewC64.h"
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
#include "SYS_PIPE.h"

#include "CViewDataDump.h"
#include "CViewDataWatch.h"
#include "CViewMemoryMap.h"
#include "CViewDisassemble.h"
#include "CViewSourceCode.h"

#include "CViewC64Screen.h"
#include "CViewC64ScreenWrapper.h"

#include "CViewC64StateCIA.h"
#include "CViewC64StateREU.h"
#include "CViewEmulationCounters.h"
#include "CViewC64StateSID.h"
#include "CViewC64StateVIC.h"
#include "CViewDrive1541StateVIA.h"
#include "CViewEmulationState.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64VicControl.h"
#include "CViewC64StateCPU.h"
#include "CViewTimeline.h"
#include "CViewDriveStateCPU.h"

#include "CViewAtariScreen.h"
#include "CViewAtariStateCPU.h"
#include "CViewAtariStateANTIC.h"
#include "CViewAtariStatePIA.h"
#include "CViewAtariStateGTIA.h"
#include "CViewAtariStatePOKEY.h"

#include "CViewNesScreen.h"
#include "CViewNesStateCPU.h"

#include "CViewBreakpoints.h"
#include "CViewMainMenu.h"
#include "CViewSettingsMenu.h"
#include "CViewFileD64.h"
#include "CViewC64KeyMap.h"
#include "CViewC64AllGraphics.h"
#include "CViewKeyboardShortcuts.h"
#include "CViewMonitorConsole.h"
#include "CViewSnapshots.h"
#include "CViewColodore.h"
#include "CViewAbout.h"
#include "CViewVicEditor.h"
#include "CViewJukeboxPlaylist.h"
#include "CJukeboxPlaylist.h"
#include "C64FileDataAdapter.h"
#include "C64KeyboardShortcuts.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "C64Symbols.h"
#include "C64Palette.h"
#include "C64KeyMap.h"
#include "C64CommandLine.h"
#include "C64SharedMemory.h"
#include "C64SIDFrequencies.h"
#include "SND_SoundEngine.h"
#include "CSlrFileFromOS.h"
#include "CColorsTheme.h"
#include "SYS_Threading.h"
#include "C64AsmSourceSymbols.h"
#include "CDebuggerEmulatorPlugin.h"
#include "CSnapshotsManager.h"
#include "C64D_InitPlugins.h"

#include "C64DebugInterfaceVice.h"
#include "AtariDebugInterface.h"
#include "NesDebugInterface.h"

CViewC64 *viewC64 = NULL;

long c64dStartupTime = 0;

#define TEXT_ADDR	0x0400
#define COLOR_ADDR	0xD800

CViewC64::CViewC64(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{	
	this->name = "CViewC64";
	viewC64 = this;
	
	SYS_SetThreadName("CViewC64");
	
	c64dStartupTime = SYS_GetCurrentTimeInMillis();
	
	C64InitPalette();
	
	this->debugInterfaceC64 = NULL;
	this->emulationThreadC64 = NULL;

	this->debugInterfaceAtari = NULL;
	this->emulationThreadAtari = NULL;

	this->debugInterfaceNes = NULL;
	this->emulationThreadNes = NULL;

	this->selectedDebugInterface = NULL;

	if (c64SettingsDefaultScreenLayoutId < 0)
	{
		c64SettingsDefaultScreenLayoutId = SCREEN_LAYOUT_C64_DATA_DUMP;
		
		LOGD("set c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	}
	
	C64DebuggerInitSharedMemory();
	SYS_SharedMemoryRegisterCallback(viewC64);

	currentScreenLayoutId = SCREEN_LAYOUT_MAX;
	
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
	
	isSoundMuted = false;
	
	keyboardShortcuts = new C64KeyboardShortcuts();
	
	// init default key map
	if (c64SettingsSkipConfig == false)
	{
		C64KeyMapLoadFromSettings();
	}
	else
	{
		C64KeyMapCreateDefault();
	}
	
	this->colorsTheme = new CColorsTheme(0);

	// init the Commodore 64 object
	this->InitViceC64();
	
	// create Commodore 64 fonts from kernal data
	this->CreateFonts();
	
	// crude hack for now, we needed c64 only for fonts
#ifndef RUN_COMMODORE64
	delete this->debugInterfaceC64;
	this->debugInterfaceC64 = NULL;
#endif
	
	
#ifdef RUN_ATARI
	// init the Atari 800 object
	this->InitAtari800();
	
	// TODO: create Atari fonts from kernal data
//	this->CreateFonts();
#endif
	
#if defined(RUN_NES)
	
	this->InitNestopia();
	
#endif

#if defined(RUN_COMMODORE64)
	//
	this->selectedDebugInterface = debugInterfaceVice;
#elif defined(RUN_ATARI)
	//
	this->selectedDebugInterface = debugInterfaceAtari;
#elif defined(RUN_NES)
	//
	this->selectedDebugInterface = debugInterfaceNes;
#endif
	
	this->InitViews();
	this->InitLayouts();
	
	// loop of views for TAB & shift+TAB
	if (debugInterfaceC64 != NULL)
	{
		traversalOfViews.push_back(viewC64ScreenWrapper);
	}
	
	if (debugInterfaceC64 != NULL)
	{
		traversalOfViews.push_back(viewC64Disassemble);
		traversalOfViews.push_back(viewC64MemoryDataDump);
		traversalOfViews.push_back(viewC64MemoryMap);
		traversalOfViews.push_back(viewDrive1541Disassemble);
		traversalOfViews.push_back(viewDrive1541MemoryDataDump);
		traversalOfViews.push_back(viewDrive1541MemoryMap);
		traversalOfViews.push_back(viewC64MonitorConsole);
	}
	
	if (debugInterfaceC64 != NULL)
	{
		traversalOfViews.push_back(viewC64VicDisplay);
	}
	
	if (debugInterfaceAtari != NULL)
	{
		traversalOfViews.push_back(viewAtariScreen);
		traversalOfViews.push_back(viewAtariDisassemble);
		traversalOfViews.push_back(viewAtariMemoryDataDump);
		traversalOfViews.push_back(viewAtariMemoryMap);
		traversalOfViews.push_back(viewAtariMonitorConsole);
	}

	if (debugInterfaceNes != NULL)
	{
		traversalOfViews.push_back(viewNesScreen);
		traversalOfViews.push_back(viewNesDisassemble);
	}

	// add views
	guiMain->AddGuiElement(this);

	// other views
	viewC64MainMenu = new CViewMainMenu(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64MainMenu);
	
	viewC64SettingsMenu = new CViewSettingsMenu(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewC64SettingsMenu);
	
	if (this->debugInterfaceC64 != NULL)
	{
		viewFileD64 = new CViewFileD64(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
		guiMain->AddGuiElement(viewFileD64);
		
		viewC64Breakpoints = new CViewBreakpoints(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceC64);
		guiMain->AddGuiElement(viewC64Breakpoints);
		
		viewC64Snapshots = new CViewSnapshots(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceC64);
		guiMain->AddGuiElement(viewC64Snapshots);
		
		viewC64KeyMap = new CViewC64KeyMap(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
		guiMain->AddGuiElement(viewC64KeyMap);

//		viewColodore = new CViewColodore(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
//		guiMain->AddGuiElement(viewColodore);
	}
	else
	{
		viewFileD64 = NULL;
		viewC64Breakpoints = NULL;
		viewC64Snapshots = NULL;
		viewC64KeyMap = NULL;
	}
	
	if (this->debugInterfaceAtari != NULL)
	{
		viewAtariSnapshots = new CViewSnapshots(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceAtari);
		guiMain->AddGuiElement(viewAtariSnapshots);
	}

	if (this->debugInterfaceNes != NULL)
	{
		viewNesSnapshots = new CViewSnapshots(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceNes);
		guiMain->AddGuiElement(viewNesSnapshots);
	}

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
	
#if defined(RUN_COMMODORE64)
	//
	viewVicEditor = new CViewVicEditor(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);
	guiMain->AddGuiElement(viewVicEditor);
#endif
	
	SYS_AddApplicationPauseResumeListener(this);
	
	// settings that need to be set when emulation is initialized
	C64DebuggerRestoreSettings(C64DEBUGGER_BLOCK_POSTLAUNCH);
	
	// do additional parsing
	C64DebuggerParseCommandLine2();

	// memory map colors
	C64DebuggerComputeMemoryMapColorTables(c64SettingsMemoryValuesStyle);
	C64DebuggerSetMemoryMapMarkersStyle(c64SettingsMemoryMarkersStyle);

	C64DebuggerSetMemoryMapCellsFadeSpeed((float)c64SettingsMemoryMapFadeSpeed / 100.0f);

	bool isInVicEditor = c64SettingsIsInVicEditor;
	
	this->isVisibleWatch = false;

	LOGD("... after parsing c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	if (c64SettingsDefaultScreenLayoutId >= SCREEN_LAYOUT_MAX)
	{
		LOGD("... c64SettingsDefaultScreenLayoutId=%d >= SCREEN_LAYOUT_MAX=%d", c64SettingsDefaultScreenLayoutId, SCREEN_LAYOUT_MAX);
		
		c64SettingsDefaultScreenLayoutId = SCREEN_LAYOUT_C64_DEBUGGER;
		LOGD("... corrected c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
	}
	this->SwitchToScreenLayout(c64SettingsDefaultScreenLayoutId);

	c64SettingsIsInVicEditor = isInVicEditor;
	
	//////////////////////
	this->viewJukeboxPlaylist = NULL;

	if (c64SettingsPathToJukeboxPlaylist != NULL)
	{
		this->InitJukebox(c64SettingsPathToJukeboxPlaylist);
	}
	
	// finished starting up
	RES_SetStateIdle();
	VID_SetFPS(FRAMES_PER_SECOND);

	//
	// Start PIPE integration
	if (c64SettingsUsePipeIntegration)
	{
		PIPE_Init();
	}
	
	//
	// Create plugins
	this->CreateEmulatorPlugins();
	
	//
	// Start emulation threads (emulation should be already initialized, just run the processor)
	//
	
#ifdef RUN_COMMODORE64
	if (debugInterfaceC64 != NULL)
	{
		emulationThreadC64 = new CEmulationThreadC64();
		SYS_StartThread(emulationThreadC64, NULL);

		this->selectedDebugInterface = debugInterfaceVice;
	}
#endif

#ifdef RUN_ATARI
	if (debugInterfaceAtari != NULL)
	{
		emulationThreadAtari = new CEmulationThreadAtari();
				
		SYS_StartThread(emulationThreadAtari, NULL);
		
		this->selectedDebugInterface = debugInterfaceAtari;
	}
#endif
	
#ifdef RUN_NES
	if (debugInterfaceNes != NULL)
	{
		emulationThreadNes = new CEmulationThreadNes();
		
		SYS_StartThread(emulationThreadNes, NULL);
		
		this->selectedDebugInterface = debugInterfaceNes;
	}
#endif

	if (selectedDebugInterface == NULL)
	{
		LOGError("No emulation thread is running");
	}
	
	if (c64SettingsIsInVicEditor == false)
	{
		SetLayout(this->currentScreenLayoutId);
	}
	
	
	// attach disks, cartridges etc
	C64DebuggerPerformStartupTasks();

	if (c64SettingsSkipConfig == false)
	{
		viewKeyboardShortcuts->RestoreKeyboardShortcuts();
	}
	
	viewKeyboardShortcuts->UpdateQuitShortcut();

	//
	C64SetPaletteNum(c64SettingsVicPalette);

#if defined(WIN32)
	// set process priority
	SYS_SetMainProcessPriorityBoostDisabled(c64SettingsIsProcessPriorityBoostDisabled);
	SYS_SetMainProcessPriority(c64SettingsProcessPriority);
#endif
	
	// start
	ShowMainScreen();
	
	// init plugins
	if (debugInterfaceC64)
	{
		debugInterfaceC64->InitPlugins();
	}

	if (debugInterfaceAtari)
	{
		debugInterfaceAtari->InitPlugins();
	}

	if (debugInterfaceNes)
	{
		debugInterfaceNes->InitPlugins();
	}
}

void CViewC64::ShowMainScreen()
{
	LOGD("CViewC64::ShowMainScreen");
	
	if (c64SettingsIsInVicEditor)
	{
		guiMain->SetView(viewVicEditor);
	}
	else
	{
		guiMain->SetView(this);
	}

	//	guiMain->SetView(viewKeyboardShortcuts);
//		guiMain->SetView(viewC64KeyMap);
	//	guiMain->SetView(viewAbout);
	//	guiMain->SetView(viewC64SettingsMenu);
	//	guiMain->SetView(viewC64MainMenu);
	//	guiMain->SetView(viewC64Breakpoints);
	//	guiMain->SetView(viewVicEditor);
//	guiMain->SetView(this->viewColodore);

	CheckMouseCursorVisibility();
}

CViewC64::~CViewC64()
{
}

void CViewC64::RegisterEmulatorPlugin(CDebuggerEmulatorPlugin *emuPlugin)
{
	CDebugInterface *interface = emuPlugin->GetDebugInterface();
	interface->RegisterPlugin(emuPlugin);
}

void CViewC64::InitJukebox(CSlrString *jukeboxJsonFilePath)
{
	guiMain->LockMutex();
	
#if defined(MACOS) || defined(LINUX)
	// set current folder to jukebox path
	
	CSlrString *path = jukeboxJsonFilePath->GetFilePathWithoutFileNameComponentFromPath();
	char *cPath = path->GetStdASCII();
	
	LOGD("CViewC64::InitJukebox: chroot to %s", cPath);

	chdir(cPath);
	
	delete [] cPath;
	delete path;
	
#endif
	
	if (this->viewJukeboxPlaylist == NULL)
	{
		this->viewJukeboxPlaylist = new CViewJukeboxPlaylist(-10, -10, -3.0, 0.1, 0.1); //SCREEN_WIDTH, SCREEN_HEIGHT);
		this->AddGuiElement(this->viewJukeboxPlaylist);
	}
	
	this->viewJukeboxPlaylist->DeletePlaylist();
	
	this->viewJukeboxPlaylist->visible = true;

	// start with black screen
	this->viewJukeboxPlaylist->fadeState = JUKEBOX_PLAYLIST_FADE_STATE_FADE_OUT;
	this->viewJukeboxPlaylist->fadeValue = 1.0f;
	this->viewJukeboxPlaylist->fadeStep = 0.0f;
	
	char *str = jukeboxJsonFilePath->GetStdASCII();
	
	this->viewJukeboxPlaylist->InitFromFile(str);
	
	delete [] str;
	
	if ((this->debugInterfaceC64 && this->debugInterfaceC64->isRunning)
		|| (this->debugInterfaceAtari && this->debugInterfaceAtari->isRunning)
		|| (this->debugInterfaceNes && this->debugInterfaceNes->isRunning))
	{
		this->viewJukeboxPlaylist->StartPlaylist();
	}
	else
	{
		// jukebox will be started by c64PerformStartupTasksThreaded()
		if (this->viewJukeboxPlaylist->playlist->setLayoutViewNumber >= 0
			&& this->viewJukeboxPlaylist->playlist->setLayoutViewNumber < SCREEN_LAYOUT_MAX)
		{
			viewC64->SwitchToScreenLayout(this->viewJukeboxPlaylist->playlist->setLayoutViewNumber);
		}
	}
	
	guiMain->UnlockMutex();
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
	
	this->debugInterfaceC64 = new C64DebugInterfaceVice(this, this->mappedC64Memory, c64SettingsFastBootKernalPatch);
	
	LOGM("CViewC64::InitViceC64: done");

}

void CViewC64::InitAtari800()
{
	LOGM("CViewC64::InitAtari800");
	
	if (debugInterfaceAtari != NULL)
	{
		delete debugInterfaceAtari;
		debugInterfaceAtari = NULL;
	}
	
//	if (c64SettingsPathToC64MemoryMapFile)
//	{
//		// Create debug interface and init Vice
//		char *asciiPath = c64SettingsPathToAtari800MemoryMapFile->GetStdASCII();
//		
//		this->MapC64MemoryToFile(asciiPath);
//		
//		LOGD(".. mapped Atari800 memory to file '%s'", asciiPath);
//		
//		delete [] asciiPath;
//		
//	}
//	else
//	{
//		this->mappedC64Memory = (uint8 *)malloc(C64_RAM_SIZE);
//	}
	
	this->debugInterfaceAtari = new AtariDebugInterface(this); //, this->mappedC64Memory, c64SettingsFastBootKernalPatch);
	
	LOGM("CViewC64::InitViceC64: done");
}

void CViewC64::InitNestopia()
{
	LOGM("CViewC64::InitNestopia");

	this->debugInterfaceNes = new NesDebugInterface(this);

	LOGM("CViewC64::InitNestopia: done");
}


void CViewC64::InitViews()
{
	// set mouse cursor outside at startup
	mouseCursorX = -SCREEN_WIDTH;
	mouseCursorY = -SCREEN_HEIGHT;
	
#ifdef RUN_ATARI
	///
	viewAtariScreen = new CViewAtariScreen(0, 0, posZ, sizeX, sizeY, debugInterfaceAtari);
	this->AddGuiElement(viewAtariScreen);
	
	viewAtariBreakpoints = new CViewBreakpoints(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceAtari);
	guiMain->AddGuiElement(viewAtariBreakpoints);
	
#endif
	

#ifdef RUN_COMMODORE64
	
	// create views
	viewC64Screen = new CViewC64Screen(0, 0, posZ, sizeX, sizeY, debugInterfaceC64);
	//	this->AddGuiElement(viewC64Screen);   this will be added on the top

	// create views
	viewC64ScreenWrapper = new CViewC64ScreenWrapper(0, 0, posZ, sizeX, sizeY, debugInterfaceC64);
	//	this->AddGuiElement(viewC64ScreenWrapper);   this will be added on the top
	
	
	// views

	viewC64MemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64, 256, 256, 0x10000, false);	// 256x256 = 64kB
	this->AddGuiElement(viewC64MemoryMap);
	viewDrive1541MemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64, 64, 1024, 0x10000, true);
	this->AddGuiElement(viewDrive1541MemoryMap);

	
	viewC64Disassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
												 debugInterfaceC64->dataAdapterC64, viewC64MemoryMap,
												 &(debugInterfaceC64->breakpointsPC), debugInterfaceC64);
	this->AddGuiElement(viewC64Disassemble);
	viewDrive1541Disassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
													debugInterfaceC64->dataAdapterDrive1541, viewDrive1541MemoryMap,
													&(debugInterfaceC64->breakpointsDrive1541PC), debugInterfaceC64);
	this->AddGuiElement(viewDrive1541Disassemble);
	
	
	viewC64MemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
											  debugInterfaceC64->dataAdapterC64, viewC64MemoryMap, viewC64Disassemble, debugInterfaceC64);
	this->AddGuiElement(viewC64MemoryDataDump);

	viewC64MemoryDataWatch = new CViewDataWatch(10, 10, -1, 300, 300,
												debugInterfaceC64->dataAdapterC64, viewC64MemoryMap, debugInterfaceC64);
	this->AddGuiElement(viewC64MemoryDataWatch);
	viewC64MemoryDataWatch->visible = false;
	

	
	viewDrive1541MemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
													debugInterfaceC64->dataAdapterDrive1541, viewDrive1541MemoryMap, viewDrive1541Disassemble,
													debugInterfaceC64);
	this->AddGuiElement(viewDrive1541MemoryDataDump);
	
	viewDrive1541MemoryDataWatch = new CViewDataWatch(10, 10, -1, 300, 300,
												debugInterfaceC64->dataAdapterDrive1541, viewDrive1541MemoryMap, debugInterfaceC64);
	this->AddGuiElement(viewDrive1541MemoryDataWatch);
	viewDrive1541MemoryDataWatch->visible = false;
	
	
	//
	viewC64SourceCode = new CViewSourceCode(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
											debugInterfaceC64->dataAdapterC64, viewC64MemoryMap, viewC64Disassemble, debugInterfaceC64);
	this->AddGuiElement(viewC64SourceCode);
	

	//
	
	viewC64StateCIA = new CViewC64StateCIA(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64StateCIA);
	viewC64StateSID = new CViewC64StateSID(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64StateSID);
	viewC64StateVIC = new CViewC64StateVIC(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64StateVIC);
	viewC64StateREU = new CViewC64StateREU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64StateREU);
	viewC64EmulationCounters = new CViewEmulationCounters(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64EmulationCounters);
	viewDrive1541StateVIA = new CViewDrive1541StateVIA(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewDrive1541StateVIA);

	viewEmulationState = new CViewEmulationState(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewEmulationState);
	
	viewC64VicDisplay = new CViewC64VicDisplay(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64VicDisplay);

	viewC64VicControl = new CViewC64VicControl(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, viewC64VicDisplay);
	this->AddGuiElement(viewC64VicControl);
	
	//
	viewC64StateCPU = new CViewC64StateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64StateCPU);
	viewDriveStateCPU = new CViewDriveStateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewDriveStateCPU);

	//
	viewC64AllGraphics = new CViewC64AllGraphics(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64AllGraphics);

	viewC64MonitorConsole = new CViewMonitorConsole(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceC64);
	this->AddGuiElement(viewC64MonitorConsole);

	// C64 only
	float timelineHeight = 10;
	viewC64Timeline = new CViewTimeline(0, SCREEN_HEIGHT-timelineHeight, posZ, SCREEN_WIDTH, timelineHeight, debugInterfaceC64);
	//	this->AddGuiElement(viewC64Timeline);

	
	// add c64 screen on top of all other views
//	this->AddGuiElement(viewC64Screen);
	this->AddGuiElement(viewC64ScreenWrapper);

#endif

	
#ifdef RUN_ATARI
//	///
//	viewAtariScreen = new CViewAtariScreen(0, 0, posZ, sizeX, sizeY, debugInterfaceAtari);
//	this->AddGuiElement(viewAtariScreen);

	viewAtariStateCPU = new CViewAtariStateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariStateCPU);

	//
	
	viewAtariMemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari, 256, 256, 0x10000, false);	// 256x256 = 64kB
	this->AddGuiElement(viewAtariMemoryMap);

	viewAtariDisassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
												debugInterfaceAtari->dataAdapter, viewAtariMemoryMap,
												&(debugInterfaceAtari->breakpointsPC), debugInterfaceAtari);
	this->AddGuiElement(viewAtariDisassemble);

	//
	viewAtariSourceCode = new CViewSourceCode(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
											debugInterfaceAtari->dataAdapter, viewAtariMemoryMap, viewAtariDisassemble, debugInterfaceAtari);
	this->AddGuiElement(viewAtariSourceCode);

	viewAtariMemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
												debugInterfaceAtari->dataAdapter, viewAtariMemoryMap, viewAtariDisassemble,
												debugInterfaceAtari);
	this->AddGuiElement(viewAtariMemoryDataDump);
	
	viewAtariMemoryDataWatch = new CViewDataWatch(10, 10, -1, 300, 300,
												debugInterfaceAtari->dataAdapter, viewAtariMemoryMap, debugInterfaceAtari);
	this->AddGuiElement(viewAtariMemoryDataWatch);
	viewAtariMemoryDataWatch->visible = false;

	
	viewAtariStateANTIC = new CViewAtariStateANTIC(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariStateANTIC);
	viewAtariStateGTIA = new CViewAtariStateGTIA(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariStateGTIA);
	viewAtariStatePIA = new CViewAtariStatePIA(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariStatePIA);
	viewAtariStatePOKEY = new CViewAtariStatePOKEY(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariStatePOKEY);

	viewAtariMonitorConsole = new CViewMonitorConsole(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariMonitorConsole);

	viewAtariEmulationCounters = new CViewEmulationCounters(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceAtari);
	this->AddGuiElement(viewAtariEmulationCounters);

	// make on top
	this->RemoveGuiElement(viewAtariScreen);
	this->AddGuiElement(viewAtariScreen);

	// Atari only
	float timelineHeight = 10;
	viewAtariTimeline = new CViewTimeline(0, SCREEN_HEIGHT-timelineHeight, posZ, SCREEN_WIDTH, timelineHeight, debugInterfaceAtari);
	//	this->AddGuiElement(viewAtariTimeline);

	
#endif
	
	
#ifdef RUN_NES
	///
	viewNesScreen = new CViewNesScreen(0, 0, posZ, sizeX, sizeY, debugInterfaceNes);
	this->AddGuiElement(viewNesScreen);
	
	viewNesStateCPU = new CViewNesStateCPU(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceNes);
	this->AddGuiElement(viewNesStateCPU);
	
	viewNesMemoryMap = new CViewMemoryMap(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT, debugInterfaceNes, 256, 256, 0x10000, false);	// 256x256 = 64kB
	this->AddGuiElement(viewNesMemoryMap);
	
	viewNesDisassemble = new CViewDisassemble(0, 0, posZ, SCREEN_WIDTH, SCREEN_HEIGHT,
												debugInterfaceNes->dataAdapter, viewNesMemoryMap,
												&(debugInterfaceNes->breakpointsPC), debugInterfaceNes);
	this->AddGuiElement(viewNesDisassemble);
	
	viewNesMemoryDataDump = new CViewDataDump(10, 10, -1, 300, 300,
												debugInterfaceNes->dataAdapter, viewNesMemoryMap, viewNesDisassemble,
												debugInterfaceNes);
	this->AddGuiElement(viewNesMemoryDataDump);

	
	
	//	viewAtariBreakpoints = new CViewBreakpoints(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT, this->debugInterfaceAtari);
	//	guiMain->AddGuiElement(viewAtariBreakpoints);
	
#endif
	

	
}

void CViewC64::InitLayouts()
{
	for (int i = 0; i < SCREEN_LAYOUT_MAX; i++)
	{
		screenPositions[i] = NULL;
	}
	
	//
	// TODO: this code below was *automagically* generated and will be transformed into 
	//       layout loader/storage from JSON files
	//       and let each view has its own parameters loader. *this below is temporary*
	//       the layout designer is in progress...
	//
	float scale;
	float memMapSize = 200.0f;
	int m;
	
#if defined(RUN_COMMODORE64)
	m = SCREEN_LAYOUT_C64_ONLY;
	screenPositions[m] = new CScreenLayout();
	scale = (float)SCREEN_HEIGHT / (float)debugInterfaceC64->GetScreenSizeY();
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = ((float)SCREEN_WIDTH-screenPositions[m]->c64ScreenSizeX)/2.0f - 0.78f;
	screenPositions[m]->c64ScreenY = 0.0f;
	
	
	m = SCREEN_LAYOUT_C64_DATA_DUMP;
	screenPositions[m] = new CScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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
	
	
	
	m = SCREEN_LAYOUT_C64_DEBUGGER;
	screenPositions[m] = new CScreenLayout();
///	scale = 1.3f;
	scale = 0.67f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 180.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 181.0f;
	screenPositions[m]->c64CpuStateY = 0.0f;
	/////////
	
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
	screenPositions[m]->c64StateVICSizeX = 4.0f*34;
	screenPositions[m]->c64StateVICSizeY = 4.0f*48;
	screenPositions[m]->c64StateVICIsVertical = true;

	
	
	m = SCREEN_LAYOUT_C64_MEMORY_MAP;
	screenPositions[m] = new CScreenLayout();
	scale = 0.41f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 420.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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

	
	m = SCREEN_LAYOUT_C64_1541_DEBUGGER;
	screenPositions[m] = new CScreenLayout();
	scale = 1.09f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 80.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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
	screenPositions[m]->drive1541StateVIAVisible = true;
	screenPositions[m]->drive1541StateVIAFontSize = 5.0f;
	screenPositions[m]->drive1541StateVIAX = 342.0f;
	screenPositions[m]->drive1541StateVIAY = 310.0f;
	screenPositions[m]->drive1541StateVIARenderVIA1 = true;
	screenPositions[m]->drive1541StateVIARenderVIA2 = false;
	screenPositions[m]->drive1541StateVIARenderDriveLED = true;
	screenPositions[m]->drive1541StateVIAIsVertical = true;
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


	m = SCREEN_LAYOUT_C64_1541_MEMORY_MAP;
	screenPositions[m] = new CScreenLayout();
	scale = 0.525f;
	memMapSize = 200.0f;
	
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenX = 190.0f;
	screenPositions[m]->c64ScreenY = 10.0f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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
	
	m = SCREEN_LAYOUT_C64_SHOW_STATES;
	screenPositions[m] = new CScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 5.0f;
	screenPositions[m]->c64StateVICX = 13.0f;
	screenPositions[m]->c64StateVICY = 13.0f;
	screenPositions[m]->c64StateVICSizeX = 5.0f*58;
	screenPositions[m]->c64StateVICSizeY = 5.0f*32;
	screenPositions[m]->c64StateVICIsVertical = false;

	screenPositions[m]->c64StateSIDVisible = true;
	screenPositions[m]->c64StateSIDFontSize = 5.0f;
	screenPositions[m]->c64StateSIDX = 0.0f;
	screenPositions[m]->c64StateSIDY = 190.0f;//195.0f;

	screenPositions[m]->c64StateCIAVisible = true;
	screenPositions[m]->c64StateCIAFontSize = 5.0f;
	screenPositions[m]->c64StateCIAX = 190.0f;
	screenPositions[m]->c64StateCIAY = 200.0f;

	screenPositions[m]->c64StateREUVisible = true;
	screenPositions[m]->c64StateREUFontSize = 5.0f;
	screenPositions[m]->c64StateREUX = 315.0f;
	screenPositions[m]->c64StateREUY = 315.0f;

	screenPositions[m]->c64EmulationCountersVisible = true;
	screenPositions[m]->c64EmulationCountersFontSize = 5.0f;
	screenPositions[m]->c64EmulationCountersX = 496.0f;
	screenPositions[m]->c64EmulationCountersY = 335.0f;
	
	screenPositions[m]->drive1541StateVIAVisible = true;
	screenPositions[m]->drive1541StateVIAFontSize = 5.0f;
	screenPositions[m]->drive1541StateVIAX = 190.0f;
	screenPositions[m]->drive1541StateVIAY = 265.0f;
	screenPositions[m]->drive1541StateVIARenderVIA1 = true;
	screenPositions[m]->drive1541StateVIARenderVIA2 = true;
	screenPositions[m]->drive1541StateVIARenderDriveLED = true;
	
	screenPositions[m]->c64DataDumpVisible = false;
	screenPositions[m]->drive1541DataDumpVisible = false;
	
	screenPositions[m]->emulationStateVisible = true;
	screenPositions[m]->emulationStateX = 371.0f;
	screenPositions[m]->emulationStateY = 350.0f;
	
	// ctrl+shift+f8
	m = SCREEN_LAYOUT_C64_MONITOR_CONSOLE;
	screenPositions[m] = new CScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64MonitorConsoleVisible = true;
	screenPositions[m]->c64MonitorConsoleX = 1.0f;
	screenPositions[m]->c64MonitorConsoleY = 1.0f;
	screenPositions[m]->c64MonitorConsoleFontScale = 1.25f;
	screenPositions[m]->c64MonitorConsoleNumLines = 23;
	screenPositions[m]->c64MonitorConsoleSizeX = 310.0f;
	screenPositions[m]->c64MonitorConsoleSizeY = screenPositions[m]->c64ScreenSizeY + 10.5f;

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
	screenPositions[m]->drive1541CpuStateVisible = false;
	screenPositions[m]->drive1541CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->drive1541CpuStateY = 0.0f;
	screenPositions[m]->drive1541CpuStateFontSize = 5.0f;
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
	m = SCREEN_LAYOUT_C64_CYCLER;
	screenPositions[m] = new CScreenLayout();
	scale = 0.676f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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
//	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT/2.0f + screenPositions[m]->c64DisassembleFontSize*4;
//	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleNumberOfLines = 29;
	screenPositions[m]->c64DisassembleShowHexCodes = true;
	screenPositions[m]->c64DisassembleShowCodeCycles = true;
	screenPositions[m]->c64DisassembleShowLabels = true;
	screenPositions[m]->c64DisassembleNumberOfLabelCharacters = 20;
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 0.0f;
	screenPositions[m]->c64DataDumpY = SCREEN_HEIGHT/2.0f + screenPositions[m]->c64DisassembleFontSize*5 + 2;
	screenPositions[m]->c64DataDumpSizeX = 313.0f;
	screenPositions[m]->c64DataDumpSizeY = SCREEN_HEIGHT - screenPositions[m]->c64DataDumpY;
	screenPositions[m]->c64DataDumpFontSize = 5.3f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->c64DataDumpShowDataCharacters = true;
	screenPositions[m]->c64DataDumpShowCharacters = false;
	screenPositions[m]->c64DataDumpShowSprites = false;
	screenPositions[m]->c64StateVICVisible = true;
	screenPositions[m]->c64StateVICFontSize = 4.0f;
	screenPositions[m]->c64StateVICX = 320.0f;
	screenPositions[m]->c64StateVICY = 330.0f;
	screenPositions[m]->c64StateVICSizeX = 4.0f*64;
	screenPositions[m]->c64StateVICSizeY = 4.0f*7;
	screenPositions[m]->c64StateVICIsVertical = true;
	screenPositions[m]->c64StateVICShowSprites = false;
	screenPositions[m]->c64StateVICNumValuesPerColumn = 0x07;

	//
	m = SCREEN_LAYOUT_C64_VIC_DISPLAY;
	screenPositions[m] = new CScreenLayout();
	scale = 0.35f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
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
	screenPositions[m]->c64StateVICSizeX = 4.5f*57;
	screenPositions[m]->c64StateVICSizeY = 4.5f*32;
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
	m = SCREEN_LAYOUT_C64_VIC_DISPLAY_LITE;
	screenPositions[m] = new CScreenLayout();
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
	screenPositions[m]->c64DataDumpShowDataCharacters = true;
	screenPositions[m]->c64DataDumpShowCharacters = false;
	screenPositions[m]->c64DataDumpShowSprites = false;
	
	scale = 0.90f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->c64ScreenY = 13.0f;

	// user can now r-click on screen to switch modes
	//	screenPositions[m]->c64VicDisplayVisible = false;
	//	screenPositions[m]->c64VicDisplayScale = 1.23f;
	//	screenPositions[m]->c64VicDisplayX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
	//	screenPositions[m]->c64VicDisplayY = 13.0f;
	//	screenPositions[m]->c64VicDisplayCanScrollDisassemble = false;

	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapSizeX = 110.0f;
	screenPositions[m]->c64MemoryMapSizeY = 99.0f;
	screenPositions[m]->c64MemoryMapX = SCREEN_WIDTH-screenPositions[m]->c64MemoryMapSizeX-2.5f;
	screenPositions[m]->c64MemoryMapY = 260;
	
	//
	m = SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM;
	screenPositions[m] = new CScreenLayout();
	scale = (float)SCREEN_HEIGHT / (float)debugInterfaceC64->GetScreenSizeY();
	screenPositions[m]->c64ScreenVisible = false;
	screenPositions[m]->c64ScreenShowZoomedScreen = true;
	
	screenPositions[m]->c64ScreenZoomedSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenZoomedSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenZoomedX = ((float)SCREEN_WIDTH-screenPositions[m]->c64ScreenZoomedSizeX)/2.0f;
	screenPositions[m]->c64ScreenZoomedY = 0.0f;

	//
	m = SCREEN_LAYOUT_C64_SOURCE_CODE;
	screenPositions[m] = new CScreenLayout();
	scale = 0.35f;
	screenPositions[m]->c64ScreenVisible = false;
	
	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 7.0f;
	screenPositions[m]->c64DisassembleX = 1.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.8f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 46;
	screenPositions[m]->c64DisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->c64DisassembleShowHexCodes = false;
	screenPositions[m]->c64DisassembleShowCodeCycles = false;
	screenPositions[m]->c64DisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->c64DisassembleShowLabels = false;
	screenPositions[m]->c64DisassembleNumberOfLabelCharacters = 10;
	screenPositions[m]->c64DataDumpVisible = false;

	screenPositions[m]->c64SourceCodeVisible = true;
	screenPositions[m]->c64SourceCodeX = screenPositions[m]->c64DisassembleSizeX + screenPositions[m]->c64DisassembleFontSize * 0.5f;
	screenPositions[m]->c64SourceCodeY = 1.0f + screenPositions[m]->c64DisassembleFontSize*2.0f;
	screenPositions[m]->c64SourceCodeSizeX = SCREEN_WIDTH-screenPositions[m]->c64SourceCodeX-2.0f;
	screenPositions[m]->c64SourceCodeSizeY = SCREEN_HEIGHT-4.0f-screenPositions[m]->c64SourceCodeY;
	screenPositions[m]->c64SourceCodeFontSize = 7.0f;
	

	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 220;
	screenPositions[m]->c64CpuStateY = 2.5f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
//	screenPositions[m]->c64DataDumpVisible = true;
//	screenPositions[m]->c64DataDumpX = screenPositions[m]->c64DisassembleFontSize * 25.0f + 10.5f;
//	screenPositions[m]->c64DataDumpY = 260;
//	screenPositions[m]->c64DataDumpSizeX = 277.0f;
//	screenPositions[m]->c64DataDumpSizeY = 97.0f;
//	screenPositions[m]->c64DataDumpFontSize = 5.0f;
//	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize*0.75f;
//	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.28f;
//	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
//	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
//	screenPositions[m]->c64DataDumpShowCharacters = false;
//	screenPositions[m]->c64DataDumpShowSprites = false;
	
	scale = 0.255f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = 478;
	screenPositions[m]->c64ScreenY = 0.0f;

	// user can now r-click on screen to switch modes
//		screenPositions[m]->c64VicDisplayVisible = true;
//		screenPositions[m]->c64VicDisplayScale = 0.35f;
//		screenPositions[m]->c64VicDisplayX = 470;
//		screenPositions[m]->c64VicDisplayY = 0.0f;
	screenPositions[m]->c64VicDisplayCanScrollDisassemble = true;

//	screenPositions[m]->c64MemoryMapVisible = true;
//	screenPositions[m]->c64MemoryMapSizeX = 110.0f;
//	screenPositions[m]->c64MemoryMapSizeY = 99.0f;
//	screenPositions[m]->c64MemoryMapX = SCREEN_WIDTH-screenPositions[m]->c64MemoryMapSizeX-2.5f;
//	screenPositions[m]->c64MemoryMapY = 260;
	
	
	//
	m = SCREEN_LAYOUT_C64_ALL_GRAPHICS;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->c64DisassembleVisible = false;
	
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = 350;
	screenPositions[m]->c64CpuStateY = 2.5f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	
	screenPositions[m]->c64DataDumpVisible = true;
	screenPositions[m]->c64DataDumpX = 355;
	screenPositions[m]->c64DataDumpY = 100;
	screenPositions[m]->c64DataDumpSizeX = 205.0f;
	screenPositions[m]->c64DataDumpSizeY = 135.0f;
	screenPositions[m]->c64DataDumpFontSize = 5.0f;
	screenPositions[m]->c64DataDumpGapAddress = screenPositions[m]->c64DataDumpFontSize*0.75f;
	screenPositions[m]->c64DataDumpGapHexData = screenPositions[m]->c64DataDumpFontSize*0.28f;
	screenPositions[m]->c64DataDumpGapDataCharacters = screenPositions[m]->c64DataDumpFontSize*0.5f;
	screenPositions[m]->c64DataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->c64DataDumpShowDataCharacters = false;
	screenPositions[m]->c64DataDumpShowCharacters = false;
	screenPositions[m]->c64DataDumpShowSprites = false;

	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapSizeX = 140.0f;
	screenPositions[m]->c64MemoryMapSizeY = 119.0f;
	screenPositions[m]->c64MemoryMapX = 420; //395; //SCREEN_WIDTH-screenPositions[m]->c64MemoryMapSizeX-2.5f;
	screenPositions[m]->c64MemoryMapY = 239;

	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 5.0f;
	screenPositions[m]->c64DisassembleX = 338.0f; //503.0f;
	screenPositions[m]->c64DisassembleY = 239.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.8f;
	screenPositions[m]->c64DisassembleSizeY = 119;
	screenPositions[m]->c64DisassembleNumberOfLines = 14;
	screenPositions[m]->c64DisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->c64DisassembleShowHexCodes = false;
	screenPositions[m]->c64DisassembleShowCodeCycles = false;
	screenPositions[m]->c64DisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->c64DisassembleShowLabels = false;
	screenPositions[m]->c64DisassembleNumberOfLabelCharacters = 10;

	scale = 0.30f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = 458;
	screenPositions[m]->c64ScreenY = 15.0f;
	
	screenPositions[m]->c64AllGraphicsVisible = true;
	screenPositions[m]->c64AllGraphicsX = 0.0f;
	screenPositions[m]->c64AllGraphicsY = 0.0f;
	
#endif
	// ^^ RUN_COMMODOREC64 ^^
	
#ifdef RUN_ATARI

	//
	// Atari layouts
	//
	
//	SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE,

	m = SCREEN_LAYOUT_ATARI_ONLY;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = (float)SCREEN_HEIGHT / (float)debugInterfaceAtari->GetScreenSizeY();
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = ((float)SCREEN_WIDTH-screenPositions[m]->atariScreenSizeX)/2.0f - 0.78f;
	screenPositions[m]->atariScreenY = 0.0f;
	

	m = SCREEN_LAYOUT_ATARI_DATA_DUMP;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.676f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenY = 10.5f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = SCREEN_WIDTH - screenPositions[m]->atariScreenSizeX-3.0f;
	
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariScreenX;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 7.0f;
	screenPositions[m]->atariDisassembleX = 1.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 15.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleNumberOfLines = 46;
	screenPositions[m]->atariDisassembleShowHexCodes = false;
	screenPositions[m]->atariDisassembleShowCodeCycles = false;
	
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 108.0f;
	screenPositions[m]->atariDataDumpY = 196.0f;
	screenPositions[m]->atariDataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - 198.0f;
	screenPositions[m]->atariDataDumpFontSize = 6.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->atariDataDumpShowSprites = false;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapX = 112.0f;
	screenPositions[m]->atariMemoryMapY = 1.0f;
	screenPositions[m]->atariMemoryMapSizeX = 199.0f;
	screenPositions[m]->atariMemoryMapSizeY = 192.0f;
	

	m = SCREEN_LAYOUT_ATARI_DEBUGGER;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	///	scale = 1.3f;
	scale = 0.67f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenX = 180.0f;
	screenPositions[m]->atariScreenY = 10.0f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = 181.0f;
	screenPositions[m]->atariCpuStateY = 0.0f;
	/////////
	
	screenPositions[m]->atariDisassembleVisible = true;
	
	screenPositions[m]->atariDisassembleFontSize = 7.0f;
	screenPositions[m]->atariDisassembleX = 1.0f; //503.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 25.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleNumberOfLines = 46;
	screenPositions[m]->atariDisassembleShowHexCodes = true;
	screenPositions[m]->atariDisassembleShowCodeCycles = true;
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 178.0f;
	screenPositions[m]->atariDataDumpY = 195.0f;
	screenPositions[m]->atariDataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - 195.0f;
	screenPositions[m]->atariDataDumpFontSize = 5.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	
	m = SCREEN_LAYOUT_ATARI_MEMORY_MAP;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.41f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenX = 420.0f;
	screenPositions[m]->atariScreenY = 10.0f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = 78.0f;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 5.0f;
	screenPositions[m]->atariDisassembleX = 0.5f;
	screenPositions[m]->atariDisassembleY = 0.5f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 15.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-1.0f;
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapX = 77.0f;
	screenPositions[m]->atariMemoryMapY = 15.0f;
	screenPositions[m]->atariMemoryMapSizeX = 340.5f;
	screenPositions[m]->atariMemoryMapSizeY = 340.5f;
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 421;
	screenPositions[m]->atariDataDumpY = 112;
	screenPositions[m]->atariDataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - 225.0f;
	screenPositions[m]->atariDataDumpFontSize = 5.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize*0.7f;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.36f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 8;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	
	screenPositions[m]->atariStateGTIAVisible = true;
	screenPositions[m]->atariStateGTIAFontSize = 3.0f;
	screenPositions[m]->atariStateGTIAX = 420.0f;
	screenPositions[m]->atariStateGTIAY = 248.0f;
	
	screenPositions[m]->atariStateANTICVisible = true;
	screenPositions[m]->atariStateANTICFontSize = 3.0f;
	screenPositions[m]->atariStateANTICX = 420.0f;
	screenPositions[m]->atariStateANTICY = 279.0f;

	screenPositions[m]->atariStatePOKEYVisible = true;
	screenPositions[m]->atariStatePOKEYFontSize = 3.0f;
	screenPositions[m]->atariStatePOKEYX = 420.0f;
	screenPositions[m]->atariStatePOKEYY = 301.0f;
	

	m = SCREEN_LAYOUT_ATARI_SHOW_STATES;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.676f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenY = 10.5f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = SCREEN_WIDTH - screenPositions[m]->atariScreenSizeX-3.0f;
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariScreenX;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	
	screenPositions[m]->atariStateANTICVisible = true;
	screenPositions[m]->atariStateANTICFontSize = 5.0f;
	screenPositions[m]->atariStateANTICX = 0.0f;
	screenPositions[m]->atariStateANTICY = 0.0f;

	screenPositions[m]->atariStateGTIAVisible = true;
	screenPositions[m]->atariStateGTIAFontSize = 5.0f;
	screenPositions[m]->atariStateGTIAX = 0.0f;
	screenPositions[m]->atariStateGTIAY = 190.0f;

	screenPositions[m]->atariStatePIAVisible = true;
	screenPositions[m]->atariStatePIAFontSize = 5.0f;
	screenPositions[m]->atariStatePIAX = 400.0f;
	screenPositions[m]->atariStatePIAY = 190.0f;

	screenPositions[m]->atariStatePOKEYVisible = true;
	screenPositions[m]->atariStatePOKEYFontSize = 5.0f;
	screenPositions[m]->atariStatePOKEYX = 0.0f;
	screenPositions[m]->atariStatePOKEYY = 300.0f; //285.0f;

	screenPositions[m]->atariEmulationCountersVisible = true;
	screenPositions[m]->atariEmulationCountersFontSize = 5.0f;
	screenPositions[m]->atariEmulationCountersX = 496.0f;
	screenPositions[m]->atariEmulationCountersY = 335.0f;

//	
//	screenPositions[m]->c64DataDumpVisible = false;
//	screenPositions[m]->drive1541DataDumpVisible = false;
	
	screenPositions[m]->emulationStateVisible = true;
	screenPositions[m]->emulationStateX = 371.0f;
	screenPositions[m]->emulationStateY = 350.0f;

	// f8
	m = SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.676f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenY = 10.5f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = SCREEN_WIDTH - screenPositions[m]->atariScreenSizeX-3.0f;
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariScreenX;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	
	screenPositions[m]->atariMonitorConsoleVisible = true;
	screenPositions[m]->atariMonitorConsoleX = 1.0f;
	screenPositions[m]->atariMonitorConsoleY = 1.0f;
	screenPositions[m]->atariMonitorConsoleFontScale = 1.25f;
	screenPositions[m]->atariMonitorConsoleNumLines = 23;
	screenPositions[m]->atariMonitorConsoleSizeX = 310.0f;
	screenPositions[m]->atariMonitorConsoleSizeY = 270.0f*scale + 10.5f; //screenPositions[m]->atariScreenSizeY + 10.5f;
	
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 5.0f;
	screenPositions[m]->atariDisassembleX = 1.0f;
	screenPositions[m]->atariDisassembleY = 195.5f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 25.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-200.5f;
	screenPositions[m]->atariDisassembleNumberOfLines = 31;
	screenPositions[m]->atariDisassembleShowHexCodes = true;
	screenPositions[m]->atariDisassembleShowCodeCycles = true;
	
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 128.0f;
	screenPositions[m]->atariDataDumpY = 195.5f;
	screenPositions[m]->atariDataDumpSizeX = 252;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - 195.0f;
	screenPositions[m]->atariDataDumpFontSize = 5.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 8;
	
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapSizeX = 199.0f;
	screenPositions[m]->atariMemoryMapSizeY = 164.0f;
	screenPositions[m]->atariMemoryMapX = SCREEN_WIDTH-screenPositions[m]->atariMemoryMapSizeX;
	screenPositions[m]->atariMemoryMapY = 195.5f;

	m = SCREEN_LAYOUT_ATARI_CYCLER;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.676f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenY = 10.5f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = SCREEN_WIDTH - screenPositions[m]->atariScreenSizeX-3.0f;
	
	screenPositions[m]->atariScreenShowGridLines = true;
	screenPositions[m]->atariScreenShowZoomedScreen = true;
	screenPositions[m]->atariScreenZoomedX = 317;
	screenPositions[m]->atariScreenZoomedY = 197;
	screenPositions[m]->atariScreenZoomedSizeX = 260;
	screenPositions[m]->atariScreenZoomedSizeY = 130; //108;
	
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariScreenX;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 7.0f;
	screenPositions[m]->atariDisassembleX = 1.0f; //503.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 45.0f;
	//	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT/2.0f + screenPositions[m]->atariDisassembleFontSize*4;
	//	screenPositions[m]->atariDisassembleNumberOfLines = 46;
	screenPositions[m]->atariDisassembleNumberOfLines = 29;
	screenPositions[m]->atariDisassembleShowHexCodes = true;
	screenPositions[m]->atariDisassembleShowCodeCycles = true;
	screenPositions[m]->atariDisassembleShowLabels = true;
	screenPositions[m]->atariDisassembleNumberOfLabelCharacters = 20;
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 0.0f;
	screenPositions[m]->atariDataDumpY = SCREEN_HEIGHT/2.0f + screenPositions[m]->atariDisassembleFontSize*5 + 2;
	screenPositions[m]->atariDataDumpSizeX = 353.0f;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - screenPositions[m]->atariDataDumpY;
	screenPositions[m]->atariDataDumpFontSize = 5.3f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	screenPositions[m]->atariDataDumpShowSprites = false;
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapSizeX = 195.0f;
	screenPositions[m]->atariMemoryMapSizeY = 174.0f;
	screenPositions[m]->atariMemoryMapX = SCREEN_WIDTH-screenPositions[m]->atariMemoryMapSizeX - 20;
	screenPositions[m]->atariMemoryMapY = 180.5f;

	// ctrl+shift+f3
	m = SCREEN_LAYOUT_ATARI_SOURCE_CODE;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	scale = 0.35f;
	screenPositions[m]->atariScreenVisible = false;
	
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 7.0f;
	screenPositions[m]->atariDisassembleX = 1.0f; //503.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 15.8f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleNumberOfLines = 46;
	screenPositions[m]->atariDisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->atariDisassembleShowHexCodes = false;
	screenPositions[m]->atariDisassembleShowCodeCycles = false;
	screenPositions[m]->atariDisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->atariDisassembleShowLabels = false;
	screenPositions[m]->atariDisassembleNumberOfLabelCharacters = 10;
	screenPositions[m]->atariDataDumpVisible = false;
	
	screenPositions[m]->atariSourceCodeVisible = true;
	screenPositions[m]->atariSourceCodeX = screenPositions[m]->atariDisassembleSizeX + screenPositions[m]->atariDisassembleFontSize * 0.5f;
	screenPositions[m]->atariSourceCodeY = 1.0f + screenPositions[m]->atariDisassembleFontSize*2.0f;
	screenPositions[m]->atariSourceCodeSizeX = SCREEN_WIDTH-screenPositions[m]->atariSourceCodeX-2.0f;
	screenPositions[m]->atariSourceCodeSizeY = SCREEN_HEIGHT-4.0f-screenPositions[m]->atariSourceCodeY;
	screenPositions[m]->atariSourceCodeFontSize = 7.0f;
	
	
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = 220;
	screenPositions[m]->atariCpuStateY = 2.5f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	
	scale = 0.255f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = 478;
	screenPositions[m]->atariScreenY = 0.0f;
	
	//
	m = SCREEN_LAYOUT_ATARI_DISPLAY_LITE;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;
	
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 7.0f;
	screenPositions[m]->atariDisassembleX = 1.0f; //503.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 25.8f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleNumberOfLines = 46;
	screenPositions[m]->atariDisassembleCodeMnemonicsOffset = +0.75f;
	screenPositions[m]->atariDisassembleShowHexCodes = false;
	screenPositions[m]->atariDisassembleShowCodeCycles = true;
	screenPositions[m]->atariDisassembleCodeCyclesOffset = -0.5f;
	screenPositions[m]->atariDisassembleShowLabels = true;
	screenPositions[m]->atariDisassembleNumberOfLabelCharacters = 10;
	screenPositions[m]->atariDataDumpVisible = false;
	
	scale = 0.90f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = screenPositions[m]->atariDisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->atariScreenY = 13.0f;
	
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariDisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->atariCpuStateY = 2.5f;
	
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = screenPositions[m]->atariDisassembleFontSize * 25.0f + 10.5f;
	screenPositions[m]->atariDataDumpY = 230;
	screenPositions[m]->atariDataDumpSizeX = 277.0f;
	screenPositions[m]->atariDataDumpSizeY = 131.0f;
	screenPositions[m]->atariDataDumpFontSize = 5.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize*0.75f;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.28f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->atariDataDumpShowDataCharacters = true;
	screenPositions[m]->atariDataDumpShowCharacters = false;
	screenPositions[m]->atariDataDumpShowSprites = false;
	
	
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapSizeX = 112.0f;
	screenPositions[m]->atariMemoryMapSizeY = 130.0f;
	screenPositions[m]->atariMemoryMapX = SCREEN_WIDTH-screenPositions[m]->atariMemoryMapSizeX-2.5f;
	screenPositions[m]->atariMemoryMapY = 230;

	
#if defined(RUN_COMMODORE64)
	//
	m = SCREEN_LAYOUT_C64_AND_ATARI;
	screenPositions[m] = new CScreenLayout();
	screenPositions[m]->debugOnAtari = true;
	screenPositions[m]->debugOnC64 = true;
	screenPositions[m]->debugOnDrive1541 = false;

	
	screenPositions[m]->atariDisassembleVisible = true;
	screenPositions[m]->atariDisassembleFontSize = 4.0f;
	screenPositions[m]->atariDisassembleX = 1.0f;
	screenPositions[m]->atariDisassembleY = 1.0f;
	screenPositions[m]->atariDisassembleSizeX = screenPositions[m]->atariDisassembleFontSize * 15.0f;
	screenPositions[m]->atariDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->atariDisassembleNumberOfLines = 83;
	screenPositions[m]->atariDisassembleShowHexCodes = false;
	screenPositions[m]->atariDisassembleShowCodeCycles = false;

	screenPositions[m]->c64DisassembleVisible = true;
	screenPositions[m]->c64DisassembleFontSize = 4.0f;
	screenPositions[m]->c64DisassembleY = 1.0f;
	screenPositions[m]->c64DisassembleSizeX = screenPositions[m]->c64DisassembleFontSize * 15.0f;
	screenPositions[m]->c64DisassembleX = SCREEN_WIDTH-screenPositions[m]->c64DisassembleSizeX-1.0f;
	screenPositions[m]->c64DisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->c64DisassembleNumberOfLines = 83;
	screenPositions[m]->c64DisassembleShowHexCodes = false;
	screenPositions[m]->c64DisassembleShowCodeCycles = false;

	scale = 0.670f;
	screenPositions[m]->atariScreenVisible = true;
	screenPositions[m]->atariScreenY = 10.5f;
	screenPositions[m]->atariScreenSizeX = (float)debugInterfaceAtari->GetScreenSizeX() * scale;
	screenPositions[m]->atariScreenSizeY = (float)debugInterfaceAtari->GetScreenSizeY() * scale;
	screenPositions[m]->atariScreenX = screenPositions[m]->atariDisassembleSizeX-15; //SCREEN_WIDTH - screenPositions[m]->atariScreenSizeX-3.0f;
	
	screenPositions[m]->atariCpuStateVisible = true;
	screenPositions[m]->atariCpuStateX = screenPositions[m]->atariScreenX + 17;
	screenPositions[m]->atariCpuStateY = 0.0f;
	screenPositions[m]->atariCpuStateFontSize = 5.0f;

	scale = 0.590f;
	screenPositions[m]->c64ScreenVisible = true;
	screenPositions[m]->c64ScreenY = 10.5f;
	screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
	screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
	screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64DisassembleSizeX - screenPositions[m]->c64ScreenSizeX-3.0f;
	
	screenPositions[m]->c64CpuStateVisible = true;
	screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
	screenPositions[m]->c64CpuStateY = 0.0f;
	screenPositions[m]->c64CpuStateFontSize = 5.0f;
	

	
	///
	screenPositions[m]->atariMemoryMapVisible = true;
	screenPositions[m]->atariMemoryMapX = 62.0f;
	screenPositions[m]->atariMemoryMapY = 173.0f;
	screenPositions[m]->atariMemoryMapSizeX = 222.0f;
	screenPositions[m]->atariMemoryMapSizeY = 186.0f;

	screenPositions[m]->c64MemoryMapVisible = true;
	screenPositions[m]->c64MemoryMapX = 62.0f + screenPositions[m]->atariMemoryMapSizeX + 10;
	screenPositions[m]->c64MemoryMapY = 173.0f;
	screenPositions[m]->c64MemoryMapSizeX = screenPositions[m]->atariMemoryMapSizeX;
	screenPositions[m]->c64MemoryMapSizeY = screenPositions[m]->atariMemoryMapSizeY;

	/*
	screenPositions[m]->atariDataDumpVisible = true;
	screenPositions[m]->atariDataDumpX = 108.0f;
	screenPositions[m]->atariDataDumpY = 196.0f;
	screenPositions[m]->atariDataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->atariDataDumpSizeY = SCREEN_HEIGHT - 198.0f;
	screenPositions[m]->atariDataDumpFontSize = 6.0f;
	screenPositions[m]->atariDataDumpGapAddress = screenPositions[m]->atariDataDumpFontSize;
	screenPositions[m]->atariDataDumpGapHexData = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpGapDataCharacters = screenPositions[m]->atariDataDumpFontSize*0.5f;
	screenPositions[m]->atariDataDumpNumberOfBytesPerLine = 16;
	screenPositions[m]->atariDataDumpShowSprites = false;
	screenPositions[m]->atariDataDumpShowCharacters = true;
	*/
#endif
	
#endif
	
	// ^^ RUN_ATARI ^^
	
#if defined(RUN_NES)
	m = SCREEN_LAYOUT_NES_ONLY;
	screenPositions[m] = new CScreenLayout();
	scale = (float)SCREEN_HEIGHT / (float)debugInterfaceNes->GetScreenSizeY();
	screenPositions[m]->nesScreenVisible = true;
	screenPositions[m]->nesScreenSizeX = (float)debugInterfaceNes->GetScreenSizeX() * scale;
	screenPositions[m]->nesScreenSizeY = (float)debugInterfaceNes->GetScreenSizeY() * scale;
	screenPositions[m]->nesScreenX = ((float)SCREEN_WIDTH-screenPositions[m]->nesScreenSizeX)/2.0f - 0.78f;
	screenPositions[m]->nesScreenY = 0.0f;
	screenPositions[m]->debugOnNes = true;
	screenPositions[m]->debugOnAtari = false;
	screenPositions[m]->debugOnC64 = false;
	screenPositions[m]->debugOnDrive1541 = false;

	
	m = SCREEN_LAYOUT_NES_DATA_DUMP;
	screenPositions[m] = new CScreenLayout();
	scale = 0.676f * 1.13f;
	screenPositions[m]->nesScreenVisible = true;
	screenPositions[m]->nesScreenY = 10.5f;
	screenPositions[m]->nesScreenSizeX = (float)debugInterfaceNes->GetScreenSizeX() * scale;
	screenPositions[m]->nesScreenSizeY = (float)debugInterfaceNes->GetScreenSizeY() * scale;
	screenPositions[m]->nesScreenX = SCREEN_WIDTH - screenPositions[m]->nesScreenSizeX-3.0f - screenPositions[m]->nesScreenSizeX * 0.1666;
	
	screenPositions[m]->nesCpuStateVisible = true;
	screenPositions[m]->nesCpuStateX = screenPositions[m]->nesScreenX;
	screenPositions[m]->nesCpuStateY = 0.0f;
	screenPositions[m]->nesCpuStateFontSize = 5.0f;
	
	screenPositions[m]->nesDisassembleVisible = true;
	screenPositions[m]->nesDisassembleFontSize = 7.0f;
	screenPositions[m]->nesDisassembleX = 1.0f;
	screenPositions[m]->nesDisassembleY = 1.0f;
	screenPositions[m]->nesDisassembleSizeX = screenPositions[m]->nesDisassembleFontSize * 15.0f;
	screenPositions[m]->nesDisassembleSizeY = SCREEN_HEIGHT-4.0f;
	screenPositions[m]->nesDisassembleNumberOfLines = 46;
	
	screenPositions[m]->nesMemoryMapVisible = true;
	screenPositions[m]->nesMemoryMapX = 112.0f;
	screenPositions[m]->nesMemoryMapY = 1.0f;
	screenPositions[m]->nesMemoryMapSizeX = 199.0f;
	screenPositions[m]->nesMemoryMapSizeY = 192.0f;

	screenPositions[m]->nesDataDumpVisible = true;
	screenPositions[m]->nesDataDumpX = 108.0f;
	screenPositions[m]->nesDataDumpY = 196.0f;
	screenPositions[m]->nesDataDumpSizeX = SCREEN_WIDTH - 110.0f;
	screenPositions[m]->nesDataDumpSizeY = SCREEN_HEIGHT - 198.0f;
	screenPositions[m]->nesDataDumpFontSize = 6.0f;
	screenPositions[m]->nesDataDumpGapAddress = screenPositions[m]->nesDataDumpFontSize;
	screenPositions[m]->nesDataDumpGapHexData = screenPositions[m]->nesDataDumpFontSize*0.5f;
	screenPositions[m]->nesDataDumpGapDataCharacters = screenPositions[m]->nesDataDumpFontSize*0.5f;
	screenPositions[m]->nesDataDumpNumberOfBytesPerLine = 16;
	
	
#endif

	guiRenderFrameCounter = 0;
	
	isShowingRasterCross = false;
	fontDisassemble = guiMain->fntConsole;
}

void CViewC64::SetLayout(int newScreenLayoutId)
{
	SwitchToScreenLayout(newScreenLayoutId);
}

void CViewC64::RefreshLayout()
{
	SwitchToScreenLayout(currentScreenLayoutId);
}

void CViewC64::SwitchToScreenLayout(int newScreenLayoutId)
{
	LOGD("SWITCH to screen layout id #%d", newScreenLayoutId);

	if (this->selectedDebugInterface == NULL)
	{
		guiMain->ShowMessage("Emulator not selected");
		
		// TODO: set layout to select emulator
		return;
	}
	
	// TODO: MOVE ME:
	
	// TODO: TEMPORARY FORCE ATARI AND MAP C64 LAYOUTS
//	LOGTODO("atari & c64 & nes layout to be done by emu switch");
//	newScreenLayoutId = SCREEN_LAYOUT_C64_AND_ATARI;
	
#if defined(RUN_ATARI)
	// TODO: this is temporary to allow a simple switch between two emulators
	//       re-use shortcuts. we need to properly map new layouts to new shortcuts.
	//       and generic emulator stuff.
	//       Atari is not priority for now so let's have it simple just to be working for demoing
	if (this->selectedDebugInterface->GetEmulatorType() == EMULATOR_TYPE_ATARI800)
	{
		switch(newScreenLayoutId)
		{
			case SCREEN_LAYOUT_C64_ONLY:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_ONLY; break;
			case SCREEN_LAYOUT_C64_DATA_DUMP:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_DATA_DUMP; break;
			case SCREEN_LAYOUT_C64_DEBUGGER:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_DEBUGGER; break;
			case SCREEN_LAYOUT_C64_SHOW_STATES:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_SHOW_STATES; break;
			case SCREEN_LAYOUT_C64_MEMORY_MAP:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_MEMORY_MAP; break;
			case SCREEN_LAYOUT_C64_MONITOR_CONSOLE:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE; break;
			case SCREEN_LAYOUT_C64_CYCLER:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_CYCLER; break;
			case SCREEN_LAYOUT_C64_VIC_DISPLAY_LITE:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_DISPLAY_LITE; break;
			case SCREEN_LAYOUT_C64_SOURCE_CODE:
				newScreenLayoutId = SCREEN_LAYOUT_ATARI_SOURCE_CODE; break;
			default:
				break;
		}
	}
#elif defined(RUN_NES)

	if (this->selectedDebugInterface->GetEmulatorType() == EMULATOR_TYPE_NESTOPIA)
	{
		switch(newScreenLayoutId)
		{
			case SCREEN_LAYOUT_C64_ONLY:
				newScreenLayoutId = SCREEN_LAYOUT_NES_ONLY; break;
			case SCREEN_LAYOUT_C64_DATA_DUMP:
				newScreenLayoutId = SCREEN_LAYOUT_NES_DATA_DUMP; break;
//			case SCREEN_LAYOUT_C64_DEBUGGER:
//				newScreenLayoutId = SCREEN_LAYOUT_NES_DEBUGGER; break;
//			case SCREEN_LAYOUT_C64_SHOW_STATES:
//				newScreenLayoutId = SCREEN_LAYOUT_NES_SHOW_STATES; break;
//			case SCREEN_LAYOUT_C64_MEMORY_MAP:
//				newScreenLayoutId = SCREEN_LAYOUT_NES_MEMORY_MAP; break;
//			case SCREEN_LAYOUT_C64_MONITOR_CONSOLE:
//				newScreenLayoutId = SCREEN_LAYOUT_NES_MONITOR_CONSOLE; break;
			default:
				break;
		}
	}
#elif defined(RUN_COMMODOREC64)
	if (newScreenLayoutId > SCREEN_LAYOUT_C64_SOURCE_CODE)
	{
		newScreenLayoutId = SCREEN_LAYOUT_C64_DATA_DUMP;
	}
#endif
	

	if (newScreenLayoutId < 0 || newScreenLayoutId >= SCREEN_LAYOUT_MAX)
	{
		LOGError("CViewC64::SwitchToScreenLayout: newScreenLayoutId=%d", newScreenLayoutId);
		return;
	}
	
	CScreenLayout *screenLayout = screenPositions[newScreenLayoutId];

	if (screenLayout == NULL)
	{
		// no screen layout initialized
		LOGError("CViewC64::SwitchToScreenLayout: newScreenLayoutId=%d not defined", newScreenLayoutId);
		return;
	}
	
	// UX workaround for VICE monitor console overlapping screen
	if (debugInterfaceC64 != NULL && newScreenLayoutId == SCREEN_LAYOUT_C64_MONITOR_CONSOLE)
	{
		int m = SCREEN_LAYOUT_C64_MONITOR_CONSOLE;
		if (c64SettingsUseNativeEmulatorMonitor)
		{
			float scale = 0.461f;
			screenPositions[m]->c64ScreenVisible = true;
			screenPositions[m]->c64ScreenY = 10.5f;
			screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
			screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
			screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
			
			screenPositions[m]->c64CpuStateVisible = true;
			screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
			screenPositions[m]->c64CpuStateY = 0.0f;
			screenPositions[m]->c64CpuStateFontSize = 5.0f;

			screenPositions[m]->c64MonitorConsoleVisible = true;
			screenPositions[m]->c64MonitorConsoleX = 1.0f;
			screenPositions[m]->c64MonitorConsoleY = 1.0f;
			screenPositions[m]->c64MonitorConsoleFontScale = 1.25f;
			screenPositions[m]->c64MonitorConsoleNumLines = 23;
			screenPositions[m]->c64MonitorConsoleSizeX = 393.0f;
			screenPositions[m]->c64MonitorConsoleSizeY = 194.371994; //screenPositions[m]->c64ScreenSizeY + 10.5f;
		}
		else
		{
			float scale = 0.676f;
			screenPositions[m]->c64ScreenVisible = true;
			screenPositions[m]->c64ScreenY = 10.5f;
			screenPositions[m]->c64ScreenSizeX = (float)debugInterfaceC64->GetScreenSizeX() * scale;
			screenPositions[m]->c64ScreenSizeY = (float)debugInterfaceC64->GetScreenSizeY() * scale;
			screenPositions[m]->c64ScreenX = SCREEN_WIDTH - screenPositions[m]->c64ScreenSizeX-3.0f;
			
			screenPositions[m]->c64MonitorConsoleVisible = true;
			screenPositions[m]->c64MonitorConsoleX = 1.0f;
			screenPositions[m]->c64MonitorConsoleY = 1.0f;
			screenPositions[m]->c64MonitorConsoleFontScale = 1.25f;
			screenPositions[m]->c64MonitorConsoleNumLines = 23;
			screenPositions[m]->c64MonitorConsoleSizeX = 310.0f;
			screenPositions[m]->c64MonitorConsoleSizeY = screenPositions[m]->c64ScreenSizeY + 10.5f;
		
			screenPositions[m]->c64CpuStateVisible = true;
			screenPositions[m]->c64CpuStateX = screenPositions[m]->c64ScreenX;
			screenPositions[m]->c64CpuStateY = 0.0f;
			screenPositions[m]->c64CpuStateFontSize = 5.0f;
		}
	}

	guiMain->LockMutex();

	if (c64SettingsIsInVicEditor)
	{
		viewVicEditor->DeactivateView();
		c64SettingsIsInVicEditor = false;
	}
	
	if (this->currentScreenLayoutId == SCREEN_LAYOUT_C64_VIC_DISPLAY)
	{
		viewC64->viewC64VicDisplay->DeactivateView();
	}
	
	this->currentScreenLayoutId = newScreenLayoutId;
	c64SettingsDefaultScreenLayoutId = newScreenLayoutId;
	
	
#if defined(RUN_COMMODORE64)
	debugInterfaceC64->SetDebugOnC64(screenLayout->debugOnC64);
	debugInterfaceC64->SetDebugOnDrive1541(screenLayout->debugOnDrive1541);

	// screen
	viewC64ScreenWrapper->SetVisible(screenLayout->c64ScreenVisible);
	viewC64ScreenWrapper->SetPosition(screenLayout->c64ScreenX,
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
									screenLayout->c64DisassembleShowSourceCode,
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
									screenLayout->drive1541DisassembleShowSourceCode,
									screenLayout->drive1541DisassembleNumberOfLabelCharacters);

	// source code
	viewC64SourceCode->SetVisible(screenLayout->c64SourceCodeVisible);
	viewC64SourceCode->SetViewParameters(screenLayout->c64SourceCodeX,
										  screenLayout->c64SourceCodeY, posZ,
										  screenLayout->c64SourceCodeSizeX, screenLayout->c64SourceCodeSizeY,
										  this->fontDisassemble,
										  screenLayout->c64SourceCodeFontSize);

	
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
	viewC64MemoryDataDump->showDataCharacters = screenLayout->c64DataDumpShowDataCharacters;
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
	viewC64StateCIA->SetPosition(screenLayout->c64StateCIAX, screenLayout->c64StateCIAY, posZ, 380, 58);
	viewC64StateCIA->fontSize = screenLayout->c64StateCIAFontSize;
	viewC64StateCIA->renderCIA1 = screenLayout->c64StateCIARenderCIA1;
	viewC64StateCIA->renderCIA2 = screenLayout->c64StateCIARenderCIA2;

	viewC64StateSID->SetVisible(screenLayout->c64StateSIDVisible);
	viewC64StateSID->SetPosition(screenLayout->c64StateSIDX, screenLayout->c64StateSIDY, posZ, 100, 100);
	viewC64StateSID->fontBytesSize = screenLayout->c64StateSIDFontSize;

	viewC64StateVIC->SetVisible(screenLayout->c64StateVICVisible);
	viewC64StateVIC->fontSize = screenLayout->c64StateVICFontSize;
	viewC64StateVIC->isVertical = screenLayout->c64StateVICIsVertical;
	viewC64StateVIC->showSprites = screenLayout->c64StateVICShowSprites;
	viewC64StateVIC->numValuesPerColumn = screenLayout->c64StateVICNumValuesPerColumn;
	viewC64StateVIC->SetPosition(screenLayout->c64StateVICX, screenLayout->c64StateVICY, screenLayout->c64StateVICSizeX, screenLayout->c64StateVICSizeY);

	viewC64StateREU->SetVisible(screenLayout->c64StateREUVisible);
	viewC64StateREU->SetPosition(screenLayout->c64StateREUX, screenLayout->c64StateREUY, posZ, 380, 58);
	viewC64StateREU->fontSize = screenLayout->c64StateREUFontSize;

	viewC64EmulationCounters->SetVisible(screenLayout->c64EmulationCountersVisible);
	viewC64EmulationCounters->SetPosition(screenLayout->c64EmulationCountersX, screenLayout->c64EmulationCountersY, posZ, 380, 58);
	viewC64EmulationCounters->fontSize = screenLayout->c64EmulationCountersFontSize;

	viewDrive1541StateVIA->SetVisible(screenLayout->drive1541StateVIAVisible);
	viewDrive1541StateVIA->SetPosition(screenLayout->drive1541StateVIAX, screenLayout->drive1541StateVIAY, posZ, 240, 50);
	viewDrive1541StateVIA->fontSize = screenLayout->drive1541StateVIAFontSize;
	viewDrive1541StateVIA->renderVIA1 = screenLayout->drive1541StateVIARenderVIA1;
	viewDrive1541StateVIA->renderVIA2 = screenLayout->drive1541StateVIARenderVIA2;
	viewDrive1541StateVIA->renderDriveLED = screenLayout->drive1541StateVIARenderDriveLED;
	viewDrive1541StateVIA->isVertical = screenLayout->drive1541StateVIAIsVertical;

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
	
	viewC64MonitorConsole->SetVisible(screenLayout->c64MonitorConsoleVisible);
	viewC64MonitorConsole->SetPosition(screenLayout->c64MonitorConsoleX, screenLayout->c64MonitorConsoleY, posZ,
									screenLayout->c64MonitorConsoleSizeX, screenLayout->c64MonitorConsoleSizeY,
									screenLayout->c64MonitorConsoleFontScale, screenLayout->c64MonitorConsoleNumLines);
	
	// cpu state
	viewC64StateCPU->SetVisible(screenLayout->c64CpuStateVisible);
	viewC64StateCPU->SetPosition(screenLayout->c64CpuStateX, screenLayout->c64CpuStateY);
	viewC64StateCPU->SetFont(this->fontDisassemble, screenLayout->c64CpuStateFontSize);
	
	viewDriveStateCPU->SetVisible(screenLayout->drive1541CpuStateVisible);
	viewDriveStateCPU->SetPosition(screenLayout->drive1541CpuStateX, screenLayout->drive1541CpuStateY);
	viewDriveStateCPU->SetFont(this->fontDisassemble, screenLayout->drive1541CpuStateFontSize);
	
	// all graphics
	viewC64AllGraphics->SetVisible(screenLayout->c64AllGraphicsVisible);
	viewC64AllGraphics->SetPosition(screenLayout->c64AllGraphicsX, screenLayout->c64AllGraphicsY);
	
#endif
	
#ifdef RUN_ATARI
	// atari
	debugInterfaceAtari->SetDebugOn(screenLayout->debugOnAtari);

	viewAtariScreen->SetVisible(screenLayout->atariScreenVisible);
	viewAtariScreen->SetPosition(screenLayout->atariScreenX,
							   screenLayout->atariScreenY, posZ,
							   screenLayout->atariScreenSizeX,
							   screenLayout->atariScreenSizeY);
	viewAtariScreen->showGridLines = screenLayout->atariScreenShowGridLines;
	
	// zoomed screen
	viewAtariScreen->showZoomedScreen = screenLayout->atariScreenShowZoomedScreen;
	viewAtariScreen->SetZoomedScreenPos(screenLayout->atariScreenZoomedX, screenLayout->atariScreenZoomedY,
									  screenLayout->atariScreenZoomedSizeX, screenLayout->atariScreenZoomedSizeY);
	
	viewAtariStateCPU->SetVisible(screenLayout->atariCpuStateVisible);
	viewAtariStateCPU->SetPosition(screenLayout->atariCpuStateX, screenLayout->atariCpuStateY);
	viewAtariStateCPU->SetFont(this->fontDisassemble, screenLayout->atariCpuStateFontSize);


	viewAtariDisassemble->SetVisible(screenLayout->atariDisassembleVisible);
	viewAtariDisassemble->SetViewParameters(screenLayout->atariDisassembleX,
											screenLayout->atariDisassembleY, posZ,
											screenLayout->atariDisassembleSizeX, screenLayout->atariDisassembleSizeY,
											this->fontDisassemble,
											screenLayout->atariDisassembleFontSize,
											screenLayout->atariDisassembleNumberOfLines,
											screenLayout->atariDisassembleCodeMnemonicsOffset,
											screenLayout->atariDisassembleShowHexCodes,
											screenLayout->atariDisassembleShowCodeCycles,
											screenLayout->atariDisassembleCodeCyclesOffset,
											screenLayout->atariDisassembleShowLabels,
											false,
											screenLayout->atariDisassembleNumberOfLabelCharacters);
	
	// source code
	viewAtariSourceCode->SetVisible(screenLayout->atariSourceCodeVisible);
	viewAtariSourceCode->SetViewParameters(screenLayout->atariSourceCodeX,
										 screenLayout->atariSourceCodeY, posZ,
										 screenLayout->atariSourceCodeSizeX, screenLayout->atariSourceCodeSizeY,
										 this->fontDisassemble,
										 screenLayout->atariSourceCodeFontSize);

	// data dump
	viewAtariMemoryDataDump->SetVisible(screenLayout->atariDataDumpVisible);
	viewAtariMemoryDataDump->fontSize = screenLayout->atariDataDumpFontSize;
	viewAtariMemoryDataDump->numberOfBytesPerLine = screenLayout->atariDataDumpNumberOfBytesPerLine;
	viewAtariMemoryDataDump->SetPosition(screenLayout->atariDataDumpX,
									   screenLayout->atariDataDumpY, posZ,
									   screenLayout->atariDataDumpSizeX,
									   screenLayout->atariDataDumpSizeY);
	viewAtariMemoryDataDump->gapAddress = screenLayout->atariDataDumpGapAddress;
	viewAtariMemoryDataDump->gapHexData = screenLayout->atariDataDumpGapHexData;
	viewAtariMemoryDataDump->gapDataCharacters = screenLayout->atariDataDumpGapDataCharacters;
	viewAtariMemoryDataDump->showDataCharacters = screenLayout->atariDataDumpShowDataCharacters;
	viewAtariMemoryDataDump->showCharacters = screenLayout->atariDataDumpShowCharacters;
	viewAtariMemoryDataDump->showSprites = screenLayout->atariDataDumpShowSprites;

	viewAtariMemoryMap->SetVisible(screenLayout->atariMemoryMapVisible);
	viewAtariMemoryMap->SetPosition(screenLayout->atariMemoryMapX,
								  screenLayout->atariMemoryMapY, posZ,
								  screenLayout->atariMemoryMapSizeX,
								  screenLayout->atariMemoryMapSizeY);

	viewAtariStateANTIC->SetVisible(screenLayout->atariStateANTICVisible);
	viewAtariStateANTIC->SetPosition(screenLayout->atariStateANTICX, screenLayout->atariStateANTICY, posZ, 100, 100);
	viewAtariStateANTIC->fontSize = screenLayout->atariStateANTICFontSize;

	viewAtariStateGTIA->SetVisible(screenLayout->atariStateGTIAVisible);
	viewAtariStateGTIA->SetPosition(screenLayout->atariStateGTIAX, screenLayout->atariStateGTIAY, posZ, 100, 100);
	viewAtariStateGTIA->fontSize = screenLayout->atariStateGTIAFontSize;

	viewAtariStatePIA->SetVisible(screenLayout->atariStatePIAVisible);
	viewAtariStatePIA->SetPosition(screenLayout->atariStatePIAX, screenLayout->atariStatePIAY, posZ, 100, 100);
	viewAtariStatePIA->fontSize = screenLayout->atariStatePIAFontSize;

	viewAtariStatePOKEY->fontSize = screenLayout->atariStatePOKEYFontSize;
	viewAtariStatePOKEY->SetVisible(screenLayout->atariStatePOKEYVisible);
	viewAtariStatePOKEY->SetPosition(screenLayout->atariStatePOKEYX, screenLayout->atariStatePOKEYY, posZ, 100, 100);

	viewAtariMonitorConsole->SetVisible(screenLayout->atariMonitorConsoleVisible);
	viewAtariMonitorConsole->SetPosition(screenLayout->atariMonitorConsoleX, screenLayout->atariMonitorConsoleY, posZ,
									screenLayout->atariMonitorConsoleSizeX, screenLayout->atariMonitorConsoleSizeY,
									screenLayout->atariMonitorConsoleFontScale, screenLayout->atariMonitorConsoleNumLines);

	viewAtariEmulationCounters->SetVisible(screenLayout->atariEmulationCountersVisible);
	viewAtariEmulationCounters->SetPosition(screenLayout->atariEmulationCountersX, screenLayout->atariEmulationCountersY, posZ, 380, 58);
	viewAtariEmulationCounters->fontSize = screenLayout->atariEmulationCountersFontSize;

#endif
	
#ifdef RUN_NES
	// nes
	debugInterfaceNes->SetDebugOn(screenLayout->debugOnNes);
	
	viewNesScreen->SetVisible(screenLayout->nesScreenVisible);
	viewNesScreen->SetPosition(screenLayout->nesScreenX,
								 screenLayout->nesScreenY, posZ,
								 screenLayout->nesScreenSizeX,
								 screenLayout->nesScreenSizeY);
	viewNesScreen->showGridLines = screenLayout->nesScreenShowGridLines;
	
	// zoomed screen
	viewNesScreen->showZoomedScreen = screenLayout->nesScreenShowZoomedScreen;
	viewNesScreen->SetZoomedScreenPos(screenLayout->nesScreenZoomedX, screenLayout->nesScreenZoomedY,
										screenLayout->nesScreenZoomedSizeX, screenLayout->nesScreenZoomedSizeY);
	
	viewNesStateCPU->SetVisible(screenLayout->nesCpuStateVisible);
	viewNesStateCPU->SetPosition(screenLayout->nesCpuStateX, screenLayout->nesCpuStateY);
	viewNesStateCPU->SetFont(this->fontDisassemble, screenLayout->nesCpuStateFontSize);
	
	
	viewNesDisassemble->SetVisible(screenLayout->nesDisassembleVisible);
	viewNesDisassemble->SetViewParameters(screenLayout->nesDisassembleX,
											screenLayout->nesDisassembleY, posZ,
											screenLayout->nesDisassembleSizeX, screenLayout->nesDisassembleSizeY,
											this->fontDisassemble,
											screenLayout->nesDisassembleFontSize,
											screenLayout->nesDisassembleNumberOfLines,
											screenLayout->nesDisassembleCodeMnemonicsOffset,
											screenLayout->nesDisassembleShowHexCodes,
											screenLayout->nesDisassembleShowCodeCycles,
											screenLayout->nesDisassembleCodeCyclesOffset,
											screenLayout->nesDisassembleShowLabels,
											false,
											screenLayout->nesDisassembleNumberOfLabelCharacters);
	
	// data dump
	viewNesMemoryDataDump->SetVisible(screenLayout->nesDataDumpVisible);
	viewNesMemoryDataDump->fontSize = screenLayout->nesDataDumpFontSize;
	viewNesMemoryDataDump->numberOfBytesPerLine = screenLayout->nesDataDumpNumberOfBytesPerLine;
	viewNesMemoryDataDump->SetPosition(screenLayout->nesDataDumpX,
										 screenLayout->nesDataDumpY, posZ,
										 screenLayout->nesDataDumpSizeX,
										 screenLayout->nesDataDumpSizeY);
	viewNesMemoryDataDump->gapAddress = screenLayout->nesDataDumpGapAddress;
	viewNesMemoryDataDump->gapHexData = screenLayout->nesDataDumpGapHexData;
	viewNesMemoryDataDump->gapDataCharacters = screenLayout->nesDataDumpGapDataCharacters;
	viewNesMemoryDataDump->showCharacters = screenLayout->nesDataDumpShowCharacters;
	viewNesMemoryDataDump->showSprites = screenLayout->nesDataDumpShowSprites;
	
	viewNesMemoryMap->SetVisible(screenLayout->nesMemoryMapVisible);
	viewNesMemoryMap->SetPosition(screenLayout->nesMemoryMapX,
									screenLayout->nesMemoryMapY, posZ,
									screenLayout->nesMemoryMapSizeX,
									screenLayout->nesMemoryMapSizeY);

//
//	viewNesStateANTIC->SetVisible(screenLayout->nesStateANTICVisible);
//	viewNesStateANTIC->SetPosition(screenLayout->nesStateANTICX, screenLayout->nesStateANTICY, posZ, 100, 100);
//	viewNesStateANTIC->fontSize = screenLayout->nesStateANTICFontSize;
//
	
#endif
	
	
	//
	// bunch of ux workarounds must be here, as always
	//

	if (newScreenLayoutId == SCREEN_LAYOUT_C64_MONITOR_CONSOLE)
	{
		SetFocus(viewC64MonitorConsole);
	}
	else if (newScreenLayoutId == SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE)
	{
		SetFocus(viewAtariMonitorConsole);
	}
	else
	{
		if (focusElement == NULL || (focusElement && focusElement->visible == false))
		{
			if (debugInterfaceC64 && viewC64ScreenWrapper->visible)
			{
				SetFocus(viewC64ScreenWrapper);
			}
			else if (debugInterfaceAtari && viewAtariScreen->visible)
			{
				SetFocus(viewAtariScreen);
			}
			else if (debugInterfaceNes && viewNesScreen->visible)
			{
				SetFocus(viewNesScreen);
			}
		}
	}
	
	if (newScreenLayoutId == SCREEN_LAYOUT_C64_VIC_DISPLAY)
	{
		viewC64->viewC64VicDisplay->ActivateView();
	}

	if (newScreenLayoutId == SCREEN_LAYOUT_C64_MONITOR_CONSOLE)
	{
		viewC64->viewC64MonitorConsole->ActivateView();
	}

	if (newScreenLayoutId == SCREEN_LAYOUT_ATARI_MONITOR_CONSOLE)
	{
		viewC64->viewAtariMonitorConsole->ActivateView();
	}

	if (debugInterfaceC64 != NULL)
	{
		if (viewC64->viewC64ScreenWrapper->visible)
		{
			viewC64->viewC64ScreenWrapper->ActivateView();
		}
	}
	
	CheckMouseCursorVisibility();
	
	UpdateWatchVisible();

	// end of ux workarounds
	
	if (guiMain->currentView != this)
		guiMain->SetView(this);
	
	
	guiMain->UnlockMutex();
}

void CEmulationThreadC64::ThreadRun(void *data)
{
	ThreadSetName("c64");

	LOGD("CEmulationThreadC64::ThreadRun");
		
	viewC64->debugInterfaceC64->RunEmulationThread();
	
	LOGD("CEmulationThreadC64::ThreadRun: finished");
}

void CEmulationThreadAtari::ThreadRun(void *data)
{
	ThreadSetName("atari");
	
	viewC64->debugInterfaceAtari->SetMachineType(c64SettingsAtariMachineType);
	viewC64->debugInterfaceAtari->SetRamSizeOption(c64SettingsAtariRamSizeOption);
	viewC64->debugInterfaceAtari->SetVideoSystem(c64SettingsAtariVideoSystem);

	LOGD("CEmulationThreadAtari::ThreadRun");
	
	viewC64->debugInterfaceAtari->RunEmulationThread();
	
	LOGD("CEmulationThreadAtari::ThreadRun: finished");
}

void CEmulationThreadNes::ThreadRun(void *data)
{
	ThreadSetName("nes");
	
	LOGD("CEmulationThreadNes::ThreadRun");
	
	viewC64->debugInterfaceNes->RunEmulationThread();
	
	LOGD("CEmulationThreadNes::ThreadRun: finished");
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

#if defined(RUN_COMMODORE64)
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
#endif
	
#if defined(RUN_ATARI)
	
	viewAtariMemoryMap->CellsAnimationLogic();
	
#endif

	guiRenderFrameCounter++;
	
//	if (frameCounter % 2 == 0)
	{
		//if (viewC64ScreenWrapper->visible)   always do this anyway
		
		if (debugInterfaceC64 && viewC64Screen)
		{
			viewC64Screen->RefreshScreen();
		}

		if (debugInterfaceAtari && viewAtariScreen)
		{
			viewAtariScreen->RefreshScreen();
		}

		if (debugInterfaceNes && viewNesScreen)
		{
			viewNesScreen->RefreshScreen();
		}
	}
	
	
	//////////

#ifdef RUN_COMMODORE64
	// copy current state of VIC
	c64d_vicii_copy_state(&(this->currentViciiState));

	viewC64VicDisplay->UpdateViciiState();

	this->UpdateViciiColors();
	
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
	debugInterfaceC64->GetDrive1541CpuState(&diskCpuState);
	
	viewDrive1541Disassemble->SetCurrentPC(diskCpuState.lastValidPC);
#endif
	
	///
#ifdef RUN_ATARI
	viewAtariDisassemble->SetCurrentPC(debugInterfaceAtari->GetCpuPC());
#endif

#ifdef RUN_NES
	viewNesDisassemble->SetCurrentPC(debugInterfaceNes->GetCpuPC());
#endif

	//
	
	//
	// now render all visible views
	//
	//
	
	CGuiView::Render();

	//
	// and stuff what is left to render:
	//
	
#ifdef RUN_COMMODORE64
	if (viewC64->viewC64ScreenWrapper->visible)
	{
		viewC64ScreenWrapper->RenderRaster(rasterToShowX, rasterToShowY);
	}
	
	if (viewC64Screen->showZoomedScreen)
	{
		viewC64Screen->RenderZoomedScreen(rasterToShowX, rasterToShowY);
	}
#endif

	// render focus border
	if (focusElement != NULL)
	{
//		LOGD("focusElement=%x %s", focusElement, focusElement->name);
		if (currentScreenLayoutId != SCREEN_LAYOUT_C64_ONLY
			&& currentScreenLayoutId != SCREEN_LAYOUT_ATARI_ONLY
			&& currentScreenLayoutId != SCREEN_LAYOUT_NES_ONLY)
		{
			focusElement->RenderFocusBorder();
		}
	}
	
	// timeline for C64 only now
	if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
	{
		float gapY = 5.0f;
		
		float x = guiMain->mousePosX;
		float y = guiMain->mousePosY;
		
		if (debugInterfaceC64)
		{
			if (x >= viewC64Timeline->posX && x <= viewC64Timeline->posEndX
				&& y >= (viewC64Timeline->posY-gapY) && y <= viewC64Timeline->posEndY)
			{
				viewC64Timeline->Render();
			}
		}
		
		if (debugInterfaceAtari)
		{
			if (x >= viewAtariTimeline->posX && x <= viewAtariTimeline->posEndX
				&& y >= (viewAtariTimeline->posY-gapY) && y <= viewAtariTimeline->posEndY)
			{
				viewAtariTimeline->Render();
			}
		}
	}
	
	RenderPlugins();

//	// debug render fps
//	char buf[128];
//	sprintf(buf, "%-6.2f %-6.2f", debugInterface->emulationSpeed, debugInterface->emulationFrameRate);
//	
//	guiMain->fntConsole->BlitText(buf, 0, 0, -1, 15);

}

void CViewC64::RenderPlugins()
{
	// render plugins
	// TODO: generalize me, iterate over debug interfaces
	CDebugInterface *debugInterface = this->debugInterfaceC64;
	if (debugInterface)
	{
		for (std::list<CDebuggerEmulatorPlugin *>::iterator it = debugInterface->plugins.begin(); it != debugInterface->plugins.end(); it++)
		{
			CDebuggerEmulatorPlugin *plugin = *it;
			plugin->RenderGUI();
		}
	}
	debugInterface = this->debugInterfaceAtari;
	if (debugInterface)
	{
		for (std::list<CDebuggerEmulatorPlugin *>::iterator it = debugInterface->plugins.begin(); it != debugInterface->plugins.end(); it++)
		{
			CDebuggerEmulatorPlugin *plugin = *it;
			plugin->RenderGUI();
		}
	}
	debugInterface = this->debugInterfaceNes;
	if (debugInterface)
	{
		for (std::list<CDebuggerEmulatorPlugin *>::iterator it = debugInterface->plugins.begin(); it != debugInterface->plugins.end(); it++)
		{
			CDebuggerEmulatorPlugin *plugin = *it;
			plugin->RenderGUI();
		}
		
	}
	//////// ^^^ TODO
}

///////////////

void CViewC64::UpdateViciiColors()
{
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
}


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
		
		// TODO: make a list of avaliable interfaces and iterate
		if (debugInterfaceC64)
		{
			viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}
		
		if (debugInterfaceAtari)
		{
			viewAtariScreen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}

		if (debugInterfaceNes)
		{
			viewNesScreen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}
		
		if (shortcut == viewC64MainMenu->kbsOpenFile)
		{
			viewC64MainMenu->OpenDialogOpenFile();
			return true;
		}

		if (debugInterfaceC64)
		{
			// TODO: generalize this
			// check emulation scrubbing
			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackOneFrame)
			{
				LOGD(">>>>>>>>>................ REWIND -1");
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(-1);
				}
				guiMain->UnlockMutex();
				return true;
			}
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardOneFrame)
			{
				LOGD(">>>>>>>>>................ FORWARD +1");
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(+1);
				}
				guiMain->UnlockMutex();
				return true;
			}

			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackOneSecond)
			{
				LOGD(">>>>>>>>>................ REWIND -1s");
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceC64->GetEmulationFPS();
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(-emulationFPS);
				}
				guiMain->UnlockMutex();
				return true;
			}
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardOneSecond)
			{
				LOGD(">>>>>>>>>................ FORWARD +1s");
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceC64->GetEmulationFPS();
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(+emulationFPS);
				}
				guiMain->UnlockMutex();
				return true;
			}

			float scrubMultipleNumSeconds = 10;
			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackMultipleFrames)
			{
				LOGD(">>>>>>>>>................ REWIND -%fs", scrubMultipleNumSeconds);
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceC64->GetEmulationFPS();
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(-emulationFPS*scrubMultipleNumSeconds);
				}
				guiMain->UnlockMutex();
				return true;
			}
			
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardMultipleFrames)
			{
				LOGD(">>>>>>>>>................ FORWARD +%fs", scrubMultipleNumSeconds);
				guiMain->LockMutex();
				if (debugInterfaceVice->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceC64->GetEmulationFPS();
					debugInterfaceVice->snapshotsManager->RestoreSnapshotByNumFramesOffset(+emulationFPS*scrubMultipleNumSeconds);
				}
				guiMain->UnlockMutex();
				return true;
			}
			//
			
			if (viewC64Snapshots->ProcessKeyboardShortcut(shortcut))
			{
				return true;
			}
			
			else if (shortcut == viewC64MainMenu->kbsInsertD64)
			{
				viewC64MainMenu->OpenDialogInsertD64();
				return true;
			}

			else if (shortcut == viewC64MainMenu->kbsReloadAndRestart
					 || shortcut == viewC64MainMenu->kbsRestartPRG)
			{
				viewC64MainMenu->ReloadAndRestartPRG();
				return true;
			}

			else if (shortcut == viewC64MainMenu->kbsBreakpointsC64)
			{
				viewC64Breakpoints->SwitchBreakpointsScreen();
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsSnapshotsC64)
			{
				viewC64Snapshots->SwitchSnapshotsScreen();
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsVicEditorScreen)
			{
				viewVicEditor->SwitchToVicEditor();
				C64DebuggerStoreSettings();
				return true;
			}

			else if (shortcut == viewC64SettingsMenu->kbsDumpC64Memory)
			{
				viewC64SettingsMenu->OpenDialogDumpC64Memory();
				return true;
			}
			else if (shortcut == viewC64SettingsMenu->kbsDumpDrive1541Memory)
			{
				viewC64SettingsMenu->OpenDialogDumpDrive1541Memory();
				return true;
			}
			else if (shortcut == viewC64->keyboardShortcuts->kbsVicEditorExportFile)
			{
				viewVicEditor->exportMode = VICEDITOR_EXPORT_UNKNOWN;
				viewVicEditor->OpenDialogExportFile();
				return true;
			}
		}

		if (debugInterfaceAtari)
		{
			// TODO: generalize this
			// check emulation scrubbing
			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackOneFrame)
			{
				LOGD(">>>>>>>>>................ REWIND -1");
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(-1);
				}
				guiMain->UnlockMutex();
				return true;
			}
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardOneFrame)
			{
				LOGD(">>>>>>>>>................ FORWARD +1");
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(+1);
				}
				guiMain->UnlockMutex();
				return true;
			}
			
			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackOneSecond)
			{
				LOGD(">>>>>>>>>................ REWIND -1s");
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceAtari->GetEmulationFPS();
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(-emulationFPS);
				}
				guiMain->UnlockMutex();
				return true;
			}
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardOneSecond)
			{
				LOGD(">>>>>>>>>................ FORWARD +1s");
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceAtari->GetEmulationFPS();
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(+emulationFPS);
				}
				guiMain->UnlockMutex();
				return true;
			}
			
			float scrubMultipleNumSeconds = 10;
			if (shortcut == keyboardShortcuts->kbsScrubEmulationBackMultipleFrames)
			{
				LOGD(">>>>>>>>>................ REWIND -%ds", scrubMultipleNumSeconds);
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceAtari->GetEmulationFPS();
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(-emulationFPS*scrubMultipleNumSeconds);
				}
				guiMain->UnlockMutex();
				return true;
			}
			
			if (shortcut == keyboardShortcuts->kbsScrubEmulationForwardMultipleFrames)
			{
				LOGD(">>>>>>>>>................ FORWARD +%ds", scrubMultipleNumSeconds);
				guiMain->LockMutex();
				if (debugInterfaceAtari->snapshotsManager->isPerformingSnapshotRestore == false)
				{
					float emulationFPS = debugInterfaceAtari->GetEmulationFPS();
					debugInterfaceAtari->snapshotsManager->RestoreSnapshotByNumFramesOffset(+emulationFPS*scrubMultipleNumSeconds);
				}
				guiMain->UnlockMutex();
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsInsertATR)
			{
				viewC64MainMenu->OpenDialogInsertATR();
				return true;
			}

			if (viewAtariSnapshots->ProcessKeyboardShortcut(shortcut))
			{
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsBreakpointsAtari)
			{
				viewAtariBreakpoints->SwitchBreakpointsScreen();
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsSnapshotsAtari)
			{
				viewAtariSnapshots->SwitchSnapshotsScreen();
				return true;
			}
		}
		
		if (debugInterfaceNes)
		{
			if (viewNesSnapshots->ProcessKeyboardShortcut(shortcut))
			{
				return true;
			}
//			else if (shortcut == viewC64MainMenu->kbsBreakpointsNes)
//			{
//				viewNesBreakpoints->SwitchBreakpointsScreen();
//				return true;
//			}
			else if (shortcut == viewC64MainMenu->kbsSnapshotsNes)
			{
				viewNesSnapshots->SwitchSnapshotsScreen();
				return true;
			}
		}
		
		if (shortcut == viewC64MainMenu->kbsMainMenuScreen)
		{
			viewC64MainMenu->SwitchMainMenuScreen();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout1)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_ONLY);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout2)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_DATA_DUMP);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout3)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_DEBUGGER);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout4)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_1541_MEMORY_MAP);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout5)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_SHOW_STATES);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout6)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_MEMORY_MAP);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout7)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_1541_DEBUGGER);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout8)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_MONITOR_CONSOLE);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout9)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout10)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_CYCLER);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout11)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_VIC_DISPLAY_LITE);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout12)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_VIC_DISPLAY);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout13)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_SOURCE_CODE);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsScreenLayout14)
		{
			SwitchToScreenLayout(SCREEN_LAYOUT_C64_ALL_GRAPHICS);
			C64DebuggerStoreSettings();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsInsertCartridge)
		{
			viewC64MainMenu->OpenDialogInsertCartridge();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsInsertAtariCartridge)
		{
			viewC64MainMenu->OpenDialogInsertAtariCartridge();
			return true;
		}
		
		// code segments
		else if (shortcut == this->keyboardShortcuts->kbsNextCodeSegmentSymbols
				 || shortcut == this->keyboardShortcuts->kbsPreviousCodeSegmentSymbols)
		{
			// TODO: Generalize me
			CDebugInterface *debugInterface = NULL;
			if (viewC64->debugInterfaceC64)
			{
				debugInterface = viewC64->debugInterfaceC64;
			}
			else if (viewC64->debugInterfaceAtari)
			{
				debugInterface = viewC64->debugInterfaceAtari;
			}
			
			
			if (debugInterface->symbols->asmSource)
			{
				if (shortcut == this->keyboardShortcuts->kbsNextCodeSegmentSymbols)
				{
					debugInterface->symbols->asmSource->SelectNextSegment();
				}
				else
				{
					debugInterface->symbols->asmSource->SelectPreviousSegment();
				}
				char *buf = SYS_GetCharBuf();
				char *buf2 = debugInterface->symbols->asmSource->currentSelectedSegment->name->GetStdASCII();
				sprintf(buf, "Segment: %s", buf2);
				delete [] buf2;
				guiMain->ShowMessage(buf);
				SYS_ReleaseCharBuf(buf);
			}
		}
		
		// tape
		
		else if (shortcut == viewC64SettingsMenu->kbsTapeAttach)
		{
			viewC64->viewC64MainMenu->OpenDialogInsertTape();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsTapeDetach)
		{
			viewC64->debugInterfaceC64->DetachTape();
			guiMain->ShowMessage("Tape detached");
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsTapeStop)
		{
			viewC64->debugInterfaceC64->DatasetteStop();
			guiMain->ShowMessage("Datasette STOP");
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsTapePlay)
		{
			viewC64->debugInterfaceC64->DatasettePlay();
			guiMain->ShowMessage("Datasette PLAY");
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsTapeForward)
		{
			viewC64->debugInterfaceC64->DatasetteForward();
			guiMain->ShowMessage("Datasette FORWARD");
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsTapeRewind)
		{
			viewC64->debugInterfaceC64->DatasetteRewind();
			guiMain->ShowMessage("Datasette REWIND");
			return true;
		}
//		else if (shortcut == viewC64SettingsMenu->kbsTapeReset)
//		{
//			viewC64->debugInterfaceC64->DatasetteReset();
//			return true;
//		}
		
		else if (shortcut == viewC64SettingsMenu->kbsSwitchNextMaximumSpeed)
		{
			viewC64SettingsMenu->SwitchNextMaximumSpeed();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsSwitchPrevMaximumSpeed)
		{
			viewC64SettingsMenu->SwitchPrevMaximumSpeed();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsIsWarpSpeed)
		{
			SwitchIsWarpSpeed();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsDiskDriveReset)
		{
			debugInterfaceC64->DiskDriveReset();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsSoftReset)
		{
			SoftReset();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsHardReset)
		{
			HardReset();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsUseKeboardAsJoystick)
		{
			SwitchUseKeyboardAsJoystick();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsStepOverInstruction)
		{
			StepOverInstruction();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsStepBackInstruction)
		{
			guiMain->LockMutex();
			
			if (debugInterfaceC64)
			{
				debugInterfaceC64->snapshotsManager->RestoreSnapshotBackstepInstruction();
			}
			
			if (debugInterfaceAtari)
			{
				debugInterfaceAtari->snapshotsManager->RestoreSnapshotBackstepInstruction();
			}
			
			guiMain->UnlockMutex();
			return true;
		}
		
		else if (shortcut == keyboardShortcuts->kbsStepOneCycle)
		{
			StepOneCycle();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsRunContinueEmulation)
		{
			RunContinueEmulation();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsIsDataDirectlyFromRam)
		{
			SwitchIsDataDirectlyFromRam();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsToggleMulticolorImageDump)
		{
			SwitchIsMulticolorDataDump();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsShowRasterBeam)
		{
			SwitchIsShowRasterBeam();
			return true;
		}
		
		else if (shortcut == viewC64MainMenu->kbsMoveFocusToNextView)
		{
			MoveFocusToNextView();
			return true;
		}
		else if (shortcut == viewC64MainMenu->kbsMoveFocusToPreviousView)
		{
			MoveFocusToPrevView();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsCartridgeFreezeButton)
		{
			debugInterfaceC64->CartridgeFreezeButtonPressed();
			return true;
		}
		// TODO: move this to viewC64SettingsMenu key shortcut checks
		else if (shortcut == viewC64SettingsMenu->kbsClearMemoryMarkers)
		{
			viewC64SettingsMenu->ClearMemoryMarkers();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsResetCpuCycleAndFrameCounters)
		{
			viewC64SettingsMenu->ResetMainCpuDebugCycleAndFrameCounters();
			return true;
		}
		
		// TODO: refactoring generalize me
		if (viewC64->debugInterfaceC64)
		{
			if (shortcut == viewC64MainMenu->kbsBrowseD64)
			{
				viewFileD64->StartBrowsingD64(0);
				return true;
			}
			else if (shortcut == viewC64MainMenu->kbsStartFromDisk)
			{
				viewFileD64->StartDiskPRGEntry(0, true);
				return true;
			}
			else if (shortcut == viewC64SettingsMenu->kbsC64ProfilerStartStop)
			{
				viewC64SettingsMenu->C64ProfilerStartStop();
				return true;
			}
		}
		
		if (shortcut == keyboardShortcuts->kbsSaveScreenImageAsPNG)
		{
			viewVicEditor->SaveScreenshotAsPNG();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachEverything)
		{
			viewC64SettingsMenu->DetachEverything(true, true);
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachCartridge)
		{
			viewC64SettingsMenu->DetachCartridge(true);
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsDetachDiskImage)
		{
			viewC64SettingsMenu->DetachDiskImage();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsAutoJmpFromInsertedDiskFirstPrg)
		{
			viewC64SettingsMenu->ToggleAutoLoadFromInsertedDisk();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsAutoJmpAlwaysToLoadedPRGAddress)
		{
			viewC64SettingsMenu->ToggleAutoJmpAlwaysToLoadedPRGAddress();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsAutoJmpDoReset)
		{
			viewC64SettingsMenu->ToggleAutoJmpDoReset();
			return true;
		}
		else if (shortcut == viewC64SettingsMenu->kbsSwitchSoundOnOff)
		{
			this->ToggleSoundMute();
			return true;
		}
		else if (shortcut == keyboardShortcuts->kbsShowWatch)
		{
			// TODO: make generic
			if (viewC64->debugInterfaceC64)
			{
				if (viewC64MemoryDataDump->visible == true)
				{
					SetWatchVisible(true);
				}
				else
				{
					SetWatchVisible(false);
				}
			}

			if (viewC64->debugInterfaceAtari)
			{
				if (viewAtariMemoryDataDump->visible == true)
				{
					SetWatchVisible(true);
				}
				else
				{
					SetWatchVisible(false);
				}
			}

			return true;
		}
		
	}
	
	return false;
}

// TODO: refactor local viewC64MemoryDataDump->renderDataWithColors to global settings variable
void CViewC64::SwitchIsMulticolorDataDump()
{
	if (viewC64->viewC64VicDisplay->visible
		|| viewC64->viewVicEditor->visible)
	{
		viewC64->viewC64VicDisplay->backupRenderDataWithColors = !viewC64->viewC64VicDisplay->backupRenderDataWithColors;
	}
	else
	{
		viewC64MemoryDataDump->renderDataWithColors = !viewC64MemoryDataDump->renderDataWithColors;
		viewC64->viewC64VicDisplay->backupRenderDataWithColors = viewC64MemoryDataDump->renderDataWithColors;
		viewC64AllGraphics->UpdateRenderDataWithColors();
	}
}

void CViewC64::SetIsMulticolorDataDump(bool isMultiColor)
{
	if (viewC64->viewC64VicDisplay->visible
		|| viewC64->viewVicEditor->visible)
	{
		viewC64->viewC64VicDisplay->backupRenderDataWithColors = isMultiColor;
	}
	else
	{
		viewC64MemoryDataDump->renderDataWithColors = isMultiColor;
		viewC64->viewC64VicDisplay->backupRenderDataWithColors = isMultiColor;
		viewC64AllGraphics->UpdateRenderDataWithColors();
	}
}


void CViewC64::SwitchIsShowRasterBeam()
{
	this->isShowingRasterCross = !this->isShowingRasterCross;
}

void CViewC64::StepOverInstruction()
{
	LOGTODO("CViewC64::StepOverInstruction(): make GENERIC");

	// TODO: make generic
	if (debugInterfaceC64)
	{
		if (debugInterfaceC64->GetDebugMode() == DEBUGGER_MODE_RUNNING)
		{
			debugInterfaceC64->SetTemporaryBreakpointPC(-1);
			debugInterfaceC64->SetTemporaryDrive1541BreakpointPC(-1);
		}
		
		debugInterfaceC64->snapshotsManager->CancelRestore();
		debugInterfaceC64->SetDebugMode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
	}

	if (debugInterfaceAtari)
	{
		debugInterfaceAtari->snapshotsManager->CancelRestore();
		debugInterfaceAtari->SetDebugMode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
	}

	if (debugInterfaceNes)
	{
		debugInterfaceNes->snapshotsManager->CancelRestore();
		debugInterfaceNes->SetDebugMode(DEBUGGER_MODE_RUN_ONE_INSTRUCTION);
	}
}

void CViewC64::StepOneCycle()
{
	LOGTODO("CViewC64::StepOneCycle(): make generic");
	if (debugInterfaceC64)
	{
		if (debugInterfaceC64->GetDebugMode() == DEBUGGER_MODE_RUNNING)
		{
			debugInterfaceC64->SetTemporaryBreakpointPC(-1);
			debugInterfaceC64->SetTemporaryDrive1541BreakpointPC(-1);
		}
		
		debugInterfaceC64->SetDebugMode(DEBUGGER_MODE_RUN_ONE_CYCLE);
	}
	
	if (debugInterfaceAtari)
	{
		LOGTODO("CViewC64::StepOneCycle: ATARI");
//		if (debugInterfaceC64->GetDebugMode() == DEBUGGER_MODE_RUNNING)
//		{
//			debugInterfaceC64->SetTemporaryBreakpointPC(-1);
//			debugInterfaceC64->SetTemporaryDrive1541BreakpointPC(-1);
//		}
//		
//		debugInterfaceC64->SetDebugMode(DEBUGGER_MODE_RUN_ONE_CYCLE);
	}
	
	if (debugInterfaceNes)
	{
		LOGTODO("CViewC64::StepOneCycle: NES");
		//		if (debugInterfaceC64->GetDebugMode() == DEBUGGER_MODE_RUNNING)
		//		{
		//			debugInterfaceC64->SetTemporaryBreakpointPC(-1);
		//			debugInterfaceC64->SetTemporaryDrive1541BreakpointPC(-1);
		//		}
		//
		//		debugInterfaceC64->SetDebugMode(DEBUGGER_MODE_RUN_ONE_CYCLE);
	}
}

void CViewC64::HardReset()
{
	if (debugInterfaceC64)
	{
		debugInterfaceC64->HardReset();
		viewC64MemoryMap->ClearExecuteMarkers();
		viewC64->viewDrive1541MemoryMap->ClearExecuteMarkers();
	}
	
	if (debugInterfaceAtari)
	{
		debugInterfaceAtari->HardReset();
		viewAtariMemoryMap->ClearExecuteMarkers();
	}
	
	if (debugInterfaceNes)
	{
		debugInterfaceNes->HardReset();
		LOGTODO("                           viewNesMemoryMap                     !!!!!!!!!! ");
		//				viewNesMemoryMap->ClearExecuteMarkers();
	}
	
	if (c64SettingsIsInVicEditor)
	{
		viewC64->viewC64VicControl->UnlockAll();
	}
}

void CViewC64::SoftReset()
{
	// TODO: make a list of avaliable interfaces and iterate
	if (debugInterfaceC64)
	{
		debugInterfaceC64->Reset();
	}
	
	if (debugInterfaceAtari)
	{
		debugInterfaceAtari->Reset();
	}
	
	if (debugInterfaceNes)
	{
		debugInterfaceNes->Reset();
	}
	
	if (c64SettingsIsInVicEditor)
	{
		viewC64->viewC64VicControl->UnlockAll();
	}
}

CViewDisassemble *CViewC64::GetActiveDisassembleView()
{
	if (debugInterfaceC64)
	{
		if (viewC64Disassemble->visible)
			return viewC64Disassemble;
		
		if (viewDrive1541Disassemble->visible)
			return viewDrive1541Disassemble;
	}
	
	if (debugInterfaceAtari)
	{
		if (viewAtariDisassemble->visible)
			return viewAtariDisassemble;
	}
	
	if (debugInterfaceNes)
	{
		if (viewNesDisassemble)
			return viewNesDisassemble;
	}
	
	return NULL;
}

void CViewC64::RunContinueEmulation()
{
	LOGTODO("CViewC64::RunContinueEmulation(): make generic");
	
	// TODO: make generic
	if (debugInterfaceC64)
	{
		debugInterfaceC64->SetTemporaryBreakpointPC(-1);
		debugInterfaceC64->SetTemporaryDrive1541BreakpointPC(-1);
		debugInterfaceC64->SetDebugMode(DEBUGGER_MODE_RUNNING);
	}

	if (debugInterfaceAtari)
	{
		debugInterfaceAtari->SetTemporaryBreakpointPC(-1);
		debugInterfaceAtari->SetDebugMode(DEBUGGER_MODE_RUNNING);
	}

	if (debugInterfaceNes)
	{
		debugInterfaceNes->SetTemporaryBreakpointPC(-1);
		debugInterfaceNes->SetDebugMode(DEBUGGER_MODE_RUNNING);
	}
}

void CViewC64::SwitchIsWarpSpeed()
{
	viewC64SettingsMenu->menuItemIsWarpSpeed->SwitchToNext();
}

void CViewC64::SwitchScreenLayout()
{
	int newScreenLayoutId = currentScreenLayoutId + 1;
	if (newScreenLayoutId == SCREEN_LAYOUT_MAX)
	{
		newScreenLayoutId = SCREEN_LAYOUT_C64_ONLY;
	}
	
	SwitchToScreenLayout(newScreenLayoutId);
}

void CViewC64::SwitchUseKeyboardAsJoystick()
{
	viewC64SettingsMenu->menuItemUseKeyboardAsJoystick->SwitchToNext();
}

void CViewC64::SwitchIsDataDirectlyFromRam()
{
	LOGTODO("CViewC64::SwitchIsDataDirectlyFromRam(): make generic");
	
	LOGError("CViewC64::SwitchIsDataDirectlyFromRam(): NOT IMPLEMENTED FOR ATARI");
	
	if (viewC64MemoryMap->isDataDirectlyFromRAM == false)
	{
		viewC64MemoryMap->isDataDirectlyFromRAM = true;
		viewC64MemoryDataDump->SetDataAdapter(debugInterfaceC64->dataAdapterC64DirectRam);
		viewDrive1541MemoryMap->isDataDirectlyFromRAM = true;
		viewDrive1541MemoryDataDump->SetDataAdapter(debugInterfaceC64->dataAdapterDrive1541DirectRam);
		
//		viewAtariMemoryMap->isDataDirectlyFromRAM = true;
//		viewAtariMemoryDataDump->SetDataAdapter(debugInterfaceAtari->data)
	}
	else
	{
		viewC64MemoryMap->isDataDirectlyFromRAM = false;
		viewC64MemoryDataDump->SetDataAdapter(debugInterfaceC64->dataAdapterC64);
		viewDrive1541MemoryMap->isDataDirectlyFromRAM = false;
		viewDrive1541MemoryDataDump->SetDataAdapter(debugInterfaceC64->dataAdapterDrive1541);
	}
}

bool CViewC64::CanSelectView(CGuiView *view)
{
	if (view->visible && view != viewC64MemoryMap && view != viewDrive1541MemoryMap)
		return true;
	
	return false;
}

// TODO: move this to CGuiView
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

//////
extern "C" {
	void machine_drive_flush(void);
}

bool CViewC64::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CViewC64::KeyDown, keyCode=%4.4x (%d) %c", keyCode, keyCode, keyCode);

#if defined(LOG_KEYBOARD_PRESS_KEY_NAME)
	CSlrString *keyCodeStr = SYS_KeyCodeToString(keyCode);
	char *str = keyCodeStr->GetStdASCII();
	LOGI("                   KeyDown=%s", str);
	delete [] str;
	delete keyCodeStr;
#endif
	
//#if defined(DEBUG_TEST_CODE)
//	if (keyCode == 'a' && isControl)
//	{
//		VID_TestMenu();
//	}
//#endif
	
#if defined(RUN_ATARI) && defined(RUN_COMMODORE64)
	// crude hack ctrl+a to switch emus. TODO: add this to key shortcuts
	if (keyCode == 'a' && isControl)
	{
		if (this->selectedDebugInterface == debugInterfaceC64)
		{
			this->selectedDebugInterface = debugInterfaceAtari;
		}
		else
		{
			this->selectedDebugInterface = debugInterfaceC64;
		}
		SetLayout(this->currentScreenLayoutId);
		return true;
	}
#endif
	
	
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
	if (this->currentScreenLayoutId == SCREEN_LAYOUT_C64_VIC_DISPLAY)
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
	if (debugInterfaceC64 && viewC64MemoryMap->visible)
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

	if (debugInterfaceAtari && viewAtariMemoryMap->visible)
	{
		if (keyCode == MTKEY_SPACEBAR && !isShift && !isAlt && !isControl)
		{
			if (viewAtariMemoryMap->IsInside(guiMain->mousePosX, guiMain->mousePosY))
			{
				this->SetFocus(viewAtariMemoryMap);
				if (viewAtariMemoryMap->KeyDown(keyCode, isShift, isAlt, isControl))
					return true;
			}
		}
	}

	if (debugInterfaceNes && viewNesMemoryMap->visible)
	{
		if (keyCode == MTKEY_SPACEBAR && !isShift && !isAlt && !isControl)
		{
			if (viewNesMemoryMap->IsInside(guiMain->mousePosX, guiMain->mousePosY))
			{
				this->SetFocus(viewNesMemoryMap);
				if (viewNesMemoryMap->KeyDown(keyCode, isShift, isAlt, isControl))
					return true;
			}
		}
	}

	///
	
	
	if (keyCode >= MTKEY_F1 && keyCode <= MTKEY_F8 && !isControl)
	{
		if (debugInterfaceC64 && viewC64ScreenWrapper->hasFocus)
		{
			return viewC64ScreenWrapper->KeyDown(keyCode, isShift, isAlt, isControl);
		}
		
		if (debugInterfaceAtari && viewAtariScreen->hasFocus)
		{
			return viewAtariScreen->KeyDown(keyCode, isShift, isAlt, isControl);
		}
		
		if (debugInterfaceNes && viewNesScreen->hasFocus)
		{
			return viewNesScreen->KeyDown(keyCode, isShift, isAlt, isControl);
		}
	}

	if (viewC64->ProcessGlobalKeyboardShortcut(keyCode, isShift, isAlt, isControl))
	{
		// when global key shortcut is detected
		// send key up for shift/alt/ctrl to the c64
		if (debugInterfaceC64)
		{
			viewC64Screen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}

		if (debugInterfaceAtari)
		{
			viewAtariScreen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}
		
		if (debugInterfaceNes)
		{
			viewNesScreen->KeyUpModifierKeys(isShift, isAlt, isControl);
		}
		
		keyDownCodes.push_back(keyCode);
		
		return true;
	}
	
	// TODO: this is a temporary UX workaround for step over jsr
	CSlrKeyboardShortcut *shortcut = this->keyboardShortcuts->FindShortcut(KBZONE_DISASSEMBLE, keyCode, isShift, isAlt, isControl);

	if (shortcut == keyboardShortcuts->kbsStepOverJsr)
	{
		if (this->debugInterfaceC64)
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
		
		if (this->debugInterfaceAtari)
		{
			viewAtariDisassemble->StepOverJsr();
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

	//
	// UX workarounds
	//

	// if in vic display layout key was not consumed key by focused view, pass it to vic display
	if (this->currentScreenLayoutId == SCREEN_LAYOUT_C64_VIC_DISPLAY)
	{
		if (viewC64VicDisplay->KeyDown(keyCode, isShift, isAlt, isControl))
			return true;
	}
	
	if (debugInterfaceC64 && viewC64ScreenWrapper->hasFocus)
	{
		return viewC64ScreenWrapper->KeyDown(keyCode, isShift, isAlt, isControl);
	}

	if (debugInterfaceAtari && viewAtariScreen->hasFocus)
	{
		return viewAtariScreen->KeyDown(keyCode, isShift, isAlt, isControl);
	}
	
	if (debugInterfaceNes && viewNesScreen->hasFocus)
	{
		return viewNesScreen->KeyDown(keyCode, isShift, isAlt, isControl);
	}
	
	return true; //CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CViewC64::KeyUp, keyCode=%d isShift=%d isAlt=%d isControl=%d", keyCode, isShift, isAlt, isControl);
	
#if defined(LOG_KEYBOARD_PRESS_KEY_NAME)
	CSlrString *keyCodeStr = SYS_KeyCodeToString(keyCode);
	char *str = keyCodeStr->GetStdASCII();
	LOGI("                   KeyUp=%s", str);
	delete [] str;
	delete keyCodeStr;
#endif
	
	if (keyCode >= MTKEY_F1 && keyCode <= MTKEY_F8 && !guiMain->isControlPressed)
	{
		if (debugInterfaceC64 && viewC64ScreenWrapper->hasFocus)
		{
			return viewC64ScreenWrapper->KeyUp(keyCode, isShift, isAlt, isControl);
		}
		
		if (debugInterfaceAtari && viewAtariScreen->hasFocus)
		{
			return viewAtariScreen->KeyUp(keyCode, isShift, isAlt, isControl);
		}

		if (debugInterfaceNes && viewNesScreen->hasFocus)
		{
			return viewNesScreen->KeyUp(keyCode, isShift, isAlt, isControl);
		}
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
	
	if (debugInterfaceC64 && viewC64ScreenWrapper->visible)
	{
		viewC64ScreenWrapper->KeyUp(keyCode, isShift, isAlt, isControl);
	}

	if (debugInterfaceAtari && viewAtariScreen->visible)
	{
		viewAtariScreen->KeyUp(keyCode, isShift, isAlt, isControl);
	}

	if (debugInterfaceNes && viewNesScreen->visible)
	{
		viewNesScreen->KeyUp(keyCode, isShift, isAlt, isControl);
	}

	return true; //CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}



//@returns is consumed
bool CViewC64::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64::DoTap:  x=%f y=%f", x, y);

	if (viewC64->debugInterfaceC64)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		// timeline for C64 only now
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			if (viewC64Timeline->IsInside(x, y))
			{
				return viewC64Timeline->DoTap(x, y);
			}
		}

		// TODO: this is a crude workaround to fix problem that c64 zoomed screen is the same instance of the c64 screen (which must be split soon btw)
		//       do not ever do this at home kids
		
		if (viewC64Screen->showZoomedScreen)
		{
			if (viewC64Screen->IsInsideViewNonVisible(x, y))
			{
				guiMain->SetFocus(viewC64ScreenWrapper);
				this->focusElement = viewC64ScreenWrapper;
				return viewC64ScreenWrapper->DoTap(x, y);
			}
			else
			{
				viewC64ScreenWrapper->hasFocus = false;
				if (guiMain->focusElement == viewC64ScreenWrapper)
				{
					guiMain->focusElement = NULL;
					this->focusElement = NULL;
				}
			}
		}
		else
		{
			if (viewC64ScreenWrapper->IsInsideView(x, y) == false && viewC64ScreenWrapper->hasFocus == true)
			{
				viewC64ScreenWrapper->hasFocus = false;
				if (guiMain->focusElement == viewC64ScreenWrapper
					|| this->focusElement == viewC64ScreenWrapper)
				{
					guiMain->focusElement = NULL;
					this->focusElement = NULL;
				}
			}
		}
		
		// TODO: end of crude workaround
		//
		
		viewC64->debugInterfaceC64->MouseDown(x, y);
	}

	if (viewC64->debugInterfaceAtari)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		// timeline for Atari only now, we need to generalize this
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			if (viewAtariTimeline->IsInside(x, y))
			{
				return viewAtariTimeline->DoTap(x, y);
			}
		}
		
		viewC64->debugInterfaceAtari->MouseDown(x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		LOGG("check inside=%s", guiElement->name);
		
		if (guiElement->visible == false)
			continue;
		
		if (guiElement->IsInside(x, y))
		{
			LOGG("... is inside=%s", guiElement->name);

			// let view decide what to do even if it does not have focus
			guiElement->DoTap(x, y);

			if (guiElement->IsFocusable() && ((focusElement != guiElement) || (guiElement->hasFocus == false)))
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
	LOGG("CViewC64::DoScrollWheel, mouseCursor=%f %f", mouseCursorX, mouseCursorY);

	// first scroll if mouse cursor is on element
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		
		LOGG("  guiElement->name=%s visible=%s", guiElement->name, STRBOOL(guiElement->name));
		
		if (!guiElement->visible)
			continue;

		LOGG("  guiElement->IsInside(%f %f)", mouseCursorX, mouseCursorY);
		if (guiElement->IsInside(mouseCursorX, mouseCursorY))
		{
			LOGG("  guiElement %s ->DoScrollWheel(%f %f)", guiElement->name, deltaX, deltaY);
			if (guiElement->DoScrollWheel(deltaX, deltaY))
			{
				return true;
			}
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
	
	if (viewC64->debugInterfaceC64)
	{
		viewC64->debugInterfaceC64->MouseUp(x, y);
		
		// TODO: workaround for quick timeline access (note this will be changed)
		// timeline for C64 only now
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewC64Timeline->DoFinishTap(x, y);
		}
	}

	if (viewC64->debugInterfaceAtari)
	{
		viewC64->debugInterfaceAtari->MouseUp(x, y);
		
		// TODO: workaround for quick timeline access (note this will be changed)
		// timeline for C64 only now
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewAtariTimeline->DoFinishTap(x, y);
		}
	}
	
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
	if (viewC64->debugInterfaceC64)
	{
		viewC64->debugInterfaceC64->MouseMove(x, y);
		
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			if (viewC64Timeline->IsInside(x, y))
			{
				return viewC64Timeline->DoMove(x, y, distX, distY, diffX, diffY);
			}
		}
	}

	if (viewC64->debugInterfaceAtari)
	{
		viewC64->debugInterfaceAtari->MouseMove(x, y);
		
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			if (viewAtariTimeline->IsInside(x, y))
			{
				return viewAtariTimeline->DoMove(x, y, distX, distY, diffX, diffY);
			}
		}
	}
	
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (viewC64->debugInterfaceC64)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewC64Timeline->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
		}
	}

	if (viewC64->debugInterfaceAtari)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewAtariTimeline->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
		}
	}

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
	if (viewC64->debugInterfaceC64)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewC64Timeline->FinishTouches();
		}
	}
	
	if (viewC64->debugInterfaceAtari)
	{
		// TODO: workaround for quick timeline access (note this will be changed)
		if (c64SettingsSnapshotsRecordIsActive && c64SettingsTimelineIsActive)
		{
			viewAtariTimeline->FinishTouches();
		}
	}

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
	LOGG("CViewC64::ApplicationEnteredBackground");
	
	// workaround for alt+tab
	if (this->debugInterfaceC64)
	{
		viewC64Screen->KeyUpModifierKeys(true, true, true);
	}
	
	if (this->debugInterfaceAtari)
	{
		viewAtariScreen->KeyUpModifierKeys(true, true, true);
	}

	if (this->debugInterfaceNes)
	{
		viewNesScreen->KeyUpModifierKeys(true, true, true);
	}
}

void CViewC64::ApplicationEnteredForeground()
{
	LOGG("CViewC64::ApplicationEnteredForeground");

	// workaround for alt+tab
	if (this->debugInterfaceC64)
	{
		viewC64Screen->KeyUpModifierKeys(true, true, true);
	}
	
	if (this->debugInterfaceAtari)
	{
		viewAtariScreen->KeyUpModifierKeys(true, true, true);
	}

	if (this->debugInterfaceNes)
	{
		viewNesScreen->KeyUpModifierKeys(true, true, true);
	}
}

#if defined(RUN_ATARI)
extern "C" {
	void MEMORY_GetCharsetScreenCodes(u8 *cs);
}
#endif

void CViewC64::CreateFonts()
{
//	u64 t1 = SYS_GetCurrentTimeInMillis();

	uint8 *charRom = debugInterfaceVice->GetCharRom();
	
	uint8 *charData;
	
	charData = charRom;
	fontCBM1 = ProcessFonts(charData, true);

	charData = charRom + 0x0800;
	fontCBM2 = ProcessFonts(charData, true);

	fontCBMShifted = ProcessFonts(charData, false);
	
	fontAtari = NULL;
	
#if defined(RUN_ATARI)
	u8 charRomAtari[0x0800];
	MEMORY_GetCharsetScreenCodes(charRomAtari);
	fontAtari = ProcessFonts(charRomAtari, true);
#endif
	
//	u64 t2 = SYS_GetCurrentTimeInMillis();
//	LOGD("time=%u", t2-t1);
	
}

// TODO: this is called by emulator code when frame is started (i.e. after VSync)
//       note that this assumes we have *ONE* emulator working (the C64 Vice is supported by now)
//       this *MUST* be refactored as different emulation engines will have different frame rates/syncs
void CViewC64::EmulationStartFrameCallback()
{
	if (viewJukeboxPlaylist != NULL)
	{
		viewJukeboxPlaylist->EmulationStartFrame();
	}
	
	// TODO: we have a plugin->DoFrame() on frame canvas refresh, shall we have a VSync too?
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

void CViewC64::ToggleSoundMute()
{
	this->SetSoundMute(!this->isSoundMuted);
}

void CViewC64::SetSoundMute(bool isMuted)
{
	this->isSoundMuted = isMuted;
	UpdateSIDMute();
}

void CViewC64::UpdateSIDMute()
{
	LOGD("CViewC64::UpdateSIDMute: isSoundMuted=%s", STRBOOL(isSoundMuted));
	
	// logic to control "only mute volume" or "skip SID emulation"
	if (this->isSoundMuted == false)
	{
		// start sound
		debugInterfaceC64->SetAudioVolume((float)(c64SettingsAudioVolume) / 100.0f);
		debugInterfaceC64->SetRunSIDEmulation(c64SettingsRunSIDEmulation);
	}
	else
	{
		// stop sound
		debugInterfaceC64->SetAudioVolume(0.0f);
		if (c64SettingsMuteSIDMode == MUTE_SID_MODE_SKIP_EMULATION)
		{
			debugInterfaceC64->SetRunSIDEmulation(false);
		}
	}
}

void CViewC64::CheckMouseCursorVisibility()
{
	if (guiMain->currentView == this
		&&
		(	this->currentScreenLayoutId == SCREEN_LAYOUT_C64_ONLY
			|| this->currentScreenLayoutId == SCREEN_LAYOUT_ATARI_ONLY
			|| this->currentScreenLayoutId == SCREEN_LAYOUT_NES_ONLY
		 )
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

void CViewC64::UpdateWatchVisible()
{
	guiMain->LockMutex();

	// TODO: make generic
	
	if (viewC64->debugInterfaceC64)
	{
		if (screenPositions[currentScreenLayoutId]->c64DataDumpVisible)
		{
			if (this->isVisibleWatch)
			{
				viewC64MemoryDataWatch->SetPosition(viewC64MemoryDataDump->posX, viewC64MemoryDataDump->posY, viewC64MemoryDataDump->posZ,
													viewC64MemoryDataDump->sizeX, viewC64MemoryDataDump->sizeY);
				
				viewC64MemoryDataWatch->SetVisible(true);
				viewC64MemoryDataDump->SetVisible(false);
			}
			else
			{
				viewC64MemoryDataWatch->SetVisible(false);
				viewC64MemoryDataDump->SetVisible(true);
			}
		}
		else
		{
			viewC64MemoryDataWatch->SetVisible(false);
			viewC64MemoryDataDump->SetVisible(false);
		}
		
		//
		if (screenPositions[currentScreenLayoutId]->drive1541DataDumpVisible)
		{
			if (this->isVisibleWatch)
			{
				viewDrive1541MemoryDataWatch->SetPosition(viewDrive1541MemoryDataDump->posX, viewDrive1541MemoryDataDump->posY, viewDrive1541MemoryDataDump->posZ,
														  viewDrive1541MemoryDataDump->sizeX, viewDrive1541MemoryDataDump->sizeY);
				
				viewDrive1541MemoryDataWatch->SetVisible(true);
				viewDrive1541MemoryDataDump->SetVisible(false);
			}
			else
			{
				viewDrive1541MemoryDataWatch->SetVisible(false);
				viewDrive1541MemoryDataDump->SetVisible(true);
			}
		}
		else
		{
			viewDrive1541MemoryDataWatch->SetVisible(false);
			viewDrive1541MemoryDataDump->SetVisible(false);
		}
	}

	if (viewC64->debugInterfaceAtari)
	{
		if (screenPositions[currentScreenLayoutId]->atariDataDumpVisible)
		{
			if (this->isVisibleWatch)
			{
				viewAtariMemoryDataWatch->SetPosition(viewAtariMemoryDataDump->posX, viewAtariMemoryDataDump->posY, viewAtariMemoryDataDump->posZ,
													viewAtariMemoryDataDump->sizeX, viewAtariMemoryDataDump->sizeY);
				
				viewAtariMemoryDataWatch->SetVisible(true);
				viewAtariMemoryDataDump->SetVisible(false);
			}
			else
			{
				viewAtariMemoryDataWatch->SetVisible(false);
				viewAtariMemoryDataDump->SetVisible(true);
			}
		}
		else
		{
			viewAtariMemoryDataWatch->SetVisible(false);
			viewAtariMemoryDataDump->SetVisible(false);
		}
	}

	
	guiMain->UnlockMutex();
}

void CViewC64::SetWatchVisible(bool isVisibleWatch)
{
	this->isVisibleWatch = isVisibleWatch;
	UpdateWatchVisible();
}

CDebugInterface *CViewC64::GetDebugInterface(u8 emulatorType)
{
	switch(emulatorType)
	{
		case EMULATOR_TYPE_C64_VICE:
			return (CDebugInterface*)viewC64->debugInterfaceC64;
			
		case EMULATOR_TYPE_ATARI800:
			return (CDebugInterface*)viewC64->debugInterfaceAtari;
			
		case EMULATOR_TYPE_NESTOPIA:
			return (CDebugInterface*)viewC64->debugInterfaceNes;
			
		default:
			return NULL;
	}
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

char *CViewC64::ATRD_GetPathForRoms_IMPL()
{
	LOGD("CViewC64::ATRD_GetPathForRoms_IMPL");
	char *buf;
	if (c64SettingsPathToAtariROMs == NULL)
	{
		buf = new char[MAX_BUFFER];
		sprintf(buf, ".");
	}
	else
	{
		buf = c64SettingsPathToAtariROMs->GetStdASCII();
	}
	
//	sprintf(buf, "%s/debugroms", gPathToDocuments);
	LOGD("ATRD_GetPathForRoms_IMPL path=%s", buf);
	
	LOGM("buf is=%s", buf);
	return buf;
}

void CViewC64::ApplicationShutdown()
{
	LOGD("CViewC64::ApplicationShutdown");
	
	guiMain->RemoveAllViews();
	
	if (viewC64->debugInterfaceC64)
	{
		viewC64->debugInterfaceC64->Shutdown();
	}
	if (viewC64->debugInterfaceAtari)
	{
		viewC64->debugInterfaceAtari->Shutdown();
	}
	if (viewC64->debugInterfaceNes)
	{
		viewC64->debugInterfaceNes->Shutdown();
	}
	SYS_Sleep(100);
}



CScreenLayout::CScreenLayout()
{
	debugOnC64 = true;
	debugOnDrive1541 = false;

	c64ScreenVisible = false;
	c64CpuStateVisible = false;
	drive1541CpuStateVisible = false;
	c64DisassembleVisible = false;
	drive1541DisassembleVisible = false;
	c64SourceCodeVisible = false;
	c64MemoryMapVisible = false;
	drive1541MemoryMapVisible = false;
	c64DataDumpVisible = false;
	drive1541DataDumpVisible = false;
	c64StateCIAVisible = false;
	c64StateSIDVisible = false;
	c64StateVICVisible = false;
	c64StateREUVisible = false;
	c64EmulationCountersVisible = false;
	drive1541StateVIAVisible = false;
	c64MonitorConsoleVisible = false;
	emulationStateVisible = false;
	
	debugOnAtari = true;
	atariScreenVisible = false;
	atariDisassembleVisible = false;
	atariSourceCodeVisible = false;
	atariDataDumpVisible = false;
	atariMemoryMapVisible = false;
	atariMonitorConsoleVisible = false;
	atariEmulationCountersVisible = false;
	
	c64ScreenX = c64ScreenY = c64ScreenSizeX = c64ScreenSizeY = c64CpuStateX = c64CpuStateY = drive1541CpuStateX = drive1541CpuStateY = c64DisassembleX = c64DisassembleY = drive1541DisassembleX = drive1541DisassembleY = c64SourceCodeX = c64SourceCodeY = c64MemoryMapX = c64MemoryMapY = c64MemoryMapSizeX = c64MemoryMapSizeY = drive1541MemoryMapX = drive1541MemoryMapY = drive1541MemoryMapSizeX = drive1541MemoryMapSizeY = c64DataDumpX = c64DataDumpY = c64DataDumpSizeX = c64DataDumpSizeY = c64StateCIAX = c64StateCIAY = c64StateSIDX = c64StateSIDY = c64StateVICX = c64StateVICY = c64StateVICSizeX = c64StateVICSizeY = c64StateREUX = c64StateREUY = c64EmulationCountersX = c64EmulationCountersY =  drive1541StateVIAX = drive1541StateVIAY = c64VicDisplayX = c64VicDisplayY = c64MonitorConsoleX = c64MonitorConsoleY = atariMonitorConsoleX = atariMonitorConsoleY = emulationStateX = emulationStateY = atariScreenX = atariScreenY = atariDisassembleSizeX = atariDisassembleSizeY = atariEmulationCountersX = atariEmulationCountersY = nesScreenX = nesScreenY
	= 0;

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
	c64DataDumpShowDataCharacters = true;
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
	c64DisassembleNumberOfLines = 30;
	c64DisassembleShowHexCodes = false;
	c64DisassembleShowCodeCycles = false;
	c64DisassembleCodeCyclesOffset = -1.5f;
	c64DisassembleShowLabels = false;
	c64DisassembleShowSourceCode = false;
	
	drive1541DisassembleCodeMnemonicsOffset = 0.0f;
	drive1541DisassembleNumberOfLines = 30;
	drive1541DisassembleShowHexCodes = false;
	drive1541DisassembleShowCodeCycles = false;
	drive1541DisassembleCodeCyclesOffset = -1.5f;
	drive1541DisassembleShowLabels = false;
	drive1541DisassembleShowSourceCode = false;
	
	c64StateCIAFontSize = c64StateSIDFontSize = c64StateVICFontSize = c64StateREUFontSize = c64EmulationCountersFontSize = drive1541StateVIAFontSize = 5.0f;
	
	c64StateCIARenderCIA1 = true;
	c64StateCIARenderCIA2 = true;
	
	c64StateVICIsVertical = false;
	c64StateVICShowSprites = true;
	c64StateVICNumValuesPerColumn = 0x0C;

	drive1541StateVIARenderVIA1 = true;
	drive1541StateVIARenderVIA2 = true;
	drive1541StateVIARenderDriveLED = true;
	drive1541StateVIAIsVertical = false;
	
	c64VicDisplayVisible = false;
	c64VicDisplayScale = 1.0f;
	c64VicDisplayCanScrollDisassemble = true;
	
	c64VicControlVisible = false;
	c64VicControlFontSize = 8.0f;

	c64AllGraphicsVisible = false;
	c64AllGraphicsX = 0.0f;
	c64AllGraphicsY = 0.0f;
	
	c64MonitorConsoleFontScale = 1.5f;
	c64MonitorConsoleNumLines = 20;
	
	//
	debugOnAtari = false;
	
	atariScreenShowGridLines = false;
	atariScreenShowZoomedScreen = false;
	atariScreenZoomedX = atariScreenZoomedY = atariScreenZoomedSizeX = atariScreenZoomedSizeY = 0;
	
	atariDisassembleCodeMnemonicsOffset = 0.0f;
	atariDisassembleNumberOfLines = 30;
	atariDisassembleShowHexCodes = false;
	atariDisassembleShowCodeCycles = false;
	atariDisassembleCodeCyclesOffset = -1.5f;
	atariDisassembleShowLabels = false;
	atariDisassembleNumberOfLabelCharacters = 20;

	atariMonitorConsoleFontScale = 1.5f;
	atariMonitorConsoleNumLines = 20;

	atariStateANTICVisible = false;
	atariStateGTIAVisible = false;
	atariStatePIAVisible = false;
	atariStatePOKEYVisible = false;

	//
	debugOnNes = false;
	
	nesScreenShowGridLines = false;
	nesScreenShowZoomedScreen = false;
	nesScreenZoomedX = nesScreenZoomedY = nesScreenZoomedSizeX = nesScreenZoomedSizeY = 0;
	nesDisassembleCodeMnemonicsOffset = 0.0f;
	nesDisassembleNumberOfLines = 30;
	nesDisassembleShowHexCodes = false;
	nesDisassembleShowCodeCycles = false;
	nesDisassembleCodeCyclesOffset = -1.5f;
	nesDisassembleShowLabels = false;

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
	
	// c64
	if (ext->CompareWith("prg") || ext->CompareWith("PRG"))
	{
		C64D_DragDropCallbackPRG(filePath);
	}
	else if (ext->CompareWith("d64") || ext->CompareWith("D64")
			 || ext->CompareWith("g64") || ext->CompareWith("G64"))
	{
		C64D_DragDropCallbackD64(filePath);
	}
	else if (ext->CompareWith("crt") || ext->CompareWith("CRT"))
	{
		C64D_DragDropCallbackCRT(filePath);
	}
	else if (ext->CompareWith("sid") || ext->CompareWith("SID"))
	{
		C64D_DragDropCallbackSID(filePath);
	}
	else if (ext->CompareWith("tap") || ext->CompareWith("TAP")
			 || ext->CompareWith("t64") || ext->CompareWith("T64"))
	{
		C64D_DragDropCallbackTAP(filePath);
	}
	else if (ext->CompareWith("snap") || ext->CompareWith("SNAP")
			 || ext->CompareWith("vsf") || ext->CompareWith("VSF"))
	{
		C64D_DragDropCallbackSNAP(filePath);
	}
	else if (ext->CompareWith("vce") || ext->CompareWith("VCE"))
	{
		C64D_DragDropCallbackVCE(filePath);
	}
	else if (ext->CompareWith("png") || ext->CompareWith("PNG"))
	{
		C64D_DragDropCallbackPNG(filePath);
	}
	// atari
	else if (ext->CompareWith("xex") || ext->CompareWith("XEX"))
	{
		C64D_DragDropCallbackXEX(filePath);
	}
	else if (ext->CompareWith("atr") || ext->CompareWith("ATR"))
	{
		C64D_DragDropCallbackATR(filePath);
	}
	else if (ext->CompareWith("cas") || ext->CompareWith("CAS"))
	{
		C64D_DragDropCallbackCAS(filePath);
	}
	else if (ext->CompareWith("car") || ext->CompareWith("CAR")
			 || ext->CompareWith("rom") || ext->CompareWith("ROM"))
	{
		C64D_DragDropCallbackCAR(filePath);
	}
	else if (ext->CompareWith("a8s") || ext->CompareWith("A8S"))
	{
		C64D_DragDropCallbackA8S(filePath);
	}
	// nes
	else if (ext->CompareWith("nes") || ext->CompareWith("NES"))
	{
		C64D_DragDropCallbackNES(filePath);
	}
	// jukebox
	else if (ext->CompareWith("c64jukebox") || ext->CompareWith("C64JUKEBOX")
			 || ext->CompareWith("json") || ext->CompareWith("JSON"))
	{
		C64D_DragDropCallbackJukeBox(filePath);
	}

	delete ext;
}

// NOTE: new extensions for drag & drop have to be added also to:
//		  - (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
// and:   BOOL MACOS_OpenFile(NSString *strPath)


void C64D_DragDropCallbackPRG(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackPRG");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadPRG(filePath, true, false, true, false);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackD64(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackD64");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->InsertD64(filePath, false, c64SettingsAutoJmpFromInsertedDiskFirstPrg, 0, true);
	
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

void C64D_DragDropCallbackTAP(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackTAP");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadTape(filePath, false, false, true);
	
	CSlrString *fileName = filePath->GetFileNameComponentFromPath();
	char *fn = fileName->GetStdASCII();
	
	char *buf = SYS_GetCharBuf();
	sprintf(buf, "Attached %s", fn);
	
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

void C64D_DragDropCallbackSID(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackSID");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadSID(filePath);
	
	C64DebuggerStoreSettings();
}


void C64D_DragDropCallbackSNAP(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackSNAP");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64Snapshots->LoadSnapshot(filePath, false);
}

void C64D_DragDropCallbackVCE(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackVCE");
	filePath->DebugPrint("filePath=");

	viewC64->viewVicEditor->ImportVCE(filePath);
	viewC64->viewVicEditor->SwitchToVicEditor();
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackPNG(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackPNG");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewVicEditor->ImportPNG(filePath);
	viewC64->viewVicEditor->SwitchToVicEditor();
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackXEX(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackXEX");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadXEX(filePath, true, false, true);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackATR(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackATR");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->InsertATR(filePath, false, c64SettingsAutoJmpFromInsertedDiskFirstPrg, 0, true);
	
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

void C64D_DragDropCallbackCAS(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackCAS");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadCAS(filePath, true, false, true);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackCAR(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackCAR");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->InsertAtariCartridge(filePath, true, false, true);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackA8S(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackA8S");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewAtariSnapshots->LoadSnapshot(filePath, false);
	
	C64DebuggerStoreSettings();
}

void C64D_DragDropCallbackNES(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackNES");
	filePath->DebugPrint("filePath=");
	
	viewC64->viewC64MainMenu->LoadNES(filePath, false);
	
	C64DebuggerStoreSettings();
}

//
void CViewC64::CreateEmulatorPlugins()
{
#if defined(RUN_COMMODORE64)
	C64D_InitPlugins();
#endif
}


void C64D_DragDropCallbackJukeBox(CSlrString *filePath)
{
	LOGD("C64D_DragDropCallbackJukeBox");
	filePath->DebugPrint("filePath=");
	
	viewC64->InitJukebox(filePath);
}



void CViewC64::AddC64DebugCode()
{
	C64DebugInterface *debugInterface = this->debugInterfaceC64;

	//debugInterface->Reset();
	
	debugInterface->LockMutex();
	int rasterNum = 0x45;
	CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(rasterNum);
	debugInterface->breakpointsRaster[rasterNum] = addrBreakpoint;
	debugInterface->breakOnRaster = true;
	debugInterface->UnlockMutex();
	
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

