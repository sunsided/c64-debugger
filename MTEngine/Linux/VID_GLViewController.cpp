//
//  GLViewController.m
//  LINUX
//
//  Created by Marcin Skoczylas on 09-11-22.
//  Copyright Marcin Skoczylas 2009. All rights reserved.
//

#include "VID_GLViewController.h"
#include "ConstantsAndMacros.h"
#include "DBG_Log.h"
#include <pthread.h>
#include "CGuiMain.h"
//#include "SYS_Main.h"	// for EXEC_ON_VALGRIND
#include "VID_ImageBinding.h"
#include <math.h>
#include <time.h>
#include <sys/time.h>
#include "SYS_CFileSystem.h"
#include "SYS_PlatformGuiSettings.h"
#include "CContinuousParamSin.h"
#include "CContinuousParamBezier.h"
#include "MTH_FastMath.h"
#include "RES_ResourceManager.h"
#include "SYS_PauseResume.h"
#include "SYS_Accelerometer.h"

byte gPlatformType = PLATFORM_TYPE_DESKTOP;

//#define SHOW_CURRENT_FPS
#define COUNT_CURRENT_FPS

GLfloat SCREEN_WIDTH = 0.0f;
GLfloat SCREEN_HEIGHT = 0.0f;
GLfloat SCREEN_SCALE = 2.0f; //DEFAULT_SCREEN_SCALE;
GLfloat SCREEN_ASPECT_RATIO = 1.0f;

static long dt = (long)((float)1000.0 / (float)FRAMES_PER_SECOND);

void VID_SetFPS(float fps)
{
	LOGTODO("VID_SetFPS: %3.2f", fps);
	dt = (long)((float)1000.0 / (float)fps);
}

void VID_SetOrthoDefault();

GLfloat VID_GetScreenWidth()
{
	return SCREEN_WIDTH;
}

GLfloat VID_GetScreenHeight()
{
	return SCREEN_HEIGHT;
}

bool gScaleDownImages = false;

//#define LOG_BLITS

static float shrink = 0.00;
volatile bool pressConsumed = false;
volatile bool moving = false;
volatile bool zooming = false;
volatile int zoomingPosX;
volatile int zoomingPosY;

float initialZoomDistance;
long firstTouchTime;
long lastTouchTime;
GLfloat moveInitialPosX;
GLfloat moveInitialPosY;
GLfloat movePreviousPosX;
GLfloat movePreviousPosY;

const float halfScreenX = ((float)SCREEN_WIDTH/2.0f);
const float halfScreenY = ((float)SCREEN_HEIGHT/2.0f);

#if defined(LOAD_AND_BLIT_ZOOM_SIGN)
CSlrImage *imgZoomSign;
#endif

pthread_mutex_t gRenderMutex;

#ifdef SHOW_CURRENT_FPS
#define COUNT_CURRENT_FPS
#endif

float CURRENT_FPS = 0.0f;

#ifdef SHOW_CURRENT_FPS
static char bufFPS[32];
#endif

long GetTickCount()
{
	timeval ts;
	gettimeofday(&ts,0);
	return (long)(ts.tv_sec * 1000 + (ts.tv_usec / 1000));
}

void SYS_LockRenderMutex()
{
	pthread_mutex_lock(&gRenderMutex);
}

void SYS_UnlockRenderMutex()
{
	pthread_mutex_unlock(&gRenderMutex);
}

long SYS_RandomSeed()
{
	return GetTickCount();
}

long SYS_GetCurrentTimeInMillis()
{
	return GetTickCount();
}

static volatile bool resetLogicClock;

void VID_ResetLogicClock()
{
	LOGD("VID_ResetLogicClock()");
	resetLogicClock = true;
}

bool VID_isAlwaysOnTop = false;

void X11SetAlwaysOnTop(bool isAlwaysOnTop);
void X11SetFullScreen(bool isFullScreen);
bool X11IsFullScreen();
void X11HideCursor(bool shouldHide);

void VID_SetWindowAlwaysOnTop(bool isAlwaysOnTop)
{
	VID_isAlwaysOnTop = isAlwaysOnTop;
	X11SetAlwaysOnTop(isAlwaysOnTop);
}

// do not store value
void VID_SetWindowAlwaysOnTopTemporary(bool isAlwaysOnTop)
{
	X11SetAlwaysOnTop(isAlwaysOnTop);
}

bool VID_IsWindowAlwaysOnTop()
{
	return VID_isAlwaysOnTop;
}

bool VID_IsWindowFullScreen()
{
	return X11IsFullScreen();
}

void SYS_SetFullScreen(bool isFullScreen);

void VID_SetWindowFullScreen(bool isFullScreen)
{
    SYS_SetFullScreen(isFullScreen);
}

void VID_HideMouseCursor()
{
	X11HideCursor(true);
}

void VID_ShowMouseCursor()
{
	X11HideCursor(false);
}

void VID_ApplicationPreloadingFinished()
{
}

void VID_RequestBannerAd()
{
}

void VID_ShowBannerAd(byte bannerPosition)
{

}

void VID_HideBannerAd()
{
}

void VID_LoadFullScreenAd()
{
}

bool VID_IsFullScreenAdAvailable()
{
        return false;
}

void VID_PresentFullScreenAd()
{
}

void VID_CloseFullScreenAd()
{
}

void SysTextFieldEditFinishedCallback::SysTextFieldEditFinished(UTFString *str)
{
}

void GUI_SetSysTextFieldEditFinishedCallback(SysTextFieldEditFinishedCallback *callback)
{
	//gAppView->textFieldEdidFinishedCallback = callback;
}

void GUI_ShowSysTextField(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY, UTFString *text)
{
	LOGD("GUI_ShowSysTextField");
//	[gAppView showSysTextField:text];
	LOGD("GUI_ShowSysTextField finished");
}

void GUI_HideSysTextField()
{
	LOGD("GUI_HideSysTextField");
//	[gAppView hideSysTextField];
	LOGD("GUI_HideSysTextField finished");
}

void GUI_ShowVirtualKeyboard()
{
	LOGTODO("GUI_ShowVirtualKeyboard");
}

void GUI_HideVirtualKeyboard()
{
	LOGTODO("GUI_HideVirtualKeyboard");
}

void GUI_ShowAcknowledgements()
{
	LOGTODO("GUI_HideVirtualKeyboard");
}

void VID_SetViewKeyboardOffset(float offsetY)
{
	LOGTODO("VID_SetViewKeyboardOffset");
}

static GLfloat vertices[] = {
	-1.0,  1.0, -3.0,
	1.0,  1.0, -3.0,
	-1.0, -1.0, -3.0,
	1.0, -1.0, -3.0
};

static Vector3D normals[] = {
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0}
};

static GLfloat texCoords[] = {
	0.0, 1.0,
	1.0, 1.0,
	0.0, 0.0,
	1.0, 0.0
};

static GLfloat colors[] = {
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0
};

static GLfloat vertsColors[] = {
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0
};

static GLfloat colorsOne[] = {
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0,
        1.0,  1.0, 1.0, 1.0
};


//#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>

long lastFrameTime, currentFrameTime;
u64 gCurrentFrameTime = 0;
double fps;
struct timeval frameTime;
int timePerFrame = 1000/15;
long currentGameTime;

#define kFontName					@"Arial"
#define kFontSize					24

void VID_SetOrthoDefault()
{
#ifdef ORIENTATION_LANDSCAPE
	glOrtho(SCREEN_WIDTH,
			 0,
			 SCREEN_HEIGHT,
			 0,
			 -5.0, 5.0);
#else
	glOrtho(0,
			 SCREEN_WIDTH,
			 SCREEN_HEIGHT,
			 0,
			 -5.0, 5.0);
#endif

}

