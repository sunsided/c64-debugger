/*
 *  CGuiSlider.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiSlider.h"
#include "CGuiMain.h"

#define GAUGE_SIZE 23
#define GAUGE_SIZE_HALF 11

void CGuiSliderCallback::SliderValueChanged(CGuiSlider *owner, float value)
{
}

void CGuiSlider::SliderValueChanged(float value)
{
}


CGuiSlider::CGuiSlider(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiSliderCallback *callback)
:CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiSlider";
	this->posX = posX;
	this->posY = posY;
	this->sizeX = sizeX;
	this->sizeY = sizeY;
	this->value = 0.5;
	this->changing = false;
	this->callback = callback;

	this->readOnly = false;

	this->alpha = 1.0;
}

bool CGuiSlider::DoTap(GLfloat x, GLfloat y)
{
	if (!this->visible)
		return false;

//	if (x >= (posX-GAUGE_SIZE_HALF) && x <= (posX+sizeX+GAUGE_SIZE_HALF)
//		&& (y >= (posY-GAUGE_SIZE_HALF)) && y <= (posY+sizeY+GAUGE_SIZE_HALF))

	if (x >= (posX) && x <= (posX+sizeX)
		&& (y >= (posY)) && y <= (posY+sizeY))
	{
		if (!this->readOnly)
		{
			this->value = (x - posX)/sizeX;
			changing = true;

			if (callback != NULL)
			{
				callback->SliderValueChanged(this, this->value);
			}
			this->SliderValueChanged(this->value);
		}
		return true;
	}

	return false;
}

bool CGuiSlider::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (!this->visible)
		return false;

	//GAUGE_SIZE_HALF
	if (x >= (posX) && x <= (posX+sizeX)
		&& (y >= (posY)) && y <= (posY+sizeY))
	{
		if (!this->readOnly)
		{
			this->value = (x - posX)/sizeX;
			changing = true;

			if (callback != NULL)
			{
				callback->SliderValueChanged(this, this->value);
			}
			this->SliderValueChanged(this->value);
		}
		return true;
	}
	return false;
}

//bool DoFinishTap(GLfloat x, GLfloat y);
bool CGuiSlider::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!this->visible)
		return false;

	if (x >= (posX) && x <= (posX+sizeX)
		&& (y >= (posY)) && y <= (posY+sizeY))
	{
		if (!this->readOnly)
		{
			this->value = (x - posX)/sizeX;
			changing = true;

			if (callback != NULL)
			{
				callback->SliderValueChanged(this, this->value);
			}
			this->SliderValueChanged(this->value);
		}
		return true;
	}
	else if (changing == true)
	{
		if (!this->readOnly)
		{
			if (x < posX)
			{
				this->value = 0.0;
			}
			else if (x > (posX+sizeX))
			{
				this->value = 1.0;
			}
			else
			{
				this->value = (x - posX)/sizeX;
			}				

			if (callback != NULL)
			{
				callback->SliderValueChanged(this, this->value);
			}
			this->SliderValueChanged(this->value);
		}
		return true;
	}

	return false;
}

//bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
void CGuiSlider::FinishTouches()
{
	this->changing = false;
}

bool CGuiSlider::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!this->visible)
		return false;

	if (changing)
	{
		this->changing = false;
		return true;
	}
	return false;
}

void CGuiSlider::DoLogic()
{
}


void CGuiSlider::Render()
{
	this->Render(this->posX, this->posY, this->sizeX, this->sizeY);
}

void CGuiSlider::Render(GLfloat posX, GLfloat posY)
{
	this->Render(posX, posY, this->sizeX, this->sizeY);
}

void CGuiSlider::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
{
	if (!this->visible)
		return;

	guiMain->theme->imgSliderFull->RenderAlpha(
		 posX, posY, posZ,
		 (sizeX * this->value), sizeY,
		 0.0, 0.0, this->value, 1.0, alpha);

	guiMain->theme->imgSliderEmpty->RenderAlpha(
		 (posX + (sizeX * this->value)), posY, posZ,
		 (sizeX - (sizeX * this->value)), sizeY,
		 this->value, 0.0, 1.0, 1.0, alpha);

	guiMain->theme->imgSliderGauge->RenderAlpha(
		 (posX + (sizeX*this->value) - GAUGE_SIZE_HALF),
		 (posY), posZ+0.01,	//(sizeX/100)*4      (sizeY*0.3)	// - (sizeY*0.36)
		 GAUGE_SIZE, sizeY,
		 0.0, 0.0, 1.0, 1.0, alpha);
}

void CGuiSlider::SetValue(float value)
{
	this->value = value;
}


