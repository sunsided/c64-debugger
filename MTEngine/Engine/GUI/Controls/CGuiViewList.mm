/*
 *  CGuiListElements.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiViewList.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"


#define LIST_UP_GAP 15.0
///#define ELEMENTS_GAP 10.0

void CGuiViewListCallback2::ViewListElementSelected(CGuiViewList *listBox)
{
	return;
}


CGuiViewList::CGuiViewList(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
						   CGuiElement **elements, int numElements, bool deleteElements, CGuiViewListCallback2 *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiViewList";

	this->callback = callback;

	this->startDrawX = 3;
	this->startDrawY = 0;

	//this->fontSize  = 11;
	//leftMenuGap = 32;
	//this->startElementsY = LIST_UP_GAP;

	this->ySpeed = 0.0;
	//this->zoomFontSize = fontSize;

	this->moving = false;
	this->clickConsumed = false;

	this->selectionHighlight = true;

	this->imgBackground = guiMain->theme->imgBackground;

	colorSelectionR = 1.0f;
	colorSelectionG = 0.0f;
	colorSelectionB = 0.0f;
	colorSelectionA = 0.5f;

	this->listElements = NULL;
	this->Init(elements, numElements, deleteElements);
}

void CGuiViewList::Init(CGuiElement **elements, int numElements, bool deleteElements)
{
	this->LockRenderMutex();

	if (listElements != NULL && this->deleteElements)
	{
		// TODO:
		LOGTODO("CGuiList::Init: listElements != NULL, delete elements");
		/*

		 crashes:
		for (int i = 0; i < numElements; i++)
		{
			delete [] listElements[i];
		}
		delete listElements;*/
	}

	this->deleteElements = deleteElements;

	this->selectedElement = 0;
	this->firstShowElement = 0;
	this->numElements = numElements;
	this->listElements = elements;
	if (this->listElements != NULL)
	{
		this->UpdateRollUp();
	}

	this->UnlockRenderMutex();
}

void CGuiViewList::UpdateRollUp()
{
	//LOGG("CGuiViewList::UpdateRollUp()");

	/*
	this->numRollUp = ((sizeY-LIST_UP_GAP) / fontHeight / 2.0);

	if ((this->selectedElement - numRollUp) < 0)
	{
		this->firstShowElement = 0;
	}
	else
	{
		this->firstShowElement = this->selectedElement - numRollUp;
	}
	*/
}

bool CGuiViewList::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	//////// DoMove
	GLfloat drawY = startDrawY + posY; // + startElementsY; //27;
	GLfloat drawX = startDrawX; //3;

	bool moveConsumed = false;
	for (int elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGG("elemNum=%d", elemNum);
		if (elemNum < 0)
		{
			//LOGG("CGuiViewList::DoMove: elemNum=%d", elemNum);
			return false;
		}
		CGuiElement *element = this->listElements[elemNum];

		if (element == NULL)
		{
			LOGError("CGuiViewList::DoMove: elem null");
			break;
		}

		// calc alignment
		if (element->elementAlignment == ELEMENT_ALIGNED_RIGHT)
		{
			drawX = posX + sizeX - element->sizeX;
		}
		else if (element->elementAlignment == ELEMENT_ALIGNED_CENTER)
		{
			drawX = posX + (sizeX - element->sizeX)/2;
		}
		else
		{
			drawX = posX;
		}

		if (x >= drawX && x <= drawX + element->sizeX
			&& y >= drawY && y <= drawY + element->sizeY)
		{
			if (element->DoMove(x - drawX, y - drawY, distX, distY, diffX, diffY))
			{
				moveConsumed = true;
				break;
				//clickConsumed = true;
				//return true;
			}
		}
		drawY += element->sizeY + element->gapY; //+ELEMENTS_GAP;

		if (drawY > posEndY)
		{
			break;
		}
	}

	// move list
	//LOGG("CGuiViewList::DoMove: %f %f", diffX, diffY);
	if (!moveConsumed)
		if (y >= posY || this->moving)	// && y < posY + sizeY
		{
			moving = true;
			MoveView(diffX, diffY);
			return true;
		}

	return moveConsumed;
}

