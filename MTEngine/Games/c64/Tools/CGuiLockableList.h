/*
 *  CGuiLockableList.h
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_LOCKABLE_LIST_
#define _GUI_LOCKABLE_LIST_

#include "CSlrFont.h"
#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"
#include "CGuiList.h"

class CGuiLockableList : public CGuiList
{
public:
	CGuiLockableList(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat fontSize, //GLfloat fontWidth, GLfloat fontHeight, 
			 char **elements, int numElements, bool deleteElements, CSlrFont *font, 
			 CSlrImage *imgBackground, GLfloat backgroundAlpha, CGuiListCallback *callback);
	~CGuiLockableList();
	
	virtual bool DoTap(GLfloat x, GLfloat y);

	virtual void Render();

	virtual bool DoScrollWheel(float deltaX, float deltaY);
	
	float selectionColorR, selectionColorG, selectionColorB;
	volatile bool isLocked;
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual void SetElement(int elementNum, bool updatePosition, bool runCallback);

	virtual bool IsFocusable();
	virtual bool SetFocus(bool focus);
	
	virtual void SetListLocked(bool isLocked);
};


#endif //_GUI_LIST_
