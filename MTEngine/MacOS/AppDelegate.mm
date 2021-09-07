//
//  AppDelegate.m
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 18/09/2020.
//  Copyright © 2020 Marcin Skoczylas. All rights reserved.
//

#import "AppDelegate.h"
#import "GLView.h"
#include "CViewC64.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	LOGD("applicationDidFinishLaunching");
	
	[NSApp activateIgnoringOtherApps:YES];
	NSWindow *w = self.window;
	GLView *v = [[GLView alloc] init];
	v.frame = [w contentRectForFrameRect:w.frame];
	w.contentView = v;
	[w makeFirstResponder:v];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	LOGD("applicationDidBecomeActive");
	[glView becomeFirstResponder];
	[NSApp activateIgnoringOtherApps:YES];
	
	// DEBUG
//	MACOS_ApplicationStartWithFile(@"testfile.prg");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

//- (void)windowWillClose:(NSNotification *)notification
//{
//
//}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	LOGD("application:openFile");
	
	if (viewC64 == NULL)
	{
		return MACOS_ApplicationStartWithFile(filename);
	}
	
	return MACOS_OpenFile(filename);
}

- (void)application:(NSApplication *)sender
		  openFiles:(NSArray *) filenames
{
	LOGD("application:openFiles");
	NSString *strPath = [filenames objectAtIndex:0];
	
	if (viewC64 == NULL)
	{
		MACOS_ApplicationStartWithFile(strPath);
	}
	else
	{
		MACOS_OpenFile(strPath);
	}
}


@end
