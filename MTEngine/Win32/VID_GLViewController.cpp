//
//  GLViewController.m
//  WIN32
//
//  Created by Marcin Skoczylas on 09-11-22.
//  Copyright Marcin Skoczylas 2009. All rights reserved.
//

#undef WIN32_LEAN_AND_MEAN
#undef WIN32_EXTRA_LEAN
#include <windows.h>

#include "VID_GLViewController.h"
#include "ConstantsAndMacros.h"
#include "DBG_LOG.h"
#include <pthread.h>
#include "CGuiMain.h"
//#include "SYS_Main.h"	// for EXEC_ON_VALGRIND
#include "VID_ImageBinding.h"
#include "SYS_CFileSystem.h"
#include "SYS_PlatformGuiSettings.h"
#include "CContinuousParamSin.h"
#include "RES_ResourceManager.h"
//#include "CContinuousParamBezier.h"
#include <math.h>
#include "MTH_FastMath.h"
#include "SYS_Accelerometer.h"
#include "SYS_PauseResume.h"

//#define LOG_BLITS

//byte gPlatformType = PLATFORM_TYPE_IPHONE;
byte gPlatformType = PLATFORM_TYPE_DESKTOP;

u64 gCurrentFrameTime = 0;
static long dt = (int) ((float) 1000.0 / (float) FRAMES_PER_SECOND);

void VID_SetFPS(float fps)
{
	LOGTODO("VID_SetFPS: %3.2f", fps);
	dt = (int) ((float) 1000.0 / (float) fps);
}

GLfloat SCREEN_WIDTH = 0.0f;
GLfloat SCREEN_HEIGHT = 0.0f;
GLfloat SCREEN_SCALE = DEFAULT_SCREEN_SCALE; //4:3 monitor sony: 2.23f;
GLfloat SCREEN_ASPECT_RATIO = 1.0f;

GLfloat VID_GetScreenWidth()
{
	return SCREEN_WIDTH;
}

GLfloat VID_GetScreenHeight()
{
	return SCREEN_HEIGHT;
}

float VIEW_START_X = 0.0;
float VIEW_START_Y = 0.0;

static float shrink = 0.00;
volatile bool pressConsumed = false;
volatile bool moving = false;
volatile bool zooming = false;
volatile int zoomingPosX;
volatile int zoomingPosY;

bool gScaleDownImages = false;

float initialZoomDistance;
long firstTouchTime;
long lastTouchTime;
GLfloat moveInitialPosX;
GLfloat moveInitialPosY;
GLfloat movePreviousPosX;
GLfloat movePreviousPosY;


const float halfScreenX = ((float) SCREEN_WIDTH / 2.0f);
const float halfScreenY = ((float) SCREEN_HEIGHT / 2.0f);

#if defined(LOAD_AND_BLIT_ZOOM_SIGN)
CSlrImage *imgZoomSign;
#endif

void VID_SetOrthoDefault();

pthread_mutex_t gRenderMutex;

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

void SysTextFieldEditFinishedCallback::SysTextFieldEditFinished(UTFString *str)
{
}

static GLfloat vertsColors[] = {
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0
};



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


void GUI_HideSysTextField()
{
	LOGD("GUI_HideSysTextField");
	//	[gAppView hideSysTextField];
	LOGD("GUI_HideSysTextField finished");
}

/*
 static float LEFT_OFFSET_X	= shrink +		-1.87;
 static float TOP_OFFSET_Y	= shrink +		-1.25;

 static float RIGHT_OFFSET_X = -shrink +		1.87;	//3.74;
 static float BOTTOM_OFFSET_Y = -shrink +	1.25;	//2.49;
 */

static float LEFT_OFFSET_X = shrink + 0.0;
static float TOP_OFFSET_Y = shrink + 0.0;

static float RIGHT_OFFSET_X = -shrink + 480.0;
static float BOTTOM_OFFSET_Y = -shrink + 320.0;

float VIEW_WIDTH = (RIGHT_OFFSET_X - LEFT_OFFSET_X);
float VIEW_HEIGHT = (BOTTOM_OFFSET_Y - TOP_OFFSET_Y);

