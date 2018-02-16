#include "C64CommandLine.h"
#include "CViewC64.h"
#include "SYS_CommandLine.h"
#include "C64Symbols.h"
#include "CViewMainMenu.h"
#include "CViewSnapshots.h"
#include "CSlrString.h"
#include "RES_ResourceManager.h"
#include "C64DebugInterface.h"
#include "C64SettingsStorage.h"
#include "C64SharedMemory.h"
#include "CViewVicEditor.h"
#include "CGuiMain.h"
#include "SND_SoundEngine.h"
#include "CViewJukeboxPlaylist.h"
#include "C64D_Version.h"

#define printLine printf
#define C64D_PASS_CONFIG_DATA_MARKER	0x029A
#define C64D_PASS_CONFIG_DATA_VERSION	0x0002

bool isPRGInCommandLine = false;
bool isD64InCommandLine = false;
bool isSNAPInCommandLine = false;
bool isCRTInCommandLine = false;

void C64DebuggerPassConfigToRunningInstance();

void c64ShowCommandLineHelp()
{
	printLine("C64 Debugger v%s by Slajerek/Samar, VICE %s by The VICE Team\n", C64DEBUGGER_VERSION_STRING, C64DEBUGGER_VICE_VERSION_STRING);
	printLine("\n");
	printLine("-help  show this help\n");
	printLine("\n");
	printLine("-layout <id>\n");
	printLine("     start with layout id <1-%d>\n", C64_SCREEN_LAYOUT_MAX);
	printLine("-breakpoints <file>\n");
	printLine("     load breakpoints from file\n");
	printLine("-symbols <file>\n");
	printLine("     load symbols (code labels)");
	printLine("-watch <file>\n");
	printLine("     load watches");
	printLine("\n");
	printLine("-wait <ms>\n");
	printLine("     wait before performing tasks\n");
	printLine("-prg <file>\n");
	printLine("     load PRG file into memory\n");
	printLine("-d64 <file>\n");
	printLine("     insert D64 disk\n");
	printLine("-crt <file>\n");
	printLine("     attach cartridge\n");
	printLine("-jmp <addr>\n");
	printLine("     jmp to address, for example jmp x1000, jmp $1000 or jmp 4096\n");
	printLine("-autojmp\n");
	printLine("     automatically jmp to address if basic SYS is detected\n");
	printLine("-alwaysjmp\n");
	printLine("     always jmp to load address of PRG\n");
	printLine("-autorundisk\n");
	printLine("     automatically load first PRG from inserted disk\n");
	printLine("-unpause\n");
	printLine("     force code running\n");
	printLine("-snapshot <file>\n");
	printLine("     load snapshot from file\n");
	printLine("-soundout <\"device name\" | device number>\n");
	printLine("     set sound out device by name or number\n");
	printLine("-playlist <file>\n");
	printLine("     load and start jukebox playlist from json file\n");
	printLine("\n");
	printLine("-clearsettings\n");
	printLine("     clear all config settings\n");
	printLine("-pass\n");
	printLine("     pass parameters to already running instance\n");
	printLine("\n");
	
	SYS_CleanExit();
}

std::vector<char *>::iterator c64cmdIt;

char *c64ParseCommandLineGetArgument()
{
	if (c64cmdIt == sysCommandLineArguments.end())
	{
		c64ShowCommandLineHelp();
	}
	
	char *arg = *c64cmdIt;
	c64cmdIt++;
	
	LOGD("c64ParseCommandLineGetArgument: arg='%s'", arg);
	
	return arg;
}

