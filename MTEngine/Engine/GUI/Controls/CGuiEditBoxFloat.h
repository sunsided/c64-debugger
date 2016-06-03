/*
 *  CGuiEditBoxFloat.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _CGUIEDITBOXFLOAT_H_
#define _CGUIEDITBOXFLOAT_H_

#include "CGuiEditBoxText.h"

class CGuiEditBoxFloat : public CGuiEditBoxText
{
public:
	CGuiEditBoxFloat(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
					float defaultValue, byte maxDigitsL, byte maxDigitsR, bool readOnly,
					CGuiEditBoxTextCallback *callback);

	CGuiEditBoxFloat(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
					 float defaultValue, byte maxDigitsL, byte maxDigitsR, byte maxNumChars, bool readOnly,
					 CGuiEditBoxTextCallback *callback);

	void SetFloat(float value);
	float GetFloat();

	float value;

	byte maxDigitsL, maxDigitsR;

	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
};

#endif

