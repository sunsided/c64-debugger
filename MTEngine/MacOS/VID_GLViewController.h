#ifndef _GLVIEWCONTROLLER_H_
#define _GLVIEWCONTROLLER_H_

#include "SYS_Defs.h"

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#include "VID_Blits.h"

extern GLfloat SCREEN_WIDTH;
extern GLfloat SCREEN_HEIGHT;
extern GLfloat SCREEN_SCALE;
extern GLfloat SCREEN_ASPECT_RATIO;

GLfloat VID_GetScreenWidth();
GLfloat VID_GetScreenHeight();

// for placing buttons in gui inside view
#define SCREEN_EDGE_HEIGHT 2.0
#define SCREEN_EDGE_WIDTH 2.0

extern float CURRENT_FPS;

extern unsigned int REAL_SCREEN_WIDTH;
extern unsigned int REAL_SCREEN_HEIGHT;

void SYS_LockRenderMutex();
void SYS_UnlockRenderMutex();

typedef struct {
	GLfloat x;
	GLfloat y;
	GLfloat z;
} Vertex3D;

typedef Vertex3D Vector3D;

class CSlrImage;
class CSlrUIMediaCallback;

extern bool gIsRetinaDisplay;

extern bool gScaleDownImages;
extern byte gPlatformType;
extern char *gPlatformDeviceString;
extern byte gIPhoneVersion;
extern bool gForceLinearScale;


extern u64 gCurrentFrameTime;

long SYS_RandomSeed();

class SysTextFieldEditFinishedCallback
{
public:
	virtual void SysTextFieldEditFinished(UTFString *str);
};

void VID_SetFPS(float fps);

void GUI_SetSysTextFieldEditFinishedCallback(SysTextFieldEditFinishedCallback *callback);
void GUI_ShowSysTextField(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY, char *text);
void GUI_HideSysTextField();
UTFString *GUI_GetSysTextFieldText();

void GUI_ShowAcknowledgements();
void GUI_ShowPhotoCredits();

void VID_SetViewKeyboardOffset(float offsetY);
void GUI_ShowVirtualKeyboard();
void GUI_HideVirtualKeyboard();

void VID_ApplicationPreloadingFinished();

float VID_GetFingerRayLength();


//void NET_SetConnectionFinishedCallback(ConnectionFinishedCallback *callback);

#define SCREENSHOT_FILTER_COLOR		1
#define SCREENSHOT_FILTER_SEPIA		2
#define SCREENSHOT_FILTER_GRAYSCALE	3

void VID_InitGL(float viewWidth, float viewHeight);
void VID_UpdateViewPort(float newWidth, float newHeight);
void VID_DrawView();
void VID_TouchesBegan(int x, int y, bool alt);
void VID_TouchesMoved(int x, int y, bool alt);
void VID_TouchesEnded(int x, int y, bool alt);

void VID_RightClickBegan(int x, int y, bool alt);
void VID_RightClickMoved(int x, int y, bool alt);
void VID_RightClickEnded(int x, int y, bool alt);

void VID_NotTouchedMoved(int x, int y);

void VID_TouchesPinchZoom(float magnifyDifference);
void VID_TouchesScrollWheel(float deltaX, float deltaY);

long SYS_GetCurrentTimeInMillis();
void VID_ResetLogicClock();

void VID_ShowActionSheet();

void VID_SetOrthoScreen();
void VID_SetOrtho(GLfloat xMin, GLfloat xMax, GLfloat yMin, GLfloat yMax,
				  GLfloat zMin, GLfloat zMax);
void VID_SetOrthoSwitchBack();

void SYS_ProcessAcceleration(float x, float y, float z);
void GUI_SetPressConsumed(bool consumed);

void SetClipping(GLint x, GLint y, GLsizei sizeX, GLsizei sizeY);
void ResetClipping();

class CSlrString;
class CByteBuffer;


#endif

