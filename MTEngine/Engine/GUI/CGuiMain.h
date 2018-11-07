/*
 *  GuiStartup.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _GUI_STARTUP_
#define _GUI_STARTUP_

#define GAP_WIDTH 2

#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "CSlrImage.h"
#include "CSlrFontBitmap.h"
#include "CGuiElement.h"
#include "CGuiButtonMenu.h"
#include "CGuiButtonText.h"
#include "CGuiView.h"
#include "CGuiViewMessageBox.h"

#include "CGuiTheme.h"
#include "CGlobalKeyboardCallback.h"
#include "CGlobalLogicCallback.h"
#include "CGlobalOSWindowChangedCallback.h"
#include "CConfigStorage.h"

#include "RES_ResourceManager.h"
#include "SYS_Threading.h"

#include <list>
#include <map>

extern CConfigStorage *globalConfig;

class CGuiViewBaseLoadingScreen;
class CGuiViewBaseResourceManager;

class CViewC64;
class CViewC64Demo;


class CViewLoaderThread;

class COneTouchData;

class GLES1DebugDraw;

extern float SCREEN_WIDTHd2;
extern float SCREEN_HEIGHTd2;

// for ADs
extern float gHudLevelOffsetY;

class CGuiMain : public CGuiButtonCallback, public CGuiMessageBoxCallback
{
public:
	CGuiMain();
	void Startup();
	void RemoveAllViews();
	void Render();
	void DoLogic();

	bool DoTap(GLfloat x, GLfloat y);
	bool DoFinishTap(GLfloat x, GLfloat y);

	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	void DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	void FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	bool DoRightClick(GLfloat x, GLfloat y);
	bool DoFinishRightClick(GLfloat x, GLfloat y);
	void DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	void FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	void DoNotTouchedMove(GLfloat x, GLfloat y);

	void InitZoom();
	void DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	void DoScrollWheel(float deltaX, float deltaY);
	
	// multi touch
	bool DoSystemMultiTap(u64 systemTapId, float x, float y);
	bool DoSystemMultiMove(u64 systemTapId, float x, float y);
	bool DoSystemMultiFinishTap(u64 systemTapId, float x, float y);
	bool DoMultiTap(COneTouchData *touch, float x, float y);
	bool DoMultiMove(COneTouchData *touch, float x, float y);
	bool DoMultiFinishTap(COneTouchData *touch, float x, float y);
	
	void FinishTouches();

	COneTouchData *touches[MAX_MULTI_TOUCHES];
	std::list<COneTouchData *> touchesNotActive;
	std::map<u64, COneTouchData *> touchesBySystemTapId;
	
	std::list<CGlobalKeyboardCallback *> globalKeyboardCallbacks;
	void AddGlobalKeyboardCallback(CGlobalKeyboardCallback *callback);
	void RemoveGlobalKeyboardCallback(CGlobalKeyboardCallback *callback);
	void ClearGlobalKeyboardCallbacks();

	std::list<CGlobalLogicCallback *> globalLogicCallbacks;
	void AddGlobalLogicCallback(CGlobalLogicCallback *callback);
	void RemoveGlobalLogicCallback(CGlobalLogicCallback *callback);
	void ClearGlobalLogicCallbacks();
	
	std::list<CGlobalOSWindowChangedCallback *> globalOSWindowChangedCallbacks;
	void AddGlobalOSWindowChangedCallback(CGlobalOSWindowChangedCallback *callback);
	void RemoveGlobalOSWindowChangedCallback(CGlobalOSWindowChangedCallback *callback);
	void ClearGlobalOSWindowChangedCallbacks();
	void NotifyGlobalOSWindowChangedCallbacks();

#if defined(USE_DEBUGSCREEN)
	CDebugScreen *debugScreen;
#endif
	
	CViewC64 *viewC64;
	CViewC64Demo *viewC64Demo;

	CGuiTheme *theme;

	CGuiElement *focusElement;

	CSlrFontBitmap *fntConsole;
	CSlrImage *imgConsoleFonts;
	CSlrFontBitmap *fntConsoleInverted;
	CSlrImage *imgConsoleInvertedFonts;
	//CSlrImage *imgRabLogo;

	CSlrImage *imgFontDefault;
	CSlrFont *fntEngineDefault;

	CSlrImage *imgFontShowMessage;
	CSlrFont *fntShowMessage;
	GLfloat showMessageScale;

	// deprecated: never change engine font, always create your own in your game class
//	void SetFontDefault(CSlrFont *font);
	void SetFontMessage(CSlrFont *font, float scale);

	// forced window on top
	CGuiElement *windowOnTop;
	void SetWindowOnTop(CGuiElement *element);

	// forced top view
	CGuiElement *viewOnTop;
	void SetViewOnTop(CGuiElement *element);

	CGuiView *guiMainView;
	CGuiView *currentView;
	
	// set as current view
	void SetView(CGuiView *element);

	// load resources and set as current view
	volatile bool isLoadingResources;
	void LoadAndSetView(CGuiView *element);
	CGuiViewBaseLoadingScreen *viewLoadingScreen;
	
	CGuiViewBaseResourceManager *viewResourceManager;
	void StartResourceManager();
	
	bool IsMainView(CGuiView *view);
	
	//void ShowMessage(const UTFString *popMessage);
	//void ShowMessage(const UTFString *popMessage, GLfloat showMessageColorR, GLfloat showMessageColorG, GLfloat showMessageColorB);
	void ShowMessage(CSlrString *showMessage);
	void ShowMessage(char *popMessage);
	void ShowMessageAsync(char *popMessage);
	void ShowMessage(char *popMessage, GLfloat showMessageColorR, GLfloat showMessageColorG, GLfloat showMessageColorB);
	void ShowMessageAsync(char *popMessage, GLfloat showMessageColorR, GLfloat showMessageColorG, GLfloat showMessageColorB);
	void StopShowingMessage();

	CGuiViewMessageBox *messageBox;
	CGuiMessageBoxCallback *messageBoxCallback;
	void ShowMessageBox(UTFString *text, CGuiMessageBoxCallback *messageBoxCallback);
	bool MessageBoxClickedOK(CGuiViewMessageBox *messageBox);

	class compareZupwards
	{
		// simple comparison function
	public:
		bool operator()(const float z1, const float z2) const
		{
			return z1 < z2; //(x-y)>0;
		}
	};

	class compareZdownwards
	{
		// simple comparison function
	public:
		bool operator()(const float z1, const float z2) const
		{
			return z1 > z2; //(x-y)>0;
		}
	};


	std::map<float, CGuiElement *, compareZupwards> guiElementsUpwards;
	std::map<float, CGuiElement *, compareZdownwards> guiElementsDownwards;

	float lastZ;
	void AddGuiElement(CGuiElement *guiElement);
	void AddGuiElement(CGuiElement *guiElement, float z);
//	void RemoveGuiElement(CGuiElement *guiElement);

	// for keyboard events:
	void SetFocus(CGuiElement *element);

	void KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	void KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	u32 repeatTime;
	bool isKeyDown;
	void KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats

	volatile bool isShiftPressed;
	volatile bool isControlPressed;
	volatile bool isAltPressed;

//	volatile bool wasShiftPressed;
//	volatile bool wasControlPressed;
//	volatile bool wasAltPressed;

	volatile bool isLeftShiftPressed;
	volatile bool isLeftControlPressed;
	volatile bool isLeftAltPressed;

	volatile bool isRightShiftPressed;
	volatile bool isRightControlPressed;
	volatile bool isRightAltPressed;

	void UpdateControlKeys(u32 keyCode);
	
	void LockRenderMutex(); //char *functionName);
	void UnlockRenderMutex(); //char *functionName);

	void LockMutex(); //char *functionName);
	void UnlockMutex(); //char *functionName);

	float mousePosX, mousePosY;

private:
	CSlrMutex *renderMutex;

	volatile GLfloat showMessageCurrentScale;
	volatile GLfloat showMessageAlpha;
	char *showMessage;
	u16 showMessageLen;
	volatile GLfloat showMessageColorR;
	volatile GLfloat showMessageColorG;
	volatile GLfloat showMessageColorB;

	CViewLoaderThread *threadViewLoader;
	
	// temporary walkaround
	volatile bool isTapping;
	
};

class CViewLoaderThread : public CSlrThread
{
public:
	virtual void ThreadRun(void *data);
};

class CLoadingResourcesCallback
{
public:
	virtual void LoadingResourcesStart(u32 numResourcesToLoad, u32 sizeOfResourcesToLoad);
	virtual void LoadingResourcesUpdate(float percentage);
	virtual void LoadingResourcesFinish();
};
			
extern CGuiMain *guiMain;

#endif