void VID_SetOrtho(GLfloat xMin, GLfloat xMax, GLfloat yMin, GLfloat yMax,
				  GLfloat zMin, GLfloat zMax)
{
    glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(xMin, xMax, yMin, yMax, zMin, zMax);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

void VID_SethOrthoScreen()
{
#ifdef ORIENTATION_LANDSCAPE
	VID_SetOrtho(SCREEN_WIDTH,
			 0,
			 SCREEN_HEIGHT,
			 0,
			 -5.0, 5.0);
#else
	VID_SetOrtho(0,
			 SCREEN_WIDTH,
			 SCREEN_HEIGHT,
			 0,
			 -5.0, 5.0);
#endif
}

void VID_SetOrthoSwitchBack()
{
    //glEnable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

void VID_InitServerMode()
{
	gIsServerMode = true;
	pthread_mutex_init(&gRenderMutex, NULL);

	SYS_InitPlatformSettings();
	SYS_InitApplicationPauseResume();
	SYS_InitAccelerometer();

	LOGM("init file system");
	SYS_InitFileSystem();

    RES_Init(SCREEN_WIDTH*SCREEN_SCALE);

    SCREEN_ASPECT_RATIO = SCREEN_WIDTH / SCREEN_HEIGHT;

    guiMain = new CGuiMain();
    guiMain->Startup();

	lastFrameTime = GetTickCount();
	currentFrameTime = GetTickCount();
	currentGameTime = GetTickCount();

}

/*
void VID_UpdateViewPort(float newWidth, float newHeight)
{
	LOGD("VID_UpdateViewPort: %f %f", newWidth, newHeight);
	
	updateViewPort = true;
	
//	 SCREEN_SCALE = (float)newWidth / (float)SCREEN_WIDTH;
//	 //LOGD("new SCREEN_SCALE=%f", SCREEN_SCALE);
//	 newWidth = (unsigned int)(SCREEN_WIDTH * SCREEN_SCALE);
//	 newHeight = (unsigned int)(SCREEN_HEIGHT * SCREEN_SCALE);
//	 glViewport(0, 0, newWidth, newHeight);
	
	double vW = (double) newWidth;
	double vH = (double) newHeight;
	double A = (double) SCREEN_WIDTH / (double) SCREEN_HEIGHT; //SCREEN_WIDTH / (float)SCREEN_HEIGHT;
	double vA = (vW / vH);
	
	LOGD("vW=%f vH=%f A=%f vA=%f", vW, vH, A, vA);
	
	if (A > vA)
	{
		LOGD("glViewport A > vA");
		VIEW_START_X = 0;
		VIEW_START_Y = (vH * 0.5) - ((vW / A) * 0.5);
		SCREEN_SCALE = vW / SCREEN_WIDTH;
		
		LOGD("glViewPort: %d %d %d %d", (GLint)VIEW_START_X, (GLint)VIEW_START_Y, (GLsizei)vW, (GLsizei)(vW/A));
		
		viewPortStartX = (GLint)VIEW_START_X;
		viewPortStartY = (GLint)VIEW_START_Y;
		viewPortSizeX = (GLsizei)vW;
		viewPortSizeY = (GLsizei)(vW / A);
	}
	else
	{
		if (A < vA)
		{
			LOGD("glViewport A < vA");
			VIEW_START_X = (vW * 0.5) - ((vH * A) * 0.5);
			VIEW_START_Y = 0;
			SCREEN_SCALE = vH / SCREEN_HEIGHT;
			
			LOGD("glViewPort: %d %d %d %d", (GLint)VIEW_START_X, (GLint)VIEW_START_Y, (GLsizei)(vH * A), (GLsizei)vH);
			
			viewPortStartX = (GLint)VIEW_START_X;
			viewPortStartY = (GLint)VIEW_START_Y;
			viewPortSizeX = (GLsizei)(vH * A);
			viewPortSizeY = (GLsizei)vH;
		}
		else
		{
			LOGD("glViewport equal");
			SCREEN_SCALE = vH / SCREEN_HEIGHT;
			
			// equal aspect ratios
			viewPortStartX = 0;
			viewPortStartY = 0;
			viewPortSizeX = (GLsizei)vW;
			viewPortSizeY = (GLsizei)vH;
		}
	}
	
	if (guiMain != NULL)
		guiMain->NotifyGlobalOSWindowChangedCallbacks();
	
	LOGD("VID_UpdateViewPort: done");
}
*/

void VID_InitGL()
{
	LOGM("initGL");

	pthread_mutex_init(&gRenderMutex, NULL);

	SYS_InitPlatformSettings();
	SYS_InitApplicationPauseResume();
	SYS_InitAccelerometer();

	LOGM("init file system");
	SYS_InitFileSystem();

    RES_Init(SCREEN_WIDTH*SCREEN_SCALE);

	pressConsumed = false;
	moving = false;

	initialZoomDistance = -1;

	#ifdef SHOW_CURRENT_FPS
	sprintf(bufFPS, "0.000");
#endif

	glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);

	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
	//glEnable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);

	/*
	 const GLfloat zNear = 0.01, zFar = 1000.0, fieldOfView = 45.0;
	 GLfloat size;
	 //glEnable(GL_DEPTH_TEST);

	 size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0);

	 glFrustumf(size,
	 -size,
	 size / (rect.size.width / rect.size.height),
	 -size / (rect.size.width / rect.size.height),
	 zNear, zFar);
	 */

	int width = SCREEN_WIDTH;
	int height = SCREEN_HEIGHT;

#ifdef ORIENTATION_LANDSCAPE
	glOrtho(width,		//glOrthof
			 0,
			 height,
			 0,
			 -5.0, 5.0);
#else
	glOrtho(0,
			 width,
			 height,
			 0,
			 -5.0, 5.0);
#endif

	SCREEN_ASPECT_RATIO = SCREEN_WIDTH / SCREEN_HEIGHT;
	LOGM("screen aspect: %3.3f", SCREEN_ASPECT_RATIO);

	/*	glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size /
	 (rect.size.width / rect.size.height), zNear, zFar);

	 */
	//	 ORIG
	glViewport(0, 0, SCREEN_WIDTH*SCREEN_SCALE, SCREEN_HEIGHT*SCREEN_SCALE);
    glMatrixMode(GL_MODELVIEW);

	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
//	glDisable(GL_COLOR_MATERIAL);
    //glBlendFunc(GL_ONE, GL_SRC_COLOR);


	/*
	 // Enable lighting
	 glEnable(GL_LIGHTING);

	 // Turn the first light on
	 glEnable(GL_LIGHT0);

	 // Define the ambient component of the first light
	 const GLfloat light0Ambient[] = {0.1, 0.1, 0.1, 1.0};
	 glLightfv(GL_LIGHT0, GL_AMBIENT, light0Ambient);

	 // Define the diffuse component of the first light
	 const GLfloat light0Diffuse[] = {0.7, 0.7, 0.7, 1.0};
	 glLightfv(GL_LIGHT0, GL_DIFFUSE, light0Diffuse);

	 // Define the specular component and shininess of the first light
	 const GLfloat light0Specular[] = {0.7, 0.7, 0.7, 1.0};
	 const GLfloat light0Shininess = 0.4;
	 glLightfv(GL_LIGHT0, GL_SPECULAR, light0Specular);


	 // Define the position of the first light
	 const GLfloat light0Position[] = {0.0, 10.0, 10.0, 0.0};
	 glLightfv(GL_LIGHT0, GL_POSITION, light0Position);

	 // Define a direction vector for the light, this one points right down the Z axis
	 const GLfloat light0Direction[] = {0.0, 0.0, -1.0};
	 glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0Direction);

	 // Define a cutoff angle. This defines a 90Â¬â field of vision, since the cutoff
	 // is number of degrees to each side of an imaginary line drawn from the light's
	 // position along the vector supplied in GL_SPOT_DIRECTION above
	 glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 45.0);
	 */


    glLoadIdentity();
	//    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glColorPointer(3, GL_FLOAT, 0, colors);

#ifdef USE_THREADED_IMAGES_LOADING
	VID_InitImageBindings();
#endif

#if defined(LOAD_AND_BLIT_ZOOM_SIGN)
	imgZoomSign = new CSlrImage("/Engine/zoom-sign", false);
#endif

	guiMain = new CGuiMain();
	guiMain->Startup();

	/*
	 UITextField *username =[[UITextField alloc] initWithFrame:CGRectMake(24.5, 65, 270, 30)];
	 username.delegate=self;
	 username.textAlignment=UITextAlignmentCenter;
	 username.borderstyle=UITextBorderstyleRoundedRect;
	 username.placeholder=@"Username\n";
	 username.autocorrectionType=UITextAutocorrectionTypeNo;
	 username.autocapitalizationType=UITextAutocapitalizationTypeNone;
	 [self.view addSubview:username];
	 */

//	currentFrameTime = CACurrentMediaTime();

	lastFrameTime = GetTickCount();
	currentFrameTime = GetTickCount();
	currentGameTime = GetTickCount();


	LOGM("setup view finished");

}


void GUI_SetPressConsumed(bool consumed)
{
	pressConsumed = consumed;
}

void VID_TouchesBegan(int xPos, int yPos, bool alt)
{
	LOGI("VID_TouchesBegan: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

	SYS_LockRenderMutex();
	firstTouchTime = GetTickCount();

	pressConsumed = false;

	if (alt == false)
	{
		// single tap
		moveInitialPosX = xPos;
		moveInitialPosY = yPos;
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;

#ifdef ORIENTATION_LANDSCAPE
		if (!guiMain->DoTap(yPos, VIEW_HEIGHT-xPos))
		{
		}
#else

		guiMain->DoSystemMultiTap(0, xPos, yPos);
		guiMain->DoTap(xPos, yPos);
#endif

		moving = false;
		zooming = false;

		// TODO: double tap
	}
	else
	{
		// zooming
		initialZoomDistance = sqrt((xPos - halfScreenX)*(xPos - halfScreenX) + (yPos - halfScreenY)*(yPos - halfScreenY));

		moveInitialPosX = xPos;
		moveInitialPosY = yPos;

		zoomingPosX = xPos;
		zoomingPosY = yPos;

		guiMain->InitZoom();
		zooming = true;
	}

	SYS_UnlockRenderMutex();
}

void VID_TouchesMoved(int xPos, int yPos, bool alt)
{
	LOGI("VID_TouchesMoved: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

	SYS_LockRenderMutex();
	lastTouchTime = GetTickCount();

	moving = true;

	if (alt == false)
	{
#ifdef ORIENTATION_LANDSCAPE
		guiMain->DoMove(yPos, VIEW_HEIGHT-xPos,
					yPos - moveInitialPosY, -(xPos - moveInitialPosX),
					yPos - movePreviousPosY, -(xPos - movePreviousPosX));
#else

		guiMain->DoSystemMultiMove(0, xPos, yPos);

		guiMain->DoMove(xPos, yPos,
					xPos - moveInitialPosX, yPos - moveInitialPosY,
					xPos - movePreviousPosX, yPos - movePreviousPosY);


#endif
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;
		zooming = false;
		initialZoomDistance = -1;
	}
	else
	{
		if (initialZoomDistance == -1)
		{
			// zooming
			initialZoomDistance = sqrt((xPos - halfScreenX)*(xPos - halfScreenX) + (yPos - halfScreenY)*(yPos - halfScreenY));

			moveInitialPosX = xPos;
			moveInitialPosY = yPos;

			zoomingPosX = xPos;
			zoomingPosY = yPos;

			guiMain->InitZoom();
			zooming = true;
		}
		else
		{
			float finalDistance = sqrt((xPos - halfScreenX)*(xPos - halfScreenX) + (yPos - halfScreenY)*(yPos - halfScreenY));

			zoomingPosX = xPos;
			zoomingPosY = yPos;

			if(initialZoomDistance > finalDistance)
			{
				guiMain->DoZoomBy(moveInitialPosX, moveInitialPosY, finalDistance - initialZoomDistance, 0.0f);
				//	NSLog(@"Zoom Out");
			}
			else
			{
				guiMain->DoZoomBy(moveInitialPosX, moveInitialPosY, finalDistance - initialZoomDistance, 0.0f);
				//	NSLog(@"Zoom In");
			}
		}
	}

	SYS_UnlockRenderMutex();
}

void VID_TouchesEnded(int xPos, int yPos, bool alt)
{
	LOGI("VID_TouchesEnded: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

	SYS_LockRenderMutex();

	if (alt == false)
	{
		if (moving)
		{
			float totalTime;
			float distanceX, distanceY;
			float accelerationX, accelerationY;

			totalTime = lastTouchTime - firstTouchTime;
			totalTime /= 1000.0f;
			LOGI("totalTime=%f", totalTime);

			distanceX = (moveInitialPosX - movePreviousPosX);	//abs
			distanceY = (moveInitialPosY - movePreviousPosY);	//abs

			LOGG("distanceX=%f", distanceX);
			LOGG("distanceY=%f", distanceY);

			accelerationX = (distanceX / (.5 * (totalTime*totalTime)));
			accelerationY = (distanceY / (.5 * (totalTime*totalTime)));

			LOGG("==========================================ACCELERATIONX=%f", accelerationX);
			LOGG("==========================================ACCELERATIONY=%f", accelerationY);

#ifdef ORIENTATION_LANDSCAPE
			guiMain->FinishMove(movePreviousPos.y, VIEW_HEIGHT-movePreviousPos.x,
							movePreviousPos.y - moveInitialPos.y, -(movePreviousPos.x - moveInitialPos.x),
							-accelerationY, accelerationX);
#else

			guiMain->DoSystemMultiFinishTap(0, movePreviousPosX, movePreviousPosY);

			guiMain->FinishMove(movePreviousPosX, movePreviousPosY,
							movePreviousPosX - moveInitialPosX, movePreviousPosY - moveInitialPosY,
							accelerationX, -accelerationY);
#endif
			moving = false;
		}
		else if (pressConsumed == false)
		{
#ifdef ORIENTATION_LANDSCAPE
			if (!guiMain->DoFinishTap(yPos, VIEW_HEIGHT-xPos))
			{
				LOGG("touchesEnded single tap not consumed");
			}
#else
			guiMain->DoSystemMultiFinishTap(0, movePreviousPosX, movePreviousPosY);

			if (!guiMain->DoFinishTap(xPos, yPos))
			{
				LOGI("touchesEnded single tap not consumed");
			}
#endif
		}
		else
		{
			guiMain->DoSystemMultiFinishTap(0, movePreviousPosX, movePreviousPosY);
		}

		guiMain->FinishTouches();

		zooming = false;
		initialZoomDistance = -1;
		pressConsumed = false;
	}
	else
	{
		zooming = false;
		initialZoomDistance = -1;
	}

	SYS_UnlockRenderMutex();
}

void VID_TouchesScrollWheel(float deltaX, float deltaY)
{
	LOGI("VID_TouchesScrollWheel: %f %f", deltaX, deltaY);
	guiMain->DoScrollWheel(deltaX, deltaY);
}

void VID_NotTouchedMoved(int xPos, int yPos)
{
	LOGI("VID_NotTouchedMoved: %d %d", xPos, yPos);

	SYS_LockRenderMutex();

		guiMain->DoNotTouchedMove(xPos, yPos);

	SYS_UnlockRenderMutex();
}

//
void VID_RightClickBegan(int xPos, int yPos)
{
	LOGI("VID_RightClickBegan: %d %d", xPos, yPos);

	SYS_LockRenderMutex();
	firstTouchTime = GetTickCount();

	pressConsumed = false;

		// single tap
		moveInitialPosX = xPos;
		moveInitialPosY = yPos;
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;

		guiMain->DoRightClick(xPos, yPos);

		moving = false;
		zooming = false;


	SYS_UnlockRenderMutex();
}

void VID_RightClickMoved(int xPos, int yPos)
{
	LOGI("VID_RightClickMoved: %d %d", xPos, yPos);

	SYS_LockRenderMutex();
	lastTouchTime = GetTickCount();

	moving = true;

		guiMain->DoRightClickMove(xPos, yPos,
					xPos - moveInitialPosX, yPos - moveInitialPosY,
					xPos - movePreviousPosX, yPos - movePreviousPosY);

		movePreviousPosX = xPos;
		movePreviousPosY = yPos;
		zooming = false;
		initialZoomDistance = -1;


	SYS_UnlockRenderMutex();
}

void VID_RightClickEnded(int xPos, int yPos)
{
	LOGI("VID_RightClickEnded: %d %d", xPos, yPos);

	SYS_LockRenderMutex();

		if (moving)
		{
			float totalTime;
			float distanceX, distanceY;
			float accelerationX, accelerationY;

			totalTime = lastTouchTime - firstTouchTime;
			totalTime /= 1000.0f;
			LOGI("totalTime=%f", totalTime);

			distanceX = (moveInitialPosX - movePreviousPosX);	//abs
			distanceY = (moveInitialPosY - movePreviousPosY);	//abs

			LOGG("distanceX=%f", distanceX);
			LOGG("distanceY=%f", distanceY);

			accelerationX = (distanceX / (.5 * (totalTime*totalTime)));
			accelerationY = (distanceY / (.5 * (totalTime*totalTime)));

			LOGG("==========================================ACCELERATIONX=%f", accelerationX);
			LOGG("==========================================ACCELERATIONY=%f", accelerationY);

			guiMain->FinishRightClickMove(movePreviousPosX, movePreviousPosY,
							movePreviousPosX - moveInitialPosX, movePreviousPosY - moveInitialPosY,
							accelerationX, -accelerationY);
			moving = false;
		}
		else if (pressConsumed == false)
		{
			if (!guiMain->DoFinishRightClick(xPos, yPos))
			{
				LOGI("touchesEnded right click tap not consumed");
			}
		}
		else
		{
			guiMain->DoSystemMultiFinishTap(0, movePreviousPosX, movePreviousPosY);
		}

		guiMain->FinishTouches();

		zooming = false;
		initialZoomDistance = -1;
		pressConsumed = false;

	SYS_UnlockRenderMutex();
}


//


void VID_DrawView()
{
#ifdef USE_THREADED_IMAGES_LOADING
	VID_BindImages();
#endif

	gCurrentFrameTime = SYS_GetCurrentTimeInMillis();

	SYS_LockRenderMutex();

	//	LOGG("drawView");
    glColor4f(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    //glEnable(GL_MULTISAMPLE);//
    //glEnable(GL_SAMPLE_ALPHA_TO_COVERAGE);
    //glEnable(GL_MULTISAMPLE_ARB);

    //glEnable(GL_POLYGON_SMOOTH);

	glLoadIdentity();

	guiMain->Render();

    //glDisable(GL_MULTISAMPLE_ARB);


#ifdef SHOW_CURRENT_FPS
	guiMain->fntConsole->BlitText(bufFPS, 0.0, 0.0, 0.0, 11.0);
#endif

#if defined(LOAD_AND_BLIT_ZOOM_SIGN)

	if (zooming)
	{
		/*
		// LOCAL WAY - dobre, ale jak zrobic zoomout?
		BlitAlpha(imgZoomSign, zoomingPosX-13.5f, zoomingPosY-13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);

		float secX, secY;
		if (zoomingPosX < moveInitialPosX)
		{
			float distX = moveInitialPosX - zoomingPosX;
			secX = moveInitialPosX + distX;
		}
		else
		{
			float distX = moveInitialPosX - halfScreenX;
			secX = moveInitialPosX - distX;
		}

		if (zoomingPosY < moveInitialPosY)
		{
			float distY = moveInitialPosY - zoomingPosY;
			secY = moveInitialPosY + distY;
		}
		else
		{
			float distY = zoomingPosY - moveInitialPosY;
			secY = moveInitialPosY - distY;
		}

		BlitAlpha(imgZoomSign, secX-13.5f, secY-13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);
		*/

		// APPLE WAY
		BlitAlpha(imgZoomSign, zoomingPosX-13.5f, zoomingPosY-13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);

		float secX, secY;
		if (zoomingPosX < halfScreenX)
		{
			float distX = halfScreenX - zoomingPosX;
			secX = halfScreenX + distX;
		}
		else
		{
			float distX = zoomingPosX - halfScreenX;
			secX = halfScreenX - distX;
		}

		if (zoomingPosY < halfScreenY)
		{
			float distY = halfScreenY - zoomingPosY;
			secY = halfScreenY + distY;
		}
		else
		{
			float distY = zoomingPosY - halfScreenY;
			secY = halfScreenY - distY;
		}

		BlitAlpha(imgZoomSign, secX-13.5f, secY-13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);
	}
#endif

	glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

	SYS_UnlockRenderMutex();
	VID_DoLogic();
}

void VID_DoLogic()
{
	currentFrameTime = GetTickCount();
	long frameTimeDiff = (currentFrameTime - lastFrameTime);

#ifdef COUNT_CURRENT_FPS
	CURRENT_FPS = (float)1000.0f / (float)frameTimeDiff;
#endif

#ifdef SHOW_CURRENT_FPS
	sprintf(bufFPS, "%3.1f", CURRENT_FPS);
	//LOGD("fps=%s", bufFPS);
#endif

	int numLoops = 0;

//	LOGD("I currentFrameTime=%ld lastFrameTime=%ld frameTimeDiff=%ld dt=%ld",
//			currentFrameTime, lastFrameTime, frameTimeDiff, dt);

	static long tta = 0;
	static u32 cnt = 0;

	if ((currentFrameTime - lastFrameTime) > dt)
	{
//		LOGD("II  currentFrameTime=%ld lastFrameTime=%ld frameTimeDiff=%ld dt=%ld",
//				currentFrameTime, lastFrameTime, frameTimeDiff, dt);

		while((currentFrameTime - lastFrameTime) > dt && numLoops < 30)	//1000
		{
//			LOGD("III  currentFrameTime=%ld lastFrameTime=%ld frameTimeDiff=%ld dt=%ld numLoops=%d",
//					currentFrameTime, lastFrameTime, frameTimeDiff, dt, numLoops);

			if (resetLogicClock)
			{
				resetLogicClock = false;
				//lastFrameTime = currentFrameTime;
				break;
			}

	//		long t1 = GetTickCount();
			guiMain->DoLogic();
	//		cnt++;
	//		long tt = GetTickCount() - t1;

	//		tta = (tta + tt) / 2;

			lastFrameTime += dt;
			numLoops++;
		}

		lastFrameTime = currentFrameTime;
	}

//	if (cnt > 100)
//	{
//		LOGD("avg logic=%d", tta);
//		cnt = 0;
//	}

//	LOGD("IV  currentFrameTime=%ld lastFrameTime=%ld frameTimeDiff=%ld dt=%ld numLoops=%d",
//			currentFrameTime, lastFrameTime, frameTimeDiff, dt, numLoops);

}

//CGuiMain *guiMain = NULL;
GLuint      texture[1];

void SetClipping(GLfloat x, GLfloat y, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("SetClipping: x=%f y=%f sizeX=%f sizeY=%f SCREEN_WIDTH=%f SCREEN_HEIGHT=%f SCREEN_SCALE=%f", x ,y, sizeX, sizeY, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_SCALE);
	glEnable(GL_SCISSOR_TEST);

#ifdef ORIENTATION_LANDSCAPE
	glScissor((SCREEN_HEIGHT-y-sizeY), (SCREEN_WIDTH-x-sizeX), sizeY, sizeX);
#else

	GLint wx = (GLint)(x*SCREEN_SCALE);
	GLint wy = (GLint)(SCREEN_HEIGHT-y-sizeY)*SCREEN_SCALE;
	GLint wsx = (GLint)(sizeX*SCREEN_SCALE);
	GLint wsy = (GLint)(sizeY*SCREEN_SCALE);

	//LOGD("             wx=%d wy=%d wsx=%d wsy=%d", wx, wy, wsx, wsy);

	glScissor(wx, wy, wsx, wsy);
#endif
}

void ResetClipping()
{
	glDisable(GL_SCISSOR_TEST);
	//glScissor(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
}

void GUI_GetRealScreenPixelSizes(double *pixelSizeX, double *pixelSizeY)
{
	LOGD("GUI_GetRealScreenPixelSizes");
	
	LOGD("  SCREEN_WIDTH=%f SCREEN_HEIGHT=%f  |  SCREEN_SCALE=%f",
		 SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_SCALE);
//	LOGD("  viewPortSizeX=%d viewPortSizeY=%d |  viewPortStartX=%d viewPortStartY=%d",
//		 viewPortSizeX, viewPortSizeY, viewPortStartX, viewPortStartY);
	
	LOGD("... calc pixel size");
	
	*pixelSizeX = (1.0f / SCREEN_SCALE); //(double)SCREEN_WIDTH / (double)viewPortSizeX;
	*pixelSizeY = (1.0f / SCREEN_SCALE); //(double)SCREEN_HEIGHT / (double)viewPortSizeY;
	
	LOGD("  pixelSizeX=%f pixelSizeY=%f", *pixelSizeX, *pixelSizeY);
	
	LOGD("GUI_GetRealScreenPixelSizes done");
}

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("BlitTexture");
#endif
	/*
	 texCoords[0] = texStartY;
	 texCoords[1] = texEndX;
	 texCoords[2] = texEndY;
	 texCoords[3] = texEndX;
	 texCoords[4] = texStartY;
	 texCoords[5] = texStartX;
	 texCoords[6] = texEndY;
	 texCoords[7] = texStartX;
	 */

	texCoords[0] = 0.0;
	texCoords[1] = 1.0;
	texCoords[2] = 1.0;
	texCoords[3] = 1.0;
	texCoords[4] = 0.0;
	texCoords[5] = 0.0;
	texCoords[6] = 1.0;
	texCoords[7] = 0.0;

#ifdef ORIENTATION_LANDSCAPE
	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, tex);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

#ifdef LOG_BLITS
	LOGG("BlitTexture done");
#endif
}

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				 GLfloat texStartX, GLfloat texStartY,
				 GLfloat texEndX, GLfloat texEndY,
				 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitTexture");
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, tex);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glColor4f(colorR, colorG, colorB, alpha);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

#ifdef LOG_BLITS
	LOGG("BlitTexture done");
#endif
}


void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z)
{
#ifdef LOG_BLITS
	LOGG("Blit: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
#endif
	/*
	 texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;
	 */
	vertices[0] = -1.0 + destY ;
	vertices[1] = 1.0 + destX ;
	vertices[2] = z;

	vertices[3] =  1.0 + destY ;
	vertices[4] =  1.0 + destX ;
	vertices[5] = z;

	vertices[6] = -1.0 + destY ;
	vertices[7] = -1.0 + destX ;
	vertices[8] = z;

	vertices[9] =  1.0 + destY ;
	vertices[10] = -1.0 + destX ;
	vertices[11] = z;

	/*
	 vertices[2] = z;
	 vertices[5] = z;
	 vertices[8] = z;
	 vertices[11] = z;
	 */

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);


	/*
	 int rect[4] = {0, 0, 256, 256};
	 glBindTexture(GL_TEXTURE_2D, what->texture[0]);
	 glTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_CROP_RECT_OES, rect);
	 //		glDrawTexiOES(int x, int y, int z, int width, int height)
	 glDrawTexiOES(destX, destY, z, 256, 256); //what->width, what->height);
	 */

#ifdef LOG_BLITS
	LOGG("Blit done: %s", what->name);
#endif

}

void BlitAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	sizeX -=1;
	sizeY -=1;
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexStartX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexStartX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexEndX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexEndX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else

	// plain exchange y
	texCoords[0] = what->defaultTexEndX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexStartX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexEndX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexStartX;
	texCoords[7] = 1.0f - what->defaultTexStartY;


	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


void BlitAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	sizeX -=1;
	sizeY -=1;
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else

	// plain exchange y
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = 1.0f - what->defaultTexStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);
}

void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB)
{
#ifdef LOG_BLITS
	LOGG("BlitMixColor: %s", what->name);
#endif

	/*
	if (alpha > 0.99)
	{
		Blit(what, destX, destY, z);
	}
	*/
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
#endif

	vertices[0] = -1.0 + destY ;
	vertices[1] = 1.0 + destX ;
	vertices[2] = z;

	vertices[3] =  1.0 + destY ;
	vertices[4] =  1.0 + destX ;
	vertices[5] = z;

	vertices[6] = -1.0 + destY ;
	vertices[7] = -1.0 + destX ;
	vertices[8] = z;

	vertices[9] =  1.0 + destY ;
	vertices[10] = -1.0 + destX ;
	vertices[11] = z;

	/*
	 vertices[2] = z;
	 vertices[5] = z;
	 vertices[8] = z;
	 vertices[11] = z;
	 */

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(mixColorR, mixColorG, mixColorB, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

	/*
	 int rect[4] = {0, 0, 256, 256};
	 glBindTexture(GL_TEXTURE_2D, what->texture[0]);
	 glTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_CROP_RECT_OES, rect);
	 //		glDrawTexiOES(int x, int y, int z, int width, int height)
	 glDrawTexiOES(destX, destY, z, 256, 256); //what->width, what->height);
	 */

#ifdef LOG_BLITS
	LOGG("BlitMixColor done: %s", what->name);
#endif

}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha: %s", what->name);
#endif

	/*
	if (alpha > 0.99)
	{
		Blit(what, destX, destY, z);
	}
	*/
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
#endif

	vertices[0] = -1.0 + destY ;
	vertices[1] = 1.0 + destX ;
	vertices[2] = z;

	vertices[3] =  1.0 + destY ;
	vertices[4] =  1.0 + destX ;
	vertices[5] = z;

	vertices[6] = -1.0 + destY ;
	vertices[7] = -1.0 + destX ;
	vertices[8] = z;

	vertices[9] =  1.0 + destY ;
	vertices[10] = -1.0 + destX ;
	vertices[11] = z;

	/*
	 vertices[2] = z;
	 vertices[5] = z;
	 vertices[8] = z;
	 vertices[11] = z;
	 */

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

	/*
	 int rect[4] = {0, 0, 256, 256};
	 glBindTexture(GL_TEXTURE_2D, what->texture[0]);
	 glTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_CROP_RECT_OES, rect);
	 //		glDrawTexiOES(int x, int y, int z, int width, int height)
	 glDrawTexiOES(destX, destY, z, 256, 256); //what->width, what->height);
	 */

#ifdef LOG_BLITS
	LOGG("BlitAlpha done: %s", what->name);
#endif

}


