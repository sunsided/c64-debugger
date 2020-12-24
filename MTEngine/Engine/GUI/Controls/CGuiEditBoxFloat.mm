#include "CGuiEditBoxFloat.h"
#include "CGuiMain.h"

CGuiEditBoxFloat::CGuiEditBoxFloat(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
				 float defaultValue, byte maxDigitsL, byte maxDigitsR, bool readOnly,
				 CGuiEditBoxTextCallback *callback)
: CGuiEditBoxText(posX, posY, posZ, fontWidth, fontHeight, "", maxDigitsL+maxDigitsR+10, readOnly, callback)

{
	this->type = TEXTBOX_TYPE_FLOAT;

	this->maxDigitsL = maxDigitsL;
	this->maxDigitsR = maxDigitsR;

	this->SetFloat(defaultValue);
}

CGuiEditBoxFloat::CGuiEditBoxFloat(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat fontWidth, GLfloat fontHeight,
				 float defaultValue, byte maxDigitsL, byte maxDigitsR, byte maxNumChars, bool readOnly,
				 CGuiEditBoxTextCallback *callback)
: CGuiEditBoxText(posX, posY, posZ, fontWidth, fontHeight, "", maxNumChars, readOnly, callback)

{
	this->type = TEXTBOX_TYPE_FLOAT;

	this->maxDigitsL = maxDigitsL;
	this->maxDigitsR = maxDigitsR;

	this->SetFloat(defaultValue);
}

void CGuiEditBoxFloat::SetFloat(float value)
{
	this->value = value;

	char format[32];
	sprintf(format, "%%+%d.%0df", maxDigitsL+maxDigitsR+1, maxDigitsR);

#if !defined(WIN32)
	snprintf(textBuffer, maxDigitsL+maxDigitsR+5, format, value);
#else
	sprintf(textBuffer, format, value);
#endif
	//LOGD("value=%3.2f", value);

	//LOGD("textBuffer='%s'", textBuffer);

	this->currentPos = strlen(this->textBuffer);
	this->numChars = strlen(this->textBuffer);
	//guiMain->UnlockRenderMutex();

	this->SetSize((fontWidth*(GLfloat)maxNumChars*gapX), (fontHeight*gapY));
}

float CGuiEditBoxFloat::GetFloat()
{
	return this->value;
}

bool CGuiEditBoxFloat::KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl)
{
	if (this->editing == false)
		return false;

//	LOGD("keyCode=%2.2x", keyCode);
	if (keyCode == 0x60)	// `
	{
		textBuffer[0] = '\0';
		this->currentPos = 0;
		this->numChars = 0;
	}
	else if ((keyCode >= 0x30 && keyCode <= 0x3A)
		|| keyCode == '.' || keyCode == '-'
		|| keyCode == 0x08
		|| keyCode == 0x0D)
	{
		CGuiEditBoxText::KeyPressed(keyCode, isShift, isAlt, isControl);
		this->value = atof(this->textBuffer);
	}

	return true;
}

