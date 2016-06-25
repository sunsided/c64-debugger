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
#include "C64DebugInterface.h"
#include "SYS_Threading.h"
#include "CGuiEditHex.h"
#include "VID_ImageBinding.h"

CViewC64StateVIC::CViewC64StateVIC(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64StateVIC";
	
	this->debugInterface = debugInterface;

	
	
	fontSize = 5.0f;
	
	fontBytes = guiMain->fntConsole;
	
	isVertical = false;
	
	spritesImageData = new std::vector<CImageData *>();
	spritesImages = new std::vector<CSlrImage *>();
	
	// init images for sprites
	for (int i = 0; i < 8; i++)
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
	
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateVIC::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
}

void CViewC64StateVIC::DoLogic()
{
}


void CViewC64StateVIC::Render()
{
//	if (debugInterface->GetSettingIsWarpSpeed() == true)
//		return;

	viewC64->debugInterface->RenderStateVIC(posX, posY, posZ, isVertical, fontBytes, fontSize, spritesImageData, spritesImages,
											viewC64->viewC64MemoryDataDump->renderDataWithColors);
}

bool CViewC64StateVIC::DoTap(GLfloat x, GLfloat y)
{
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

void CViewC64StateVIC::SetFocus(bool focus)
{
	return;
}


