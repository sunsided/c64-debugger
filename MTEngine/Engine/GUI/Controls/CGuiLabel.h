/*
 *  CGuiLabel.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_LABEL_
#define _GUI_LABEL_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include "SYS_Main.h"
class CSlrString;
class CSlrFont;

#define LABEL_ALIGNED_CENTER	BV00
#define LABEL_ALIGNED_UP		BV01
#define LABEL_ALIGNED_DOWN		BV02
#define LABEL_ALIGNED_LEFT		BV03
#define LABEL_ALIGNED_RIGHT		BV04

class CGuiLabelCallback;

class CGuiLabel : public CGuiElement
{
public:
	CGuiLabel(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiLabelCallback *callback);
	CGuiLabel(char *text, bool stretched, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, GLfloat fontWidth, GLfloat fontHeight, CGuiLabelCallback *callback);
	CGuiLabel(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, CSlrFont *font, float fontSize, CGuiLabelCallback *callback);
	CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, float fontSize, CGuiLabelCallback *callback);
	CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, GLfloat fontSize,
			  float colorR, float colorG, float colorB, float alpha, CGuiLabelCallback *callback);
	CGuiLabel(CSlrString *textUTF, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CSlrFont *font, GLfloat fontSize,
			  float bkgColorR, float bkgColorG, float bkgColorB, float blgColorA,
			  float textColorR, float textColorG, float textColorB, float textColorA,
			  float textOffsetX, float textOffsetY,
			  CGuiLabelCallback *callback);
	void Render();
	void Render(GLfloat posX, GLfloat posY);

	bool DoTap(GLfloat x, GLfloat y);
	bool DoFinishTap(GLfloat x, GLfloat y);
	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	void FinishTouches();
	void DoLogic();

	void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	void UpdateTextSize(bool stretched);

	// overwrite this
	virtual bool Clicked(GLfloat posX, GLfloat posY);
	virtual bool Pressed(GLfloat posX, GLfloat posY);

	void InitWithText(char *txt, bool stretched);
	void SetText(const char *text, bool stretched);

	void InitWithText(CSlrString *textUTF);
	void SetText(CSlrString *textUTF);

	char *text;
	GLfloat fontWidth;
	GLfloat fontHeight;

	CSlrString *textUTF;
	CSlrFont *font;
	float fontSize;

	CSlrImage *image;

	GLfloat textPosX;
	GLfloat textPosY;

	bool clickConsumed;
	bool beingClicked;

	//bool zoomable;

	byte alignment;

	bool transparentToTaps;

	float bkgColorR;
	float bkgColorG;
	float bkgColorB;
	float bkgColorA;

	float textColorR;
	float textColorG;
	float textColorB;
	float textColorA;

	CGuiLabelCallback *callback;
};

class CGuiLabelCallback
{
public:
	virtual bool LabelClicked(CGuiLabel *label);
	virtual bool LabelPressed(CGuiLabel *label);
};



#endif
//_GUI_BUTTON_