void BlitSize(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size)
{
#ifdef LOG_BLITS
	LOGG("BlitSize: %s", what->name);
#endif

	GLfloat sizeX = size;
	GLfloat sizeY = size;

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = 0.0;
	texCoords[1] = 1.0;
	texCoords[2] = 1.0;
	texCoords[3] = 1.0;
	texCoords[4] = 0.0;
	texCoords[5] = 0.0;
	texCoords[6] = 1.0;
	texCoords[7] = 0.0;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	texCoords[0] = 0.0;
	texCoords[1] = 0.0;
	texCoords[2] = 1.0;
	texCoords[3] = 0.0;
	texCoords[4] = 0.0;
	texCoords[5] = 1.0;
	texCoords[6] = 1.0;
	texCoords[7] = 1.0;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#ifdef LOG_BLITS
	LOGG("BlitSize done: %s", what->name);
#endif

}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("Blit: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#ifdef LOG_BLITS
	LOGG("Blit done: %s", what->name);
#endif


}

void BlitFlipVertical(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("Blit: x=%f y=%f sx=%f sy=%f", destX, destY, sizeX, sizeY);

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			; //;
	vertices[1]  =  sizeX + destX	; //;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	; //;
	vertices[4]  =  sizeX + destX	; //;
	vertices[5]  =	z;

	vertices[6]  =  destY			; //;
	vertices[7]  =  destX			; //;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	; //;
	vertices[10] =	destX			; //;
	vertices[11] =	z;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			; //;
	vertices[1]  =  destY	; //;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //;
	vertices[4]  =  destY	; //;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //;
	vertices[7]  =  sizeY + destY			; //;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //;
	vertices[10] =	sizeY + destY			; //;
	vertices[11] =	z;
#endif

	for (int i = 0; i < 12; i++)
	{
		//LOGD("vertices[%d] = %f", i, vertices[i]);
		//LOGD("  texCoords[%d] = %f", i, texCoords[i]);
	}

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

void BlitFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("Blit: x=%f y=%f sx=%f sy=%f", destX, destY, sizeX, sizeY);

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			; //;
	vertices[1]  =  sizeX + destX	; //;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	; //;
	vertices[4]  =  sizeX + destX	; //;
	vertices[5]  =	z;

	vertices[6]  =  destY			; //;
	vertices[7]  =  destX			; //;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	; //;
	vertices[10] =	destX			; //;
	vertices[11] =	z;
#else
	texCoords[0] = what->defaultTexEndX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexStartX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexEndX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexStartX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			; //;
	vertices[1]  =  destY	; //;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //;
	vertices[4]  =  destY	; //;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //;
	vertices[7]  =  sizeY + destY			; //;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //;
	vertices[10] =	sizeY + destY			; //;
	vertices[11] =	z;
#endif

	for (int i = 0; i < 12; i++)
	{
		//LOGD("vertices[%d] = %f", i, vertices[i]);
		//LOGD("  texCoords[%d] = %f", i, texCoords[i]);
	}

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

void BlitAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("BlitAtl: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	//this->defaultTexStartX = 0.000977f; //((GLfloat)atlStartX / (GLfloat)rasterWidth);
	//this->defaultTexEndX = 0.092773f; //((GLfloat)atlEndX / (GLfloat)rasterWidth);
	//this->defaultTexStartY = 1.0f - 0.092773f; //0.7f; //0.000977f; // ((GLfloat)atlStartY / (GLfloat)rasterHeight);
	//this->defaultTexEndY = 1.0f - 0.000977f; //((GLfloat)atlEndY / (GLfloat)rasterHeight);

	// plain exchange y
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = 1.0f - what->defaultTexStartY;
	/*
	 texCoords[0] = what->defaultTexStartX;
	 texCoords[1] = 1.0f - what->defaultTexStartY;
	 texCoords[2] = what->defaultTexEndX;
	 texCoords[3] = 1.0f - what->defaultTexStartY;
	 texCoords[4] = what->defaultTexStartX;
	 texCoords[5] = 1.0f - what->defaultTexEndY;
	 texCoords[6] = what->defaultTexEndX;
	 texCoords[7] = 1.0f - what->defaultTexEndY;
	 */

	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#ifdef LOG_BLITS
	LOGG("BlitAtl done: %s", what->name);
#endif

}

void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB)
{
#ifdef LOG_BLITS
	LOGG("BlitMixColor: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(mixColorR, mixColorG, mixColorB, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitMixColor done: %s", what->name);
#endif

}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexEndX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexEndX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexStartX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexStartX;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 1.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 1.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 0.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 0.0;*/

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitAlpha done: %s", what->name);
#endif

}

void BlitCheckAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	if (what->isFromAtlas)
	{
		BlitAtl(what, destX, destY, z, sizeX, sizeY);
	}
	else
	{
		Blit(what, destX, destY, z, sizeX, sizeY);
	}

}

void BlitCheckAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	if (what->isFromAtlas)
	{
		BlitAtlAlpha(what, destX, destY, z, sizeX, sizeY, alpha);
	}
	else
	{
		BlitAlpha(what, destX, destY, z, sizeX, sizeY, alpha);
	}

}

void BlitCheckAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	if (what->isFromAtlas)
	{
		BlitAtlFlipHorizontal(what, destX, destY, z, sizeX, sizeY);
	}
	else
	{
		SYS_FatalExit("not implemented");
		//..BlitFlipHorizontal(what, destX, destY, z, sizeX, sizeY, alpha);
	}

}


void BlitOLD(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	texCoords[0] = 0.0;
	texCoords[1] = 1.0;
	texCoords[2] = 1.0;
	texCoords[3] = 1.0;
	texCoords[4] = 0.0;
	texCoords[5] = 0.0;
	texCoords[6] = 1.0;
	texCoords[7] = 0.0;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY)
{
#ifdef LOG_BLITS
	LOGG("Blit: %s", what->name);
#endif

	GLfloat sizeX = size;
	GLfloat sizeY = size;

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#ifdef LOG_BLITS
	LOGG("Blit done: %s", what->name);
#endif

}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha: %s", what->name);
#endif

	GLfloat sizeX = size;
	GLfloat sizeY = size;

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

	glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitAlpha done: %s", what->name);