void C64DebuggerParseCommandLine0()
{
	LOGD("C64DebuggerParseCommandLine0");

	if (sysCommandLineArguments.empty())
		return;
	
	// check if it's just a single argument with file path (drop file on exe in Win32)
	if (sysCommandLineArguments.size() == 1)	// 1   , 3 for dev xcode
	{
		char *arg = sysCommandLineArguments[0];

		LOGD("arg=%s", arg);

		if (SYS_FileExists(arg))
		{
			CSlrString *filePath = new CSlrString(arg);
			filePath->DebugPrint("filePath=");

			CSlrString *ext = filePath->GetFileExtensionComponentFromPath();			
			ext->DebugPrint("ext=");

			if (ext->CompareWith("prg") || ext->CompareWith("PRG"))
			{
				isPRGInCommandLine = true;
				
				char *path = sysCommandLineArguments[0];
				sysCommandLineArguments.clear();
				sysCommandLineArguments.push_back("-pass");
				sysCommandLineArguments.push_back("-wait");
				sysCommandLineArguments.push_back("700");
				sysCommandLineArguments.push_back("-prg");
				sysCommandLineArguments.push_back(path);
				sysCommandLineArguments.push_back("-autojmp");

				// TODO: this will be overwritten by settings loader
				c64SettingsFastBootKernalPatch = true;

				LOGD("delete filePath");
				delete filePath;
				
//				c64SettingsPathToPRG = filePath;
				c64SettingsWaitOnStartup = 500;
//				c64SettingsAutoJmp = true;
				LOGD("delete ext");
				delete ext;

				// pass to running instance if exists
				C64DebuggerInitSharedMemory();
				C64DebuggerPassConfigToRunningInstance();

				return;
			}
			else if (ext->CompareWith("d64") || ext->CompareWith("D64"))
			{
				isD64InCommandLine = true;
				
				char *path = sysCommandLineArguments[0];

				sysCommandLineArguments.clear();
				sysCommandLineArguments.push_back("-pass");
				sysCommandLineArguments.push_back("-d64");
				sysCommandLineArguments.push_back(path);
				delete filePath;

//				c64SettingsPathToD64 = filePath;
//				c64SettingsWaitOnStartup = 500;
				delete ext;
				
				// pass to running instance if exists
				C64DebuggerInitSharedMemory();
				C64DebuggerPassConfigToRunningInstance();

				return;
			}
			else if (ext->CompareWith("crt") || ext->CompareWith("CRT"))
			{
				isCRTInCommandLine = true;
				
				char *path = sysCommandLineArguments[0];

				sysCommandLineArguments.clear();
				sysCommandLineArguments.push_back("-pass");
				sysCommandLineArguments.push_back("-crt");
				sysCommandLineArguments.push_back(path);
				delete filePath;

//				c64SettingsPathToCartridge = filePath;
//				c64SettingsWaitOnStartup = 500;
				delete ext;

				// pass to running instance if exists
				C64DebuggerInitSharedMemory();
				C64DebuggerPassConfigToRunningInstance();
				
				return;
			}
			else if (ext->CompareWith("snap") || ext->CompareWith("SNAP")
					 || ext->CompareWith("vsf") || ext->CompareWith("VSF"))
			{
				isSNAPInCommandLine = true;
				
				char *path = sysCommandLineArguments[0];

				sysCommandLineArguments.clear();
				sysCommandLineArguments.push_back("-pass");
				sysCommandLineArguments.push_back("-snapshot");
				sysCommandLineArguments.push_back(path);
				delete filePath;

//				c64SettingsPathToSnapshot = filePath;
//				c64SettingsWaitOnStartup = 500;
				delete ext;
				
				// pass to running instance if exists
				C64DebuggerInitSharedMemory();
				C64DebuggerPassConfigToRunningInstance();
				
				return;
			}
			delete filePath;
			delete ext;
			
		}
	}

	
	c64cmdIt = sysCommandLineArguments.begin();
	
	while(c64cmdIt != sysCommandLineArguments.end())
	{
		char *cmd = c64ParseCommandLineGetArgument();
		
		if (!strcmp(cmd, "help") || !strcmp(cmd, "h")
			|| !strcmp(cmd, "-help") || !strcmp(cmd, "-h")
			|| !strcmp(cmd, "--help") || !strcmp(cmd, "--h"))
		{
			c64ShowCommandLineHelp();
		}
		
		if (!strcmp(cmd, "-pass") || !strcmp(cmd, "pass"))
		{
			C64DebuggerInitSharedMemory();
			C64DebuggerPassConfigToRunningInstance();
		}
	}
}

