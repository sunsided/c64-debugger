/*
 *  Created by Marcin Skoczylas on 09-11-19.
 *
 */

#include "C64D_Version.h"

//#define DO_NOT_USE_AUDIO_QUEUE
//#define USE_FAKE_CALLBACK

#define START_C64DEBUGGER

#include "CGuiMain.h"
#include "DBG_Log.h"
#include "VID_GLViewController.h"

#include "SND_SoundEngine.h"
#include "CSlrFontSystem.h"
#include "SYS_CFileSystem.h"
//#include "RES_ResourceManager.h"
#include <math.h>
#include "ConstantsAndMacros.h"
#include "MTH_MTRand.h"
#include "CSlrString.h"
#include "COneTouchData.h"
#include "CGuiViewBaseLoadingScreen.h"
#include "CGuiViewBaseResourceManager.h"
#include "CGuiViewLoadingScreen.h"
#include "CGuiViewResourceManager.h"
#include "SYS_KeyCodes.h"

#if defined(START_C64DEBUGGER)
#include "CViewC64.h"
#endif

#include "RES_ResourceManager.h"

#if defined(FINAL_RELEASE) && defined(START_ANIM_EDITOR)
#error FINAL_RELEASE and START_ANIM_EDITOR defined which is meaningless
#endif

#if defined(START_TESTER) || defined(START_TESTER_CONNECTION) || defined(START_TRACKER)
#undef IS_ANIMATION_EDITOR_ENABLED
#endif

#if defined(START_TESTER_CONNECTION)
#define LOAD_DEFAULT_FONT
#endif

// move user to the resource manager view when cicked top right edge of the screen (hidden in release)
#define DEBUG_USE_RESOURCE_MANAGER_AREA

#define CONSOLE_FONT_SIZE_X		0.03125
#define CONSOLE_FONT_SIZE_Y		0.03125
#define CONSOLE_FONT_PITCH_X	0.035156251
#define CONSOLE_FONT_PITCH_Y	0.035156251

float gHudLevelOffsetY = 0.0f;

CGuiMain *guiMain = NULL;
CConfigStorage *globalConfig = NULL;

CGuiMain::CGuiMain()
{
	guiMain = this;
}

void CGuiMain::Startup()
{
	LOGG("GUI_Startup()");
	
	//RES_GenerateEmbedDefaults();
	SYS_InitCharBufPool();
	
#if defined(USE_DEBUGSCREEN)
	debugScreen = new CDebugScreen(40, 20);
#endif
		
	// resource manager: preload graphics only on startup
	//RES_SetStateSkipResourcesLoading();
	
	RES_SetStateIdle();
	//VID_SetFPS(LOADING_SCREEN_FPS);
	
#if defined(START_ANIM_EDITOR)
	bool loadDefaultAnimation = true;
#else
	bool loadDefaultAnimation = false;
#endif

	SYS_InitStrings();
	MTH_TestMTRand();

#if defined(MTENGINE_CONFIG_FILE_NAME)
	globalConfig = new CConfigStorage(true, MTENGINE_CONFIG_FILE_NAME);
	//globalConfig->DumpToLog();
#else
	globalConfig = new CConfigStorage();
#endif

	isMouseCursorVisible = false;

	renderMutex = new CSlrMutex("CGuiMain::renderMutex");
	uiThreadTasksMutex = new CSlrMutex("CGuiMain::uiThreadTasksMutex");

	LOGM("sound engine init");
	SYS_InitSoundEngine();

	SCREEN_WIDTHd2 = SCREEN_WIDTH / 2.0f;
	SCREEN_HEIGHTd2 = SCREEN_HEIGHT / 2.0f;

	LOGM("load engine images");

	gScaleDownImages = false;

	threadViewLoader = new CViewLoaderThread();
	threadViewLoader->ThreadSetName("CViewLoaderThread");
	isLoadingResources = false;

	//bool tmp = gScaleDownImages;	// force always nearest
	gScaleDownImages = false;
	
#if defined(LOAD_CONSOLE_FONT)
	imgConsoleFonts = RES_GetImage("/Engine/console-plain");
	imgConsoleFonts->ResourceSetPriority(RESOURCE_PRIORITY_STATIC);
	fntConsole = new CSlrFontBitmap("console", imgConsoleFonts, CONSOLE_FONT_SIZE_X,
			CONSOLE_FONT_SIZE_Y, CONSOLE_FONT_PITCH_X, CONSOLE_FONT_PITCH_Y);
	fntConsole->ResourceSetPriority(RESOURCE_PRIORITY_STATIC);
#endif
	
#if defined(LOAD_CONSOLE_INVERTED_FONT)
	imgConsoleInvertedFonts = RES_GetImage("/Engine/console-inverted-plain");
	imgConsoleInvertedFonts->ResourceSetPriority(RESOURCE_PRIORITY_STATIC);
	fntConsoleInverted = new CSlrFontBitmap("console-inverted",
			imgConsoleInvertedFonts, CONSOLE_FONT_SIZE_X, CONSOLE_FONT_SIZE_Y, CONSOLE_FONT_PITCH_X,
			CONSOLE_FONT_PITCH_Y);
	fntConsoleInverted->ResourceSetPriority(RESOURCE_PRIORITY_STATIC);
#endif

#if defined(LOAD_DEFAULT_UI_THEME)
	this->theme = new CGuiTheme("default");
	
#elif defined(INIT_DEFAULT_UI_THEME)
	this->theme = new CGuiTheme();
#else
	this->theme = NULL;
//	this->imgBlack = NULL;
#endif

	this->focusElement = NULL;
	this->currentView = NULL;

// TODO: check if font file exists in a deploy

#ifdef LOAD_DEFAULT_FONT
	fntEngineDefault = RES_GetFont("/Engine/default-font");
	fntEngineDefault->scaleAdjust = 0.25f;

//	// default font:
//	imgFontDefault = RES_GetImage("/Engine/default-font", true, true);
//	
//	RES_DebugPrintResources();
//
//	CByteBuffer *fontData;
//	fontData = new CByteBuffer(true, "/Engine/default-font", DEPLOY_FILE_TYPE_FONT);
//	fntDefault = new CSlrFontProportional(fontData, imgFontDefault);
//	fntDefault->scaleAdjust = 0.25f;
//	delete fontData;

	fntShowMessage = fntEngineDefault;
#else
	imgFontDefault = NULL;
	fntShowMessage = NULL;
#endif

//#ifdef IOS
//	sfntDefault = new CSlrFontSystem("helvetica-36", true);	//36
//#else
//	// TEMPORARY
//	sfntDefault = fntConsole;
//#endif

	
	//
	// sound engine init moved to CViewC64 to enable selection of output device via command line & settings
	//
//	LOGM("sound engine startup");
//#ifndef DO_NOT_USE_AUDIO_QUEUE
//	gSoundEngine->StartAudioUnit(true, false, 0);
//#endif

	
	LOGM("init multi touch");
	for (u32 i = 0; i < MAX_MULTI_TOUCHES; i++)
	{
		touches[i] = new COneTouchData(i);
		touchesNotActive.push_back(touches[i]);
	}
	
	mousePosX = -1;
	mousePosY = -1;

	isShiftPressed = false;
	isAltPressed = false;
	isControlPressed = false;
	
	isLeftShiftPressed = false;
	isLeftControlPressed = false;
	isLeftAltPressed = false;
	
	isRightShiftPressed = false;
	isRightControlPressed = false;
	isRightAltPressed = false;

	
	windowOnTop = NULL;

	showMessage = NULL;
	showMessageScale = 5.0f;
	showMessageCurrentScale = 0.0;
	showMessageAlpha = 0.0;

	this->messageBox = NULL;
	this->repeatTime = 0;
	this->isKeyDown = false;

	this->isTapping = false;

	this->viewOnTop = NULL;
	
	this->lastZ = -1.0013;

	LOGM("adding main views");

//#if !defined(FINAL_RELEASE)
//
//	LOGM("...viewLoadingScreen");
//	viewLoadingScreen = new CGuiViewLoadingScreen(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT); // /- 60
//	this->AddGuiElement(viewLoadingScreen, -2.451318);
//	viewLoadingScreen->visible = true;
//	
//	LOGM("...viewResourceManager");
//	viewResourceManager = new CGuiViewResourceManager(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT); // /- 60
//	this->AddGuiElement(viewResourceManager, -2.461318);
//	viewResourceManager->visible = true;
//
//#else

	viewLoadingScreen = new CGuiViewBaseLoadingScreen(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT); // /- 60
	this->AddGuiElement(viewLoadingScreen, -2.451318);
	viewResourceManager = new CGuiViewBaseResourceManager(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT); // /- 60
	this->AddGuiElement(viewResourceManager, -2.461318);

//#endif
	
	// do not load resources for screens above ^^^^^^^
	RES_ClearResourcesToLoad();

	/////////////////////////////////////////////
	/////////////// game resources
	//
	viewLoadingScreen->SetLoadingText("init game");
	
#ifdef START_C64DEBUGGER
	// ===== init c64 debugger =====

	LOGM("...viewC64");
	viewC64 = new CViewC64(0, 0, -3.0, SCREEN_WIDTH, SCREEN_HEIGHT);// /- 60
	
#endif
	
	
	VID_ApplicationPreloadingFinished();


	LOGM("adding views done");
	
	LOGM("CGuiMain init done");

}

