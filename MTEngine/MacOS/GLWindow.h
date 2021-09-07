//
//  GLWindow.h
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 19/09/2020.
//
//

#import <Cocoa/Cocoa.h>

@interface GLWindow : NSWindow <NSWindowDelegate>

- (void) close;

//! @return yes
- (BOOL) acceptsFirstResponder;

////! Close the window if escape key is receieved.
//- (void) keyDown:(NSEvent*)event;

- (void)windowDidMove:(NSNotification *)notification;

@end