void C64DebuggerParseCommandLine1()
{
	if (sysCommandLineArguments.empty())
		return;

	c64cmdIt = sysCommandLineArguments.begin();
	
	while(c64cmdIt != sysCommandLineArguments.end())
	{
		char *cmd = c64ParseCommandLineGetArgument();

		if (!strcmp(cmd, "help") || !strcmp(cmd, "h")
			|| !strcmp(cmd, "-help") || !strcmp(cmd, "-h")
			|| !strcmp(cmd, "--help") || !strcmp(cmd, "--h"))
		{
			c64ShowCommandLineHelp();
		}
		
		if (!strcmp(cmd, "-clearsettings") || !strcmp(cmd, "clearsettings"))
		{
			c64SettingsSkipConfig = true;
			printLine("Skipping loading config\n");
			LOGD("Skipping auto loading settings config");
		}		
	}
}

///////////
CSlrString *c64CommandLineAudioOutDevice = NULL;

void c64PerformStartupTasksThreaded()
{
	LOGM("START c64PerformStartupTasksThreaded");
	
	if (c64CommandLineAudioOutDevice != NULL)
	{
		if (gSoundEngine->SetOutputAudioDevice(c64CommandLineAudioOutDevice) == false)
		{
			printLine("Selected sound out device not found, fall back to default output.\n");
		}
	}
	
	// load breakpoints & symbols
	if (c64SettingsPathToBreakpoints != NULL)
	{
		viewC64->symbols->ClearBreakpoints(viewC64->debugInterface);
		viewC64->symbols->ParseBreakpoints(c64SettingsPathToBreakpoints, viewC64->debugInterface);
	}
	
	if (c64SettingsPathToSymbols != NULL)
	{
		viewC64->symbols->ClearSymbols(viewC64->debugInterface);
		viewC64->symbols->ParseSymbols(c64SettingsPathToSymbols, viewC64->debugInterface);
	}
	
	if (c64SettingsPathToWatches != NULL)
	{
		viewC64->symbols->ClearWatches(viewC64->debugInterface);
		viewC64->symbols->ParseWatches(c64SettingsPathToWatches, viewC64->debugInterface);
	}
	
	if (c64SettingsPathToDebugInfo != NULL)
	{
		viewC64->symbols->ClearSourceDebugInfo(viewC64->debugInterface);
		viewC64->symbols->ParseSourceDebugInfo(c64SettingsPathToDebugInfo, viewC64->debugInterface);
	}
	
	// skip any automatic loading if jukebox is active
	if (viewC64->viewJukeboxPlaylist != NULL)
	{
		if (c64SettingsSIDEngineModel != 0)
		{
			viewC64->debugInterface->SetSidType(c64SettingsSIDEngineModel);
		}
		
		viewC64->viewJukeboxPlaylist->StartPlaylist();
		return;
	}
	
	// process, order is important
	// we need to create new strings for path as they will be deleted and updated by loaders
	if (c64SettingsPathToSnapshot != NULL)
	{
		viewC64->viewC64Snapshots->LoadSnapshot(c64SettingsPathToSnapshot, false);
		
		SYS_Sleep(150);
	}
	else
	{
		// DONE?: Is it possible to init VICE with proper Engines at startup to not re-create here?
		// DONE?: Vice 3.1 by default starts with strange model (unknown=99), check cmdline parsing how it's handled in VICE
		if (c64SettingsC64Model != 0)
		{
//			SYS_Sleep(300);
//			viewC64->debugInterface->SetC64ModelType(c64SettingsC64Model);
		}
		
		// setup SID
		if (c64SettingsSIDEngineModel != 0)
		{
			viewC64->debugInterface->SetSidType(c64SettingsSIDEngineModel);
		}
		
		//
		if (c64SettingsPathToD64 != NULL)
		{
			LOGD("isPRGInCommandLine=%s", STRBOOL(isPRGInCommandLine));
			if (isPRGInCommandLine == false && isD64InCommandLine == true)
			{
				// start disk based on settings
				if (c64SettingsAutoJmpFromInsertedDiskFirstPrg)
				{
					SYS_Sleep(100);
				}
				viewC64->viewC64MainMenu->InsertD64(c64SettingsPathToD64, false, c64SettingsAutoJmpFromInsertedDiskFirstPrg, 0, true);
			}
			else
			{
				// just load disk, do not start, we will start PRG instead
				viewC64->viewC64MainMenu->InsertD64(c64SettingsPathToD64, false, false, 0, false);
			}
			
		}
		
		if (c64SettingsPathToCartridge != NULL)
		{
			viewC64->viewC64MainMenu->InsertCartridge(c64SettingsPathToCartridge, false);
			SYS_Sleep(666);
		}
	}
	
	///////////
	
	if (c64SettingsPathToPRG != NULL)
	{
		LOGD("c64PerformStartupTasksThreaded: loading PRG, isPRGInCommandLine=%s isD64InCommandLine=%s", STRBOOL(isPRGInCommandLine), STRBOOL(isD64InCommandLine));
		c64SettingsPathToPRG->DebugPrint("c64SettingsPathToPRG=");
		
		if ((isPRGInCommandLine == false) && (isD64InCommandLine == true) && c64SettingsAutoJmpFromInsertedDiskFirstPrg)
		{
			// do not load prg when disk inserted from command line and autostart
		}
		else //if (isPRGInCommandLine == true)
		{
			viewC64->viewC64MainMenu->LoadPRG(c64SettingsPathToPRG, c64SettingsAutoJmp, false, true);
		}
	}
	
	if (c64SettingsJmpOnStartupAddr > 0 && c64SettingsJmpOnStartupAddr < 0x10000)
	{
		//SYS_Sleep(150);
		
		LOGD("c64PerformStartupTasksThreaded: c64SettingsJmpOnStartupAddr=%04x", c64SettingsJmpOnStartupAddr);

		viewC64->debugInterface->MakeJsrC64(c64SettingsJmpOnStartupAddr);
	}

	//
	viewC64->viewVicEditor->RunDebug();
}