bool CGuiViewList::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!visible)
		return false;

	if (!IsInside(x, y))
		return false;

	//////// DoMove
	GLfloat drawY = startDrawY + posY; // + startElementsY; //27;
	GLfloat drawX = startDrawX; //3;

	for (int elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGG("elemNum=%d", elemNum);
		if (elemNum < 0)
		{
			//LOGG("CGuiViewList::FinishMove: elemNum=%d", elemNum);
			return false;
		}
		CGuiElement *element = this->listElements[elemNum];

		if (element == NULL)
		{
			LOGError("CGuiViewList::FinishMove: elem null");
			break;
		}

		// calc alignment
		if (element->elementAlignment == ELEMENT_ALIGNED_RIGHT)
		{
			drawX = posX + sizeX - element->sizeX;
		}
		else if (element->elementAlignment == ELEMENT_ALIGNED_CENTER)
		{
			drawX = posX + (sizeX - element->sizeX)/2;
		}
		else
		{
			drawX = posX;
		}

		if (x >= drawX && x <= drawX + element->sizeX
			&& y >= drawY && y <= drawY + element->sizeY)
		{
			if (element->FinishMove(x - drawX, y - drawY, distX, distY, accelerationX, accelerationY))
			{
				break;
				//clickConsumed = true;
				//return true;
			}
		}
		drawY += element->sizeY + element->gapY; //+ELEMENTS_GAP;

		if (drawY > posEndY)
		{
			break;
		}
	}

	//LOGG("CGuiViewList::FinishMove: finish move: %f %f", distX, distY);
	//LOGG("CGuiViewList::FinishMove: accel=(%f, %f)", accelerationX, accelerationY);

	if (y >= posY || this->moving)	// && y < posY + sizeY
	{
		ySpeed = accelerationY / 130;
		moving = false;

		return true;
	}

	return false;
}

bool CGuiViewList::InitZoom()
{
	if (!visible)
		return false;

	//zoomFontSize = fontSize;
	return true;
}

bool CGuiViewList::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (!visible)
		return false;

	/*
	LOGG("CGuiList::DoZoomBy: %f", zoomValue);

	LOGG("fontSize=%f", fontSize);
	float newFontSize = zoomFontSize + (zoomValue / 10);

	if (newFontSize > 6 && newFontSize < 45)
	{
		fontSize = newFontSize;
		fontWidth = newFontSize;
		fontHeight = newFontSize;
	}

	UpdateRollUp();
	LOGG("newFontSize=%f", newFontSize);
	return true;*/

	return false;
}

