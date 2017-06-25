#include "CViewC64Palette.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "C64Tools.h"
#include "CViewC64Screen.h"
#include "C64DebugInterface.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "VID_ImageBinding.h"
#include "CViewC64.h"
#include "CViewVicEditor.h"
#include "C64DebugInterfaceVice.h"
#include "C64VicDisplayCanvas.h"

CViewC64Palette::CViewC64Palette(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64Palette";
	this->vicEditor = vicEditor;

	viewFrame = new CGuiViewFrame(this, new CSlrString("Palette"));
	this->AddGuiElement(viewFrame);
	
	this->isVertical = false;
	
	this->SetPosition(posX, posY, sizeX, false);
	
	colorD020 = 14;
	colorD021 = 6;
	colorLMB = 15;
	colorRMB = 14;
}

void CViewC64Palette::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	LOGD("CViewC64Palette::SetPosition: %f %f", posX, posY);
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64Palette::SetPosition(float posX, float posY, float sizeX, bool isVertical)
{
	this->isVertical = isVertical;
	
	if (!isVertical)
	{
		// horizontal size
		//float size1 = 10*scale + 8*gap1 + gap2;
		float newScale = (sizeX - 8*gap1 - gap2)/10.0f;
		
		this->SetPosition(this->posX, this->posY, this->posZ, newScale);
		
	}
	else
	{
		SYS_FatalExit("TODO");
	}
}


// scale is scale of a colour rect
void CViewC64Palette::SetPosition(float posX, float posY, float posZ, float scale)
{
	// so we have
	this->gap1 = scale / 8.0f;
	this->gap2 = scale / 4.0f;
	this->rectSize = scale;
	this->rectSize4 = scale/4.0f;
	
	this->rectSizeBig = scale * 2.15f;
	
	float size1 = 8*scale + 7*gap1 + gap2 + scale*2 + gap1;
	float size2 = scale * 2.0f + gap1;

	if (!isVertical)
	{
		this->SetPosition(posX, posY, posZ, size1, size2);
	}
	else
	{
		this->SetPosition(posX, posY, posZ, size2, size1);
	}
}


void CViewC64Palette::DoLogic()
{
	CGuiView::DoLogic();
}


void CViewC64Palette::Render()
{
//	LOGD("CViewC64Palette::Render: pos=%f %f", posX, posY);
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, viewFrame->barColorR, viewFrame->barColorG, viewFrame->barColorB, 1);
	float py = posY;
	float px;
	
	if (!isVertical)
	{
		int colNum = 0;
		for (int p = 0; p < 2; p++)
		{
			px = posX;
			for (int i = 0; i < 8; i++)
			{
				float fr,fg,fb;
				viewC64->debugInterface->GetFloatCBMColor(colNum, &fr, &fg, &fb);
				BlitFilledRectangle(px, py, posZ, rectSize, rectSize, fr, fg, fb, 1.0f);

				if (colNum == this->colorLMB)
				{
					BlitRectangle(px+1, py+1, posZ, rectSize-1, rectSize-1, 1.0f, 0.2f, 0.2f, 1.0f, 1.0f);
				}
				
				colNum++;

				px += rectSize+gap1;
			}
			
			py += rectSize + gap1;
		}
		
		//
		// background
		float sy = posY;
		float sx = px + gap1;
		py = sy;
		px = sx;
		
		float r,g,b;
		viewC64->debugInterface->GetFloatCBMColor(colorD021, &r, &g, &b);
		
		BlitFilledRectangle(px, py, posZ, rectSizeBig, rectSizeBig, r, g, b, 1);
		
		sx += gap2;
		sy += gap2;
		
		px = sx + rectSize*0.65f;
		py = sy + rectSize*0.65f;
		
		viewC64->debugInterface->GetFloatCBMColor(colorRMB, &r, &g, &b);
		BlitFilledRectangle(px, py, posZ, rectSize, rectSize, r, g, b, 1);
		BlitRectangle(px, py, posZ, rectSize, rectSize, 0, 0, 0, 1);
		
		px = sx;
		py = sy;
		viewC64->debugInterface->GetFloatCBMColor(colorLMB, &r, &g, &b);
		BlitFilledRectangle(px, py, posZ, rectSize, rectSize, r, g, b, 1);
		BlitRectangle(px, py, posZ, rectSize, rectSize, 0, 0, 0, 1);
	}
	
	
	CGuiView::Render();

	BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0, 0, 0, 1, 1);
}

bool CViewC64Palette::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Palette::DoTap: %f %f", x, y);
	
	if (IsInside(x, y))
	{
		int colorIndex = GetColorIndex(x, y);
		
		if (colorIndex != -1)
		{
			SetColorLMB(colorIndex);
			return true;
		}
		
		return true;
	}
	
	return CGuiView::DoTap(x, y);
}

bool CViewC64Palette::DoRightClick(GLfloat x, GLfloat y)
{
	LOGI("CViewC64Palette::DoRightClick: %f %f", x, y);

	if (IsInside(x, y))
	{
		LOGD(".......inside");
		int colorIndex = GetColorIndex(x, y);
		
		if (colorIndex != -1)
		{
			SetColorRMB(colorIndex);

			LOGD(" CViewC64Palette: ret true");
			return true;
		}
		
		return true;
	}
	
	LOGD(" CViewC64Palette: ret CGuiView::DoRightClick");
	return CGuiView::DoRightClick(x, y);
}

bool CViewC64Palette::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->IsInsideView(x, y))
		return true;
	
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

int CViewC64Palette::GetColorIndex(float x, float y)
{
	LOGD("CViewC64Palette::GetColorIndex: %f %f", x, y);
	
	float py = posY;
	
	if (!isVertical)
	{
		int colNum = 0;
		for (int p = 0; p < 2; p++)
		{
			float px = posX;
			for (int i = 0; i < 8; i++)
			{
				if (x >= px && x <= (px + rectSize)
					&& y >= py && y <= (py + rectSize))
				{
					return colNum;
				}
				
				colNum++;
				
				px += rectSize+gap1;
			}
			
			py += rectSize + gap1;
		}
	}
	
	return -1;
}


bool CViewC64Palette::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CViewC64Palette::KeyDown: %d", keyCode);
	
	if (keyCode == 'x')
	{
		u8 t = colorLMB;
		SetColorLMB(colorRMB);
		SetColorRMB(t);
		return true;
	}
	
	return false;
}

bool CViewC64Palette::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewC64Palette::SetFocus(bool focus)
{
	return true;
}

void CViewC64Palette::SetColorLMB(u8 color)
{
	this->colorLMB = color;
	vicEditor->PaletteColorChanged(VICEDITOR_COLOR_SOURCE_LMB, color);
}

void CViewC64Palette::SetColorRMB(u8 color)
{
	this->colorRMB = color;
	vicEditor->PaletteColorChanged(VICEDITOR_COLOR_SOURCE_RMB, color);
}

