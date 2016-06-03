/*
 *  CGuiBackground.h
 *  MTEngine
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_BACKGROUND_
#define _GUI_BACKGROUND_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include "SYS_Main.h"

class CGuiBackground : public CGuiElement
{
public:
	CGuiBackground(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	CGuiBackground(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	CGuiBackground(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float colorR, float colorG, float colorB, float alpha);
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

	CSlrImage *image;
	float colorR, colorG, colorB, colorA;
};

#endif
//_GUI_BUTTON_

