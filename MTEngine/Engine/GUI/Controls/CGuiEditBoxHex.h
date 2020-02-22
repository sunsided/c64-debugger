/*
 *  CGuiEditBoxHex.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_EDITBOX_HEX_
#define _GUI_EDITBOX_HEX_
#include "CGuiView.h"
#include "CGuiButton.h"

class CGuiEditBoxHex;

class CGuiEditBoxHexCallback
{
public:
	virtual void EditBoxValueChanged(CGuiEditBoxHex *editBox, byte value);
	virtual void EditBoxValueSet(CGuiEditBoxHex *editBox, byte value);
};

class CGuiEditBoxHex : public CGuiView, CGuiButtonCallback
{
public:
	CGuiEditBoxHex(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
			  int value, byte numDigits, bool showHexValues, bool readOnly, CGuiEditBoxHexCallback *callback);

	bool editable;

	void Render();
	volatile GLfloat alpha;

	GLfloat fontWidth;
	GLfloat fontHeight;

	GLfloat cursorAlpha;
	GLfloat cursorAlphaSpeed;

	volatile u32 value;
	byte numDigits;
	byte itemVal;
	byte minVal;
	byte maxVal;

	bool showHexValues;
	volatile bool readOnly;
	volatile bool editing;
	volatile byte editingDigitNum;

	bool DoTap(GLfloat x, GLfloat y);
	bool DoFinishTap(GLfloat x, GLfloat y);
	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	void FinishTouches();
	void DoLogic();
	bool InitZoom();
	bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	void DrawDigits(GLfloat posX, GLfloat posY, GLfloat fontWidth);

	char *drawBuf;
	CGuiEditBoxHexCallback *callback;

	CGuiButton *btn0;
	CGuiButton *btn1;
	CGuiButton *btn2;
	CGuiButton *btn3;
	CGuiButton *btn4;
	CGuiButton *btn5;
	CGuiButton *btn6;
	CGuiButton *btn7;
	CGuiButton *btn8;
	CGuiButton *btn9;
	CGuiButton *btnA;
	CGuiButton *btnB;
	CGuiButton *btnC;
	CGuiButton *btnD;
	CGuiButton *btnE;
	CGuiButton *btnF;
	CGuiButton *btnDone;

	void StartEditing();
};

#endif
//_GUI_EDITBOX_HEX_

