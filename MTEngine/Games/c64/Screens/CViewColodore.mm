#include "CViewC64.h"
#include "CViewColodore.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "C64Tools.h"
#include "SYS_KeyCodes.h"
#include "CSlrKeyboardShortcuts.h"
#include "CSlrFileFromOS.h"
#include "CColorsTheme.h"
#include "C64SettingsStorage.h"
#include "CViewC64Screen.h"
#include "C64Palette.h"
#include "C64KeyboardShortcuts.h"
#include "CViewBreakpoints.h"
#include "CViewSnapshots.h"
#include "C64DebugInterface.h"
#include "MTH_Random.h"

#include "CViewMemoryMap.h"

#include "CGuiMain.h"

CViewColodore::CViewColodore(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewColodore";
	
	font = viewC64->fontCBMShifted;
	fontScale = 1.5;
	fontHeight = font->GetCharHeight('@', fontScale) + 2;
	
	strHeader = new CSlrString("colodore v1 by pepto");
}

CViewColodore::~CViewColodore()
{
}

void CViewColodore::DoLogic()
{
	
}

void CViewColodore::Render()
{
//	BlitFilledRectangle(0, 0, -1, sizeX, sizeY,
//						viewC64->colorsTheme->MTCOL_MMABFR1_R,
//						viewC64->colorsTheme->MTCOL_MMABFR1_G,
//						viewC64->colorsTheme->MTCOL_MMABFR1_B,
//						1.0);
	
	float sb = 20;
	float gap = 4;
	
	float tr = viewC64->colorsTheme->colorTextR;
	float tg = viewC64->colorsTheme->colorTextG;
	float tb = viewC64->colorsTheme->colorTextB;
	
	float lr = viewC64->colorsTheme->colorHeaderLineR;
	float lg = viewC64->colorsTheme->colorHeaderLineG;
	float lb = viewC64->colorsTheme->colorHeaderLineB;
	float lSizeY = 3;
	
	float scrx = sb;
	float scry = sb;
	float scrsx = sizeX - sb*2.0f;
	float scrsy = sizeY - sb*2.0f;
	float cx = scrsx/2.0f + sb;
	
	float bg_r = viewC64->colorsTheme->colorBackgroundR;
	float bg_g = viewC64->colorsTheme->colorBackgroundG;
	float bg_b = viewC64->colorsTheme->colorBackgroundB;
	
//	BlitFilledRectangle(scrx, scry, -1, scrsx, scrsy, bg_r, bg_g, bg_b, 1.0);
	
	float px = scrx + gap;
	float py = scry + gap;
	
	fontScale = 3.0f;
	fontHeight = font->GetCharHeight('@', fontScale) + 1;

	float htr = viewC64->colorsTheme->colorTextHeaderR;
	float htg = viewC64->colorsTheme->colorTextHeaderG;
	float htb = viewC64->colorsTheme->colorTextHeaderB;
	font->BlitTextColor(strHeader, cx, py, -1, fontScale, htr, htg, htb, 1, FONT_ALIGN_CENTER);

	py += fontHeight;
	//	font->BlitTextColor(strHeader2, cx, py, -1, fontScale, tr, tg, tb, 1, FONT_ALIGN_CENTER);
	//	py += fontHeight;
	py += 4.0f;
	
	BlitFilledRectangle(scrx, py, -1, scrsx, lSizeY, lr, lg, lb, 1);
	
	py += lSizeY + gap + 4.0f;
	
	
	fontScale = 2.0f;
	fontHeight = font->GetCharHeight('@', fontScale) + 1;

//	font->BlitTextColor("C64 Debugger is (C) Marcin Skoczylas, aka Slajerek/Samar", px, py, posZ, fontScale, tr, tg, tb, 1); py += fontHeight;
	
	
	viewC64->viewC64Screen->RefreshScreen();
	viewC64->viewC64Screen->Render();

}

void CViewColodore::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewColodore::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewColodore::DoTap:  x=%f y=%f", x, y);
//	guiMain->SetView(viewC64->viewC64MainMenu);
	return CGuiView::DoTap(x, y);
}

bool CViewColodore::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewColodore::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewColodore::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewColodore::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewColodore::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewColodore::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewColodore::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewColodore::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewColodore::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewColodore::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewColodore::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewColodore::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewColodore::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewColodore::FinishTouches()
{
	return CGuiView::FinishTouches();
}

void CViewColodore::SwitchAboutScreen()
{
	if (guiMain->currentView == this)
	{
		guiMain->SetView(viewC64->viewC64MainMenu);
	}
	else
	{
		guiMain->SetView(this);
	}
}

bool CViewColodore::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
//	guiMain->SetView(viewC64->viewC64MainMenu);

//	if (keyCode == MTKEY_BACKSPACE)
//	{
//		guiMain->SetView(viewC64->viewC64MainMenu);
//		return true;
//	}
	
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewColodore::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewColodore::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewColodore::ActivateView()
{
	LOGG("CViewColodore::ActivateView()");
	
	C64SetPaletteOriginalColorCodes();
	
	viewC64->viewC64Screen->SetVisible(true);
	
	float scale = 1.8f;
	float sx = (float)viewC64->debugInterface->GetC64ScreenSizeX() * scale;
	float sy = (float)viewC64->debugInterface->GetC64ScreenSizeY() * scale;
	float px = this->sizeX - sx + 150.0f;
	float py = 50.0;//this->sizeY - sy;
	viewC64->viewC64Screen->SetPosition(px,
							   py, posZ,
							   sx,
							   sy);

	
	viewC64->viewC64Screen->SetupScreenColodore();
	
}

void CViewColodore::DeactivateView()
{
	LOGG("CViewColodore::DeactivateView()");
}

