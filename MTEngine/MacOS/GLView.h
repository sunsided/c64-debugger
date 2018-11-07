#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

#include "SYS_Threading.h"

@class GLViewController;

@interface GLView : NSView
{
	
	NSOpenGLContext *openGLContext;
	NSOpenGLPixelFormat *pixelFormat;
	
	GLViewController *controller;
	
	CVDisplayLinkRef displayLink;
	BOOL isAnimating;
	
	int viewWidth;
	int viewHeight;
}

- (void) initGL;

- (id) initWithFrame:(NSRect)frameRect;
- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context;

- (NSOpenGLContext*) openGLContext;

- (void) setMainController:(GLViewController*)theController;

- (void) updateSize;

- (void) drawView;

- (void) startAnimation;
- (void) stopAnimation;

- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop;

- (bool)isWindowFullScreen;

@end

extern GLView *glView;

BOOL MACOS_OpenFile(NSString *strPath);

class CMacOsOpenFileThread : public CSlrThread
{
public:
	CMacOsOpenFileThread(char *threadName);
	virtual void ThreadRun(void *data);
};
