#include "C64D_Version.h"

#include "NstApiMachine.hpp"
#include "NstMachine.hpp"
#include "NstApiEmulator.hpp"
#include "NstCpu.hpp"
#include "NstPpu.hpp"

#include "NesPpuNmtDataAdapter.h"
#include "NesDebugInterface.h"
#include "CViewNesPpuPalette.h"
#include "CColorsTheme.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "VID_ImageBinding.h"
#include "CViewC64.h"
#include "SYS_KeyCodes.h"
#include "NesDebugInterface.h"
#include "C64SettingsStorage.h"
#include "C64KeyboardShortcuts.h"

extern Nes::Api::Emulator nesEmulator;

CViewNesPpuPalette::CViewNesPpuPalette(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, NesDebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewNesPpuPalette";
	
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
	
	// screen texture boundaries
	screenTexEndX = (float)debugInterface->GetScreenSizeX() / 512.0f;
	screenTexEndY = 1.0f - (float)debugInterface->GetScreenSizeY() / 512.0f;

	this->showGridLines = true;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}


CViewNesPpuPalette::~CViewNesPpuPalette()
{
}

void CViewNesPpuPalette::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewNesPpuPalette::RefreshScreen()
{
//	LOGD("CViewNesPpuPalette::RefreshScreen");
	
	debugInterface->LockRenderScreenMutex();
	
	// refresh texture of Nes screen
	CImageData *screen = debugInterface->GetScreenImageData();
	
#if !defined(FINAL_RELEASE)
	if (screen == NULL)
	{
		//LOGError("CViewNesPpuPalette::RefreshScreen: screen is NULL!");
		debugInterface->UnlockRenderScreenMutex();
		return;
	}
#endif
	
	imageScreen->SetLoadImageData(screen);
	imageScreen->ReBindImage();
	imageScreen->loadImageData = NULL;
	
	debugInterface->UnlockRenderScreenMutex();
}


void CViewNesPpuPalette::Render()
{
//	LOGD("CViewNesPpuPalette::Render");
//	guiMain->fntConsole->BlitText("Palette", posX, posY, -1, 5);

	Nes::Core::Machine& machine = nesEmulator;
	Nes::Core::Video::Screen screen = machine.ppu.GetScreen();

	float sx = sizeX/16.0f;
	float sy = sizeY/2.0f;
	
	int colorIndex = 0;
	float py = posY;
	for (int y = 0; y < 2; y++)
	{
		float px = posX;
		for (int x = 0; x < 16; x++)
		{
			u32 pixel = machine.ppu.output.palette[colorIndex];
			u32 rgba = screen.palette[pixel];

			u8 r = (rgba & 0x000000FF)       & 0x000000FF;
			u8 g = (rgba & 0x0000FF00) >> 8  & 0x000000FF;
			u8 b = (rgba & 0x00FF0000) >> 16 & 0x000000FF;

			float fr = (float)r / 255.0f;
			float fg = (float)g / 255.0f;
			float fb = (float)b / 255.0f;
			
			BlitFilledRectangle(px, py, -1, sx, sy, fr, fg, fb, 1);

			colorIndex++;
			px += sx;
		}
		py += sy;
	}
	
	// grid
	float px = posX;
	const float s = 0.5f;
	const float s2 = s*2.0f;
	for (int x = 0; x < 16; x++)
	{
		BlitFilledRectangle(px - s, posY, -1, s2, sizeY, 0.0f, 0.0f, 0.0f, 0.75f);
		px += sx;
	}
	BlitFilledRectangle(posX, posY + sy - s, -1, sizeX, s2, 0.0f, 0.0f, 0.0f, 0.75f);

	if (HasFocus())
	{
		BlitRectangle(posX, posY, -1, sizeX, sizeY, 1.0f, 0.0f, 0, 1);
	}
	else
	{
		BlitRectangle(posX, posY, -1, sizeX, sizeY, 0.5f, 0.5f, 0.5f, 1);
	}

	return;
	
	RefreshScreen();
	
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
		 posX,
		 posY, -1,
		 sizeX,
		 sizeY,
		 0.0f, 1.0f, screenTexEndX, screenTexEndY);
	
//	if (showGridLines)
//	{
//		// raster screen in hex:
//		// startx = 68 (88) endx = 1e8 (1c8)
//		// starty = 10 (32) endy = 120 ( fa)
//
//		float cys = posY + (float)0x0010 * rasterScaleFactorY  + rasterCrossOffsetY;
//		float cye = posY + (float)0x0120 * rasterScaleFactorY  + rasterCrossOffsetY;
//
//		float cxs = posX + (float)0x0068 * rasterScaleFactorX  + rasterCrossOffsetX;
//		float cxe = posX + (float)0x01E8 * rasterScaleFactorX  + rasterCrossOffsetX;
//
//
//		// vertical lines
//		for (float rasterX = 103.5f; rasterX < 0x01e8; rasterX += 0x08)
//		{
//			float cx = posX + (float)rasterX * rasterScaleFactorX  + rasterCrossOffsetX;
//
//			BlitLine(cx, cys, cx, cye, -1,
//					 gridLinesColorR, gridLinesColorG, gridLinesColorB, gridLinesColorA);
//		}
//
//		// horizontal lines
//		for (float rasterY = 18.5f; rasterY < 0x0120; rasterY += 0x08)
//		{
//			float cy = posY + (float)rasterY * rasterScaleFactorY  + rasterCrossOffsetY;
//
//			BlitLine(cxs, cy, cxe, cy, -1,
//					 gridLinesColorR, gridLinesColorG, gridLinesColorB, gridLinesColorA);
//		}
//	}
	
}

void CViewNesPpuPalette::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewNesPpuPalette::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

//@returns is consumed
bool CViewNesPpuPalette::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewNesPpuPalette::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CViewNesPpuPalette::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewNesPpuPalette::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewNesPpuPalette::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewNesPpuPalette::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewNesPpuPalette::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewNesPpuPalette::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewNesPpuPalette::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewNesPpuPalette::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewNesPpuPalette::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewNesPpuPalette::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewNesPpuPalette::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewNesPpuPalette::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewNesPpuPalette::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewNesPpuPalette::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewNesPpuPalette::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI(".......... CViewNesPpuPalette::KeyDown: keyCode=%d", keyCode);
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewNesPpuPalette::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI(".......... CViewNesPpuPalette::KeyUp: keyCode=%d", keyCode);
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewNesPpuPalette::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewNesPpuPalette::ActivateView()
{
	LOGG("CViewNesPpuPalette::ActivateView()");
}

void CViewNesPpuPalette::DeactivateView()
{
	LOGG("CViewNesPpuPalette::DeactivateView()");
}
