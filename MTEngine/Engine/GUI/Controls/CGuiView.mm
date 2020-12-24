/*
 *  CGuiView.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiView.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CGuiWindow.h"

CGuiView::CGuiView(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
	: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiView";
	this->previousZ = posZ;
	this->previousFrontZ = posZ;
	
	focusElement = NULL;
	
	consumeTapBackground = true;
	positionElementsOnFrameMove = true;
	
	//mousePosX = mousePosY = -1;
}

bool CGuiView::IsInside(GLfloat x, GLfloat y)
{
	return CGuiElement::IsInside(x,y);
}

bool CGuiView::IsInsideView(GLfloat x, GLfloat y)
{
	if (!this->visible)
		return false;
	
	return this->IsInsideViewNonVisible(x, y);
}

bool CGuiView::IsInsideViewNonVisible(GLfloat x, GLfloat y)
{
	if (x >= this->posX && x <= this->posEndX
		&& y >= this->posY && y <= this->posEndY)
	{
		return true;
	}
	
	return false;
}


void CGuiView::SetPosition(GLfloat posX, GLfloat posY)
{
	CGuiElement::SetPosition(posX, posY);
}
void CGuiView::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ)
{
	CGuiElement::SetPosition(posX, posY, posZ);
}

void CGuiView::SetSize(GLfloat sizeX, GLfloat sizeY)
{
	CGuiElement::SetSize(sizeX, sizeY);
}

void CGuiView::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiElement::SetPosition(posX, posY, posZ, sizeX, sizeY);
	
	if (positionElementsOnFrameMove)
	{
		this->SetPositionElements(posX, posY);
	}
}

// iterate over all elements and move them accordingly, to be called by CGuiViewFrame when window is moved
// TODO: change window frame movements to use CGuiAnimation and glTranslate
void CGuiView::SetPositionElements(GLfloat posX, GLfloat posY)
{
	LOGG("CGuiView::SetPositionElements: px=%f py=%f", posX, posY);
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;
		
		LOGG("pElement '%s' offset=%f %f", pElement->name, pElement->offsetPosX, pElement->offsetPosY);
		pElement->SetPosition(this->posX + pElement->offsetPosX, this->posY + pElement->offsetPosY);
	}
	
}

void CGuiView::PositionCenterOnParentView()
{
	float parentX, parentY;
	if (this->parent)
	{
		parentX = this->parent->posX;
		parentY = this->parent->posY;
	}
	else
	{
		parentX = SCREEN_WIDTH/2.0f;
		parentY = SCREEN_HEIGHT/2.0f;
		
	}
	
	this->SetPosition(parentX - this->sizeX/2.0f, parentY - this->sizeY/2.0f);
}


void CGuiView::RemoveGuiElements()
{
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;
		pElement->parent = NULL;
	}

	guiElementsUpwards.clear();
	guiElementsDownwards.clear();
}

void CGuiView::RemoveGuiElement(CGuiElement *guiElement)
{
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;
		
		if (pElement == guiElement)
		{
			this->guiElementsUpwards.erase(enumGuiElems);
			break;
		}
	}

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;
		
		if (pElement == guiElement)
		{
			this->guiElementsDownwards.erase(enumGuiElems);
			break;
		}
	}
	
	guiElement->parent = NULL;
}


void CGuiView::AddGuiElement(CGuiElement *guiElement, float z)
{
#ifndef RELEASE
	// sanity check
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;

		if (pElement == guiElement)
		{
			SYS_FatalExit("'%s' is already in the view '%s'", guiElement->name, this->name);
		}
	}
#endif

	//map<int, CObjectInfo *>::iterator objDataIt = detectedObjects.find(val);
	this->guiElementsUpwards[z] = guiElement;
	this->guiElementsDownwards[z] = guiElement;
//	this->previousZ = z;
	
	if (previousFrontZ < z)
		previousFrontZ = z;
	
	guiElement->parent = this;
}

void CGuiView::AddGuiElement(CGuiElement *guiElement)
{
#ifndef RELEASE
	// sanity check
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *pElement = (*enumGuiElems).second;

		if (pElement == guiElement)
		{
			SYS_FatalExit("'%s' is already in the view '%s'", guiElement->name, this->name);
		}
	}
#endif

	//map<int, CObjectInfo *>::iterator objDataIt = detectedObjects.find(val);

	this->previousZ += 0.001;
	this->guiElementsUpwards[previousZ] = guiElement;
	this->guiElementsDownwards[previousZ] = guiElement;
	
	guiElement->parent = this;

}

void CGuiView::BringToFront(CGuiElement *guiElement)
{
	RemoveGuiElement(guiElement);	
	AddGuiElement(guiElement, previousFrontZ + 0.01f);
}

void CGuiView::DoLogic()
{
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		if (!guiElement->visible)
			continue;

		guiElement->DoLogic();
	}
}


//@returns is consumed
bool CGuiView::DoTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiView::DoTap: '%s' x=%f y=%f", this->name, x, y);
	if (CGuiView::DoTapNoBackground(x, y))
		return true;

	//LOGG("done");
	
	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}

bool CGuiView::DoTapNoBackground(GLfloat x, GLfloat y)
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		LOGG("CGuiView::DoTap: %s", guiElement->name);
		if (!guiElement->visible)
			continue;

		if (guiElement->IsFocusable() && guiElement->IsInside(x, y))
		{
			SetFocus(guiElement);
		}
		
		if (guiElement->DoTap(x, y))
		{
			if (focusElement != NULL && focusElement != guiElement)
			{
				ClearFocus();
			}
			
			if (guiElement->bringToFrontOnTap)
			{
				guiMain->LockMutex(); //"CGuiView::DoTapNoBackground");
				this->BringToFront(guiElement);
				guiMain->UnlockMutex(); //"CGuiView::DoTapNoBackground");
			}
			return true;
		}
	}

	if (focusElement && !focusElement->IsInside(x, y))
	{
		ClearFocus();
	}
	
	return false;
}


bool CGuiView::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiView::DoFinishTap: %f %f", x, y);

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->DoFinishTap(x, y))
			return true;
	}

	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}

//@returns is consumed
bool CGuiView::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiView::DoDoubleTap:  x=%f y=%f", x, y);

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->DoDoubleTap(x, y))
			return true;
	}

	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}

bool CGuiView::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiView::DoFinishTap: %f %f", x, y);

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->DoFinishDoubleTap(x, y))
			return true;
	}

	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}


bool CGuiView::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	LOGG("CGuiView::DoMove: this is '%s'", this->name);
	
	//	LOGG("--- DoMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		LOGG("DoMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		if (!guiElement->visible)
			continue;
		
		volatile bool consumed = guiElement->DoMove(x, y, distX, distY, diffX, diffY);
		
		LOGG("   consumed=%d", consumed);
		if (consumed)
			return true;
	}
	
	return false;
}

bool CGuiView::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	//viewScoreTracks->FinishMove(x, y, distX, distY, accelerationX, accelerationY);
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->FinishMove(x, y, distX, distY, accelerationX, accelerationY))
			return true;
	}
	
	return false;
}






//@returns is consumed
bool CGuiView::DoRightClick(GLfloat x, GLfloat y)
{
	LOGG("CGuiView::DoRightClick: '%s' x=%f y=%f", this->name, x, y);
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		
		LOGG("CGuiView::DoRightClick: %s visible=%d", guiElement->name, guiElement->visible);
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoRightClick(x, y))
		{
			if (guiElement->bringToFrontOnTap)
			{
				guiMain->LockMutex(); //"CGuiView::DoRightClick");
				this->BringToFront(guiElement);
				guiMain->UnlockMutex(); //"CGuiView::DoRightClick");
			}
			
			return true;
		}
			
	}
	
	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	
	return false;
}


bool CGuiView::DoFinishRightClick(GLfloat x, GLfloat y)
{
	//LOGG("CGuiView::DoFinishRightClick: %f %f", x, y);
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoFinishRightClick(x, y))
			return true;
	}
	
	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}


bool CGuiView::DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	//	LOGG("--- DoRightClickMove ---");
	/*
	if (this->IsInside(x, y))
	{
		mousePosX = x;
		mousePosY = y;
	}
	else
	{
		mousePosX = -1;
		mousePosY = -1;
	}*/
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		//LOGG("DoRightClickMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		bool consumed = guiElement->DoRightClickMove(x, y, distX, distY, diffX, diffY);
		//LOGG("   consumed=%d", consumed);
		if (consumed)
			return true;
	}
	
	return false;
}

