#include "CViewC64SpritesSheet.h"
#include "CViewC64.h"
#include "VID_GLViewController.h"
#include "C64DebugInterface.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64VicControl.h"
#include "CGuiMain.h"
#include "CGuiLockableList.h"
#include "CSlrString.h"

CViewC64SpritesSheet::CViewC64SpritesSheet(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface)
: CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CViewC64SpritesSheet";
	this->debugInterface = debugInterface;
	
	this->consumeTapBackground = false;
	this->allowFocus = false;
	
	forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_NONE;
	
	numBitmapDisplays = 0x10000/0x2000;	//8
	
	numScreenDisplays = 0x10000/0x0400;	// 0x40
	
	numVicDisplays = numScreenDisplays;	// 0x40
	vicDisplays = new CViewC64VicDisplay *[numVicDisplays];
	vicControl = new CViewC64VicControl *[numVicDisplays];
	for (int i = 0; i < numVicDisplays; i++)
	{
		vicDisplays[i] = new CViewC64VicDisplay(0, 0, posZ, 100, 100, debugInterface);
		vicDisplays[i]->SetShowDisplayBorderType(VIC_DISPLAY_SHOW_BORDER_NONE);
		
		vicDisplays[i]->showSpritesFrames = false;
		vicDisplays[i]->showSpritesGraphics = false;
		
		vicControl[i] = new CViewC64VicControl(0, 0, posZ, 100, 100, vicDisplays[i]);
		vicControl[i]->visible = false;
		
		vicDisplays[i]->SetVicControlView(vicControl[i]);
		
		vicControl[i]->lstScreenAddresses->SetListLocked(true);
	}

	this->SetMode(VIEW_C64_ALL_GRAPHICS_MODE_BITMAPS);
	
	//
	font = viewC64->fontCBMShifted;
	fontScale = 0.8;
	fontHeight = font->GetCharHeight('I', fontScale) + 2;

	float px = posX + 350;
	float py = posY + 15;
	float buttonSizeX = 25.0f;
	float buttonSizeY = 10.0f;
	float gap = 5.0f;

	btnModeBitmapColorsGrayscale = new CGuiButtonSwitch(NULL, NULL, NULL,
										   px, py, posZ, buttonSizeX, buttonSizeY,
										   new CSlrString("B/W"),
										   FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
										   font, fontScale,
										   1.0, 1.0, 1.0, 1.0,
										   1.0, 1.0, 1.0, 1.0,
										   0.3, 0.3, 0.3, 1.0,
										   this);
	btnModeBitmapColorsGrayscale->SetOn(false);
	SetSwitchButtonDefaultColors(btnModeBitmapColorsGrayscale);
	this->AddGuiElement(btnModeBitmapColorsGrayscale);

	px += buttonSizeX + gap;

	btnModeHires = new CGuiButtonSwitch(NULL, NULL, NULL,
														px, py, posZ, buttonSizeX, buttonSizeY,
														new CSlrString("HIRES"),
														FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
														font, fontScale,
														1.0, 1.0, 1.0, 1.0,
														1.0, 1.0, 1.0, 1.0,
														0.3, 0.3, 0.3, 1.0,
														this);
	btnModeHires->SetOn(false);
	SetSwitchButtonDefaultColors(btnModeHires);
	this->AddGuiElement(btnModeHires);

	px += buttonSizeX + gap;
	
	btnModeMulti = new CGuiButtonSwitch(NULL, NULL, NULL,
										px, py, posZ, buttonSizeX, buttonSizeY,
										new CSlrString("MULTI"),
										FONT_ALIGN_CENTER, buttonSizeX/2, 3.5,
										font, fontScale,
										1.0, 1.0, 1.0, 1.0,
										1.0, 1.0, 1.0, 1.0,
										0.3, 0.3, 0.3, 1.0,
										this);
	btnModeMulti->SetOn(false);
	SetSwitchButtonDefaultColors(btnModeMulti);
	this->AddGuiElement(btnModeMulti);
	
	//
	// list of screen addresses
	px = posX + 350;
	py += buttonSizeY + gap;
	
	
	char **txtScreenAddresses = new char *[0x40];
	
	u16 addr = 0x0000;
	for (int i = 0; i < 0x40; i++)
	{
		char *txtAddr = new char[5];
		sprintf(txtAddr, "%04x", addr);
		addr += 0x0400;
		
		txtScreenAddresses[i] = txtAddr;
	}
	
	float lstFontSize = 4.0f;
	
	this->lstScreenAddresses = new CGuiLockableList(px, py, posZ+0.01, lstFontSize*6.5f, 65.0f, lstFontSize,
													NULL, 0, false,
													guiMain->fntConsole,
													guiMain->theme->imgBackground, 1.0f,
													this);
	this->lstScreenAddresses->Init(txtScreenAddresses, 0x40, true);
	this->lstScreenAddresses->SetGaps(0.0f, -0.25f);
	this->AddGuiElement(this->lstScreenAddresses);

}

