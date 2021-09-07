		//
//  main.m
//  MTEngine
//
//  Created by Marcin Skoczylas on 1/31/12.
//  Copyright (c) 2012 Marcin Skoczylas. All rights reserved.
//

// crash symbolicator for MacOS: https://github.com/agentsim/Symbolicator


#import <Cocoa/Cocoa.h>
#import "GLWindow.h"
#import "GLView.h"
#import "AppDelegate.h"
#include "DBG_Log.h"
#include "SYS_CommandLine.h"
#include "SYS_CFileSystem.h"
#include "C64CommandLine.h"
#include "C64D_Version.h"

void SYS_InitCharBufPool();
void SYS_InitStrings();
void C64DebuggerParseCommandLine0();

NSMenu* createMenuBar(NSString *appName) {
  id menubar = [NSMenu new];
  id appMenuItem = [NSMenuItem new];
  id appMenu = [NSMenu new];
  id quitMenuItem = [[NSMenuItem alloc]
                     initWithTitle:[@"Quit " stringByAppendingString:appName]
                     action:@selector(terminate:)
                     keyEquivalent:@"q"];

  [appMenu addItem:quitMenuItem];
  [appMenuItem setSubmenu:appMenu];
  [menubar addItem:appMenuItem];
  return menubar;
}

GLWindow *mainWindow;

int main(int argc, char *argv[])
{
//	NSLog(@"MTEngine: main");
	
	@autoreleasepool
	{
		LOG_Init();

		SYS_InitCharBufPool();
		SYS_InitStrings();
		
		SYS_SetCommandLineArguments(argc, argv);
		
		SYS_InitFileSystem();
		
		C64DebuggerInitStartupTasks();
		C64DebuggerParseCommandLine0();

		AppDelegate *delegate = [[AppDelegate alloc] init];
		[[NSApplication sharedApplication] setDelegate:delegate];

		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		
#if defined(RUN_COMMODORE64)
		NSString *appName = @"C64 Debugger";
#elif defined(RUN_ATARI)
		NSString *appName = @"65XE Debugger";
#elif defined(RUN_NES)
		NSString *appName = @"NES Debugger";
#else
		NSString *appName = [[NSProcessInfo processInfo] processName];
#endif
		[NSApp activateIgnoringOtherApps:YES];

		[NSApp setMainMenu:createMenuBar(appName)];
		
		NSRect frame = [GLView getStoredMainWindowPosition];
//		NSLog(@"frame=%@", NSStringFromRect(frame));
		
		mainWindow = [[GLWindow alloc] initWithContentRect:frame
												styleMask:NSTitledWindowMask | NSResizableWindowMask | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
												  backing:NSBackingStoreBuffered
													defer:NO];
		[delegate setWindow: mainWindow];
		[mainWindow setDelegate:mainWindow];
		[mainWindow setTitle: appName];
		[mainWindow setFrame: frame display:NO];
		[mainWindow makeFirstResponder: glView];
		[mainWindow setBackgroundColor: NSColor.blackColor];
		[mainWindow makeKeyAndOrderFront:nil];

		[NSApp activateIgnoringOtherApps:YES];
		
//		[NSApp run];
//		return 0;
		return NSApplicationMain(argc,  (const char **) argv);
	}
}
