/*
 *  CGuiListTree.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiElement.h"
#include "CGuiListTree.h"
#include "CGuiMain.h"
#include "CGuiTheme.h"
#include "CSlrFont.h"
#include "CSlrFontBitmap.h"
#include "CSlrImage.h"
#include "CSlrImageTexture.h"
#include "DBG_Log.h"
//#include <math.h>
#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "VID_GLViewController.h"
#include <cmath>
#include <cstring>
#include <iterator>
#include <map>
#include <new>
#include <utility>
#include <vector>

#define LIST_UP_GAP 1.0
#define ELEMENTS_GAP 2.0

void CGuiListTreeCallback::ListTreeElementSelected(CGuiListTree *listBox)
{
	return;
}

CGuiListTreeElement::CGuiListTreeElement(CGuiListTreeElement *parent, char *text, void *obj)
{
	this->elementId = -1;
	this->parent = parent;
	this->text = text;
	this->textLen = strlen(this->text);
	this->obj = obj;
	this->openerSpaces = 0;
	this->unfoldable = false;
	this->unfolded = false;
}

u32 CGuiListTreeElement::CountUnfolded()
{
	u32 val = 1;

	if (this->unfolded)
	{
		for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements.begin();
			 itElems != elements.end(); itElems++)
		{
			CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;

			val += el->CountUnfolded();
		}
	}

	return val;
}

u32 CGuiListTreeElement::AddToListElems(char **listElems, CGuiListTreeElement **listTreeElems, u32 elemNum, u32 numSpaces)
{
	//LOGD("AddToListElems: %d, add '%s'", elemNum, this->text);

	listTreeElems[elemNum] = this;
	this->openerSpaces = numSpaces;

	listElems[elemNum] = new char[textLen +5 + numSpaces];
	for (u32 i = 0; i < numSpaces; i++)
	{
		listElems[elemNum][i] = ' ';
	}
	listElems[elemNum][numSpaces] = 0x00;


	if (this->elements.empty())
	{
		strcat(listElems[elemNum], this->text);
		return elemNum+1;
	}

	if (this->unfolded)
	{
		strcat(listElems[elemNum], "-");
		strcat(listElems[elemNum], this->text);

		elemNum++;
		for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements.begin();
			 itElems != elements.end(); itElems++)
		{
			CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;

			elemNum = el->AddToListElems(listElems, listTreeElems, elemNum, numSpaces+1);
		}
		return elemNum;
	}
	else
	{
		strcat(listElems[elemNum], ">");
		strcat(listElems[elemNum], this->text);
		return elemNum+1;
	}
}

void CGuiListTreeElement::ReInit(std::map<i64, CGuiListTreeElement *> *map)
{
	if (this->unfoldable)
	{
		//LOGD("find %d", this->elementId);
		std::map<i64, CGuiListTreeElement *>::iterator itOld = map->find(this->elementId);
		if (itOld != map->end())
		{
			//LOGD("found %d", this->elementId);
			CGuiListTreeElement *oldElement = itOld->second;

			this->unfolded = oldElement->unfolded;
		}
	}

	//LOGD("...elems...");
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements.begin();
				 itElems != elements.end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;
		el->ReInit(map);
	}
	//LOGD("...........");
}

void CGuiListTreeElement::AddToMap(std::map<i64, CGuiListTreeElement *> *map)
{
	(*map)[this->elementId] = this;
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements.begin();
				 itElems != elements.end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;
		el->AddToMap(map);
	}
}

CGuiListTreeElement::~CGuiListTreeElement()
{
	// delete existing elements
	while(!this->elements.empty())
	{
		CGuiListTreeElement *elem = (CGuiListTreeElement *)this->elements.front();
		this->elements.erase(this->elements.begin());
		delete elem;
	}
}

CGuiListTree::CGuiListTree(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize,
			 bool deleteElements, CSlrFont *font,
			 CSlrImage *imgBackground, GLfloat backgroundAlpha, CGuiListTreeCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	LOGG("CGuiListTree::CGuiListTree");
	this->name = "CGuiListTree";

	this->callback = callback;

	this->font = font;

	this->imgBackground = imgBackground;
	this->backgroundAlpha = backgroundAlpha;

	//this->fontWidth = fontWidth;
	//this->fontHeight = fontHeight;

	this->startDrawX = 3;
	this->startDrawY = 0;

	this->fontSize  = fontSize; //11;
	//this->fontHeight = fontSize;
	//this->fontWidth = fontSize;
	//
	this->startElementsY = LIST_UP_GAP;

	this->ySpeed = 0.0;
	this->zoomFontSize = fontSize;

	this->moving = false;
	this->scrollModified = false;

	this->readOnly = false;

	this->listElements = NULL;
	this->listTreeElements = NULL;

	LOGG("CGuiListTree::CGuiListTree done");
}

CGuiListTree::CGuiListTree(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize,
				   std::vector<CGuiListTreeElement *> *elements, bool deleteElements, CSlrFont *font,
				   CSlrImage *imgBackground, GLfloat backgroundAlpha,
				   CGuiListTreeCallback *callback)
	: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	LOGG("CGuiListTree::CGuiListTree");
	this->name = "CGuiListTree";

	this->callback = callback;

	this->font = font;

	this->imgBackground = imgBackground;
	this->backgroundAlpha = backgroundAlpha;

	//this->fontWidth = fontWidth;
	//this->fontHeight = fontHeight;

	this->startDrawX = 3;
	this->startDrawY = 0;

	this->fontSize  = fontSize; //11;
	//this->fontHeight = fontSize;
	//this->fontWidth = fontSize;
	//
	this->startElementsY = LIST_UP_GAP;

	this->ySpeed = 0.0;
	this->zoomFontSize = fontSize;

	this->moving = false;
	this->scrollModified = false;

	this->readOnly = false;

	this->listElements = NULL;
	this->listTreeElements = NULL;

	this->Init(elements, deleteElements);

	LOGG("CGuiListTree::CGuiListTree done");
}

CGuiListTree::~CGuiListTree()
{
}

void CGuiListTree::Init(std::vector<CGuiListTreeElement *> *elements, bool deleteElements)
//Init(char **elements, int numElements, bool deleteElements)
{
	LOGG("CGuiListTree::Init");
	this->LockRenderMutex();

	// delete existing elements
	while(!this->treeElements.empty())
	{
		CGuiListTreeElement *elem = (CGuiListTreeElement *)this->treeElements.front();
		this->treeElements.erase(this->treeElements.begin());
		delete elem;
	}

	this->typeOfElements = GUI_LIST_ELEMTYPE_CHARS;

	this->deleteElements = deleteElements;

	this->selectedElement = -1;
	this->firstShowElement = 0;
	this->numElements = numElements;

	// copy elements
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements->begin();
		 itElems != elements->end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;
		this->treeElements.push_back(el);

		this->mapElements[el->elementId] = el;
		el->AddToMap(&this->mapElements);
	}

	this->UpdateListElements();

	this->UnlockRenderMutex();
	LOGG("CGuiListTree::Init done");
}

void CGuiListTree::ReInit(std::vector<CGuiListTreeElement *> *elements, bool deleteElements)
{
	LOGG("CGuiListTree::ReInit");
	this->LockRenderMutex();

	std::vector<CGuiListTreeElement *>::iterator itNew = elements->begin();

	while (itNew != elements->end())
	{
		CGuiListTreeElement *el = *itNew;
		el->ReInit(&this->mapElements);

		itNew++;
	}

	i64 selectedObjectId = -1;
	if (this->selectedObject != NULL)
	{
		CGuiListTreeElement *el = this->GetTreeElementByObj((void*)this->selectedObject);
		if (el != NULL)
		{
			selectedObjectId = el->elementId;
		}
	}
	u64 firstShowElementCopy = firstShowElement;

	// delete existing elements
	this->mapElements.clear();
	while(!this->treeElements.empty())
	{
		CGuiListTreeElement *elem = (CGuiListTreeElement *)this->treeElements.front();
		this->treeElements.erase(this->treeElements.begin());
		delete elem;
	}

	this->typeOfElements = GUI_LIST_ELEMTYPE_CHARS;

	this->deleteElements = deleteElements;
	this->selectedElement = -1;
	this->firstShowElement = 0;
	this->numElements = numElements;

	// copy elements
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = elements->begin();
		 itElems != elements->end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;
		this->treeElements.push_back(el);

		this->mapElements[el->elementId] = el;
		el->AddToMap(&this->mapElements);
	}

	this->UpdateListElements();

	if (selectedObjectId != -1)
	{
		LOGD("find object");
		std::map<i64, CGuiListTreeElement *>::iterator it = this->mapElements.find(selectedObjectId);
		if (it != this->mapElements.end())
		{
			LOGD("set object");
			CGuiListTreeElement *element = it->second;
			this->SetObject(element->obj, true);
		}
		else
		{
			// element not found (deleted?)
			LOGD("element not found");

			this->firstShowElement = firstShowElementCopy;
			//this->UpdateRollUp();
		}
	}

	this->UnlockRenderMutex();
	LOGG("CGuiListTree::Init done");
}


void CGuiListTree::UpdateListElements()
{
	if (listElements != NULL && this->deleteElements)
	{
		// v2 crashes LOGG("CGuiListTree::Init: listElements != NULL, delete elements");
		LOGTODO("delete elements, TODO: BUG CHECK");
//		char **charListElems = (char **)listElements;
//		for (int i = 0; i < this->numElements; i++)
//		{
//			delete charListElems[i];
//		}
//		delete [] charListElems;
		listElements = NULL;

//		delete [] listTreeElements;
		listTreeElements = NULL;
	}

	// traverse and count unfolded elements
	//LOGD("traverse and count unfolded elements");

	numElements = 0;
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = treeElements.begin();
		 itElems != treeElements.end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;

		numElements += el->CountUnfolded();
	}

	//LOGD("numElements=%d", numElements);

	listTreeElements = new CGuiListTreeElement *[numElements];
	char **charListElements = new char *[numElements];

	int elemNum = 0;
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = treeElements.begin();
		 itElems != treeElements.end(); itElems++)
	{
		//LOGD("!elemNum=%d", elemNum);
		CGuiListTreeElement *el = (CGuiListTreeElement *)*itElems;
		elemNum = el->AddToListElems(charListElements, listTreeElements, elemNum, 0);
	}

	this->listElements = (void**)charListElements;
	if (this->listElements != NULL)
	{
		this->UpdateRollUp();
	}
	this->scrollModified = false;
}

void *CGuiListTree::GetObject(u32 elemNum)
{
	if (elemNum < numElements)
		return listTreeElements[elemNum]->obj;

	return NULL;
}

void CGuiListTree::DebugPrintTree()
{
	LOGD("CGuiListTree::DebugPrintTree: numElements=%d", numElements);
	char **charListElems = (char**)this->listElements;
	for (int i = 0; i < numElements; i++)
	{
		CGuiListTreeElement *listTreeElement = listTreeElements[i];
		LOGD("%04d: '%s' (%d)", i, charListElems[i], listTreeElement->openerSpaces);
	}
}

void CGuiListTree::UpdateRollUp()
{
	LOGG("CGuiListTree::UpdateRollUp()");

	this->numRollUp = ((sizeY-LIST_UP_GAP) / fontSize / 2.0);

	if ((this->selectedElement - numRollUp) < 0)
	{
		this->firstShowElement = 0;
	}
	else
	{
		this->firstShowElement = this->selectedElement - numRollUp;
	}

}

bool CGuiListTree::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return false;

	LOGG("CGuiListTree::DoMove: %f %f", diffX, diffY);
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

bool CGuiListTree::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!visible)
		return false;

	LOGG("CGuiListTree::FinishMove: finish move: %f %f", distX, distY);
	LOGG("CGuiListTree::FinishMove: accel=(%f, %f)", accelerationX, accelerationY);

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

bool CGuiListTree::InitZoom()
{
	if (!visible)
		return false;

	zoomFontSize = fontSize;
	return true;
}

bool CGuiListTree::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (!visible)
		return false;

	LOGG("CGuiListTree::DoZoomBy: %f", zoomValue);
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

void CGuiListTree::MoveView(GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return;

	LOGG("CGuiListTree::MoveView: %f %f firstShowElement=%d", diffX, diffY, firstShowElement);

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
				y += fontSize+ELEMENTS_GAP;
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
					y += fontSize+ELEMENTS_GAP;
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

bool CGuiListTree::DoTap(GLfloat x, GLfloat y)
{
	scrollModified = false;
	return CGuiElement::DoTap(x, y);
}

bool CGuiListTree::DoFinishTap(GLfloat x, GLfloat y)
{
	//LOGD("CGuiListTree::DoFinishTap: '%s'", this->name);
	if (!visible)
		return false;

	if (!IsInside(x, y))
	{
		//LOGD("   -outside");
		return false;
	}

	if (scrollModified == true)
	{
		//LOGD("CGuiList::DoFinishTap: scrollModified");
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
		if (y >= drawY && y <= drawY + fontSize+2)
		{
			found = true;
			break;
		}

		drawY += fontSize+2;

		if (drawY > sizeY + posY)
		{
			//found = false;
			break;
		}
	}

	if (!found)
	{
		this->selectedElement = -1;
		this->selectedObject = NULL;
		if (this->callback)
			this->callback->ListTreeElementSelected(this);
		this->ElementSelected();
		return true;
	}

	int selected = elemNum;

	if (selected < 0 || selected >= numElements)
		return true;

	//LOGD("selected=%d", selected);

	if (!this->readOnly)
	{
		if (selected < numElements)
		{
			this->selectedElement = selected;

			CGuiListTreeElement *elem = this->listTreeElements[selected];
			this->selectedObject = elem->obj;

			if (this->callback)
				this->callback->ListTreeElementSelected(this);
			this->ElementSelected();
		}
	}

	CGuiListTreeElement *elem = this->listTreeElements[selected];
	if (!elem->elements.empty())
	{
		// click on unfold button (>) ?
		GLfloat px = this->posX + startDrawX + elem->openerSpaces * this->fontSize;

		if (x >= px && x <= px + fontSize)
		{
			// fold or unfold
			elem->unfolded = !elem->unfolded;

			guiMain->LockMutex();
			this->UpdateListElements();
			guiMain->UnlockMutex();
		}
		//else LOGD("not");
	}

	return true;
}

bool CGuiListTree::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	return DoFinishTap(x, y);
}

void CGuiListTree::Render()
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
				else
				{
					SYS_FatalExit("Unknown font type: %2.2x", font->fontType);
				}
			}
		}

		drawY += fontSize+ELEMENTS_GAP;

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

		drawX += GUI_GAP_WIDTH;

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

		drawY += fontSize+ELEMENTS_GAP;

		if (drawY > posEndY)
			break;
	}

	ResetClipping();

	this->UnlockRenderMutex();
}

void CGuiListTree::DoLogic()
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

void CGuiListTreeElement::SetUnfoldedToAllParents(bool value)
{
	if (this->parent != NULL)
	{
		this->parent->unfolded = value;
		this->parent->SetUnfoldedToAllParents(value);
	}

}

CGuiListTreeElement *CGuiListTreeElement::FindObj(void *obj)
{
	if (this->obj == obj)
		return this;

	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = this->elements.begin(); itElems < this->elements.end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement*)*itElems;

		CGuiListTreeElement *objEl = el->FindObj(obj);

		if (objEl != NULL)
			return objEl;
	}

	return NULL;
}


CGuiListTreeElement *CGuiListTree::GetTreeElementByObj(void *obj)
{
	for (std::vector<CGuiListTreeElement *>::const_iterator itElems = this->treeElements.begin(); itElems < this->treeElements.end(); itElems++)
	{
		CGuiListTreeElement *el = (CGuiListTreeElement*)*itElems;
		CGuiListTreeElement *objEl = el->FindObj(obj);
		if (objEl != NULL)
			return objEl;
	}

	return NULL;
}

void CGuiListTree::SetObject(void *obj, bool updatePosition)
{
	//LOGD("CGuiListTree::SetObject");
	if (obj == NULL)
	{
		this->selectedElement = -1;
		this->selectedObject = NULL;
		return;
	}

	CGuiListTreeElement *el = this->GetTreeElementByObj(obj);
	if (el == NULL)
	{
		this->selectedElement = -1;
		this->selectedObject = NULL;
		return;
	}

	el->SetUnfoldedToAllParents(true);
	this->UpdateListElements();

	for (int i = 0; i < numElements; i++)
	{
		if (listTreeElements[i] == el)
		{
			this->selectedElement = i;
			this->selectedObject = obj;
		}
	}

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

	// CHECK THIS:
	if (this->callback)
		this->callback->ListTreeElementSelected(this);
	this->ElementSelected();
}

void CGuiListTree::SetElement(int elementNum, bool updatePosition)
{
	//LOGG("CGuiList::SetElement");
	if (elementNum < 0 || elementNum >= numElements)
	{
		this->selectedElement = -1;
		this->selectedObject = NULL;
		return;
	}

	this->selectedElement = elementNum;
	this->selectedObject = listTreeElements[elementNum]->obj;

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

	// CHECK THIS:
	if (this->callback)
		this->callback->ListTreeElementSelected(this);
	this->ElementSelected();
}

void CGuiListTree::ElementSelected()
{
	LOGG("CGuiListTree::ElementSelected()");
}

void CGuiListTree::LockRenderMutex()
{
	guiMain->LockMutex();
}

void CGuiListTree::UnlockRenderMutex()
{
	guiMain->UnlockMutex();
}

