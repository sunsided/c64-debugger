/*
 *  CGuiViewMessageBox.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-09-03.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_VIEW_MSGBOX_
#define _GUI_VIEW_MSGBOX_

#include "CGuiView.h"
#include "CGuiButton.h"

class CGuiMessageBoxCallback;

class CGuiViewMessageBox : public CGuiView, CGuiButtonCallback
{
public:
	CGuiViewMessageBox(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, UTFString *message, CGuiMessageBoxCallback *callback);
	~CGuiViewMessageBox();

	void SetText(UTFString *message);

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
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual void FinishTouches();

	virtual void ActivateView();
	virtual void DeactivateView();

	UTFString *messageLine1;
	UTFString *messageLine2;
	UTFString *messageLine3;
	UTFString *messageLine4;

	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);

	CGuiButton *btnOK;

	GLfloat textPosX;
	GLfloat textPosY;

	CGuiMessageBoxCallback *callback;
};

class CGuiMessageBoxCallback
{
public:
	virtual bool MessageBoxClickedOK(CGuiViewMessageBox *messageBox);
};

#endif
//_GUI_VIEW_MSGBOX_

