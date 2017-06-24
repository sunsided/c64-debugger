/*
 *  CGuiButtonSwitch.mm
 *  MobiTracker
 *
 *  Created by mars on 4/12/10.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiButtonSwitch.h"
#include "CGuiMain.h"

CGuiButtonSwitch::CGuiButtonSwitch(CSlrImage *imageOn, CSlrImage *imageOff,
		GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment,
		CGuiButtonSwitchCallback *callback)
: CGuiButton(imageOff, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonSwitch";
	this->beingClicked = false;
	this->clickConsumed = false;
	this->isOn = false;

	this->imageOn = imageOn;
	this->imageOff = imageOff;

	this->switchCallback = callback;
}

CGuiButtonSwitch::CGuiButtonSwitch(char *text,
		GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment,
		CGuiButtonSwitchCallback *callback)
: CGuiButton(text, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonSwitch:Text";

	this->beingClicked = false;
	this->clickConsumed = false;
	this->isOn = false;

	this->imageOff = guiMain->theme->imgButtonBackgroundEnabled;
	this->imageOn = guiMain->theme->imgButtonBackgroundEnabledPressed;

	this->switchCallback = callback;
}

CGuiButtonSwitch::CGuiButtonSwitch(CSlrImage *bkgImageOn, CSlrImage *bkgImageOff, CSlrImage *bkgImageDisabled,
				 GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
				 CSlrString *textUTF,
				 byte textAlignment, float textOffsetX, float textOffsetY,
				 CSlrFont *font, float fontScale,
			   float textColorOnR, float textColorOnG, float textColorOnB, float textColorOnA,
			   float textColorOffR, float textColorOffG, float textColorOffB, float textColorOffA,
			   float textColorDisabledR, float textColorDisabledG, float textColorDisabledB, float textColorDisabledA,
				 CGuiButtonSwitchCallback *callback)
: CGuiButton(bkgImageOn, bkgImageDisabled,
				posX, posY, posZ, sizeX, sizeY,
				textUTF,
				textAlignment, textOffsetX, textOffsetY,
				font, fontScale,
				textColorOnR, textColorOnG, textColorOnB, textColorOnA,
				textColorDisabledR, textColorDisabledG, textColorDisabledB, textColorDisabledA,
				callback)

			 
{
	this->name = "CGuiButtonSwitch:Text";
	
	this->beingClicked = false;
	this->clickConsumed = false;
	this->isOn = false;
	
	this->imageOff = bkgImageOff;
	this->imageOn = bkgImageOn;

	this->textColorOffR = textColorOffR;
	this->textColorOffG = textColorOffG;
	this->textColorOffB = textColorOffB;
	this->textColorOffA = textColorOffA;
	
	this->switchCallback = callback;
	
	InitBackgroundColors();

}

void CGuiButtonSwitch::InitBackgroundColors()
{
	CGuiButton::InitBackgroundColors();

	buttonSwitchOnColorR = guiMain->theme->buttonSwitchOnColorR;
	buttonSwitchOnColorG = guiMain->theme->buttonSwitchOnColorG;
	buttonSwitchOnColorB = guiMain->theme->buttonSwitchOnColorB;
	buttonSwitchOnColorA = guiMain->theme->buttonSwitchOnColorA;
	buttonSwitchOnColor2R = guiMain->theme->buttonSwitchOnColor2R;
	buttonSwitchOnColor2G = guiMain->theme->buttonSwitchOnColor2G;
	buttonSwitchOnColor2B = guiMain->theme->buttonSwitchOnColor2B;
	buttonSwitchOnColor2A = guiMain->theme->buttonSwitchOnColor2A;
	
	buttonSwitchOffColorR = guiMain->theme->buttonSwitchOffColorR;
	buttonSwitchOffColorG = guiMain->theme->buttonSwitchOffColorG;
	buttonSwitchOffColorB = guiMain->theme->buttonSwitchOffColorB;
	buttonSwitchOffColorA = guiMain->theme->buttonSwitchOffColorA;
	buttonSwitchOffColor2R = guiMain->theme->buttonSwitchOffColor2R;
	buttonSwitchOffColor2G = guiMain->theme->buttonSwitchOffColor2G;
	buttonSwitchOffColor2B = guiMain->theme->buttonSwitchOffColor2B;
	buttonSwitchOffColor2A = guiMain->theme->buttonDisabledColor2A;
	
}


void CGuiButtonSwitch::InitWithText(char *text)
{
	this->image = guiMain->theme->imgButtonBackgroundEnabled;
	this->imageOff = guiMain->theme->imgButtonBackgroundEnabled;
	this->imageOn = guiMain->theme->imgButtonBackgroundEnabledPressed;
	SetText(text);
}

bool CGuiButtonSwitch::DoSwitch()
{
	if (this->isOn == true)
	{
		this->isOn = false;
		this->image = imageOff;
	}
	else
	{
		this->isOn = true;
		this->image = imageOn;
	}

	if (this->switchCallback)
	{
		return this->switchCallback->ButtonSwitchChanged(this);
	}
	else
	{
		return false;
	}
}

void CGuiButtonSwitch::SetOn(bool isOn)
{
	this->isOn = isOn;
	if (this->isOn == true)
	{
		this->image = imageOn;
	}
	else
	{
		this->image = imageOff;
	}

	// locks later
	//if (this->switchCallback)
	//	this->switchCallback->ButtonSwitchChanged(this);
}

bool CGuiButtonSwitch::IsOn()
{
	return this->isOn;
}

bool CGuiButtonSwitch::Pressed(GLfloat posX, GLfloat posY)
{
	return this->DoSwitch();
}

void CGuiButtonSwitch::Render()
{
	this->Render(posX, posY);
}

void CGuiButtonSwitch::RenderUTFButton(GLfloat posX, GLfloat posY)
{
	CSlrImage *rimg = this->imageOn;
	
	if (this->enabled == false)
	{
		if (this->imageDisabled != NULL)
		{
			rimg = imageDisabled;
		}
	}
	else if (this->isOn == false)
	{
		rimg = this->imageOff;
	}
	
	if (rimg != NULL)
	{
		rimg->Render(posX, posY, posZ, sizeX, sizeY);
	}
	else
	{
		if (this->enabled)
		{
			if (this->isOn)
			{
				BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
									this->buttonSwitchOnColor2R, this->buttonSwitchOnColor2G, this->buttonSwitchOnColor2B,
									this->buttonSwitchOnColor2A);
				
				BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
									this->sizeX - this->buttonShadeDistance2, this->sizeY - this->buttonShadeDistance2,
									this->buttonSwitchOnColorR, this->buttonSwitchOnColorG, this->buttonSwitchOnColorB,
									this->buttonSwitchOnColorA);
			}
			else
			{
				BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
									this->buttonEnabledColor2R, this->buttonEnabledColor2G, this->buttonEnabledColor2B,
									this->buttonEnabledColor2A);
				
				BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
									this->sizeX - this->buttonShadeDistance2, this->sizeY - this->buttonShadeDistance2,
									this->buttonEnabledColorR, this->buttonEnabledColorG, this->buttonEnabledColorB,
									this->buttonEnabledColorA);
			}
		}
		else
		{
			BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
								this->buttonDisabledColor2R, this->buttonDisabledColor2G, this->buttonDisabledColor2B,
								this->buttonDisabledColor2A);
			
			BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
								this->sizeX - this->buttonShadeDistance2, this->sizeY - this->buttonShadeDistance2,
								this->buttonDisabledColorR, this->buttonDisabledColorG, this->buttonDisabledColorB,
								this->buttonDisabledColorA);			
		}

	}
	
	if (this->enabled)
	{
		if (this->isOn)
		{
			this->font->BlitTextColor(textUTF, posX + textDrawPosX, posY + textDrawPosY, posZ,
									  fontScale,
									  textColorR, textColorG, textColorB, textColorA,
									  textAlignment);			
		}
		else
		{
			this->font->BlitTextColor(textUTF, posX + textDrawPosX, posY + textDrawPosY, posZ,
									  fontScale,
									  textColorOffR, textColorOffG, textColorOffB, textColorOffA,
									  textAlignment);
		}
	}
	else
	{
		this->font->BlitTextColor(textUTF, posX + textDrawPosX, posY + textDrawPosY, posZ,
								  fontScale,
								  textColorDisabledR, textColorDisabledG, textColorDisabledB, textColorDisabledA,
								  textAlignment);
	}
}

void CGuiButtonSwitch::Render(GLfloat posX, GLfloat posY)
{
	//LOGD("CGuiButtonSwitch='%s'", this->name);

	if (this->visible)
	{
		//LOGD("--visible");
		
		if (textUTF != NULL)
		{
			this->RenderUTFButton(posX, posY);
			return;
		}
		
		if (this->enabled)
		{
			//LOGD("--enabled");
			if (this->isOn)
			{
				//LOGD("--isOn");
				if (this->imageOn != NULL)
				{
					image->Render(posX, posY, posZ, sizeX, sizeY);
				}
				else
				{
					//shade
					BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY,
										this->buttonSwitchOnColor2R, this->buttonSwitchOnColor2G, this->buttonSwitchOnColor2B,
										this->buttonSwitchOnColor2A);

					BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
										sizeX - this->buttonShadeDistance2, sizeY - this->buttonShadeDistance2,
										this->buttonSwitchOnColorR, this->buttonSwitchOnColorG, this->buttonSwitchOnColorB,
										this->buttonSwitchOnColorA);
				}
			}
			else
			{
				//LOGD("--isOff");
				if (this->imageOff != NULL)
				{
					image->Render(posX, posY, posZ, sizeX, sizeY);
				}
				else
				{
					//shade
					BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY,
										this->buttonSwitchOffColor2R, this->buttonSwitchOffColor2G, this->buttonSwitchOffColor2B,
										this->buttonSwitchOffColor2A);

					BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
										sizeX - this->buttonShadeDistance2, sizeY - this->buttonShadeDistance2,
										this->buttonEnabledColorR, this->buttonEnabledColorG, this->buttonEnabledColorB,
										this->buttonEnabledColorA);
				}
			}
		}
		else
		{
			//LOGD("--disabled");
			if (this->imageDisabled != NULL)
			{
				imageDisabled->Render(posX, posY, posZ, sizeX, sizeY);
			}
			else
			{
				//shade
				BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY,
									this->buttonDisabledColor2R, this->buttonDisabledColor2G, this->buttonDisabledColor2B,
									this->buttonDisabledColor2A);

				BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
									sizeX - this->buttonShadeDistance2, sizeY - this->buttonShadeDistance2,
									this->buttonDisabledColorR, this->buttonDisabledColorG, this->buttonDisabledColorB,
									this->buttonDisabledColorA);
			}
		}
		//LOGD("--------- DONE");

		this->RenderText(posX, posY);
	}
}

bool CGuiButtonSwitch::DoTap(GLfloat x, GLfloat y)
{
	return CGuiButton::DoTap(x, y);
}

bool CGuiButtonSwitch::DoFinishTap(GLfloat x, GLfloat y)
{
	return CGuiButton::DoFinishTap(x, y);
}

bool CGuiButtonSwitch::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	return CGuiButton::DoFinishDoubleTap(x, y);
}

bool CGuiButtonSwitch::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return CGuiButton::DoMove(x, y, distX, distY, diffX, diffY);
}

bool CGuiButtonSwitch::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return CGuiButton::FinishMove(x, y, distX, distY, accelerationX, accelerationY);
}

void CGuiButtonSwitch::FinishTouches()
{
	CGuiButton::FinishTouches();
}

void CGuiButtonSwitch::DoLogic()
{
	CGuiButton::DoLogic();
}

bool CGuiButtonSwitchCallback::ButtonSwitchChanged(CGuiButtonSwitch *button)
{
	return true;
}

