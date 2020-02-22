/*
 *  CGuiButtonMenu.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-01.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiButtonMenu.h"
#include "VID_GLViewController.h"
#include "GuiConsts.h"

CGuiButtonMenu::CGuiButtonMenu(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback)
: CGuiButton(image, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonMenu";

	this->beingClicked = false;
	this->clickConsumed = false;
	this->isExpanded = false;
	this->finishTapConsumed = false;

	this->backgroundImage = NULL;
	this->backgroundPosX = -1;
	this->backgroundPosY = -1;
	this->backgroundSizeX = -1;
	this->backgroundSizeY = -1;

	this->previousZ = posZ;

	this->manualRendering = false;
}

CGuiButtonMenu::CGuiButtonMenu(char *text, bool blah, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback)
: CGuiButton(text, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonMenu";
	
	this->beingClicked = false;
	this->clickConsumed = false;
	this->isExpanded = false;
	this->finishTapConsumed = false;
	
	this->backgroundImage = NULL;
	this->backgroundPosX = -1;
	this->backgroundPosY = -1;
	this->backgroundSizeX = -1;
	this->backgroundSizeY = -1;
	
	this->previousZ = posZ;
	
	this->manualRendering = false;
}

CGuiButtonMenu::CGuiButtonMenu(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment,
							   CSlrImage *backgroundImage,
							   GLfloat backgroundPosX, GLfloat backgroundPosY, GLfloat backgroundSizeX, GLfloat backgroundSizeY,
							   CGuiButtonCallback *callback)
: CGuiButton(image, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonMenu";

	this->beingClicked = false;
	this->clickConsumed = false;
	this->isExpanded = false;
	this->finishTapConsumed = false;

	this->backgroundImage = backgroundImage;
	this->backgroundPosX = backgroundPosX;
	this->backgroundPosY = backgroundPosY;
	this->backgroundSizeX = backgroundSizeX;
	this->backgroundSizeY = backgroundSizeY;

	this->previousZ = posZ;

	this->manualRendering = false;
}

void CGuiButtonMenu::AddMenuSubItem(CGuiElement *guiElement, float z)
{
	this->AddGuiElement(guiElement, z);
}

void CGuiButtonMenu::AddMenuSubItem(CGuiElement *guiElement)
{
	previousZ += 0.001;
	this->AddGuiElement(guiElement, previousZ);
}

/*
void CGuiButtonMenu::SetMenu(std::list<CGuiElement *> *menuElements)
{
	this->menuElements = menuElements;
}*/

void CGuiButtonMenu::Render()
{
	//LOGG("CGuiButtonMenu::Render");
	if (!manualRendering)
	{
		RenderElements();
		RenderButton();
	}
}

void CGuiButtonMenu::RenderElements()
{
	if (this->isExpanded)
	{
		if (this->backgroundImage)
			this->backgroundImage->RenderAlpha(backgroundPosX, backgroundPosY, posZ, backgroundSizeX, backgroundSizeY, 0.85f);

		for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
			 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
		{
			CGuiElement *guiElement = (*enumGuiElems).second;

			if (!guiElement->visible)
				continue;

			//LOGG("render %f: %s", (*enumGuiElems).first, guiElement->name);
			guiElement->Render();
		}
	}
}

void CGuiButtonMenu::RenderButton()
{
	CGuiButton::Render();
}

void CGuiButtonMenu::HideSubMenu(bool immediately)
{
	LOGD("CGuiButtonMenu::HideSubMenu: this=%s", this->name);
	this->isExpanded = false;

	if (this->callback)
		this->callback->ButtonExpandedChanged(this);

	this->HideSubMenuNoCallback(immediately);

}

void CGuiButtonMenu::HideSubMenuNoCallback(bool immediately)
{
	//LOGG("CGuiButtonMenu::HideSubMenuNoCallback");
	beingClicked = false;
	clickConsumed = false;
	zoomingLocked = false;
	finishTapConsumed = false;

	if (immediately)
	{
		this->sizeX = this->buttonSizeX;
		this->sizeY = this->buttonSizeY;
		this->posX = this->buttonPosX;
		this->posY = this->buttonPosY;
	}

	this->isExpanded = false;
}

bool CGuiButtonMenu::DoTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiButtonMenu::DoTap");
	if (this->enabled == false)
		return IsInside(x, y);

	finishTapConsumed = false;

	if (this->isExpanded)
	{
		//LOGG("isExpanded=true, check buttons");
		for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
			 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
		{
			CGuiElement *guiElement = (*enumGuiElems).second;

			if (!guiElement->visible)
				continue;

			if (guiElement->DoTap(x, y))
				return true;
		}
		//LOGG("isExpanded=true, check done");
	}

	if (CGuiButton::DoTap(x, y))
		return true;

	if (this->isExpanded && (x < (SCREEN_WIDTH-menuButtonSizeX)))
	{
		return true;
	}

	return false;
}