bool CGuiView::FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->FinishRightClickMove(x, y, distX, distY, accelerationX, accelerationY))
			return true;
	}
	
	return false;
}


bool CGuiView::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	//	LOGG("--- DoNotTouchedMove ---");
	/*
	if (this->IsInside(x, y))
	{
		mousePosX = x;
		mousePosY = y;
	}
	else
	{
		mousePosX = -1;
		mousePosY = -1;
	}
	 */
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		//LOGG("DoNotTouchedMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		//bool consumed =
		guiElement->DoNotTouchedMove(x, y);
		
		//LOGG("   consumed=%d", consumed);
		// arrrgh! this is a bug... not touched move event does not need to be 'consumed'. it is for tracking mouse!
		// TODO: refactor DoNotTouchedMove to not return anything (void).
//		if (consumed)
//			return true;
	}
	
	return false;
}

bool CGuiView::InitZoom()
{
	//viewScoreTracks->InitZoom();

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->InitZoom())
			return true;
	}

	return false;

}

bool CGuiView::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		if (guiElement->DoZoomBy(x, y, zoomValue, difference))
			return true;
	}

	return false;
}

bool CGuiView::DoScrollWheel(float deltaX, float deltaY)
{
	LOGG("CGuiView::DoScrollWheel: deltaX=%f deltaY=%f", deltaX, deltaY);

	if (!this->IsInsideView(guiMain->mousePosX, guiMain->mousePosY))
		return false;
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		LOGD("... checking guiElement %s", guiElement->name);
		if (!guiElement->visible)
			continue;
		
		if (guiElement->IsInside(guiMain->mousePosX, guiMain->mousePosY))
		{
			if (guiElement->DoScrollWheel(deltaX, deltaY))
				return true;
		}
		
	}
	
	return false;
}

