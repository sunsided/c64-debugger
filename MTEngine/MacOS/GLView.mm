//
//  GLView.m
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 18/09/2020. Based on Stackoverflow examples, kept original comments.
//  Copyright © 2020 Marcin Skoczylas. All rights reserved.
//

#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <Foundation/Foundation.h>

#import "GLView.h"
#include "DBG_Log.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <CoreVideo/CVDisplayLink.h>
#import <AppKit/AppKit.h>
#import <AppKit/NSEvent.h>

#include "SND_SoundEngine.h"
#include "SYS_Threading.h"
#include "CSlrString.h"
#include "SYS_Funct.h"
#include "C64SettingsStorage.h"
#include "CViewC64.h"
#include "MenuControllerSettings.h"
#include "VID_GLViewController.h"
#include "SYS_KeyCodes.h"
#include "CGuiMain.h"
#include "SYS_PauseResume.h"
#include "SYS_Defs.h"

GLView *glView;

@implementation GLView
{
	CVDisplayLinkRef displayLink;
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	@autoreleasepool {
		[self drawView];
	}
	return kCVReturnSuccess;
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink,
									const CVTimeStamp* now,
									const CVTimeStamp* outputTime,
									CVOptionFlags flagsIn,
									CVOptionFlags* flagsOut,
									void* displayLinkContext)
{
//	LOGD("displayLinkCallback");
	CVReturn result = [(__bridge GLView*)displayLinkContext getFrameForTime:outputTime];
	return result;
}

- (instancetype) init
{
	glView = self;
	
	if ((self = [super init])) {
		NSOpenGLPixelFormatAttribute attrs[] =
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
		
		NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
		if (!pf) {
			NSLog(@"FATAL: No OpenGL pixel format");
			exit(EINVAL);
		}
		
		NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
		
#ifndef NDEBUG
		// When we're using a CoreProfile context, crash if we call a legacy OpenGL function
		// This will make it much more obvious where and when such a function call is made so
		// that we can remove such calls.
		// Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
		// but it would be more difficult to see where that function was called.
		CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif
		
		[self setPixelFormat:pf];
		[self setOpenGLContext:context];
		
		[self setWantsBestResolutionOpenGLSurface:YES];
		
	} else {
		NSLog(@"FATAL view creation failure"); // "never" happens
		exit(EINVAL);
	}
	
	isAltKeyDown = false;
	isShiftKeyDown = false;
	isControlKeyDown = false;

	NSWindow *mainWindow = [self window];
	[mainWindow setAcceptsMouseMovedEvents:YES];
	[self restoreMainWindowPosition];

	SYS_UpdateMenuItems();

	return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void) prepareOpenGL
{
	[super prepareOpenGL];
	[self initGL];


	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void*)self);

	//  the below crashes:
	//  CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	//  CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	//  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);

	CVDisplayLinkStart(displayLink);
		
	// register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
	
	// and for mouseMoved events
	NSTrackingArea *trackingArea =
		[[NSTrackingArea alloc] initWithRect:self.frame options:NSTrackingActiveAlways | NSTrackingInVisibleRect |
											 NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved
									   owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void) windowWillClose:(NSNotification*)notification
{
	CVDisplayLinkStop(displayLink);
}

