#include "CViewC64Screen.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "VID_ImageBinding.h"
#include "CViewC64.h"
#include "SYS_KeyCodes.h"
#include "C64DebugInterface.h"
#include "C64SettingsStorage.h"

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

	// zoomed screen
	this->zoomedScreenLevel = c64SettingsScreenRasterViewfinderScale;
	this->showZoomedScreen = false;
	
	this->showGridLines = false;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
	
//	/// debug
//	int rasterNum = 0x003A;
//	C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(rasterNum);
//	debugInterface->breakpointsC64Raster[rasterNum] = addrBreakpoint;
//	
//	debugInterface->breakOnC64Raster = true;

	InitRasterColors();
}

CViewC64Screen::~CViewC64Screen()
{
}

void CViewC64Screen::GetRasterColorScheme(int schemeNum, float splitAmount, float *r, float *g, float *b)
{
	switch(schemeNum)
	{
		default:
			// red
			*r = 1.0f - splitAmount;
			*g = splitAmount;
			*b = 0.0f;
			break;
		case 1:
			// green
			*r = splitAmount;
			*g = 1.0f - splitAmount;
			*b = 0.0f;
			break;
		case 2:
			// blue
			*r = splitAmount;
			*g = 0.0f;
			*b = 1.0f - splitAmount;
			break;
		case 3:
			// black
			*r = 0.0f;
			*g = 0.0f;
			*b = 0.0f;
			break;
		case 4:
			// dark gray
			*r = 0.25f;
			*g = 0.25f;
			*b = 0.25f;
			break;
		case 5:
			// light gray
			*r = 0.70f;
			*g = 0.70f;
			*b = 0.70f;
			break;
		case 6:
			// white
			*r = 1.0f;
			*g = 1.0f;
			*b = 1.0f;
			break;
	}

}

void CViewC64Screen::InitRasterColors()
{
	// grid lines
	GetRasterColorScheme(c64SettingsScreenGridLinesColorScheme, 0.0f,
						 &gridLinesColorR, &gridLinesColorG, &gridLinesColorB);
	
	gridLinesColorA = c64SettingsScreenGridLinesAlpha;

	// raster long screen line
	GetRasterColorScheme(c64SettingsScreenRasterCrossLinesColorScheme, 0.0f,
						 &rasterLongScrenLineR, &rasterLongScrenLineG, &rasterLongScrenLineB);
	rasterLongScrenLineA = c64SettingsScreenRasterCrossLinesAlpha;
	
	//c64SettingsScreenRasterCrossAlpha = 0.85

	// exterior
	GetRasterColorScheme(c64SettingsScreenRasterCrossExteriorColorScheme, 0.1f,
						 &rasterCrossExteriorR, &rasterCrossExteriorG, &rasterCrossExteriorB);
	
	rasterCrossExteriorA = 0.8235f * c64SettingsScreenRasterCrossAlpha;		// 0.7
	
	// tip
	GetRasterColorScheme(c64SettingsScreenRasterCrossTipColorScheme, 0.1f,
						 &rasterCrossEndingTipR, &rasterCrossEndingTipG, &rasterCrossEndingTipB);
	
	rasterCrossEndingTipA = 0.1765f * c64SettingsScreenRasterCrossAlpha;	// 0.15
	
	// white interior cross
	GetRasterColorScheme(c64SettingsScreenRasterCrossInteriorColorScheme, 0.1f,
						 &rasterCrossInteriorR, &rasterCrossInteriorG, &rasterCrossInteriorB);

	rasterCrossInteriorA = c64SettingsScreenRasterCrossAlpha;	// 0.85
	
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
	
	if (showGridLines)
	{
		// raster screen in hex:
		// startx = 68 (88) endx = 1e8 (1c8)
		// starty = 10 (32) endy = 120 ( fa)

		float cys = posY + (float)0x0010 * rasterScaleFactorY  + rasterCrossOffsetY;
		float cye = posY + (float)0x0120 * rasterScaleFactorY  + rasterCrossOffsetY;

		float cxs = posX + (float)0x0068 * rasterScaleFactorX  + rasterCrossOffsetX;
		float cxe = posX + (float)0x01E8 * rasterScaleFactorX  + rasterCrossOffsetX;

		
		// vertical lines
		for (float rasterX = 103.5f; rasterX < 0x01e8; rasterX += 0x08)
		{
			float cx = posX + (float)rasterX * rasterScaleFactorX  + rasterCrossOffsetX;
			
			BlitLine(cx, cys, cx, cye, -1,
					 gridLinesColorR, gridLinesColorG, gridLinesColorB, gridLinesColorA);
		}
		
		// horizontal lines
		for (float rasterY = 18.5f; rasterY < 0x0120; rasterY += 0x08)
		{
			float cy = posY + (float)rasterY * rasterScaleFactorY  + rasterCrossOffsetY;
			
			BlitLine(cxs, cy, cxe, cy, -1,
					 gridLinesColorR, gridLinesColorG, gridLinesColorB, gridLinesColorA);
		}
		
		
//		float cx = posX + (float)rasterX * rasterScaleFactorX  + rasterCrossOffsetX;
//		float cy = posY + (float)rasterY * rasterScaleFactorY  + rasterCrossOffsetY;
	}
}