void CGuiViewList::MoveView(GLfloat diffX, GLfloat diffY)
{
	if (!visible)
		return;

	if (numElements < 1)
		return;

//	LOGG("CGuiViewList::MoveView: %f %f", diffX, diffY);
//	LOGG("------------>>>>>> START: firstShowElement=%d firstShowElem->sizeY=%f startDrawY=%f",
//		 firstShowElement, this->listElements[firstShowElement]->sizeY, startDrawY);

	GLfloat newStartDrawY = startDrawY + diffY;

//	LOGG("newStartDrawY=%f", newStartDrawY);

	u32 i = 0;
	while(true)
	{
//		LOGG("LOOP: i=%d newStartDrawY=%f firstShowElement=%d", i++, newStartDrawY, firstShowElement);
		if (newStartDrawY < -(this->listElements[firstShowElement]->sizeY + this->listElements[firstShowElement]->gapY)) //+ELEMENTS_GAP))
		{
//			LOGG("INSIDE: if (newStartDrawY < -this->listElements[firstShowElement]->sizeY)");
			// check if not end
			bool fits = false;
			float y = newStartDrawY;
			int elemNum = firstShowElement;
			while(elemNum < numElements)
			{
				y += (this->listElements[elemNum]->sizeY + this->listElements[elemNum]->gapY);
				if (y >= (sizeY)) //-startElementsY))
				{
					fits = true;
					break;
				}
				elemNum += 1;
				//y += ELEMENTS_GAP;
			}

			if (fits)
			{
//				LOGD(" (1) fits");
				newStartDrawY += (this->listElements[firstShowElement]->sizeY + this->listElements[firstShowElement]->gapY);
				firstShowElement++;
			}
			else
			{
//				LOGD(" (1) not fits");
				newStartDrawY = startDrawY;
				break;
			}
		}
		else if (newStartDrawY > 0.0)
		{
//			LOGG("INSIDE: if (newStartDrawY >= 0.0)");
			if (firstShowElement == 0)
			{
//				LOGD("firstShowElement == 0");
				newStartDrawY = 0.0;
				break;
			}
			else
			{
//				LOGD("firstShowElement--");
				firstShowElement--;
				newStartDrawY -= (this->listElements[firstShowElement]->sizeY + this->listElements[firstShowElement]->gapY);
			}
		}
		else
		{
//			LOGG("INSIDE: else other");
			if (newStartDrawY < 0)
			{
//				LOGD("check if not end");
				// check if not end
				bool fits = false;
				float y = newStartDrawY;
				int elemNum = firstShowElement;
				while(elemNum < numElements)
				{
					y += (this->listElements[elemNum]->sizeY + this->listElements[elemNum]->gapY);
					if (y >= (sizeY)) //-startElementsY))
					{
						fits = true;
						break;
					}
					//y += ELEMENTS_GAP;
					elemNum += 1;
				}

				if (fits)
				{
//					LOGD(" (2) fits");
//					if (diffY > 0)
//					{
//						if (firstShowElement > 0)
//						{
//							firstShowElement--;
//						}
//					}
//					else
//					{
//						if (firstShowElement < numElements-1)
//						{
//							firstShowElement++;
//						}
//					}
						
					break;
				}
				else
				{
//					LOGD(" (2) not fits: newStartDrawY = startDrawY");
					newStartDrawY = startDrawY;
					break;
				}
			}
			else
			{
//				LOGG("INSIDE: else other / else");
			}

			break;
		}
	}

	startDrawY = newStartDrawY;
//	LOGG("------------>>>>>> FINISH: firstShowElement=%d firstShowElem->sizeY=%f startDrawY=%f",
//		 firstShowElement, this->listElements[firstShowElement]->sizeY, startDrawY);

}

bool CGuiViewList::DoTap(GLfloat x, GLfloat y)
{
	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;

	GLfloat drawY = startDrawY + posY;  //+ startElementsY
	if (y < drawY)
		return false;


	bool found = false;
	int elemNum = firstShowElement;
	for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGD("elemNum=%d drawY=%f y=%f", elemNum, drawY, y);
		GLfloat sy = (this->listElements[elemNum]->sizeY + this->listElements[elemNum]->gapY);
		if (y >= drawY && y <= drawY + sy)
		{
			found = true;
			break;
		}
		
		drawY += sy;
		
		if (drawY > sizeY + posY)
		{
			//found = false;
			break;
		}
	}
	
	if (!found)
	{
		this->selectedElement = -1;
		if (this->callback)
			this->callback->ViewListElementSelected(this);
		this->ElementSelected();
		return true;
	}
	
	this->selectedElement = elemNum;

	if (this->callback)
		this->callback->ViewListElementSelected(this);
	this->ElementSelected();

	//int elemNum;

	this->clickConsumed = false;

	drawY = startDrawY + posY; // + startElementsY; //27;
	GLfloat drawX = startDrawX; //3;

	for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGG("elemNum=%d", elemNum);
		if (elemNum < 0)
		{
			LOGG("CGuiViewList::DoTap: elemNum=%d", elemNum);
			return false;
		}
		CGuiElement *element = this->listElements[elemNum];

		if (element == NULL)
		{
			LOGError("CGuiViewList::DoTap: elem null");
			break;
		}

		// calc alignment
		if (element->elementAlignment == ELEMENT_ALIGNED_RIGHT)
		{
			drawX = posX + sizeX - element->sizeX;
		}
		else if (element->elementAlignment == ELEMENT_ALIGNED_CENTER)
		{
			drawX = posX + (sizeX - element->sizeX)/2;
		}
		else
		{
			drawX = posX;
		}

		if (x >= drawX && x <= drawX + element->sizeX
			&& y >= drawY && y <= drawY + element->sizeY)
		{
			if (element->DoTap(x - drawX, y - drawY))
			{
				clickConsumed = true;
				return true;
			}
		}
		drawY += element->sizeY + element->gapY; //+ELEMENTS_GAP;

		if (drawY > posEndY)
		{
			break;
		}
	}

	return false;
}