class C64PerformStartupTasksThread : public CSlrThread
{
	virtual void ThreadRun(void *data)
	{
		LOGM("C64PerformStartupTasksThread: ThreadRun");
		if (c64SettingsPathToSnapshot != NULL && c64SettingsWaitOnStartup < 150)
			c64SettingsWaitOnStartup = 150;
		
		if (c64dStartupTime == 0 || (SYS_GetCurrentTimeInMillis() - c64dStartupTime < 500))
		{
			LOGD("C64PerformStartupTasksThread: early run, wait 500ms");
			c64SettingsWaitOnStartup += 500;
		}
		
		LOGD("C64PerformStartupTasksThread: c64SettingsWaitOnStartup=%d", c64SettingsWaitOnStartup);
		SYS_Sleep(c64SettingsWaitOnStartup);
		
		c64PerformStartupTasksThreaded();
	};
};

////////////////////////

void C64DebuggerParseCommandLine2()
{
	if (sysCommandLineArguments.empty())
		return;
	
	c64cmdIt = sysCommandLineArguments.begin();
	
	LOGD("C64DebuggerParseCommandLine2: iterate");
	while(c64cmdIt != sysCommandLineArguments.end())
	{
		char *cmd = c64ParseCommandLineGetArgument();

		//LOGD("...cmd='%s'", cmd);

		if (cmd[0] == '-')
			cmd++;
		
		if (!strcmp(cmd, "breakpoints") || !strcmp(cmd, "b"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToBreakpoints = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "symbols") || !strcmp(cmd, "vicesymbols") || !strcmp(cmd, "vs"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToSymbols = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "watch") || !strcmp(cmd, "w"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToWatches = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "debuginfo"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToDebugInfo = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "autojmp") || !strcmp(cmd, "autojump"))
		{
			c64SettingsAutoJmp = true;
		}
		else if (!strcmp(cmd, "unpause"))
		{
			c64SettingsForceUnpause = true;
		}
		else if (!strcmp(cmd, "autorundisk"))
		{
			c64SettingsAutoJmpFromInsertedDiskFirstPrg = true;
		}
		else if (!strcmp(cmd, "alwaysjmp") || !strcmp(cmd, "alwaysjump"))
		{
			c64SettingsAutoJmpAlwaysToLoadedPRGAddress = true;
		}
		else if (!strcmp(cmd, "d64"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToD64 = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "prg"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			LOGD("C64DebuggerParseCommandLine2: set c64SettingsPathToPRG=%s", arg);
			c64SettingsPathToPRG = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "cartridge"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToCartridge = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "snapshot"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathToSnapshot = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "jmp"))
		{
			int addr;
			char *str = c64ParseCommandLineGetArgument();
			
			if (str[0] == '$' || str[0] == 'x')
			{
				// hex
				str++;
				sscanf(str, "%x", &addr);
			}
			else
			{
				sscanf(str, "%d", &addr);
			}
			
			c64SettingsJmpOnStartupAddr = addr;
		}
		else if (!strcmp(cmd, "layout"))
		{
			int layoutId;
			char *str = c64ParseCommandLineGetArgument();
			layoutId = atoi(str)-1;
			c64SettingsDefaultScreenLayoutId = layoutId;
			
			LOGD("c64SettingsDefaultScreenLayoutId=%d", layoutId);
		}
		else if (!strcmp(cmd, "wait"))
		{
			char *str = c64ParseCommandLineGetArgument();
			c64SettingsWaitOnStartup = atoi(str);
		}
		else if (!strcmp(cmd, "soundout"))
		{
			char *str = c64ParseCommandLineGetArgument();
			LOGD("soundout='%s'", str);
			c64CommandLineAudioOutDevice = new CSlrString(str);
		}
		else if (!strcmp(cmd, "playlist") || !strcmp(cmd, "jukebox"))
		{
			char *str = c64ParseCommandLineGetArgument();
			LOGD("playlist='%s'", str);
			c64SettingsPathToJukeboxPlaylist = new CSlrString(str);
		}
	}
}

