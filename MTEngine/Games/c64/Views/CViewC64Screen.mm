#include "CViewC64Screen.h"
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

#include "CViewAtariScreen.h"

CViewC64Screen::CViewC64Screen(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64Screen";
	
	this->debugInterface = debugInterface;
		
	int w = 512 * debugInterface->screenSupersampleFactor;
	int h = 512 * debugInterface->screenSupersampleFactor;
	imageDataScreenDefault = new CImageData(w, h, IMG_TYPE_RGBA);
	imageDataScreenDefault->AllocImage(false, true);
	
	//	for (int x = 0; x < w; x++)
	//	{
	//		for (int y = 0; y < h; y++)
	//		{
	//			imageDataScreen->SetPixelResultRGBA(x, y, x % 255, y % 255, 0, 255);
	//		}
	//	}
	
	
	imageScreenDefault = new CSlrImage(true, true);
	imageScreenDefault->LoadImage(imageDataScreenDefault, RESOURCE_PRIORITY_STATIC, false);
	imageScreenDefault->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	imageScreenDefault->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(imageScreenDefault, NULL);
	
	imageScreen = imageScreenDefault;
	
	// c64 screen texture boundaries
	screenTexEndX = (float)debugInterface->GetScreenSizeX() / 512.0f;
	screenTexEndY = 1.0f - (float)debugInterface->GetScreenSizeY() / 512.0f;

	this->colodoreScreen = NULL;
	
	// zoomed screen
	this->zoomedScreenLevel = c64SettingsScreenRasterViewfinderScale;
	this->showZoomedScreen = false;
	
	this->showGridLines = false;
	
	shiftDown = false;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
	
//	/// debug
//	int rasterNum = 0x003A;
//	CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(rasterNum);
//	debugInterface->breakpointsC64Raster[rasterNum] = addrBreakpoint;
//	
//	debugInterface->breakOnC64Raster = true;

	InitRasterColorsFromScheme();
}

CViewC64Screen::~CViewC64Screen()
{
}

void CViewC64Screen::SetSupersampleFactor(int supersampleFactor)
{
	guiMain->LockMutex();
	debugInterface->LockRenderScreenMutex();
	
	debugInterface->SetSupersampleFactor(supersampleFactor);
	
	CImageData *screenData = debugInterface->GetScreenImageData();
	this->imageScreen->RefreshImageParameters(screenData,  RESOURCE_PRIORITY_STATIC, false);
	VID_PostImageBinding(imageScreenDefault, NULL);
	debugInterface->UnlockRenderScreenMutex();
	guiMain->UnlockMutex();
}

void CViewC64Screen::SetupScreenColodore()
{
	this->colodoreScreen = new C64ColodoreScreen(this->debugInterface);
	
	imageScreenColodore = new CSlrImage(true, true);
	imageScreenColodore->LoadImage(this->colodoreScreen->imageDataColodoreScreen, RESOURCE_PRIORITY_STATIC, false);
	imageScreenColodore->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	imageScreenColodore->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(imageScreenColodore, NULL);

	imageScreen = imageScreenColodore;
}

