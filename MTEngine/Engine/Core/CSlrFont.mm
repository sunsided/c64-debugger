/*
 *  CSlrFont.mm
 *  MusicTracker
 *
 *  Created by Marcin Skoczylas on 11-04-04.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#include "CSlrFont.h"
#include "CSlrString.h"

CSlrFont::CSlrFont()
{
	this->name = NULL;
	this->resourceType = RESOURCE_TYPE_FONT;
	this->fontType = FONT_TYPE_UNKNOWN;
}

CSlrFont::CSlrFont(char *name)
{
	LOGR("CSlrFont::CSlrFont: name='%s'", name);
	this->name = strdup(name);
	this->resourceType = RESOURCE_TYPE_FONT;
	this->fontType = FONT_TYPE_UNKNOWN;
}

void CSlrFont::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size)
{
	SYS_FatalExit("CSlrFont::BlitText (1) not implemented");
}

void CSlrFont::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitText (2) not implemented");
}

void CSlrFont::BlitTextColor(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitTextColor (2) not implemented");
}

void CSlrFont::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitTextColor (3) not implemented");
}

void CSlrFont::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, float advance, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitTextColor (4) not implemented");
}

void CSlrFont::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, int align)
{
	SYS_FatalExit("CSlrFont::BlitTextColor (5) not implemented");	
}

void CSlrFont::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontSizeX, GLfloat fontSizeY, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitText (3) not implemented");
}

void CSlrFont::BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size)
{
	SYS_FatalExit("CSlrFont::BlitText (4) not implemented");
}


void CSlrFont::BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitText (5) not implemented");
}

void CSlrFont::BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat alpha)
{
	SYS_FatalExit("CSlrFont::BlitChar (6) not implemented");
	
}
void CSlrFont::BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size)
{
	SYS_FatalExit("CSlrFont::BlitChar (7) not implemented");
}

void CSlrFont::BlitCharColor(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, float r, float g, float b, float alpha)
{
	SYS_FatalExit("CSlrFont::BlitChar (8) not implemented");
}

void CSlrFont::BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	this->BlitText(text, x, y, z, colorR, colorG, colorB, alpha, FONT_ALIGN_LEFT, 1.0f);
}

void CSlrFont::BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
				  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	this->BlitText(text, x, y, z, colorR, colorG, colorB, alpha, FONT_ALIGN_LEFT, 1.0f);
}

void CSlrFont::BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
			  int align = FONT_ALIGN_LEFT, GLfloat scale = 1.0f)
{
	SYS_FatalExit("CSlrFont::BlitText (6) not implemented");
}

void CSlrFont::BlitText(UTFString *text, GLfloat x, GLfloat y, GLfloat z,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
			  int align = FONT_ALIGN_LEFT, GLfloat scale = 1.0f)
{
	SYS_FatalExit("CSlrFont::BlitText (7) not implemented");
}

void CSlrFont::BlitText(const std::string &text, GLfloat x, GLfloat y, GLfloat z,
			  GLfloat alpha, int align, GLfloat scale)
{
	SYS_FatalExit("CSlrFont::BlitText (8) not implemented");
}

float CSlrFont::GetCharWidth(char text, float scale)
{
	SYS_FatalExit("CSlrFont::GetCharWidth not implemented");
	return 0;
}

float CSlrFont::GetCharHeight(char ch, float scale)
{
	SYS_FatalExit("CSlrFont::GetCharHeight not implemented");
	return 0;
}

float CSlrFont::GetTextWidth(char *text, float scale)
{
	SYS_FatalExit("CSlrFont::GetTextWidth not implemented");
	return 0;
}

float CSlrFont::GetTextWidth(CSlrString *text, float scale)
{
	SYS_FatalExit("CSlrFont::GetTextWidth not implemented (2)");
	return 0;
}

void CSlrFont::GetTextSize(char *text, float scale, u16 *width, u16 *height)
{
	SYS_FatalExit("CSlrFont::GetTextSize not implemented");
}

void CSlrFont::GetTextSize(char *text, float scale, float *width, float *height)
{
	SYS_FatalExit("CSlrFont::GetTextSize (2) not implemented");
}

void CSlrFont::GetTextSize(CSlrString *text, float scale, float *width, float *height)
{
	SYS_FatalExit("CSlrFont::GetTextSize (3) not implemented");
}

void CSlrFont::GetTextSize(CSlrString *text, float scale, float advance, float *width, float *height)
{
	SYS_FatalExit("CSlrFont::GetTextSize (4) not implemented");
}

float CSlrFont::GetLineHeight()
{
	SYS_FatalExit("CSlrFont::GetLineHeight not implemented");
	return 0.0f;
}

void CSlrFont::ResourcesPrepare()
{
	SYS_FatalExit("CSlrFont::ResourcesPrepare: not implemented");
}

char *CSlrFont::ResourceGetTypeName()
{
	return "font";
}

CSlrFont::~CSlrFont()
{
	free(name);
}


