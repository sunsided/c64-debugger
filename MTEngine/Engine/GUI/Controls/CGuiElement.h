/*
 *  CGuiElement.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-26.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_ELEM_
#define _GUI_ELEM_

#include "SYS_Defs.h"
#if defined(IOS)
#include "OpenGLCommon.h"
#endif
#include "SYS_Main.h"
#include <map>
#include "GuiConsts.h"
#include "COneTouchData.h"

#define ELEMENT_ALIGNED_NONE	BV00
#define ELEMENT_ALIGNED_CENTER	BV01
#define ELEMENT_ALIGNED_UP		BV02
#define ELEMENT_ALIGNED_DOWN		BV03
#define ELEMENT_ALIGNED_LEFT		BV04
#define ELEMENT_ALIGNED_RIGHT	BV05

class CGuiElement
{
public:
	CGuiElement(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CGuiElement();

	GLfloat posX, posY, posZ, sizeX, sizeY, posEndX, posEndY;
	GLfloat gapX, gapY; // for GuiViewList
	virtual bool IsInside(GLfloat x, GLfloat y);
	virtual bool IsInsideNonVisible(GLfloat x, GLfloat y);

	virtual void SetVisible(bool isVisible);

	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual void SetSize(GLfloat sizeX, GLfloat sizeY);

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoRightClick(GLfloat x, GLfloat y);
	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	// not touched move = mouse move with not clicked button
	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	// multi touch
	virtual bool DoMultiTap(COneTouchData *touch, float x, float y);
	virtual bool DoMultiMove(COneTouchData *touch, float x, float y);
	virtual bool DoMultiFinishTap(COneTouchData *touch, float x, float y);

	virtual void FinishTouches();

	virtual void DoLogic();

	virtual void FocusReceived();
	virtual void FocusLost();

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats

	virtual GLfloat GetHeight();
	virtual GLfloat GetWidth();
	
	// Resource Manager
	// this method should prepare all resources, refresh resources
	virtual void ResourcesPrepare();
	virtual void ResourcesPostLoad();

	volatile bool visible;

	// does not render in view->Render method
	bool manualRender;

	byte elementAlignment;

	char *name;

	virtual void SetFocus(bool focus);
	
	volatile bool hasFocus;
	volatile bool locked;
	//NSString *fullPath;
	char *fullPath;

	class compareZupwards
	{
		// simple comparison function
	public:
		bool operator()(const float z1, const float z2) const
		{
			return z1 < z2; //(x-y)>0;
		}
	};

	class compareZdownwards
	{
		// simple comparison function
	public:
		bool operator()(const float z1, const float z2) const
		{
			return z1 > z2; //(x-y)>0;
		}
	};


	std::map<float, CGuiElement *, compareZupwards> guiElementsUpwards;
	std::map<float, CGuiElement *, compareZdownwards> guiElementsDownwards;

	void AddGuiElement(CGuiElement *guiElement, float z);
	//	void RemoveGuiElement(CGuiElement *guiElement);
	
	void *userData;

};

#endif //_GUI_ELEM_