void CViewC64Screen::InitRasterColorsFromScheme()
{
	// grid lines
	GetColorsFromScheme(c64SettingsScreenGridLinesColorScheme, 0.0f,
						 &gridLinesColorR, &gridLinesColorG, &gridLinesColorB);
	
	gridLinesColorA = c64SettingsScreenGridLinesAlpha;

	// raster long screen line
	GetColorsFromScheme(c64SettingsScreenRasterCrossLinesColorScheme, 0.0f,
						 &rasterLongScrenLineR, &rasterLongScrenLineG, &rasterLongScrenLineB);
	rasterLongScrenLineA = c64SettingsScreenRasterCrossLinesAlpha;
	
	//c64SettingsScreenRasterCrossAlpha = 0.85

	// exterior
	GetColorsFromScheme(c64SettingsScreenRasterCrossExteriorColorScheme, 0.1f,
						 &rasterCrossExteriorR, &rasterCrossExteriorG, &rasterCrossExteriorB);
	
	rasterCrossExteriorA = 0.8235f * c64SettingsScreenRasterCrossAlpha;		// 0.7
	
	// tip
	GetColorsFromScheme(c64SettingsScreenRasterCrossTipColorScheme, 0.1f,
						 &rasterCrossEndingTipR, &rasterCrossEndingTipG, &rasterCrossEndingTipB);
	
	rasterCrossEndingTipA = 0.1765f * c64SettingsScreenRasterCrossAlpha;	// 0.15
	
	// white interior cross
	GetColorsFromScheme(c64SettingsScreenRasterCrossInteriorColorScheme, 0.1f,
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
	
	if (this->colodoreScreen)
	{
		RefreshScreenColodore();
		return;
	}
	
	debugInterface->LockRenderScreenMutex();
	
	// refresh texture of C64's screen
	CImageData *screen = debugInterface->GetScreenImageData();
	
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

void CViewC64Screen::RefreshScreenColodore()
{
	//LOGD("CViewC64Screen::RefreshScreen");
	
	debugInterface->LockRenderScreenMutex();
	
	// refresh texture of C64's screen
	CImageData *screen = debugInterface->GetScreenImageData();
	colodoreScreen->RefreshColodoreScreen(screen);
	
	imageScreen->Deallocate();
	imageScreen->SetLoadImageData(colodoreScreen->imageDataColodoreScreen);
	imageScreen->BindImage();
	imageScreen->loadImageData = NULL;
	
	debugInterface->UnlockRenderScreenMutex();
}


void CViewC64Screen::Render()
{
	// render texture of C64's screen
	
	if (c64SettingsRenderScreenNearest)
	{
		// nearest neighbour
		{
			glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);
			
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		}
	}
	else
	{
		// billinear interpolation
		{
			glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);
			
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		}
	}

	// blit texture of the screen
	Blit(imageScreen,
		 posX,
		 posY, -1,
		 sizeX,
		 sizeY,
		 0.0f, 1.0f, screenTexEndX, screenTexEndY);

	// and any other stuff on top of the screen
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
	if (zoomedScreenLevel < 0.05f)
	{
		zoomedScreenLevel = 0.05f;
	}
	
	if (zoomedScreenLevel > 25.0f)
	{
		zoomedScreenLevel = 25.0f;
	}
	
	this->zoomedScreenLevel = zoomedScreenLevel;
	
	zoomedScreenImageSizeX = (float)debugInterface->GetScreenSizeX() * zoomedScreenLevel;
	zoomedScreenImageSizeY = (float)debugInterface->GetScreenSizeY() * zoomedScreenLevel;

	zoomedScreenRasterScaleFactorX = zoomedScreenImageSizeX / (float)384; //debugInterface->GetC64ScreenSizeX();
	zoomedScreenRasterScaleFactorY = zoomedScreenImageSizeY / (float)272; //debugInterface->GetC64ScreenSizeY();
	zoomedScreenRasterOffsetX =  -103.787 * zoomedScreenRasterScaleFactorX;
	zoomedScreenRasterOffsetY = -15.500 * zoomedScreenRasterScaleFactorY;
	
}

bool CViewC64Screen::DoScrollWheel(float deltaX, float deltaY)
{
	float newLevel = this->zoomedScreenLevel + deltaY*0.045f;
	
	SetZoomedScreenLevel(newLevel);
	
	return true;
}

bool CViewC64Screen::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64Screen::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	float newLevel = this->zoomedScreenLevel + difference * 0.06f;
	SetZoomedScreenLevel(newLevel);
	
	return true;
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

	if (c64SettingsRenderScreenNearest)
	{
		// nearest neighbour
		{
			glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);
			
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
		}
	}
	else
	{
		// billinear interpolation
		{
			glBindTexture(GL_TEXTURE_2D, imageScreen->texture[0]);
			
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
		}
	}
	
	Blit(imageScreen,
		 zoomedScreenImageStartX,
		 zoomedScreenImageStartY, -1,
		 zoomedScreenImageSizeX,
		 zoomedScreenImageSizeY,
		 0.0f, 1.0f, screenTexEndX, screenTexEndY);
	
	// clipping
	if (viewC64->currentScreenLayoutId != SCREEN_LAYOUT_C64_FULL_SCREEN_ZOOM)
	{
		BlitRectangle(zoomedScreenPosX, zoomedScreenPosY, -1, zoomedScreenSizeX, zoomedScreenSizeY, 0.0f, 1.0f, 1.0f, 1.0f);
	}
	
	
	float rs = 0.3f;
	float rs2 = rs*2.0f;
	BlitFilledRectangle(zoomedScreenCenterX - rs, zoomedScreenPosY, -1, rs2, zoomedScreenSizeY,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);
	BlitFilledRectangle(zoomedScreenPosX, zoomedScreenCenterY, -1, zoomedScreenSizeX, rs2,
						rasterLongScrenLineR, rasterLongScrenLineG, rasterLongScrenLineB, rasterLongScrenLineA);
	
	ResetClipping();
	
	if (this->hasFocus)
	{
		this->RenderFocusBorder();
	}
}


void CViewC64Screen::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);

	UpdateRasterCrossFactors();
}

