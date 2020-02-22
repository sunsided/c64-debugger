/*
 *  CGuiEditBoxText.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_EDITBOX_TEXT_
#define _GUI_EDITBOX_TEXT_

#include "CGuiView.h"
#include "CGuiButton.h"

#define TEXTBOX_TYPE_TEXT	0x00
#define TEXTBOX_TYPE_FLOAT	0x01
#define TEXTBOX_TYPE_INT	0x02

class CGuiEditBoxText;

class CGuiEditBoxTextCallback
{
public:
	virtual void EditBoxTextValueChanged(CGuiEditBoxText *editBox, char *text);
	virtual void EditBoxTextFinished(CGuiEditBoxText *editBox, char *text);
};

class CGuiEditBoxText : public CGuiView
{
public:
	CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
			  char *defaultText, u16 maxNumChars, bool readOnly,
					CGuiEditBoxTextCallback *callback);

	CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ,
					GLfloat sizeX, GLfloat sizeY,
					char *defaultText, u16 maxNumChars,
					CSlrFont *textFont, float fontScale, bool readOnly, CGuiEditBoxTextCallback *callback);

	CGuiEditBoxText(GLfloat posX, GLfloat posY, GLfloat posZ,
					GLfloat sizeX,
					char *defaultText, u16 maxNumChars,
					CSlrFont *textFont, float fontScale, bool readOnly, CGuiEditBoxTextCallback *callback);

	void Initialize(char *defaultText, u16 maxNumChars, bool readOnly,
					CGuiEditBoxTextCallback *callback);

	volatile bool enabled;
	bool editable;
	byte type;

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	volatile GLfloat alpha;

	GLfloat fontWidth;
	GLfloat fontHeight;

	void SetFont(CSlrFont *font, float fontScale);
	CSlrFont *font;
	float fontScale;
	float fontAlpha;

	float textOffsetY;

	GLfloat cursorAlpha;
	//GLfloat cursorAlphaVal;
	GLfloat cursorAlphaSpeed;

	char *textBuffer;
	u16 numChars;
	u16 currentPos;
	u16 maxNumChars;

	bool forceCapitals;

	GLfloat gapX, gapY, gapX2, gapY2;
	float cursorGapY;
	float cursorWidth, cursorHeight;

	volatile bool readOnly;
	volatile bool editing;

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	virtual void FinishTouches();
	virtual void DoLogic();
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void FocusReceived();
	virtual void FocusLost();

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats

	virtual void SetText(char *setText);
	virtual char *GetText();

	GLfloat colorR;
	GLfloat colorG;
	GLfloat colorB;
	GLfloat colorA;
	GLfloat color2R;
	GLfloat color2G;
	GLfloat color2B;
	GLfloat color2A;
	GLfloat cursorColorR;
	GLfloat cursorColorG;
	GLfloat cursorColorB;
	GLfloat cursorColorA;

	virtual void SetEnabled(bool setEnabled);
	CGuiEditBoxTextCallback *callback;

};

#endif //_GUI_EDITBOX_TEXT_
