		//
//  main.m
//  MTEngine
//
//  Created by Marcin Skoczylas on 1/31/12.
//  Copyright (c) 2012 Marcin Skoczylas. All rights reserved.
//

// crash symbolicator for MacOS: https://github.com/agentsim/Symbolicator


#import <Cocoa/Cocoa.h>
#include "DBG_Log.h"
#include "SYS_CommandLine.h"
#include "SYS_CFileSystem.h"

void SYS_InitCharBufPool();
void SYS_InitStrings();


void C64DebuggerParseCommandLine0();

int main(int argc, char *argv[])
{
	@autoreleasepool
	{
		LOG_Init();

		SYS_InitCharBufPool();
		SYS_InitStrings();
		
		SYS_SetCommandLineArguments(argc, argv);
		
		SYS_InitFileSystem();
		
		C64DebuggerParseCommandLine0();

		return NSApplicationMain(argc,  (const char **) argv);
	}
}
