/*
 *  CGuiRadio.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-06.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiRadio.h"
#include "CGuiMain.h"

void RadioElementSelected(CGuiRadioElement *radioElem)
{
	return;
}

CGuiRadioElement::CGuiRadioElement(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CSlrImage *imageNotSelected, CSlrImage *imageSelected)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->imageNotSelected = imageNotSelected;
	this->imageSelected = imageSelected;
	this->isSelected = false;
}

CGuiRadioElement::CGuiRadioElement(CSlrImage *imageNotSelected, CSlrImage *imageSelected)
: CGuiElement(50, 50, -1, 100, 100)
{
	this->imageNotSelected = imageNotSelected;
	this->imageSelected = imageSelected;
	this->isSelected = false;
}

CGuiRadio::CGuiRadio(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, std::list<CGuiRadioElement *> *elements, bool blitScaled)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiRadio";
	
	this->elements = elements;
	this->selectedElement = NULL;
	this->blitScaled = blitScaled;
}

void CGuiRadio::Render()
{
	this->Render(this->posX, this->posY);
}

void CGuiRadio::Render(GLfloat posX, GLfloat posY)
{
	if (blitScaled)
	{
		GLfloat elemSizeX = this->sizeX / this->elements->size();
		GLfloat drawX = posX;
		
		for (std::list<CGuiRadioElement *>::iterator enumElem = this->elements->begin();
			 enumElem != this->elements->end(); enumElem++)
		{
			CGuiRadioElement *radioElem = (*enumElem);
			
			if (radioElem->isSelected)
			{
				//void Render(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
				radioElem->imageSelected->Render(drawX, posY, this->posZ,
					 elemSizeX, this->sizeY);
			}
			else 
			{
				radioElem->imageNotSelected->Render(drawX, posY, this->posZ,
					 elemSizeX, this->sizeY);				
			}
			
			drawX += elemSizeX;

			radioElem->Render();
		}
	}
	else
	{
		for (std::list<CGuiRadioElement *>::iterator enumElem = this->elements->begin();
			 enumElem != this->elements->end(); enumElem++)
		{
			CGuiRadioElement *radioElem = (*enumElem);
			
			if (radioElem->isSelected)
			{
				//void Render(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
				radioElem->imageSelected->Render(radioElem->posX, radioElem->posY, this->posZ,
					 radioElem->sizeX, radioElem->sizeY);
			}
			else 
			{
				//void Render(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
				radioElem->imageNotSelected->Render(radioElem->posX, radioElem->posY, this->posZ,
					 radioElem->sizeX, radioElem->sizeY);				
			}

			radioElem->Render();
		}
	}
	
	
}

void CGuiRadio::SetElement(CGuiRadioElement *selectedElement)
{
	for (std::list<CGuiRadioElement *>::iterator enumElem = this->elements->begin();
		 enumElem != this->elements->end(); enumElem++)
	{
		CGuiRadioElement *radioElem = (*enumElem);
		if (radioElem == selectedElement)
		{
			radioElem->isSelected = true;
		}
		else 
		{
			radioElem->isSelected = false;
		}
	}
	
	this->selectedElement = selectedElement;
}

void CGuiRadio::SetElement(int elemNum)
{
	int i = 0;
	
	CGuiRadioElement *selectElem = NULL;
	
	for (std::list<CGuiRadioElement *>::iterator enumElem = this->elements->begin();
		 enumElem != this->elements->end(); enumElem++)
	{
		CGuiRadioElement *radioElem = (*enumElem);
		if (i == elemNum)
		{
			radioElem->isSelected = true;
			selectElem = radioElem;
		}
		else 
		{
			radioElem->isSelected = false;
		}
		
		i++;
	}
	
	this->selectedElement = selectElem;
}

bool CGuiRadio::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiRadio::DoTap(%d, %d)", x, y);
	for (std::list<CGuiRadioElement *>::iterator enumElem = this->elements->begin();
		 enumElem != this->elements->end(); enumElem++)
	{
		CGuiRadioElement *radioElem = (*enumElem);
	
		if (radioElem->IsInside(x, y))
		{
			this->SetElement(radioElem);
			return true;
		}
	}
	
	return false;
}

/*
bool CGuiRadio::DoFinishTap(GLfloat x, GLfloat y);
bool CGuiRadio::DoDoubleTap(GLfloat x, GLfloat y);
bool CGuiRadio::DoFinishDoubleTap(GLfloat x, GLfloat y);
bool CGuiRadio::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
bool CGuiRadio::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);	
void CGuiRadio::FinishTouches();
void CGuiRadio::DoLogic();
*/