void CGuiMain::AddUiThreadTask(CUiThreadTaskCallback *taskCallback)
{
	uiThreadTasksMutex->Lock();
	uiThreadTasks.push_back(taskCallback);
	uiThreadTasksMutex->Unlock();
}

void CGuiMain::AddGuiElement(CGuiElement *guiElement)
{
	//map<int, CObjectInfo *>::iterator objDataIt = detectedObjects.find(val);
	this->guiElementsUpwards[lastZ] = guiElement;
	this->guiElementsDownwards[lastZ] = guiElement;
	
	lastZ -= 0.01;
}

void CGuiMain::AddGuiElement(CGuiElement *guiElement, float z)
{
	//map<int, CObjectInfo *>::iterator objDataIt = detectedObjects.find(val);
	this->guiElementsUpwards[z] = guiElement;
	this->guiElementsDownwards[z] = guiElement;
}

//@returns is consumed
bool CGuiMain::DoTap(GLfloat x, GLfloat y)
{
	LOGI("CGuiMain: DoTap: px=%3.2f; py=%3.2f;", x, y);

	
#if !defined(FINAL_RELEASE)
	if (x > SCREEN_WIDTH - 20 && y < 20)
	//if (x > SCREEN_WIDTH - 20 && y > SCREEN_HEIGHT - 20)
	//if (x < 20 && y > SCREEN_HEIGHT - 20)
	{
		StartResourceManager();
		return true;
	}
#endif

	isTapping = true;

	if (messageBox)
	{
		messageBox->DoTap(x, y);
		LOGI("CGuiMain: DoTap finished");
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoTap(x, y)) {
			LOGI("CGuiMain: DoTap finished");
			return true;
		}
	}

	if (viewOnTop)
	{
		LOGI("CGuiMain: DoTap finished");
		return viewOnTop->DoTap(x, y);
	}

	if (currentView)
	{
		LOGI("CGuiMain: DoTap finished");
		return currentView->DoTap(x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		LOGI("guiElement->'%s' Do tap:", guiElement->name);

		if (guiElement->DoTap(x, y))
		{
			LOGI("[tap consumed]");
			LOGI("CGuiMain: DoTap finished (consumed)");
			return true;
		}
	}
	LOGI("CGuiMain: DoTap finished (not consumed)");
	return false;
}

bool CGuiMain::DoFinishTap(GLfloat x, GLfloat y)
{
	//LOGF(DBGLVL_GUI, "CGuiMain: DoFinishTap: %f %f", x, y);

	isTapping = false;

	if (messageBox)
	{
		messageBox->DoFinishTap(x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoFinishTap(x, y))
			return true;
	}

	if (viewOnTop)
	{
		return viewOnTop->DoFinishTap(x, y);
	}

	if (currentView)
	{
		return currentView->DoFinishTap(x, y);
	}

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		if (guiElement->DoFinishTap(x, y))
			return true;
	}
	return false;
}

//@returns is consumed
bool CGuiMain::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGI("CGuiMain: DoDoubleTap:  x=%f y=%f", x, y);

	isTapping = true;

	if (messageBox)
	{
		messageBox->DoDoubleTap(x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoDoubleTap(x, y))
			return true;
	}

	if (viewOnTop)
	{
		return viewOnTop->DoDoubleTap(x, y);
	}
	
	if (currentView)
	{
		return currentView->DoDoubleTap(x, y);
	}


	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		if (guiElement->DoDoubleTap(x, y))
			return true;
	}
	return false;
}

bool CGuiMain::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGI("CGuiMain: DoFinishDoubleTap: %f %f", x, y);

	isTapping = false;

	if (messageBox)
	{
		messageBox->DoFinishDoubleTap(x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoFinishDoubleTap(x, y))
			return true;
	}

	if (viewOnTop)
	{
		return viewOnTop->DoFinishDoubleTap(x, y);
	}

	if (currentView)
	{
		return currentView->DoFinishDoubleTap(x, y);
	}
	

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		if (guiElement->DoFinishDoubleTap(x, y))
			return true;
	}
	return false;
}

void CGuiMain::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY,
		GLfloat diffX, GLfloat diffY)
{
	//viewScoreTracks->DoMove(x, y, distX, distY, diffX, diffY);

	mousePosX = x;
	mousePosY = y;
	
	if (isTapping == false)
	{
		// walkaround for lost tap
		this->DoTap(x, y);
		return;
	}

	if (messageBox)
	{
		messageBox->DoMove(x, y, distX, distY, diffX, diffY);
		return;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoMove(x, y, distX, distY, diffX, diffY))
			return;
	}

	if (viewOnTop)
	{
		viewOnTop->DoMove(x, y, distX, distY, diffX, diffY);
		return;
	}

	if (currentView)
	{
		currentView->DoMove(x, y, distX, distY, diffX, diffY);
		return;
	}

	//	LOGF("--- DoMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		//		LOGF("DoMove %f: %s", (*enumGuiElems).first, guiElement->name);

		bool consumed = guiElement->DoMove(x, y, distX, distY, diffX, diffY);
//		LOGF("   consumed=%d", consumed);
		if (consumed)
			return;
	}
}

void CGuiMain::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY,
		GLfloat accelerationX, GLfloat accelerationY)
{
//	LOGF(DBGLVL_GUI, "CGuiMain::FinishMove: x=%f y=%f accelX=%f accelY=%f", x, y, accelerationX, accelerationY);

	//viewScoreTracks->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
	isTapping = false;

	if (messageBox)
	{
		messageBox->FinishMove(x, y, distX, distY, accelerationX,
				accelerationY);
		return;
	}

	if (windowOnTop)
	{
		if (windowOnTop->FinishMove(x, y, distX, distY, accelerationX,
				accelerationY))
			return;
	}

	if (viewOnTop)
	{
		viewOnTop->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
		return;
	}
	
	if (currentView)
	{
		currentView->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		if (guiElement->FinishMove(x, y, distX, distY, accelerationX,
				accelerationY))
			return;
	}
}
//////


