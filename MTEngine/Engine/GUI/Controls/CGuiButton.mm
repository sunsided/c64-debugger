/*
 *  CGuiButton.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CGuiButton.h"
#include "VID_GLViewController.h"
#include "CGuiMain.h"
#include "CSlrString.h"

static float buttonZ = -2.0;

bool CGuiButtonCallback::ButtonClicked(CGuiButton *button)
{
	return true;
}

bool CGuiButtonCallback::ButtonPressed(CGuiButton *button)
{
	return true;
}

void CGuiButtonCallback::ButtonExpandedChanged(CGuiButton *button)
{
	return;
}


CGuiButton::CGuiButton(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback)
	: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiButton";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->image = image;
	this->imageDisabled = NULL;
	this->imageExpanded = NULL;
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->buttonPosX = posX;
	this->buttonPosY = posY;
	this->sizeX = DEFAULT_BUTTON_SIZE * sizeX;
	this->sizeY = DEFAULT_BUTTON_SIZE * sizeY;
	this->buttonSizeX = sizeX;
	this->buttonSizeY = sizeY;

	this->gapX = DEFAULT_BUTTON_GAPX;
	this->gapY = DEFAULT_BUTTON_GAPY;
	

	this->alignment = alignment;
	this->centerText = true;
	this->textOffsetY = 0.0f;
	this->beingClicked = false;
	this->clickConsumed = false;
	this->buttonZoom = DEFAULT_BUTTON_ZOOM;

	this->zoomable = true;
	this->zoomingLocked = false;
	this->zoomSpeed = DEFAULT_BUTTON_ZOOM_SPEED;

	this->enabled = true;
	this->text2 = NULL;
	this->textUTF = NULL;

	this->font = NULL;
	this->fontScale = 1.0f;
	this->textColorA = 1.0f;
	
	this->textDrawPosX = 0;
	this->textDrawPosY = 0;

	this->imageFlippedX = false;
	
	InitBackgroundColors();
}

CGuiButton::CGuiButton(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	//LOGD("CGuiButton::CGuiButton text=%s", text);
	this->name = "CGuiButton:Text";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->image = guiMain->theme->imgButtonBackgroundEnabled;
	this->imageDisabled = guiMain->theme->imgButtonBackgroundDisabled;
	this->imageExpanded = NULL;
	this->callback = callback;

	this->posX = posX;
	this->posY = posY;
	this->buttonPosX = posX;
	this->buttonPosY = posY;
	this->sizeX = DEFAULT_BUTTON_SIZE * sizeX;
	this->sizeY = DEFAULT_BUTTON_SIZE * sizeY;
	this->buttonSizeX = sizeX;
	this->buttonSizeY = sizeY;

	this->gapX = DEFAULT_BUTTON_GAPX;
	this->gapY = DEFAULT_BUTTON_GAPY;

	this->alignment = alignment;
	this->centerText = true;
	this->textOffsetY = 0.0f;
	this->beingClicked = false;
	this->clickConsumed = false;
	this->buttonZoom = DEFAULT_BUTTON_ZOOM;

	this->zoomable = true;
	this->zoomingLocked = false;
	this->zoomSpeed = DEFAULT_BUTTON_ZOOM_SPEED;

	this->enabled = true;

	this->font = NULL;
	this->fontScale = 1.0f;
	this->textColorA = 1.0f;
	
	this->textDrawPosX = 0;
	this->textDrawPosY = 0;
	
	this->imageFlippedX = false;
	this->textUTF = NULL;

	InitBackgroundColors();
	
	SetText(text);
}

CGuiButton::CGuiButton(CSlrImage *bkgImage, CSlrImage *bkgImageDisabled,
					   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   CSlrString *textUTF,
					   byte textAlignment, float textOffsetX, float textOffsetY,
					   CSlrFont *font, float fontScale,
					   float textColorR, float textColorG, float textColorB, float textColorA,
					   float textColorDisabledR, float textColorDisabledG, float textColorDisabledB, float textColorDisabledA,
					   CGuiButtonCallback *callback)
: CGuiElement(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiButton:Text";
	this->beingClicked = false;
	this->clickConsumed = false;
	
	this->image = bkgImage;
	this->imageDisabled = bkgImageDisabled;
	this->imageExpanded = NULL;
	this->callback = callback;
	
	this->posX = posX;
	this->posY = posY;
	this->buttonPosX = posX;
	this->buttonPosY = posY;
	this->sizeX = DEFAULT_BUTTON_SIZE * sizeX;
	this->sizeY = DEFAULT_BUTTON_SIZE * sizeY;
	this->buttonSizeX = sizeX;
	this->buttonSizeY = sizeY;
	
	this->gapX = DEFAULT_BUTTON_GAPX;
	this->gapY = DEFAULT_BUTTON_GAPY;
	
	this->alignment = BUTTON_ALIGNED_CENTER;
	this->centerText = true;
	this->textOffsetY = 0.0f;
	this->beingClicked = false;
	this->clickConsumed = false;
	this->buttonZoom = 1.0f;
	
	this->zoomable = false;
	this->zoomingLocked = false;
	this->zoomSpeed = DEFAULT_BUTTON_ZOOM_SPEED;
	
	this->enabled = true;
	
	this->font = font;
	this->fontScale = fontScale;
	
	this->textColorR = textColorR;
	this->textColorG = textColorG;
	this->textColorB = textColorB;
	this->textColorA = textColorA;

	this->textColorDisabledR = textColorDisabledR;
	this->textColorDisabledG = textColorDisabledG;
	this->textColorDisabledB = textColorDisabledB;
	this->textColorDisabledA = textColorDisabledA;
	
	this->textUTF = new CSlrString(textUTF);
	this->textAlignment = textAlignment;
	this->textDrawPosX = textOffsetX;
	this->textDrawPosY = textOffsetY;
	
	this->imageFlippedX = false;
	
	InitBackgroundColors();
}

void CGuiButton::SetText(CSlrString *textUTF)
{
	if (this->textUTF != NULL)
		delete this->textUTF;
	this->textUTF = new CSlrString(textUTF);
}

void CGuiButton::InitBackgroundColors()
{
	buttonShadeAmount = guiMain->theme->buttonShadeAmount;
	buttonShadeDistance = guiMain->theme->buttonShadeDistance;
	buttonShadeDistance2 = guiMain->theme->buttonShadeDistance2;
	
	buttonEnabledColorR = guiMain->theme->buttonEnabledColorR;
	buttonEnabledColorG = guiMain->theme->buttonEnabledColorG;
	buttonEnabledColorB = guiMain->theme->buttonEnabledColorB;
	buttonEnabledColorA = guiMain->theme->buttonEnabledColorA;
	buttonEnabledColor2R = guiMain->theme->buttonEnabledColor2R;
	buttonEnabledColor2G = guiMain->theme->buttonEnabledColor2G;
	buttonEnabledColor2B = guiMain->theme->buttonEnabledColor2B;
	buttonEnabledColor2A = guiMain->theme->buttonEnabledColor2A;
	
	buttonDisabledColorR = guiMain->theme->buttonDisabledColorR;
	buttonDisabledColorG = guiMain->theme->buttonDisabledColorG;
	buttonDisabledColorB = guiMain->theme->buttonDisabledColorB;
	buttonDisabledColorA = guiMain->theme->buttonDisabledColorA;
	buttonDisabledColor2R = guiMain->theme->buttonDisabledColor2R;
	buttonDisabledColor2G = guiMain->theme->buttonDisabledColor2G;
	buttonDisabledColor2B = guiMain->theme->buttonDisabledColor2B;
	buttonDisabledColor2A = guiMain->theme->buttonDisabledColor2A;

	textColorR = guiMain->theme->buttonOffTextColorR;
	textColorG = guiMain->theme->buttonOffTextColorG;
	textColorB = guiMain->theme->buttonOffTextColorB;
	
	textColorDisabledR = guiMain->theme->buttonDisabledTextColorR;
	textColorDisabledG = guiMain->theme->buttonDisabledTextColorG;
	textColorDisabledB = guiMain->theme->buttonDisabledTextColorB;

}

void CGuiButton::UpdateTheme()
{
	InitBackgroundColors();
}

void CGuiButton::SetFont(CSlrFont *font, float fontScale)
{
	this->font = font;
	this->fontScale = fontScale;
	
	this->RecalcTextPosition();
}

void CGuiButton::SetEnabled(bool enabled)
{
	this->enabled = enabled;
}

void CGuiButton::InitWithText(char *text)
{
	this->image = guiMain->theme->imgButtonBackgroundEnabled;
	SetText(text);
}

void CGuiButton::SetText(char *text)
{
	if (text == NULL)
	{
		LOGError("CGuiButton::SetText: NULL text");
		this->text2 = NULL;
		return;
	}
	this->beingClicked = false;
	this->clickConsumed = false;

	int len = strlen(text);
	this->text2 = new char[len+1];
	strcpy(this->text2, text);
	
	len++;
	fontWidth = sizeX / len;
	fontHeight = sizeY * 0.8;

	this->zoomable = false;
	
	this->RecalcTextPosition();
}

void CGuiButton::RecalcTextPosition()
{
	if (this->text2 != NULL)
	{
		if (this->font != NULL)
		{
			float width, height;
			this->font->GetTextSize(this->text2, this->fontScale, &width, &height);
			
			if (centerText)
			{
				textDrawPosX = (sizeX / 2.0f) - (width / 2.0f);
			}
			else
			{
				textDrawPosX = 0.0f;
			}
			
			textDrawPosY = (sizeY / 2.0f) - (height / 2.0f) + textOffsetY;
		}
		else
		{
			if (guiMain->fntEngineDefault != NULL)
			{
				float width, height;
				guiMain->fntEngineDefault->GetTextSize(this->text2, this->fontScale, &width, &height);
				
				textDrawPosX = (sizeX / 2.0f) - (width / 2.0f);
				textDrawPosY = (sizeY / 2.0f) - (height / 2.0f);							
			}
			else
			{
				this->textDrawPosX = 0.0f;
				this->textDrawPosY = 0.0f;						
			}
		}
	}
	else
	{
		this->textDrawPosX = 0.0f;
		this->textDrawPosY = 0.0f;		
	}
}

void CGuiButton::Render()
{
	this->Render(this->posX, this->posY);
}

void CGuiButton::RenderText(GLfloat posX, GLfloat posY)
{
	if (this->text2 != NULL)
	{
		if (this->font == NULL)
		{
			if (guiMain->fntEngineDefault == NULL)
			{
				//BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha)
				guiMain->fntConsole->BlitText(this->text2,
										  posX + fontWidth/2, posY + sizeY*0.1, -1.0,
										  fontWidth, fontHeight, 1.0);
			}
			else 
			{
				guiMain->fntEngineDefault->BlitText(this->text2, posX + textDrawPosX, posY + textDrawPosY, posZ, fontScale, textColorA);
			}
		}
		else 
		{
			this->font->BlitText(this->text2, posX + textDrawPosX, posY + textDrawPosY, -1, fontScale, textColorA);
		}
	}
}

void CGuiButton::RenderUTFButton(GLfloat posX, GLfloat posY)
{
	CSlrImage *rimg = this->image;
	if (this->enabled == false)
	{
		if (this->imageDisabled != NULL)
		{
			rimg = imageDisabled;
		}
	}

	if (rimg != NULL)
	{
		rimg->Render(posX, posY, posZ, sizeX, sizeY);
	}
	else
	{
		if (this->enabled)
		{
				BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
									this->buttonEnabledColor2R, this->buttonEnabledColor2G, this->buttonEnabledColor2B,
									this->buttonEnabledColor2A);
				
				BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
									this->sizeX - this->buttonShadeDistance2, this->sizeY - this->buttonShadeDistance2,
									this->buttonEnabledColorR, this->buttonEnabledColorG, this->buttonEnabledColorB,
									this->buttonEnabledColorA);
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
		this->font->BlitTextColor(textUTF, posX + textDrawPosX, posY + textDrawPosY, posZ,
								  fontScale,
								  textColorR, textColorG, textColorB, textColorA,
								  textAlignment);
	}
	else
	{
		this->font->BlitTextColor(textUTF, posX + textDrawPosX, posY + textDrawPosY, posZ,
								  fontScale,
								  textColorDisabledR, textColorDisabledG, textColorDisabledB, textColorDisabledA,
								  textAlignment);
	}
}



void CGuiButton::Render(GLfloat posX, GLfloat posY)
{
	if (this->visible)
	{
		if (this->textUTF != NULL)
		{
			RenderUTFButton(posX, posY);
			return;
		}
		
		if (this->enabled)
		{
			if (this->image != NULL)
			{
				if (this->imageExpanded == NULL)
				{
					if (!imageFlippedX)
					{
						image->Render(posX, posY, buttonZ, this->sizeX, this->sizeY);
					}
					else
					{
						image->RenderFlipHorizontal(posX, posY, buttonZ, this->sizeX, this->sizeY);
					}
				}
				else
				{
					if (!this->isExpanded)
					{
						if (!imageFlippedX)
						{
							image->Render(posX, posY, buttonZ, this->sizeX, this->sizeY);
						}
						else
						{
							image->RenderFlipHorizontal(posX, posY, buttonZ, this->sizeX, this->sizeY);
						}
					}
					else
					{
						if (!imageFlippedX)
						{
							imageExpanded->Render(posX, posY, buttonZ, this->sizeX, this->sizeY);
						}
						else
						{
							imageExpanded->RenderFlipHorizontal(posX, posY, buttonZ, this->sizeX, this->sizeY);
						}
					}

				}
			}
			else
			{
				//shade
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
			if (this->imageDisabled != NULL)
			{
				if (!imageFlippedX)
				{
					imageDisabled->Render(posX, posY, buttonZ, this->sizeX, this->sizeY);
				}
				else
				{
					imageDisabled->RenderFlipHorizontal(posX, posY, buttonZ, this->sizeX, this->sizeY);
				}
			}
			else
			{
				//shade
				BlitFilledRectangle(posX, posY, posZ, this->sizeX, this->sizeY,
						this->buttonDisabledColor2R, this->buttonDisabledColor2G, this->buttonDisabledColor2B,
						this->buttonDisabledColor2A);

				BlitFilledRectangle(posX + this->buttonShadeDistance, posY + this->buttonShadeDistance, posZ,
									this->sizeX - this->buttonShadeDistance2, this->sizeY - this->buttonShadeDistance2,
									this->buttonDisabledColorR, this->buttonDisabledColorG, this->buttonDisabledColorB,
									this->buttonDisabledColorA);
			}
		}

		this->RenderText(posX, posY);
	}

//
//	if (this->visible)
//	{
//		if (this->image != NULL)
//		{
//			if (!imageFlippedX)
//			{
//				image->Render(posX, posY, buttonZ, this->sizeX, this->sizeY);
//			}
//			else
//			{
//				image->RenderFlipHorizontal(posX, posY, buttonZ, this->sizeX, this->sizeY);
//			}
//		}
//
//		if (this->text != NULL)
//		{
//			//BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha)
//			guiMain->fntConsole->BlitText(this->text,
//										  posX + fontWidth/2, posY + sizeY*0.1, -1.0,
//										  fontWidth, fontHeight, 1.0);
//		}
//	}
}

// @returns is consumed
bool CGuiButton::DoTap(GLfloat posX, GLfloat posY)
{
	//LOGD("CGuiButton::DoTap");
	if (!this->visible)
		return false;

	this->wasExpanded = this->isExpanded;
	
	beingClicked = false;
	if (IsInside(posX, posY))
	{
		if (!this->enabled)
			return true;

		beingClicked = true;
		clickConsumed = this->Clicked(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->ButtonClicked(this);
		}
		return true; //clickConsumed;
	}

	clickConsumed = false;
	return false;
}

bool CGuiButton::DoFinishTap(GLfloat posX, GLfloat posY)
{
	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		if (!this->enabled)
			return true;

		beingClicked = false;
		pressConsumed = this->Pressed(posX, posY);
		if (!pressConsumed && callback != NULL)
		{
			pressConsumed = callback->ButtonPressed(this);
		}
		return pressConsumed;
	}

	return false;
}

void CGuiButton::ReleaseClick()
{
	beingClicked = false;
}

// @returns is consumed
bool CGuiButton::DoDoubleTap(GLfloat posX, GLfloat posY)
{
	if (!this->visible)
		return false;

	if (beingClicked == false)
	{
		if (!this->enabled)
			return true;

		beingClicked = false;
		if (IsInside(posX, posY))
		{
			beingClicked = true;
			clickConsumed = this->Clicked(posX, posY);
			if (!clickConsumed && callback != NULL)
			{
				clickConsumed = callback->ButtonClicked(this);
			}
			return clickConsumed;
		}
	}
	clickConsumed = false;
	return false;
}

bool CGuiButton::DoFinishDoubleTap(GLfloat posX, GLfloat posY)
{
	if (!this->visible)
		return false;

	beingClicked = false;
	if (IsInside(posX, posY))
	{
		if (!this->enabled)
			return true;

		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->ButtonPressed(this);
		}
		return clickConsumed;
	}

	return false;
}

bool CGuiButton::Clicked(GLfloat posX, GLfloat posY)
{
	LOGG("CGuiButton::Clicked: %f %f", posX, posY);
	return false;
}

bool CGuiButton::Pressed(GLfloat posX, GLfloat posY)
{
	LOGG("CGuiButton::Pressed: %f %f", posX, posY);
	return false;
}

bool CGuiButton::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (!this->visible)
		return false;

	//LOGG("CGuiButton::DoMove: %f %f", x, y);
	clickConsumed = false;
	if (IsInside(x, y))
	{
		if (!this->enabled)
			return true;

		//LOGD("IsInside");
		beingClicked = true;
		return true; //this->Pressed(posX, posY);
	}
	else
	{
		beingClicked = false;
	}

	return false;
}

bool CGuiButton::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (!this->visible)
		return false;

	LOGG("CGuiButton::FinishMove: %f %f", x, y);
	if (IsInside(x, y))
	{
		if (!this->enabled)
			return true;

		beingClicked = false;
		clickConsumed = this->Pressed(posX, posY);
		if (!clickConsumed && callback != NULL)
		{
			clickConsumed = callback->ButtonPressed(this);
		}
		return clickConsumed;
	}

	beingClicked = false;

	return false;
}

void CGuiButton::FinishTouches()
{
	beingClicked = false;
}

void CGuiButton::DoLogic()
{
	if (!this->visible)
		return;

	if (zoomable == true && (zoomingLocked || beingClicked == true))
	{
		//LOGG("CGuiButton::DoLogic clicked=TRUE");
		if (sizeX < buttonSizeX*buttonZoom)
		{
			sizeX += this->zoomSpeed;
			sizeY += this->zoomSpeed;

			if (IS_SET(alignment, BUTTON_ALIGNED_RIGHT))
			{
				posX -= this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_LEFT))
			{
			}
			else
			{
				posX -= this->zoomSpeed/2;
			}


			if (IS_SET(alignment, BUTTON_ALIGNED_DOWN))
			{
				posY -= this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_UP))
			{
				//
			}
			else
			{
				posY -= this->zoomSpeed/2;
			}
		}
	}
	else
	{
		if (sizeX > buttonSizeX) // || sizeY > buttonSizeY)
		{
			sizeX -= this->zoomSpeed;
			sizeY -= this->zoomSpeed;
			if (IS_SET(alignment, BUTTON_ALIGNED_RIGHT))
			{
				posX += this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_LEFT))
			{
				//
			}
			else
			{
				posX += this->zoomSpeed/2;
			}

			if (IS_SET(alignment, BUTTON_ALIGNED_DOWN))
			{
				posY += this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_UP))
			{
				//
			}
			else
			{
				posY += this->zoomSpeed/2;
			}

			if (sizeX <= buttonSizeX || sizeY <= buttonSizeY)
			{
				CGuiElement::SetPosition(buttonPosX, buttonPosY, this->posZ, buttonSizeX, buttonSizeY);
			}
		}
	}
}

bool CGuiButton::DoExpandZoom()
{
	if (zoomable == true && (zoomingLocked || beingClicked == true))
	{
		//LOGG("CGuiButton::DoLogic clicked=TRUE");
		if (sizeX < buttonSizeX*buttonZoom)
		{
			sizeX += this->zoomSpeed;
			sizeY += this->zoomSpeed;

			if (IS_SET(alignment, BUTTON_ALIGNED_RIGHT))
			{
				posX -= this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_LEFT))
			{
			}
			else
			{
				posX -= this->zoomSpeed/2;
			}


			if (IS_SET(alignment, BUTTON_ALIGNED_DOWN))
			{
				posY -= this->zoomSpeed;
			}
			else if (IS_SET(alignment, BUTTON_ALIGNED_UP))
			{
				//
			}
			else
			{
				posY -= this->zoomSpeed/2;
			}
			return false;
		}
	}
	return true;
}

bool CGuiButton::IsZoomed()
{
	if (sizeX != buttonSizeX)
		return true;

	return false;
}

bool CGuiButton::IsZoomingOut()
{
	if (zoomable == true && (zoomingLocked || beingClicked == true))
		return false;

	if (sizeX > buttonSizeX)
	{
		return true;
	}

	return false;
}

void CGuiButton::SetFontScale(float fontScale)
{
	this->fontScale = fontScale;
	this->RecalcTextPosition();
}