void CGuiView::FinishTouches()
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;

		guiElement->FinishTouches();
	}

}

bool CGuiView::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiView::KeyDown: %d %s %s %s", keyCode, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	if (focusElement)
	{
		if (focusElement->KeyDown(keyCode, isShift, isAlt, isControl))
			return true;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->KeyDown(keyCode, isShift, isAlt, isControl))
		{
			return true;
		}
	}
	
	return false;
}

bool CGuiView::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (focusElement)
	{
		if (focusElement->KeyUp(keyCode, isShift, isAlt, isControl))
			return true;
	}

	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->KeyUp(keyCode, isShift, isAlt, isControl))
		{
			return true;
		}
	}
	
	return false;
}

bool CGuiView::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (focusElement)
	{
		if (focusElement->KeyPressed(keyCode, isShift, isAlt, isControl))
			return true;
	}
	
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->KeyPressed(keyCode, isShift, isAlt, isControl))
		{
			return true;
		}
	}
	
	return false;
}


bool CGuiView::DoMultiTapNoBackground(COneTouchData *touch, float x, float y)
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		//LOGG("CGuiView::DoTap: %s", guiElement->name);
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoMultiTap(touch, x, y))
			return true;
	}
	
	return false;
}

//@returns is consumed
bool CGuiView::DoMultiTap(COneTouchData *touch, float x, float y)
{
	//LOGD("CGuiView::DoMultiTap: '%s' x=%f y=%f", this->name, x, y);
	if (CGuiView::DoMultiTapNoBackground(touch, x, y))
		return true;
	
	//LOGD("done");
	
	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}

bool CGuiView::DoMultiMove(COneTouchData *touch, float x, float y)
{
	//viewScoreTracks->DoMove(x, y, distX, distY, diffX, diffY);
	
	//	LOGG("--- DoMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		//LOGG("DoMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		bool consumed = guiElement->DoMultiMove(touch, x, y); //, distX, distY, diffX, diffY);
		//LOGG("   consumed=%d", consumed);
		if (consumed)
			return true;
	}
	
	return false;

}

