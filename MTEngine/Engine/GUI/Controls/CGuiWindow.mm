#include "CGuiWindow.h"
#include "CGuiViewWindowsManager.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "SYS_Threading.h"
#include "VID_ImageBinding.h"
#include <list>

CGuiWindow::CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   CSlrString *windowName)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	if (windowName != NULL)
	{
		this->Initialize(posX, posY, posZ, sizeX, sizeY, windowName, GUI_FRAME_MODE_WINDOW, NULL);
	}
	else
	{
		this->Initialize(posX, posY, posZ, sizeX, sizeY, windowName, GUI_FRAME_NO_FRAME, NULL);
	}
}

CGuiWindow::CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   CSlrString *windowName, CGuiWindowCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	if (windowName != NULL)
	{
		this->Initialize(posX, posY, posZ, sizeX, sizeY, windowName, GUI_FRAME_MODE_WINDOW, callback);
	}
	else
	{
		this->Initialize(posX, posY, posZ, sizeX, sizeY, windowName, GUI_FRAME_NO_FRAME, callback);
	}
}


CGuiWindow::CGuiWindow(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   CSlrString *windowName, u32 mode, CGuiWindowCallback *callback)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->Initialize(posX, posY, posZ, sizeX, sizeY, windowName, mode, callback);
}

void CGuiWindow::Initialize(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						CSlrString *windowName, u32 mode, CGuiWindowCallback *callback)
{
	if (windowName != NULL)
	{
		char *buf = SYS_GetCharBuf();
		char *bufName = windowName->GetStdASCII();
		sprintf(buf, "CGuiWindow (%s)", bufName);
		this->name = STRALLOC(buf);
		delete [] bufName;
		SYS_ReleaseCharBuf(buf);
	}
	else
	{
		this->name = STRALLOC("CGuiWindow");
	}
	
	this->callback = callback;
	
	if (IS_SET(mode, GUI_FRAME_HAS_FRAME))
	{
		viewFrame = new CGuiViewFrame(this, windowName, mode);
		this->AddGuiElement(viewFrame);
	}
	else
	{
		viewFrame = NULL;
	}
}

void CGuiWindow::SetSize(GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetSize(sizeX, sizeY);
	
	if (viewFrame)
	{
		this->viewFrame->SetSize(sizeX, sizeY);
	}
}

void CGuiWindow::SetPosition(GLfloat posX, GLfloat posY)
{
	LOGD("CGuiWindow::SetPosition: %f %f (sizeX=%f sizeY=%f)", posX, posY, this->sizeX, this->sizeY);
	
	CGuiView::SetPosition(posX, posY);
}

void CGuiWindow::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	LOGD("CGuiWindow::SetPosition: %f %f %f %f", posX, posY, sizeX, sizeY);
	
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CGuiWindow::DoLogic()
{
	CGuiView::DoLogic();
}

void CGuiWindow::Render()
{
//	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, backgroundColorR, backgroundColorG, backgroundColorB, backgroundColorA);
	
	CGuiView::Render();
	
	if (viewFrame)
	{
		BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0, 0, 0, 1, 1);
	}
}

bool CGuiWindow::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiWindow::DoTap: %f %f", x, y);
	
	if (viewFrame)
	{
		if (viewFrame->DoTap(x, y) == false)
		{
			if (CGuiView::DoTap(x, y) == false)
			{
				if (this->IsInsideView(x, y))
				{
					return true;
				}
			}
		}
	}
	
	return CGuiView::DoTap(x, y);;
}

bool CGuiWindow::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}


bool CGuiWindow::DoRightClick(GLfloat x, GLfloat y)
{
	LOGI("CGuiWindow::DoRightClick: %f %f", x, y);
	
	return CGuiView::DoRightClick(x, y);
}


void CGuiWindow::ActivateView()
{
}

void CGuiWindow::RenderWindowBackground()
{
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, viewFrame->barColorR, viewFrame->barColorG, viewFrame->barColorB, 1);
}

void CGuiWindow::WindowCloseButtonPressed()
{
	LOGD("CGuiWindow::WindowCloseButtonPressed");
	
	if (this->callback)
	{
		if (this->callback->GuiWindowCallbackWindowClose(this))
		{
			return;
		}
	}
	
	if (this->parent)
	{
		CGuiViewWindowsManager *parentView = (CGuiViewWindowsManager*)this->parent;
		parentView->HideWindow(this);
	}
}

bool CGuiWindowCallback::GuiWindowCallbackWindowClose(CGuiWindow *window)
{
	// do not cancel close
	return false;
}