#endif

}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY)
{
#ifdef LOG_BLITS
	LOGG("Blit: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

#ifdef LOG_BLITS
	LOGG("Blit done: %s", what->name);
#endif

}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitAlpha done: %s", what->name);
#endif

}

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha_aaaa: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitAlpha_aaaa done: %s", what->name);
#endif

}

void BlitAlphaColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitAlpha: %s", what->name);
#endif

#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(colorR, colorG, colorB, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitAlpha done: %s", what->name);
#endif

}


void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitFilledRectangle: destX=%f destY=%f z=%f sizeX=%f sizeY=%f colorR=%f colorG=%f colorB=%f alpha=%f",
		destX, destY, z, sizeX, sizeY, colorR, colorG, colorB, alpha);
#endif

	//LOGD("define verts");
#ifdef ORIENTATION_LANDSCAPE
	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;
#else
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
#endif

	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	//LOGD("glColor4f");
	glColor4f(colorR, colorG, colorB, alpha);

	//LOGD("glVertexPointer");
    glVertexPointer(3, GL_FLOAT, 0, vertices);
	//LOGD("glNormalPointer");
//    glNormalPointer(GL_FLOAT, 0, normals);
//	glDisableClientState(GL_COLOR_ARRAY);

	//LOGD("glDrawArrays");
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	//LOGD("glEnable");
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);

	//LOGD("glColor4f");
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitFilledRectangle done");
#endif

}

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitRectangle");
#endif

	BlitLine(destX, destY, destX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY+sizeY, destX+sizeX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX+sizeX, destY, destX+sizeX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY, destX+sizeX, destY, z, colorR, colorG, colorB, alpha);

#ifdef LOG_BLITS
	LOGG("BlitRectangle done");
#endif

}

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
                                   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, GLfloat lineWidth)
{
        BlitFilledRectangle(destX, destY - lineWidth, z, sizeX, lineWidth, colorR, colorG, colorB, alpha);
        BlitFilledRectangle(destX, destY + sizeY, z, sizeX, lineWidth, colorR, colorG, colorB, alpha);

        BlitFilledRectangle(destX - lineWidth, destY - lineWidth, z, lineWidth, sizeY + lineWidth*2.0f, colorR, colorG, colorB, alpha);
        BlitFilledRectangle(destX + sizeX, destY - lineWidth, z, lineWidth, sizeY + lineWidth*2.0f, colorR, colorG, colorB, alpha);
}


void BlitGradientRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
                                                   GLfloat colorR1, GLfloat colorG1, GLfloat colorB1, GLfloat colorA1,
                                                   GLfloat colorR2, GLfloat colorG2, GLfloat colorB2, GLfloat colorA2,
                                                   GLfloat colorR3, GLfloat colorG3, GLfloat colorB3, GLfloat colorA3,
                                                   GLfloat colorR4, GLfloat colorG4, GLfloat colorB4, GLfloat colorA4)

