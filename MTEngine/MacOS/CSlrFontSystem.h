/*
 *  SYS_CSystemFont.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-07-14.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 * original file by http://www.themusingsofalostprogrammer.com/2010/01/how-to-do-font-rendering-in-opengl-on.html
 * (public domain)
 */

#ifndef _CSYSTEM_FONT_H_
#define _CSYSTEM_FONT_H_

#include "CSlrFont.h"
#include <map>
#include <string>
#include <sstream>

class CSlrFontSystem : public CSlrFont
{
public:
	CSlrFontSystem(char *name, bool withHalo, const std::string &family = "Helvetica", int size = 36);
	CSlrFontSystem(char *name, bool withHalo, int size, const std::string &family = "Helvetica");
	~CSlrFontSystem();
	
	void EnsureCharacters(UTFString *text);
	 
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha);
	void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);
	
	void BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z, 
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, 
				  int align = FONT_ALIGN_LEFT, GLfloat scale = 1.0f);
	
	void BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z, 
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, 
				  int align = FONT_ALIGN_LEFT, GLfloat scale = 1.0f);

	UTFString *family;
	const int size;
	bool withHalo;
	GLfloat haloR, haloG, haloB; //, haloAlpha;
};

#endif // _CSYSTEM_FONT_H_