void CViewC64Screen::SetZoomedScreenPos(float zoomedScreenPosX, float zoomedScreenPosY, float zoomedScreenSizeX, float zoomedScreenSizeY)
{
	this->zoomedScreenPosX = zoomedScreenPosX;
	this->zoomedScreenPosY = zoomedScreenPosY;
	this->zoomedScreenSizeX = zoomedScreenSizeX;
	this->zoomedScreenSizeY = zoomedScreenSizeY;
	
	this->zoomedScreenCenterX = zoomedScreenPosX + zoomedScreenSizeX/2.0f;
	this->zoomedScreenCenterY = zoomedScreenPosY + zoomedScreenSizeY/2.0f;

	this->SetZoomedScreenLevel(this->zoomedScreenLevel);
	
}

void CViewC64Screen::SetZoomedScreenLevel(float zoomedScreenLevel)
{
	this->zoomedScreenLevel = zoomedScreenLevel;
	
	zoomedScreenImageSizeX = (float)debugInterface->GetC64ScreenSizeX() * zoomedScreenLevel;
	zoomedScreenImageSizeY = (float)debugInterface->GetC64ScreenSizeY() * zoomedScreenLevel;

	zoomedScreenRasterScaleFactorX = zoomedScreenImageSizeX / (float)384; //debugInterface->GetC64ScreenSizeX();
	zoomedScreenRasterScaleFactorY = zoomedScreenImageSizeY / (float)272; //debugInterface->GetC64ScreenSizeY();
	zoomedScreenRasterOffsetX =  -103.787 * zoomedScreenRasterScaleFactorX;
	zoomedScreenRasterOffsetY = -15.500 * zoomedScreenRasterScaleFactorY;
	
}

void CViewC64Screen::CalcZoomedScreenTextureFromRaster(int rasterX, int rasterY)
{
	float ttrx = (float)rasterX * zoomedScreenRasterScaleFactorX + zoomedScreenRasterOffsetX;
	float ttry = (float)rasterY * zoomedScreenRasterScaleFactorY + zoomedScreenRasterOffsetY;

	zoomedScreenImageStartX = zoomedScreenCenterX - ttrx;
	zoomedScreenImageStartY = zoomedScreenCenterY - ttry;
}


