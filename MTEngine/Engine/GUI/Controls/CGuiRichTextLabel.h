/*
 *  CGuiLabel.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 10-01-07.
 *  Copyright 2010 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef _GUI_MULTILINE_LABEL_
#define _GUI_MULTILINE_LABEL_

#include "CGuiElement.h"
#include "CSlrImage.h"
#include "SYS_Main.h"
#include "CSlrString.h"
#include "CSlrFont.h"
#include "CContinuousParam.h"
#include "CPool.h"

#define RICH_TEXT_USE_ELEMENTS_POOL
#define RICH_TEXT_ELEMENTS_POOL	10000

#define RICH_TEXT_LABEL_ALIGNMENT_LEFT		1
#define RICH_TEXT_LABEL_ALIGNMENT_RIGHT		2
#define RICH_TEXT_LABEL_ALIGNMENT_JUSTIFY	3
#define RICH_TEXT_LABEL_ALIGNMENT_CENTER	4

#define RICH_TEXT_LABEL_ELEMENT_TYPE_UNKNOWN		0
#define RICH_TEXT_LABEL_ELEMENT_TYPE_TEXT			1
#define RICH_TEXT_LABEL_ELEMENT_TYPE_IMAGE			2
#define RICH_TEXT_LABEL_ELEMENT_TYPE_LINE_BREAK		3

#define RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_OFF		0
#define RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_LINEAR	1
#define RICH_TEXT_LABEL_ELEMENT_BLINK_MODE_SINUS	2

class CGuiRichTextLabelCallback;

class CGuiRichTextLabelElement
{
public:
	CGuiRichTextLabelElement();
	CGuiRichTextLabelElement(float x, float y, float z, float textWidth, float fontHeight, float spaceWidth, float gapHeight, byte alignment, byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames);
	virtual void DoLogic();
	virtual void Render();
	virtual ~CGuiRichTextLabelElement();
	virtual void UpdatePos(float x, float y, float z);

	byte type;

	float x, y, z;
	float textWidth;
	float spaceWidth;
	float fontHeight;
	float gapHeight;
	byte alignment;
	
	byte blinkMode;
	float blinkParamMin;
	float blinkParamMax;
	u32 blinkParamNumFrames;
	CContinuousParam *blinkParam;
	void InitBlink();
	
#ifdef RICH_TEXT_USE_ELEMENTS_POOL
private:
	static CPool poolElements;
public:
	static void* operator new(const size_t size) { return poolElements.New(size); }
	static void operator delete(void* pObject) { poolElements.Delete(pObject); }
#endif
};

class CGuiRichTextLabelElementText : public CGuiRichTextLabelElement
{
public:
	CGuiRichTextLabelElementText(CSlrString *str, CSlrFont *font, float x, float y, float z, float r, float g, float b, float a, float scale,
		 float fontHeight, float spaceWidth, float gapHeight, byte alignment,
		 byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames);
	virtual void Render();
	virtual ~CGuiRichTextLabelElementText();
	CSlrString *text;
	CSlrFont *font;
	float r;
	float g;
	float b;
	float a;
	float scale;
	
#ifdef RICH_TEXT_USE_ELEMENTS_POOL
private:
	static CPool poolElementsText;
public:
	static void* operator new(const size_t size) { return poolElementsText.New(size); }
	static void operator delete(void* pObject) { poolElementsText.Delete(pObject); }
#endif
	
};

class CGuiRichTextLabelElementImage : public CGuiRichTextLabelElement
{
public:
	CGuiRichTextLabelElementImage(CSlrImage *image,
			float x, float y, float z, float sizeX, float sizeY, float offsetX, float offsetY,
			float spaceWidth, float gapHeight, byte alignment,
			byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames);
	virtual void Render();
	virtual ~CGuiRichTextLabelElementImage();

	CSlrImage *image;
	float offsetX;
	float offsetY;
	virtual void UpdatePos(float x, float y, float z);
	
#ifdef RICH_TEXT_USE_ELEMENTS_POOL
private:
	static CPool poolElementsImage;
public:
	static void* operator new(const size_t size) { return poolElementsImage.New(size); }
	static void operator delete(void* pObject) { poolElementsImage.Delete(pObject); }
#endif
	
};

class CGuiRichTextLabelElementLineBreak : public CGuiRichTextLabelElement
{
public:
	CGuiRichTextLabelElementLineBreak(float fontHeight, float spaceWidth, float gapHeight, byte alignment,
									  byte blinkMode, float blinkParamMin, float blinkParamMax, u32 blinkParamNumFrames);
	virtual void Render();
	virtual ~CGuiRichTextLabelElementLineBreak();
	
#ifdef RICH_TEXT_USE_ELEMENTS_POOL
private:
	static CPool poolElementsLineBreak;
public:
	static void* operator new(const size_t size) { return poolElementsLineBreak.New(size); }
	static void operator delete(void* pObject) { poolElementsLineBreak.Delete(pObject); }
#endif
};


class CGuiRichTextLabel : public CGuiElement
{
public:
	CGuiRichTextLabel(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float scale, CGuiRichTextLabelCallback *callback);
	CGuiRichTextLabel(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, float scale, CGuiRichTextLabelCallback *callback);
	
	void Init();
	
	virtual ~CGuiRichTextLabel();
	void Render();
	void Render(GLfloat posX, GLfloat posY);

	bool DoTap(GLfloat x, GLfloat y);
	bool DoFinishTap(GLfloat x, GLfloat y);
	bool DoDoubleTap(GLfloat x, GLfloat y);
	bool DoFinishDoubleTap(GLfloat x, GLfloat y);
	bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	void FinishTouches();
	void DoLogic();

	void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	void SetParameters(CSlrFont *font, float scale, float r, float g, float b, float a, byte alignment);
	void SetPositionNoParse(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	void SetParametersNoParse(CSlrFont *font, float scale, float r, float g, float b, float a, byte alignment);

	bool clickConsumed;
	bool beingClicked;

	// overwrite this
	virtual bool Clicked(GLfloat posX, GLfloat posY);
	virtual bool Pressed(GLfloat posX, GLfloat posY);

	void SetText(const char *text);
	void SetText(CSlrString *text);
	
	CSlrString *text;

	GLfloat scale;
	bool transparentToTaps;

	void Parse();
	std::list<CGuiRichTextLabelElement *> elements;

	CGuiRichTextLabelCallback *callback;

private:
	std::list<u16> tagStopChars;
	std::list<u16> tagOpenStopChars;
	std::list<u16> whiteSpaceChars;

	CSlrFont *currentFont;
	float currentFontScale;

	float startFontColorR;
	float startFontColorG;
	float startFontColorB;
	float startFontColorA;

	float currentFontColorR;
	float currentFontColorG;
	float currentFontColorB;
	float currentFontColorA;

	float currentX;
	float currentY;

	float currentSpaceWidth;
	float currentFontHeight;
	float currentGapHeight;

	byte currentAlignment;
	
	byte currentBlinkMode;
	float currentBlinkParamMin;
	float currentBlinkParamMax;
	u32 currentBlinkParamNumFrames;
	
	void UpdateFont();

	void AddTextElements(CSlrString *str);
	void MakeTextLayout();

	float bx1, by1, bx2, by2;

	std::list<CGuiRichTextLabelElement *> textElements;

	std::list<CSlrString *> tags;
	std::list<CSlrString *> vals;

	bool TagExists(char *tagName);
	CSlrString *GetValueForTag(char *tagName);
	float GetFloatValueForTag(char *tagName, float defaultValue);
	int GetIntValueForTag(char *tagName, int defaultValue);

	void AddElement(CGuiRichTextLabelElement *el);
	
	void DeleteElements();
};

class CGuiRichTextLabelCallback
{
public:
	virtual bool RichTextLabelClicked(CGuiRichTextLabel *label);
	virtual bool RichTextLabelPressed(CGuiRichTextLabel *label);
};



#endif
//_GUI_BUTTON_

