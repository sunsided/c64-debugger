#include "VID_GLViewController.h"
#include "ConstantsAndMacros.h"
#include "DBG_Log.h"
#include <pthread.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include "CGuiMain.h"
#include "SYS_Main.h"	// for MacOS EXEC_ON_VALGRIND tweak
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
#import "GLView.h"


// these are two most important features here:

//#define SHOW_CURRENT_FPS
//#define COUNT_CURRENT_FPS


pthread_mutex_t gRenderMutex;

byte gPlatformType = PLATFORM_TYPE_DESKTOP;
bool gForceLinearScale = false;
bool gScaleDownImages = false;

char *gPlatformDeviceString = NULL;

u64 gCurrentFrameTime = 0;
//static long dt = (long)((float)1000.0 / (float)FRAMES_PER_SECOND);
static float dtf = (double)1000.0f / (double)FRAMES_PER_SECOND;
float gTargetFPS = (float)FRAMES_PER_SECOND;

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

GLfloat SCREEN_WIDTH = 0.0f;
GLfloat SCREEN_HEIGHT = 0.0f;
GLfloat SCREEN_SCALE = 2.0f; //DEFAULT_SCREEN_SCALE;
GLfloat SCREEN_ASPECT_RATIO = 1.0f;
float VIEW_START_X = 0.0;
float VIEW_START_Y = 0.0;

static float LEFT_OFFSET_X	= shrink +		0.0;
static float TOP_OFFSET_Y	= shrink +		0.0;

static float RIGHT_OFFSET_X = -shrink +		480.0;
static float BOTTOM_OFFSET_Y = -shrink +	320.0;

GLint viewPortStartX = 0;
GLint viewPortStartY = 0;
GLsizei viewPortSizeX = 1;
GLsizei viewPortSizeY = 1;
volatile bool updateViewPort = false;


float VIEW_WIDTH = (RIGHT_OFFSET_X - LEFT_OFFSET_X);
float VIEW_HEIGHT = (BOTTOM_OFFSET_Y - TOP_OFFSET_Y);

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


GLfloat VID_GetScreenWidth()
{
	return SCREEN_WIDTH;
}

GLfloat VID_GetScreenHeight()
{
	return SCREEN_HEIGHT;
}

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

double GetTickCountF()
{
	timeval ts;
	gettimeofday(&ts,0);
	return (double)((double)ts.tv_sec * 1000.0 + ((double)ts.tv_usec / 1000.0));
}

void SYS_LockRenderMutex()
{
	guiMain->LockMutex(); //"SYS_LockRenderMutex");
//	pthread_mutex_lock(&gRenderMutex);
}