//@returns is consumed
bool CGuiMain::DoRightClick(GLfloat x, GLfloat y)
{
	LOGI("CGuiMain: DoRightClick: px=%3.2f; py=%3.2f;", x, y);
	
	isTapping = true;
	
	if (messageBox)
	{
		messageBox->DoRightClick(x, y);
		LOGI("CGuiMain: DoRightClick finished");
		return true;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->DoRightClick(x, y)) {
			LOGI("CGuiMain: DoRightClick finished");
			return true;
		}
	}
	
	if (viewOnTop)
	{
		LOGI("CGuiMain: DoTap finished");
		return viewOnTop->DoRightClick(x, y);
	}
	
	if (currentView)
	{
		LOGI("CGuiMain: DoTap finished");
		return currentView->DoRightClick(x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement == windowOnTop)
			continue;
		
		LOGI("guiElement->'%s' Do right click:", guiElement->name);
		
		if (guiElement->DoRightClick(x, y))
		{
			LOGI("[tap consumed]");
			LOGI("CGuiMain: DoTap finished (consumed)");
			return true;
		}
	}
	LOGI("CGuiMain: DoTap finished (not consumed)");
	return false;
}

bool CGuiMain::DoFinishRightClick(GLfloat x, GLfloat y)
{
	//LOGG("CGuiMain: DoFinishRightClick: %f %f", x, y);
	
	isTapping = false;
	
	if (messageBox)
	{
		messageBox->DoFinishRightClick(x, y);
		return true;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->DoFinishRightClick(x, y))
			return true;
	}
	
	if (viewOnTop)
	{
		return viewOnTop->DoFinishRightClick(x, y);
	}
	
	if (currentView)
	{
		return currentView->DoFinishRightClick(x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement == windowOnTop)
			continue;
		
		if (guiElement->DoFinishRightClick(x, y))
			return true;
	}
	return false;
}

void CGuiMain::DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY,
					  GLfloat diffX, GLfloat diffY)
{
	mousePosX = x;
	mousePosY = y;

	if (isTapping == false)
	{
		// walkaround for lost tap on some OSes
		this->DoRightClick(x, y);
		return;
	}
	
	if (messageBox)
	{
		messageBox->DoRightClickMove(x, y, distX, distY, diffX, diffY);
		return;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->DoRightClickMove(x, y, distX, distY, diffX, diffY))
			return;
	}
	
	if (viewOnTop)
	{
		viewOnTop->DoRightClickMove(x, y, distX, distY, diffX, diffY);
		return;
	}
	
	if (currentView)
	{
		currentView->DoRightClickMove(x, y, distX, distY, diffX, diffY);
		return;
	}
	
		LOGG("--- DoRightClickMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement == windowOnTop)
			continue;
		
				LOGG("DoRightClickMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		bool consumed = guiElement->DoRightClickMove(x, y, distX, distY, diffX, diffY);
				LOGG("   consumed=%d", consumed);
		if (consumed)
			return;
	}
}

void CGuiMain::FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY,
						  GLfloat accelerationX, GLfloat accelerationY)
{
	//	LOGG("CGuiMain::FinishRightClickMove: x=%f y=%f accelX=%f accelY=%f", x, y, accelerationX, accelerationY);
	
	isTapping = false;
	
	if (messageBox)
	{
		messageBox->FinishRightClickMove(x, y, distX, distY, accelerationX,
							   accelerationY);
		return;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->FinishRightClickMove(x, y, distX, distY, accelerationX,
									accelerationY))
			return;
	}
	
	if (viewOnTop)
	{
		viewOnTop->FinishRightClickMove(x, y, distX, distY, accelerationX, accelerationY);
		return;
	}
	
	if (currentView)
	{
		currentView->FinishRightClickMove(x, y, distX, distY, accelerationX, accelerationY);
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement == windowOnTop)
			continue;
		
		if (guiElement->FinishRightClickMove(x, y, distX, distY, accelerationX,
								   accelerationY))
			return;
	}
}

///
void CGuiMain::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	mousePosX = x;
	mousePosY = y;

	if (messageBox)
	{
		messageBox->DoNotTouchedMove(x, y);
		return;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->DoNotTouchedMove(x, y))
			return;
	}
	
	if (viewOnTop)
	{
		viewOnTop->DoNotTouchedMove(x, y);
		return;
	}
	
	if (currentView)
	{
		currentView->DoNotTouchedMove(x, y);
		return;
	}
	
	//	LOGF("--- DoNotTouchedMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement == windowOnTop)
			continue;
		
				//LOGD("DoNotTouchedMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		//bool consumed =
		guiElement->DoNotTouchedMove(x, y);

		// TODO: refactor DoNotTouchedMove to not return anything
			//LOGD("   consumed=%d", consumed);
//		if (consumed)
//			return;
	}
}

void CGuiMain::InitZoom()
{
	if (messageBox)
	{
		messageBox->InitZoom();
		return;
	}

	if (windowOnTop)
	{
		if (windowOnTop->InitZoom())
			return;
	}

	if (viewOnTop)
	{
		viewOnTop->InitZoom();
		return;
	}

	if (currentView)
	{
		currentView->InitZoom();
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		if (guiElement->InitZoom())
			return;
	}

}

void CGuiMain::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (messageBox)
	{
		messageBox->DoZoomBy(x, y, zoomValue, difference);
		return;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoZoomBy(x, y, zoomValue, difference))
			return;
	}

	if (viewOnTop)
	{
		viewOnTop->DoZoomBy(x, y, zoomValue, difference);
		return;
	}

	if (currentView)
	{
		currentView->DoZoomBy(x, y, zoomValue, difference);
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->DoZoomBy(x, y, zoomValue, difference))
			return;
	}
}

void CGuiMain::DoScrollWheel(float deltaX, float deltaY)
{
	if (messageBox)
	{
		messageBox->DoScrollWheel(deltaX, deltaY);
		return;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->DoScrollWheel(deltaX, deltaY))
			return;
	}
	
	if (viewOnTop)
	{
		viewOnTop->DoScrollWheel(deltaX, deltaY);
		return;
	}
	
	if (currentView)
	{
		currentView->DoScrollWheel(deltaX, deltaY);
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoScrollWheel(deltaX, deltaY))
			return;
	}
	
}


//@returns is consumed
bool CGuiMain::DoMultiTap(COneTouchData *touch, float x, float y)
{
	LOGI("CGuiMain: DoMultiTap: tapId=%d px=%3.2f; py=%3.2f;", touch->tapId, x, y);
	
	if (messageBox)
	{
		messageBox->DoMultiTap(touch, x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoMultiTap(touch, x, y))
		{
			return true;
		}
	}

	if (viewOnTop)
	{
		return viewOnTop->DoMultiTap(touch, x, y);
	}

	if (currentView)
	{
		return currentView->DoMultiTap(touch, x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		LOGI("guiElement->'%s' DoMultiTap:", guiElement->name);

		if (guiElement->DoMultiTap(touch, x, y))
		{
			LOGI("[tap consumed]");
			UnlockMutex();
			return true;
		}
	}
	
	return false;
}

bool CGuiMain::DoMultiMove(COneTouchData *touch, float x, float y)
{
	LOGI("CGuiMain: DoMultiMove: tapId=%d px=%3.2f; py=%3.2f;", touch->tapId, x, y);

	if (messageBox)
	{
		messageBox->DoMultiMove(touch, x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoMultiMove(touch, x, y))
			return true;
	}

	if (viewOnTop)
	{
		return viewOnTop->DoMultiMove(touch, x, y);
	}

	if (currentView)
	{
		return currentView->DoMultiMove(touch, x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		LOGI("guiElement->'%s' DoMultiMove:", guiElement->name);

		if (guiElement->DoMultiMove(touch, x, y))
		{
			LOGI("[tap consumed]");
			return true;
		}
	}
	
	return false;
}

bool CGuiMain::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	LOGI("CGuiMain: DoMultiFinishTap: tapId=%d px=%3.2f; py=%3.2f;", touch->tapId, x, y);

	if (messageBox)
	{
		messageBox->DoMultiFinishTap(touch, x, y);
		return true;
	}

	if (windowOnTop)
	{
		if (windowOnTop->DoMultiFinishTap(touch, x, y))
			return true;
	}

	if (viewOnTop)
	{
		return viewOnTop->DoMultiFinishTap(touch, x, y);
	}

	if (currentView)
	{
		return currentView->DoMultiFinishTap(touch, x, y);
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)
			continue;

		LOGI("guiElement->'%s' DoMultiFinishTap:", guiElement->name);

		if (guiElement->DoMultiFinishTap(touch, x, y))
		{
			LOGI("[tap consumed]");
			return true;
		}
	}
	return false;
}

