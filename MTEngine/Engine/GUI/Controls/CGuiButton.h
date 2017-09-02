/*
 *  CGuiButton.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_BUTTON_
#define _GUI_BUTTON_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include "SYS_Main.h"
#include "CSlrFont.h"

#define BUTTON_ALIGNED_CENTER	BV00
#define BUTTON_ALIGNED_UP		BV01
#define BUTTON_ALIGNED_DOWN		BV02
#define BUTTON_ALIGNED_LEFT		BV03
#define BUTTON_ALIGNED_RIGHT	BV04

#define DEFAULT_BUTTON_GAPX 5.0f
#define DEFAULT_BUTTON_GAPY 5.0f

#define DEFAULT_BUTTON_SIZE 1.0f
#define DEFAULT_BUTTON_ZOOM 1.5f

//#define DEFAULT_BUTTON_ZOOM_SPEED 6.3f
#define DEFAULT_BUTTON_ZOOM_SPEED ( (60.0f/(float)FRAMES_PER_SECOND) * 3.3f )

class CGuiButtonCallback;

class CGuiButton : public CGuiElement
{
 public:
	CGuiButton(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback);
	CGuiButton(CSlrImage *bkgImage, CSlrImage *bkgImageDisabled,
			   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
			   CSlrString *textUTF,
			   byte textAlignment, float textOffsetX, float textOffsetY,
			   CSlrFont *font, float fontScale,
			   float textColorR, float textColorG, float textColorB, float textColorA,
			   float textColorDisabledR, float textColorDisabledG, float textColorDisabledB, float textColorDisabledA,
			   CGuiButtonCallback *callback);

	CGuiButton(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, CGuiButtonCallback *callback);
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	virtual void RenderText(GLfloat posX, GLfloat posY);
	virtual void RenderUTFButton(GLfloat posX, GLfloat posY);

	bool DoTap(GLfloat x, GLfloat y);
	bool DoFinishTap(GLfloat x, GLfloat y);
	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	void FinishTouches();
	void DoLogic();

	// overwrite this
	virtual bool Clicked(GLfloat posX, GLfloat posY);
	virtual bool Pressed(GLfloat posX, GLfloat posY);

	virtual void ReleaseClick();
	
	float buttonShadeAmount;
	float buttonShadeDistance;
	float buttonShadeDistance2;
	
	float buttonEnabledColorR;
	float buttonEnabledColorG;
	float buttonEnabledColorB;
	float buttonEnabledColorA;
	float buttonEnabledColor2R;
	float buttonEnabledColor2G;
	float buttonEnabledColor2B;
	float buttonEnabledColor2A;
	
	float buttonDisabledColorR;
	float buttonDisabledColorG;
	float buttonDisabledColorB;
	float buttonDisabledColorA;
	float buttonDisabledColor2R;
	float buttonDisabledColor2G;
	float buttonDisabledColor2B;
	float buttonDisabledColor2A;

	virtual void InitBackgroundColors();
	
	virtual void InitWithText(char *txt);
	void SetText(char *text);
	char *text2;
	GLfloat fontWidth;
	GLfloat fontHeight;

	void SetFont(CSlrFont *font, float fontScale);
	CSlrFont *font;
	float fontScale;
	
	int textAlignment;
	
	float textColorR;
	float textColorG;
	float textColorB;
	float textColorA;

	float textColorDisabledR;
	float textColorDisabledG;
	float textColorDisabledB;
	float textColorDisabledA;

	void RecalcTextPosition();
	float textDrawPosX;
	float textDrawPosY;
	
	void SetFontScale(float fontScale);

	CSlrImage *image;
	CSlrImage *imageDisabled;
	CSlrImage *imageExpanded;
	
	CSlrImage *bkgImage;
	CSlrString *textUTF;

	GLfloat buttonPosX;
	GLfloat buttonPosY;
	GLfloat buttonSizeX;
	GLfloat buttonSizeY;

	GLfloat buttonZoom;

	volatile bool clickConsumed;
	bool beingClicked;
	volatile bool pressConsumed;

	volatile bool enabled;
	void SetEnabled(bool enabled);

	bool zoomable;
	bool zoomingLocked;
	float zoomSpeed;
	bool IsZoomingOut();
	bool IsZoomed();

	byte alignment;

	CGuiButtonCallback *callback;

	volatile bool wasExpanded;
	volatile bool isExpanded;
	bool DoExpandZoom();

	bool imageFlippedX;
	
	bool centerText;
	float textOffsetY;
};

class CGuiButtonCallback
{
public:
	virtual bool ButtonClicked(CGuiButton *button);
	virtual bool ButtonPressed(CGuiButton *button);

	// TODO: move callback from CGuiButtonMenu to CGuiButton to have action when expanded (not only menu show)
	// for CGuiButtonMenu
	virtual void ButtonExpandedChanged(CGuiButton *button);
};

#endif //_GUI_BUTTON_
