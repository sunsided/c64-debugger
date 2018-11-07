/*
 *  CGuiView.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_
#define _GUI_VIEW_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include "SYS_Main.h"

class CGuiView : public CGuiElement
{
public:
	CGuiView(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual void SetPositionElements(GLfloat posX, GLfloat posY);
	virtual void SetSize(GLfloat sizeX, GLfloat sizeY);

	// is inside including frame (with title bar, etc)?
	virtual bool IsInside(GLfloat x, GLfloat y);
	
	// is inside view interior area (without title bar, etc)?
	virtual bool IsInsideView(GLfloat x, GLfloat y);
	virtual bool IsInsideViewNonVisible(GLfloat x, GLfloat y);

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoTapNoBackground(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoRightClick(GLfloat x, GLfloat y);
	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);
	
	virtual bool DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	virtual void FinishTouches();

	// multi touch
	virtual bool DoMultiTap(COneTouchData *touch, float x, float y);
	virtual bool DoMultiTapNoBackground(COneTouchData *touch, float x, float y);
	virtual bool DoMultiMove(COneTouchData *touch, float x, float y);
	virtual bool DoMultiFinishTap(COneTouchData *touch, float x, float y);

	void PositionCenterOnParentView();
	
	virtual void ActivateView();
	virtual void DeactivateView();

	bool positionElementsOnFrameMove;
	bool consumeTapBackground;
	
	CSlrImage *imgBackground;

	class compareZupwards
	{
		// simple comparison function
	public:
		bool operator()(const GLfloat z1, const GLfloat z2) const
		{
			return z1 < z2; //(x-y)>0;
		}
	};

	class compareZdownwards
	{
		// simple comparison function
	public:
		bool operator()(const GLfloat z1, const GLfloat z2) const
		{
			return z1 > z2; //(x-y)>0;
		}
	};

	// TODO: volatile bool isActiveView;

	std::map<GLfloat, CGuiElement *, compareZupwards> guiElementsUpwards;
	std::map<GLfloat, CGuiElement *, compareZdownwards> guiElementsDownwards;

	void AddGuiElement(CGuiElement *guiElement, GLfloat z);
	void AddGuiElement(CGuiElement *guiElement);

	void RemoveGuiElements();
	void RemoveGuiElement(CGuiElement *guiElement);
	
	void BringToFront(CGuiElement *guiElement);
	
	// focus
	virtual void RenderFocusBorder();
	virtual void ClearFocus();
	virtual bool SetFocus(CGuiElement *view);
	CGuiElement *focusElement;
		

	// Resource Manager
	// this method should prepare all resources, refresh resources
	virtual void ResourcesPrepare();

	// returns if succeeded
	virtual bool StartAnimationEditorDebug();
	virtual void ReturnFromAnimationEditorDebug();
	
//	float mousePosX, mousePosY;
	
	virtual void UpdateTheme();

private:
	float previousZ;
	float previousFrontZ;
};

#endif
//_GUI_VIEW_

