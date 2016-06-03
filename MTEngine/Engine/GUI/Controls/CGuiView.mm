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

CGuiView::CGuiView(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
	: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiView";
	this->previousZ = posZ;
	
	consumeTapBackground = true;
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
}

void CGuiView::RemoveGuiElements()
{
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
	//LOGD("CGuiView::DoTap: '%s' x=%f y=%f", this->name, x, y);
	if (CGuiView::DoTapNoBackground(x, y))
		return true;

	//LOGD("done");
	
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
		//LOGD("CGuiView::DoTap: %s", guiElement->name);
		if (!guiElement->visible)
			continue;

		if (guiElement->DoTap(x, y))
			return true;
	}

	return false;
}


bool CGuiView::DoFinishTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiView::DoFinishTap: %f %f", x, y);

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
	//viewScoreTracks->DoMove(x, y, distX, distY, diffX, diffY);
	
	//	LOGG("--- DoMove ---");
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		//LOGG("DoMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		bool consumed = guiElement->DoMove(x, y, distX, distY, diffX, diffY);
		//LOGG("   consumed=%d", consumed);
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
	//LOGD("CGuiView::DoRightClick: '%s' x=%f y=%f", this->name, x, y);
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		//LOGD("CGuiView::DoRightClick: %s", guiElement->name);
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoRightClick(x, y))
			return true;
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
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		//LOGG("DoNotTouchedMove %f: %s", (*enumGuiElems).first, guiElement->name);
		
		bool consumed = guiElement->DoNotTouchedMove(x, y);
		//LOGG("   consumed=%d", consumed);
		if (consumed)
			return true;
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
	for (std::map<float, CGuiElement *, compareZdownwards>::iterator enumGuiElems = guiElementsDownwards.begin();
		 enumGuiElems != guiElementsDownwards.end(); enumGuiElems++)
	{
		CGuiElement *guiElement = (*enumGuiElems).second;
		if (!guiElement->visible)
			continue;
		
		if (guiElement->DoScrollWheel(deltaX, deltaY))
			return true;
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
		//LOGD("CGuiView::DoTap: %s", guiElement->name);
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

bool CGuiView::StartAnimationEditorDebug()
{
	return false;
}

void CGuiView::ReturnFromAnimationEditorDebug()
{
}

