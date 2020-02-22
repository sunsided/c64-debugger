#import "GLView.h"
#import "GLViewController.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSEvent.h>
#include "SND_SoundEngine.h"
#include "SYS_Threading.h"
#include "CSlrString.h"
#include "SYS_Funct.h"
#include "C64SettingsStorage.h"
#include "CViewC64.h"

GLView *glView;

@implementation GLView

#define MACOS_SUPPORT_RETINA

//-(BOOL)wantsLayer
//{
//	return YES;
//}
//
//-(id)makeBackingLayer
//{
//	[[CALayer layer] setBackgroundColor:(CGColorRef _Nullable)
//	return [CALayer layer];
//}
//
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

	[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	
	
	glView = self;
	
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
	
	//NSRect bounds = [self bounds];
	
	[[controller scene] initGL:backingBounds];
	
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	
	//
	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *event)
	{
		[controller keyDown:event];
		return event;
	}];

	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyUpMask handler:^(NSEvent *event)
	 {
		 [controller keyUp:event];
		 return event;
	 }];

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
	dispatch_async(dispatch_get_main_queue(), ^{

	#if defined(MACOS_SUPPORT_RETINA)
		NSRect backingBounds = [self convertRectToBacking:[self bounds]];
	#else
		NSRect backingBounds = [self bounds];
	#endif

		viewWidth = backingBounds.size.width;
		viewHeight = backingBounds.size.height;
		[[controller scene] setViewportRect:backingBounds];
		
	});
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
	if ([NSOpenGLContext currentContext] != openGLContext)
	{
		[openGLContext makeCurrentContext];
		[openGLContext update];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
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
	});
	
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
}

- (void) keyUp:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling key events
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

- (bool)isWindowFullScreen
{
	return [controller isWindowFullScreen];
}

- (BOOL)preservesContentDuringLiveResize
{
	return NO;
}

- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop
{
//	NSLog(@"setWindowAlwaysOnTop: %d", isAlwaysOnTop);
	if (isAlwaysOnTop)
	{
		[self.window setLevel:NSFloatingWindowLevel];
	}
	else
	{
		[self.window setLevel:NSNormalWindowLevel];
	}
}

- (void)storeMainWindowPosition
{
	[controller storeMainWindowPosition];
}

- (void)restoreMainWindowPosition
{
	[controller restoreMainWindowPosition];
}

- (void)testMenu
{
	NSLog(@"TEST MENU");
}

// drag&drop
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	//NSLog(@"draggingEntered");
	[self setNeedsDisplay: YES];
	return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	//NSLog(@"draggingExited");
	[self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	//NSLog(@"prepareForDragOperation");
	[self setNeedsDisplay: YES];
	return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	//NSLog(@"performDragOperation");

	NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	NSString *strExt = [[draggedFilenames objectAtIndex:0] pathExtension];

	if ([strExt isEqual:@"prg"] || [strExt isEqual:@"d64"] || [strExt isEqual:@"g64"]
		|| [strExt isEqual:@"crt"] || [strExt isEqual:@"tap"] || [strExt isEqual:@"t64"]
		|| [strExt isEqualToString:@"snap"] || [strExt isEqualToString:@"vce"] || [strExt isEqualToString:@"png"]
		|| [strExt isEqual:@"PRG"] || [strExt isEqual:@"D64"] || [strExt isEqual:@"G64"]
		|| [strExt isEqual:@"CRT"] || [strExt isEqual:@"TAP"] || [strExt isEqual:@"T64"]
		|| [strExt isEqualToString:@"SNAP"] || [strExt isEqualToString:@"VCE"] || [strExt isEqualToString:@"PNG"]
		|| [strExt isEqual:@"sid"] || [strExt isEqual:@"SID"]
		|| [strExt isEqual:@"xex"] || [strExt isEqual:@"XEX"]
		|| [strExt isEqual:@"atr"] || [strExt isEqualToString:@"ATR"]
		|| [strExt isEqual:@"cas"] || [strExt isEqual:@"CAS"]
		|| [strExt isEqual:@"car"] || [strExt isEqual:@"CAR"]
		|| [strExt isEqual:@"a8s"] || [strExt isEqual:@"A8S"]
		|| [strExt isEqual:@"nes"] || [strExt isEqual:@"NES"]
		|| [strExt isEqual:@"c64jukebox"] || [strExt isEqualToString:@"C64JUKEBOX"] || [strExt isEqual:@"json"] || [strExt isEqualToString:@"JSON"])
		
	{
		//NSString *strPath = [draggedFilenames objectAtIndex:0];
		//NSLog(@"..... YES=%@", strPath);
		return YES;
	}
	else
	{
		//NSLog(@"..... NO");
		return NO;
	}
}


// drag & drop callbacks
void C64D_DragDropCallbackPRG(CSlrString *filePath);
void C64D_DragDropCallbackD64(CSlrString *filePath);
void C64D_DragDropCallbackCRT(CSlrString *filePath);
void C64D_DragDropCallbackSID(CSlrString *filePath);
void C64D_DragDropCallbackSNAP(CSlrString *filePath);
void C64D_DragDropCallbackXEX(CSlrString *filePath);
void C64D_DragDropCallbackATR(CSlrString *filePath);
void C64D_DragDropCallbackCAS(CSlrString *filePath);
void C64D_DragDropCallbackCAR(CSlrString *filePath);
void C64D_DragDropCallbackA8S(CSlrString *filePath);
void C64D_DragDropCallbackNES(CSlrString *filePath);
void C64D_DragDropCallbackJukeBox(CSlrString *filePath);

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	//NSLog(@"concludeDragOperation");

	NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	NSString *strPath = [draggedFilenames objectAtIndex:0];
 
	MACOS_OpenFile(strPath);
}

