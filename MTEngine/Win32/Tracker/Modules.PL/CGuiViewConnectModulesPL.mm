/*
 *  CGuiViewConnectModulesPL.mm
 *  MusicTracker
 *
 *  Created by Marcin Skoczylas on 11-01-11.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#include "CGuiViewConnectModulesPL.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CViewTrackerMain.h"

void GUI_ShowModulesPLView()
{
}

void GUI_HideModulesPLView()
{
}

CGuiViewConnectModulesPL::CGuiViewConnectModulesPL(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewConnectModulesPL";
	
	//btnDone = new CGuiButton("DONE", posEndX - (guiButtonSizeX + guiButtonGapX), 
	//						 posEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04, 
	//						 guiButtonSizeX, guiButtonSizeY, 
	//						 BUTTON_ALIGNED_DOWN, this);
	//this->AddGuiElement(btnDone);	
}

CGuiViewConnectModulesPL::~CGuiViewConnectModulesPL()
{
}

void CGuiViewConnectModulesPL::DoLogic()
{
	CGuiView::DoLogic();
}


//@returns is consumed
bool CGuiViewConnectModulesPL::DoTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiViewConnectModulesPL::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CGuiViewConnectModulesPL::DoFinishTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiViewConnectModulesPL::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewConnectModulesPL::DoDoubleTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiViewConnectModulesPL::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewConnectModulesPL::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiViewConnectModulesPL::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CGuiViewConnectModulesPL::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiViewConnectModulesPL::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewConnectModulesPL::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CGuiViewConnectModulesPL::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue)
{
	return CGuiView::DoZoomBy(x, y, zoomValue);
}


void CGuiViewConnectModulesPL::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CGuiViewConnectModulesPL::ActivateView()
{
	LOGD("CGuiViewConnectModulesPL::ActivateView()");
	GUI_ShowModulesPLView();	
}

void CGuiViewConnectModulesPL::DeactivateView()
{
	//LOGG("CGuiViewConnectModulesPL::DeactivateView()");
}

void CGuiViewConnectModulesPL::Render()
{
	//guiMain->fntConsole->BlitText("CGuiViewConnectModulesPL", 0, 0, 0, 11, 1.0);
	
	//CGuiView::Render();
}

void CGuiViewConnectModulesPL::Render(GLfloat posX, GLfloat posY)
{
	//CGuiView::Render(posX, posY);
}

/*
bool CGuiViewConnectModulesPL::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CGuiViewConnectModulesPL::ButtonPressed(CGuiButton *button)
{
	if (button == btnDone)
	{
		guiMain->SetView((CGuiView*)guiMain->viewMainEditor);
		GUI_SetPressConsumed(true);
		return true;
	}
	
	return false;
}
*/

/*
 void CGuiViewConnectModulesPL::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
 {
 CGuiView::Render(posX, posY, sizeX, sizeY);
 }
 */