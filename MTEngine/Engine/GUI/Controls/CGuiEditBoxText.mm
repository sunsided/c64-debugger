
/*
 *  CGuiEditBoxText.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "GuiConsts.h"
#include "CGuiEditBoxText.h"
#include "SYS_Main.h"
#include "CGuiMain.h"
#include "SYS_KeyCodes.h"

void CGuiEditBoxTextCallback::EditBoxTextValueChanged(CGuiEditBoxText *editBox, char *text)
{
}

void CGuiEditBoxTextCallback::EditBoxTextFinished(CGuiEditBoxText *editBox, char *text)
{
}

CGuiEditBoxText::CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ,
								 GLfloat fontWidth, GLfloat fontHeight,
								 char *defaultText, u16 maxNumChars, bool readOnly,
								 CGuiEditBoxTextCallback *callback)
:CGuiView(posX, posY, posZ, 50, 50)
{
	this->fontWidth = fontWidth;
	this->fontHeight = fontHeight;

	this->SetSize((fontWidth*(GLfloat)maxNumChars*gapX), (fontHeight*gapY));
	this->SetPosition(posX, posY, posZ, fontWidth*numChars, fontHeight);

	this->Initialize(defaultText, maxNumChars, readOnly, callback);

	textBuffer[0] = '\0';
}

CGuiEditBoxText::CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ,
								 GLfloat sizeX, GLfloat sizeY,
								 char *defaultText, u16 maxNumChars,
								 CSlrFont *textFont, float fontScale, bool readOnly, CGuiEditBoxTextCallback *callback)
:CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->Initialize(defaultText, maxNumChars, readOnly, callback);

	this->font = textFont;
	this->fontScale = fontScale;

	fontWidth = sizeX / (float)maxNumChars;
	fontHeight = sizeY;

	this->SetSize(sizeX, sizeY);
	this->SetPosition(posX, posY, posZ, sizeX, sizeY);

	// TODO: BUG: move with Initialize and fontWidth
	this->SetText(defaultText);
}

CGuiEditBoxText::CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ,
								 GLfloat sizeX,
								 char *defaultText, u16 maxNumChars,
								 CSlrFont *textFont, float fontScale, bool readOnly, CGuiEditBoxTextCallback *callback)
:CGuiView(posX, posY, posZ, sizeX, 0.0f)
{
	this->Initialize(defaultText, maxNumChars, readOnly, callback);

	this->font = textFont;
	this->fontScale = fontScale;

	cursorGapY = 0;

	float sx = font->GetCharWidth('X', fontScale);

	fontWidth = sx; //sizeX / (float)maxNumChars;
	
	float sy = font->GetCharHeight('X', fontScale);
	fontHeight = sy + gapY*2.0f;

	cursorWidth = fontWidth;
	cursorHeight = fontHeight;

	this->SetSize(sizeX, sy);
	this->SetPosition(posX, posY, posZ, sizeX, sy);

	// TODO: BUG: move with Initialize and fontWidth
	this->SetText(defaultText);
}

void CGuiEditBoxText::Initialize(char *defaultText, u16 maxNumChars, bool readOnly,
								 CGuiEditBoxTextCallback *callback)
{
	this->name = "CGuiEditBoxText";

	this->type = TEXTBOX_TYPE_TEXT;

	this->forceCapitals = false;

	this->enabled = true;
	this->gapX = 1.1f;
	this->gapY = 1.1f;
	this->gapX2 = (1.0f - this->gapX)/2;
	this->gapY2 = (1.0f - this->gapY)/2;

	this->textOffsetY = 0.0f;

	this->font = NULL;
	this->fontScale = 1.0f;
	this->fontAlpha = 1.0f;

	this->currentPos = 0;
	this->maxNumChars = maxNumChars;
	this->textBuffer = new char[maxNumChars+5];

	this->SetText(defaultText);

	this->readOnly = readOnly;
	this->editing = false;

	this->callback = callback;

	this->alpha = 1.0;

	this->cursorAlpha = 1.0;
	this->cursorAlphaSpeed = guiMain->theme->textBoxCursorBlinkSpeed;

	this->colorR = guiMain->theme->textBoxColorR;
	this->colorG = guiMain->theme->textBoxColorG;
	this->colorB = guiMain->theme->textBoxColorB;
	this->colorA = guiMain->theme->textBoxColorA;
	this->color2R = guiMain->theme->textBoxColor2R;
	this->color2G = guiMain->theme->textBoxColor2G;
	this->color2B = guiMain->theme->textBoxColor2B;
	this->color2A = guiMain->theme->textBoxColor2A;
	this->cursorColorR = guiMain->theme->cursorColorR;
	this->cursorColorG = guiMain->theme->cursorColorG;
	this->cursorColorB = guiMain->theme->cursorColorB;
	this->cursorColorA = guiMain->theme->cursorColorA;
}

void CGuiEditBoxText::SetFont(CSlrFont *font, float fontScale)
{
	this->font = font;
	this->fontScale = fontScale;

	cursorGapY = 0;
	
	fontWidth = sizeX / (float)maxNumChars;

	float sy = font->GetCharHeight('X', fontScale);
	fontHeight = sy;
	
	cursorWidth = fontWidth;
	cursorHeight = fontHeight;
}

bool CGuiEditBoxText::DoTap(GLfloat x, GLfloat y)
{
	LOGG("CGuiEditBoxText::DoTap: x=%f y=%f posX=%f posY=%f sizeX=%f sizeY=%f",
		 x, y, posX, posY, sizeX, sizeY);

	if (IsInside(x, y))
	{
		LOGD("INSIDE");
		if (this->enabled == false)
			return true;
		guiMain->SetFocus(this);
		return true;
	}
	return false;
}

bool CGuiEditBoxText::DoFinishTap(GLfloat x, GLfloat y)
{
	return false;
}

bool CGuiEditBoxText::DoDoubleTap(GLfloat x, GLfloat y)
{
	return false;
}

bool CGuiEditBoxText::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	return false;
}

bool CGuiEditBoxText::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	return false;
}

bool CGuiEditBoxText::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	return false;
}

bool CGuiEditBoxText::InitZoom()
{
	return false;
}

bool CGuiEditBoxText::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	return false;
}

void CGuiEditBoxText::FinishTouches()
{
}

void CGuiEditBoxText::DoLogic()
{
	//LOGD("DoLogic: this->editing=%d", this->editing);
	if (this->enabled == false)
		return;

	if (this->editing == true)
	{
		//LOGD("editing=true");
		cursorAlpha -= cursorAlphaSpeed;
		if (cursorAlpha < 0.3f)
		{
			cursorAlpha = 0.3f;
			cursorAlphaSpeed = -cursorAlphaSpeed;
		}
		else if (cursorAlpha > 1.0f)
		{
			cursorAlpha = 1.0;
			cursorAlphaSpeed = -cursorAlphaSpeed;
		}
		CGuiView::DoLogic();
	}
	//LOGD("cursorAlpha=%f", cursorAlpha);
}

void CGuiEditBoxText::Render()
{
	this->Render(this->posX, this->posY);
}

void CGuiEditBoxText::Render(GLfloat posX, GLfloat posY)
{
	if (!this->visible)
		return;

	//LOGD("Render: this->editing=%d", this->editing);
	//LOGD("sizeX=%f sizeY=%f", sizeX, sizeY);

	BlitRectangle(posX, posY, posZ, sizeX, sizeY,
				  color2R, color2G, color2B, color2A);

	if (this->enabled == false)
	{
		BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY,
						colorR, colorR, colorR, colorA);
	}
	else
	{
		BlitFilledRectangle(posX, posY, posZ, sizeX, sizeY,
						colorR, colorG, colorB, colorA);

		if (this->editing == true)
		{
			// cursor
			if (this->font != NULL)
			{
				float w = font->GetTextWidth(textBuffer, fontScale);
				BlitFilledRectangle(posX + w, posY+gapY+cursorGapY, posZ, cursorWidth, cursorHeight,
									cursorColorR, cursorColorG, cursorColorB, cursorAlpha);
			}
			else
			{
				//LOGD("currentPos=%d", currentPos);
				BlitFilledRectangle(posX + fontWidth*currentPos, posY, posZ, fontWidth, fontHeight,
									cursorColorR, cursorColorG, cursorColorB, cursorAlpha);
			}
		}
	}

	if (this->font)
	{
		font->BlitText(textBuffer, posX + this->gapX2, posY + this->gapY2 + textOffsetY, posZ, fontScale, 1.0f);
	}
	else
	{
		guiMain->fntConsole->BlitText(textBuffer,
								  posX + this->gapX2,
								  posY + this->gapY2 + textOffsetY, posZ,
								  fontWidth, 1.0);
	}
}

void CGuiEditBoxText::Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY)
{
	this->Render(posX, posY);
}

void CGuiEditBoxText::SetText(char *setText)
{
	//guiMain->LockRenderMutex();
	if (setText == NULL)
	{
		textBuffer[0] = '\0';
	}

	if (setText != NULL)
	{
		// TODO: WIN32 is fucking not C99 compliant... write own snprintf(textBuffer, maxNumChars, "%s", setText);
		sprintf(textBuffer, "%s", setText);
	}

	this->currentPos = strlen(this->textBuffer);
	this->numChars = strlen(this->textBuffer);
	//guiMain->UnlockRenderMutex();

	this->SetSize((fontWidth*(GLfloat)maxNumChars*gapX), (fontHeight*gapY));
}

char *CGuiEditBoxText::GetText()
{
	return textBuffer;
}

void CGuiEditBoxText::FocusReceived()
{
	LOGM("CGuiEditBoxText::FocusReceived");
	GUI_ShowVirtualKeyboard();

	this->editing = true;
	LOGD("this->editing=%d", this->editing);
}

void CGuiEditBoxText::FocusLost()
{
	LOGM("CGuiEditBoxText::FocusLost");
	GUI_HideVirtualKeyboard();
	this->editing = false;
	LOGD("this->editing=%d", this->editing);
}


bool CGuiEditBoxText::KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	LOGI("CGuiEditBoxText::KeyDown: %2.2x '%c'", keyCode, (char)keyCode);

	if (this->editing == false)
		return false;

	if (keyCode == MTKEY_ARROW_LEFT)
	{
		if (currentPos > 0)
			currentPos--;
		return true;
	}
	if (keyCode == MTKEY_ARROW_RIGHT)
	{
		int l = strlen(textBuffer);
		if (currentPos < l)
			currentPos++;
		return true;
	}
	
	if (keyCode >= MTKEY_ARROW_LEFT)
	{
		return true;
	}
	
	if (keyCode == MTKEY_BACKSPACE)
	{
		if (currentPos > 0)
			currentPos--;
		textBuffer[currentPos] = '\0';
	}
	else if (keyCode == MTKEY_ENTER)
	{
		if (callback != NULL)
			callback->EditBoxTextFinished(this, textBuffer);
		return true;
	}
	else
	{
		if (currentPos < maxNumChars)
		{
			if (forceCapitals == false)
			{
				textBuffer[currentPos] = keyCode;
			}
			else
			{
				textBuffer[currentPos] = toupper(keyCode);
			}

			currentPos++;
			textBuffer[currentPos] = '\0';
		}
	}

	if (callback != NULL)
		callback->EditBoxTextValueChanged(this, textBuffer);

	return true;
}

void CGuiEditBoxText::SetEnabled(bool setEnabled)
{
	this->enabled = setEnabled;
	if (this->enabled == false && this->editing == true)
	{
		this->editing = false;
	}
}
