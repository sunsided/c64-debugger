#ifndef _CGUIEDITHEX_H_
#define _CGUIEDITHEX_H_

#include "CGuiElement.h"

class CGuiEditHex;
class CSlrString;

class CGuiEditHexCallback
{
public:
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled) {};
};

class CGuiEditHex //: public CGuiElement
{
public:
	CGuiEditHex(CGuiEditHexCallback *callback);
//	CGuiEditHex(float posX, float posY, float posZ, float sizeX, float sizeY);

	void SetValue(int value, int numDigits);
	void SetText(CSlrString *str);
	
	CSlrString *text;
	CSlrString *textWithCursor;
	
	bool isCapitalLetters;
	
	int cursorPos;
	
	unsigned int value;
	
	void KeyDown(u32 keyCode);
	void FinalizeEntering(u32 keyCode, bool isCancelled);
	void UpdateValue();
	void SetCursorPos(int newPos);
	void UpdateCursor();
	
	CGuiEditHexCallback *callback;
};

#endif