CViewC64SpritesSheet::~CViewC64SpritesSheet()
{
}

void CViewC64SpritesSheet::SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn)
{
	btn->buttonSwitchOffColorR = 0.0f;
	btn->buttonSwitchOffColorG = 0.0f;
	btn->buttonSwitchOffColorB = 0.0f;
	btn->buttonSwitchOffColorA = 1.0f;
	
	btn->buttonSwitchOffColor2R = 0.3f;
	btn->buttonSwitchOffColor2G = 0.3f;
	btn->buttonSwitchOffColor2B = 0.3f;
	btn->buttonSwitchOffColor2A = 1.0f;
	
	btn->buttonSwitchOnColorR = 0.0f;
	btn->buttonSwitchOnColorG = 0.7f;
	btn->buttonSwitchOnColorB = 0.0f;
	btn->buttonSwitchOnColorA = 1.0f;
	
	btn->buttonSwitchOnColor2R = 0.3f;
	btn->buttonSwitchOnColor2G = 0.3f;
	btn->buttonSwitchOnColor2B = 0.3f;
	btn->buttonSwitchOnColor2A = 1.0f;
	
}

void CViewC64SpritesSheet::SetLockableButtonDefaultColors(CGuiButtonSwitch *btn)
{
	btn->buttonSwitchOffColorR = 0.0f;
	btn->buttonSwitchOffColorG = 0.0f;
	btn->buttonSwitchOffColorB = 0.0f;
	btn->buttonSwitchOffColorA = 1.0f;
	
	btn->buttonSwitchOffColor2R = 0.3f;
	btn->buttonSwitchOffColor2G = 0.3f;
	btn->buttonSwitchOffColor2B = 0.3f;
	btn->buttonSwitchOffColor2A = 1.0f;
	
	btn->buttonSwitchOnColorR = 0.7f;
	btn->buttonSwitchOnColorG = 0.0f;
	btn->buttonSwitchOnColorB = 0.0f;
	btn->buttonSwitchOnColorA = 1.0f;
	
	btn->buttonSwitchOnColor2R = 0.3f;
	btn->buttonSwitchOnColor2G = 0.3f;
	btn->buttonSwitchOnColor2B = 0.3f;
	btn->buttonSwitchOnColor2A = 1.0f;
	
}

void CViewC64SpritesSheet::SetMode(int newMode)
{
	guiMain->LockMutex();
	this->displayMode = newMode;
	
	if (displayMode == VIEW_C64_ALL_GRAPHICS_MODE_BITMAPS)
	{
		numVisibleDisplays = numBitmapDisplays;
		numDisplaysColumns = 2;
		
		numDisplaysRows = (float)numVisibleDisplays / (float)numDisplaysColumns;

		float px = posX;
		float py = posY;
		float displaySizeX = (SCREEN_WIDTH / (float)numDisplaysColumns) * 0.6f;
		float displaySizeY = SCREEN_HEIGHT / (float)numDisplaysRows;
		
		int i = 0;
		px = 0.0f;
		for(int x = 0; x < numDisplaysColumns; x++)
		{

			py = 0.0f;
			for (int y = 0; y < numDisplaysRows; y++)
			{
				LOGD("......px=%f py=%f", px, py);
				vicDisplays[i]->SetDisplayPosition(px, py, 0.45f, true);
				py += displaySizeY;
				
				vicControl[i]->btnModeBitmap->SetOn(true);
				vicControl[i]->lstBitmapAddresses->SetListLocked(true);
				vicControl[i]->lstBitmapAddresses->SetElement(i, false, false);
				
				i++;
			}
			px += displaySizeX;
		}
	}
	
	guiMain->UnlockMutex();
}

void CViewC64SpritesSheet::DoLogic()
{
	CGuiView::DoLogic();
}