bool CGuiView::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoMultiFinishTap(touch, x, y))
			return true;
	}
	
	if (consumeTapBackground)
	{
		if (x >= posX && x < posEndX && y >= posY && y <= posEndY)
			return true;
	}
	
	return false;
}

void CGuiView::ActivateView()
{
	LOGG("CGuiView::ActivateView()");
}

void CGuiView::DeactivateView()
{
	LOGG("CGuiView::DeactivateView()");
}

void CGuiView::Render()
{
//#define LOGGUIVIEW
	
	
#if defined(LOGGUIVIEW)
	LOGD("-------------- CGuiView::Render() --------------");
	LOGD("view=%s", this->name);
#endif

	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		if ( (!guiElement->visible) || (guiElement->manualRender == true) )
			continue;

#if defined(LOGGUIVIEW)
		LOGD("....render %f: %s", (*enumGuiElems).first, guiElement->name);
#endif


		guiElement->Render();


#if defined(LOGGUIVIEW)
		LOGD("....render done %f: %s", (*enumGuiElems).first, guiElement->name);
#endif

	}
}

void CGuiView::Render(GLfloat posX, GLfloat posY)
{
	//LOGG("-------------- CGuiView::Render(posX=%f, posY=%f) --------------", posX, posY);
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		if (!guiElement->visible)
			continue;

		//LOGD("render %f: %s posX=%f posY=%f", (*enumGuiElems).first, guiElement->name, posX, posY);
		guiElement->Render(guiElement->posX + posX, guiElement->posY + posY);
	}
}

/*
void CGuiView::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
{
	//	LOGG("-------------- CGuiView::Render(posX=%f, posY=%f) --------------", posX, posY);
	for (std::map<float, CGuiElement *>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		if (!guiElement->visible)
			continue;

		//LOGG("render %f: %s posX=%f posY=%f", (*enumGuiElems).first, guiElement->name, posX, posY);
		guiElement->Render(guiElement->posX + posX, guiElement->posY + posY, sizeX, sizeY);
	}
}
*/

void CGuiView::RenderFocusBorder()
{
	if (this->focusElement != NULL)
	{
		this->focusElement->RenderFocusBorder();
	}
	else
	{
		BlitRectangle(this->posX, this->posY, this->posZ, this->sizeX, this->sizeY, 1.0f, 0.0f, 0.0f, 0.5f, guiMain->theme->focusBorderLineWidth);
	}
}

void CGuiView::UpdateTheme()
{
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		
		guiElement->UpdateTheme();
	}
}


// focus
void CGuiView::ClearFocus()
{
	LOGD("CGuiView::ClearFocus");
	if (focusElement != NULL)
	{
		focusElement->FocusLost();
	}

	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		
		guiElement->hasFocus = false;
	}
	
	focusElement = NULL;
}

bool CGuiView::SetFocus(CGuiElement *element)
{
	LOGD("CGuiView::SetFocus: %s", (element ? element->name : "NULL"));
	this->repeatTime = 0;
	ClearFocus();

	if (element != NULL && element->SetFocus(true))
	{
		this->focusElement = element;
		element->hasFocus = true;
		
		LOGD("CGuiView::SetFocus: %s is set focus", element->name);
	}
	
	return true;
}



void CGuiView::ResourcesPrepare()
{
	for (std::map<float, CGuiElement *, compareZupwards>::iterator enumGuiElems = guiElementsUpwards.begin();
		 enumGuiElems != guiElementsUpwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;

		// win32 fuckup:
//	for (std::map<float, CGuiElement *>::iterator enumGuiElems = guiElementsDownwards.begin();
//		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
//	{
//		CGuiElement *guiElement = (*enumGuiElems).second;
		
		
		guiElement->ResourcesPrepare();

	}
}

//

bool CGuiView::StartAnimationEditorDebug()
{
	return false;
}

void CGuiView::ReturnFromAnimationEditorDebug()
{
}

