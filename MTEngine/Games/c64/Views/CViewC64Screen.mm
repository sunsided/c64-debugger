#include "CViewC64Screen.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "VID_ImageBinding.h"
#include "CViewC64.h"
#include "SYS_KeyCodes.h"
#include "C64DebugInterface.h"

CViewC64Screen::CViewC64Screen(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64Screen";
	
	this->debugInterface = debugInterface;
	
	int w = 512;
	int h = 512;
	CImageData *imageData = new CImageData(w, h, IMG_TYPE_RGBA);
	imageData->AllocImage(false, true);
	
	//	for (int x = 0; x < w; x++)
	//	{
	//		for (int y = 0; y < h; y++)
	//		{
	//			imageData->SetPixelResultRGBA(x, y, x % 255, y % 255, 0, 255);
	//		}
	//	}
	
	
	imageScreen = new CSlrImage(true, true);
	imageScreen->LoadImage(imageData, RESOURCE_PRIORITY_STATIC, false);
	imageScreen->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	imageScreen->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(imageScreen, NULL);
	
	
	// c64 screen texture boundaries
	screenTexEndX = (float)debugInterface->GetC64ScreenSizeX() / 512.0f;
	screenTexEndY = 1.0f - (float)debugInterface->GetC64ScreenSizeY() / 512.0f;

	this->SetPosition(posX, posY, posZ, sizeX, sizeY);

}

CViewC64Screen::~CViewC64Screen()
{
}

void CViewC64Screen::KeyUpModifierKeys(bool isShift, bool isAlt, bool isControl)
{
	debugInterface->LockIoMutex();
	if (isShift)
	{
		debugInterface->KeyboardUp(MTKEY_LSHIFT);
		debugInterface->KeyboardUp(MTKEY_RSHIFT);
	}
	if (isAlt)
	{
		debugInterface->KeyboardUp(MTKEY_LALT);
		debugInterface->KeyboardUp(MTKEY_RALT);
	}
	if (isControl)
	{
		debugInterface->KeyboardUp(MTKEY_LCONTROL);
		debugInterface->KeyboardUp(MTKEY_RCONTROL);
	}
	debugInterface->UnlockIoMutex();
}


void CViewC64Screen::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewC64Screen::RefreshScreen()
{
	//LOGD("CViewC64Screen::RefreshScreen");
	
	debugInterface->LockRenderScreenMutex();
	
	// refresh texture of C64's screen
	CImageData *screen = debugInterface->GetC64ScreenImageData();
	
#if !defined(FINAL_RELEASE)
	if (screen == NULL)
	{
		//LOGError("CViewC64Screen::RefreshScreen: screen is NULL!");
		debugInterface->UnlockRenderScreenMutex();
		return;
	}
#endif
	
	imageScreen->Deallocate();
	imageScreen->SetLoadImageData(screen);
	imageScreen->BindImage();
	imageScreen->loadImageData = NULL;
	
	debugInterface->UnlockRenderScreenMutex();
}


void CViewC64Screen::Render()
{
	// render texture of C64's screen
	Blit(imageScreen,
		 posX,
		 posY, -1,
		 sizeX,
		 sizeY,
		 0.0f, 1.0f, screenTexEndX, screenTexEndY);

}

void CViewC64Screen::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);

	UpdateRasterCrossFactors();
}

void CViewC64Screen::UpdateRasterCrossFactors()
{
	if (viewC64->debugInterface->GetEmulatorType() == C64_EMULATOR_VICE)
	{
		if (debugInterface->GetC64MachineType() == C64_MACHINE_PAL)
		{
			/// PAL
			this->rasterScaleFactorX = sizeX / (float)384; //debugInterface->GetC64ScreenSizeX();
			this->rasterScaleFactorY = sizeY / (float)272; //debugInterface->GetC64ScreenSizeY();
//			rasterCrossOffsetX =  -71.787 * rasterScaleFactorX;
			rasterCrossOffsetX =  -103.787 * rasterScaleFactorX;
			rasterCrossOffsetY = -15.500 * rasterScaleFactorY;
		}
		else if (debugInterface->GetC64MachineType() == C64_MACHINE_NTSC)
		{
			/// NTSC uses the same framebuffer
			this->rasterScaleFactorX = sizeX / (float)384; //debugInterface->GetC64ScreenSizeX();
			this->rasterScaleFactorY = sizeY / (float)272; //debugInterface->GetC64ScreenSizeY();
			rasterCrossOffsetX =  -103.787 * rasterScaleFactorX;
			rasterCrossOffsetY = -15.500 * rasterScaleFactorY;
		}
	}
	
	rasterCrossWidth = 1.0f;
	rasterCrossWidth2 = rasterCrossWidth/2.0f;
	
	rasterCrossSizeX = 25.0f * rasterScaleFactorX;
	rasterCrossSizeY = 25.0f * rasterScaleFactorY;
	rasterCrossSizeX2 = rasterCrossSizeX/2.0f;
	rasterCrossSizeY2 = rasterCrossSizeY/2.0f;
	rasterCrossSizeX3 = rasterCrossSizeX/3.0f;
	rasterCrossSizeY3 = rasterCrossSizeY/3.0f;
	rasterCrossSizeX4 = rasterCrossSizeX/4.0f;
	rasterCrossSizeY4 = rasterCrossSizeY/4.0f;
	rasterCrossSizeX6 = rasterCrossSizeX/6.0f;
	rasterCrossSizeY6 = rasterCrossSizeY/6.0f;
	
	rasterCrossSizeX34 = rasterCrossSizeX2+rasterCrossSizeX4;
	rasterCrossSizeY34 = rasterCrossSizeY2+rasterCrossSizeY4;
}