void CViewC64Screen::RenderZoomedScreen(int rasterX, int rasterY)
{
	CalcZoomedScreenTextureFromRaster(rasterX, rasterY);
	
	SetClipping(zoomedScreenPosX, zoomedScreenPosY, zoomedScreenSizeX, zoomedScreenSizeY);
	
	//LOGD("x=%6.2f %6.2f  y=%6.2f y=%6.2f", zoomedScreenImageStartX, zoomedScreenImageStartY, zoomedScreenImageSizeX, zoomedScreenImageSizeY);

	// nearest neighbour
	{
		glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);

		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	Blit(imageScreen,
		 zoomedScreenImageStartX,
		 zoomedScreenImageStartY, -1,
		 zoomedScreenImageSizeX,
		 zoomedScreenImageSizeY,
		 0.0f, 1.0f, screenTexEndX, screenTexEndY);
	
	// back to linear scale
	{
		glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);
		
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}

	// clipping
	BlitRectangle(zoomedScreenPosX, zoomedScreenPosY, -1, zoomedScreenSizeX, zoomedScreenSizeY, 0.0f, 1.0f, 1.0f, 1.0f);
	
	
	float rs = 1.0f;
	float rs2 = rs*2.0f;
	BlitFilledRectangle(zoomedScreenCenterX - rs, zoomedScreenPosY, -1, rs2, zoomedScreenSizeY,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);
	BlitFilledRectangle(zoomedScreenPosX, zoomedScreenCenterY, -1, zoomedScreenSizeX, rs2,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);
	
	ResetClipping();
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
//	static int min = 999999;
//	static int max = 0;
//
//	if (rasterX > max)
//	{
//		max = rasterX;
//	}
//	
//	if (rasterX < min)
//	{
//		min = rasterX;
//	}
	//	LOGD("min=%d max=%d   sfx=%3.2f sfy=%3.2f", min, max, rasterScaleFactorX, rasterScaleFactorY);
	
	
	float cx = posX + (float)rasterX * rasterScaleFactorX  + rasterCrossOffsetX;
	float cy = posY + (float)rasterY * rasterScaleFactorY  + rasterCrossOffsetY;
	

	/// long screen line
	BlitFilledRectangle(posX, cy - rasterCrossWidth2, posZ, sizeX, rasterCrossWidth,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);
	BlitFilledRectangle(cx - rasterCrossWidth2, posY, posZ, rasterCrossWidth, sizeY,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);

	// red cross
	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY2, posZ, rasterCrossWidth, rasterCrossSizeY,
						rasterCrossExteriorR, rasterCrossExteriorG, rasterCrossExteriorB, rasterCrossExteriorA);
	BlitFilledRectangle(cx - rasterCrossSizeX2, cy - rasterCrossWidth2, posZ, rasterCrossSizeX, rasterCrossWidth,
						rasterCrossExteriorR, rasterCrossExteriorG, rasterCrossExteriorB, rasterCrossExteriorA);

	// cross ending tip
	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY34, posZ, rasterCrossWidth, rasterCrossSizeY4,
						rasterCrossEndingTipR, rasterCrossEndingTipG, rasterCrossEndingTipB, rasterCrossEndingTipA);
	BlitFilledRectangle(cx - rasterCrossWidth2, cy + rasterCrossSizeY2, posZ, rasterCrossWidth, rasterCrossSizeY4,
						rasterCrossEndingTipR, rasterCrossEndingTipG, rasterCrossEndingTipB, rasterCrossEndingTipA);
	BlitFilledRectangle(cx - rasterCrossSizeX34, cy - rasterCrossWidth2, posZ, rasterCrossSizeX4, rasterCrossWidth,
						rasterCrossEndingTipR, rasterCrossEndingTipG, rasterCrossEndingTipB, rasterCrossEndingTipA);
	BlitFilledRectangle(cx + rasterCrossSizeX2, cy - rasterCrossWidth2, posZ, rasterCrossSizeX4, rasterCrossWidth,
						rasterCrossEndingTipR, rasterCrossEndingTipG, rasterCrossEndingTipB, rasterCrossEndingTipA);

	// white interior cross
	BlitFilledRectangle(cx - rasterCrossWidth2, cy - rasterCrossSizeY6, posZ, rasterCrossWidth, rasterCrossSizeY3,
						rasterCrossInteriorR, rasterCrossInteriorG, rasterCrossInteriorB, rasterCrossInteriorA);
	BlitFilledRectangle(cx - rasterCrossSizeX6, cy - rasterCrossWidth2, posZ, rasterCrossSizeX3, rasterCrossWidth,
						rasterCrossInteriorR, rasterCrossInteriorG, rasterCrossInteriorB, rasterCrossInteriorA);
	
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
	LOGD(".......... CViewC64Screen::KeyDown: keyCode=%d", keyCode);
//	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	debugInterface->LockIoMutex();

	keyCode = SYS_KeyCodeConvertSpecial(keyCode, isShift, isAlt, isControl);

	debugInterface->KeyboardDown(keyCode); //bareKey);
	debugInterface->UnlockIoMutex();
	return true;
	
	//return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64Screen::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD(".......... CViewC64Screen::KeyUp: keyCode=%d", keyCode);
//	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	debugInterface->LockIoMutex();
	
	keyCode = SYS_KeyCodeConvertSpecial(keyCode, isShift, isAlt, isControl);

	debugInterface->KeyboardUp(keyCode); //bareKey);
	debugInterface->UnlockIoMutex();
	
	return true;

//	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
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
