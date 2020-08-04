/*
 *  CGuiElement.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiElement.h"

CGuiElement::CGuiElement(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	this->name = "GuiElement";

	this->parent = NULL;
	
	this->visible = true;
	this->allowFocus = true;
	
	SetPositionOffset(posX, posY, posZ);
	SetPosition(posX, posY, posZ, sizeX, sizeY);

	this->elementAlignment = ELEMENT_ALIGNED_NONE;

	this->locked = false;
	this->fullPath = NULL;

	this->hasFocus = false;

	this->manualRender = false;
	this->bringToFrontOnTap = false;
	
	this->repeatTime = 0;
	this->isKeyDown = false;
	
	this->userData = NULL;
}

CGuiElement::~CGuiElement()
{

}

bool CGuiElement::IsVisible()
{
	return this->visible;
}

void CGuiElement::SetVisible(bool isVisible)
{
	this->visible = isVisible;
}

// refresh UI
void CGuiElement::UpdatePosition()
{
	this->SetPosition(this->posX, this->posY, this->posZ, this->sizeX, this->sizeY);
}

void CGuiElement::SetPosition(GLfloat posX, GLfloat posY)
{
	this->SetPosition(posX, posY, this->posZ, sizeX, sizeY);
}

void CGuiElement::SetSize(GLfloat sizeX, GLfloat sizeY)
{
	this->sizeX = sizeX;
	this->sizeY = sizeY;
	this->posEndX = posX + sizeX;
	this->posEndY = posY + sizeY;
}

void CGuiElement::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ)
{
	this->SetPosition(posX, posY, posZ, this->sizeX, this->sizeY);
}

void CGuiElement::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("CGuiElement::SetPosition3, name=%s", this->name);

	this->posX = posX;
	this->posY = posY;
	this->posZ = posZ;
	this->SetSize(sizeX, sizeY);
	
	this->gapX = 0;
	this->gapY = 0;
}

void CGuiElement::SetPositionOffset(GLfloat offsetPosX, GLfloat offsetPosY)
{
	this->SetPositionOffset(offsetPosX, offsetPosY, offsetPosZ);
}

void CGuiElement::SetPositionOffset(GLfloat offsetPosX, GLfloat offsetPosY, GLfloat offsetPosZ)
{
	this->offsetPosX = offsetPosX;
	this->offsetPosY = offsetPosY;
	this->offsetPosZ = offsetPosZ;
	
	this->offsetPosEndX = offsetPosX + sizeX;
	this->offsetPosEndY = offsetPosY + sizeY;
}

bool CGuiElement::IsInside(GLfloat x, GLfloat y)
{
	if (!this->visible)
		return false;

	return IsInsideNonVisible(x, y);
}

bool CGuiElement::IsInsideNonVisible(GLfloat x, GLfloat y)
{
	if (x >= this->posX && x <= this->posEndX
		&& y >= this->posY && y <= this->posEndY)
	{
		return true;
	}

	return false;
}

void CGuiElement::Render()
{
}


void CGuiElement::Render(GLfloat posX, GLfloat posY)
{
	Render();
}

void CGuiElement::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
{
	Render(posX, posY);
}

void CGuiElement::RenderFocusBorder()
{
	// TODO: render focus rectangle based on colours from theme!
	const float lineWidth = 0.7f;
	BlitRectangle(this->posX, this->posY, this->posZ, this->sizeX, this->sizeY, 1.0f, 0.0f, 0.0f, 0.5f, lineWidth);
}

bool CGuiElement::IsFocusable()
{
	return allowFocus;
}

bool CGuiElement::DoTap(GLfloat x, GLfloat y)
{
	//LOGG("CGuiElement::DoTap");
	return false;
}

bool CGuiElement::DoFinishTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiElement::DoFinishTap");
	return false;
}

bool CGuiElement::DoDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiElement::DoDoubleTap");
	return this->DoTap(x, y);
}

bool CGuiElement::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiElement::DoFinishDoubleTap");
	return this->DoFinishTap(x, y);
}

bool CGuiElement::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	LOGG("CGuiElement::DoMove");
	return false;
}

bool CGuiElement::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	LOGG("CGuiElement::FinishMove");
	return false;
}

bool CGuiElement::DoRightClick(GLfloat x, GLfloat y)
{
	return false;
}

bool CGuiElement::DoFinishRightClick(GLfloat x, GLfloat y)
{
	return false;
}

bool CGuiElement::DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return false;
}

bool CGuiElement::FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return false;	
}


bool CGuiElement::DoNotTouchedMove(GLfloat x, GLfloat y)
{
	//LOGG("CGuiElement::DoNotTouchedMove");
	return false;
}

bool CGuiElement::InitZoom()
{
	LOGG("CGuiElement::InitZoom");
	return false;
}

bool CGuiElement::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	LOGG("CGuiElement::DoZoomBy");
	return false;
}

bool CGuiElement::DoScrollWheel(float deltaX, float deltaY)
{
	LOGG("CGuiElement::DoScrollWheel");
	return false;
}

bool CGuiElement::DoMultiTap(COneTouchData *touch, float x, float y)
{
	LOGG("CGuiElement::DoMultiTap: %s", this->name);
	return false;
}

bool CGuiElement::DoMultiMove(COneTouchData *touch, float x, float y)
{
	LOGG("CGuiElement::DoMultiMove: %s", this->name);
	return false;

}

bool CGuiElement::DoMultiFinishTap(COneTouchData *touch, float x, float y)
{
	LOGG("CGuiElement::DoMultiFinishTap: %s", this->name);
	return false;
}

void CGuiElement::FinishTouches()
{
	//LOGG("CGuiElement::FinishTouches");
}

void CGuiElement::DoLogic()
{
	//LOGG("CGuiElement::DoLogic");
}

void CGuiElement::AddGuiElement(CGuiElement *guiElement, float z)
{
	//map<int, CObjectInfo *>::iterator objDataIt = detectedObjects.find(val);
	this->guiElementsUpwards[z] = guiElement;
	this->guiElementsDownwards[z] = guiElement;
	
	guiElement->parent = this;
}

GLfloat CGuiElement::GetWidth()
{
	// optimize this in setPosition... or better not
	return this->posEndX - this->posX;
}

GLfloat CGuiElement::GetHeight()
{
	// optimize this in setPosition... or better not
	return this->posEndY - this->posY;
}

void CGuiElement::FocusReceived()
{
	this->hasFocus = true;
}

void CGuiElement::FocusLost()
{
	this->hasFocus = false;
}

bool CGuiElement::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiElement::KeyDown: %d %s %s %s", keyCode, STRBOOL(isShift), STRBOOL(isAlt), STRBOOL(isControl));
	return false;
}

bool CGuiElement::KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

bool CGuiElement::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	return false;
}

void CGuiElement::ResourcesPrepare()
{	
}

void CGuiElement::ResourcesPostLoad()
{
}

bool CGuiElement::SetFocus(bool focus)
{
	this->FocusReceived();
	return true;
}

