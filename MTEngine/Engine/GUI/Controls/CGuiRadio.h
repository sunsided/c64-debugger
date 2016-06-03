/*
 *  CGuiRadio.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-06.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_RADIO_H_
#define _GUI_RADIO_H_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include <list>

class CGuiRadioCallback;

class CGuiRadioElement : public CGuiElement
{
public:
	CGuiRadioElement(CSlrImage *imageNotSelected, CSlrImage *imageSelected);
	CGuiRadioElement(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CSlrImage *imageNotSelected, CSlrImage *imageSelected);
	CSlrImage *imageNotSelected;
	CSlrImage *imageSelected;
	volatile bool isSelected;	
};

class CGuiRadio : public CGuiElement 
{
public:
	CGuiRadio(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, std::list<CGuiRadioElement *> *elements, bool blitScaled);
	
	std::list<CGuiRadioElement *> *elements;
	volatile CGuiRadioElement *selectedElement;

	void Render();
	void Render(GLfloat posX, GLfloat posY);	
	
	bool DoTap(GLfloat x, GLfloat y);
//	bool DoFinishTap(GLfloat x, GLfloat y);
//	bool DoDoubleTap(GLfloat x, GLfloat y);
//	bool DoFinishDoubleTap(GLfloat x, GLfloat y);
//	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
//	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);	
//	void FinishTouches();
//	void DoLogic();

	void SetElement(CGuiRadioElement *selectedElement);
	void SetElement(int elemNum);
	
	bool blitScaled;
};

class CGuiRadioCallback
{
public:
	virtual void RadioElementSelected(CGuiRadioElement *radioElem);
};


#endif
