#include "CGuiEditBoxInt.h"

CGuiEditBoxInt::CGuiEditBoxInt(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
								   int defaultValue, byte maxDigits, bool readOnly,
								   CGuiEditBoxTextCallback *callback)
: CGuiEditBoxText(posX, posY, posZ, fontWidth, fontHeight, "", maxDigits+1, readOnly, callback)

{
	this->type = TEXTBOX_TYPE_INT;

	this->maxDigits = maxDigits;

	this->SetInteger(defaultValue);
}


void CGuiEditBoxInt::SetInteger(int value)
{
	this->value = value;

	char format[32];
	sprintf(format, "%%%dd", maxDigits);

	sprintf(textBuffer, format, value);

	this->currentPos = strlen(this->textBuffer);
	this->numChars = strlen(this->textBuffer);
	//guiMain->UnlockRenderMutex();

	this->SetSize((fontWidth*(GLfloat)maxNumChars*gapX), (fontHeight*gapY));
}

int CGuiEditBoxInt::GetInteger()
{
	return this->value;
}

bool CGuiEditBoxInt::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (this->editing == false)
		return false;

	if (keyCode == 0x60)	// `
	{
		textBuffer[0] = '\0';
		this->currentPos = 0;
		this->numChars = 0;
	}
	else if ((keyCode >= 0x30 && keyCode <= 0x3A)
		|| keyCode == '-'
		|| keyCode == 0x08 || keyCode == 0x0D)
	{
		CGuiEditBoxText::KeyPressed(keyCode, isShift,isAlt, isControl);
		this->value = atoi(this->textBuffer);
	}

	return true;
}