void C64DebuggerPerformStartupTasks()
{
	LOGM("C64DebuggerPerformStartupTasks()");
	C64PerformStartupTasksThread *thread = new C64PerformStartupTasksThread();
	SYS_StartThread(thread, NULL);
}

//

void C64DebuggerPassConfigToRunningInstance()
{
	//NSLog(@"C64DebuggerPassConfigToRunningInstance");
	
	c64SettingsPassConfigToRunningInstance = true;
	printLine("-----< C64 Debugger v%s by Slajerek/Samar >------\n", C64DEBUGGER_VERSION_STRING);
	fflush(stdout);
	
	//printLine("Passing parameters to running instance\n");
	
	LOGD("C64DebuggerPassConfigToRunningInstance: C64DebuggerParseCommandLine2");
	C64DebuggerParseCommandLine2();

	LOGD("C64DebuggerPassConfigToRunningInstance: after C64DebuggerParseCommandLine2");
	
	// check if we need just to pass parameters to other running instance
	// and pass them if necessary
	
	CByteBuffer *byteBuffer = new CByteBuffer();
	LOGD("...C64D_PASS_CONFIG_DATA_MARKER");
	byteBuffer->PutU16(C64D_PASS_CONFIG_DATA_MARKER);
	byteBuffer->PutU16(C64D_PASS_CONFIG_DATA_VERSION);
	
	LOGD("... put folder");
	gUTFPathToCurrentDirectory->DebugPrint("gUTFPathToCurrentDirectory=");
	byteBuffer->PutSlrString(gUTFPathToCurrentDirectory);

	if (c64SettingsPathToSnapshot)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_LOAD_SNAPSHOT);
		byteBuffer->PutSlrString(c64SettingsPathToSnapshot);
	}
	
	if (c64SettingsPathToBreakpoints)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_BREAKPOINTS_FILE);
		byteBuffer->PutSlrString(c64SettingsPathToBreakpoints);
	}
	
	if (c64SettingsPathToSymbols)
	{
		LOGD("c64SettingsPathToSymbols");
		c64SettingsPathToSymbols->DebugPrint("c64SettingsPathToSymbols=");
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_SYMBOLS_FILE);
		byteBuffer->PutSlrString(c64SettingsPathToSymbols);
	}
	
	if (c64SettingsPathToWatches)
	{
		LOGD("c64SettingsPathToWatches");
		c64SettingsPathToWatches->DebugPrint("c64SettingsPathToWatches=");
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_WATCHES_FILE);
		byteBuffer->PutSlrString(c64SettingsPathToWatches);
	}
	
	if (c64SettingsPathToDebugInfo)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_DEBUG_INFO);
		byteBuffer->PutSlrString(c64SettingsPathToDebugInfo);
	}
	
	if (c64SettingsWaitOnStartup > 0)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_WAIT);
		byteBuffer->putInt(c64SettingsWaitOnStartup);
	}
	
	if (c64SettingsPathToCartridge)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_PATH_TO_CRT);
		byteBuffer->PutSlrString(c64SettingsPathToCartridge);
	}

	if (c64SettingsPathToD64)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_PATH_TO_D64);
		byteBuffer->PutSlrString(c64SettingsPathToD64);
	}
	
	if (c64SettingsAutoJmp)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_SET_AUTOJMP);
		byteBuffer->PutBool(c64SettingsAutoJmp);
	}

	if (c64SettingsForceUnpause)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_FORCE_UNPAUSE);
		byteBuffer->PutBool(c64SettingsForceUnpause);
	}
	
	if (c64SettingsAutoJmpFromInsertedDiskFirstPrg)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_AUTO_RUN_DISK);
		byteBuffer->PutBool(c64SettingsAutoJmpFromInsertedDiskFirstPrg);
	}

	if (c64SettingsAutoJmpAlwaysToLoadedPRGAddress)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_ALWAYS_JMP);
		byteBuffer->PutBool(c64SettingsAutoJmpAlwaysToLoadedPRGAddress);
	}

	if (c64SettingsPathToPRG)
	{
		LOGD("c64SettingsPathToPRG");
		c64SettingsPathToPRG->DebugPrint("c64SettingsPathToPRG=");
		
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_PATH_TO_PRG);
		byteBuffer->PutSlrString(c64SettingsPathToPRG);
	}
	
	if (c64SettingsJmpOnStartupAddr >= 0)
	{
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_JMP);
		byteBuffer->putInt(c64SettingsJmpOnStartupAddr);
	}

	if (c64SettingsDefaultScreenLayoutId >= 0)
	{
		LOGD("c64SettingsDefaultScreenLayoutId=%d", c64SettingsDefaultScreenLayoutId);
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_LAYOUT);
		byteBuffer->putInt(c64SettingsDefaultScreenLayoutId);
	}

	if (c64CommandLineAudioOutDevice != NULL)
	{
		LOGD("c64CommandLineAudioOutDevice");
		byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_SOUND_DEVICE_OUT);
		byteBuffer->PutSlrString(c64CommandLineAudioOutDevice);
	}
	
	LOGD("...C64D_PASS_CONFIG_DATA_EOF");
	
	byteBuffer->PutU8(C64D_PASS_CONFIG_DATA_EOF);
	
	int pid = C64DebuggerSendConfiguration(byteBuffer);
	if (pid > 0)
	{
		printLine("Parameters sent to instance pid=%d. Bye.\n", pid);
		fflush(stdout);
		SYS_CleanExit();
	}
	else
	{
		printLine("Other instance was not found, performing regular startup instead.\n");
		fflush(stdout);
	}
}

