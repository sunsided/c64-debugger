/*
 *  CSlrFontBitmap.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-23.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __VID_CSlrFontBitmap_H__
#define __VID_CSlrFontBitmap_H__

#include "SYS_Defs.h"
#include "VID_GLViewController.h"
#include "CSlrFont.h"
//#include "CSlrImage.h"


class CSlrImage;

class CSlrFontBitmap : public CSlrFont
{
public:
	CSlrFontBitmap(char *name, CSlrImage *fntImageData,
			 GLfloat fntWidth, GLfloat fntHeight, GLfloat fntPitchX, GLfloat fntPitchY);

	~CSlrFontBitmap();

	void GetFontChar(unsigned char c, byte *x, byte *y);
	void GetFontCharNoInvert(unsigned char c, byte *x, byte *y);
	void GetFontChar(bool invert, unsigned char c, byte *x, byte *y);
//	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ);
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	void BlitText(bool invert, char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);
	void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha);
	void BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
	void BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
				  int align, GLfloat scale);

	void BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
				  int align, GLfloat scale);


	virtual void BlitTextColor(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
	virtual void BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

	void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);

	virtual float GetTextWidth(char *text, float scale);

	GLfloat width, height, pitchX, pitchY;
	CSlrImage *imageData;
	
	virtual void ResourcesPrepare();
	
};


#endif

