/*
 *  CGuiViewConnectModulesPL.h
 *  MusicTracker
 *
 *  Created by Marcin Skoczylas on 11-01-11.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_CONNECT_MODULESPL_
#define _GUI_VIEW_CONNECT_MODULESPL_

#include "CGuiView.h"
#include "CGuiButton.h"

void GUI_ShowModulesPLView();
void GUI_HideModulesPLView(); 

class CGuiViewConnectModulesPL : public CGuiView, CGuiButtonCallback
{
public:
	CGuiViewConnectModulesPL(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	~CGuiViewConnectModulesPL();
	
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue);
	virtual void FinishTouches();
	
	virtual void ActivateView();
	virtual void DeactivateView();
	
	//bool ButtonClicked(CGuiButton *button);
	//bool ButtonPressed(CGuiButton *button);
	
	//CGuiButton *btnDone;
};

#endif //_GUI_VIEW_CONNECT_MODULESPL_