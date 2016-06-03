#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

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

@end
