//
//  MenuControllerSettings.m
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 11/9/12.
//
//

#import "MenuControllerSettings.h"
#include "SYS_Defs.h"
#include "DBG_Log.h"
#include "SYS_Main.h"

//#include "CViewKidsChristmasTreeMain.h"

@implementation MenuControllerSettings

- (IBAction)aboutKCT:(id)pId
{
	LOGM("menu select: about");
	
	NSURL *url = [NSURL URLWithString:@"http://samar.untergrund.net/"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)playSounds:(id)pId
{
	SYS_FatalExit("REMOVED");
	
//	LOGM("menu select: playSounds");
//
//	NSMenuItem *menuItem = (NSMenuItem *)pId;
//	
//	LOGD("menuItem.state=%d", menuItem.state);
//	
//	bool selected = false;
//	if (menuItem.state == 1)
//	{
//		[menuItem setState:0];
//		selected = false;
//	}
//	else
//	{
//		[menuItem setState:1];
//		selected = true;
//	}
//	
//	viewKCTMain->SetEnableSounds(selected);
}

- (IBAction)playMusic:(id)pId
{
	LOGM("menu select: playMusic");

	SYS_FatalExit("REMOVED");

//	NSMenuItem *menuItem = (NSMenuItem *)pId;
//	LOGD("menuItem.state=%d", menuItem.state);
//	
//	bool selected = false;
//	if (menuItem.state == 1)
//	{
//		[menuItem setState:0];
//		selected = false;
//	}
//	else
//	{
//		[menuItem setState:1];
//		selected = true;
//	}
//	
//	viewKCTMain->SetEnableMusic(selected);
}

- (IBAction)enableSharingMenu:(id)pId
{
	LOGM("menu select: enableSharingMenu");
	
	SYS_FatalExit("REMOVED");

//	NSMenuItem *menuItem = (NSMenuItem *)pId;
//	LOGD("menuItem.state=%d", menuItem.state);
//	
//	bool selected = false;
//	if (menuItem.state == 1)
//	{
//		[menuItem setState:0];
//		selected = false;
//	}
//	else
//	{
//		[menuItem setState:1];
//		selected = true;
//	}
//	
//	viewKCTMain->SetEnableSharingMenu(selected);
}

@end

void SYS_UpdateMenuItems()
{
	return;

//	LOGD("SYS_UpdateMenuItems");
//	NSMenu *rootMenu = [NSApp mainMenu];
//	NSMenuItem *subMenu = [rootMenu itemAtIndex:[rootMenu indexOfItemWithTitle: @"Settings"]];
//	
//	NSArray *menuItems = subMenu.submenu.itemArray;
//    NSMenuItem *menuItem;
//	
//	menuItem = [menuItems objectAtIndex:0];
//	if (viewKCTMain->enableSounds)
//	{
//		[menuItem setState:NSOnState];
//	}
//	else
//	{
//		[menuItem setState:NSOffState];
//	}
//
//	menuItem = [menuItems objectAtIndex:1];
//	if (viewKCTMain->enableMusic)
//	{
//		[menuItem setState:NSOnState];
//	}
//	else
//	{
//		[menuItem setState:NSOffState];
//	}
//
//	viewKCTMain->enableSharingMenu = false;
	

	/*menuItem = [menuItems objectAtIndex:3];
	if (viewKCTMain->enableSharingMenu)
	{
		[menuItem setState:NSOnState];
	}
	else
	{
		[menuItem setState:NSOffState];
	}*/
	
}