void CGuiMain::FinishTouches()
{
	isTapping = false;

	if (messageBox)
	{
		messageBox->FinishTouches();
		return;
	}

	if (windowOnTop)
	{
		windowOnTop->FinishTouches();
	}

	if (viewOnTop)
	{
		viewOnTop->FinishTouches();
		return;
	}

	if (currentView)
	{
		currentView->FinishTouches();
		return;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems =
			guiElementsDownwards.begin();
			enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement == windowOnTop)// actually this is important to the wot behavior^
			continue;

		guiElement->FinishTouches();
	}

}

bool CGuiMain::DoSystemMultiTap(u64 systemTapId, float x, float y)
{
	LOGI("CGuiMain::DoSystemMultiTap: %llu", systemTapId);
	
	LockMutex();

	// assert check if not in taps (Android broken devices workaround)
	std::map<u64, COneTouchData *>::iterator it = touchesBySystemTapId.find(systemTapId);
	if (it != touchesBySystemTapId.end())
	{
		LOGError("CGuiMain::DoSystemMultiTap: Assert failed: %lu is already in touchesBySystemTapId", systemTapId);
		DoSystemMultiFinishTap(systemTapId, x, y);
	}
	
	if (touchesNotActive.empty())
	{
		LOGWarning("CGuiMain::DoSystemMultiTap: no more touches available (MAX_MULTI_TOUCHES=%d)", MAX_MULTI_TOUCHES);
		UnlockMutex();
		return false;
	}
	
	COneTouchData *touch = touchesNotActive.back();
	touchesNotActive.pop_back();
	
	touch->systemTapId = systemTapId;
	touch->isActive = true;
	touch->x = x;
	touch->y = y;
	touch->userData = NULL;

	touchesBySystemTapId[systemTapId] = touch;

	this->DoMultiTap(touch, x, y);
	
	UnlockMutex();
	return true;
}

bool CGuiMain::DoSystemMultiMove(u64 systemTapId, float x, float y)
{
	//LOGI("CGuiMain::DoSystemMultiMove: %llu", systemTapId);
	LockMutex();
	
	std::map<u64, COneTouchData *>::iterator it = touchesBySystemTapId.find(systemTapId);
	if (it == touchesBySystemTapId.end())
	{
		LOGError("CGuiMain::DoSystemMultiMove: Assert failed: %lu is not in touchesBySystemTapId", systemTapId);
		DoSystemMultiTap(systemTapId, x, y);
		UnlockMutex();
		return true;
	}
	
	COneTouchData *touch = it->second;
	touch->x = x;
	touch->y = y;
	
	this->DoMultiMove(touch, x, y);
	
	UnlockMutex();
	return true;
}

bool CGuiMain::DoSystemMultiFinishTap(u64 systemTapId, float x, float y)
{
	LOGI("CGuiMain::DoSystemMultiFinishTap: %llu", systemTapId);
	
	LockMutex();
	
	std::map<u64, COneTouchData *>::iterator it = touchesBySystemTapId.find(systemTapId);
	if (it == touchesBySystemTapId.end())
	{
		LOGError("CGuiMain::DoSystemMultiFinishTap: Assert failed: %lu is not in touchesBySystemTapId", systemTapId);
		UnlockMutex();
		return false;
	}
	
	COneTouchData *touch = it->second;
	
	this->DoMultiFinishTap(touch, x, y);
	
	touchesBySystemTapId.erase(it);
	
	touch->isActive = false;
	touch->systemTapId = 0;
	touch->x = 0.0f;
	touch->y = 0.0f;
	touch->userData = NULL;
	
	touchesNotActive.push_back(touch);
	
	UnlockMutex();
	return true;
}


bool CGuiMain::IsMainView(CGuiView *view)
{
	if (this->windowOnTop != NULL)
	{
		if (this->windowOnTop == view)
			return true;

		return false;
	}

	if (this->viewOnTop != NULL)
	{
		if (this->viewOnTop == view)
			return true;

		return false;
	}

	if (this->currentView == view)
		return true;

	return false;
}

