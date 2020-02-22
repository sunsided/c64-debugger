/*
 *  CGuiViewMessageBox.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-09-03.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiViewMessageBox.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "GuiConsts.h"

bool CGuiMessageBoxCallback::MessageBoxClickedOK(CGuiViewMessageBox *messageBox)
{
	return false;
}

CGuiViewMessageBox::CGuiViewMessageBox(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, UTFString *message, CGuiMessageBoxCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewMessageBox";
	this->callback = callback;
		
	GLfloat sw2 = sizeX / 2;
	GLfloat sh3 = sizeY / 4;
	
//	btnOK = new CGuiButton("OK", sw2 - (guiButtonSizeX/2), posEndY - (guiButtonSizeY*2 + guiButtonGapY), posZ + 0.04, 
//							 guiButtonSizeX, guiButtonSizeY, BUTTON_ALIGNED_DOWN, this);
	btnOK = new CGuiButton("OK", sw2 - (guiButtonSizeX), posEndY - (guiButtonSizeY*2 + guiButtonGapY*4), posZ + 0.04, 
						   guiButtonSizeX*2, guiButtonSizeY*2, BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnOK);
		
	this->messageLine1 = NULL;
	this->messageLine2 = NULL;
	this->messageLine3 = NULL;
	this->messageLine4 = NULL;
	this->SetText(message);
}

CGuiViewMessageBox::~CGuiViewMessageBox()
{
}

void CGuiViewMessageBox::SetText(UTFString *message)
{
#ifdef IOS
	if (this->messageLine1 != NULL)
	{
		[this->messageLine1 release];
		//delete this->messageLine1;
		if (this->messageLine2 != NULL)
		{
			[this->messageLine2 release];
			//delete this->messageLine2;
			if (this->messageLine3 != NULL)
			{
				[this->messageLine3 release];
				//delete this->messageLine3;
				if (this->messageLine4 != NULL)
				{
					[this->messageLine4 release];
					//delete this->messageLine4;
				}
			}
		}
		this->messageLine1 = NULL;
		this->messageLine2 = NULL;
		this->messageLine3 = NULL;
		this->messageLine4 = NULL;
	}
#endif

	/*
	TODO:
	if (message != NULL)
	{
		this->messageLine1 = message;
		CSlrFontSystem::Size size = guiMain->sfntDefault->GetTextSize(message, 1.0);
		
		GLfloat sw2 = sizeX / 2;
		GLfloat sh3 = sizeY / 4;
		
		textPosX = sw2;// - (size.width / 2);
		textPosY = sh3 - (size.height / 2);	
	}*/

}

void CGuiViewMessageBox::DoLogic()
{
	CGuiView::DoLogic();
}


void CGuiViewMessageBox::Render()
{
	/*
	TODO:
	if (this->messageLine1 != NULL)
	{
		guiMain->sfntDefault->BlitText(this->messageLine1, 
									   textPosX, textPosY, posZ,
									   1.0, 1.0, 1.0, 1.0,
									   FONT_ALIGN_CENTER, 1.0);
	}*/


	CGuiView::Render();
}

void CGuiViewMessageBox::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

/*
 void CGuiViewMessageBox::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
 {
 CGuiView::Render(posX, posY, sizeX, sizeY);
 }
 */

bool CGuiViewMessageBox::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CGuiViewMessageBox::ButtonPressed(CGuiButton *button)
{
	if (button == btnOK)
	{
		if (this->callback)
		{
			this->callback->MessageBoxClickedOK(this);
		}
		else 
		{
			guiMain->SetView((CGuiView*)guiMain->guiMainView);
		}
		GUI_SetPressConsumed(true);
		return true;			
	}
	
	return false;
}


//@returns is consumed
bool CGuiViewMessageBox::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMessageBox::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CGuiViewMessageBox::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMessageBox::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CGuiViewMessageBox::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMessageBox::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CGuiViewMessageBox::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewMessageBox::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CGuiViewMessageBox::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiViewMessageBox::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CGuiViewMessageBox::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CGuiViewMessageBox::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}


void CGuiViewMessageBox::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CGuiViewMessageBox::ActivateView()
{
	LOGG("CGuiView::ActivateView()");
}

void CGuiViewMessageBox::DeactivateView()
{
	LOGG("CGuiViewMessageBox::DeactivateView()");
}

