//
//  MenuControllerSettings
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 11/9/12.
//
//

#import <Foundation/Foundation.h>

@interface MenuControllerSettings : NSMenu {
	
}

- (IBAction)aboutKCT:(id)pId;

- (IBAction)playSounds:(id)pId;
- (IBAction)playMusic:(id)pId;
- (IBAction)enableSharingMenu:(id)pId;

@end

void SYS_UpdateMenuItems();