#import "Scene.h"
#import <OpenGL/glu.h>
#include "VID_GLViewController.h"

static double dtor( double degrees )
{
    return degrees * M_PI / 180.0;
}

@implementation Scene

- (id) init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)advanceTimeBy:(float)seconds
{
}

- (void)initGL:(NSRect)bounds
{
	[[NSThread currentThread] setName:@"MAIN"];

	LOGM("Scene: initGL");
	int viewWidth = bounds.size.width;
	int viewHeight = bounds.size.height;
	VID_InitGL(viewWidth, viewHeight);
}


- (void)setViewportRect:(NSRect)bounds
{
	//LOGD("Scene:setViewportRect: %3.2f %3.2f", bounds.size.width, bounds.size.height);
	VID_UpdateViewPort(bounds.size.width, bounds.size.height);
}

- (void)render
{
	//LOGD("Scene:render");
	VID_DrawView();
}

@end
