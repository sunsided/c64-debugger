/*
 *  CGuiButtonMenu.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-01.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_BUTTON_MENU_
#define _GUI_BUTTON_MENU_

#include "CGuiButton.h"
#include <list>

class CGuiButtonMenu : public CGuiButton
{
public:
	CGuiButtonMenu(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, 
				   CSlrImage *backgroundImage, 
				   GLfloat backgroundPosX, GLfloat backgroundPosY, GLfloat backgroundSizeX, GLfloat backgroundSizeY,
				   CGuiButtonCallback *callback);
	CGuiButtonMenu(CSlrImage *image, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, 
				   CGuiButtonCallback *callback);
	
	CGuiButtonMenu(char *text, bool blah, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, 
				   CGuiButtonCallback *callback);
	virtual void Render();
	void RenderElements();
	void RenderButton();
	
	/*
	bool IsInsideButton(float posX, float posY);
	*/

//	void SetMenu(std::list<CGuiElement *> *menuElements);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);	
	virtual void FinishTouches();
	virtual void DoLogic();
	
	void HideSubMenu(bool immediately);
	void HideSubMenuNoCallback(bool immediately);
	
	CSlrImage *backgroundImage;
	GLfloat backgroundPosX;
	GLfloat backgroundPosY;
	GLfloat backgroundSizeX;
	GLfloat backgroundSizeY;
	
	bool manualRendering;

	// overwrite this
	//bool Clicked(float posX, float posY);
	//bool Pressed(float posX, float posY);
	
	//std::list<CGuiElement *> *menuElements;
	
	GLfloat previousZ;
	
	void AddMenuSubItem(CGuiElement *guiElement, float z);
	void AddMenuSubItem(CGuiElement *guiElement);
	
	volatile bool finishTapConsumed;	
	
	void SetExpanded(bool expanded);
};

#endif //_GUI_BUTTON_
