/*
 *  CGuiList.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiList.h"

#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include <math.h>

void CGuiListCallback::ListElementSelected(CGuiList *listBox)
{
	return;
}

bool CGuiListCallback::ListElementPreSelect(CGuiList *listBox, int elementNum)
{
	return true;
}

CGuiList::CGuiList(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize,
				   char **elements, int numElements, bool deleteElements, CSlrFont *font,
				   CSlrImage *imgBackground, GLfloat backgroundAlpha,
				   CGuiListCallback *callback)
	: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	LOGG("CGuiList::CGuiList");
	this->name = "CGuiList";

	this->listUpGap = 1.0f;
	this->elementsGap = 2.0f;
	
	pthread_mutex_init(&renderMutex, NULL);

	this->callback = callback;

	this->font = font;

	this->imgBackground = imgBackground;
	this->backgroundAlpha = backgroundAlpha;

	//this->fontWidth = fontWidth;
	//this->fontHeight = fontHeight;

	this->startDrawX = 3;
	this->startDrawY = 0;
	
	if (this->font->fontType == FONT_TYPE_PROPORTIONAL)
	{
		this->fontScale = fontSize;
		this->fontSize = this->font->GetLineHeight() * fontScale;
	}
	else
	{
		this->fontSize  = fontSize; //11;
	}
	
	//this->fontHeight = fontSize;
	//this->fontWidth = fontSize;
	//
	this->startElementsY = listUpGap;

	this->ySpeed = 0.0;
	this->zoomFontSize = fontSize;

	textOffsetX = 0.0f;
	textOffsetY = 0.0f;

	this->moving = false;
	this->scrollModified = false;

	this->readOnly = false;

	this->listElements = NULL;
	this->Init(elements, numElements, deleteElements);
	LOGG("CGuiList::CGuiList done");
}

CGuiList::~CGuiList()
{
	pthread_mutex_destroy(&renderMutex);
}

void CGuiList::Init(char **elements, int numElements, bool deleteElements)
{
	LOGG("CGuiList::Init");
	this->LockRenderMutex();

	if (listElements != NULL && this->deleteElements)
	{
		LOGG("CGuiList::Init: listElements != NULL, delete elements");
		
		// tracker v2 crashes here, for debug temporary delete commented out 
		// TODO: debug on valgrind
		LOGTODO("delete elements, TODO: CHECK FOR CONST CHAR* IN HIGH-LEVEL CODE");
//		char **charListElems = (char **)listElements;
//		for (int i = 0; i < this->numElements; i++)
//		{
//			delete charListElems[i];
//		}
//		delete [] charListElems;
		listElements = NULL;
	}

	this->typeOfElements = GUI_LIST_ELEMTYPE_CHARS;

	this->deleteElements = deleteElements;

	this->selectedElement = -1;
	this->firstShowElement = 0;
	this->numElements = numElements;
	this->listElements = (void**)elements;
	if (this->listElements != NULL)
	{
		this->UpdateRollUp();
	}
	this->scrollModified = false;
	
	fontSelected = NULL;

	this->UnlockRenderMutex();
	LOGG("CGuiList::Init done");
}

void CGuiList::SetGaps(float listUpGap, float elementsGap)
{
	this->listUpGap = listUpGap;
	this->elementsGap = elementsGap;
	this->UpdateRollUp();
}

void CGuiList::UpdateRollUp()
{
	LOGG("CGuiList::UpdateRollUp()");

	this->numRollUp = ((sizeY-listUpGap) / fontSize / 2.0);

	if ((this->selectedElement - numRollUp) < 0)
	{
		this->firstShowElement = 0;
	}
	else
	{
		this->firstShowElement = this->selectedElement - numRollUp;
	}

}

bool CGuiList::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return false;

	LOGG("CGuiList::DoMove: %f %f", diffX, diffY);
	if (IsInside(x, y) || this->moving)
	{
		moving = true;
		scrollModified = true;
		MoveView(diffX, diffY);
		return true;
	}
	else
	{
		//LOGTODO("not inside [checkme]");
	}

	return false;
}

bool CGuiList::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!visible)
		return false;

	LOGG("CGuiList::FinishMove: finish move: %f %f", distX, distY);
	LOGG("CGuiList::FinishMove: accel=(%f, %f)", accelerationX, accelerationY);

	if (IsInside(x,y) || this->moving)	// && y < posY + sizeY
	{
		ySpeed = accelerationY / 130;
		moving = false;

		return true;
	}
	else
	{
		//LOGTODO("not inside [checkme]");
	}

	return false;
}

bool CGuiList::InitZoom()
{
	if (!visible)
		return false;

	zoomFontSize = fontSize;
	return true;
}

bool CGuiList::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (!visible)
		return false;

	LOGG("CGuiList::DoZoomBy: %f", zoomValue);
	scrollModified = true;

	LOGG("fontSize=%f", fontSize);
	float newFontSize = zoomFontSize + (zoomValue / 10);

	if (newFontSize > 6 && newFontSize < 45)
	{
		fontSize = newFontSize;
	}

	UpdateRollUp();
	LOGG("newFontSize=%f", newFontSize);
	return true;
}

void CGuiList::MoveView(GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return;

	LOGG("CGuiList::MoveView: %f %f firstShowElement=%d", diffX, diffY, firstShowElement);

	GLfloat newStartDrawY = startDrawY + diffY;

	while(true)
	{
		if (newStartDrawY < -fontSize)
		{
			// check if not end
			bool fits = false;
			float y = newStartDrawY;
			int instrNum = firstShowElement;
			while(instrNum < numElements)
			{
				instrNum += 1;
				y += fontSize+elementsGap;
				if (y >= (sizeY-startElementsY))
				{
					fits = true;
					break;
				}

			}

			if (fits)
			{
				newStartDrawY += fontSize;
				firstShowElement++;
			}
			else
			{
				newStartDrawY = startDrawY;
				break;
			}
		}
		else if (newStartDrawY >= 0.0)
		{
			if (firstShowElement == 0)
			{
				newStartDrawY = 0.0;
				break;
			}
			else
			{
				newStartDrawY -= fontSize;
				firstShowElement--;
			}
		}
		else
		{
			if (newStartDrawY < 0)
			{
				// check if not end
				bool fits = false;
				float y = newStartDrawY;
				int instrNum = firstShowElement;
				while(instrNum < numElements)
				{
					instrNum += 1;
					y += fontSize+elementsGap;
					if (y >= (sizeY-startElementsY))
					{
						fits = true;
						break;
					}

				}

				if (fits)
				{
					break;
				}
				else
				{
					newStartDrawY = startDrawY;
					break;
				}
			}

			break;
		}
	}

	startDrawY = newStartDrawY;
}

bool CGuiList::DoTap(GLfloat x, GLfloat y)
{
	LOGD("CGuiList::DoTap");
	scrollModified = false;
	
	LOGD("scrollModified = %d", scrollModified);
	return CGuiElement::DoTap(x, y);
}

bool CGuiList::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGD("CGuiList::DoFinishTap: '%s'", this->name);
	if (!visible)
		return false;

	if (!IsInside(x, y))
	{
		LOGD("   -outside");
		return false;
	}

	if (scrollModified == true)
	{
		LOGD("CGuiList::DoFinishTap: scrollModified");
		return false;
	}

	//LOGD("   -[INSIDE]");

	GLfloat drawY = startDrawY + startElementsY + posY;
	if (y < drawY)
	{
		//LOGD("y=%f < drawY=%f, return", y, drawY);
		return false;
	}

	bool found = false;
	int elemNum = firstShowElement;
	for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGD("elemNum=%d drawY=%f y=%f", elemNum, drawY, y);
		if (y >= drawY && y <= drawY + fontSize+elementsGap)
		{
			found = true;
			break;
		}
		
		drawY += fontSize+elementsGap;
		
		if (drawY > sizeY + posY)
		{
			//found = false;
			break;
		}
	}
	
	if (!found)
	{
		if (this->callback)
		{
			// cancel select?
			if (this->callback->ListElementPreSelect(this, -1) == false)
			{
				return true;
			}
		}

		this->selectedElement = -1;
		if (this->callback)
			this->callback->ListElementSelected(this);
		this->ElementSelected();
		
		return true;
	}
	
	int selected = elemNum;
	//LOGD("selected=%d", selected);

	if (!this->readOnly)
	{
		if (selected < numElements)
		{
			if (this->callback)
			{
				// cancel select?
				if (this->callback->ListElementPreSelect(this, selected) == false)
				{
					return true;
				}
			}

			this->selectedElement = selected;

			if (this->callback)
				this->callback->ListElementSelected(this);
			this->ElementSelected();
		}
	}

	return true;
}

bool CGuiList::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	return DoFinishTap(x, y);
}

void CGuiList::Render()
{
	if (!visible)
		return;

	this->LockRenderMutex();
	
//	GLfloat posZ = -1.8;
//	GLfloat fontSize = fontWidth;
	//LOGG(" CGuiSelectInstrument::Render(");

	if (imgBackground != NULL)
		imgBackground->RenderAlpha(posX, posY, posZ, sizeX, sizeY, backgroundAlpha);

	/*
	 guiMain->fntConsole->BlitText(this->text,
	 posX + fontWidth/2, posY + sizeY*0.1, -1.0,
	 fontWidth, fontHeight, 1.0);
	 */

	//guiMain->fntConsole->BlitText("[listtext]", posX + 3.0f, posY + 3.0f, posZ, 8.0);	//Select

	//mtrMain->appView->BlitBackground(mtrMain->imgBackground);
	//guiMain->fntConsole->BlitText("EDIT INSTRUMENTS", posX + 24, posY + 9, 8.0);

	int elemNum;
