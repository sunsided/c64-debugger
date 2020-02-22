/*
 *  CGuiEditBoxInt.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-12-03.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _CGUIEDITBOXINT_H_
#define _CGUIEDITBOXINT_H_

#include "CGuiEditBoxText.h"

class CGuiEditBoxInt : public CGuiEditBoxText
{
public:
	CGuiEditBoxInt(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
					 int defaultValue, byte maxDigits, bool readOnly,
					 CGuiEditBoxTextCallback *callback);

	void SetInteger(int value);
	int GetInteger();

	int value;

	byte maxDigits;

	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
};

#endif