- (void) initGL
{
	[[self openGLContext] makeCurrentContext];
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	

	[self setWantsBestResolutionOpenGLSurface:YES];
	NSRect backingBounds = [self convertRectToBacking:[self bounds]];

	[[NSThread currentThread] setName:@"MAIN"];
	LOGM("Scene: initGL");
	int viewWidth = backingBounds.size.width;
	int viewHeight = backingBounds.size.height;
	VID_InitGL(viewWidth, viewHeight);

	[self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}

- (void)reshape
{
	[super reshape];
	
	// We draw on a secondary thread through the display link. However, when
	// resizing the view, -drawRect is called on the main thread.
	// Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing.
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	// Get the view size in Points
	NSRect viewRectPoints = [self bounds];
	NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
	
	[self updateSize];

	CGLUnlockContext([[self openGLContext] CGLContextObj]);
	
	// coming back from fullscreen stops the display link (thanks Apple, it was not in previous OSes!)
	[self startAnimation];
}

- (void)updateSize
{
//	NSLog(@"updateSize");
//	dispatch_async(dispatch_get_main_queue(), ^{

		NSRect backingBounds = [self convertRectToBacking:[self bounds]];

		viewWidth = backingBounds.size.width;
		viewHeight = backingBounds.size.height;
		
		VID_UpdateViewPort(backingBounds.size.width, backingBounds.size.height);
		
//	});
}

- (void)viewDidEndLiveResize
{
	[self updateSize];
}

- (void)renewGState
{
	[[self window] disableScreenUpdatesUntilFlush];
	[super renewGState];
}

- (void) drawRect: (NSRect) theRect
{
	[self drawView]; // Avoid flickering during resize by drawiing
}

- (void) drawView
{
	[[self openGLContext] makeCurrentContext];
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
//	NSLog(@"drawRect");
//	static int i = 0;
//	i = ++i % 3;
//
//	switch (i) {
//		case 0: glClearColor(1, 0, 0, 1); break;
//		case 1: glClearColor(0, 1, 0, 1); break;
//		case 2: glClearColor(0, 0, 1, 1); break;
//	}
//
//	glClear(GL_COLOR_BUFFER_BIT);

	dispatch_async(dispatch_get_main_queue(), ^{
			NSRect backingBounds = [self convertRectToBacking:[self bounds]];
		
			if (viewWidth != backingBounds.size.width
				|| viewHeight != backingBounds.size.height)
			{
				[self updateSize];
			}
	});

	VID_DrawView();
	
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (bool)isWindowFullScreen
{
	NSWindow *mainWindow = [self window];

	NSUInteger masks = [mainWindow styleMask];
	if ( masks & NSFullScreenWindowMask)
	{
		return true;
	}
	
	return false;
}

u32 mapKey(int c, int keyCodeBare, bool isShift)
{
	LOGI("mapKey c=%d (%04x), keyCodeBare=%d (%04x) isShift=%d", c, c, keyCodeBare, keyCodeBare, isShift);
	
	// spanish keyboard workaround
	if (c == 0x27 && keyCodeBare == 0)	//39
	{
		if (isShift)
		{
			return MTKEY_UMLAUT;
		}
		else
		{
			return MTKEY_RIGHT_APOSTROPHE;
		}
	}

	// spanish keyboard workaround
	if (c == 0x21 && keyCodeBare == 0)	//33
	{
		if (isShift)
		{
			return MTKEY_TILDE;
		}
		else
		{
			return '[';
		}
	}
	

	if (c == 53)
		return MTKEY_ESC;
	else if (c == 123)
		return MTKEY_ARROW_LEFT;
	else if (c == 124)
		return MTKEY_ARROW_RIGHT;
	else if (c == 125)
		return MTKEY_ARROW_DOWN;
	else if (c == 126)
		return MTKEY_ARROW_UP;
	else if (c == 51)
		return MTKEY_BACKSPACE;
	else if (c == 117)
		return MTKEY_DELETE;
	else if (c == 36)
		return MTKEY_ENTER;
	else if (c == 48)
		return MTKEY_TAB;
	else if (c == 0x007A)
		return MTKEY_F1;
	else if (c == 0x0078)
		return MTKEY_F2;
	else if (c == 0x0063)
		return MTKEY_F3;
	else if (c == 0x0076)
		return MTKEY_F4;
	else if (c == 0x0060)
		return MTKEY_F5;
	else if (c == 0x0061)
		return MTKEY_F6;
	else if (c == 0x0062)
		return MTKEY_F7;
	else if (c == 0x0064)
		return MTKEY_F8;
	else if (c == 0x0065)
		return MTKEY_F9;
	else if (c == 0x006D)
		return MTKEY_F10;
	else if (c == 0x0067)
		return MTKEY_F11;
	else if (c == 0x0074)
		return MTKEY_PAGE_UP;
	else if (c == 0x0079)
		return MTKEY_PAGE_DOWN;
	else if (c == 0x0027)				// workaround for spanish keyboard
	{
		if (isShift)
		{
			return '"';
		}
		else
		{
			return '\'';
		}
	}
	else if (c == 0x0021)
	{
		if (isShift)
		{
			return '{';
		}
		else
		{
			return '[';
		}
	}
	else if (c == 0x0032)
	{
		if (isShift)
		{
			return MTKEY_TILDE;
		}
		else
		{
			return MTKEY_LEFT_APOSTROPHE;
		}
	}
	else
	{
		//LOGD("mapKey: %d", c);
	}
	
	return 0;
}

int quitKeyCode = -1;
bool quitIsShift = false;
bool quitIsAlt = false;
bool quitIsControl = false;

void SYS_SetQuitKey(int keyCode, bool isShift, bool isAlt, bool isControl)
{
	quitKeyCode = keyCode;
	quitIsShift = isShift;
	quitIsAlt = isAlt;
	quitIsControl = isControl;
}

void SYS_DoFastQuit()
{
	
}

- (int) characterWithoutModifierKeysIncludingShift:(NSEvent *)event
{
	CFDataRef currentLayoutData;
	TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
	
	if(currentKeyboard == NULL)
	{
		LOGError("Could not find keyboard layout\n");
		return 0;
	}
	
	currentLayoutData = (CFDataRef)TISGetInputSourceProperty(currentKeyboard,
															 kTISPropertyUnicodeKeyLayoutData);
	CFRelease(currentKeyboard);
	if(currentLayoutData == NULL)
	{
		LOGError("Could not find layout data\n");
		return 0;
	}
	
	const UCKeyboardLayout* keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(currentLayoutData);
	
	const UniCharCount maxStrLen = 4;
	UniChar strBuff[maxStrLen];
	UniCharCount actualLength = 0;
	UInt32 deadKeyState = 0;
	
	OSStatus status = UCKeyTranslate(keyboardLayout, [event keyCode],
									 kUCKeyActionDown, ((event.modifierFlags) >> 8), LMGetKbdType(),
									 kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStrLen, &actualLength,
									 strBuff);
//	LOGI("...characterWithoutModifierKeysIncludingShift status=%d, actualLength=%d", status, actualLength);
	
	if (actualLength == 0)
		return 0;
	
	int character = strBuff[0];
	
	return character;
}

bool wasKeyDownShift = false;
bool wasKeyDownAlt = false;
bool wasKeyDownControl = false;

- (void) keyDown:(NSEvent *)event
{
	NSLog(@"keyDown");
	// https://stackoverflow.com/questions/3202629/where-can-i-find-a-list-of-mac-virtual-key-codes

	LOGI(">>>>> GLViewController: keyDown event, keyCode=%d", [event keyCode]);
	
	int keyCodeBare = [self characterWithoutModifierKeysIncludingShift:event];

	LOGI("                        keyDown keyCodeBare=%d (%x) %c", keyCodeBare, keyCodeBare, keyCodeBare);
	
	bool isShift = false;
	bool isAlt = false;
	bool isControl = false;
	
	if ([event modifierFlags] & NSShiftKeyMask)
	{
		isShift = true;
	}
	if ([event modifierFlags] & NSAlternateKeyMask)
	{
		isAlt = true;
    }
	if ([event modifierFlags] & NSCommandKeyMask)
	{
		isControl = true;
    }
	
	wasKeyDownShift = isShift;
	wasKeyDownAlt = isAlt;
	wasKeyDownControl = isControl;
	
	
	//  kVK_ANSI_Quote,  kVK_ANSI_LeftBracket
	unichar c = [event keyCode];
	
	u32 key = mapKey(c, keyCodeBare, isShift);
	if (key != 0)
	{
		LOGI("     ... mapped keydown=%d %04x %c", key, key, key);
		guiMain->KeyDown(key, isShift, isAlt, isControl);
		
		if (key == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
		{
			LOGM("QUIT.");
			SYS_ApplicationShutdown();
			gSoundEngine->StopAudioUnit();
			[self stopAnimation];
			//exit(0);
			//_Exit(0);
			_exit(0);
		}
	}
	else
	{
		LOGI("     ... not mapped keydown=%d (%04x) isShift=%d isAlt=%d isCtrl=%d", key, key, isShift, isAlt, isControl);
		// BUG: does not include shift! unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
		unichar keyCode = [[event charactersIgnoringModifiers] characterAtIndex:0];

		LOGI("          converted keydown keyCode=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d", keyCode, keyCode, keyCode, isShift, isAlt, isControl);

		if (keyCode == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
		{
			LOGM("QUIT.");
			SYS_ApplicationShutdown();
			gSoundEngine->StopAudioUnit();
			[self stopAnimation];
			//exit(0);
			//_Exit(0);
			_exit(0);
		}
		
		int keyCodeBare = [self characterWithoutModifierKeysIncludingShift:event];
		
//		keyCode = 33;
		
		LOGI("keyDown not mapped, keyCodeM=%d (%04x) [%c] keyCodeBare=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d",
			 keyCode, keyCode, keyCode, keyCodeBare, keyCodeBare, keyCodeBare, isShift, isAlt, isControl);
		guiMain->KeyDown(keyCode, isShift, isAlt, isControl);
	}
}

- (void) keyUp:(NSEvent *)event
{
	LOGI(">>>>> GLViewController: keyUp event, keyCode=%d", [event keyCode]);

	int keyCodeBare = [self characterWithoutModifierKeysIncludingShift:event];

	LOGI("                        keyUp keyCodeBare=%d (%x) %c", keyCodeBare, keyCodeBare, keyCodeBare);

	bool isShift = wasKeyDownShift;
	bool isAlt = wasKeyDownAlt;
	bool isControl = wasKeyDownControl;
	
//    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
	unichar c = [event keyCode];
	
	u32 key = mapKey(c, keyCodeBare, isShift);
	
	if (key != 0)
	{
		LOGI("     ... mapped keyup=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d", key, key, key, isShift, isAlt, isControl);
		guiMain->KeyUp(key, isShift, isAlt, isControl);
	}
	else
	{
		LOGI("     ... not mapped keyup=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d", key, key, key, isShift, isAlt, isControl);

		unichar keyCode = [[event charactersIgnoringModifiers] characterAtIndex:0];
		int keyCodeBare = [self characterWithoutModifierKeysIncludingShift:event];

		LOGI("          converted keyup keyCode=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d", keyCode, keyCode, keyCode, isShift, isAlt, isControl);

//		keyCode = 33;

		LOGI("keyUp not mapped, keyCodeM=%d (%04x) [%c] keyCodeBare=%d (%04x) [%c] isShift=%d isAlt=%d isCtrl=%d",
			 keyCode, keyCode, keyCode, keyCodeBare, keyCodeBare, keyCodeBare, isShift, isAlt, isControl);
		guiMain->KeyUp(keyCode, isShift, isAlt, isControl);
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	//LOGD("mouseDown");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	//NSPoint tvarMousePointInView   = [self convertPoint:tvarMousePointInWindow fromView:nil];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];
	
#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_TouchesBegan(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_TouchesBegan(backingPoint.x, backingPoint.y, false);
#endif
	
}

-(void)mouseDragged:(NSEvent *)theEvent
{
	LOGD("mouseDragged");
	NSPoint mousePointInWindow = [theEvent locationInWindow];

	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];

#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_TouchesMoved(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_TouchesMoved(backingPoint.x, backingPoint.y, false);
#endif
}

-(void)mouseUp:(NSEvent *)theEvent
{
	//LOGD("mouseUp");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];

#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_TouchesEnded(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_TouchesEnded(backingPoint.x, backingPoint.y, false);
#endif
}

//

- (void)rightMouseDown:(NSEvent *)theEvent
{
	//LOGD("rightMouseDown");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	//NSPoint tvarMousePointInView   = [self convertPoint:tvarMousePointInWindow fromView:nil];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];
	
#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_RightClickBegan(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_RightClickBegan(backingPoint.x, backingPoint.y, false);
#endif
}

-(void)rightMouseDragged:(NSEvent *)theEvent
{
	//LOGD("rightMouseDragged");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];

#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_RightClickMoved(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_RightClickMoved(backingPoint.x, backingPoint.y, false);
#endif

}

-(void)rightMouseUp:(NSEvent *)theEvent
{
	//LOGD("mouseUp");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];
	
#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_RightClickEnded(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_RightClickEnded(backingPoint.x, backingPoint.y, false);
#endif
}


//


-(void)mouseMoved:(NSEvent *)theEvent
{
//	LOGD("mouseMoved");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	
	NSPoint backingPoint = [self convertPointToBacking:mousePointInWindow];
	
	VID_NotTouchedMoved(backingPoint.x, backingPoint.y);
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
	//    [resultsField setStringValue:
	//	 [NSString stringWithFormat:@"Magnification value is %f", [event magnification]]];
	//    NSSize newSize;
	//    newSize.height = self.frame.size.height * ([event magnification] + 1.0);
	//    newSize.width = self.frame.size.width * ([event magnification] + 1.0);
	//    [self setFrameSize:newSize];
//	NSLog(@"magnify %f", [theEvent magnification]);
	
	VID_TouchesPinchZoom([theEvent magnification]);
}

- (void)scrollWheel:(NSEvent *)theEvent
{
//	NSLog(@"user scrolled %f horizontally and %f vertically", [theEvent deltaX], [theEvent deltaY]);

	float deltaX = [theEvent deltaX];
	float deltaY = [theEvent deltaY];
	VID_TouchesScrollWheel(deltaX, deltaY);
}

-(void)flagsChanged:(NSEvent*)event
{
	LOGI(">>>>>>>>>> flagsChanged");

	bool isShift = false;
	bool isAlt = false;
	bool isControl = false;
	
	int mtKey;
	
	if ([event modifierFlags] & NSShiftKeyMask)
	{
		isShift = true;
	}
	if ([event modifierFlags] & NSAlternateKeyMask)
	{
		isAlt = true;
	}
	if ([event modifierFlags] & NSCommandKeyMask)
	{
		isControl = true;
	}

	
	if ([event modifierFlags] & NSShiftKeyMask)
	{
		if (isShiftKeyDown == false)
		{
			isShiftKeyDown = true;
			if ([event keyCode] == 56)
			{
				LOGI("     flagsChanged: key down LSHIFT");
				guiMain->KeyDown(MTKEY_LSHIFT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 60)
			{
				LOGI("     flagsChanged: key down RSHIFT");
				guiMain->KeyDown(MTKEY_RSHIFT, isShift, isAlt, isControl);
			}
		}
	}
	else
	{
		if (isShiftKeyDown == true)
		{
			isShiftKeyDown = false;
			if ([event keyCode] == 56)
			{
				LOGI("     flagsChanged: key up LSHIFT");
				guiMain->KeyUp(MTKEY_LSHIFT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 60)
			{
				LOGI("     flagsChanged: key up RSHIFT");
				guiMain->KeyUp(MTKEY_RSHIFT, isShift, isAlt, isControl);
			}
		}
	}
	
	if ([event modifierFlags] & NSAlternateKeyMask)
	{
		if (isAltKeyDown == false)
		{
			isAltKeyDown = true;
			
			if ([event keyCode] == 58)
			{
				LOGI("     flagsChanged: key down LALT");
				guiMain->KeyDown(MTKEY_LALT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 61)
			{
				LOGI("     flagsChanged: key down RALT");
				guiMain->KeyDown(MTKEY_RALT, isShift, isAlt, isControl);
			}
		}
	}
	else
	{
		if (isAltKeyDown == true)
		{
			isAltKeyDown = false;
			if ([event keyCode] == 58)
			{
				LOGI("     flagsChanged: key up LALT");
				guiMain->KeyUp(MTKEY_LALT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 61)
			{
				LOGI("     flagsChanged: key up RALT");
				guiMain->KeyUp(MTKEY_RALT, isShift, isAlt, isControl);
			}
		}
	}
	
	if ([event modifierFlags] & NSCommandKeyMask)
	{
		if (isControlKeyDown == false)
		{
			isControlKeyDown = true;
			if ([event keyCode] == 55)
			{
				LOGI("     flagsChanged: key down LCTRL");
				guiMain->KeyDown(MTKEY_LCONTROL, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 54)
			{
				LOGI("     flagsChanged: key down RCTRL");
				guiMain->KeyDown(MTKEY_RCONTROL, isShift, isAlt, isControl);
			}
		}
	}
	else
	{
		if (isControlKeyDown == true)
		{
			isControlKeyDown = false;
			if ([event keyCode] == 55)
			{
				LOGI("     flagsChanged: key up LCTRL");
				guiMain->KeyUp(MTKEY_LCONTROL, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 54)
			{
				LOGI("     flagsChanged: key up RCTRL");
				guiMain->KeyUp(MTKEY_RCONTROL, isShift, isAlt, isControl);
			}
		}
	}

//	if ([event modifierFlags] & NSControlKeyMask)
//	{
//		if (isControlKeyDown == false)
//		{
//			isControlKeyDown = true;
//			guiMain->KeyDown(MTKEY_CONTROL, isShift, isAlt, isControl);
//		}
//	}
//	else
//	{
//		if (isControlKeyDown == true)
//		{
//			isControlKeyDown = false;
//			guiMain->KeyUp(MTKEY_CONTROL, isShift, isAlt, isControl);
//		}
//	}
	
//	switch ([event keyCode]) {
//		case 54: // Right Command
//		case 55: // Left Command
//			return ([event modifierFlags] & NSCommandKeyMask) == 0;
//
//		case 57: // Capslock
//			return ([event modifierFlags] & NSAlphaShiftKeyMask) == 0;
//
//		case 56: // Left Shift
//		case 60: // Right Shift
//			return ([event modifierFlags] & NSShiftKeyMask) == 0;
//
//		case 58: // Left Alt
//		case 61: // Right Alt
//			return ([event modifierFlags] & NSAlternateKeyMask) == 0;
//
//		case 59: // Left Ctrl
//		case 62: // Right Ctrl
//			return ([event modifierFlags] & NSControlKeyMask) == 0;
//
//		case 63: // Function
//			return ([event modifierFlags] & NSFunctionKeyMask) == 0;
}

// https://src.chromium.org/chrome/branches/official/build_166.0/src/webkit/glue/webinputevent_mac.mm
//static bool isKeypadEvent(NSEvent* event)
//{
//	// Check that this is the type of event that has a keyCode.
//	switch ([event type]) {
//		case NSKeyDown:
//		case NSKeyUp:
//		case NSFlagsChanged:
//			break;
//		default:
//			return false;
//	}
//
//	switch ([event keyCode]) {
//		case 71: // Clear
//		case 81: // =
//		case 75: // /
//		case 67: // *
//		case 78: // -
//		case 69: // +
//		case 76: // Enter
//		case 65: // .
//		case 82: // 0
//		case 83: // 1
//		case 84: // 2
//		case 85: // 3
//		case 86: // 4
//		case 87: // 5
//		case 88: // 6
//		case 89: // 7
//		case 91: // 8
//		case 92: // 9
//			return true;
//	}
//
//	return false;
//}




- (void) startAnimation
{
	LOGD("startAnimation");
	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStart(displayLink);
}

- (void) stopAnimation
{
	LOGD("stopAnimation");
	if (displayLink && CVDisplayLinkIsRunning(displayLink))
		CVDisplayLinkStop(displayLink);
}

- (BOOL)preservesContentDuringLiveResize
{
	return NO;
}

- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop
{
	NSLog(@"setWindowAlwaysOnTop: %d", isAlwaysOnTop);
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
	NSWindow *mainWindow = [self window];
	NSRect frame = mainWindow.frame;
	
	[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(frame) forKey:@"MainWindowFrameKey"];
}

- (void)restoreMainWindowPosition
{
	NSWindow *mainWindow = [self window];
	
	NSString *winFrameString = [[NSUserDefaults standardUserDefaults] stringForKey:@"MainWindowFrameKey"];
	
	if (winFrameString != nil)
	{
		NSRect savedRect = NSRectFromString(winFrameString);
		if (CGRectContainsRect([NSScreen mainScreen].visibleFrame, savedRect))
		{
			if (savedRect.size.width > 10 && savedRect.size.height > 10)
			{
				[mainWindow setFrame:savedRect display:NO];
			}
		}
	}
}

// TODO: move me
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
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSViewGlobalFrameDidChangeNotification
												  object:self];
	[super dealloc];
}
@end