void CViewC64Screen::RenderRaster(int rasterX, int rasterY)
{
	static int min = 999999;
	static int max = 0;

	if (rasterX > max)
	{
		max = rasterX;
	}
	
	if (rasterX < min)
	{
		min = rasterX;
	}
	
//	LOGD("min=%d max=%d   sfx=%3.2f sfy=%3.2f", min, max, rasterScaleFactorX, rasterScaleFactorY);
	
	
	float cx = posX + (float)rasterX * rasterScaleFactorX  + rasterCrossOffsetX;
	float cy = posY + (float)rasterY * rasterScaleFactorY  + rasterCrossOffsetY;
	

	/// long line
	float rr4 = 0.7f;
	float rg4 = 0.7f;
	float rb4 = 0.7f;
	float ra4 = 0.35f;
	
	BlitFilledRectangle(posX, cy - rasterCrossWidth2, posZ, sizeX, rasterCrossWidth, rr4, rg4, rb4, ra4);
	BlitFilledRectangle(cx - rasterCrossWidth2, posY, posZ, rasterCrossWidth, sizeY, rr4, rg4, rb4, ra4);

	
	float rr1 = 0.9f;
	float rg1 = 0.1f;
	float rb1 = 0.0f;
	float ra1 = 0.7f;
	
	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY2, posZ, rasterCrossWidth, rasterCrossSizeY, rr1, rg1, rb1, ra1);
	BlitFilledRectangle(cx - rasterCrossSizeX2, cy - rasterCrossWidth2, posZ, rasterCrossSizeX, rasterCrossWidth, rr1, rg1, rb1, ra1);

	float rr2 = 0.0f;
	float rg2 = 0.0f;
	float rb2 = 0.0f;
	float ra2 = 0.15f;
	
	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY34, posZ, rasterCrossWidth, rasterCrossSizeY4, rr2, rg2, rb2, ra2);
	BlitFilledRectangle(cx - rasterCrossWidth2, cy + rasterCrossSizeY2, posZ, rasterCrossWidth, rasterCrossSizeY4, rr2, rg2, rb2, ra2);
	BlitFilledRectangle(cx - rasterCrossSizeX34, cy - rasterCrossWidth2, posZ, rasterCrossSizeX4, rasterCrossWidth, rr2, rg2, rb2, ra2);
	BlitFilledRectangle(cx + rasterCrossSizeX2, cy - rasterCrossWidth2, posZ, rasterCrossSizeX4, rasterCrossWidth, rr2, rg2, rb2, ra2);
	
	float rr3 = 1.0f;
	float rg3 = 1.0f;
	float rb3 = 1.0f;
	float ra3 = 0.85f;

	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY6, posZ, rasterCrossWidth, rasterCrossSizeY3, rr3, rg3, rb3, ra3);
	BlitFilledRectangle(cx - rasterCrossSizeX6, cy - rasterCrossWidth2, posZ, rasterCrossSizeX3, rasterCrossWidth, rr3, rg3, rb3, ra3);

	
}


void CViewC64Screen::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewC64Screen::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Screen::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CViewC64Screen::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Screen::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewC64Screen::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Screen::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewC64Screen::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Screen::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewC64Screen::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64Screen::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewC64Screen::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64Screen::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewC64Screen::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewC64Screen::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewC64Screen::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewC64Screen::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewC64Screen::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	debugInterface->LockIoMutex();
	debugInterface->KeyboardDown(bareKey);
	debugInterface->UnlockIoMutex();
	return true;
	
	//return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64Screen::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	debugInterface->LockIoMutex();
	debugInterface->KeyboardUp(bareKey);
	debugInterface->UnlockIoMutex();

	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewC64Screen::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewC64Screen::ActivateView()
{
	LOGG("CViewC64Screen::ActivateView()");
}

void CViewC64Screen::DeactivateView()
{
	LOGG("CViewC64Screen::DeactivateView()");
}
