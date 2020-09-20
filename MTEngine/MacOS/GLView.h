//
//  GLView.h
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 18/09/2020.
//  Copyright © 2020 Marcin Skoczylas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "SYS_Threading.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLView : NSOpenGLView
{
	int viewWidth;
	int viewHeight;

	bool isAltKeyDown;
	bool isShiftKeyDown;
	bool isControlKeyDown;
}

-(void)startAnimation;
- (void)updateSize;

@end

extern GLView *glView;

BOOL MACOS_OpenFile(NSString *strPath);

class CMacOsOpenFileThread : public CSlrThread
{
public:
	CMacOsOpenFileThread(char *threadName);
	virtual void ThreadRun(void *data);
};

NS_ASSUME_NONNULL_END
