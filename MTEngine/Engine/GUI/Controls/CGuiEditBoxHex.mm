/*
 *  CGuiEditBoxHex.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#include "GuiConsts.h"
#include "CGuiEditBoxHex.h"
#include "SYS_Main.h"
#include "CGuiMain.h"

CGuiEditBoxHex::CGuiEditBoxHex(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
						  int value, byte numDigits, bool showHexValues, bool readOnly, CGuiEditBoxHexCallback *callback)
:CGuiView(posX, posY, posZ, sizeX, sizeY)
{
	this->name = "CGuiEditBoxHex";

	this->fontWidth = fontWidth;
	this->fontHeight = fontHeight;
	this->value = value;
	this->numDigits = numDigits;
	this->showHexValues = showHexValues;

	this->readOnly = readOnly;
	this->editing = false;

	this->editingDigitNum = 0;

	this->drawBuf = new char[32];

	this->callback = callback;

	this->SetPosition(posX, posY, posZ, fontWidth*numDigits, fontHeight);
	this->alpha = 1.0;

	this->cursorAlpha = 1.0;
	this->cursorAlphaSpeed = 0.1;

	GLfloat pEndX = SCREEN_WIDTH - 15.0;
	GLfloat pEndY = SCREEN_HEIGHT - 15.0;

	GLfloat pSizeX = SCREEN_WIDTH - 30.0;
	GLfloat pSizeY = SCREEN_HEIGHT - 30.0;

	GLfloat startX = 15.0;
	GLfloat startY = 15.0;

	GLfloat butStepX = pSizeX / 5;
	GLfloat butSizeX = butStepX * 0.90;
	GLfloat butStepY = pSizeY / 4;
	GLfloat butSizeY = butStepY * 0.90;

	//	7 8 9 E F
	//	4 5 6 C D
	//	1 2 3 A B
	//	    0

	btn7 = new CGuiButton("7", startX, startY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn7);
	btn8 = new CGuiButton("8", startX + 1*butStepX, startY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn8);
	btn9 = new CGuiButton("9", startX + 2*butStepX, startY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn9);
	btnE = new CGuiButton("E", startX + 3*butStepX, startY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnE);
	btnF = new CGuiButton("F", startX + 4*butStepX, startY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnF);

	btn4 = new CGuiButton("4", startX, startY + 1*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn4);
	btn5 = new CGuiButton("5", startX + 1*butStepX, startY + 1*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn5);
	btn6 = new CGuiButton("6", startX + 2*butStepX, startY + 1*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn6);
	btnC = new CGuiButton("C", startX + 3*butStepX, startY + 1*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnC);
	btnD = new CGuiButton("D", startX + 4*butStepX, startY + 1*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnD);

	btn1 = new CGuiButton("1", startX, startY + 2*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn1);
	btn2 = new CGuiButton("2", startX + 1*butStepX, startY + 2*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn2);
	btn3 = new CGuiButton("3", startX + 2*butStepX, startY + 2*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn3);
	btnA = new CGuiButton("A", startX + 3*butStepX, startY + 2*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnA);
	btnB = new CGuiButton("B", startX + 4*butStepX, startY + 2*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btnB);

	btn0 = new CGuiButton("0", startX + 2*butStepX, startY + 3*butStepY, posZ, butSizeX, butSizeY, BUTTON_ALIGNED_CENTER, this);
	this->AddGuiElement(btn0);

	btnDone = new CGuiButton("DONE", pEndX - (guiButtonSizeX + guiButtonGapX), pEndY - (guiButtonSizeY + guiButtonGapY), posZ + 0.04,
							 guiButtonSizeX, guiButtonSizeY, BUTTON_ALIGNED_DOWN, this);
	this->AddGuiElement(btnDone);
}

bool CGuiEditBoxHex::ButtonPressed(CGuiButton *button)
{
	LOGG("CGuiEditBoxHex::ButtonPressed");

	byte digit = 0xFF;

	if (button == btnDone)
	{
		this->editing = false;
		// callback:
		if (this->callback)
			this->callback->EditBoxValueSet(this, this->value);
		guiMain->SetWindowOnTop(NULL);
		return true;
	}
	else if (button == btn0)
	{
		digit = 0x00;
	}
	else if (button == btn1)
	{
		digit = 0x01;
	}
	else if (button == btn2)
	{
		digit = 0x02;
	}
	else if (button == btn3)
	{
		digit = 0x03;
	}
	else if (button == btn4)
	{
		digit = 0x04;
	}
	else if (button == btn5)
	{
		digit = 0x05;
	}
	else if (button == btn6)
	{
		digit = 0x06;
	}
	else if (button == btn7)
	{
		digit = 0x07;
	}
	else if (button == btn8)
	{
		digit = 0x08;
	}
	else if (button == btn9)
	{
		digit = 0x09;
	}
	else if (button == btnA)
	{
		digit = 0x0A;
	}
	else if (button == btnB)
	{
		digit = 0x0B;
	}
	else if (button == btnC)
	{
		digit = 0x0C;
	}
	else if (button == btnD)
	{
		digit = 0x0D;
	}
	else if (button == btnE)
	{
		digit = 0x0E;
	}
	else if (button == btnF)
	{
		digit = 0x0F;
	}

	if (digit != 0xFF)
	{
		if (editingDigitNum == 2)
		{
			this->value = (this->value & 0x0F) | (digit << 4);
		}
		else if (editingDigitNum == 1)
		{
			this->value = (this->value & 0xF0) | (digit);
		}
		editingDigitNum--;
		if (editingDigitNum == 0)
		{
			this->editing = false;
			guiMain->SetWindowOnTop(NULL);
			this->callback->EditBoxValueSet(this, this->value);
			this->editingDigitNum = numDigits;
		}

		if (this->callback != NULL)
		{
			this->callback->EditBoxValueChanged(this, this->value);
		}

		return true;
	}

	return false;
}

bool CGuiEditBoxHex::ButtonClicked(CGuiButton *button)
{
	return false;
}

void CGuiEditBoxHex::StartEditing()
{
	this->editing = true;
	this->editingDigitNum = numDigits;
	guiMain->SetWindowOnTop(this);
}

bool CGuiEditBoxHex::DoTap(GLfloat x, GLfloat y)
{
	if (this->callback != NULL)
	{
		//		this->callback->ValueChanged
	}

	if (this->editing == false)
	{
		if (IsInside(x, y))
		{
			if (this->readOnly == false)
			{
				this->StartEditing();
			}
			GUI_SetPressConsumed(true);
			return true;
		}
	}
	else
	{
		CGuiView::DoTap(x, y);
		return true;
	}
	return false;
}

bool CGuiEditBoxHex::DoFinishTap(GLfloat x, GLfloat y)
{
	if (this->editing)
	{
		CGuiView::DoFinishTap(x, y);
		return true;
	}
	return false;
}

bool CGuiEditBoxHex::DoDoubleTap(GLfloat x, GLfloat y)
{
	if (this->editing)
	{
		return this->DoTap(x, y);
	}
	return false;
}

bool CGuiEditBoxHex::DoFinishDoubleTap(GLfloat x, GLfloat y)
{
	if (this->editing)
	{
		return this->DoFinishTap(x, y);
	}
	return false;
}

bool CGuiEditBoxHex::DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY)
{
	if (this->editing)
	{
		return this->DoTap(x, y);
	}
	return false;
}

bool CGuiEditBoxHex::FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY)
{
	if (this->editing)
	{
		return this->DoFinishTap(x, y);
	}
	return false;
}

bool CGuiEditBoxHex::InitZoom()
{
	if (this->editing)
	{
		CGuiView::InitZoom();
		return true;
	}
	return false;
}

bool CGuiEditBoxHex::DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference)
{
	if (this->editing)
	{
		CGuiView::DoZoomBy(x, y, zoomValue, difference);
		return true;
	}
	return false;
}

void CGuiEditBoxHex::FinishTouches()
{
	if (this->editing)
	{
		CGuiView::FinishTouches();
	}
}

void CGuiEditBoxHex::DoLogic()
{
	if (this->editing)
	{
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
}


void CGuiEditBoxHex::DrawDigits(GLfloat posX, GLfloat posY, GLfloat fontWidth)
{
	GLfloat drawX = posX;
	GLfloat fontSize = fontWidth;
	GLfloat posZ = -2.0;

	if (showHexValues)
	{
		if (numDigits == 1)
			Byte2Hex1digitR(value, drawBuf);
		else if (numDigits == 2)
			Byte2Hex2digits(value, drawBuf);
		else
		{
			char buf[10] = {0};
			sprintf(buf, "%%%d.%dx", numDigits, numDigits);
			sprintf(drawBuf, buf, value);
		}
	}
	else
	{
		char buf[10] = {0};
		sprintf(buf, "%%%dd", numDigits);
		//LOGF("Buf: '%s'\n", buf);
		sprintf(drawBuf, buf, value);
	}

	for (byte i = 0; i < numDigits; i++)
	{
		// draw cursor
		if (this->editing && i == (numDigits-editingDigitNum))
		{
			guiMain->theme->imgBackgroundTextboxEditCursor->RenderAlpha(drawX, posY, posZ, fontSize, fontSize, cursorAlpha);
		}

		guiMain->fntConsole->BlitChar(drawBuf[i], drawX, posY, posZ, fontSize, alpha);
		drawX += fontWidth;
	}

	/*
	 for (byte i = 0; i < numDigits; i++)
	 {
	 if (drawElem == selectedItem && editMode && editCursorPos == i)
	 {
	 mtrMain->fntConsoleInverted->BlitChar(drawBuf[i], drawX, drawY);
	 }
	 else
	 {
	 mtrMain->fntConsole->BlitChar(drawBuf[i], drawX, drawY);
	 }
	 drawX += FONT_WIDTH;
	 }*/
}

