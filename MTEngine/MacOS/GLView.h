//
//  GLView.h
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 18/09/2020.
//  Copyright © 2020 Marcin Skoczylas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "SYS_Threading.h"
#include "C64CommandLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLView : NSOpenGLView
{
	int viewWidth;
	int viewHeight;

	bool isAltKeyDown;
	bool isShiftKeyDown;
	bool isControlKeyDown;
}

- (void)startAnimation;
- (void)updateSize;
- (bool)isWindowFullScreen;
- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop;
- (void)storeMainWindowPosition;
- (void)restoreMainWindowPosition;
+ (NSRect)getStoredMainWindowPosition;
- (void)goFullScreen;
- (void)shutdownMTEngine;

@end

extern GLView *glView;

BOOL MACOS_OpenFile(NSString *strPath);
BOOL MACOS_ApplicationStartWithFile(NSString *strPath);

class CMacOsOpenFileThread : public CSlrThread
{
public:
	CMacOsOpenFileThread(char *threadName);
	virtual void ThreadRun(void *data);
};

class C64DebuggerStartupTaskOpenFileCallback : public C64DebuggerStartupTaskCallback
{
public:
	virtual void PreRunStartupTaskCallback();
	virtual void PostRunStartupTaskCallback();
};

NS_ASSUME_NONNULL_END