{
        vertices[0]  =  destX                   ;
        vertices[1]  =  sizeY + destY   ;
        vertices[2]  =  z;

        vertices[3]  =  sizeX + destX   ;
        vertices[4]  =  sizeY + destY   ;
        vertices[5]  =  z;

        vertices[6]  =  destX                   ;
        vertices[7]  =  destY                   ;
        vertices[8]  =  z;

        vertices[9]  =  sizeX + destX   ;
        vertices[10] =  destY                   ;
        vertices[11] =  z;

        vertsColors[0]  = colorR1;
        vertsColors[1]  = colorG1;
        vertsColors[2]  = colorB1;
        vertsColors[3]  = colorA1;

        vertsColors[4]  = colorR2;
        vertsColors[5]  = colorG2;
        vertsColors[6]  = colorB2;
        vertsColors[7]  = colorA2;

        vertsColors[8]  = colorR3;
        vertsColors[9]  = colorG3;
        vertsColors[10] = colorB3;
        vertsColors[11] = colorA3;

        vertsColors[12] = colorR4;
        vertsColors[13] = colorG4;
        vertsColors[14] = colorB4;
        vertsColors[15] = colorA4;

        glDisable(GL_TEXTURE_2D);

    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
        glColorPointer(4, GL_FLOAT, 0, vertsColors);

        glEnableClientState(GL_COLOR_ARRAY);

        //glColor4f(1.0f, 0.5f, 1.0f, 1.0f);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glEnable(GL_TEXTURE_2D);

        glDisableClientState(GL_COLOR_ARRAY);
        //glColorPointer(3, GL_FLOAT, 0, colorsOne);
        //glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}


void VID_EnableSolidsOnly()
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

}

void VID_DisableSolidsOnly()
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
}

void VID_DisableTextures()
{
	glDisable(GL_TEXTURE_2D);
}

void VID_EnableTextures()
{
	glEnable(GL_TEXTURE_2D);
}

void BlitPolygonMixColor(CSlrImage *what, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#ifdef LOG_BLITS
        LOGG("BlitPolygonMixColor: %s", what->name);
#endif

        //      LOGD("========= BlitPolygonAlpha ========");
        //      for (u32 i = 0; i < 6; i++)
        //              LOGD("texCoords[%d]=%3.2f", i, texs[i]);
        //
        //      for (u32 i = 0; i < 9; i++)
        //              LOGD("vertices[%d]=%3.2f", i, verts[i]);
        //
        //      for (u32 i = 0; i < 9; i++)
        //              LOGD("normals[%d]=%3.2f", i, norms[i]);

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glNormalPointer(GL_FLOAT, 0, norms);
    glTexCoordPointer(2, GL_FLOAT, 0, texs);

        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        glColor4f(mixColorR, mixColorG, mixColorB, mixColorA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numVertices);
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

#ifdef LOG_BLITS
        LOGG("BlitPolygonMixColor done: %s", what->name);
#endif

}


void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitLine");
#endif

#ifdef ORIENTATION_LANDSCAPE
	vertices[0] = startY;
	vertices[1] = startX;
	vertices[2] = posZ;

	vertices[3] = endY;
	vertices[4] = endX;
	vertices[5] = posZ;
#else
	vertices[0] = startX;
	vertices[1] = startY;
	vertices[2] = posZ;

	vertices[3] = endX;
	vertices[4] = endY;
	vertices[5] = posZ;
#endif


	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glColor4f(colorR, colorG, colorB, alpha);

	glVertexPointer(3, GL_FLOAT,  0, vertices);

	//glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINE_STRIP, 0, 2);
	//glDisableClientState(GL_VERTEX_ARRAY);

	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);

	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitLine done");
#endif

}

void BlitCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA)
{
	const int numCircleVerts = 32;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = MTH_FastSin(angle)*radius;	//sinf
		glverts[i*2+1] = MTH_FastCos(angle)*radius;	//cosf
	}

	glPushMatrix();
	glTranslatef(centerX, centerY, 0);

    //edge lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);

	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);

	glPopMatrix();
}

void BlitFilledCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA)
{
	const int numCircleVerts = 32;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = MTH_FastSin(angle)*radius;	//sinf
		glverts[i*2+1] = MTH_FastCos(angle)*radius;	//cosf
	}

	glPushMatrix();
	glTranslatef(centerX, centerY, 0);

	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_TRIANGLE_FAN, 0, numCircleVerts);

    //edge lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);

	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);

	glPopMatrix();
}

void GenerateLineStripFromCircularBuffer(CGLLineStrip *lineStrip, signed short *data, int length, int pos, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = length / sizeX;

	GLfloat samplePos = pos;
	int c = 0;

	for (GLfloat x = 0; x <= sizeX; x += 1.0)
	{
#ifdef ORIENTATION_PLAIN
		lineStripData[c] = posX + x;
		c++;
		lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
		c++;
		lineStripData[c] = posZ;
		c++;
#else
		lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
		c++;
		lineStripData[c] = posX + x;
		c++;
		lineStripData[c] = posZ;
		c++;
#endif

		samplePos += step;
		if (samplePos >= length)
			samplePos = 0;

		if ((c+3) >= dataLen)
			break;
	}
	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer done");
#endif

	return;
}

void GenerateLineStripFromFft(CGLLineStrip *lineStrip, float *data, int start, int count, float multiplier, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	GLfloat endY = posY + sizeY;
	int c = 0;

	float maxVal = data[0];

	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
#ifdef ORIENTATION_PLAIN
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = (endY) - (maxVal*multiplier) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;
#else
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = (endY) - (maxVal*multiplier) * sizeY;
			c++;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posZ;
			c++;
#endif

			int prevSamplePos = (int)samplePos;
			samplePos += step;
			int nextSamplePos = (int)samplePos;

			if (prevSamplePos+1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int)samplePos];
					if (fabs(val) > fabs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft done");
#endif

	return;

}


void GenerateLineStripFromFloat(CGLLineStrip *lineStrip, float *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFloat");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	int c = 0;

	float maxVal = data[0];

	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
#ifdef ORIENTATION_PLAIN
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posY + (maxVal) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;
#else
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posY + (maxVal) * sizeY;
			c++;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posZ;
			c++;
#endif

			int prevSamplePos = (int)samplePos;
			samplePos += step;
			int nextSamplePos = (int)samplePos;

			if (prevSamplePos+1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int)samplePos];
					if (fabs(val) > fabs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFloat done");
#endif

	return;

}

#ifdef IS_TRACKER
void GenerateLineStripFromEnvelope(CGLLineStrip *lineStrip,
								   envelope_t *envelope,
								   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromEnvelope");
#endif

	int dataLen = (int)(envelope->numPoints * 3);
	lineStrip->Update(dataLen);

	GLfloat *lineStripData = lineStrip->lineStripData;

	//LOGG("GenerateLineStripFromEnvelope: envelope numPoints=%d", envelope->numPoints);

	/*
	 2010-03-10 11:53:57.813 MobiTracker[2740:207] point=0 x=0   y=64
	 2010-03-10 11:53:57.814 MobiTracker[2740:207] point=1 x=21  y=33
	 2010-03-10 11:53:57.814 MobiTracker[2740:207] point=2 x=118 y=64
	 2010-03-10 11:53:57.815 MobiTracker[2740:207] point=3 x=150 y=0
	 2010-03-10 11:53:57.815 MobiTracker[2740:207] point=4 x=243 y=35
	 2010-03-10 11:53:57.816 MobiTracker[2740:207] point=5 x=324 y=0
	 */

	// x = 0..324
	// y = 0..64
	int c = 0;
	for (int currentPoint = 0; currentPoint < envelope->numPoints; currentPoint++)
	{
		GLfloat x = envelope->points[currentPoint * 2];
		GLfloat y = envelope->points[currentPoint * 2 + 1];

		//LOGG("point=%d x=%f y=%f", currentPoint, x, y);

#ifdef ORIENTATION_PLAIN
		lineStripData[c] = posX + (x / 324.0) * sizeX;
		c++;
		lineStripData[c] = posY + ((64.0 - y)/64.0) * sizeY;
		c++;
		lineStripData[c] = posZ;
		c++;
#else
		lineStripData[c] = posY + ((64.0 - y)/64.0) * sizeY;
		c++;
		lineStripData[c] = posX + (x / 324.0) * sizeX;
		c++;
		lineStripData[c] = posZ;
		c++;
#endif

	}

	//SYS_FatalExit("exit");
	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromEnvelope done");
#endif

	return;

	//SYS_Errorf("generatelinestrip");
}
#endif


