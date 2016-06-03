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

int main(int argc, char *argv[])
{
	//@autoreleasepool
	{
		LOG_Init();
		SYS_SetCommandLineArguments(argc, argv);
		return NSApplicationMain(argc,  (const char **) argv);
	}
}
