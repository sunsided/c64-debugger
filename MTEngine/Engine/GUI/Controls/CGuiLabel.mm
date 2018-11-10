/*
 *  CGuiLabel.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#define DEFAULT_LABEL_ZOOM 1.0

#include "CGuiLabel.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"
#include "CSlrFont.h"

bool CGuiLabelCallback::LabelClicked(CGuiLabel *button)
{
	return true;
}

bool CGuiLabelCallback::LabelPressed(CGuiLabel *button)
{
	return true;
}


CGuiLabel::CGuiLabel(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiLabel";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->transparentToTaps = false;

	this->image = image;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->sizeX = DEFAULT_LABEL_ZOOM * sizeX;
	this->sizeY = DEFAULT_LABEL_ZOOM * sizeY;
	this->alignment = alignment;
//	this->buttonZoom = DEFAULT_BUTTON_ZOOM;
//	this->zoomable = true;

	this->font = NULL;

	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;

	fontWidth = 11.0;
	fontHeight = 11.0;
}

CGuiLabel::CGuiLabel(char *text, bool stretched, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, GLfloat fontWidth, GLfloat fontHeight, CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiLabel:Text";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->transparentToTaps = false;

	this->image = guiMain->theme->imgBackgroundLabel;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->sizeX = DEFAULT_LABEL_ZOOM * sizeX;
	this->sizeY = DEFAULT_LABEL_ZOOM * sizeY;
	this->alignment = alignment;
//	this->buttonZoom = DEFAULT_BUTTON_ZOOM;
//	this->zoomable = true;

	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;

	this->font = NULL;
	this->fontWidth = fontWidth;
	this->fontHeight = fontHeight;

	SetText(text, stretched);
}

CGuiLabel::CGuiLabel(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, CSlrFont *font, float fontSize, CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiLabel:Text";
	this->beingClicked = false;
	this->clickConsumed = false;
	
	this->transparentToTaps = false;
	
	this->image = NULL; //guiMain->theme->imgBackgroundLabel;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;
	
	this->posX = posX;
	this->posY = posY;
	this->sizeX = DEFAULT_LABEL_ZOOM * sizeX;
	this->sizeY = DEFAULT_LABEL_ZOOM * sizeY;
	this->alignment = LABEL_ALIGNED_LEFT;
	//	this->buttonZoom = DEFAULT_BUTTON_ZOOM;
	//	this->zoomable = true;
	
	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;
	
	this->font = font;
	this->fontSize = fontSize;
	this->fontWidth = fontSize;
	this->fontHeight = fontSize;
	
	CSlrString *textUTF = new CSlrString(text);
	SetText(textUTF);
	delete textUTF;
}

CGuiLabel::CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, GLfloat fontSize, CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, 1.0f, 1.0f)
{
	this->name = "CGuiLabel:Text";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->transparentToTaps = false;

	this->image = guiMain->theme->imgBackgroundLabel;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->alignment = alignment;

	textColorR = 1.0f;
	textColorG = 1.0f;
	textColorB = 1.0f;
	textColorA = 1.0f;

	this->font = font;
	this->fontSize = fontSize;
	this->fontWidth = fontSize;
	this->fontHeight = fontSize;

	SetText(textUTF);
	
	this->sizeY = font->GetLineHeight();

}

CGuiLabel::CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, GLfloat fontSize, float colorR, float colorG, float colorB, float alpha, CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, 1.0f, 1.0f)
{
	this->name = "CGuiLabel:Text";
	this->beingClicked = false;
	this->clickConsumed = false;
	
	this->transparentToTaps = false;
	
	this->image = guiMain->theme->imgBackgroundLabel;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;
	
	this->posX = posX;
	this->posY = posY;
	this->alignment = alignment;
	
	textColorR = colorR;
	textColorG = colorG;
	textColorB = colorB;
	textColorA = alpha;
	
	this->font = font;
	this->fontSize = fontSize;
	this->fontWidth = fontSize;
	this->fontHeight = fontSize;
	
	SetText(textUTF);
	
	this->sizeY = font->GetLineHeight();
}

CGuiLabel::CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, GLfloat fontScale,
					 float bkgColorR, float bkgColorG, float bkgColorB, float bkgColorA,
					 float textColorR, float textColorG, float textColorB, float textColorA,
					 float textOffsetX, float textOffsetY,
					 CGuiLabelCallback *callback)
: CGuiElement(posX, posY, posZ, 1.0f, 1.0f)
{
	this->name = "CGuiLabel:Text";
	this->beingClicked = false;
	this->clickConsumed = false;
	
	this->transparentToTaps = false;
	
	this->image = guiMain->theme->imgBackgroundLabel;
	this->text = NULL;
	this->textUTF = NULL;
	this->callback = callback;
	
	this->posX = posX;
	this->posY = posY;
	this->alignment = alignment;
	
	this->bkgColorR = bkgColorR;
	this->bkgColorG = bkgColorG;
	this->bkgColorB = bkgColorB;
	this->bkgColorA = bkgColorA;
	
	this->textColorR = textColorR;
	this->textColorG = textColorG;
	this->textColorB = textColorB;
	this->textColorA = textColorA;
	
	this->font = font;
	this->fontSize = fontScale;
	this->fontWidth = fontScale;
	this->fontHeight = fontScale;
	
	SetText(textUTF);
	
	this->sizeX = sizeX;
	this->sizeY = sizeY;

	//LOGD("(font->GetLineHeight() * fontScale) = %f", (font->GetLineHeight() * fontScale));
	
	textPosX = 0.0f;
	textPosY = 0.0f;
	
	if (alignment == LABEL_ALIGNED_CENTER)
	{
		float tw = 0.0f;
		float th = 0.0f;
		font->GetTextSize(textUTF, fontScale, &tw, &th);
		
		textPosX = (sizeX - tw)/2.0f;
		textPosY = 0.0f;
	}
	else if (alignment == LABEL_ALIGNED_RIGHT)
	{
		float tw = 0.0f;
		float th = 0.0f;
		font->GetTextSize(textUTF, fontScale, &tw, &th);
		
		textPosX = (sizeX - tw);
		textPosY = 0.0f;
	}
	
	textPosX += textOffsetX;
	textPosY += textOffsetY;
}

void CGuiLabel::InitWithText(char *text, bool stretched)
{
	this->image = guiMain->theme->imgBackgroundLabel;
	SetText(text, stretched);
}

void CGuiLabel::SetText(char *text, bool stretched)
{
	this->beingClicked = false;
	this->clickConsumed = false;

	if (this->text != NULL)
	{
		STRFREE(this->text);
	}

	this->text = STRALLOC(text);

	this->UpdateTextSize(stretched);

//	this->zoomable = false;
}

void CGuiLabel::InitWithText(CSlrString *textUTF)
{
	this->image = guiMain->theme->imgBackgroundLabel;
	SetText(textUTF);
}

void CGuiLabel::SetText(CSlrString *textUTF)
{
	//LOGD("CGuiLabel::SetText:");
//	if (textUTF != NULL)
//		textUTF->DebugPrint("textUTF=");

	this->beingClicked = false;
	this->clickConsumed = false;

	if (this->textUTF != NULL)
		delete this->textUTF;
	this->textUTF = NULL;

	if (textUTF != NULL)
	{
		this->textUTF = new CSlrString(textUTF);

		this->sizeX = this->font->GetTextWidth(textUTF, this->fontSize);
	}

	textPosX = 0.0f;
	textPosY = 0.0f;

//	this->zoomable = false;
}

void CGuiLabel::UpdateTextSize(bool stretched)
{
	if (this->text == NULL)
		return;

	int len = strlen(text);

	len++;

	if (stretched)
	{
		fontWidth = sizeX / len;
		fontHeight = sizeY * 0.8;
	}
	else
	{
		sizeX = guiMain->fntConsole->GetTextWidth(text, fontWidth);
		if (alignment == LABEL_ALIGNED_CENTER)
			sizeX += fontWidth;

		sizeY = fontHeight * 1.25;
	}

	if (alignment == LABEL_ALIGNED_CENTER)
	{
		textPosX = fontWidth/2;
		textPosY = sizeY*0.1;
	}
	else if (alignment == LABEL_ALIGNED_LEFT)
	{
		textPosX = 0.0f;
		textPosY = sizeY*0.1;
	}
	else
	{
		LOGTODO("CGuiLabel::UpdateTextSize: alignment=%d", alignment);
		textPosX = 0.0f;
	}

}

void CGuiLabel::SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
	CGuiElement::SetPosition(posX, posY, posZ, sizeX, sizeY);
	this->UpdateTextSize(true);
}


void CGuiLabel::Render()
{
	this->Render(this->posX, this->posY);
}

void CGuiLabel::Render(GLfloat posX, GLfloat posY)
{
	if (this->visible)
	{
		if (this->image != NULL)
		{
			//LOGD("CGuiLabel::Render: %s posX=%f posY=%f sizeX=%f sizeY=%f", name, posX, posY, sizeX, sizeY);
			image->Render(posX, posY, posZ, this->sizeX, this->sizeY);
		}

		if (this->text != NULL)
		{
			//LOGD("CGuiLabel::BlitText: '%s' %f %f %f %f", this->text, this->textPosX, this->textPosY, fontWidth, fontHeight);

			//BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha)
			guiMain->fntConsole->BlitText(this->text,
										  posX + textPosX, posY + textPosY, -1.0,
										  fontWidth, fontHeight, 1.0);
		}

		if (this->textUTF != NULL)
		{
			//this->textUTF->DebugPrint("textUTF=");
			this->font->BlitTextColor(this->textUTF, posX + textPosX, posY + textPosY, posZ, this->fontSize, textColorR, textColorG, textColorB, textColorA);
		}
	}
}

// @returns is consumed
bool CGuiLabel::DoTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = true;
		clickConsumed = this->Clicked(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->LabelClicked(this);
		}
		return clickConsumed;
	}

	clickConsumed = false;
	return false;
}

bool CGuiLabel::DoFinishTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->LabelPressed(this);
		}
		return clickConsumed;
	}

	return false;
}

// @returns is consumed
bool CGuiLabel::DoDoubleTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	if (beingClicked == false)
	{
		beingClicked = false;
		if (IsInside(posX, posY))
		{
			beingClicked = true;
			clickConsumed = this->Clicked(posX, posY);
			if (!clickConsumed && callback != NULL)
			{
				clickConsumed = callback->LabelClicked(this);
			}
			return clickConsumed;
		}
	}
	clickConsumed = false;
	return false;
}

bool CGuiLabel::DoFinishDoubleTap(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->LabelPressed(this);
		}
		return clickConsumed;
	}

	return false;
}

bool CGuiLabel::Clicked(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	LOGG("CGuiLabel::Clicked: %f %f", posX, posY);
	return false;
}

bool CGuiLabel::Pressed(GLfloat posX, GLfloat posY)
{
	if (this->transparentToTaps)
		return false;

	LOGG("CGuiLabel::Pressed: %f %f", posX, posY);
	return false;
}

bool CGuiLabel::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	LOGG("CGuiLabel::DoMove: %f %f", x, y);
	clickConsumed = false;
	if (IsInside(x, y))
	{
		beingClicked = true;
		return true; //this->Pressed(posX, posY);
	}
	else
	{
		beingClicked = false;
	}

	return false;
}

bool CGuiLabel::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (this->transparentToTaps)
		return false;

	if (!this->visible)
		return false;

	LOGG("CGuiLabel::FinishMove: %f %f", x, y);
	if (IsInside(x, y))
	{
		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		return clickConsumed;
	}

	beingClicked = false;

	return false;
}

void CGuiLabel::FinishTouches()
{
	if (this->transparentToTaps)
		return;

	beingClicked = false;
}

void CGuiLabel::DoLogic()
{
	if (!this->visible)
		return;

	/*
	if (zoomable == true && beingClicked == true)
	{
		//LOGG("CGuiButton::DoLogic clicked=TRUE");
		if (sizeX < buttonSizeX*buttonZoom)
		{
			sizeX += buttonZoomSpeed;
			sizeY += buttonZoomSpeed;

			if (IS_SET(alignment, BUTTON_ALIGNED_RIGHT))
			{
				posX -= buttonZoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_LEFT))
			{
			}
			else
			{
				posX -= buttonZoomSpeed/2;
			}


			if (IS_SET(alignment, BUTTON_ALIGNED_DOWN))
			{
				posY -= buttonZoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_UP))
			{
				//
			}
			else
			{
				posY -= buttonZoomSpeed/2;
			}
		}
	}
	else
	{
		if (sizeX > buttonSizeX)
		{
			sizeX -= buttonZoomSpeed;
			sizeY -= buttonZoomSpeed;
			if (IS_SET(alignment, BUTTON_ALIGNED_RIGHT))
			{
				posX += buttonZoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_LEFT))
			{
				//
			}
			else
			{
				posX += buttonZoomSpeed/2;
			}

			if (IS_SET(alignment, BUTTON_ALIGNED_DOWN))
			{
				posY += buttonZoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_UP))
			{
				//
			}
			else
			{
				posY += buttonZoomSpeed/2;
			}
		}

	}
	*/
}


