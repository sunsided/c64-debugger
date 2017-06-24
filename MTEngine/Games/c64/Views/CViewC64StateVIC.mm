extern "C" {
#include "viciitypes.h"
}

#include "CViewC64StateVIC.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CGuiMain.h"
#include "CSlrDataAdapter.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "CViewDataDump.h"
#include "C64Tools.h"
#include "CViewC64Screen.h"
#include "CViewDataDump.h"
#include "CViewC64VicDisplay.h"
#include "C64DebugInterface.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "VID_ImageBinding.h"
#include "C64DebugInterfaceVice.h"

CViewC64StateVIC::CViewC64StateVIC(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64StateVIC";
	
	this->debugInterface = debugInterface;

	isLockedState = false;

	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	isVertical = false;
	
	spritesImageData = new std::vector<CImageData *>();
	spritesImages = new std::vector<CSlrImage *>();
	
	// init images for sprites
	for (int i = 0; i < 0x0F; i++)
	{
		// alloc image that will store character pixels
		CImageData *imageData = new CImageData(32, 32, IMG_TYPE_RGBA);
		imageData->AllocImage(false, true);
		
		spritesImageData->push_back(imageData);
		
		/// init CSlrImage with empty image (will be deleted by loader)
		CImageData *emptyImageData = new CImageData(32, 32, IMG_TYPE_RGBA);
		emptyImageData->AllocImage(false, true);
		
		CSlrImage *imageSprite = new CSlrImage(true, false);
		imageSprite->LoadImage(emptyImageData, RESOURCE_PRIORITY_STATIC, false);
		imageSprite->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
		imageSprite->resourcePriority = RESOURCE_PRIORITY_STATIC;
		VID_PostImageBinding(imageSprite, NULL);
		
		spritesImages->push_back(imageSprite);
	}
	
	// do not force colors
	for (int i = 0; i < 0x0F; i++)
	{
		forceColors[i] = -1;
	}
	forceColorD800 = -1;
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateVIC::SetPosition(GLfloat posX, GLfloat posY)
{
	CGuiView::SetPosition(posX, posY, posZ, fontSize*52, fontSize*29);
}

void CViewC64StateVIC::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateVIC::DoLogic()
{
}

void CViewC64StateVIC::UpdateSpritesImages()
{
	C64DebugInterfaceVice *vice = (C64DebugInterfaceVice*)viewC64->debugInterface;
	
	vice->UpdateVICSpritesImages(&(viewC64->viciiStateToShow),
								 spritesImageData, spritesImages,
								 viewC64->viewC64MemoryDataDump->renderDataWithColors);
}

void CViewC64StateVIC::RenderColorRectangle(float px, float py, float ledSizeX, float ledSizeY, float gap, bool isLocked, u8 color)
{
	float colorR, colorG, colorB;
	viewC64->debugInterface->GetFloatCBMColor(color, &colorR, &colorG, &colorB);
	
	BlitFilledRectangle(px, py, posZ, ledSizeX, ledSizeY,
						colorR, colorG, colorB, 1.0f);
	
	
	if (!isLocked)
	{
		colorR = colorG = colorB = 0.3f;
	}
	else
	{
		colorR = 1.0f;
		colorG = colorB = 0.3f;
	}
	
	BlitRectangle(px, py - gap, posZ, ledSizeX, ledSizeY,
				  colorR, colorG, colorB, 1.0f, gap);
	
}

void CViewC64StateVIC::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;
	
	//BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0.2f, 1.0f, 1.0f, 1.0f);
	
	
	if (isLockedState)
	{
		BlitFilledRectangle(posX, posY, posZ, fontSize*56.6, fontSize*26, 0.2f, 0.0f, 0.0f, 1.0f);
	}

	viewC64->debugInterface->RenderStateVIC(&(viewC64->viciiStateToShow),
											posX, posY, posZ, isVertical, showSprites, fontBytes, fontSize,
											spritesImageData, spritesImages,
											viewC64->viewC64MemoryDataDump->renderDataWithColors);
	
	// render colors
	if (isVertical == false)
	{
		float ledX = posX + fontSize * 37.0f;
		float ledY = posY + fontSize * 4.5;
		
		char buf[8] = { 'D', '0', '2', '0', 0x00 };
		float ledSizeX = fontSize*4.0f;
		float gap = fontSize * 0.1f;
		float step = fontSize * 0.75f;
		float ledSizeY = fontSize + gap + gap;
		
		float px = ledX;
		float py = ledY;
		float py2 = py + fontSize + gap;
		
		// D020-D023
		for (int i = 0x00; i < 0x04; i++)
		{
			buf[3] = 0x30 + i;
			guiMain->fntConsole->BlitText(buf, px, py, posZ, fontSize);
			
			u8 color = viewC64->colorsToShow[i];
			bool isForced = (this->forceColors[i] != -1);
			RenderColorRectangle(px, py2, ledSizeX, ledSizeY, gap, isForced, color);
			
			px += ledSizeX + step;
		}

		px = ledX;
		py += ledSizeY + fontSize + step;
		py2 = py + fontSize + gap;
		
		// D024-D027
		for (int i = 0x04; i < 0x07; i++)
		{
			buf[3] = 0x30 + i;
			guiMain->fntConsole->BlitText(buf, px, py, posZ, fontSize);
			
			u8 color = viewC64->colorsToShow[i];
			bool isForced = (this->forceColors[i] != -1);
			RenderColorRectangle(px, py2, ledSizeX, ledSizeY, gap, isForced, color);
			
			px += ledSizeX + step;
		}
		
		// D800
		guiMain->fntConsole->BlitText("RAM", px, py, posZ, fontSize);

		u8 color = viewC64->colorToShowD800;
		bool isForced = (this->forceColorD800 != -1);
		RenderColorRectangle(px, py2, ledSizeX, ledSizeY, gap, isForced, color);

		
		// sprite colors
		px = posX + fontSize * 10.5f;
		py = posY + fontSize * 12.75f;
		step = fontSize * 6;
		
		// D027-D02E
		for (int i = 0x07; i < 0x0F; i++)
		{
			u8 color = viewC64->colorsToShow[i];
			bool isForced = (this->forceColors[i] != -1);
			RenderColorRectangle(px, py, ledSizeX, ledSizeY, gap, isForced, color);
			
			px += step;
		}

	}

}