void CViewC64SpritesSheet::Render()
{
	u16 screenAddress;
	vicii_cycle_state_t *viciiState = &viewC64->viciiStateToShow;
	
	screenAddress = viciiState->vbank_phi2 + ((viciiState->regs[0x18] & 0xf0) << 6);
	screenAddress = (screenAddress & viciiState->vaddr_mask_phi2) | viciiState->vaddr_offset_phi2;
	
	if (lstScreenAddresses->isLocked)
	{
		screenAddress = lstScreenAddresses->selectedElement * 0x0400;
	}
	else
	{
		bool updatePosition = true;
		
		if (lstScreenAddresses->IsInside(guiMain->mousePosX, guiMain->mousePosY))
			updatePosition = false;
		
		// update controls
		int addrItemNum = screenAddress / 0x0400;
		lstScreenAddresses->SetElement(addrItemNum, updatePosition, false);
	}

	//
	if (forcedRenderScreenMode == VIEW_C64_ALL_GRAPHICS_FORCED_NONE)
	{
		u8 mc;
		
		mc = (viciiState->regs[0x16] & 0x10) >> 4;

		btnModeBitmapColorsGrayscale->SetOn(false);
		btnModeHires->SetOn(!mc);
		btnModeMulti->SetOn(mc);
	}

	// TODO: move me to button press
	
	// vic displays
	for (int i = 0; i < numVisibleDisplays; i++)
	{
//		LOGD("Render VIC Display %d", i);
		int addrItemNum = screenAddress / 0x0400;
		vicDisplays[i]->viewVicControl->btnModeText->SetOn(false);
		vicDisplays[i]->viewVicControl->btnModeBitmap->SetOn(true);

		vicDisplays[i]->viewVicControl->btnModeStandard->SetOn(true);
		vicDisplays[i]->viewVicControl->btnModeExtended->SetOn(false);

//		LOGD("forcedRenderScreenMode=%d", forcedRenderScreenMode);
		switch(forcedRenderScreenMode)
		{
			case VIEW_C64_ALL_GRAPHICS_FORCED_NONE:
				vicDisplays[i]->viewVicControl->forceGrayscaleColors = false;
				vicDisplays[i]->viewVicControl->btnModeHires->SetOn(!btnModeMulti->IsOn());
				vicDisplays[i]->viewVicControl->btnModeMulti->SetOn(btnModeMulti->IsOn());
				break;
			case VIEW_C64_ALL_GRAPHICS_FORCED_GRAY:
				vicDisplays[i]->viewVicControl->forceGrayscaleColors = true;
				vicDisplays[i]->viewVicControl->btnModeHires->SetOn(true);
				vicDisplays[i]->viewVicControl->btnModeMulti->SetOn(false);
				break;
			case VIEW_C64_ALL_GRAPHICS_FORCED_HIRES:
				vicDisplays[i]->viewVicControl->forceGrayscaleColors = false;
				vicDisplays[i]->viewVicControl->btnModeHires->SetOn(true);
				vicDisplays[i]->viewVicControl->btnModeMulti->SetOn(false);
				break;
			case VIEW_C64_ALL_GRAPHICS_FORCED_MULTI:
				vicDisplays[i]->viewVicControl->forceGrayscaleColors = false;
				vicDisplays[i]->viewVicControl->btnModeHires->SetOn(false);
				vicDisplays[i]->viewVicControl->btnModeMulti->SetOn(true);
				break;
		}
		
		vicDisplays[i]->viewVicControl->lstScreenAddresses->SetElement(addrItemNum, false, false);
		vicDisplays[i]->Render();
	}

	CGuiView::Render();	
}

void CViewC64SpritesSheet::Render(GLfloat posX, GLfloat posY)
{
	CGuiView::Render(posX, posY);
}

bool CViewC64SpritesSheet::ButtonClicked(CGuiButton *button)
{
	return false;
}