static GLfloat vertices[] =
	{ -1.0, 1.0, -3.0, 1.0, 1.0, -3.0, -1.0, -1.0, -3.0, 1.0, -1.0, -3.0 };

static Vector3D normals[] =
	{
		{ 0.0, 0.0, 1.0 },
		{ 0.0, 0.0, 1.0 },
		{ 0.0, 0.0, 1.0 },
		{ 0.0, 0.0, 1.0 } };

static GLfloat texCoords[] =
	{ 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0 };

static GLfloat colors[] =
	{ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };

//#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>

long lastFrameTime, currentFrameTime;
double fps;
struct timeval frameTime;
int timePerFrame = 1000 / 15;
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
	glOrtho(0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, -5.0, 5.0);
#endif

}

void GUI_ShowVirtualKeyboard()
{
	//LOGTODO("GUI_ShowVirtualKeyboard");
}

void GUI_HideVirtualKeyboard()
{
	//LOGTODO("GUI_HideVirtualKeyboard");
}

void VID_SetOrtho(GLfloat xMin, GLfloat xMax, GLfloat yMin, GLfloat yMax, GLfloat zMin, GLfloat zMax)
{
	glDisable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	glOrtho(xMin, xMax, yMin, yMax, zMin, zMax);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
}

void VID_ShowActionSheet()
{
	LOGTODO("VID_ShowActionSheet()");
}

void VID_PrepareScreenshot(byte filterType)
{
	LOGTODO("VID_PrepareScreenshot()");
}

void VID_SaveScreenshot()
{
	LOGTODO("VID_SaveScreenshot()");
}

void VID_ShowScreenshot()
{
	LOGTODO("VID_ShowScreenshot()");
}

void VID_HideScreenshot()
{
	LOGTODO("VID_HideScreenshot()");
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
	VID_SetOrtho(0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, -5.0, 5.0);
#endif
}

void VID_SetOrthoSwitchBack()
{
	//glEnable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
}

void VID_UpdateViewPort(float newWidth, float newHeight)
{
	/*
	 SCREEN_SCALE = (float)newWidth / (float)SCREEN_WIDTH;
	 //LOGD("new SCREEN_SCALE=%f", SCREEN_SCALE);
	 newWidth = (unsigned int)(SCREEN_WIDTH * SCREEN_SCALE);
	 newHeight = (unsigned int)(SCREEN_HEIGHT * SCREEN_SCALE);
	 glViewport(0, 0, newWidth, newHeight);
	 */

	float vW = (float) newWidth;
	float vH = (float) newHeight;
	float A = (float) SCREEN_WIDTH / (float) SCREEN_HEIGHT; //SCREEN_WIDTH / (float)SCREEN_HEIGHT;
	float vA = (vW / vH);

	if (A > vA)
	{
		//LOGD("glViewport A > vA");
		VIEW_START_X = 0;
		VIEW_START_Y = (vH * 0.5) - ((vW / A) * 0.5);
		SCREEN_SCALE = vW / SCREEN_WIDTH;
		glViewport(VIEW_START_X, VIEW_START_Y, vW, vW / A);
	}
	else
	{
		if (A < vA)
		{
			//LOGD("glViewport A < vA");
			VIEW_START_X = (vW * 0.5) - ((vH * A) * 0.5);
			VIEW_START_Y = 0;
			SCREEN_SCALE = vH / SCREEN_HEIGHT;
			glViewport(VIEW_START_X, VIEW_START_Y, vH * A, vH);
		}
		else
		{
			//LOGD("glViewport equal");
			glViewport(0, 0, vW, vH); // equal aspect ratios
			SCREEN_SCALE = vH / SCREEN_HEIGHT;
		}
	}
}

void VID_InitGL()
{
	LOGM("initGL");

	pthread_mutex_init(&gRenderMutex, NULL);

	SYS_InitStrings();
	SYS_InitPlatformSettings();
	SYS_InitApplicationPauseResume();
	SYS_InitAccelerometer();

	LOGM("init file system");
	SYS_InitFileSystem();

	RES_Init(2048);

	//	gAppView = self;
	pressConsumed = false;
	moving = false;

	initialZoomDistance = -1;

	//NSString *text = @"http://www.modules.pl/tracker/get_authors.php?l=a";
	//	[gAppView initConnection:text];

	GLfloat posX = 20.0;
	GLfloat posY = 50.0;
	GLfloat sizeX = 380.0;
	GLfloat sizeY = 30.0;

	glDisable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);

	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
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
	glOrtho(width, //glOrthof
			0,
			height,
			0,
			-5.0, 5.0);