bool CGuiButtonMenu::DoFinishTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiButtonMenu::DoFinishTap");
	if (this->enabled == false)
		return IsInside(x, y);

	if (finishTapConsumed)
	{
		//LOGG("finishTapConsumed == true");
		finishTapConsumed = false;
		return true;
	}

	if (this->isExpanded)
	{
		//LOGG("isExpanded");
		for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
			 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
		{
			CGuiElement *guiElement = (*enumGuiElems).second;

			if (!guiElement->visible)
				continue;

			if (guiElement->DoFinishTap(x, y))
				return true;
		}
	}

	if (IsInside(x, y))
	{
		//LOGG("isInside");

		//if (this->isExpanded)
		//	LOGG("isExpanded");
		//if (this->zoomable)
		//	LOGG("zoomable");

			if (!this->zoomable)
			{
				//LOGD("[%s] DoFinishTap: set isExpanded=!isExpanded", this->name);
				this->isExpanded = !this->isExpanded;
				if (this->callback)
					this->callback->ButtonExpandedChanged(this);
			}

		if (this->isExpanded && this->zoomable)
		{
			//LOGD("[%s] DoFinishTap: this->isExpanded && this->zoomable: hide submenu", this->name);
			HideSubMenu(false);
			this->clickConsumed = true;
			return true;
		}
		else
		{
			if (this->zoomable)
			{
				//LOGD("[%s] DoFinishTap: this->zoomable: set isExpanded=false", this->name);
				this->isExpanded = false;
				zoomingLocked = false;
			}
			return CGuiButton::DoFinishTap(x, y);
		}
	}
/*
	if (IsInside(x, y))
	{
		if (!this->zoomable)
		{
			LOGG("DoFinishTap: set isExpanded=!isExpanded");
			this->isExpanded = !this->isExpanded;
			if (this->callback)
				this->callback->ButtonExpandedChanged(this);
		}
	}
*/

	if (CGuiButton::DoFinishTap(x, y))
		return true;

	if (this->isExpanded && (x < (SCREEN_WIDTH-menuButtonSizeX)))
		return true;

	return false;
}

bool CGuiButtonMenu::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	return DoFinishTap(x, y);
}


bool CGuiButtonMenu::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	//LOGG("CGuiButtonMenu::DoMove");
	//LOGG("distX=%f", distX);
	//LOGG("distY=%f", distY);

	//LOGG("> (%f)", (float)(buttonSizeX * this->buttonZoom));

	if (isExpanded)
	{
		for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
			 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
		{
			CGuiElement *guiElement = (*enumGuiElems).second;

			if (!guiElement->visible)
				continue;

			if (guiElement->IsInside(x, y))
			{
				if (guiElement->DoMove(x, y, distX, distY, diffX, diffY))
					return true;
			}
		}
		return true;
	}

	if (!IsInside(x, y) && this->beingClicked) //, abs(distX) > (buttonSizeX * this->buttonZoom) || abs(distY) > (buttonSizeY * this->buttonZoom))
	{
		//LOGG("SHOW BUTTONMENU");
		//LOGG("DoMove: set isExpanded=true");
		isExpanded = true;
		zoomingLocked = true;
		if (this->callback)
			this->callback->ButtonExpandedChanged(this);

		while (1)
		{
			if (DoExpandZoom())
				break;
		}

		return true;
	}

	if (!this->IsInside(x, y))
	{
		if (isExpanded && (x < SCREEN_WIDTH-menuButtonSizeX))
			return true;
	}

	isExpanded = false;
	return CGuiButton::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiButtonMenu::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
//	if (this->isExpanded
//		&& (x < (SCREEN_WIDTH-menuButtonSizeX)))
//		return true;
//	return false;

	if (this->isExpanded && this->wasExpanded)
	{
		return this->DoFinishTap(x, y);
	}
	
	this->wasExpanded = this->isExpanded;
	
	return false;

}


void CGuiButtonMenu::FinishTouches()
{
	//LOGG("CGuiButtonMenu::FinishTouches");

	if (this->isExpanded == false)
		CGuiButton::FinishTouches();

	this->wasExpanded = this->isExpanded;

	/*
	if (this->zoomable)
		this->isExpanded = false;
	CGuiButton::FinishTouches();
	 */

}

void CGuiButtonMenu::DoLogic()
{
	if (beingClicked && this->zoomable && sizeX >= buttonSizeX*buttonZoom)
	{
		//LOGG("DoLogic: set isExpanded=true");
		if (this->isExpanded == false)
		{
			this->isExpanded = true;
			if (this->callback)
				this->callback->ButtonExpandedChanged(this);
			//sizeX = buttonSizeX*buttonZoom;
			finishTapConsumed = true;
		}
	}
	else if (!beingClicked && this->zoomable && sizeX < buttonSizeX)
	{
		//LOGG("DoLogic: set isExpanded=false");
		if (this->isExpanded == true)
		{
			this->isExpanded = false;
			if (this->callback)
				this->callback->ButtonExpandedChanged(this);
		}
	}

	if (isExpanded)
		return;

	CGuiButton::DoLogic();
}

void CGuiButtonMenu::SetExpanded(bool expanded)
{
	this->isExpanded = expanded;
}