void CGuiMain::Render()
{
	//LOGD("-------------- GUI_Render() --------------");

	RunUiTasks();
	
	this->LockRenderMutex(); //"CGuiMain::Render");

//	this->imgBackgroundBlue->Render(0, 0, -3.0, 320, 200);

	/*
	 A	诶	ēi
	 B	比	bǐ
	 C	西	xī
	 D	迪	dí
	 E	伊	yī
	 F	艾弗	ài fú
	 G	吉	jí
	 H	艾尺	ài chǐ
	 I	艾	ài
	 J	杰	jié
	 K	开	kāi
	 L	艾勒	ài lè
	 M	艾马	ài mǎ
	 N	艾娜	ài nà
	 O	哦	ó
	 P	屁	pì
	 Q	吉吾	jí wú
	 R	艾儿	ài ér
	 S	艾丝	ài sī
	 T	提	tí
	 U	伊吾	yī wú
	 V	维	wéi
	 W	豆贝尔维	dòu bèi ěr wéi
	 X	艾克斯	yī kè sī
	 Y	吾艾	wú ài
	 Z	贼德
	 */

//	sfntDefault->Blit("ABC ĄiÓę 诶 豆贝尔维 dòu bèi ěr wéi", 10, 10, -0.1, 1.0, 1.0, 0.0, 1.0, SYSFONT_ALIGN_LEFT, 1.0f);
//	sfntDefault->Blit("Ąćęłńóśźż 诶比贼德豆贝尔维吉吾", 10, 10, -1, SYSFONT_ALIGN_LEFT, 1.0f);
//	sfntDefault->Blit("AąćętestiiiiijiklmnoiXĄŁ", 10, 10, -1, SYSFONT_ALIGN_LEFT, 1.0f);
///	fntConsole->BlitText("test 123", 10, 10, -1.0, 5.0);
//	return;
//	Blit(guiMain->imgConsoleFonts, 0.0, 0.0, -2.0f, SCREEN_WIDTH, SCREEN_HEIGHT); //, 0.0, 0.0, bkgTexX, bkgTexY);
//	return;
	if (messageBox)
	{
		messageBox->Render();
	}
	else if (viewOnTop)
	{
		viewOnTop->Render();
		if (windowOnTop)
		{
			windowOnTop->Render();
		}
	}
	else
	{
		if (currentView)
		{
			currentView->Render();
		}
		else
		{
			for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems =
				 guiElementsUpwards.begin();
				 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++) {
				CGuiElement *guiElement = (*enumGuiElems).second;
				
				//LOGG("==MAIN== check %3.2f: %s visible=%s", (*enumGuiElems).first, guiElement->name, guiElement->visible ? "true" : "false");
				if (!guiElement->visible)
					continue;
				
				if (guiElement == windowOnTop)
					continue;
				
				//LOGG("==MAIN=== render %3.2f: %s", (*enumGuiElems).first, guiElement->name);
				guiElement->Render();
				//LOGG("==MAIN=== render %3.2f done: %s", (*enumGuiElems).first, guiElement->name);
			}
			
		}

		if (windowOnTop)
		{
			windowOnTop->Render();
		}
	}

	if (this->showMessage != NULL)
	{
		float sizeWidth;
		float sizeHeight;
		fntShowMessage->GetTextSize(this->showMessage,
				this->showMessageCurrentScale * this->showMessageScale,
				&sizeWidth, &sizeHeight);

		GLfloat sw2 = VID_GetScreenWidth() / 2;
		GLfloat sh3 = VID_GetScreenHeight() / 4;

		GLfloat msgPosX = sw2 - (sizeWidth / 2.0f);
		GLfloat msgPosY = sh3 - (sizeHeight / 2.0f);
		
#if defined(IS_TP)
		msgPosY += 20;
#endif

		//LOGD("BlitText: %f %f", msgPosX, msgPosY);
		fntShowMessage->BlitText(this->showMessage, msgPosX,
				msgPosY + gHudLevelOffsetY, -0.1,
				this->showMessageCurrentScale * this->showMessageScale,
				this->showMessageAlpha);
//							  showMessageColorR, showMessageColorG, showMessageColorB, this->showMessageAlpha,
//							  FONT_ALIGN_LEFT, this->showMessageCurrentScale * this->showMessageScale);

		/*
		 #if defined(IPHONE)
		 CSlrFontSystem::Size size = ((CSlrFontSystem *)sfntDefault)->GetTextSize(this->showMessage, this->showMessageCurrentScale * this->showMessageScale);

		 GLfloat sw2 = VID_GetScreenWidth() / 2;
		 GLfloat sh3 = VID_GetScreenHeight() / 4;

		 GLfloat msgPosX = sw2 - (size.width / 2);
		 GLfloat msgPosY = sh3 - (size.height / 2);

		 //LOGD("BlitText: %f %f", msgPosX, msgPosY);
		 sfntDefault->BlitText(this->showMessage, msgPosX, msgPosY, -0.1,
		 showMessageColorR, showMessageColorG, showMessageColorB, this->showMessageAlpha,
		 FONT_ALIGN_LEFT, this->showMessageCurrentScale * this->showMessageScale);
		 #else
		 */

//		const GLfloat fontSize = 22.0f;
//		GLfloat sizeWidth = (float)this->showMessageLen * this->showMessageCurrentScale * fontSize * this->showMessageScale;
//		GLfloat sizeHeight = this->showMessageCurrentScale * fontSize;
//
//		GLfloat sw2 = VID_GetScreenWidth() / 2;
//		GLfloat sh3 = VID_GetScreenHeight() / 4;
//
//		GLfloat msgPosX = sw2 - (sizeWidth / 2);
//		GLfloat msgPosY = sh3 - (sizeHeight / 2);
//
//		//LOGD("Render.ShowMessage: '%s' %f %f", this->showMessage, msgPosX, msgPosY);
//		fntConsole->BlitText(this->showMessage, msgPosX, msgPosY, -0.1,
//							 showMessageColorR, showMessageColorG, showMessageColorB, this->showMessageAlpha,
//							 FONT_ALIGN_LEFT, this->showMessageCurrentScale * fontSize * this->showMessageScale);
//#endif
	}

#if defined(DO_NOT_USE_AUDIO_QUEUE) && defined(USE_FAKE_CALLBACK)
	// fake soundengine callback
	playbackFakeCallback((int)(SOUND_SAMPLE_RATE / (FRAMES_PER_SECOND*2)));
#endif

#if !defined(FINAL_RELEASE)
	RES_DebugRender();
#if defined(USE_DEBUGSCREEN)
	debugScreen->Render();
#endif
#endif

	guiMain->UnlockRenderMutex(); //"CGuiMain::Render");

	RunUiTasks();
	
//	LOGD("------------ GUI_Render done -------------");

}

void CGuiMain::RunUiTasks()
{
	uiThreadTasksMutex->Lock();
	while(!uiThreadTasks.empty())
	{
		CUiThreadTaskCallback *taskCallback = uiThreadTasks.front();
		uiThreadTasks.pop_front();
		
		taskCallback->RunUIThreadTask();
		delete taskCallback;
	}
	uiThreadTasksMutex->Unlock();
}

void CGuiMain::DoLogic()
{
	this->LockMutex();

	// TODO: make this normal:)
//#if !defined(IPHONE)
//
//	if (this->viewKidsChristmasTreeMain->musicPlayer != NULL)
//		this->viewKidsChristmasTreeMain->musicPlayer->Update2();
//
//#endif

	//LOGF("DoLogic()");
	if (messageBox) {
		messageBox->DoLogic();
		this->UnlockMutex();
		return;
	}

	if (windowOnTop) {
		windowOnTop->DoLogic();
	}

	if (viewOnTop) {
		viewOnTop->DoLogic();
	} else {
		for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems =
				guiElementsUpwards.begin();
				enumGuiElems != guiElementsUpwards.end(); enumGuiElems++) {
			CGuiElement *guiElement = (*enumGuiElems).second;

			if (!guiElement->visible)
				continue;

			if (guiElement == windowOnTop)
				continue;

			guiElement->DoLogic();
		}
	}

	if (this->showMessageAlpha > 0.0)
	{
#if defined(IS_TP)
		showMessageCurrentScale -= 0.012 * 0.35; //0.025;
		showMessageAlpha -= 0.02; //0.06;
#else
#if defined(RUN_ATARI)
		showMessageCurrentScale -= 0.006 * 0.45; //0.025;
		showMessageAlpha -= 0.02; //0.06;
#else
		showMessageCurrentScale -= 0.012 * 0.45; //0.025;
		showMessageAlpha -= 0.03; //0.06;
#endif
#endif
	}
	else if (this->showMessage != NULL) {
//#if defined(IPHONE)
//		[this->showMessage release];
//#else
		free(this->showMessage);
//#endif
		this->showMessage = NULL;
	}

//	LOGTODO("GLOBALLOGICCALLBACK");'
//	for(std::list<CGlobalLogicCallback *>::iterator it = this->globalLogicCallbacks.begin();
//			it != this->globalLogicCallbacks.end(); it++)
//	{
//		CGlobalLogicCallback *val = (*it);
//		val->GlobalLogicCallback();
//	}

	this->UnlockMutex();

	/*
	 static int i = 0;
	 i++;

	 if (i > 30)
	 {
	 this->ShowMessage("Test");
	 i = 0;
	 }
	 */
}

void CGuiMain::SetWindowOnTop(CGuiElement *element) {
	this->windowOnTop = element;
}

void CGuiMain::SetViewOnTop(CGuiElement *element) {
	this->viewOnTop = element;
}

void CGuiMain::LoadAndSetView(CGuiView *element)
{
	LOGM("CGuiMain::LoadAndSetView: view=%s", element->name);

	this->isLoadingResources = true;

	// async load/create resources first
	this->SetView(this->viewLoadingScreen);
	
	SYS_StartThread(threadViewLoader, (void*) element);
}

void CViewLoaderThread::ThreadRun(void *data)
{	
	ThreadSetName("loader");
	
	LOGD(
			"======================================= CViewLoaderThread::ThreadRun");

	CGuiView *view = (CGuiView*) data;
	
	LOGD("... load view %s", view->name);

	RES_StartResourcesAllocate();

	SYS_Sleep(20);

	// wait one frame
	guiMain->LockMutex();
	guiMain->UnlockMutex();
	
	VID_SetFPS(LOADING_SCREEN_FPS);

//	LOGD2("CViewLoaderThread::ThreadRun: debug SYS_Sleep");
//	SYS_Sleep(5000);
	
	view->ResourcesPrepare();

	RES_LoadResourcesSync(NULL, NULL);

	guiMain->LockMutex();

	guiMain->isLoadingResources = false;
	VID_SetFPS(FRAMES_PER_SECOND);

	guiMain->viewLoadingScreen->LoadingFinishedSetView(view);

	guiMain->UnlockMutex();

	LOGD(
			"======================================= CViewLoaderThread::ThreadRun finished");

}

