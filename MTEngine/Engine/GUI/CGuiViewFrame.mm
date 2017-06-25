#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "CGuiViewFrame.h"
#include "CViewC64.h"
#include "CSlrString.h"
#include "CGuiMain.h"

CGuiViewFrame::CGuiViewFrame(CGuiView *view, CSlrString *barTitle)
: CGuiView(view->posX, view->posY, view->posZ, view->sizeX, view->sizeY)
{
	this->view = view;
	this->view->bringToFrontOnTap = true;
	
	this->barTitle = barTitle;
	
	char *buf = SYS_GetCharBuf();
	char *t = barTitle->GetStdASCII();
	sprintf(buf, "CGuiViewFrame (%s)", t);
	
	this->name = STRALLOC(buf);
	
	SYS_ReleaseCharBuf(buf);
	delete [] t;
	
	barHeight = 13.0f;
	frameWidth = 5.0f;
	
	barColorR = 58.0f/255.0f;
	barColorG = 57.0f/255.0f;
	barColorB = 57.0f/255.0f;
	barColorA = 1.0f;
	
	barTextColorR = 147.0f/255.0f;
	barTextColorG = 147.0f/255.0f;
	barTextColorB = 147.0f/255.0f;
	barTextColorA = 1.0f;
	
	fontSize = 1.5f;
	
	barFont = viewC64->fontCBMShifted;
	
	movingView = false;

}

void CGuiViewFrame::SetBarTitle(CSlrString *newBarTitle)
{
	guiMain->LockMutex();
	
	delete this->barTitle;
	this->barTitle = newBarTitle;
	
	guiMain->UnlockMutex();
}

bool CGuiViewFrame::IsInside(GLfloat x, GLfloat y)
{
	if (x >= (view->posX - frameWidth) && x <= (view->posEndX + frameWidth)
		&& y >= (view->posY - barHeight) && y <= (view->posEndY + frameWidth))
	{
		return true;
	}
	
	return false;
}

bool CGuiViewFrame::DoTap(GLfloat x, GLfloat y)
{
	if (IsInsideSurroundingFrame(x, y))
	{
		movingView = true;
		return true;
	}
	
	return false;
}

bool CGuiViewFrame::DoRightClick(GLfloat x, GLfloat y)
{
	if (IsInsideSurroundingFrame(x, y))
	{
		return true;
	}
	
	return false;
}

bool CGuiViewFrame::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiViewFrame::DoFinishTap()");
	
	if (movingView)
	{
		movingView = false;
		return true;
	}
	
	return false;
}

bool CGuiViewFrame::IsInsideSurroundingFrame(float x, float y)
{
	if (
			(
				x >= (view->posX - frameWidth) && x < (view->posX)
				&& y >= (view->posY - barHeight) && y < (view->posEndY + frameWidth)
				
			 )
			||
			(
				x >= (view->posEndX)           && x <= (view->posEndX + frameWidth)
				&& y >= (view->posY - barHeight) && y < (view->posEndY + frameWidth)
			 )
			||
			(
				x >= (view->posX - frameWidth) && x <= (view->posEndX + frameWidth)
				&& y >= (view->posEndY)           && y <= (view->posEndY + frameWidth)
			 )
			||
			(
				x >= (view->posX - frameWidth) && x <= (view->posEndX + frameWidth)
				&& y >= (view->posY - barHeight)  && y <= view->posY
				
			 )
		)
	{
		return true;
	}
	
	return false;
}

bool CGuiViewFrame::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	LOGD("CGuiViewFrame::DoMove: movingView=%d diffX=%f diffY=%f", movingView, diffX, diffY);
	
	if (IsInsideSurroundingFrame(x, y))
	{
		movingView = true;
	}
	
	if (movingView)
	{
//		LOGD(".... prev pos=%f %f new pos=%f %f", view->posX, view->posY, view->posX + diffX, view->posY + diffY);
		view->SetPosition(view->posX + diffX, view->posY + diffY);
		return true;
	}
	return false;
}

bool CGuiViewFrame::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (movingView)
	{
		movingView = false;
		return true;
	}
	
	return false;
}


bool CGuiViewFrame::DoDoubleTap(GLfloat x, GLfloat y)
{
	return false;
}
bool CGuiViewFrame::DoFinishDoubleTap(GLfloat posX, GLfloat posY)
{
	return false;	
}

void CGuiViewFrame::Render()
{
//	LOGG("CGuiViewFrame::Render: %s", this->name);
	
	BlitRectangle(view->posX, view->posY, view->posZ, view->sizeX, view->sizeY, barColorR, barColorG, barColorB, barColorA, frameWidth);
	
	BlitFilledRectangle(view->posX-frameWidth, view->posY-barHeight, view->posZ, view->sizeX+frameWidth*2.0f, barHeight, barColorR, barColorG, barColorB, barColorA);
	
	barFont->BlitTextColor(this->barTitle, view->posX, view->posY-barHeight+frameWidth*0.75f, view->posZ, fontSize,
						   barTextColorR, barTextColorG, barTextColorB, barTextColorA);

	BlitRectangle(view->posX-frameWidth, view->posY-barHeight, view->posZ, view->sizeX+frameWidth*2.0f, view->sizeY+barHeight+frameWidth, 0, 0, 0, 1, 1);

	//LOGD("movingView=%x", movingView);
}

void CGuiViewFrame::Render(GLfloat posX, GLfloat posY)
{
	
	LOGD("CGuiViewFrame::Render %f %f", posX, posY);

	BlitRectangle(posX, posY, this->posZ, this->sizeX, this->sizeY, 0.0f, 0.0f, 1.0f, 1.0f);

}

void CGuiViewFrame::DoLogic()
{
	// NO DO LOGIC
	LOGD("movingView=%x", movingView);
}