void GenerateLineStrip(CGLLineStrip *lineStrip,
					   signed short *data,
					   int start, int count,
					   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStrip");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	int c = 0;
	GLfloat end = (GLfloat)(start+count);
	signed short maxVal = data[0];

	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
#ifdef ORIENTATION_PLAIN
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posY + (((GLfloat)maxVal + 32767.0) / 65536.0) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;
#else
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posY + (((GLfloat)maxVal + 32767.0) / 65536.0) * sizeY;
			c++;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posZ;
			c++;
#endif

			int prevSamplePos = (int)samplePos;
			samplePos += step;
			int nextSamplePos = (int)samplePos;

			if (samplePos >= end)
				break;

			// debug -> simple:
			/* maxVal
			if (prevSamplePos+1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					signed short val = data[(int)samplePos];
					if (abs(val) > abs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else*/
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStrip done");
#endif


	return;

	/*
	 else
	 {
	 lineStrip[c] = (((GLfloat)data[(int)samplePos] + 128.0) / 256.0) * sizeY;
	 c++;
	 lineStrip[c] = 0.0;
	 c++;
	 lineStrip[c] = posZ;
	 c++;

	 samplePos += step;

	 GLfloat prevSamplePos = 0.0;

	 for (GLfloat x = 1.0; x < sizeX; x += 1.0)
	 {
	 unsigned char maxVal = 0;

	 for (int x2 = (int)prevSamplePos; x2 <= (int)samplePos; x2++)
	 {
	 unsigned char curVal = data[(int)x2];
	 if (abs(curVal) > abs(maxVal))
	 {
	 maxVal = curVal;
	 }
	 }

	 LOGG("maxVal=%d", maxVal);
	 lineStrip[c] = (((GLfloat)maxVal + 128.0) / 256.0) * sizeY;
	 c++;
	 lineStrip[c] = x;
	 c++;
	 lineStrip[c] = posZ;
	 c++;

	 prevSamplePos = samplePos;
	 samplePos += step;
	 }
	 }
	 lineStripData
	 */
}



void BlitLineStrip(CGLLineStrip *glLineStrip, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitLineStrip");
#endif

	glColor4f(colorR, colorG, colorB, alpha);

	glDisable(GL_TEXTURE_2D);
	glVertexPointer(3, GL_FLOAT,  0, glLineStrip->lineStripData);

	//glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINE_STRIP, 0, glLineStrip->length);
	//glDisableClientState(GL_VERTEX_ARRAY);

	glEnable(GL_TEXTURE_2D);

	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitLineStrip done");
#endif

}

#define CENTER_MARKER_SIZE 12.0

void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha)
{
		BlitLine(posX, posY-CENTER_MARKER_SIZE,
				posX, posY+CENTER_MARKER_SIZE, posZ,
				r, g, b, alpha);

		BlitLine(posX-CENTER_MARKER_SIZE, posY,
				posX+CENTER_MARKER_SIZE, posY, posZ,
				r, g, b, alpha);
}

void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha)
{
		BlitLine(posX, posY-sizeY/2,
				posX, posY+sizeY/2, posZ,
				r, g, b, alpha);

		BlitLine(posX-sizeX/2, posY,
				posX+sizeX/2, posY, posZ,
				r, g, b, alpha);
}

void PushMatrix2D()
{
	glPushMatrix();
}

void PopMatrix2D()
{
	glPopMatrix();
}

void Translate2D(GLfloat posX, GLfloat posY, GLfloat posZ)
{
	glTranslatef(posX, posY, posZ);
}

void Rotate2D(GLfloat angle)
{
	glRotatef( angle , 0, 0, 1 );	//* RADTODEG
}

void Scale2D(GLfloat scaleX, GLfloat scaleY, GLfloat scaleZ)
{
	glScalef(scaleX, scaleY, scaleZ);
}

void BlitRotatedImage(CSlrImage *image, GLfloat pX, GLfloat pY, GLfloat pZ, GLfloat rotationAngle, GLfloat alpha)
{
	GLfloat rPosX = pX;
	GLfloat rPosY = pY;
	GLfloat rPosZ = pZ;
	GLfloat rSizeX = image->width;
	GLfloat rSizeY = image->height;
	GLfloat rSizeX2 = rSizeX/2.0f;
	GLfloat rSizeY2 = rSizeY/2.0f;
	rPosX -= rSizeX2;
	rPosY -= rSizeY2;

	//LOGD("BLIT: %3.2f %3.2f %3.2f | %3.2f %3.2f", rPosX, rPosY, rPosZ, rSizeX, rSizeY);

	PushMatrix2D();

	Translate2D(rPosX + rSizeX2, rPosY + rSizeY2, rPosZ);
	Rotate2D(rotationAngle);

	BlitAlpha(image, -rSizeX2, -rSizeY2, 0, rSizeX, rSizeY, alpha);
	PopMatrix2D();
}

// TODO: screenshot
void VID_PrepareScreenshot(byte filterType)
{
	LOGTODO("VID_PrepareScreenshot");
}

void VID_SaveScreenshot()
{
	LOGTODO("VID_SaveScreenshot");
}

void VID_ShowScreenshot()
{
	LOGTODO("VID_ShowScreenshot");

}

void VID_HideScreenshot()
{
	LOGTODO("VID_HideScreenshot");

}

void VID_ShowActionSheet()
{
	LOGTODO("VID_ShowActionSheet");

}

void BlitTriangleAlpha(CSlrImage *what, GLfloat z, GLfloat alpha,
		GLfloat vert1x, GLfloat vert1y, GLfloat tex1x, GLfloat tex1y,
		GLfloat vert2x, GLfloat vert2y, GLfloat tex2x, GLfloat tex2y,
		GLfloat vert3x, GLfloat vert3y, GLfloat tex3x, GLfloat tex3y)
{
#ifdef LOG_BLITS
	LOGG("BlitTriangleAlpha: %s", what->name);
#endif

	GLfloat tx = (what->defaultTexEndX - what->defaultTexStartX);
	GLfloat ty = (what->defaultTexEndY - what->defaultTexStartY);

	GLfloat t1x = tx * tex1x + what->defaultTexStartX;
	GLfloat t1y = ty * (1.0f-tex1y) + what->defaultTexStartY;
	GLfloat t2x = tx * tex2x + what->defaultTexStartX;
	GLfloat t2y = ty * (1.0f-tex2y) + what->defaultTexStartY;
	GLfloat t3x = tx * tex3x + what->defaultTexStartX;
	GLfloat t3y = ty * (1.0f-tex3y) + what->defaultTexStartY;

	texCoords[0] = t1x;
	texCoords[1] = t1y;
	texCoords[2] = t2x;
	texCoords[3] = t2y;
	texCoords[4] = t3x;
	texCoords[5] = t3y;

	vertices[0]  =  vert1x;
	vertices[1]  =  vert1y;
	vertices[2]  =	z;

	vertices[3]  =  vert2x;
	vertices[4]  =  vert2y;
	vertices[5]  =	z;

	vertices[6]  =  vert3x;
	vertices[7]  =  vert3y;
	vertices[8]  =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
	glColor4f(1.0, 1.0, 1.0, 1.0);

#ifdef LOG_BLITS
	LOGG("BlitTriangleAlpha done: %s", what->name);
#endif

}

void BlitPolygonAlpha(CSlrImage *what, GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#ifdef LOG_BLITS
    LOGG("BlitPolygonAlpha: %s", what->name);
#endif

//  LOGD("========= BlitPolygonAlpha ========");
//  for (u32 i = 0; i < 6; i++)
//      LOGD("texCoords[%d]=%3.2f", i, texs[i]);
//
//  for (u32 i = 0; i < 9; i++)
//      LOGD("vertices[%d]=%3.2f", i, verts[i]);
//
//  for (u32 i = 0; i < 9; i++)
//      LOGD("normals[%d]=%3.2f", i, norms[i]);

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glNormalPointer(GL_FLOAT, 0, norms);
    glTexCoordPointer(2, GL_FLOAT, 0, texs);

    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numVertices);
    glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

#ifdef LOG_BLITS
    LOGG("BlitPolygonAlpha done: %s", what->name);
#endif

}

float VID_GetFingerRayLength()
{
    return 25.0f;
}

void VID_StoreMainWindowPosition()
{
    // TODO
}
