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

#define printLine printf

void c64ShowCommandLineHelp()
{
	printLine("C64 Debugger v%s by Slajerek/Samar, VICE 2.4 by The VICE Team\n", C64DEBUGGER_VERSION_STRING);
	printLine("\n");
	printLine("-help  show this help\n");
	printLine("\n");
	printLine("-layout <id> start with layout id <1-%d>\n", C64_SCREEN_LAYOUT_MAX);
	printLine("-breakpoints <file>  load breakpoints from file\n");
	printLine("-vicesymbols <file>  load Vice symbols (code labels)");
	printLine("\n");
	printLine("-wait <ms>   wait before performing tasks\n");
	printLine("-prg <file>  load PRG file into memory\n");
	printLine("-d64 <file>  insert D64 disk\n");
	printLine("-crt <file>  attach cartridge\n");
	printLine("-jmp <addr>  jmp to address\n");
	printLine("             for example jmp x1000, jmp $1000 or jmp 4096\n");
	printLine("-autojmp     automatically jmp to address if basic SYS is detected\n");
	printLine("-snapshot <file>  load snapshot from file\n");
	printLine("\n");
	printLine("-clearsettings    clear all config settings");
	printLine("\n");
	
	SYS_CleanExit();
}


void C64DebuggerParseCommandLine1()
{
	if (sysCommandLineArguments.size() > 0)
	{
		char *cmd = sysCommandLineArguments[0];
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

void c64PerformStartupTasksThreaded()
{
	LOGD("c64PerformStartupTasksThreaded");
	
	// process, order is important
	// we need to create new strings for path as they will be deleted and updated by loaders
	if (c64SettingsPathSnapshot != NULL)
	{
		viewC64->viewC64Snapshots->LoadSnapshot(c64SettingsPathSnapshot, false);
	}
	else
	{
		// TODO: Is it possible to init VICE with proper Engines at startup to not re-create here?
		if (c64SettingsC64Model != 0)
		{
			SYS_Sleep(300);
			viewC64->debugInterface->SetC64ModelType(c64SettingsC64Model);
		}
		
		if (c64SettingsSIDEngineModel != 0)
		{
			viewC64->debugInterface->SetSidType(c64SettingsSIDEngineModel);
		}
		
		if (c64SettingsPathD64 != NULL)
		{
			viewC64->viewC64MainMenu->InsertD64(c64SettingsPathD64);
		}
		
		if (c64SettingsPathCartridge != NULL)
		{
			viewC64->viewC64MainMenu->InsertCartridge(c64SettingsPathCartridge);
			SYS_Sleep(666);
		}
		
		if (c64SettingsPathPRG != NULL)
		{
			//LOGD("c64SettingsPathPRG='%s'", c64SettingsPathPRG);
			//		if (statepath == NULL)
			//		{
			//			// load default state to speed up
			//			CSlrFile *file = RES_GetFile("/c64/startup", DEPLOY_FILE_TYPE_DATA);
			//			CByteBuffer *buf = new CByteBuffer(file, false);
			//			viewC64->viewC64Snapshots->LoadSnapshot(buf, false);
			//			delete buf;
			//			delete file;
			//		}
			
			viewC64->viewC64MainMenu->LoadPRG(c64SettingsPathPRG, c64SettingsAutoJmp);
		}
		
		if (c64SettingsJmpOnStartupAddr > 0 && c64SettingsJmpOnStartupAddr < 0x10000)
		{
			//SYS_Sleep(150);
			
			//LOGD("c64SettingsJmpOnStartupAddr=%04x", c64SettingsJmpOnStartupAddr);

			viewC64->debugInterface->MakeJsrC64(c64SettingsJmpOnStartupAddr);
		}
	}
}

class C64PerformStartupTasksThread : public CSlrThread
{
	virtual void ThreadRun(void *data)
	{
		if (c64SettingsPathSnapshot != NULL && c64SettingsWaitOnStartup < 150)
			c64SettingsWaitOnStartup = 150;
		
		SYS_Sleep(c64SettingsWaitOnStartup);
		c64PerformStartupTasksThreaded();
	};
};

void C64DebuggerParseCommandLine2()
{
	if (sysCommandLineArguments.empty())
		return;
	
	c64cmdIt = sysCommandLineArguments.begin();
	
	while(c64cmdIt != sysCommandLineArguments.end())
	{
		char *cmd = c64ParseCommandLineGetArgument();
		if (cmd[0] == '-')
			cmd++;
		
		if (!strcmp(cmd, "breakpoints") || !strcmp(cmd, "b"))
		{
			char *fname = c64ParseCommandLineGetArgument();
			viewC64->symbols->ParseBreakpoints(fname, viewC64->debugInterface);
		}
		else if (!strcmp(cmd, "vicesymbols") || !strcmp(cmd, "vs"))
		{
			char *fname = c64ParseCommandLineGetArgument();
			viewC64->symbols->ParseSymbols(fname, viewC64->debugInterface);
		}
		else if (!strcmp(cmd, "autojmp"))
		{
			c64SettingsAutoJmp = true;
		}
		else if (!strcmp(cmd, "d64"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathD64 = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "prg"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathPRG = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "cartridge"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathCartridge = new CSlrString(arg);
		}
		else if (!strcmp(cmd, "snapshot"))
		{
			char *arg = c64ParseCommandLineGetArgument();
			c64SettingsPathSnapshot = new CSlrString(arg);
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
		}
		else if (!strcmp(cmd, "wait"))
		{
			char *str = c64ParseCommandLineGetArgument();
			c64SettingsWaitOnStartup = atoi(str);
		}

	}
}

void C64DebuggerPerformStartupTasks()
{
	C64PerformStartupTasksThread *thread = new C64PerformStartupTasksThread();
	SYS_StartThread(thread, NULL);
}
