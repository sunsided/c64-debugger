#import "GLView.h"
#import "GLViewController.h"
#include "SND_SoundEngine.h"
#include "SYS_Threading.h"

@implementation GLView

#define MACOS_SUPPORT_RETINA

- (NSOpenGLContext*) openGLContext
{
	return openGLContext;
}

- (NSOpenGLPixelFormat*) pixelFormat
{
	return pixelFormat;
}

- (void) setMainController:(GLViewController*)theController;
{
	controller = theController;
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called because it will be called from a background thread
	// It's important to create one or you will leak objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Update the animation
	CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
	[[controller scene] advanceTimeBy:(currentTime - [controller renderTime])];
	[controller setRenderTime:currentTime];
	
	[self drawView];
	
	[pool release];
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(GLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void) setupDisplayLink
{
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
}

- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context
{
    NSOpenGLPixelFormatAttribute attribs[] =
    {
		kCGLPFAAccelerated,
		kCGLPFANoRecovery,
		kCGLPFADoubleBuffer,
		kCGLPFAColorSize, 24,
//		kCGLPFADepthSize, 16,
		kCGLPFAStencilSize, 8,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 4,
		NSOpenGLPFADoubleBuffer,
		0
    };
	
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
    if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");
	
	// NSOpenGLView does not handle context sharing, so we draw to a custom NSView instead
	openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
	
	if (self = [super initWithFrame:frameRect]) 
	{
		[[self openGLContext] makeCurrentContext];
		
		// Synchronize buffer swaps with vertical refresh rate
		GLint swapInt = 1;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
		
		[self setupDisplayLink];
		
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override 
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(reshape) 
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
	
	}
	
//	NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
//									 NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
	
//	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
//														options:options
//														  owner:self
//													   userInfo:nil];
	
	return self;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}


- (void) initGL
{
#if defined(MACOS_SUPPORT_RETINA)
	[self setWantsBestResolutionOpenGLSurface:YES];
	NSRect backingBounds = [self convertRectToBacking:[self bounds]];
#else
	NSRect backingBounds = [self bounds];
#endif
	
	[[controller scene] initGL:backingBounds];
	
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
}

- (void) lockFocus
{
	[super lockFocus];
	if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
}

- (void) reshape
{
	// This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	// Delegate to the scene object to update for a change in the view size
	[self updateSize];
	
	[[self openGLContext] update];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)updateSize
{
	//NSLog(@"updateSize");
	
#if defined(MACOS_SUPPORT_RETINA)
	NSRect backingBounds = [self convertRectToBacking:[self bounds]];
#else
	NSRect backingBounds = [self bounds];
#endif

	viewWidth = backingBounds.size.width;
	viewHeight = backingBounds.size.height;
	[[controller scene] setViewportRect:backingBounds];
}

//https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaPerformance/Articles/CocoaLiveResize.html

- (void)viewDidEndLiveResize
{
	[self updateSize];
}

- (void) drawRect:(NSRect)dirtyRect
{
	// Ignore if the display link is still running
	if (!CVDisplayLinkIsRunning(displayLink))
		[self drawView];
}

- (void) drawView
{
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	// Make sure we draw to the right context
	[[self openGLContext] makeCurrentContext];
	
#if defined(MACOS_SUPPORT_RETINA)
	NSRect backingBounds = [self convertRectToBacking:[self bounds]];
#else
	NSRect backingBounds = [self bounds];
#endif
	
	if (viewWidth != backingBounds.size.width
		|| viewHeight != backingBounds.size.height)
	{
		[self updateSize];
	}
		
	// Delegate to the scene object for rendering
    [[controller scene] render];
	
	[[self openGLContext] flushBuffer];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}
 
- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	// Delegate to the controller object for handling key events
	[controller flagsChanged:theEvent];
}

- (void) keyDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling key events
    [controller keyDown:theEvent];
}

- (void) keyUp:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling key events
    [controller keyUp:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling mouse events
    [controller mouseDown:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling mouse events
    [controller mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling mouse events
    [controller mouseUp:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	// Delegate to the controller object for handling mouse events
	[controller rightMouseDown:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	// Delegate to the controller object for handling mouse events
	[controller rightMouseDragged:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	// Delegate to the controller object for handling mouse events
	[controller rightMouseUp:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	// Delegate to the controller object for handling mouse events
	[controller mouseMoved:theEvent];
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
	[controller magnifyWithEvent:theEvent];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[controller scrollWheel:theEvent];
}

- (void) startAnimation
{
	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStart(displayLink);
}

- (void) stopAnimation
{
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
}

- (BOOL)preservesContentDuringLiveResize
{
	return NO;
}

void SYS_PrepareShutdown();

- (void) dealloc
{
	SYS_PrepareShutdown();
	
	// stop playing audio
	gSoundEngine->LockMutex("shutdown");
	
	// Stop and release the display link
	CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
	
	// Destroy the context
	[openGLContext release];
	[pixelFormat release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSViewGlobalFrameDidChangeNotification
												  object:self];
	[super dealloc];
}	


@end
