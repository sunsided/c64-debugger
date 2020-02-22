/*
 *  CGuiViewNumKeys.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-05-25.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#include "CSlrImage.h"
#include "CGuiElement.h"
#include "CGuiView.h"

class CGuiViewNumKeysCallback;

class CGuiViewNumKeys : public CGuiView
{
public:
	CGuiViewNumKeys(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CGuiViewNumKeysCallback *callback);
	
	virtual void Render();
	CGuiViewNumKeysCallback *callback;

};
