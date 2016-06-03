#include "CGuiViewDummy.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"

CGuiViewDummy::CGuiViewDummy(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewDummy";
	
	/*btnDone = new CGuiButton("DONE", posEndX - (guiButtonSizeX + guiButtonGapX), 
							 posEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04, 
							 guiButtonSizeX, guiButtonSizeY, 
							 BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnDone);	
	 */
}

CGuiViewDummy::~CGuiViewDummy()
{
}

void CGuiViewDummy::DoLogic()
{
	CGuiView::DoLogic();
}

void CGuiViewDummy::Render()
{
	guiMain->fntConsole->BlitText("CGuiViewDummy", 0, 0, 0, 11, 1.0);

	CGuiView::Render();
}

void CGuiViewDummy::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CGuiViewDummy::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CGuiViewDummy::ButtonPressed(CGuiButton *button)
{
	/*
	if (button == btnDone)
	{
		guiMain->SetView((CGuiView*)guiMain->viewMainEditor);
		GUI_SetPressConsumed(true);
		return true;
	}
	*/
	return false;
}

//@returns is consumed
bool CGuiViewDummy::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDummy::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CGuiViewDummy::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDummy::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewDummy::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDummy::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewDummy::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewDummy::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CGuiViewDummy::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiViewDummy::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewDummy::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CGuiViewDummy::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CGuiViewDummy::DoScrollWheel(float deltaX, float deltaY)
{
	return CGuiView::DoScrollWheel(deltaX, deltaY);
}

bool CGuiViewDummy::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CGuiViewDummy::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CGuiViewDummy::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CGuiViewDummy::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CGuiViewDummy::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CGuiViewDummy::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CGuiViewDummy::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CGuiViewDummy::ActivateView()
{
	LOGG("CGuiViewDummy::ActivateView()");
}

void CGuiViewDummy::DeactivateView()
{
	LOGG("CGuiViewDummy::DeactivateView()");
}