void SYS_UnlockRenderMutex()
{
	guiMain->UnlockMutex(); //"SYS_LockRenderMutex");
//	pthread_mutex_unlock(&gRenderMutex);
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

void VID_SetWindowAlwaysOnTop(bool isAlwaysOnTop)
{
	VID_isAlwaysOnTop = isAlwaysOnTop;

	[glView setWindowAlwaysOnTop:isAlwaysOnTop];
}

// do not store value
void VID_SetWindowAlwaysOnTopTemporary(bool isAlwaysOnTop)
{
	[glView setWindowAlwaysOnTop:isAlwaysOnTop];
}

bool VID_IsWindowAlwaysOnTop()
{
	return VID_isAlwaysOnTop;
}

void VID_SetWindowFullScreen(bool isFullScreen)
{
	if (isFullScreen == false)
	{
		LOGTODO("VID_SetWindowFullScreen: isFullScreen=false not supported yet");
		return;
	}
	
	[glView goFullScreen];
}

void SysTextFieldEditFinishedCallback::SysTextFieldEditFinished(UTFString *str)
{
}

void GUI_SetSysTextFieldEditFinishedCallback(SysTextFieldEditFinishedCallback *callback)
{
	//gAppView->textFieldEdidFinishedCallback = callback;
}

void GUI_ShowSysTextField(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY, char *text)
{
	LOGD("GUI_ShowSysTextField");
	//[gAppView showSysTextField:text];
	LOGD("GUI_ShowSysTextField finished");
}

void GUI_HideSysTextField()
{
	LOGD("GUI_HideSysTextField");
	//	[gAppView hideSysTextField];
	LOGD("GUI_HideSysTextField finished");
}

UTFString *GUI_GetSysTextFieldText()
{
	SYS_FatalExit("TODO: GUI_GetSysTextFieldText");
	
	LOGD("GUI_GetSysTextFieldText finished");
	
	return NULL;
}

void GUI_ShowVirtualKeyboard()
{
	//LOGTODO("GUI_ShowVirtualKeyboard");
}

void GUI_HideVirtualKeyboard()
{
	//LOGTODO("GUI_HideVirtualKeyboard");
}

void VID_SetViewKeyboardOffset(float offsetY)
{
	
}

void VID_ApplicationPreloadingFinished()
{
}


//long lastFrameTime, currentFrameTime;
double lastFrameTimeF, currentFrameTimeF, lastFrameTimeForFPS;
double fps;
double avgFps = FRAMES_PER_SECOND;
double avgFpsSum = 0.0f;
int avgFpsCounter = 0;
struct timeval frameTime;
int timePerFrame = 1000/15;
//long currentGameTime;
double currentGameTimeF;

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

void VID_UpdateViewPort(float newWidth, float newHeight)
{
//	LOGG("VID_UpdateViewPort: %f %f", newWidth, newHeight);
	
	updateViewPort = true;
	
	/*
	 SCREEN_SCALE = (float)newWidth / (float)SCREEN_WIDTH;
	 //LOGD("new SCREEN_SCALE=%f", SCREEN_SCALE);
	 newWidth = (unsigned int)(SCREEN_WIDTH * SCREEN_SCALE);
	 newHeight = (unsigned int)(SCREEN_HEIGHT * SCREEN_SCALE);
	 glViewport(0, 0, newWidth, newHeight);
	 */
	
	double vW = (double) newWidth;
	double vH = (double) newHeight;
	double A = (double) SCREEN_WIDTH / (double) SCREEN_HEIGHT; //SCREEN_WIDTH / (float)SCREEN_HEIGHT;
	double vA = (vW / vH);
	
//	LOGD("vW=%f vH=%f A=%f vA=%f", vW, vH, A, vA);
	
	if (A > vA)
	{
//		LOGD("glViewport A > vA");
		VIEW_START_X = 0;
		VIEW_START_Y = (vH * 0.5) - ((vW / A) * 0.5);
		SCREEN_SCALE = vW / SCREEN_WIDTH;
		
//		LOGD("glViewPort: %d %d %d %d", (GLint)VIEW_START_X, (GLint)VIEW_START_Y, (GLsizei)vW, (GLsizei)(vW/A));
		
		viewPortStartX = (GLint)VIEW_START_X;
		viewPortStartY = (GLint)VIEW_START_Y;
		viewPortSizeX = (GLsizei)vW;
		viewPortSizeY = (GLsizei)(vW / A);
	}
	else
	{
		if (A < vA)
		{
//			LOGD("glViewport A < vA");
			VIEW_START_X = (vW * 0.5) - ((vH * A) * 0.5);
			VIEW_START_Y = 0;
			SCREEN_SCALE = vH / SCREEN_HEIGHT;

//			LOGD("glViewPort: %d %d %d %d", (GLint)VIEW_START_X, (GLint)VIEW_START_Y, (GLsizei)(vH * A), (GLsizei)vH);
			
			viewPortStartX = (GLint)VIEW_START_X;
			viewPortStartY = (GLint)VIEW_START_Y;
			viewPortSizeX = (GLsizei)(vH * A);
			viewPortSizeY = (GLsizei)vH;
		}
		else
		{
//			LOGD("glViewport equal");
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
	
//	LOGG("VID_UpdateViewPort: done");
}

void VID_InitGL(float viewWidth, float viewHeight)
{
	LOGM("VID_InitGL: %f %f", viewWidth, viewHeight);
	
	size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine];
    free(machine);
	
	gPlatformDeviceString = STRALLOC([platform UTF8String]);
	
	LOGD("gPlatformDeviceString=%s", gPlatformDeviceString);

	
#if defined(REAL_ORIENTATION_LANDSCAPE)

	// MacOS aspect 1440x960 (1.5)
	SCREEN_WIDTH = 580; //576;
	SCREEN_HEIGHT = 360; //360;

//	// aspect 1.6
//	SCREEN_WIDTH = 576; //360 * 16/10;
//	SCREEN_HEIGHT = 360;
	
	// aspect 4:3
	//SCREEN_WIDTH = 480;
	//SCREEN_HEIGHT = 360;
	
	//              SCREEN_WIDTH = 480;
	//              SCREEN_HEIGHT = 320;
#elif defined(REAL_ORIENTATION_PLAIN)
	SCREEN_WIDTH = 360;
	SCREEN_HEIGHT = 480;
	
	
	// KIDS CHRISTMAS TREE
	SCREEN_WIDTH = 320;
	SCREEN_HEIGHT = 480;
#endif

	
	pthread_mutex_init(&gRenderMutex, NULL);
	
	SYS_InitApplicationPauseResume();
	SYS_InitAccelerometer();
	SYS_InitPlatformSettings();
	
	LOGM("init file system");
	SYS_InitFileSystem();
	
	RES_Init(2048);
	
	//      gAppView = self;
	pressConsumed = false;
	moving = false;
	
	initialZoomDistance = -1;
	
	//NSString *text = @"http://www.modules.pl/tracker/get_authors.php?l=a";
	//      [gAppView initConnection:text];
	
	GLfloat posX = 20.0;
	GLfloat posY = 50.0;
	GLfloat sizeX = 380.0;
	GLfloat sizeY = 30.0;
	
	glDisable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
	
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_MULTISAMPLE_ARB);
	
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
	
	VID_UpdateViewPort(viewWidth, viewHeight);
		
	glMatrixMode(GL_MODELVIEW);
	
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	//      glDisable(GL_COLOR_MATERIAL);
	//glBlendFunc(GL_ONE, GL_SRC_COLOR);
	
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
	imgZoomSign = RES_GetImage("/Engine/zoom-sign", true, true);
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
	
	//      currentFrameTime = CACurrentMediaTime();
	
//	lastFrameTime = GetTickCount();
//	currentFrameTime = GetTickCount();
//	currentGameTime = GetTickCount();
	
	lastFrameTimeF = GetTickCountF();
	currentFrameTimeF = GetTickCountF();
	currentGameTimeF = GetTickCountF();
	
	LOGM("setup view finished");
	
}



void GUI_SetPressConsumed(bool consumed)
{
	pressConsumed = consumed;
}

void VID_TouchesBegan(int x, int y, bool alt)
{
	LOGG("VID_TouchesBegan: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);
	
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
		LOGG("================= TAP %f %f ====================", xPos, yPos);
		
		guiMain->DoSystemMultiTap(0, xPos, yPos);
		guiMain->DoTap(xPos, yPos);

#endif
		
		moving = false;
		zooming = false;
		
		// TODO: double tap
	}
	else
	{
		LOGG("================= INIT ZOOMING ==================");
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

void VID_TouchesMoved(int x, int y, bool alt)
{
	LOGG("VID_TouchesMoved: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);

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
		
		//LOGG("================= MOVE %f %f ==================", xPos, yPos);

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

			LOGG("================= ZOOM %f %f ==================", xPos, yPos);

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

void VID_TouchesEnded(int x, int y, bool alt)
{
	LOGG("VID_TouchesEnded: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);

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
			LOGG("================= FINISH MOVE %f %f ==================", movePreviousPosX, movePreviousPosY);

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
				LOGG("touchesEnded single tap not consumed");
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

///

void VID_RightClickBegan(int x, int y, bool alt)
{
	LOGG("VID_RightClickBegan: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);
	
	SYS_LockRenderMutex();
	
	firstTouchTime = GetTickCount();
	
	pressConsumed = false;
	
		// single tap
		moveInitialPosX = xPos;
		moveInitialPosY = yPos;
		movePreviousPosX = xPos;
		movePreviousPosY = yPos;
		
		LOGG("================= RIGHT CLICK %f %f ====================", xPos, yPos);
		
		guiMain->DoRightClick(xPos, yPos);
		
		moving = false;
		zooming = false;
		
	SYS_UnlockRenderMutex();
}

void VID_RightClickMoved(int x, int y, bool alt)
{
	LOGG("VID_RightClickMoved: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);
	
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

void VID_RightClickEnded(int x, int y, bool alt)
{
	LOGG("VID_RightClickEnded: %d %d %s", x, y, (alt ? "[alt]" : ""));
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);
	
	SYS_LockRenderMutex();
	
		if (moving)
		{
			float totalTime;
			float distanceX, distanceY;
			float accelerationX, accelerationY;
			
			totalTime = lastTouchTime - firstTouchTime;
			totalTime /= 1000.0f;
			LOGG("totalTime=%f", totalTime);
			
			distanceX = (moveInitialPosX - movePreviousPosX);	//abs
			distanceY = (moveInitialPosY - movePreviousPosY);	//abs
			
			LOGG("distanceX=%f", distanceX);
			LOGG("distanceY=%f", distanceY);
			
			accelerationX = (distanceX / (.5 * (totalTime*totalTime)));
			accelerationY = (distanceY / (.5 * (totalTime*totalTime)));
			
			LOGG("==========================================ACCELERATIONX=%f", accelerationX);
			LOGG("==========================================ACCELERATIONY=%f", accelerationY);
			
			LOGG("================= FINISH RIGHT CLICK MOVE %f %f ==================", movePreviousPosX, movePreviousPosY);
			
			guiMain->FinishRightClickMove(movePreviousPosX, movePreviousPosY,
								movePreviousPosX - moveInitialPosX, movePreviousPosY - moveInitialPosY,
								accelerationX, -accelerationY);
		}
		else if (pressConsumed == false)
		{
			if (!guiMain->DoFinishRightClick(xPos, yPos))
			{
				LOGG("touchesEnded right click not consumed");
			}
			
			moving = false;
			
			guiMain->FinishTouches();
			
			zooming = false;
			initialZoomDistance = -1;
			pressConsumed = false;
		}

	SYS_UnlockRenderMutex();
}



///


void VID_NotTouchedMoved(int x, int y)
{
//	LOGG("VID_NotTouchedMoved: %d %d", x, y);
	
	float xPos = (int)(((float)x - VIEW_START_X) / (float)SCREEN_SCALE);
	float yPos = (int)SCREEN_HEIGHT - (((float)y - VIEW_START_Y) / (float)SCREEN_SCALE);
	
	//SYS_LockRenderMutex();
	
#ifdef ORIENTATION_LANDSCAPE
		guiMain->DoNotTouchedMove(yPos, VIEW_HEIGHT-xPos);
#else
		
		//LOGN("================= MOVE %f %f ==================", xPos, yPos);
		
		
		guiMain->DoNotTouchedMove(xPos, yPos);
#endif
	
	//SYS_UnlockRenderMutex();
}

static float gMagnifyTotal;

void VID_TouchesPinchZoom(float magnifyDifference)
{
	if (zooming == false)
	{
		guiMain->InitZoom();
		zooming = true;
		
		gMagnifyTotal = 0.0f;
	}
	
	gMagnifyTotal += magnifyDifference * 100.0f;
	
	guiMain->DoZoomBy(0.0f, 0.0f, gMagnifyTotal, magnifyDifference*100.0f);
}

void VID_TouchesScrollWheel(float deltaX, float deltaY)
{
	LOGI("VID_TouchesScrollWheel: %f %f", deltaX, deltaY);
	guiMain->DoScrollWheel(deltaX, deltaY);
}

void VID_DrawView()
{
//	LOGD("VID_DrawView()");
	
	[NSThread setThreadPriority:0.5];
	
	gCurrentFrameTime = SYS_GetCurrentTimeInMillis();

	if (updateViewPort)
	{
		glViewport(viewPortStartX, viewPortStartY, viewPortSizeX, viewPortSizeY);
		//GLenum error = glGetError();
		//NSLog(@"glViewport error: %d", error);
	}
	
	SYS_LockRenderMutex();

#ifdef USE_THREADED_IMAGES_LOADING
	VID_BindImages();
#endif
	
	// Set the stencil clear value
    glClearStencil ( 0x0 );
	glClearColor (0.0,0.0,0.0,1);
	glClear (GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);	//GL_DEPTH_BUFFER_BIT |
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
	
	glEnable(GL_MULTISAMPLE);
	glEnable(GL_MULTISAMPLE_ARB);
	
	glEnable(GL_LINE_SMOOTH);
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	glEnable(GL_POINT_SMOOTH);
	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);

	glEnable( GL_POLYGON_SMOOTH );
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

	glEnable(GL_BLEND);

	////////
	// added for particle system gldraw
	//glMatrixMode(GL_MODELVIEW);
	
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glEnable(GL_TEXTURE_2D);
	//glEnable(GL_BLEND);

	//////////
	
	
	//glEnable( GL_ALPHA_TEST );
	
	glLoadIdentity();
	
	guiMain->Render();
	
#ifdef SHOW_CURRENT_FPS
	guiMain->fntConsole->BlitText(bufFPS, 0.0, 0.0, 0.0, 7.0);
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
#endif	//LOAD_AND_BLIT_ZOOM_SIGN
	
	glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	///
	/// TIMING
	///
	//currentFrameTime = GetTickCount();
	currentFrameTimeF = GetTickCountF();

	if (resetLogicClock)
	{
		resetLogicClock = false;
		//lastFrameTime = currentFrameTime;
		lastFrameTimeF = currentFrameTimeF;
		lastFrameTimeForFPS = currentFrameTimeF;
	}
	else
	{	

		//long frameTimeDiff = (currentFrameTime - lastFrameTime);
		double frameTimeDiffF = currentFrameTimeF - lastFrameTimeF;
		
	#ifdef COUNT_CURRENT_FPS
		double frameTimeDiffFpsF = currentFrameTimeF - lastFrameTimeForFPS;
		CURRENT_FPS = (float)1000.0f / (float)frameTimeDiffFpsF;
	#endif
		
	#ifdef SHOW_CURRENT_FPS
//		sprintf(bufFPS, "%3.1f/%3.1f", CURRENT_FPS, FRAMES_PER_SECOND);
		
		avgFpsSum += CURRENT_FPS;
		avgFpsCounter++;
		if (avgFpsCounter == FRAMES_PER_SECOND)
		{
			avgFps = avgFpsSum / (double)FRAMES_PER_SECOND;
			avgFpsSum = 0.0;
			avgFpsCounter = 0;
		}
		
		sprintf(bufFPS, "%5.2f %5.2f", CURRENT_FPS, avgFps);
		
		///%3.4f  f=%f dtf=%f", CURRENT_FPS, FRAMES_PER_SECOND, frameTimeDiffFpsF, dtf);
		//LOGD("fps=%s", bufFPS);
	#endif
	
		int numLoops = 0;

		static long tta = 0;
		static u32 cnt = 0;
		//while((currentFrameTime - lastFrameTime) > dt && numLoops < 1000)	//1000
		while((currentFrameTimeF - lastFrameTimeF) > dtf && numLoops < 1000)
		{
			
			//		long t1 = GetTickCount();
			guiMain->DoLogic();
			//		cnt++;
			//		long tt = GetTickCount() - t1;
			
			//		tta = (tta + tt) / 2;
			
			//lastFrameTime += dt;
			lastFrameTimeF += dtf;
			numLoops++;
		}
	}
	
	//lastFrameTimeF = currentFrameTimeF;
	lastFrameTimeForFPS = GetTickCountF();

	SYS_UnlockRenderMutex();

	
	
	//	if (cnt > 100)
	//	{
	//		LOGD("avg logic=%d", tta);
	//		cnt = 0;
	//	}
}

//CGuiMain *guiMain = NULL;

void SetClipping(GLint x, GLint y, GLsizei sizeX, GLsizei sizeY)
{
	glEnable(GL_SCISSOR_TEST);
	
#ifdef ORIENTATION_LANDSCAPE
	glScissor((SCREEN_HEIGHT-y-sizeY), (SCREEN_WIDTH-x-sizeX), sizeY, sizeX);
#else
	//      LOGD("SetClipping: x=%f y=%f sizeX=%f sizeY=%f SCREEN_WIDTH=%d SCREEN_HEIGHT=%d", x ,y, sizeX, sizeY, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	float nx = (float)x * SCREEN_SCALE + VIEW_START_X;
	float ny = (SCREEN_HEIGHT - ((float)y) - ((float)sizeY)) * SCREEN_SCALE + VIEW_START_Y;
	float sx = (float)sizeX * SCREEN_SCALE;
	float sy = (float)sizeY * SCREEN_SCALE;
	
	glScissor((GLint)nx, (GLint)ny, (GLsizei)sx, (GLsizei)sy);
#endif
	
}

void ResetClipping()
{
	glDisable(GL_SCISSOR_TEST);
	glScissor(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
}



float VID_GetFingerRayLength()
{
	if (gPlatformType == PLATFORM_TYPE_PHONE)
	{
		return 35.0f;
	}
	else
	{
		return 25.0f;
	}
}

void VID_SetFPS(float fps)
{
	LOGM("VID_SetFPS: %3.2f", fps);
	
	gTargetFPS = fps;
	//dt = (long)((float)1000.0 / (float)fps);
	dtf = 1000.0 / (double)fps;
	
	LOGTODO("VID_SetFPS: MacOS not implemented");
	//[g_glView setFrameIntervalFPS:fps];
}

void GUI_GetRealScreenPixelSizes(double *pixelSizeX, double *pixelSizeY)
{
	LOGD("GUI_GetRealScreenPixelSizes");
	
	LOGD("  SCREEN_WIDTH=%f SCREEN_HEIGHT=%f  |  SCREEN_SCALE=%f",
		 SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_SCALE);
	LOGD("  viewPortSizeX=%d viewPortSizeY=%d |  viewPortStartX=%d viewPortStartY=%d",
		 viewPortSizeX, viewPortSizeY, viewPortStartX, viewPortStartY);
	
	LOGD("... calc pixel size");
	
	*pixelSizeX = (double)SCREEN_WIDTH / (double)viewPortSizeX;
	*pixelSizeY = (double)SCREEN_HEIGHT / (double)viewPortSizeY;
	
	LOGD("  pixelSizeX=%f pixelSizeY=%f", *pixelSizeX, *pixelSizeY);
	
	LOGD("GUI_GetRealScreenPixelSizes done");
}

//
bool VID_IsWindowFullScreen()
{
	return [glView isWindowFullScreen];
}

static volatile bool VID_isMouseCursorHidden = false;

void VID_ShowMouseCursor()
{
	LOGM("VID_ShowMouseCursor");
	dispatch_async(dispatch_get_main_queue(), ^{
		if (VID_isMouseCursorHidden == true)
		{
			VID_isMouseCursorHidden = false;
			[NSCursor unhide];
		}
	});
}

void VID_HideMouseCursor()
{
	LOGM("VID_HideMouseCursor");
	dispatch_async(dispatch_get_main_queue(), ^{
		if (VID_isMouseCursorHidden == false)
		{
			VID_isMouseCursorHidden = true;
			[NSCursor hide];
		}
	});
}

void VID_StoreMainWindowPosition()
{
	[glView storeMainWindowPosition];
}

void VID_RestoreMainWindowPosition()
{
	[glView restoreMainWindowPosition];
}

void VID_TestMenu()
{
//	[glView testMenu];
}