enum
{
	MACOS_OPEN_FILE_TYPE_PRG = 1,
	MACOS_OPEN_FILE_TYPE_D64,
	MACOS_OPEN_FILE_TYPE_TAP,
	MACOS_OPEN_FILE_TYPE_CRT,
	MACOS_OPEN_FILE_TYPE_SID,
	MACOS_OPEN_FILE_TYPE_SNAP,
	MACOS_OPEN_FILE_TYPE_VCE,
	MACOS_OPEN_FILE_TYPE_PNG,
	MACOS_OPEN_FILE_TYPE_XEX,
	MACOS_OPEN_FILE_TYPE_ATR,
	MACOS_OPEN_FILE_TYPE_CAS,
	MACOS_OPEN_FILE_TYPE_CAR,
	MACOS_OPEN_FILE_TYPE_A8S,
	MACOS_OPEN_FILE_TYPE_NES,
	MACOS_OPEN_FILE_TYPE_JukeBox
};

static int macOsThreadedOpenFileType = -1;
static CSlrString *macOsThreadedOpenFilePath = NULL;
static CMacOsOpenFileThread *macOsOpenFileThread = new CMacOsOpenFileThread("OpenFileThread");
static bool macOsThreadedOpenFileAutoJMP = false;

BOOL MACOS_OpenFile(NSString *strPath)
{
	LOGD("MACOS_OpenFile");
	
	// TODO: fix this workaround by a proper threads scheduling:
	// store copy of Auto JMP parameter and make it false
	// so PRG is not loaded twice first with old settings by startup settings thread
	// the best would be to pass this setting to settings thread,
	// but we are not sure if it's already being run - and thus could be too late
	macOsThreadedOpenFileAutoJMP = c64SettingsAutoJmp;
	
	NSString *strExt = [strPath pathExtension];
	
	if ([strExt isEqual:@"prg"] || [strExt isEqual:@"PRG"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;

		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_PRG;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"d64"] || [strExt isEqual:@"D64"]
			 || [strExt isEqual:@"g64"] || [strExt isEqual:@"G64"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;

		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_D64;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"tap"] || [strExt isEqual:@"TAP"]
			 || [strExt isEqual:@"t64"] || [strExt isEqual:@"T64"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;
		
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_TAP;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"crt"] || [strExt isEqual:@"CRT"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;

		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_CRT;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"sid"] || [strExt isEqual:@"SID"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;
		
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_SID;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"snap"] || [strExt isEqual:@"SNAP"]
			 || [strExt isEqual:@"vsf"] || [strExt isEqual:@"VSF"])
	{
		//NSLog(@"%@", strPath);
		c64SettingsAutoJmp = false;

		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_SNAP;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"vce"] || [strExt isEqual:@"VCE"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_VCE;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"png"] || [strExt isEqual:@"PNG"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_PNG;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		return YES;
	}
	else if ([strExt isEqual:@"xex"] || [strExt isEqual:@"XEX"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_XEX;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"atr"] || [strExt isEqual:@"ATR"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_ATR;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"cas"] || [strExt isEqual:@"CAS"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_CAS;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"car"] || [strExt isEqual:@"CAR"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_CAR;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"a8s"] || [strExt isEqual:@"A8S"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_A8S;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"nes"] || [strExt isEqual:@"NES"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_NES;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}
	else if ([strExt isEqual:@"c64jukebox"] || [strExt isEqual:@"C64JUKEBOX"]
			 || [strExt isEqual:@"json"] || [strExt isEqual:@"JSON"])
	{
		macOsThreadedOpenFileType = MACOS_OPEN_FILE_TYPE_JukeBox;
		macOsThreadedOpenFilePath = FUN_ConvertNSStringToCSlrString(strPath);
		
		SYS_StartThread(macOsOpenFileThread);
		
		return YES;
	}

	return NO;
}

CMacOsOpenFileThread::CMacOsOpenFileThread(char *threadName)
: CSlrThread(threadName)
{
}

void CMacOsOpenFileThread::ThreadRun(void *data)
{
	LOGD("CMacOsOpenFileThread::ThreadRun: sleep");
	SYS_Sleep(400);
	
	if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_PRG)
	{
		LOGD("CMacOsOpenFileThread::ThreadRun: C64D_DragDropCallbackPRG");
		C64D_DragDropCallbackPRG(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_D64)
	{
		C64D_DragDropCallbackD64(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_TAP)
	{
		C64D_DragDropCallbackTAP(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_CRT)
	{
		C64D_DragDropCallbackCRT(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_SID)
	{
		C64D_DragDropCallbackSID(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_SNAP)
	{
		C64D_DragDropCallbackSNAP(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_VCE)
	{
		C64D_DragDropCallbackVCE(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_PNG)
	{
		C64D_DragDropCallbackPNG(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_XEX)
	{
		C64D_DragDropCallbackXEX(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_ATR)
	{
		C64D_DragDropCallbackATR(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_CAS)
	{
		C64D_DragDropCallbackCAS(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_CAR)
	{
		C64D_DragDropCallbackCAR(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_A8S)
	{
		C64D_DragDropCallbackA8S(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_NES)
	{
		C64D_DragDropCallbackNES(macOsThreadedOpenFilePath);
	}
	else if (macOsThreadedOpenFileType == MACOS_OPEN_FILE_TYPE_JukeBox)
	{
		C64D_DragDropCallbackJukeBox(macOsThreadedOpenFilePath);
	}

	delete macOsThreadedOpenFilePath;
	macOsThreadedOpenFilePath = NULL;
	macOsThreadedOpenFileType = -1;

	c64SettingsAutoJmp = macOsThreadedOpenFileAutoJMP;
}


- (void) dealloc
{
	SYS_ApplicationShutdown();
	
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