#else
	glOrtho(0, width, height, 0, -5.0, 5.0);
#endif

	SCREEN_ASPECT_RATIO = SCREEN_WIDTH / SCREEN_HEIGHT;
	LOGM("screen aspect: %3.3f", SCREEN_ASPECT_RATIO);

	/*	glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size /
	 (rect.size.width / rect.size.height), zNear, zFar);

	 */
	//	 ORIG
	glViewport(0, 0, SCREEN_WIDTH * SCREEN_SCALE, SCREEN_HEIGHT * SCREEN_SCALE);

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
#if !defined(WIN_32)
	imgZoomSign = new CSlrImage("/Engine/zoom-sign", false);
#else
		imgZoomSign = RES_GetImage("/Engine/zoom-sign", true, true); //false);
#endif
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
	//LOGD("VID_TouchesBegan: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

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
		if (!guiMain->DoTap(xPos, yPos))
		{
		}
#endif

		moving = false;
		zooming = false;


		// TODO: double tap
	}
	else
	{
		// zooming
		initialZoomDistance = sqrt((xPos - halfScreenX) * (xPos - halfScreenX) + (yPos - halfScreenY) * (yPos
				- halfScreenY));

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
	//LOGD("VID_TouchesMoved: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

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
		guiMain->DoMove(xPos, yPos, xPos - moveInitialPosX, yPos - moveInitialPosY, xPos - movePreviousPosX, yPos
				- movePreviousPosY);
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
			initialZoomDistance = sqrt((xPos - halfScreenX) * (xPos - halfScreenX) + (yPos - halfScreenY) * (yPos
					- halfScreenY));

			moveInitialPosX = xPos;
			moveInitialPosY = yPos;

			zoomingPosX = xPos;
			zoomingPosY = yPos;

			guiMain->InitZoom();
			zooming = true;
		}
		else
		{
			float finalDistance = sqrt((xPos - halfScreenX) * (xPos - halfScreenX) + (yPos - halfScreenY) * (yPos
					- halfScreenY));

			zoomingPosX = xPos;
			zoomingPosY = yPos;

			// TODO: calculate difference (now set as 0.0)
			if (initialZoomDistance > finalDistance)
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
	//LOGD("VID_TouchesEnded: %d %d %s", xPos, yPos, (alt ? "[alt]" : ""));

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
			LOGG("totalTime=%f", totalTime);

			distanceX = (moveInitialPosX - movePreviousPosX); //abs
			distanceY = (moveInitialPosY - movePreviousPosY); //abs

			LOGG("distanceX=%f", distanceX);
			LOGG("distanceY=%f", distanceY);

			accelerationX = (distanceX / (.5 * (totalTime * totalTime)));
			accelerationY = (distanceY / (.5 * (totalTime * totalTime)));

			LOGG("==========================================ACCELERATIONX=%f", accelerationX);
			LOGG("==========================================ACCELERATIONY=%f", accelerationY);

#ifdef ORIENTATION_LANDSCAPE
			guiMain->FinishMove(movePreviousPos.y, VIEW_HEIGHT-movePreviousPos.x,
					movePreviousPos.y - moveInitialPos.y, -(movePreviousPos.x - moveInitialPos.x),
					-accelerationY, accelerationX);
#else
			guiMain->FinishMove(movePreviousPosX, movePreviousPosY, movePreviousPosX - moveInitialPosX,
					movePreviousPosY - moveInitialPosY, accelerationX, -accelerationY);
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
			if (!guiMain->DoFinishTap(xPos, yPos))
			{
				LOGG("touchesEnded single tap not consumed");
			}
#endif
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

///

void VID_RightClickBegan(int xPos, int yPos)
{
	//LOGD("VID_RightClickBegan: %d %d", xPos, yPos);

	SYS_LockRenderMutex();
	firstTouchTime = GetTickCount();

	pressConsumed = false;

		// single tap
		moveInitialPosX = xPos;
		moveInitialPosY = yPos;
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;

#ifdef ORIENTATION_LANDSCAPE
		if (!guiMain->DoRightClick(yPos, VIEW_HEIGHT-xPos))
		{
		}
#else
		if (!guiMain->DoRightClick(xPos, yPos))
		{
		}
#endif

		moving = false;
		zooming = false;


		// TODO: double tap

	SYS_UnlockRenderMutex();
}

void VID_RightClickMoved(int xPos, int yPos)
{
	//LOGD("VID_RightClickMoved: %d %d", xPos, yPos);

	SYS_LockRenderMutex();
	lastTouchTime = GetTickCount();

	moving = true;

#ifdef ORIENTATION_LANDSCAPE
		guiMain->DoRightClickMove(yPos, VIEW_HEIGHT-xPos,
				yPos - moveInitialPosY, -(xPos - moveInitialPosX),
				yPos - movePreviousPosY, -(xPos - movePreviousPosX));
#else
		guiMain->DoRightClickMove(xPos, yPos, xPos - moveInitialPosX, yPos - moveInitialPosY, xPos - movePreviousPosX, yPos
				- movePreviousPosY);
#endif
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;
		zooming = false;
		initialZoomDistance = -1;

	SYS_UnlockRenderMutex();
}

void VID_RightClickEnded(int xPos, int yPos)
{
	//LOGD("VID_RightClickEnded: %d %d", xPos, yPos);

	SYS_LockRenderMutex();

		if (moving)
		{
			float totalTime;
			float distanceX, distanceY;
			float accelerationX, accelerationY;

			totalTime = lastTouchTime - firstTouchTime;
			totalTime /= 1000.0f;
			LOGG("totalTime=%f", totalTime);

			distanceX = (moveInitialPosX - movePreviousPosX); //abs
			distanceY = (moveInitialPosY - movePreviousPosY); //abs

			LOGG("distanceX=%f", distanceX);
			LOGG("distanceY=%f", distanceY);

			accelerationX = (distanceX / (.5 * (totalTime * totalTime)));
			accelerationY = (distanceY / (.5 * (totalTime * totalTime)));

			LOGG("==========================================ACCELERATIONX=%f", accelerationX);
			LOGG("==========================================ACCELERATIONY=%f", accelerationY);

#ifdef ORIENTATION_LANDSCAPE
			guiMain->FinishRightClickMove(movePreviousPos.y, VIEW_HEIGHT-movePreviousPos.x,
					movePreviousPos.y - moveInitialPos.y, -(movePreviousPos.x - moveInitialPos.x),
					-accelerationY, accelerationX);
#else
			guiMain->FinishRightClickMove(movePreviousPosX, movePreviousPosY, movePreviousPosX - moveInitialPosX,
					movePreviousPosY - moveInitialPosY, accelerationX, -accelerationY);
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
			if (!guiMain->DoFinishRightClick(xPos, yPos))
			{
				LOGG("touchesEnded single tap not consumed");
			}
#endif
		}

		guiMain->FinishTouches();

		zooming = false;
		initialZoomDistance = -1;
		pressConsumed = false;

	SYS_UnlockRenderMutex();
}

void VID_TouchesScrollWheel(float deltaX, float deltaY)
{
//	LOGI("VID_TouchesScrollWheel: %f %f", deltaX, deltaY);
	guiMain->DoScrollWheel(deltaX, deltaY);
}

void VID_NotTouchedMoved(int xPos, int yPos)
{
	//LOGD("VID_NotTouchedMoved: %d %d", xPos, yPos);

	SYS_LockRenderMutex();

#ifdef ORIENTATION_LANDSCAPE
		guiMain->DoNotTouchedMove(yPos, VIEW_HEIGHT-xPos);
#else
		guiMain->DoNotTouchedMove(xPos, yPos);
#endif

	SYS_UnlockRenderMutex();
}

///

void VID_DrawView()
{
	gCurrentFrameTime = SYS_GetCurrentTimeInMillis();

	//LOGD("VID_DrawView");

	//LOGD("SYS_LockRenderMutex");
	SYS_LockRenderMutex();
	//LOGD("SYS_LockRenderMutex done");


#ifdef USE_THREADED_IMAGES_LOADING
	VID_BindImages();
#endif


	currentFrameTime = GetTickCount();
	int numLoops = 0;

	while ((currentFrameTime - lastFrameTime) > dt && numLoops < 1000)
	{
		if (resetLogicClock)
		{
			resetLogicClock = false;
			lastFrameTime = currentFrameTime;
			break;
		}
		//LOGD("guiMain->DoLogic()");
		guiMain->DoLogic();
		lastFrameTime += dt;
		numLoops++;
	}

	//LOGD("drawView");
	glColor4f(1.0, 1.0, 1.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glLoadIdentity();

	//LOGD("guiMain->Render()");
	guiMain->Render();

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
		BlitAlpha(imgZoomSign, zoomingPosX - 13.5f, zoomingPosY - 13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);

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

		BlitAlpha(imgZoomSign, secX - 13.5f, secY - 13.5f, -2.0f, 27.0f, 27.0f, 0.0, 0.0, 1.0, 1.0, 0.75f);
	}
#endif

	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);


	//LOGD("SYS_UnlockRenderMutex");
	SYS_UnlockRenderMutex();

}