void CViewC64Screen::UpdateRasterCrossFactors()
{
	if (viewC64->debugInterfaceC64->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
	{
		if (debugInterface->GetC64MachineType() == MACHINE_TYPE_PAL)
		{
			/// PAL
			this->rasterScaleFactorX = sizeX / (float)384; //debugInterface->GetC64ScreenSizeX();
			this->rasterScaleFactorY = sizeY / (float)272; //debugInterface->GetC64ScreenSizeY();
//			rasterCrossOffsetX =  -71.787 * rasterScaleFactorX;
			rasterCrossOffsetX =  -103.787 * rasterScaleFactorX;
			rasterCrossOffsetY = -15.500 * rasterScaleFactorY;
		}
		else if (debugInterface->GetC64MachineType() == MACHINE_TYPE_NTSC)
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

int CViewC64Screen::GetJoystickAxis(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	// because Windows is totally messed up with right-Alt key, let's compare only keyCodes
	if (c64SettingsJoystickIsOn)
	{
		if (viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == keyCode)
		{
			return JOYPAD_FIRE;
		}
		if (viewC64->keyboardShortcuts->kbsJoystickUp->keyCode == keyCode)
		{
			return JOYPAD_N;
		}
		if (viewC64->keyboardShortcuts->kbsJoystickDown->keyCode == keyCode)
		{
			return JOYPAD_S;
		}
		if (viewC64->keyboardShortcuts->kbsJoystickLeft->keyCode == keyCode)
		{
			return JOYPAD_W;
		}
		if (viewC64->keyboardShortcuts->kbsJoystickRight->keyCode == keyCode)
		{
			return JOYPAD_E;
		}
	}
	return JOYPAD_IDLE;

	
	/*
	
		// this does not work, let's skip possibility to select control keys with joystick keys
		// workaround for fire (eg. fire+up = ALT+UP)
		CSlrKeyboardShortcut *shortcut = NULL;

		if (viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == keyCode
			&& viewC64->keyboardShortcuts->kbsJoystickFire->isShift == isShift
			&& viewC64->keyboardShortcuts->kbsJoystickFire->isAlt == isAlt
			&& viewC64->keyboardShortcuts->kbsJoystickFire->isControl == isControl)
		{
			return JOYPAD_FIRE;
		}
		else
		{
			if (viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_LALT
				|| viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_RALT)
			{
				isAlt = false;
			}
			else if (viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_LCONTROL
					 || viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_RCONTROL)
			{
				isControl = false;
			}
			else if (viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_LSHIFT
					 || viewC64->keyboardShortcuts->kbsJoystickFire->keyCode == MTKEY_RSHIFT)
			{
				isShift = false;
			}
			
			shortcut = viewC64->keyboardShortcuts->FindShortcut(KBZONE_SCREEN, keyCode, isShift, isAlt, isControl);
		}
		
		if (shortcut != NULL)
		{
			if (shortcut == viewC64->keyboardShortcuts->kbsJoystickUp)
			{
				return JOYPAD_N;
			}
			else if (shortcut == viewC64->keyboardShortcuts->kbsJoystickDown)
			{
				return JOYPAD_S;
			}
			// something is messy here, why this is opposite?
			else if (shortcut == viewC64->keyboardShortcuts->kbsJoystickLeft)
			{
				return JOYPAD_W;
			}
			else if (shortcut == viewC64->keyboardShortcuts->kbsJoystickRight)
			{
				return JOYPAD_E;
			}
			else if (shortcut == viewC64->keyboardShortcuts->kbsJoystickFire)
			{
				return JOYPAD_FIRE;
			}
		}
	}

	return JOYPAD_IDLE;
		
		*/
}


bool CViewC64Screen::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD(".......... CViewC64Screen::KeyDown: keyCode=%d isShift=%s isAlt=%s isControl=%s", keyCode,
		 STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	
	if (viewC64->currentScreenLayoutId == SCREEN_LAYOUT_C64_AND_ATARI)
	{
		viewC64->viewAtariScreen->KeyDown(keyCode, isShift, isAlt, isControl);
	}
	
	int joyAxis = GetJoystickAxis(keyCode, isShift, isAlt, isControl);
	
	if (joyAxis != JOYPAD_IDLE)
	{
		this->JoystickDown(joyAxis);
		return true;
	}
	
//	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);
	
	debugInterface->LockIoMutex();
	
	/*
	std::map<u32, bool>::iterator it = pressedKeyCodes.find(keyCode);

	if (it == pressedKeyCodes.end())
	{
		pressedKeyCodes[keyCode] = true;
	}
	else
	{
		// key is already pressed
		LOGD("key %d is already pressed, skipping...", keyCode);
		debugInterface->UnlockIoMutex();
		return true;
	}
	 */
	
	
	keyCode = SYS_KeyCodeConvertSpecial(keyCode, isShift, isAlt, isControl);


	LOGI(".........SYS_KeyCodeConvertSpecial converted key is ", keyCode);
	
	
	/// GIANA SISTERS' pause workaround
//	if (isShift)
//		return true;
	
	if (keyCode == MTKEY_LSHIFT
		|| keyCode == MTKEY_RSHIFT)
	{
		shiftDown = true;
	}
	
	debugInterface->KeyboardDown(keyCode); //bareKey);
	debugInterface->UnlockIoMutex();
	return true;
	
	//return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}


extern "C"
{
	// workaround
	void c64d_keyboard_force_key_up_latch(signed long key);
}

bool CViewC64Screen::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD(".......... CViewC64Screen::KeyUp: keyCode=%d isShift=%s isAlt=%s isControl=%s  shiftDown=%s", keyCode,
		 STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl), STRBOOL(shiftDown));
	
	if (viewC64->currentScreenLayoutId == SCREEN_LAYOUT_C64_AND_ATARI)
	{
		viewC64->viewAtariScreen->KeyUp(keyCode, isShift, isAlt, isControl);
	}
	
	int joyAxis = GetJoystickAxis(keyCode, isShift, isAlt, isControl);
	
	if (joyAxis != JOYPAD_IDLE)
	{
		this->JoystickUp(joyAxis);
		return true;
	}
	

		
	//	u32 bareKey = SYS_GetBareKey(keyCode, isShift, isAlt, isControl);

	debugInterface->LockIoMutex();
	
	/*
	std::map<u32, bool>::iterator it = pressedKeyCodes.find(keyCode);
	
	if (it == pressedKeyCodes.end())
	{
		// key is already not pressed
		LOGD("key %d is already not pressed, skipping...", keyCode);
		debugInterface->UnlockIoMutex();
		
		return true;
	}
	else
	{
		pressedKeyCodes.erase(it);
	}
	 */
	 
	keyCode = SYS_KeyCodeConvertSpecial(keyCode, isShift, isAlt, isControl);

	LOGI(".........SYS_KeyCodeConvertSpecial converted key is ", keyCode);

	debugInterface->KeyboardUp(keyCode); //bareKey);
	
	// workaround for keeping pressed shift
	if (keyCode != MTKEY_LSHIFT
		&& keyCode != MTKEY_RSHIFT
		&& isShift)
	{
		if (guiMain->isLeftShiftPressed)
		{
			LOGD("workaround: send keydown MTKEY_LSHIFT");
			debugInterface->KeyboardDown(MTKEY_LSHIFT);
			shiftDown = true;
		}
		if (guiMain->isRightShiftPressed)
		{
			LOGD("workaround: send keydown MTKEY_RSHIFT");
			debugInterface->KeyboardDown(MTKEY_RSHIFT);
			shiftDown = true;
		}
	}
	else if (!isShift && shiftDown)
	{
		LOGD("workaround: send key UP L/R SHIFT");
		c64d_keyboard_force_key_up_latch(MTKEY_LSHIFT);
		c64d_keyboard_force_key_up_latch(MTKEY_RSHIFT);
		shiftDown = false;
	}
	
	if ((keyCode == MTKEY_LALT || keyCode == MTKEY_RALT) && !isShift)
	{
		LOGD("workaround 2: send key UP L/R SHIFT");
		c64d_keyboard_force_key_up_latch(MTKEY_LSHIFT);
		c64d_keyboard_force_key_up_latch(MTKEY_RSHIFT);
		shiftDown = false;
	}
	
	debugInterface->UnlockIoMutex();
	
	return true;

//	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewC64Screen::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewC64Screen::JoystickDown(u32 axis)
{
	if (c64SettingsJoystickPort == 0)
	{
		// both ports
		debugInterface->JoystickDown(1, axis);
		debugInterface->JoystickDown(2, axis);
	}
	else
	{
		debugInterface->JoystickDown(c64SettingsJoystickPort, axis);
	}
}

void CViewC64Screen::JoystickUp(u32 axis)
{
	if (c64SettingsJoystickPort == 0)
	{
		// both ports
		debugInterface->JoystickUp(1, axis);
		debugInterface->JoystickUp(2, axis);
	}
	else
	{
		debugInterface->JoystickUp(c64SettingsJoystickPort, axis);
	}
}


void CViewC64Screen::ActivateView()
{
	LOGG("CViewC64Screen::ActivateView()");
}

void CViewC64Screen::DeactivateView()
{
	LOGG("CViewC64Screen::DeactivateView()");
}