bool CGuiViewList::DoFinishTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	if (numElements < 1)
		return false;

	if (!IsInside(x, y))
		return false;


	//////// DoFinishTap
	GLfloat drawY = startDrawY + posY; // + startElementsY; //27;
	GLfloat drawX = startDrawX; //3;

	for (int elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		//LOGG("elemNum=%d", elemNum);
		if (elemNum < 0)
		{
			LOGG("CGuiViewList::DoFinishTap: elemNum=%d", elemNum);
			return false;
		}
		CGuiElement *element = this->listElements[elemNum];

		if (element == NULL)
		{
			LOGError("CGuiViewList::DoFinishTap: elem null");
			break;
		}

		// calc alignment
		if (element->elementAlignment == ELEMENT_ALIGNED_RIGHT)
		{
			drawX = posX + sizeX - element->sizeX;
		}
		else if (element->elementAlignment == ELEMENT_ALIGNED_CENTER)
		{
			drawX = posX + (sizeX - element->sizeX)/2;
		}
		else
		{
			drawX = posX;
		}

		if (x >= drawX && x <= drawX + element->sizeX
			&& y >= drawY && y <= drawY + element->sizeY)
		{
			if (element->DoFinishTap(x - drawX, y - drawY))
			{
				clickConsumed = true;
				return true;
			}
		}
		drawY += element->sizeY + element->gapY; //+ELEMENTS_GAP;

		if (drawY > posEndY)
		{
			break;
		}
	}

	return true;
}

bool CGuiViewList::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!visible)
		return false;

	return DoFinishTap(x, y);
}

