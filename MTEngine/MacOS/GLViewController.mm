// MacOS multitouch:
// https://developer.apple.com/library/mac/documentation/cocoa/conceptual/eventoverview/HandlingTouchEvents/HandlingTouchEvents.html

// http://stackoverflow.com/questions/15604724/detect-multi-touch-gestures-or-drags-with-mouse-in-mac-os-x-app

#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <Foundation/Foundation.h>

#import "GLViewController.h"
#import "GLView.h"
#include "MenuControllerSettings.h"
#include "VID_GLViewController.h"
#include "SYS_KeyCodes.h"
#include "CGuiMain.h"
#include "SYS_PauseResume.h"
#include "SND_SoundEngine.h"
#include "SYS_Defs.h"

@implementation GLViewController

- (IBAction) goFullScreen:(id)sender
{
	LOGM("goFullScreen");
	isInFullScreenMode = YES;
	
	// Pause the non-fullscreen view
	[openGLView stopAnimation];
	
	// Mac OS X 10.6 and later offer a simplified mechanism to create full-screen contexts
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
	
	NSRect mainDisplayRect, viewRect;
	
	// Create a screen-sized window on the display you want to take over
	// Note, mainDisplayRect has a non-zero origin if the key window is on a secondary display
	mainDisplayRect = [[NSScreen mainScreen] frame];
	fullScreenWindow = [[NSWindow alloc] initWithContentRect:mainDisplayRect styleMask:NSBorderlessWindowMask 
													 backing:NSBackingStoreBuffered defer:YES];
	
	// Set the window level to be above the menu bar
	[fullScreenWindow setLevel:NSMainMenuWindowLevel+1];
	
	// Perform any other window configuration you desire
	[fullScreenWindow setOpaque:YES];
	[fullScreenWindow setHidesOnDeactivate:YES];
	
	// Create a view with a double-buffered OpenGL context and attach it to the window
	// By specifying the non-fullscreen context as the shareContext, we automatically inherit the OpenGL objects (textures, etc) it has defined
	viewRect = NSMakeRect(0.0, 0.0, mainDisplayRect.size.width, mainDisplayRect.size.height);
	fullScreenView = [[GLView alloc] initWithFrame:viewRect shareContext:[openGLView openGLContext]];
	[fullScreenWindow setContentView:fullScreenView];
	
	// Show the window
	[fullScreenWindow makeKeyAndOrderFront:self];
	
	// Set the scene with the full-screen viewport and viewing transformation
	[scene setViewportRect:viewRect];
	
	// Assign the view's MainController to self
	[fullScreenView setMainController:self];
	
	if (!isAnimating) {
		// Mark the view as needing drawing to initalize its contents
		[fullScreenView setNeedsDisplay:YES];
	}
	else {
		// Start playing the animation
		[fullScreenView startAnimation];
	}
	
#else
	// Mac OS X 10.5 and eariler require additional work to capture the display and set up a special context
	// This demo uses CGL for full-screen rendering on pre-10.6 systems. You may also use NSOpenGL to achieve this.
	
	CGLPixelFormatObj pixelFormatObj;
	GLint numPixelFormats;
	
	// Capture the main display
	CGDisplayCapture(kCGDirectMainDisplay);
	
	// Set up an array of attributes
	CGLPixelFormatAttribute attribs[] = {
		
		// The full-screen attribute
		kCGLPFAFullScreen,
		
		// The display mask associated with the captured display
		// We may be on a multi-display system (and each screen may be driven by a different renderer),
		// so we need to specify which screen we want to take over. For this demo, we'll specify the main screen.
		kCGLPFADisplayMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
		
		// Attributes common to full-screen and non-fullscreen
		kCGLPFAAccelerated,
		kCGLPFANoRecovery,
		kCGLPFADoubleBuffer,
		kCGLPFAColorSize, 24,
//		kCGLPFADepthSize, 16,
		kCGLPFAMultisample,
		kCGLPFASampleBuffers, 1,
		kCGLPFASamples, 4,
        0
    };
	
	
	// Create the full-screen context with the attributes listed above
	// By specifying the non-fullscreen context as the shareContext, we automatically inherit the OpenGL objects (textures, etc) it has defined
	CGLChoosePixelFormat(attribs, &pixelFormatObj, &numPixelFormats);
	CGLCreateContext(pixelFormatObj, [[openGLView openGLContext] CGLContextObj], &fullScreenContextObj);
	CGLDestroyPixelFormat(pixelFormatObj);
	
	if (!fullScreenContextObj) {
        NSLog(@"Failed to create full-screen context");
		CGReleaseAllDisplays();
		[self goWindow];
        return;
    }
	
	// Set the current context to the one to use for full-screen drawing
	CGLSetCurrentContext(fullScreenContextObj);
	
	// Attach a full-screen drawable object to the current context
	CGLSetFullScreen(fullScreenContextObj);
	
    // Lock us to the display's refresh rate
    GLint newSwapInterval = 1;
    CGLSetParameter(fullScreenContextObj, kCGLCPSwapInterval, &newSwapInterval);
	
	// Tell the scene the dimensions of the area it's going to render to, so it can set up an appropriate viewport and viewing transformation
    [scene setViewportRect:NSMakeRect(0, 0, CGDisplayPixelsWide(kCGDirectMainDisplay), CGDisplayPixelsHigh(kCGDirectMainDisplay))];
	
	// Perform the application's main loop until exiting full-screen
	// The shift here is from a model in which we passively receive events handed to us by the AppKit (in window mode)
	// to one in which we are actively driving event processing (in full-screen mode)
	while (isInFullScreenMode)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		// Check for and process input events
        NSEvent *event;
        while (event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES])
		{
            switch ([event type])
			{
                case NSLeftMouseDown:
                    [self mouseDown:event];
                    break;
					
                case NSLeftMouseUp:
                    [self mouseUp:event];
                    break;
					
                case NSLeftMouseDragged:
                    [self mouseDragged:event];
                    break;
					
                case NSKeyDown:
                    [self keyDown:event];
                    break;
					
                default:
                    break;
            }
        }
		
		// Update our animation