bool CViewC64StateVIC::DoTap(GLfloat x, GLfloat y)
{
	// lock / unlock
	if (isVertical == false)
	{
		float ledX = posX + fontSize * 37.0f;
		float ledY = posY + fontSize * 4.5;
		float ledSizeX = fontSize*4.0f;
		float gap = fontSize * 0.1f;
		float step = fontSize * 0.75f;
		float ledSizeY = fontSize + gap + gap;
		float ledSizeY2 = ledSizeY + fontSize + step;
		
		float px = ledX;
		float py = ledY;
		float py2 = py + fontSize + gap;
		
		// D020-D023
		for (int i = 0x00; i < 0x04; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);
				
				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				else
				{
					this->forceColors[i] = -1;
				}
				
				return true;
			}
			
			px += ledSizeX + step;
		}
		
		px = ledX;
		py += ledSizeY + fontSize + step;
		py2 = py + fontSize + gap;
		
		// D024-D027
		for (int i = 0x04; i < 0x07; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);
				
				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				else
				{
					this->forceColors[i] = -1;
				}
				
				return true;
			}

			px += ledSizeX + step;
		}
		
		// D800
		if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
		{
			LOGD("clicked d800");
			
			if (this->forceColorD800 == -1)
			{
				this->forceColorD800 = viewC64->colorToShowD800;
			}
			else
			{
				this->forceColorD800 = -1;
			}

			return true;
		}
		
		
		// sprite colors
		px = posX + fontSize * 10.5f;
		py = posY + fontSize * 12.75f;
		step = fontSize * 6;
		
		// D027-D02E
		for (int i = 0x07; i < 0x0F; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);

				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				else
				{
					this->forceColors[i] = -1;
				}
				
				return true;
			}
			
			px += step;
		}
		
	}
	
	
	return false;
}

bool CViewC64StateVIC::DoRightClick(GLfloat x, GLfloat y)
{
	// lock / unlock
	if (isVertical == false)
	{
		float ledX = posX + fontSize * 37.0f;
		float ledY = posY + fontSize * 4.5;
		float ledSizeX = fontSize*4.0f;
		float gap = fontSize * 0.1f;
		float step = fontSize * 0.75f;
		float ledSizeY = fontSize + gap + gap;
		float ledSizeY2 = ledSizeY + fontSize + step;
		
		float px = ledX;
		float py = ledY;
		float py2 = py + fontSize + gap;
		
		// D020-D023
		for (int i = 0x00; i < 0x04; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);
				
				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				
				this->forceColors[i] = (this->forceColors[i] + 1) & 0x0F;
				
				return true;
			}
			
			px += ledSizeX + step;
		}
		
		px = ledX;
		py += ledSizeY + fontSize + step;
		py2 = py + fontSize + gap;
		
		// D024-D027
		for (int i = 0x04; i < 0x07; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);
				
				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				
				this->forceColors[i] = (this->forceColors[i] + 1) & 0x0F;
				
				return true;
			}
			
			px += ledSizeX + step;
		}
		
		// D800
		if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
		{
			LOGD("clicked d800");
			
			if (this->forceColorD800 == -1)
			{
				this->forceColorD800 = viewC64->colorToShowD800;
			}
			
			this->forceColorD800 = (this->forceColorD800 + 1) & 0x0F;
			
			return true;
		}
		
		
		// sprite colors
		px = posX + fontSize * 10.5f;
		py = posY + fontSize * 12.75f;
		step = fontSize * 6;
		
		// D027-D02E
		for (int i = 0x07; i < 0x0F; i++)
		{
			if (x >= px && x <= px + ledSizeX && y >= py && y <= py + ledSizeY2)
			{
				LOGD("clicked %02x", i);
				
				if (this->forceColors[i] == -1)
				{
					this->forceColors[i] = viewC64->colorsToShow[i];
				}
				else
				{
					this->forceColors[i] = (this->forceColors[i] + 1) & 0x0F;
				}
				
				return true;
			}
			
			px += step;
		}
		
	}
	
	return false;
}

bool CViewC64StateVIC::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	
	return false;
}

bool CViewC64StateVIC::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewC64StateVIC::SetFocus(bool focus)
{
	return false;
}