GLuint texture[1];

void SetClipping(GLint x, GLint y, GLsizei sizeX, GLsizei sizeY)
{
	// TODO: SetClipping does not work on win in fullscreen mode (dd)
	glEnable(GL_SCISSOR_TEST);


#ifdef ORIENTATION_LANDSCAPE
	glScissor((SCREEN_HEIGHT-y-sizeY), (SCREEN_WIDTH-x-sizeX), sizeY, sizeX);
#else
	//	LOGD("SetClipping: x=%f y=%f sizeX=%f sizeY=%f SCREEN_WIDTH=%d SCREEN_HEIGHT=%d", x ,y, sizeX, sizeY, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	
	float nx = (float)x * SCREEN_SCALE + VIEW_START_X;
	float ny = (SCREEN_HEIGHT - ((float)y) - ((float)sizeY)) * SCREEN_SCALE + VIEW_START_Y;
	float sx = (float)sizeX * SCREEN_SCALE;
	float sy = (float)sizeY * SCREEN_SCALE;
	
	glScissor((GLint)nx, (GLint)ny, (GLsizei)sx, (GLsizei)sy);

	//glScissor(x * SCREEN_SCALE, (SCREEN_HEIGHT - y - sizeY) * SCREEN_SCALE, sizeX * SCREEN_SCALE, sizeY * SCREEN_SCALE);
#endif

}

