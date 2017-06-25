#include "CViewVicEditorLayers.h"
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
#include "CVicEditorLayer.h"
#include <list>

CViewVicEditorLayers::CViewVicEditorLayers(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewVicEditorLayers";
	
	this->vicEditor = vicEditor;
	
	float px = posX + 11.5f;
	float py = posY + 1.0f;
	
	float sx = sizeX - 5.0f;
	float sy = 50;
	
	font = viewC64->fontCBMShifted;
	fontScale = 1.25f;
	float upGap = 0.0f;
	float elementsGap = -1.0f;

	this->lstLayers = new CGuiList(px, py, posZ, sx, sy, fontScale,
									  NULL, 0, false,
									  font,
									  guiMain->theme->imgBackground, 1.0f,
									  this);
	this->lstLayers->SetGaps(upGap, elementsGap);
	this->lstLayers->textOffsetY = 2.1f;
	this->lstLayers->fontSelected = viewC64->fontCBMShifted;
	this->AddGuiElement(this->lstLayers);

	RefreshLayers();
	
	viewFrame = new CGuiViewFrame(this, new CSlrString("Layers"));
	this->AddGuiElement(viewFrame);
}

void CViewVicEditorLayers::RefreshLayers()
{
	guiMain->LockMutex();
	
	while(!btnsVisible.empty())
	{
		CGuiButtonSwitch *btn = btnsVisible.back();
		btnsVisible.pop_back();
		
		RemoveGuiElement(btn);
		delete btn;
	}
	char **items = new char *[vicEditor->layers.size()];
	
	int i = 0;
	for (std::list<CVicEditorLayer *>::reverse_iterator it = vicEditor->layers.rbegin();
		 it != vicEditor->layers.rend(); it++)
	{
		CVicEditorLayer *layer = *it;
		int len = strlen(layer->layerName);
		
		items[i] = new char[len+1];
		strcpy(items[i], layer->layerName);
		
		i++;
	}
	this->lstLayers->Init(items, vicEditor->layers.size(), true);

	// create buttons
	float px = posX + 2.0f;
	float py = posY + 2.5f;
	float buttonSizeX = 12.0f;
	float buttonSizeY = 8.0f;

	for (std::list<CVicEditorLayer *>::reverse_iterator it = vicEditor->layers.rbegin();
		 it != vicEditor->layers.rend(); it++)
	{
		CVicEditorLayer *layer = *it;
		
		CSlrString *buttonText;
		if (layer != (CVicEditorLayer *)vicEditor->layerVirtualSprites)
		{
			buttonText = new CSlrString("V");
		}
		else
		{
			// virtual sprites layer does not show sprites
			buttonText = new CSlrString("P");
		}
		
		CGuiButtonSwitch *btnVisible = new CGuiButtonSwitch(NULL, NULL, NULL,
												 px, py, posZ, buttonSizeX, buttonSizeY,
												 buttonText,
												 FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
												 font, fontScale,
												 1.0, 1.0, 1.0, 1.0,
												 1.0, 1.0, 1.0, 1.0,
												 0.3, 0.3, 0.3, 1.0,
												 this);
		btnVisible->SetOn(layer->isVisible);
		btnVisible->textDrawPosY = 1.75f;
		btnVisible->buttonEnabledColorA = 0.25f;
		btnVisible->userData = layer;
		this->AddGuiElement(btnVisible);
	
		this->btnsVisible.push_back(btnVisible);

		py += 9.0f;
	}
	
	guiMain->UnlockMutex();

}

void CViewVicEditorLayers::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	LOGD("CViewVicEditorLayers::SetPosition: %f %f", posX, posY);
	
	// TODO: fix this and let guiview manage this
	CGuiView::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	float px = posX + 11.5f;
	float py = posY + 1.0f;

	lstLayers->SetPosition(px, py);

	// move buttons
	px = posX + 2.0f;
	py = posY + 2.5f;
	
	for (std::vector<CGuiButtonSwitch *>::iterator it = this->btnsVisible.begin();
		 it != this->btnsVisible.end(); it++)
	{
		CGuiButtonSwitch *btnVisible = *it;
		btnVisible->SetPosition(px, py);
		
		py += 9.0f;
	}
}


bool CViewVicEditorLayers::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	LOGD("CViewVicEditorLayers::ButtonSwitchChanged");
	
	CVicEditorLayer *layer = (CVicEditorLayer *)button->userData;
	
	layer->isVisible = button->IsOn();
	
	return false;
}

void CViewVicEditorLayers::ListElementSelected(CGuiList *listBox)
{
	LOGD("CViewVicEditorLayers::ListElementSelected");
	
	if (listBox->selectedElement == -1)
	{
		SelectLayer(NULL);
	}
	else
	{
		CGuiButtonSwitch *btnLayer = btnsVisible[listBox->selectedElement];
		SelectLayer((CVicEditorLayer *)btnLayer->userData);
	}
}

void CViewVicEditorLayers::SelectLayer(CVicEditorLayer *layer)
{
	if (vicEditor->selectedLayer == layer || layer == NULL)
	{
		// unselect
		vicEditor->SelectLayer(NULL);
		lstLayers->SetElement(-1, false);
		return;
	}
	
	vicEditor->SelectLayer(layer);
}

void CViewVicEditorLayers::SelectNextLayer()
{
	LOGD("CViewVicEditorLayers::SelectNextLayer");
	
	int el = this->lstLayers->selectedElement;
	
	for (int i = 0; i < btnsVisible.size(); i++)
	{
		el++;
		if (el == btnsVisible.size())
		{
			el = 0;
		}
		
		if (btnsVisible[el]->IsOn())
		{
			this->lstLayers->SetElement(el, false);
			return;
		}
	}
}

void CViewVicEditorLayers::DoLogic()
{
	CGuiView::DoLogic();
}


void CViewVicEditorLayers::Render()
{
	BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY, viewFrame->barColorR, viewFrame->barColorG, viewFrame->barColorB, 1);

	CGuiView::Render();

	BlitRectangle(posX, posY, posZ, sizeX, sizeY, 0, 0, 0, 1, 1);
}

bool CViewVicEditorLayers::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewVicEditorLayers::DoTap: %f %f", x, y);

//	if (this->IsInsideView(x, y))
//	{
//		if (CGuiView::DoTapNoBackground(x, y) == false)
//		{
//			SelectLayer(NULL);
//		}
//	}
	
	if (CGuiView::DoTap(x, y) == false)
	{
		if (this->IsInsideView(x, y))
		{
			return true;
		}
	}
	
	return CGuiView::DoTap(x, y);;
}

bool CViewVicEditorLayers::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->IsInsideView(x, y))
		return true;
	
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}


bool CViewVicEditorLayers::DoRightClick(GLfloat x, GLfloat y)
{
	LOGI("CViewVicEditorLayers::DoRightClick: %f %f", x, y);
	
	if (this->IsInsideView(x, y))
		return true;
	
	return CGuiView::DoRightClick(x, y);
}


bool CViewVicEditorLayers::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGD("CViewVicEditorLayers::KeyDown: %d", keyCode);
	
	return false;
}

bool CViewVicEditorLayers::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CViewVicEditorLayers::SetFocus(bool focus)
{
	return true;
}

