/*
 *  CGuiViewVerticalScroll.h
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_VERTICAL_SCROLL_
#define _GUI_VIEW_VERTICAL_SCROLL_

#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"

class CGuiViewVerticalScrollCallback;

#define VERTICAL_SCROLL_ACCEL_NUM_FRAMES 5

#define STATE_SHOW 0
#define STATE_MOVE_ANIM	1

class CGuiViewVerticalScroll : public CGuiElement
{
public:
	CGuiViewVerticalScroll(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
				 CGuiElement **elements, int numElements, bool deleteElements, CGuiViewVerticalScrollCallback *callback);
	
	void Init(CGuiElement **elements, int numElements, bool deleteElements);
	
	virtual void Render();
	
	int numElements;
	CGuiElement **listElements;
	
	bool deleteElements;
	
	GLfloat startDrawX;
	GLfloat startDrawY;	
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void DoLogic();
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	
	void ScrollHome();
	void ScrollTo(int newElement);

	virtual void ElementSelected();
	CGuiViewVerticalScrollCallback *callback;

	GLfloat animDrawPosY[VERTICAL_SCROLL_ACCEL_NUM_FRAMES + 5];
	int selectedElement;
	int nextCurrentTlo;

	GLfloat drawPosY;
	int moveAnimFrame;

	byte state;
};

class CGuiViewVerticalScrollCallback
{
public:
	virtual void VerticalScrollElementSelected(CGuiViewVerticalScroll *listBox);
};


#endif //_GUI_VIEW_VERTICAL_SCROLL_
