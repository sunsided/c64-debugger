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
									guiMain->theme->buttonSwitchOnColor2R, guiMain->theme->buttonSwitchOnColor2G, guiMain->theme->buttonSwitchOnColor2B,
									guiMain->theme->buttonSwitchOnColor2A);
				
				BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
									this->sizeX - guiMain->theme->buttonShadeDistance2, this->sizeY - guiMain->theme->buttonShadeDistance2,
									guiMain->theme->buttonSwitchOnColorR, guiMain->theme->buttonSwitchOnColorG, guiMain->theme->buttonSwitchOnColorB,
									guiMain->theme->buttonSwitchOnColorA);
			}
			else
			{
				BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
									guiMain->theme->buttonEnabledColor2R, guiMain->theme->buttonEnabledColor2G, guiMain->theme->buttonEnabledColor2B,
									guiMain->theme->buttonEnabledColor2A);
				
				BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
									this->sizeX - guiMain->theme->buttonShadeDistance2, this->sizeY - guiMain->theme->buttonShadeDistance2,
									guiMain->theme->buttonEnabledColorR, guiMain->theme->buttonEnabledColorG, guiMain->theme->buttonEnabledColorB,
									guiMain->theme->buttonEnabledColorA);
			}
		}
		else
		{
			BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
								guiMain->theme->buttonDisabledColor2R, guiMain->theme->buttonDisabledColor2G, guiMain->theme->buttonDisabledColor2B,
								guiMain->theme->buttonDisabledColor2A);
			
			BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
								this->sizeX - guiMain->theme->buttonShadeDistance2, this->sizeY - guiMain->theme->buttonShadeDistance2,
								guiMain->theme->buttonDisabledColorR, guiMain->theme->buttonDisabledColorG, guiMain->theme->buttonDisabledColorB,
								guiMain->theme->buttonDisabledColorA);			
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
										guiMain->theme->buttonSwitchOnColor2R, guiMain->theme->buttonSwitchOnColor2G, guiMain->theme->buttonSwitchOnColor2B,
										guiMain->theme->buttonSwitchOnColor2A);

					BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
										sizeX - guiMain->theme->buttonShadeDistance2, sizeY - guiMain->theme->buttonShadeDistance2,
										guiMain->theme->buttonSwitchOnColorR, guiMain->theme->buttonSwitchOnColorG, guiMain->theme->buttonSwitchOnColorB,
										guiMain->theme->buttonSwitchOnColorA);
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
										guiMain->theme->buttonSwitchOffColor2R, guiMain->theme->buttonSwitchOffColor2G, guiMain->theme->buttonSwitchOffColor2B,
										guiMain->theme->buttonSwitchOffColor2A);

					BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
										sizeX - guiMain->theme->buttonShadeDistance2, sizeY - guiMain->theme->buttonShadeDistance2,
										guiMain->theme->buttonEnabledColorR, guiMain->theme->buttonEnabledColorG, guiMain->theme->buttonEnabledColorB,
										guiMain->theme->buttonEnabledColorA);
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
									guiMain->theme->buttonDisabledColor2R, guiMain->theme->buttonDisabledColor2G, guiMain->theme->buttonDisabledColor2B,
									guiMain->theme->buttonDisabledColor2A);

				BlitFilledRectangle(posX + guiMain->theme->buttonShadeDistance, posY + guiMain->theme->buttonShadeDistance, posZ,
									sizeX - guiMain->theme->buttonShadeDistance2, sizeY - guiMain->theme->buttonShadeDistance2,
									guiMain->theme->buttonDisabledColorR, guiMain->theme->buttonDisabledColorG, guiMain->theme->buttonDisabledColorB,
									guiMain->theme->buttonDisabledColorA);
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