void ResetClipping()
{
	glDisable(GL_SCISSOR_TEST);
	glScissor(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
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
	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
#else
	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat texStartX,
		GLfloat texStartY, GLfloat texEndX, GLfloat texEndY, GLfloat colorR, GLfloat colorG, GLfloat colorB,
		GLfloat alpha)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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
	vertices[0] = -1.0 + destY + TOP_OFFSET_Y;
	vertices[1] = 1.0 + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = 1.0 + destY + TOP_OFFSET_Y;
	vertices[4] = 1.0 + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = -1.0 + destY + TOP_OFFSET_Y;
	vertices[7] = -1.0 + destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = 1.0 + destY + TOP_OFFSET_Y;
	vertices[10] = -1.0 + destX + LEFT_OFFSET_X;
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

	vertices[0] = -1.0 + destY + TOP_OFFSET_Y;
	vertices[1] = 1.0 + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = 1.0 + destY + TOP_OFFSET_Y;
	vertices[4] = 1.0 + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = -1.0 + destY + TOP_OFFSET_Y;
	vertices[7] = -1.0 + destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = 1.0 + destY + TOP_OFFSET_Y;
	vertices[10] = -1.0 + destX + LEFT_OFFSET_X;
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
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
#else
	texCoords[0] = 0.0;
	texCoords[1] = 0.0;
	texCoords[2] = 1.0;
	texCoords[3] = 0.0;
	texCoords[4] = 0.0;
	texCoords[5] = 1.0;
	texCoords[6] = 1.0;
	texCoords[7] = 1.0;

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

	vertices[0] = destY; //+ TOP_OFFSET_Y;
	vertices[1] = sizeX + destX; //+ LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY; //+ TOP_OFFSET_Y;
	vertices[4] = sizeX + destX; //+ LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY; //+ TOP_OFFSET_Y;
	vertices[7] = destX; //+ LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY; //+ TOP_OFFSET_Y;
	vertices[10] = destX; //+ LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX; //+ LEFT_OFFSET_X;
	vertices[1] = destY; //+ TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX; //+ LEFT_OFFSET_X;
	vertices[4] = destY; //+ TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX; //+ LEFT_OFFSET_X;
	vertices[7] = sizeY + destY; //+ TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX; //+ LEFT_OFFSET_X;
	vertices[10] = sizeY + destY; //+ TOP_OFFSET_Y;
	vertices[11] = z;
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

	vertices[0]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[1]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[4]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[5]  =	z;

	vertices[6]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[7]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[10] =	destX			; //+ LEFT_OFFSET_X;
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

	vertices[0]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[1]  =  destY	; //+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[4]  =  destY	; //+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[7]  =  sizeY + destY			; //+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[10] =	sizeY + destY			; //+ TOP_OFFSET_Y;
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	sizeX -= 1;
	sizeY -= 1;
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	sizeX -= 1;
	sizeY -= 1;
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = what->defaultTexStartY;
	texCoords[1] = what->defaultTexStartX;
	texCoords[2] = what->defaultTexEndY;
	texCoords[3] = what->defaultTexStartX;
	texCoords[4] = what->defaultTexStartY;
	texCoords[5] = what->defaultTexEndX;
	texCoords[6] = what->defaultTexEndY;
	texCoords[7] = what->defaultTexEndX;

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
#endif

	glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
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

void BlitCheckAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
		GLfloat alpha)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;

	glBindTexture(GL_TEXTURE_2D, what->texture[0]);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size, GLfloat texStartX, GLfloat texStartY,
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size, GLfloat texStartX,
		GLfloat texStartY, GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size, GLfloat texStartX,
		GLfloat texStartY, GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

	vertices[0]  =  destY			+ TOP_OFFSET_Y;
	vertices[1]  =  sizeX + destX	+ LEFT_OFFSET_X;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	+ TOP_OFFSET_Y;
	vertices[4]  =  sizeX + destX	+ LEFT_OFFSET_X;
	vertices[5]  =	z;

	vertices[6]  =  destY			+ TOP_OFFSET_Y;
	vertices[7]  =  destX			+ LEFT_OFFSET_X;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	+ TOP_OFFSET_Y;
	vertices[10] =	destX			+ LEFT_OFFSET_X;
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

	vertices[0]  =  destX			+ LEFT_OFFSET_X;
	vertices[1]  =  sizeY + destY	+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	+ LEFT_OFFSET_X;
	vertices[4]  =  sizeY + destY	+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			+ LEFT_OFFSET_X;
	vertices[7]  =  destY			+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	+ LEFT_OFFSET_X;
	vertices[10] =	destY			+ TOP_OFFSET_Y;
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
	LOGG("BlitAlphaColor: %s", what->name);
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
	LOGG("BlitAlphaColor done: %s", what->name);