//	byte line = 0;

	GLfloat drawY = startDrawY + startElementsY; //27;
	GLfloat drawX = startDrawX; //3;

	SetClipping(posX, posY + startElementsY, sizeX, sizeY - startElementsY);

	for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		if (elemNum < numElements)
		{
			if (typeOfElements == GUI_LIST_ELEMTYPE_CHARS)
			{
				if (font == guiMain->fntConsole)
				{
				}
				else if (font->fontType == FONT_TYPE_SYSTEM)
				{
					if (elemNum == selectedElement)
						guiMain->theme->imgListSelection->Render(this->posX, posY + drawY-1.0f, this->posZ, this->sizeX, this->fontSize*1.3f);
				}
				else if (font->fontType == FONT_TYPE_BITMAP)
				{
					if (elemNum == selectedElement)
						guiMain->theme->imgListSelection->Render(this->posX, drawY-1.0f, this->posZ, this->sizeX, this->fontSize+1.0f);
				}
				else if (font->fontType == FONT_TYPE_PROPORTIONAL)
				{
					if (elemNum == selectedElement)
					{
						if (guiMain->theme->imgListSelection != NULL)
						{
							guiMain->theme->imgListSelection->Render(this->posX, drawY-1.0f, this->posZ, this->sizeX, this->zoomFontSize+1.0f);
						}
						else
						{
							BlitFilledRectangle(posX + drawX, posY + drawY, posZ, sizeX, fontSize+elementsGap, 0.0f, 0.0f, 1.0f, 1.0f);
						}
					}
				}
				else
				{
					SYS_FatalExit("Unknown font type: %2.2x", font->fontType);
				}
			}
		}

		drawY += fontSize+elementsGap;

		if (drawY > posEndY)
			break;
	}

	drawY = startDrawY + startElementsY; //27;

	//LOGD("CGuiList::Render: numElements=%d", numElements);

	for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGD("	elemNum=%d", elemNum);
		drawX = startDrawX;

		/*
		Byte2Hex2digits(elemNum, drawBuf);
		guiMain->fntConsole->BlitChar(drawBuf[0], posX + drawX, posY + drawY, posZ, fontSize);
		drawX += fontWidth;
		guiMain->fntConsole->BlitChar(drawBuf[1], posX + drawX, posY + drawY, posZ, fontSize);
		drawX += fontWidth + GAP_WIDTH*3;
		*/

		/*fix
		 mtrMain->appView->BlitClip
		 (guiMain->imgBkgMenu, drawX, drawY-1, drawX, drawY-1, VIEW_WIDTH-FONT_WIDTH*2-GAP_WIDTH*3-4, FONT_HEIGHT);
		 */

		drawX += GAP_WIDTH;

		if (elemNum < numElements)
		{
			if (typeOfElements == GUI_LIST_ELEMTYPE_CHARS)
			{
				bool strFinished = false;
				char **elements = (char**)listElements;

				if (font == guiMain->fntConsole)
				{
					for (int i = 0; i < MAX_STRING_LENGTH; i++)
					{
						if (strFinished)
						{
							guiMain->fntConsoleInverted->BlitChar(' ', posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
						}
						else if (elements[elemNum][i] == 0x00)
						{
							if (elemNum == selectedElement)
							{
								guiMain->fntConsoleInverted->BlitChar(' ', posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
								strFinished = true;
							}
							else break;
						}
						else
						{
							if (elemNum == selectedElement)
							{
								guiMain->fntConsoleInverted->BlitChar(elements[elemNum][i], posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
							}
							else
								guiMain->fntConsole->BlitChar(elements[elemNum][i], posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
						}

						drawX += fontSize;
						if (drawX > (posEndX)-fontSize)
							break;
					}
				}
				else if (font->fontType == FONT_TYPE_SYSTEM)
				{
					//if (elemNum == selectedElement)
					//	guiMain->imgListSelection->Render(this->posX, posY + drawY-1.0f, this->posZ, this->sizeX, this->fontSize*1.3f);

					//LOGD("fontSize=%f", fontSize);
					font->BlitText(elements[elemNum], posX + drawX, posY + drawY, this->posZ+0.01f, fontSize, 1.0f);
				}
				else if (font->fontType == FONT_TYPE_BITMAP)
				{
					//if (elemNum == selectedElement)
					//	guiMain->imgListSelection->Render(this->posX, drawY-1.0f, this->posZ, this->sizeX, this->fontSize+1.0f);

					for (int i = 0; i < MAX_STRING_LENGTH; i++)
					{
						if (elements[elemNum][i] == 0x00)
							break;

						guiMain->fntConsole->BlitChar(elements[elemNum][i], posX + drawX, posY + drawY, posZ+0.01, this->fontSize);

						drawX += fontSize;
						if (drawX > (posEndX)-fontSize)
							break;
					}
				}
				else if (font->fontType == FONT_TYPE_PROPORTIONAL)
				{
					font->BlitText(elements[elemNum], posX + drawX + textOffsetX, posY + drawY + textOffsetY, this->posZ+0.01f, fontScale, 1.0f);
				}
				else
				{
					SYS_FatalExit("Unknown font type: %2.2x", font->fontType);
				}

			}
		}
		else
		{
			if (elemNum == selectedElement)
				guiMain->fntConsoleInverted->BlitChar('?', posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
			else
				guiMain->fntConsole->BlitChar('?', posX + drawX, posY + drawY, posZ+0.01, this->fontSize);
		}

		drawY += fontSize+elementsGap;

		if (drawY > posEndY)
			break;
	}

	ResetClipping();

	this->UnlockRenderMutex();
}

void CGuiList::DoLogic()
{
	//LOGD("CGuiList::DoLogic");

	if (!visible)
		return;

	//LOGD("ySpeed=%f", ySpeed);

	if (fabs(ySpeed) > 0.01)
	{
		//LOGD("[MOVE] ySpeed=%f", ySpeed);
		this->MoveView(0.0, ySpeed);
		ySpeed = ySpeed / 1.3;
	}
}

void CGuiList::SetElement(int elementNum, bool updatePosition)
{
	//LOGG("CGuiList::SetElement");
	if (elementNum < 0)
	{
		this->selectedElement = -1;
		return;
	}

	this->selectedElement = elementNum;

	if (updatePosition)
	{
		if ((this->selectedElement - numRollUp) < 0)
		{
			this->firstShowElement = 0;
		}
		else
		{
			this->firstShowElement = this->selectedElement - numRollUp;
		}
	}

	// TODO: CHECK THIS:
	if (this->callback)
		this->callback->ListElementSelected(this);
	this->ElementSelected();
}

void CGuiList::ElementSelected()
{
	//LOGG("CGuiList::ElementSelected()");
}

void CGuiList::BackupListPosition()
{
	backupSelectedElement = this->selectedElement;
	backupFirstShowElement = this->firstShowElement;
	backupStartDrawY = this->startDrawY;
}

void CGuiList::RestoreListPosition()
{
	if (this->backupSelectedElement < this->numElements
		&& this->backupSelectedElement >= 0)
	{
		this->selectedElement = backupSelectedElement;
	}

	if (this->backupFirstShowElement < this->numElements
		&& this->backupFirstShowElement >= 0)
	{
		this->firstShowElement = backupFirstShowElement;
	}
	
	this->startDrawY = backupStartDrawY;
}

void CGuiList::LockRenderMutex()
{
	pthread_mutex_lock(&this->renderMutex);
}

void CGuiList::UnlockRenderMutex()
{
	pthread_mutex_unlock(&this->renderMutex);
}