void c64PerformNewConfigurationTasksThreaded(CByteBuffer *byteBuffer)
{
	LOGD("c64PerformNewConfigurationTasksThreaded");
	//byteBuffer->DebugPrint();
	byteBuffer->Rewind();
	
	u16 marker = byteBuffer->GetU16();
	if (marker != C64D_PASS_CONFIG_DATA_MARKER)
	{
		LOGError("Config data marker not found (received %04x, should be %04x)", marker, C64D_PASS_CONFIG_DATA_MARKER);
		return;
	}
	
	u16 v = byteBuffer->GetU16();
	if (v != C64D_PASS_CONFIG_DATA_VERSION)
	{
		LOGError("Config data version not correct (received %04x, should be %04x)", v, C64D_PASS_CONFIG_DATA_VERSION);
		return;
	}

	CSlrString *currentFolder = byteBuffer->GetSlrString();

	LOGD("... got folder");
	currentFolder->DebugPrint("currentFolder=");

	SYS_SetCurrentFolder(currentFolder);

	delete currentFolder;
	
	while(!byteBuffer->isEof())
	{
		uint8 t = byteBuffer->GetU8();

		if (t == C64D_PASS_CONFIG_DATA_EOF)
			break;
		
		if (t == C64D_PASS_CONFIG_DATA_LOAD_SNAPSHOT)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->viewC64Snapshots->LoadSnapshot(str, false);
			delete str;
			
			SYS_Sleep(150);
		}
		else if (t == C64D_PASS_CONFIG_DATA_BREAKPOINTS_FILE)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->symbols->ClearBreakpoints(viewC64->debugInterface);
			viewC64->symbols->ParseBreakpoints(str, viewC64->debugInterface);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_SYMBOLS_FILE)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->symbols->ClearSymbols(viewC64->debugInterface);
			viewC64->symbols->ParseSymbols(str, viewC64->debugInterface);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_WATCHES_FILE)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->symbols->ClearWatches(viewC64->debugInterface);
			viewC64->symbols->ParseWatches(str, viewC64->debugInterface);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_DEBUG_INFO)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->symbols->ClearSymbols(viewC64->debugInterface);
			viewC64->symbols->ParseSymbols(str, viewC64->debugInterface);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_WAIT)
		{
			int wait = byteBuffer->getInt();
			SYS_Sleep(wait);
		}
		else if (t == C64D_PASS_CONFIG_DATA_PATH_TO_D64)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->viewC64MainMenu->InsertD64(str, false, c64SettingsAutoJmpFromInsertedDiskFirstPrg, 0, true);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_PATH_TO_CRT)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->viewC64MainMenu->InsertCartridge(str, false);
			SYS_Sleep(666);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_SET_AUTOJMP)
		{
			bool b = byteBuffer->GetBool();
			c64SettingsAutoJmp = b;
		}
		else if (t == C64D_PASS_CONFIG_DATA_FORCE_UNPAUSE)
		{
			bool b = byteBuffer->GetBool();
			c64SettingsForceUnpause = b;
		}
		else if (t == C64D_PASS_CONFIG_DATA_AUTO_RUN_DISK)
		{
			bool b = byteBuffer->GetBool();
			c64SettingsAutoJmpFromInsertedDiskFirstPrg = b;
		}
		else if (t == C64D_PASS_CONFIG_DATA_ALWAYS_JMP)
		{
			bool b = byteBuffer->GetBool();
			c64SettingsAutoJmpAlwaysToLoadedPRGAddress = b;
		}
		else if (t == C64D_PASS_CONFIG_DATA_PATH_TO_PRG)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			viewC64->viewC64MainMenu->LoadPRG(str, c64SettingsAutoJmp, false, true);
			delete str;
		}
		else if (t == C64D_PASS_CONFIG_DATA_LAYOUT)
		{
			int layoutId = byteBuffer->getInt();
			c64SettingsDefaultScreenLayoutId = layoutId;
			if (c64SettingsDefaultScreenLayoutId >= C64_SCREEN_LAYOUT_MAX)
			{
				c64SettingsDefaultScreenLayoutId = C64_SCREEN_LAYOUT_C64_DEBUGGER;
			}
			viewC64->SwitchToScreenLayout(c64SettingsDefaultScreenLayoutId);

		}
		else if (t == C64D_PASS_CONFIG_DATA_JMP)
		{
			int jmpAddr = byteBuffer->getInt();
			viewC64->debugInterface->MakeJsrC64(jmpAddr);
		}
		else if (t == C64D_PASS_CONFIG_DATA_SOUND_DEVICE_OUT)
		{
			CSlrString *str = byteBuffer->GetSlrString();
			if (gSoundEngine->SetOutputAudioDevice(str) == false)
			{
				printLine("Selected sound out device not found, fall back to default output.\n");
			}
			
			delete str;
		}
	}
	
	//guiMain->ShowMessage("updated");
	delete byteBuffer;
}

class C64PerformNewConfigurationTasksThread : public CSlrThread
{
	virtual void ThreadRun(void *data)
	{
		LOGD("C64PerformNewConfigurationTasksThread: ThreadRun");
		CByteBuffer *byteBuffer = (CByteBuffer *)data;
		c64PerformNewConfigurationTasksThreaded(byteBuffer);
	};
};


void C64DebuggerPerformNewConfigurationTasks(CByteBuffer *byteBuffer)
{
	CByteBuffer *copyByteBuffer = new CByteBuffer(byteBuffer);
	
	C64PerformNewConfigurationTasksThread *thread = new C64PerformNewConfigurationTasksThread();
	SYS_StartThread(thread, copyByteBuffer);

}


//
//{
//	//// TEST
//	
//	LOGD("CViewC64::DoTap: TEST C64DebuggerSendConfiguration");
//	CByteBuffer *b = new CByteBuffer();
//	b->PutFloat(x);
//	b->PutFloat(y);
//	
//	C64DebuggerSendConfiguration(b);
//
//}