//        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//        if (isAnimating) {
//            [scene advanceTimeBy:(currentTime - renderTime)];
//        }
//        renderTime = currentTime;
		
		// Delegate to the scene object for rendering
		[scene render];
		CGLFlushDrawable(fullScreenContextObj);
		
		[pool release];
	}
	
#endif
}

- (void) goWindow
{
	LOGM("goWindow");
	isInFullScreenMode = NO;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
	
	// Release the screen-sized window and view
	[fullScreenWindow release];
	[fullScreenView release];
	
#else
	
	// Set the current context to NULL
	CGLSetCurrentContext(NULL);
	// Clear the drawable object
	CGLClearDrawable(fullScreenContextObj);
	// Destroy the rendering context
	CGLDestroyContext(fullScreenContextObj);
	// Release the displays
	CGReleaseAllDisplays();
	
#endif
	
	// Switch to the non-fullscreen context
	[[openGLView openGLContext] makeCurrentContext];
	
	if (!isAnimating) {
		// Mark the view as needing drawing
		// The animation has advanced while we were in full-screen mode, so its current contents are stale
		[openGLView setNeedsDisplay:YES];
	}
	else {
		// Continue playing the animation
		[openGLView startAnimation];
	}
	
	[scene setViewportRect:[openGLView bounds]];
}

- (void) windowDidLoad
{
	// NOTE this is not called as we do not have window that is loaded
	LOGD("windowDidLoad");
}

- (void) awakeFromNib
{
	[NSApp setDelegate: self];

	// TODO: auto
	//guard let data = UserDefaults.standard.data(forKey: key),
	//let frame = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSRect else {
	//	return
	// }
//	window?.setFrame(frame, display: true)
	
	isAltKeyDown = false;
	isShiftKeyDown = false;
	isControlKeyDown = false;
	
	// Allocate the scene object
	scene = [[Scene alloc] init];
	
	// Assign the view's MainController to self
	[openGLView setMainController:self];
	
	[openGLView initGL];
	
	// Activate the display link now
	[openGLView startAnimation];
	isAnimating = YES;

	NSWindow *mainWindow = [openGLView window];
	
	[mainWindow setAcceptsMouseMovedEvents:YES];
	[mainWindow setDelegate:self];
	
	[self restoreMainWindowPosition];

	SYS_UpdateMenuItems();
}