#endif

}



void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat texStartX,
		GLfloat texStartY, GLfloat texEndX, GLfloat texEndY)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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
		GLfloat texStartX, GLfloat texStartY, GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
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

	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
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

	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat colorR,
		GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitFilledRectangle: destX=%f destY=%f z=%f sizeX=%f sizeY=%f colorR=%f colorG=%f colorB=%f alpha=%f",
			destX, destY, z, sizeX, sizeY, colorR, colorG, colorB, alpha);
#endif


	//LOGD("define verts");
#ifdef ORIENTATION_LANDSCAPE
	vertices[0] = destY + TOP_OFFSET_Y;
	vertices[1] = sizeX + destX + LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] = sizeY + destY + TOP_OFFSET_Y;
	vertices[4] = sizeX + destX + LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = destY + TOP_OFFSET_Y;
	vertices[7] = destX + LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] = sizeY + destY + TOP_OFFSET_Y;
	vertices[10] = destX + LEFT_OFFSET_X;
	vertices[11] = z;
#else
	vertices[0] = destX + LEFT_OFFSET_X;
	vertices[1] = sizeY + destY + TOP_OFFSET_Y;
	vertices[2] = z;

	vertices[3] = sizeX + destX + LEFT_OFFSET_X;
	vertices[4] = sizeY + destY + TOP_OFFSET_Y;
	vertices[5] = z;

	vertices[6] = destX + LEFT_OFFSET_X;
	vertices[7] = destY + TOP_OFFSET_Y;
	vertices[8] = z;

	vertices[9] = sizeX + destX + LEFT_OFFSET_X;
	vertices[10] = destY + TOP_OFFSET_Y;
	vertices[11] = z;
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

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat colorR,
		GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS
	LOGG("BlitRectangle");
