#include "CViewC64AllSIDs.h"
#include "CViewC64.h"
#include "VID_GLViewController.h"
#include "C64DebugInterface.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64VicControl.h"
#include "CViewDataDump.h"
#include "CViewMemoryMap.h"
#include "C64Tools.h"
#include "CGuiMain.h"
#include "CViewDataDump.h"
#include "CGuiLockableList.h"
#include "CSlrString.h"
#include "CViewSIDTrackerHistory.h"
#include "CViewDisassemble.h"
#include "CViewDataDump.h"
#include "SYS_KeyCodes.h"

CViewC64AllSIDs::CViewC64AllSIDs(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64AllSIDs";
	this->debugInterface = debugInterface;
	
	this->consumeTapBackground = false;
	this->allowFocus = false;
	
	viewTrackerHistory = new CViewSIDTrackerHistory(2, 0, -1, 319, 139, (C64DebugInterfaceVice*)debugInterface);
	this->AddGuiElement(viewTrackerHistory);

	viewPianoKeyboard = new CSIDPianoKeyboard(2, 147, -1, 450, 50, viewTrackerHistory);
	this->AddGuiElement(viewPianoKeyboard);
}

CViewC64AllSIDs::~CViewC64AllSIDs()
{
}

void CViewC64AllSIDs::SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn)
{
	btn->buttonSwitchOffColorR = 0.0f;
	btn->buttonSwitchOffColorG = 0.0f;
	btn->buttonSwitchOffColorB = 0.0f;
	btn->buttonSwitchOffColorA = 1.0f;
	
	btn->buttonSwitchOffColor2R = 0.3f;
	btn->buttonSwitchOffColor2G = 0.3f;
	btn->buttonSwitchOffColor2B = 0.3f;
	btn->buttonSwitchOffColor2A = 1.0f;
	
	btn->buttonSwitchOnColorR = 0.0f;
	btn->buttonSwitchOnColorG = 0.7f;
	btn->buttonSwitchOnColorB = 0.0f;
	btn->buttonSwitchOnColorA = 1.0f;
	
	btn->buttonSwitchOnColor2R = 0.3f;
	btn->buttonSwitchOnColor2G = 0.3f;
	btn->buttonSwitchOnColor2B = 0.3f;
	btn->buttonSwitchOnColor2A = 1.0f;
	
}

void CViewC64AllSIDs::SetLockableButtonDefaultColors(CGuiButtonSwitch *btn)
{
	btn->buttonSwitchOffColorR = 0.0f;
	btn->buttonSwitchOffColorG = 0.0f;
	btn->buttonSwitchOffColorB = 0.0f;
	btn->buttonSwitchOffColorA = 1.0f;
	
	btn->buttonSwitchOffColor2R = 0.3f;
	btn->buttonSwitchOffColor2G = 0.3f;
	btn->buttonSwitchOffColor2B = 0.3f;
	btn->buttonSwitchOffColor2A = 1.0f;
	
	btn->buttonSwitchOnColorR = 0.7f;
	btn->buttonSwitchOnColorG = 0.0f;
	btn->buttonSwitchOnColorB = 0.0f;
	btn->buttonSwitchOnColorA = 1.0f;
	
	btn->buttonSwitchOnColor2R = 0.3f;
	btn->buttonSwitchOnColor2G = 0.3f;
	btn->buttonSwitchOnColor2B = 0.3f;
	btn->buttonSwitchOnColor2A = 1.0f;
	
}


void CViewC64AllSIDs::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewC64AllSIDs::Render()
{
//	LOGD("ALL SIDS RENDER");

	this->DoLogic();
	
	viewPianoKeyboard->Render();
	viewTrackerHistory->Render();
	
	// TODO: temporary hack, hide overlapping views when there are 3 sids, remove this in ImGui branch
	if (debugInterface->GetNumSids() < 3)
	{
//		LOGD("show overlapping views");
		viewC64->viewC64Disassemble->visible = true;
		viewC64->viewC64MemoryMap->visible = true;
		viewC64->viewC64MemoryDataDump->SetPosition(458, 100, -1, SCREEN_WIDTH - 110.0f, 135.0f, false);
	}
	else
	{
//		LOGD("hide overlapping views");
		viewC64->viewC64Disassemble->visible = false;
		viewC64->viewC64MemoryMap->visible = false;
		viewC64->viewC64MemoryDataDump->SetPosition(458, 100, -1, SCREEN_WIDTH - 110.0f, 95.0f, false);
	}
	
	CGuiView::Render();	
}

void CViewC64AllSIDs::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewC64AllSIDs::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64AllSIDs::DoTap:  x=%f y=%f", x, y);
	
	return CGuiView::DoTap(x, y);
}

bool CViewC64AllSIDs::SetFocus(CGuiElement *view)
{
	LOGD("CViewC64AllSIDs::SetFocus: view=%s", view->name);
	return viewC64->SetFocus(view);
}

bool CViewC64AllSIDs::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	return false;
}


bool CViewC64AllSIDs::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewC64AllSIDs::ButtonPressed(CGuiButton *button)
{
	LOGD("CViewC64AllSIDs::ButtonPressed");
	
	return false;
}

bool CViewC64AllSIDs::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	LOGD("CViewC64AllSIDs::ButtonSwitchChanged");
	
	return false;
}

/*
bool CViewC64AllSIDs::ListElementPreSelect(CGuiList *listBox, int elementNum)
{
	LOGD("CViewC64AllSIDs::ListElementPreSelect");
	guiMain->LockMutex();
	
//	CGuiLockableList *list = (CGuiLockableList*)listBox;
//	
//	if (list->isLocked)
//	{
//		// click on the same element - unlock
//		if (list->selectedElement == elementNum)
//		{
//			list->SetListLocked(false);
//			guiMain->UnlockMutex();
//			return true;
//		}
//	}
//	
//	list->SetListLocked(true);
	
	guiMain->UnlockMutex();
	
	return true;
}
*/

bool CViewC64AllSIDs::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64AllSIDs::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewC64AllSIDs::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64AllSIDs::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewC64AllSIDs::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64AllSIDs::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewC64AllSIDs::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64AllSIDs::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewC64AllSIDs::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64AllSIDs::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewC64AllSIDs::DoScrollWheel(float deltaX, float deltaY)
{
	return CGuiView::DoScrollWheel(deltaX, deltaY);
}

bool CViewC64AllSIDs::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewC64AllSIDs::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewC64AllSIDs::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewC64AllSIDs::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewC64AllSIDs::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD("CViewC64AllSIDs::KeyDown: keyCode=%x", keyCode);
	if (keyCode == MTKEY_ARROW_UP || keyCode == MTKEY_ARROW_DOWN
		|| keyCode == MTKEY_SPACEBAR)
	{
		return viewTrackerHistory->KeyDown(keyCode, isShift, isAlt, isControl);
	}
	
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64AllSIDs::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewC64AllSIDs::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewC64AllSIDs::ActivateView()
{
	LOGG("CViewC64AllSIDs::ActivateView()");
}

void CViewC64AllSIDs::DeactivateView()
{
	LOGG("CViewC64AllSIDs::DeactivateView()");
}