void CGuiMain::SetMouseCursorVisible(bool isVisible)
{
//	LOGD("CGuiMain::SetMouseCursorVisible isNowMouseCursorVisible=%s setToVisible=%s", STRBOOL(isMouseCursorVisible), STRBOOL(isVisible));
	if (isVisible == isMouseCursorVisible)
	{
		return;
	}
	
	CUiThreadTaskSetMouseCursorVisible *task = new CUiThreadTaskSetMouseCursorVisible(isVisible);
	this->AddUiThreadTask(task);
}

void CGuiMain::SetApplicationWindowFullScreen(bool isFullScreen)
{
	CUiThreadTaskSetFullScreen *task = new CUiThreadTaskSetFullScreen(isFullScreen);
	this->AddUiThreadTask(task);
}

void CGuiMain::SetApplicationWindowAlwaysOnTop(bool isAlwaysOnTop)
{
	CUiThreadTaskSetAlwaysOnTop *task = new CUiThreadTaskSetAlwaysOnTop(isAlwaysOnTop);
	this->AddUiThreadTask(task);
}

void CGuiMain::SetView(CGuiView *element)
{
	if (element == NULL)
	{
		return;
	}

	LOGG("CGuiMain::SetView: view=%s", element->name);

	if (this->currentView == NULL)
	{
		this->SetViewAsync(element);
	}
	else
	{
		CUiThreadTaskSetView *task = new CUiThreadTaskSetView(element);
		this->AddUiThreadTask(task);
	}
}

void CGuiMain::SetViewAsync(CGuiView *element)
{
	if (element == NULL)
	{
		return;
	}

	LOGG("CGuiMain::SetViewAsync: view=%s", element->name);
	
	LOGG("CGuiMain::SetViewAsync: LockMutex");
	guiMain->LockMutex();
	
	bool found = false;
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems =
			guiElementsUpwards.begin();
			enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		if (guiElement == element)
		{
			element->visible = true;
			element->ActivateView();
			found = true;
		}
		else
		{
			guiElement->visible = false;
			//guiElement->DeactivateView();
		}
	}

	this->currentView = element;

	if (!found)
	{
		SYS_FatalExit("CGuiMain::SetViewAsync: view not found (%s)", element->name);
	}
	
	SetFocus(element);
	
	LOGG("CGuiMain::SetViewAsync: UnlockMutex");
	guiMain->UnlockMutex();
	
	LOGG("CGuiMain::SetViewAsync: finished");
}

void CGuiMain::ShowMessage(CSlrString *showMessage)
{
	char *cStr = showMessage->GetStdASCII();
	this->ShowMessage(cStr);
	delete [] cStr;
}

void CGuiMain::ShowMessage(char *showMessage)
{
	guiMain->ShowMessage(showMessage, 0.7, 0.7, 0.7);
}

void CGuiMain::ShowMessageAsync(char *showMessage)
{
	guiMain->ShowMessageAsync(showMessage, 0.7, 0.7, 0.7);
}

void CGuiMain::ShowMessage(char *showMessage, float showMessageColorR, float showMessageColorG, float showMessageColorB)
{
	LOGM("CGuiMain::ShowMessage");
	CUiThreadTaskShowMessage *taskShowMessage = new CUiThreadTaskShowMessage(showMessage, showMessageColorR, showMessageColorG, showMessageColorB);
	this->AddUiThreadTask(taskShowMessage);
}

CUiThreadTaskShowMessage::CUiThreadTaskShowMessage(char *showMessage, float showMessageColorR, float showMessageColorG, float showMessageColorB)
{
	this->showMessage = strdup(showMessage); this->showMessageColorR = showMessageColorR; this->showMessageColorG = showMessageColorG; this->showMessageColorB = showMessageColorB;
}

void CUiThreadTaskShowMessage::RunUIThreadTask()
{
	guiMain->ShowMessageAsync(this->showMessage, showMessageColorR, showMessageColorG, showMessageColorB);
}

// note: ShowMessageAsync assumes that showMessage was allocated by CGuiMain and thus can be safely deleted
void CGuiMain::ShowMessageAsync(char *showMessage, GLfloat showMessageColorR,
		GLfloat showMessageColorG, GLfloat showMessageColorB)
{
	LOGM("CGuiMain::ShowMessageAsync");
	if (this->showMessage != NULL)
	{
		free(this->showMessage);
	}

	if (showMessage == NULL)
	{
		this->showMessage = NULL;
		return;
	}

	LOGM("showMessage='%s'", showMessage);

	this->showMessage = showMessage;
	this->showMessageLen = strlen(showMessage);

	this->showMessageCurrentScale = 0.75;
	this->showMessageAlpha = 2.0;
	this->showMessageColorR = showMessageColorR;
	this->showMessageColorG = showMessageColorG;
	this->showMessageColorB = showMessageColorB;
}

void CGuiMain::StopShowingMessage()
{
	guiMain->LockRenderMutex(); //CGuiMain::StopShowingMessage");

	if (this->showMessage != NULL) {
		free(this->showMessage);
	}

	this->showMessage = NULL;
	this->showMessageAlpha = 0.0f;
	this->showMessageCurrentScale = 0.0f;

	guiMain->UnlockRenderMutex(); //CGuiMain::StopShowingMessage");
}

void CGuiMain::ShowMessageBox(UTFString *text,
		CGuiMessageBoxCallback *messageBoxCallback)
{
	guiMain->LockRenderMutex(); //"CGuiMain::ShowMessageBox");
	if (this->messageBox != NULL)
	{
		delete this->messageBox;
	}

	this->messageBoxCallback = messageBoxCallback;
	this->messageBox = new CGuiViewMessageBox(0, 0, -3.0, SCREEN_WIDTH,
			SCREEN_HEIGHT, text, this);
	guiMain->UnlockRenderMutex(); //"CGuiMain::ShowMessageBox");
}

bool CGuiMain::MessageBoxClickedOK(CGuiViewMessageBox *messageBox)
{
	if (this->messageBoxCallback)
	{
		return this->messageBoxCallback->MessageBoxClickedOK(messageBox);
	}

	guiMain->LockRenderMutex(); //"CGuiMain::MessageBoxClickedOK");
	if (this->messageBox != NULL)
	{
		delete this->messageBox;
		this->messageBox = NULL;
	}
	guiMain->UnlockRenderMutex(); //"CGuiMain::MessageBoxClickedOK");

	return false;
}

void CGlobalLogicCallback::GlobalLogicCallback() {

}

void CGlobalOSWindowChangedCallback::GlobalOSWindowChangedCallback() {
	
}


void CGuiMain::ClearGlobalLogicCallbacks() {
	this->globalLogicCallbacks.clear();
}

void CGuiMain::AddGlobalLogicCallback(CGlobalLogicCallback *callback) {
	for (std::list<CGlobalLogicCallback *>::iterator it =
			this->globalLogicCallbacks.begin();
			it != this->globalLogicCallbacks.end(); it++) {
		CGlobalLogicCallback *val = (*it);
		if (val == callback) {
			LOGWarning("AddGlobalLogicCallback: double callback");
			return;
		}
	}
	this->globalLogicCallbacks.push_back(callback);
}

void CGuiMain::RemoveGlobalLogicCallback(CGlobalLogicCallback *callback) {
	this->globalLogicCallbacks.remove(callback);
}

//

void CGuiMain::ClearGlobalOSWindowChangedCallbacks() {
	this->globalOSWindowChangedCallbacks.clear();
}