#endif

	BlitLine(destX, destY, destX, destY + sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY + sizeY, destX + sizeX, destY + sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX + sizeX, destY, destX + sizeX, destY + sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY, destX + sizeX, destY, z, colorR, colorG, colorB, alpha);


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
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ, GLfloat colorR, GLfloat colorG,
		GLfloat colorB, GLfloat alpha)
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

	glVertexPointer(3, GL_FLOAT, 0, vertices);

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
	const int numCircleVerts = 48;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);

	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = sinf(angle)*radius;
		glverts[i*2+1] = cosf(angle)*radius;
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

void GenerateLineStripFromCircularBuffer(CGLLineStrip *lineStrip, signed short *data, int length, int pos,
		GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer");
#endif

	int dataLen = (int) ((sizeX + 1) * 3.0);
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
		lineStripData[c] = posY + (((GLfloat) data[(int) samplePos] + 32767.0) / 65536.0) * sizeY;
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

		if ((c + 3) >= dataLen)
			break;
	}
	lineStrip->length = (int) (c / 3);


#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer done");
#endif

	return;
}

void GenerateLineStripFromFft(CGLLineStrip *lineStrip, float *data, int start, int count, float multiplier,
		GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft");
#endif

	int dataLen = (int) ((sizeX + 1) * 3.0);
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
			lineStripData[c] = (endY) - (maxVal * multiplier) * sizeY;
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

			int prevSamplePos = (int) samplePos;
			samplePos += step;
			int nextSamplePos = (int) samplePos;

			if (prevSamplePos + 1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int) samplePos];
					if (abs(val) > abs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int) samplePos];
			}

			counter += step;
			if (((int) counter) >= (int) count)
				break;
		}
	}

	lineStrip->length = (int) (c / 3);


#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft done");
#endif

	return;

}

void GenerateLineStripFromFloat(CGLLineStrip *lineStrip, float *data, int start, int count, GLfloat posX, GLfloat posY,
		GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFloat");
#endif

	int dataLen = (int) ((sizeX + 1) * 3.0);
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

			int prevSamplePos = (int) samplePos;
			samplePos += step;
			int nextSamplePos = (int) samplePos;

			if (prevSamplePos + 1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int) samplePos];
					if (abs(val) > abs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int) samplePos];
			}

			counter += step;
			if (((int) counter) >= (int) count)
				break;
		}
	}

	lineStrip->length = (int) (c / 3);


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

void GenerateLineStrip(CGLLineStrip *lineStrip, signed short *data, int start, int count, GLfloat posX, GLfloat posY,
		GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStrip");
#endif

	int dataLen = (int) ((sizeX + 1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	int c = 0;
	GLfloat end = (GLfloat) (start + count);
	signed short maxVal = data[0];


	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
#ifdef ORIENTATION_PLAIN
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posY + (((GLfloat) maxVal + 32767.0) / 65536.0) * sizeY;
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

			int prevSamplePos = (int) samplePos;
			samplePos += step;
			int nextSamplePos = (int) samplePos;

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
				maxVal = data[(int) samplePos];
			}

			counter += step;
			if (((int) counter) >= (int) count)
				break;
		}
	}

	lineStrip->length = (int) (c / 3);


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
	glVertexPointer(3, GL_FLOAT, 0, glLineStrip->lineStripData);

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
	BlitLine(posX, posY - CENTER_MARKER_SIZE, posX, posY + CENTER_MARKER_SIZE, posZ, r, g, b, alpha);

	BlitLine(posX - CENTER_MARKER_SIZE, posY, posX + CENTER_MARKER_SIZE, posY, posZ, r, g, b, alpha);
}

void BlitGradientRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						   GLfloat colorR1, GLfloat colorG1, GLfloat colorB1, GLfloat colorA1,
						   GLfloat colorR2, GLfloat colorG2, GLfloat colorB2, GLfloat colorA2,
						   GLfloat colorR3, GLfloat colorG3, GLfloat colorB3, GLfloat colorA3,
						   GLfloat colorR4, GLfloat colorG4, GLfloat colorB4, GLfloat colorA4)

{
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
	
	vertsColors[0]	= colorR1;
	vertsColors[1]	= colorG1;
	vertsColors[2]	= colorB1;
	vertsColors[3]	= colorA1;
	
	vertsColors[4]	= colorR2;
	vertsColors[5]	= colorG2;
	vertsColors[6]	= colorB2;
	vertsColors[7]	= colorA2;
	
	vertsColors[8]	= colorR3;
	vertsColors[9]	= colorG3;
	vertsColors[10]	= colorB3;
	vertsColors[11]	= colorA3;
	
	vertsColors[12]	= colorR4;
	vertsColors[13]	= colorG4;
	vertsColors[14]	= colorB4;
	vertsColors[15]	= colorA4;
	
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

void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat r, GLfloat g, GLfloat b,
		GLfloat alpha)
{
	BlitLine(posX, posY - sizeY / 2, posX, posY + sizeY / 2, posZ, r, g, b, alpha);

	BlitLine(posX - sizeX / 2, posY, posX + sizeX / 2, posY, posZ, r, g, b, alpha);
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
	glRotatef(angle, 0, 0, 1); //* RADTODEG
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
	GLfloat rSizeX2 = rSizeX / 2.0f;
	GLfloat rSizeY2 = rSizeY / 2.0f;
	rPosX -= rSizeX2;
	rPosY -= rSizeY2;

	//LOGD("BLIT: %3.2f %3.2f %3.2f | %3.2f %3.2f", rPosX, rPosY, rPosZ, rSizeX, rSizeY);

	PushMatrix2D();

	Translate2D(rPosX + rSizeX2, rPosY + rSizeY2, rPosZ);
	Rotate2D(rotationAngle);

	BlitAlpha(image, -rSizeX2, -rSizeY2, 0, rSizeX, rSizeY, alpha);
	PopMatrix2D();
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

void GUI_ShowAcknowledgements()
{
}

void VID_SetViewKeyboardOffset(float offsetY)
{
}

float VID_GetFingerRayLength()
{
	return 25.0f;
}

void BlitPolygonMixColor(CSlrImage *what, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#ifdef LOG_BLITS
	LOGG("BlitPolygonMixColor: %s", what->name);
#endif
	
	//	LOGD("========= BlitPolygonAlpha ========");
	//	for (u32 i = 0; i < 6; i++)
	//		LOGD("texCoords[%d]=%3.2f", i, texs[i]);
	//
	//	for (u32 i = 0; i < 9; i++)
	//		LOGD("vertices[%d]=%3.2f", i, verts[i]);
	//
	//	for (u32 i = 0; i < 9; i++)
	//		LOGD("normals[%d]=%3.2f", i, norms[i]);
	
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glNormalPointer(GL_FLOAT, 0, norms);
    glTexCoordPointer(2, GL_FLOAT, 0, texs);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(mixColorR, mixColorG, mixColorB, mixColorA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numVertices);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

#ifdef LOG_BLITS
	LOGG("BlitPolygonMixColor done: %s", what->name);
#endif
	
}

void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha,
				  GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	
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
	
		glBindTexture(GL_TEXTURE_2D, what->texture[0]);
		glVertexPointer(3, GL_FLOAT, 0, vertices);
		glNormalPointer(GL_FLOAT, 0, normals);
		glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
		
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glColor4f(mixColorR, mixColorG, mixColorB, alpha);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);


	
	
//		glBindTexture(GL_TEXTURE_2D, what->texture[0]);
//		
//		//glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
//		glColor4f(mixColorR, mixColorG, mixColorB, alpha);
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//		//glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}
