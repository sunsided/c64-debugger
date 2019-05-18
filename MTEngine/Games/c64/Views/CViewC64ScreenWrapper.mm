#include "CViewC64ScreenWrapper.h"
#include "CColorsTheme.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "VID_ImageBinding.h"
#include "CViewC64.h"
#include "SYS_KeyCodes.h"
#include "C64DebugInterface.h"
#include "C64SettingsStorage.h"
#include "C64ColodoreScreen.h"
#include "C64KeyboardShortcuts.h"
#include "CViewC64Screen.h"
#include "CViewC64VicDisplay.h"

CViewC64ScreenWrapper::CViewC64ScreenWrapper(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64ScreenWrapper";
	
	this->debugInterface = debugInterface;
	
	selectedScreenMode = C64SCREENWRAPPER_MODE_C64_SCREEN;
}

CViewC64ScreenWrapper::~CViewC64ScreenWrapper()
{
}

void CViewC64ScreenWrapper::DoLogic()
{
//	CGuiView::DoLogic();
}

void CViewC64ScreenWrapper::Render()
{
//	LOGD("CViewC64ScreenWrapper::Render");

	if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_SCREEN)
	{
		viewC64->viewC64Screen->Render();
	}
	else if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_DISPLAY)
	{
		VID_SetClipping(posX, posY, sizeX, sizeY);
		viewC64->viewC64VicDisplay->Render();
		VID_ResetClipping();
	}
}

void CViewC64ScreenWrapper::RenderRaster(int rasterX, int rasterY)
{
	if (viewC64->isShowingRasterCross &&
		(selectedScreenMode == C64SCREENWRAPPER_MODE_C64_SCREEN
		 || selectedScreenMode == C64SCREENWRAPPER_MODE_C64_DISPLAY))
	{
		viewC64->viewC64Screen->RenderRaster(rasterX, rasterY);
	}
	
	if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_ZOOMED)
	{
		viewC64->viewC64Screen->RenderZoomedScreen(rasterX, rasterY);
	}

}


void CViewC64ScreenWrapper::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	UpdateC64ScreenPosition();
}

void CViewC64ScreenWrapper::UpdateC64ScreenPosition()
{
	if (viewC64->currentScreenLayoutId == SCREEN_LAYOUT_C64_VIC_DISPLAY
		&& this->selectedScreenMode == C64SCREENWRAPPER_MODE_C64_DISPLAY)
	{
		this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_SCREEN);
	}
	
	if (viewC64->currentScreenLayoutId == SCREEN_LAYOUT_C64_CYCLER
		&& this->selectedScreenMode == C64SCREENWRAPPER_MODE_C64_ZOOMED)
	{
		this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_SCREEN);
	}
	
	viewC64->viewC64Screen->SetPosition(posX, posY, posZ, sizeX, sizeY);
	viewC64->viewC64Screen->UpdateRasterCrossFactors();
	
	if (viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_VIC_DISPLAY)
	{
		float scaleFactor = 1.35995; //1.575f;
		
		float scale = scaleFactor * sizeX / (float)debugInterface->GetScreenSizeX();
		float offsetX = -24.23*scale;
		float offsetY = 0;
		viewC64->viewC64VicDisplay->SetDisplayPosition(posX + offsetX, posY + offsetY, scale, false);
		
		viewC64->viewC64VicDisplay->SetShowDisplayBorderType(VIC_DISPLAY_SHOW_BORDER_VISIBLE_AREA);
	}

	if (viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM
		&& viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_CYCLER)
	{
		viewC64->viewC64Screen->SetZoomedScreenPos(posX, posY, sizeX, sizeY);
	}

}

void CViewC64ScreenWrapper::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewC64ScreenWrapper::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64ScreenWrapper::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CViewC64ScreenWrapper::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64ScreenWrapper::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewC64ScreenWrapper::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64ScreenWrapper::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewC64ScreenWrapper::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64ScreenWrapper::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}

bool CViewC64ScreenWrapper::DoRightClick(GLfloat x, GLfloat y)
{
	if (IsInside(x, y))
	{
		if (viewC64->currentScreenLayoutId == SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM)
		{
			return true;
		}
		
		if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_SCREEN)
		{
			if (viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_CYCLER)
			{
				this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_ZOOMED);
			}
			else
			{
				this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_DISPLAY);
			}
		}
		else if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_ZOOMED)
		{
			if (viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_VIC_DISPLAY)
			{
				this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_DISPLAY);
			}
			else
			{
				this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_SCREEN);
			}
		}
		else //if (selectedScreenMode == C64SCREENWRAPPER_MODE_C64_DISPLAY)
		{
			this->SetSelectedScreenMode(C64SCREENWRAPPER_MODE_C64_SCREEN);
		}
		
		UpdateC64ScreenPosition();
		
		return true;
	}

	return false;
}

void CViewC64ScreenWrapper::SetSelectedScreenMode(u8 newScreenMode)
{
	this->selectedScreenMode = newScreenMode;
}

bool CViewC64ScreenWrapper::DoScrollWheel(float deltaX, float deltaY)
{
	if (this->selectedScreenMode == C64SCREENWRAPPER_MODE_C64_ZOOMED)
	{
		return viewC64->viewC64Screen->DoScrollWheel(deltaX, deltaY);
	}
	
	return false;
}


bool CViewC64ScreenWrapper::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64ScreenWrapper::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewC64ScreenWrapper::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64ScreenWrapper::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewC64ScreenWrapper::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewC64ScreenWrapper::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewC64ScreenWrapper::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewC64ScreenWrapper::FinishTouches()
{
	return CGuiView::FinishTouches();
}


bool CViewC64ScreenWrapper::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI(".......... CViewC64ScreenWrapper::KeyDown: keyCode=%d isShift=%s isAlt=%s isControl=%s", keyCode,
		 STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	
	viewC64->viewC64Screen->KeyDown(keyCode, isShift, isAlt, isControl);

	return true;
	
	//return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}



bool CViewC64ScreenWrapper::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI(".......... CViewC64ScreenWrapper::KeyUp: keyCode=%d isShift=%s isAlt=%s isControl=%s", keyCode,
		 STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	
	viewC64->viewC64Screen->KeyUp(keyCode, isShift, isAlt, isControl);

	return true;

//	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewC64ScreenWrapper::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}


void CViewC64ScreenWrapper::ActivateView()
{
	LOGG("CViewC64ScreenWrapper::ActivateView()");
	
	this->UpdateC64ScreenPosition();
}

void CViewC64ScreenWrapper::DeactivateView()
{
	LOGG("CViewC64ScreenWrapper::DeactivateView()");
}
