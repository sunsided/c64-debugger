/*
 *  CGuiButtonText.mm
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-02.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

/*
#include "CGuiButtonText.h"
#include "CGuiMain.h"

CGuiButtonText::CGuiButtonText(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, byte alignment, char *text, CGuiButtonCallback *callback)
:CGuiButton(guiMain->imgBtnBackground2, posX, posY, posZ, sizeX, sizeY, alignment, callback)
{
	this->name = "CGuiButtonText";
	this->beingClicked = false;
	this->clickConsumed = false;

	this->text = text;
	int len = strlen(text);
	
	len++;
	fontWidth = sizeX / len;
	fontHeight = sizeY * 0.8;
	
	this->zoomable = false;
}

bool CGuiButtonText::Clicked(GLfloat posX, GLfloat posY)
{
	return CGuiButton::Clicked(posX, posY);
}

bool CGuiButtonText::Pressed(GLfloat posX, GLfloat posY)
{
	return CGuiButton::Pressed(posX, posY);
}

void CGuiButtonText::Render()
{
	CGuiButton::Render();
	
	//BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha)
	guiMain->fntConsole->BlitText(this->text, 
								  posX + fontWidth/2, posY + sizeY*0.1, -1.0, 
								  fontWidth, fontHeight, 1.0);
}

*/