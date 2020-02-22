/*
 *  CSlrFont.h
 *  MusicTracker
 *
 *  Created by Marcin Skoczylas on 11-04-04.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */


#ifndef _CSLR_FONT_
#define _CSLR_FONT_

#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "VID_Main.h"
#include "CSlrResourceBase.h"

#define FONT_TYPE_UNKNOWN 0
#define FONT_TYPE_BITMAP 1
#define FONT_TYPE_SYSTEM 2
#define FONT_TYPE_PROPORTIONAL 3

#define FONT_ALIGN_LEFT -1
#define FONT_ALIGN_CENTER 0
#define FONT_ALIGN_RIGHT 1

class CSlrString;

// base abstract class
class CSlrFont : public CSlrResourceBase
{
public:
	CSlrFont();
	CSlrFont(char *name);
	virtual ~CSlrFont();

	char *name;

	byte fontType;
	
	float scaleAdjust;
	
	// override
	virtual void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	virtual void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);
	virtual void BlitTextColor(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
	virtual void BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
	virtual void BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, float advance, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
	virtual void BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, int align);
	virtual void BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha);
	virtual void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	virtual void BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha);
	virtual void BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat alpha);
	virtual void BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size);
	virtual void BlitCharColor(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, float r, float g, float b, float alpha);

	virtual void BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

	virtual void BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

	virtual void BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
				  int align, GLfloat scale);

	virtual void BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
				  int align, GLfloat scale);

	virtual void BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat alpha, int align, GLfloat scale);

	virtual void GetTextSize(char *text, float scale, u16 *width, u16 *height);
	virtual void GetTextSize(char *text, float scale, float *width, float *height);
	virtual void GetTextSize(CSlrString *text, float scale, float *width, float *height);
	virtual void GetTextSize(CSlrString *text, float scale, float advance, float *width, float *height);
	virtual float GetTextWidth(char *text, float scale);
	virtual float GetTextWidth(CSlrString *text, float scale);
	virtual float GetCharWidth(char ch, float scale);
	virtual float GetCharHeight(char ch, float scale);
	
	virtual float GetLineHeight();
	
	virtual void ResourcesPrepare();
	virtual char *ResourceGetTypeName();
};

#endif
//_CSLR_FONT_

