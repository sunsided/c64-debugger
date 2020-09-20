//
//  AppDelegate.m
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 18/09/2020.
//  Copyright © 2020 Marcin Skoczylas. All rights reserved.
//

#import "AppDelegate.h"
#import "GLView.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSLog(@"applicationDidFinishLaunching");
	
	[NSApp activateIgnoringOtherApps:YES];
	NSWindow *w = self.window;
	GLView *v = [[GLView alloc] init];
	v.frame = [w contentRectForFrameRect:w.frame];
	w.contentView = v;
	[w makeFirstResponder:v];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	NSLog(@"applicationDidBecomeActive");
	[glView becomeFirstResponder];
	[NSApp activateIgnoringOtherApps:YES];
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
	NSLog(@"openFile");
	return MACOS_OpenFile(filename);
}

- (void)application:(NSApplication *)sender
		  openFiles:(NSArray *) filenames
{
	NSLog(@"openFiles");
	NSString *strPath = [filenames objectAtIndex:0];
	
	MACOS_OpenFile(strPath);
}


@end