- (void)storeMainWindowPosition
{
	NSWindow *mainWindow = [openGLView window];
	NSRect frame = mainWindow.frame;
	
	[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(frame) forKey:@"MainWindowFrameKey"];
}

- (void)restoreMainWindowPosition
{	
	NSWindow *mainWindow = [openGLView window];
	
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

- (void)windowDidBecomeKey:(NSNotification *)notification
{
//#if defined(FINAL_RELEASE)
//	LOGM("windowDidBecomeKey");
//	[self startAnimation];
//	SYS_ApplicationResumed();
//	VID_ResetLogicClock();
//#endif
	
	SYS_ApplicationEnteredForeground();
}

- (void)windowDidResignKey:(NSNotification *)notification
{
//#if defined(FINAL_RELEASE)
//	LOGM("windowDidResignKey");
//	[self stopAnimation];
//	SYS_ApplicationPaused();
//#endif
	
	SYS_ApplicationEnteredBackground();

}

- (void)windowWillClose:(NSNotification *)notification
{
	LOGM("windowWillClose");
	
	// TODO: auto
//	guard let frame = window?.frame else {
//		return
//	}
//	
//	let data = NSKeyedArchiver.archivedData(withRootObject: frame)
//	UserDefaults.standard.set(data, forKey: key)
	
	SYS_ApplicationShutdown();
}

- (bool)isWindowFullScreen
{
	NSWindow *mainWindow = [openGLView window];

	NSUInteger masks = [mainWindow styleMask];
	if ( masks & NSFullScreenWindowMask)
	{
		return true;
	}
	
	return false;
}

- (void) dealloc
{
	[scene release];
	[super dealloc];
}

- (Scene*) scene
{
	return scene;
}

- (CFAbsoluteTime) renderTime
{
	return renderTime;
}

- (void) setRenderTime:(CFAbsoluteTime)time
{
	renderTime = time;
}

- (void) startAnimation
{
	if (!isAnimating)
	{
		if (!isInFullScreenMode)
			[openGLView startAnimation];
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
		else
			[fullScreenView startAnimation];
#endif
		isAnimating = YES;
	}
}

- (void) stopAnimation
{
	if (isAnimating)
	{
		if (!isInFullScreenMode)
			[openGLView stopAnimation];
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
		else
			[fullScreenView stopAnimation];
#endif
		isAnimating = NO;
	}
}

- (void) toggleAnimation
{
	if (isAnimating)
		[self stopAnimation];
	else
		[self startAnimation];
}

- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop
{
	[openGLView setWindowAlwaysOnTop:isAlwaysOnTop];
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
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif
	
#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_TouchesBegan(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_TouchesBegan(backingPoint.x, backingPoint.y, false);
#endif
	
}

-(void)mouseDragged:(NSEvent *)theEvent
{
	//LOGD("mouseDragged");
	NSPoint mousePointInWindow = [theEvent locationInWindow];

#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif

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
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif

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
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif
	
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
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif

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
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif
	
#if defined(EMULATE_ZOOM_WITH_ALT)
	VID_RightClickEnded(backingPoint.x, backingPoint.y, isAltKeyDown);
#else
	VID_RightClickEnded(backingPoint.x, backingPoint.y, false);
#endif
}


//


-(void)mouseMoved:(NSEvent *)theEvent
{
	//LOGD("mouseMoved");
	NSPoint mousePointInWindow = [theEvent locationInWindow];
	
#if defined(MACOS_SUPPORT_RETINA)
	NSPoint backingPoint = [openGLView convertPointToBacking:mousePointInWindow];
#else
	NSPoint backingPoint = mousePointInWindow;
#endif
	
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


-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

//- (void)windowWillClose:(NSNotification *)notification
//{
//	
//}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	//NSLog(@"openFile");
	return MACOS_OpenFile(filename);
}

- (void)application:(NSApplication *)sender
		  openFiles:(NSArray *) filenames
{
	//NSLog(@"openFiles");
	NSString *strPath = [filenames objectAtIndex:0];
	
	MACOS_OpenFile(strPath);
	
}

@end