void CGuiMain::AddGlobalOSWindowChangedCallback(CGlobalOSWindowChangedCallback *callback)
{
	for (std::list<CGlobalOSWindowChangedCallback *>::iterator it =
			this->globalOSWindowChangedCallbacks.begin();
			it != this->globalOSWindowChangedCallbacks.end(); it++)
	{
		CGlobalOSWindowChangedCallback *val = (*it);
		if (val == callback)
		{
			LOGWarning("AddGlobalOSWindowChangedCallback: double callback");
			return;
		}
	}
	this->globalOSWindowChangedCallbacks.push_back(callback);
}

void CGuiMain::RemoveGlobalOSWindowChangedCallback(CGlobalOSWindowChangedCallback *callback) {
	this->globalOSWindowChangedCallbacks.remove(callback);
}

void CGuiMain::NotifyGlobalOSWindowChangedCallbacks()
{
	for (std::list<CGlobalOSWindowChangedCallback *>::const_iterator it = this->globalOSWindowChangedCallbacks.begin();
			it != this->globalOSWindowChangedCallbacks.end();
			it++)
	{
		CGlobalOSWindowChangedCallback *callback = (CGlobalOSWindowChangedCallback *) *it;
		callback->GlobalOSWindowChangedCallback();
	}

}

//


bool CGlobalKeyboardCallback::GlobalKeyDownCallback(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CGlobalKeyboardCallback::GlobalKeyUpCallback(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CGlobalKeyboardCallback::GlobalKeyPressCallback(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

void CGuiMain::ClearGlobalKeyboardCallbacks()
{
	this->globalKeyboardCallbacks.clear();
}

void CGuiMain::AddGlobalKeyboardCallback(CGlobalKeyboardCallback *callback)
{
	for (std::list<CGlobalKeyboardCallback *>::iterator it =
			this->globalKeyboardCallbacks.begin();
			it != this->globalKeyboardCallbacks.end(); it++)
	{
		CGlobalKeyboardCallback *val = (*it);
		if (val == callback)
		{
			LOGWarning("AddGlobalKeyboardCallback: double callback");
			return;
		}
	}
	this->globalKeyboardCallbacks.push_back(callback);
}

void CGuiMain::RemoveGlobalKeyboardCallback(CGlobalKeyboardCallback *callback)
{
	this->globalKeyboardCallbacks.remove(callback);
}

void CGuiMain::SetFocus(CGuiElement *element)
{
	//LOGD("CGuiMain::SetFocus: %s", (element ? element->name : "NULL"));
	this->repeatTime = 0;
	if (focusElement != NULL)
	{
		focusElement->FocusLost();
	}

	focusElement = element;

	if (focusElement != NULL)
	{
		focusElement->FocusReceived();
	}
}

void CGuiMain::StartResourceManager()
{
#if !defined(FINAL_RELEASE)
	LOGM("CGuiMain::START RESOURCE MANAGER");

	if (this->currentView == this->viewResourceManager)
	{
		this->viewResourceManager->DoReturnView();
	}
	else
	{
		this->viewResourceManager->SetReturnView(this->currentView);
		this->SetView(this->viewResourceManager);
	}
#endif
}

void CGuiMain::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiMain::KeyDown: keyCode=%d (0x%2.2x = %c) isShift=%s isAlt=%s isControl=%s", keyCode, keyCode, keyCode, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	
	isShiftPressed = isShift;
	isAltPressed = isAlt;
	isControlPressed = isControl;

//	wasShiftPressed = isShift;
//	wasAltPressed = isAlt;
//	wasControlPressed = isControl;

	if (keyCode == MTKEY_LSHIFT)
	{
		isShiftPressed = true;
		isLeftShiftPressed = true;
	}
	else if (keyCode == MTKEY_RSHIFT)
	{
		isShiftPressed = true;
		isRightShiftPressed = true;
	}
	else if (keyCode == MTKEY_LALT)
	{
		isAltPressed = true;
		isLeftAltPressed = true;
	}
	else if (keyCode == MTKEY_RALT)
	{
		isAltPressed = true;
		isRightAltPressed = true;
	}
	else if (keyCode == MTKEY_LCONTROL)
	{
		isControlPressed = true;
		isLeftControlPressed = true;
	}
	else if (keyCode == MTKEY_RCONTROL)
	{
		isControlPressed = true;
		isRightControlPressed = true;
	}

	// sanity check
	if (isShiftPressed == false)
	{
		isLeftShiftPressed = false;
		isRightShiftPressed = false;
	}
	if (isAltPressed == false)
	{
		isLeftAltPressed = false;
		isRightAltPressed = false;
	}
	if (isControlPressed == false)
	{
		isLeftControlPressed = false;
		isRightControlPressed = false;
	}
	
	this->repeatTime = 0;
	isKeyDown = true;

#ifndef IS_C64DEBUGGER
	if ((keyCode == 'r' || keyCode == 'R') && isControl)
	{
		StartResourceManager();
		return;
	}
#endif

	if (messageBox)
	{
		messageBox->KeyDown(keyCode, isShift, isAlt, isControl);
		LOGI("CGuiMain: KeyDown finished");
		return;
	}
	
	if (windowOnTop)
	{
		if (windowOnTop->KeyDown(keyCode, isShift, isAlt, isControl)) {
			LOGI("CGuiMain: KeyDown finished");
			return;
		}
	}
	
	if (viewOnTop)
	{
		LOGI("CGuiMain: KeyDown finished");
		viewOnTop->KeyDown(keyCode, isShift, isAlt, isControl);
		return;
	}
	
	if (this->currentView != NULL)
	{
		this->currentView->KeyDown(keyCode, isShift, isAlt, isControl);
	}

//	if (guiMain->focusElement)
//	{
//		// consumed?
//		LOGD("keyDown focusElement=%s", guiMain->focusElement->name);
//		if (guiMain->focusElement->KeyDown(keyCode, isShift, isAlt, isControl))
//		{
//			return;
//		}
//	}

	for (std::list<CGlobalKeyboardCallback *>::const_iterator itKeybardCallbacks =
			this->globalKeyboardCallbacks.begin();
			itKeybardCallbacks != this->globalKeyboardCallbacks.end();
			itKeybardCallbacks++)
	{
		CGlobalKeyboardCallback *callback =
				(CGlobalKeyboardCallback *) *itKeybardCallbacks;
		if (callback->GlobalKeyDownCallback(keyCode, isShift, isAlt, isControl) == true)
			break;

		//LOGTODO("check tracker: #ifdef WIN32 wtf?");
		/*
		 #ifdef WIN32
		 if (callback->GlobalKeyDownCallback(keyCode) == true)
		 callback->GlobalKeyPressCallback(keyCode);
		 #endif
		 */
	}
}

void CGuiMain::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiMain::KeyUp: keyCode=%d (0x%2.2x = %c) isShift=%s isAlt=%s isControl=%s", keyCode, keyCode, keyCode, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	
	UpdateControlKeys(keyCode);

	this->repeatTime = 0;
	isKeyDown = false;

//	if (this->focusElement)
//	{
//		// consumed?
//		if (this->focusElement->KeyUp(keyCode, isShiftPressed, isAltPressed, isControlPressed))
//		{
//			UpdateControlKeys(keyCode);
//			return;
//		}
//		
//		// consumed?
//		if (this->focusElement->KeyPressed(keyCode, isShiftPressed, isAltPressed, isControlPressed))
//		{
//			UpdateControlKeys(keyCode);
//			return;
//		}
//	}

	if (this->currentView != NULL)
	{
		// consumed?
		if (this->currentView->KeyUp(keyCode, isShiftPressed, isAltPressed, isControlPressed) == false)
		{
			this->currentView->KeyPressed(keyCode, isShiftPressed, isAltPressed, isControlPressed);
			UpdateControlKeys(keyCode);
//			return;
		}
	}
	
	
	for (std::list<CGlobalKeyboardCallback *>::const_iterator itKeybardCallbacks =
			this->globalKeyboardCallbacks.begin();
			itKeybardCallbacks != this->globalKeyboardCallbacks.end();
			itKeybardCallbacks++)
	{
		CGlobalKeyboardCallback *callback = (CGlobalKeyboardCallback *) *itKeybardCallbacks;
		if (callback->GlobalKeyUpCallback(keyCode, isShiftPressed, isAltPressed, isControlPressed))
			break;

#ifndef WIN32
		if (callback->GlobalKeyPressCallback(keyCode, isShiftPressed, isAltPressed, isControlPressed))
			break;
#endif

	}	
}

void CGuiMain::UpdateControlKeys(u32 keyCode)
{
	if (keyCode == MTKEY_LSHIFT)
	{
		isShiftPressed = false;
		isLeftShiftPressed = false;
	}
	else if (keyCode == MTKEY_RSHIFT)
	{
		isShiftPressed = false;
		isRightShiftPressed = false;
	}
	else if (keyCode == MTKEY_LALT)
	{
		isAltPressed = false;
		isLeftAltPressed = false;
	}
	else if (keyCode == MTKEY_RALT)
	{
		isAltPressed = false;
		isRightAltPressed = false;
	}
	else if (keyCode == MTKEY_LCONTROL)
	{
		isControlPressed = false;
		isLeftControlPressed = false;
	}
	else if (keyCode == MTKEY_RCONTROL)
	{
		isControlPressed = false;
		isRightControlPressed = false;
	}

//	if (keyCode == MTKEY_LSHIFT)
//	{
//		wasShiftPressed = false;
//	}
//	else if (keyCode == MTKEY_RSHIFT)
//	{
//		wasShiftPressed = false;
//	}
//	else if (keyCode == MTKEY_LALT)
//	{
//		wasAltPressed = false;
//	}
//	else if (keyCode == MTKEY_RALT)
//	{
//		wasAltPressed = false;
//	}
//	else if (keyCode == MTKEY_LCONTROL)
//	{
//		wasControlPressed = false;
//	}
//	else if (keyCode == MTKEY_RCONTROL)
//	{
//		wasControlPressed = false;
//	}

}

void CGuiMain::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiMain::KeyPressed: %2.2x '%c'", keyCode, keyCode);
//	if (this->focusElement)
//	{
//		// consumed?
//		if (this->focusElement->KeyPressed(keyCode, isShift, isAlt, isControl))
//		{
//			return;
//		}
//	}
	
	if (this->currentView != NULL)
	{
		this->currentView->KeyPressed(keyCode, isShift, isAlt, isControl);
	}

	for (std::list<CGlobalKeyboardCallback *>::const_iterator itKeybardCallbacks =
			this->globalKeyboardCallbacks.begin();
			itKeybardCallbacks != this->globalKeyboardCallbacks.end();
			itKeybardCallbacks++)
	{
		CGlobalKeyboardCallback *callback = (CGlobalKeyboardCallback *) *itKeybardCallbacks;
		callback->GlobalKeyPressCallback(keyCode, isShift, isAlt, isControl);
	}
}

