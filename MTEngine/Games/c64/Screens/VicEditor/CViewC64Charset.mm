#include "CViewC64Charset.h"
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
#include "C64DebugInterfaceVice.h"
#include "CViewVicEditor.h"
#include "CViewC64VicDisplay.h"
#include "CViewDataDump.h"

CViewC64Charset::CViewC64Charset(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64Charset";
	
	this->vicEditor = vicEditor;
	
	viewFrame = new CGuiViewFrame(this, new CSlrString("Charset"));
	
	int w = 256;
	int h = 64;
	imageDataCharset = new CImageData(w, h, IMG_TYPE_RGBA);
	imageDataCharset->AllocImage(false, true);
		
	imageCharset = new CSlrImage(true, true);
	imageCharset->LoadImage(imageDataCharset, RESOURCE_PRIORITY_STATIC, false);
	imageCharset->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	imageCharset->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(imageCharset, NULL);

	selX = -1;
	selY = -1;
	selSizeX = this->sizeX / 32.0f;
	selSizeY = this->sizeY / 8.0f;
	
	this->AddGuiElement(viewFrame);
	
	SelectChar(17 + 0x40);
}

void CViewC64Charset::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	LOGD("CViewC64Charset::SetPosition: %f %f", posX, posY);
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	selSizeX = this->sizeX / 32.0f;
	selSizeY = this->sizeY / 8.0f;
}

void CViewC64Charset::DoLogic()
{
	CGuiView::DoLogic();
}


void CViewC64Charset::Render()
{
//	LOGD("CViewC64Charset::Render: pos=%f %f", posX, posY);
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, viewFrame->barColorR, viewFrame->barColorG, viewFrame->barColorB, 1);
	float py = posY;
	float px;
	
	vicii_cycle_state_t *viciiState = &(viewC64->viciiStateToShow);

	u8 *screen_ptr;
	u8 *color_ram_ptr;
	u8 *chargen_ptr;
	u8 *bitmap_low_ptr;
	u8 *bitmap_high_ptr;
	u8 colors[0x0F];
	
	vicEditor->viewVicDisplayMain->GetViciiPointers(viciiState, &screen_ptr, &color_ram_ptr, &chargen_ptr, &bitmap_low_ptr, &bitmap_high_ptr, colors);

	if (viewC64->viewC64VicDisplay->backupRenderDataWithColors)
	{
		CopyMultiCharsetToImage(chargen_ptr, imageDataCharset, 32, colors[1], colors[2], colors[3], viewC64->colorToShowD800, viewC64->debugInterface);
	}
	else
	{
		CopyHiresCharsetToImage(chargen_ptr, imageDataCharset, 32, 0, 1, viewC64->debugInterface);
	}

	imageCharset->ReplaceImageData(imageDataCharset);

	
	//viewC64->debugInterface
	
	// TODO: create generic engine function for this
	
	// nearest neighbour
	{
		glBindTexture(GL_TEXTURE_2D, this->imageCharset->texture[0]);
		
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	
	Blit(this->imageCharset, posX, posY, posZ, sizeX, sizeY);
	
	
//	// back to linear scale
//	{
//		glBindTexture(GL_TEXTURE_2D, this->imageCharset->texture[0]);
//		
//		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
//	}

	if (selectedChar >= 0)
	{
		BlitRectangle(this->posX + selX, this->posY + selY, posZ, selSizeX, selSizeY, 1.0f, 0.0f, 0.0f, 1.0f, 1.5f);
	}
	
	
	CGuiView::Render();

	BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0, 0, 0, 1, 1);
}

bool CViewC64Charset::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64Charset::DoTap: %f %f", x, y);

	if (this->IsInsideView(x, y))
	{
		int xp = (int)floor((x - this->posX) / selSizeX);
		int yp = (int)floor((y - this->posY) / selSizeY);
		
		int chr = yp * 32 + xp;
		
		this->SelectChar(chr);
		return true;
	}
	
	
	return CGuiView::DoTap(x, y);
}

bool CViewC64Charset::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->IsInsideView(x, y))
		return true;
	
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}


int CViewC64Charset::GetSelectedChar()
{
	return selectedChar;
}

void CViewC64Charset::SelectChar(int chr)
{
	if (chr < 0 || chr > 255)
	{
		this->selectedChar = -1;
		return;
	}
	
	this->selectedChar = chr;
	

	selSizeX = this->sizeX / 32.0f;
	selSizeY = this->sizeY / 8.0f;

	int row = floor((float)chr / 32.0f);
	int col = chr % 32;
	
	selX = selSizeX * col;
	selY = selSizeY * row;

}


bool CViewC64Charset::DoRightClick(GLfloat x, GLfloat y)
{
	LOGI("CViewC64Charset::DoRightClick: %f %f", x, y);
	
	if (this->IsInsideView(x, y))
		return true;
	
	return CGuiView::DoRightClick(x, y);
}


bool CViewC64Charset::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD("CViewC64Charset::KeyDown: %d", keyCode);
	
	return false;
}

bool CViewC64Charset::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewC64Charset::SetFocus(bool focus)
{
	return true;
}

