#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <StoreKit/StoreKit.h>

@class GLView;
@class Scene;

//@interface GLViewController : NSResponder <NSApplicationDelegate, NSWindowDelegate, NSFileManagerDelegate> 
@interface GLViewController : NSResponder <NSApplicationDelegate, NSWindowDelegate, NSFileManagerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver >
{

	BOOL isInFullScreenMode;
	
	// full-screen mode
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
	NSWindow *fullScreenWindow;
	GLView *fullScreenView;
#else
	CGLContextObj fullScreenContextObj;
#endif
	
	// window mode
	IBOutlet GLView *openGLView;
	
	Scene *scene;
	BOOL isAnimating;
	CFAbsoluteTime renderTime;
	
	bool isAltKeyDown;
	bool isShiftKeyDown;
	bool isControlKeyDown;
}

- (IBAction) goFullScreen:(id)sender;
- (void) goWindow;

- (Scene*) scene;

- (CFAbsoluteTime) renderTime;
- (void) setRenderTime:(CFAbsoluteTime)time;

- (void)setWindowAlwaysOnTop:(BOOL)isAlwaysOnTop;

//// payments
//- (void) startPayment;
//- (void) completeTransaction: (SKPaymentTransaction *)transaction;
//- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
//- (void) failedTransaction: (SKPaymentTransaction *)transaction;

@end