bool CViewC64SpritesSheet::ButtonPressed(CGuiButton *button)
{
	LOGD("CViewC64SpritesSheet::ButtonPressed");
	
	if (button == btnModeBitmapColorsGrayscale)
	{
		if (forcedRenderScreenMode != VIEW_C64_ALL_GRAPHICS_FORCED_GRAY)
		{
			btnModeMulti->SetOn(false);
			btnModeHires->SetOn(false);
			btnModeBitmapColorsGrayscale->SetOn(true);
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_GRAY;
			SetLockableButtonDefaultColors(btnModeBitmapColorsGrayscale);
		}
		else
		{
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_NONE;
			SetSwitchButtonDefaultColors(btnModeBitmapColorsGrayscale);
		}
	}
	else if (button == btnModeHires)
	{
		if (forcedRenderScreenMode != VIEW_C64_ALL_GRAPHICS_FORCED_HIRES)
		{
			btnModeBitmapColorsGrayscale->SetOn(false);
			btnModeMulti->SetOn(false);
			btnModeHires->SetOn(true);
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_HIRES;
			SetLockableButtonDefaultColors(btnModeHires);
		}
		else
		{
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_NONE;
			SetSwitchButtonDefaultColors(btnModeHires);
		}
	}
	else if (button == btnModeMulti)
	{
		if (forcedRenderScreenMode != VIEW_C64_ALL_GRAPHICS_FORCED_MULTI)
		{
			btnModeBitmapColorsGrayscale->SetOn(false);
			btnModeHires->SetOn(false);
			btnModeMulti->SetOn(true);
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_MULTI;
			SetLockableButtonDefaultColors(btnModeMulti);
		}
		else
		{
			forcedRenderScreenMode = VIEW_C64_ALL_GRAPHICS_FORCED_NONE;
			SetSwitchButtonDefaultColors(btnModeMulti);
		}
	}

	return false;
}

bool CViewC64SpritesSheet::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	LOGD("CViewC64SpritesSheet::ButtonSwitchChanged");
	
	return false;
}

bool CViewC64SpritesSheet::ListElementPreSelect(CGuiList *listBox, int elementNum)
{
	LOGD("CViewC64SpritesSheet::ListElementPreSelect");
	guiMain->LockMutex();
	
	CGuiLockableList *list = (CGuiLockableList*)listBox;
	
	if (list->isLocked)
	{
		// click on the same element - unlock
		if (list->selectedElement == elementNum)
		{
			list->SetListLocked(false);
			guiMain->UnlockMutex();
			return true;
		}
	}
	
	list->SetListLocked(true);
	
	guiMain->UnlockMutex();
	
	return true;
}

//@returns is consumed
bool CViewC64SpritesSheet::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64SpritesSheet::DoTap:  x=%f y=%f", x, y);
	return CGuiView::DoTap(x, y);
}

bool CViewC64SpritesSheet::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64SpritesSheet::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishTap(x, y);
}

//@returns is consumed
bool CViewC64SpritesSheet::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64SpritesSheet::DoDoubleTap:  x=%f y=%f", x, y);
	return CGuiView::DoDoubleTap(x, y);
}

bool CViewC64SpritesSheet::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CViewC64SpritesSheet::DoFinishTap: %f %f", x, y);
	return CGuiView::DoFinishDoubleTap(x, y);
}


bool CViewC64SpritesSheet::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiView::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CViewC64SpritesSheet::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiView::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

bool CViewC64SpritesSheet::InitZoom()
{
	return CGuiView::InitZoom();
}

bool CViewC64SpritesSheet::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return CGuiView::DoZoomBy(x, y, zoomValue, difference);
}

bool CViewC64SpritesSheet::DoScrollWheel(float deltaX, float deltaY)
{
	return CGuiView::DoScrollWheel(deltaX, deltaY);
}

bool CViewC64SpritesSheet::DoMultiTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiTap(touch, x, y);
}

bool CViewC64SpritesSheet::DoMultiMove(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiMove(touch, x, y);
}

bool CViewC64SpritesSheet::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	return CGuiView::DoMultiFinishTap(touch, x, y);
}

void CViewC64SpritesSheet::FinishTouches()
{
	return CGuiView::FinishTouches();
}

bool CViewC64SpritesSheet::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyDown(keyCode, isShift, isAlt, isControl);
}

bool CViewC64SpritesSheet::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyUp(keyCode, isShift, isAlt, isControl);
}

bool CViewC64SpritesSheet::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return CGuiView::KeyPressed(keyCode, isShift, isAlt, isControl);
}

void CViewC64SpritesSheet::ActivateView()
{
	LOGG("CViewC64SpritesSheet::ActivateView()");
}

void CViewC64SpritesSheet::DeactivateView()
{
	LOGG("CViewC64SpritesSheet::DeactivateView()");
}