//
// deprecated: never change engine font, always create your own in your game class
//
//void CGuiMain::SetFontDefault(CSlrFont *font) {
//	LOGM("CGuiMain::SetFontDefault: name='%s'", font->name);
//
//	//  delete yourself!
////	if (this->fntDefault != NULL)
////		delete this->fntDefault;
////
//	this->fntEngineDefault = font;
//}

void CGuiMain::SetFontMessage(CSlrFont *font, float scale)
{
	//  delete yourself!
//	if (this->fntShowMessage != NULL)
//		delete this->fntShowMessage;
//
	this->fntShowMessage = font;
	this->showMessageScale = scale;
}

void CGuiMain::RemoveAllViews()
{
	this->LockMutex();
	
	this->guiElementsDownwards.clear();
	this->guiElementsUpwards.clear();
	
	this->UnlockMutex();
}

void CGuiMain::LockRenderMutex()  //char *functionName)
{
//	LOGD("CGuiMain::LockRenderMutex: threadId=%x isLocked=%d", (u64)pthread_self(), renderMutex->isLocked);
//	NSLog(@"CGuiMain::LockRenderMutex: threadId=%x lockedLevel pre=%d (locking to %d)", (u64)pthread_self(), renderMutex->lockedLevel, renderMutex->lockedLevel+1); //, functionName);
	renderMutex->Lock();
}

void CGuiMain::UnlockRenderMutex()  //char *functionName)
{
//	LOGD("CGuiMain::UnlockRenderMutex: threadId=%x", (u64)pthread_self());
//	NSLog(@"CGuiMain::UnlockRenderMutex: threadId=%x  lockedLevel pre=%d (unlocked to %d)", (u64)pthread_self(), renderMutex->lockedLevel, renderMutex->lockedLevel-1); //, functionName);
	renderMutex->Unlock();
}

void CGuiMain::LockMutex() //char *functionName)
{
//		LOGD("CGuiMain::LockMutex");
	this->LockRenderMutex(); //functionName);
}

void CGuiMain::UnlockMutex() //char *functionName)
{
//		LOGD("CGuiMain::UnlockMutex");
	this->UnlockRenderMutex(); //functionName);
}

float SCREEN_WIDTHd2 = 0.0f;
float SCREEN_HEIGHTd2 = 0.0f;

void CLoadingResourcesCallback::LoadingResourcesStart(u32 numResourcesToLoad,
		u32 sizeOfResourcesToLoad)
{
	LOGWarning("CLoadingResourcesCallback::LoadingResourcesStart not implemented");
}

void CLoadingResourcesCallback::LoadingResourcesUpdate(float percentage)
{
	LOGWarning("CLoadingResourcesCallback::LoadingResourcesUpdate not implemented (percentage=%f)",
			percentage);
}

void CLoadingResourcesCallback::LoadingResourcesFinish()
{
	LOGWarning("CLoadingResourcesCallback::LoadingResourcesFinish not implemented");
}

void CUiThreadTaskCallback::RunUIThreadTask()
{
}

void CUiThreadTaskSetView::RunUIThreadTask()
{
	LOGD("CUiThreadTaskSetView::RunUIThreadTask");
	guiMain->SetViewAsync(this->view);
}

CUiThreadTaskSetMouseCursorVisible::CUiThreadTaskSetMouseCursorVisible(bool mouseCursorVisible)
{
	this->mouseCursorVisible = mouseCursorVisible;
}
	
void CUiThreadTaskSetMouseCursorVisible::RunUIThreadTask()
{
//	LOGD(" CUiThreadTaskSetMouseCursorVisible::RunUIThreadTask");
	if (mouseCursorVisible)
	{
		VID_ShowMouseCursor();
	}
	else
	{
		VID_HideMouseCursor();
	}
	
	guiMain->isMouseCursorVisible = mouseCursorVisible;
}

CUiThreadTaskSetFullScreen::CUiThreadTaskSetFullScreen(bool isFullScreen)
{
	this->isFullScreen = isFullScreen;
}
	
void CUiThreadTaskSetFullScreen::RunUIThreadTask()
{
	VID_SetWindowFullScreen(isFullScreen);
}

CUiThreadTaskSetAlwaysOnTop::CUiThreadTaskSetAlwaysOnTop(bool isAlwaysOnTop)
{
	this->isAlwaysOnTop = isAlwaysOnTop;
}
	
void CUiThreadTaskSetAlwaysOnTop::RunUIThreadTask()
{
	VID_SetWindowAlwaysOnTop(isAlwaysOnTop);
}
