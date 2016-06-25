// MacOS multitouch:
// https://developer.apple.com/library/mac/documentation/cocoa/conceptual/eventoverview/HandlingTouchEvents/HandlingTouchEvents.html

// http://stackoverflow.com/questions/15604724/detect-multi-touch-gestures-or-drags-with-mouse-in-mac-os-x-app

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

- (void) awakeFromNib
{
	[NSApp setDelegate: self];
	
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

	SYS_UpdateMenuItems();
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

u32 mapKey(int c)
{
	LOGI("mapKey c=%d (%4.4x)", c, c);
	
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

- (void) keyDown:(NSEvent *)event
{
	LOGI("GLViewController: keyDown event");
	
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
	
    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
    switch (c)
	{
			
#if !defined(FINAL_RELEASE)
		// [Esc] exits full-screen mode
        case 27:
			if (isInFullScreenMode)
			{
				[self goWindow];
			}
			else
			{
				LOGM("ESC pressed. QUIT.");
				gSoundEngine->StopAudioUnit();
				[self stopAnimation];
				//exit(0);
				//_Exit(0);
				_exit(0);
			}
			return;
#endif
			
		case 13:
			if (isAlt)
			{
				if (isInFullScreenMode)
				{
					[self goWindow];
				}
				else
				{
					[self goFullScreen:self];
				}
				return;
			}
			break;
		// [space] toggles rotation of the globe
//        case 32:
//            [self toggleAnimation];
//            break;
//			
//		// [W] toggles wireframe rendering
//        case 'w':
//        case 'W':
//            [scene toggleWireframe];
//            break;
		default:
			break;
    }
	
	c = [event keyCode];
	
	u32 key = mapKey(c);
	if (key != 0)
	{
		guiMain->KeyDown(key, isShift, isAlt, isControl);
		
		if (key == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
		{
			LOGM("QUIT.");
			gSoundEngine->StopAudioUnit();
			[self stopAnimation];
			//exit(0);
			//_Exit(0);
			_exit(0);
		}
	}
	else
	{
		unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];

		if (c == quitKeyCode && isShift == quitIsShift && isAlt == quitIsAlt && isControl == quitIsControl)
		{
			LOGM("QUIT.");
			gSoundEngine->StopAudioUnit();
			[self stopAnimation];
			//exit(0);
			//_Exit(0);
			_exit(0);
		}

		guiMain->KeyDown(c, isShift, isAlt, isControl);
	}
}

- (void) keyUp:(NSEvent *)event
{
	bool isShift = false;
	bool isAlt = false;
	bool isControl = false;
	
//    unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
	unichar c = [event keyCode];
	u32 key = mapKey(c);
	if (key != 0)
	{
		guiMain->KeyUp(key, isShift, isAlt, isControl);
	}
	else
	{
		unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];
		guiMain->KeyUp(c, isShift, isAlt, isControl);
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
	
	VID_TouchesBegan(backingPoint.x, backingPoint.y, isAltKeyDown);
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

	VID_TouchesMoved(backingPoint.x, backingPoint.y, isAltKeyDown);
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

	VID_TouchesEnded(backingPoint.x, backingPoint.y, isAltKeyDown);
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
	
	VID_RightClickBegan(backingPoint.x, backingPoint.y, isAltKeyDown);
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
	
	VID_RightClickMoved(backingPoint.x, backingPoint.y, isAltKeyDown);
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
	
	VID_RightClickEnded(backingPoint.x, backingPoint.y, isAltKeyDown);
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
//	NSLog(@"flagsChanged: event=%@", event);

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
				guiMain->KeyDown(MTKEY_LSHIFT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 60)
			{
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
				guiMain->KeyUp(MTKEY_LSHIFT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 60)
			{
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
				guiMain->KeyDown(MTKEY_LALT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 61)
			{
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
				guiMain->KeyUp(MTKEY_LALT, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 61)
			{
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
				guiMain->KeyDown(MTKEY_LCONTROL, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 54)
			{
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
				guiMain->KeyUp(MTKEY_LCONTROL, isShift, isAlt, isControl);
			}
			else if ([event keyCode] == 54)
			{
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


@end