void CGuiViewList::Render()
{
	if (!visible)
		return;

	//LOGG("CGuiViewList::Render()");

	if (this->imgBackground)
	{
		this->imgBackground->Render(posX, posY, posZ, sizeX, sizeY);
	}

	if (numElements > 0)
	{
		SetClipping(posX, posY, sizeX, sizeY);

		int elemNum;

		GLfloat drawY = startDrawY + posY; // + startElementsY; //27;
		GLfloat drawX = startDrawX; //3;

		for (elemNum = firstShowElement; elemNum < numElements; elemNum++)
		{
			//LOGG("elemNum=%d", elemNum);
			if (elemNum < 0)
			{
				//LOGG("CGuiViewList::Render: elemNum=%d", elemNum);
				return;
			}
			CGuiElement *element = this->listElements[elemNum];

			//LOGG("elemNum[%d] = %s", elemNum, element->name);

			/*
			 Byte2Hex2digits(elemNum, drawBuf);
			 guiMain->fntConsole->BlitChar(drawBuf[0], posX + drawX, posY + drawY, posZ, fontSize);
			 drawX += fontWidth;
			 guiMain->fntConsole->BlitChar(drawBuf[1], posX + drawX, posY + drawY, posZ, fontSize);
			 drawX += fontWidth + GAP_WIDTH*3;
			 */

			/*fix
			 mtrMain->appView->BlitClip
			 (guiMain->imgBkgMenu, drawX, drawY-1, drawX, drawY-1, SCREEN_WIDTH-FONT_WIDTH*2-GAP_WIDTH*3-4, FONT_HEIGHT);
			 */

			//drawX += GAP_WIDTH;

			if (element == NULL)
			{
				//LOGG("elem null");
				break;
			}

			// calc alignment
			if (element->elementAlignment == ELEMENT_ALIGNED_RIGHT)
			{
				drawX = posX + sizeX - element->sizeX;
			}
			else if (element->elementAlignment == ELEMENT_ALIGNED_CENTER)
			{
				drawX = posX + (sizeX - element->sizeX)/2;
			}
			else
			{
				drawX = posX;
			}

			if (selectionHighlight)
			{
				if (selectedElement == elemNum)
				{
					BlitFilledRectangle(drawX, drawY + element->gapY, posZ-0.01,
							sizeX, element->sizeY,
							colorSelectionR, colorSelectionG, colorSelectionB, colorSelectionA);
				}
			}

			//LOGG("element->Render");
			element->Render(drawX, drawY);

			drawY += element->sizeY + element->gapY; //+ELEMENTS_GAP;

			if (drawY > posEndY)
			{
				//LOGG("break render: drawY=%f posEndY=%f", drawY, posEndY);
				break;
			}
		}

		ResetClipping();
	}
}

void CGuiViewList::DoLogic()
{
	//LOGG("CGuiList::DoLogic");

	if (!visible)
		return;

	if (fabs(ySpeed) > 0.01)
	{
		//LOGG("ySpeed=%f", ySpeed);
		this->MoveView(0.0, ySpeed);
		ySpeed = ySpeed / 1.3;
	}

	for (int elemNum = firstShowElement; elemNum < numElements; elemNum++)
	{
		if (elemNum < 0)
		{
			continue;
		}
		CGuiElement *element = this->listElements[elemNum];
		element->DoLogic();

	}
}

void CGuiViewList::ScrollHome()
{
	this->startDrawY = 0;
	this->firstShowElement = 0;
}

void CGuiViewList::SetElement(int elementNum, bool updatePosition)
{
	LOGD("SetElement: elemNum=%d numElements=%d", elementNum, numElements);
	if (elementNum < 0)
		return;

	this->selectedElement = elementNum;

	if (updatePosition)
	{
		// calc height
		this->ScrollHome();
		
		if (elementNum > 0)
		{
			CGuiElement *element = this->listElements[0];
			for (int i = 0; i < elementNum; i++)
			{
				if (i < this->numElements)
				{
					element = this->listElements[i];
					MoveView(0.0f, -element->sizeY);
				}
				else MoveView(0.0f, -element->sizeY);;
			}
			
			element = this->listElements[elementNum];
			if (elementNum >= numElements-2)
			{
				this->firstShowElement++;
				if (firstShowElement >= numElements)
				{
					firstShowElement = numElements-1;
				}
			}
			else if (elementNum < numElements-1)
			{
				MoveView(0.0f, +element->sizeY);
			}
		}
	}

}

void CGuiViewList::ElementSelected()
{
	LOGG("CGuiViewList::ElementSelected()");
}

void CGuiViewList::BackupViewListPosition()
{
	backupSelectedElement = this->selectedElement;
	backupFirstShowElement = this->firstShowElement;
	backupStartDrawY = this->startDrawY;
}

void CGuiViewList::RestoreViewListPosition()
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

CGuiElement *CGuiViewList::GetSelectedElement()
{
	if (this->selectedElement != -1)
		{
			return this->listElements[this->selectedElement];
		}

	return NULL;
}


void CGuiViewList::LockRenderMutex()
{
}

void CGuiViewList::UnlockRenderMutex()
{
}

