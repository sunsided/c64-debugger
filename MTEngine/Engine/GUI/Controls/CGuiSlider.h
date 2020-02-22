/*
 *  CGuiSlider.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_SLIDER_
#define _GUI_SLIDER_
#include "CGuiElement.h"

class CGuiSliderCallback;

class CGuiSlider : public CGuiElement
{
public:
	CGuiSlider(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiSliderCallback *callback);
	void Render();
	void Render(GLfloat posX, GLfloat posY);
	void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	volatile GLfloat alpha;

	volatile float value;	// <0.0, 1.0>
	void SetValue(float value);

	volatile bool changing;
	volatile bool readOnly;

	bool DoTap(GLfloat x, GLfloat y);
	//bool DoFinishTap(GLfloat x, GLfloat y);
	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	void FinishTouches();
	void DoLogic();

	CGuiSliderCallback *callback;

	virtual void SliderValueChanged(float value);

};

class CGuiSliderCallback
{
public:
	virtual void SliderValueChanged(CGuiSlider *slider, float value);
};

#endif
//_GUI_SLIDER_