void CGuiEditBoxHex::Render()
{
	if (!this->visible)
		return;

	if (this->editing == false)
	{
		DrawDigits(this->posX, this->posY, this->fontWidth);
	}
	else
	{
		// editing = fullscreen
		guiMain->theme->imgBackground->RenderAlpha(0.0, 0.0, -0.1, SCREEN_WIDTH, SCREEN_HEIGHT, 0.8);

		CGuiView::Render();

		DrawDigits(30.0, SCREEN_HEIGHT-40.0, 30.0f);
	}

}

void CGuiEditBoxHexCallback::EditBoxValueChanged(CGuiEditBoxHex *editBox, byte value)
{
}

void CGuiEditBoxHexCallback::EditBoxValueSet(CGuiEditBoxHex *editBox, byte value)
{
}


/*

 1 2 3
 4 5 6
 7 8 9
 A B C
 D E F

 1 2 3 4
 5 6 7 8
 9 A B C
 D E F 0

 0 1 2 3
 4 5 6 7
 8 9 A B
 C D E F


 1 2 3 4 5
 6 7 8 9 0
 A B C D E
 F

 1 2 3 4 5 6
 7 8 9 A B C
 D E F

 1 2 3 4 5 6 7
 8 9 A B C D E
 F

 1 2 3 4 5 6 7 8
 9 0 A B C D E F

 1 2 3 A B
 4 5 6 C D
 7 8 9 E F
     0


 7 8 9 E F
 4 5 6 C D
 1 2 3 A B
     0

*/
