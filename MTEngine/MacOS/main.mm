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

int main(int argc, char *argv[])
{
	NSLog(@"main");
	
	@autoreleasepool
	{
		LOG_Init();

		SYS_InitCharBufPool();
		SYS_InitStrings();
		
		SYS_SetCommandLineArguments(argc, argv);
		
		SYS_InitFileSystem();
		
		C64DebuggerParseCommandLine0();

		NSLog(@"delegate");
	
		AppDelegate *delegate = [[AppDelegate alloc] init];
		[[NSApplication sharedApplication] setDelegate:delegate];

		NSLog(@"conf NSApp");

		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		NSString *appName = [[NSProcessInfo processInfo] processName];

		[NSApp activateIgnoringOtherApps:YES];

		[NSApp setMainMenu:createMenuBar(appName)];

		NSLog(@"conf window");
		NSRect frame = NSRectFromCGRect(CGRectMake(100, 100, 800, 600));
		GLWindow *window = [[GLWindow alloc] initWithContentRect:frame
												styleMask:NSTitledWindowMask | NSResizableWindowMask | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
												  backing:NSBackingStoreBuffered
													defer:NO];
		[delegate setWindow:window];
		[window setTitle:appName];
		[window makeFirstResponder: glView];
		[window setBackgroundColor: NSColor.blackColor];
		[window makeKeyAndOrderFront:nil];

		[NSApp activateIgnoringOtherApps:YES];

//		[NSApp run];
//		return 0;
		return NSApplicationMain(argc,  (const char **) argv);
	}
}
