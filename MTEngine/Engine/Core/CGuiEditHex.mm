#include "CGuiEditHex.h"
#include "CSlrString.h"
#include "SYS_KeyCodes.h"
#include "C64Tools.h"

CGuiEditHex::CGuiEditHex(CGuiEditHexCallback *callback)
{
	this->callback = callback;
	this->text = NULL;
	this->textWithCursor = new CSlrString();
	this->isCapitalLetters = true;
}

void CGuiEditHex::SetValue(int value, int numDigits)
{
	char *buf = SYS_GetCharBuf();
	if (numDigits == 4)
	{
		if (isCapitalLetters)
		{
			sprintf(buf, "%4.4X", value);
		}
		else
		{
			sprintf(buf, "%4.4x", value);
		}
	}
	else if (numDigits == 3)
	{
		if (isCapitalLetters)
		{
			sprintf(buf, "%3.3X", value);
		}
		else
		{
			sprintf(buf, "%2.2x", value);
		}
	}
	else
	{
		if (isCapitalLetters)
		{
			sprintf(buf, "%2.2X", value);
		}
		else
		{
			sprintf(buf, "%2.2x", value);
		}
	}
	
	CSlrString *str = new CSlrString(buf);
	SetText(str);
}

void CGuiEditHex::SetText(CSlrString *str)
{
	if (this->text != NULL)
	{
		delete this->text;
	}
	this->text = str;
	
	cursorPos = 0;
	UpdateCursor();
}

void CGuiEditHex::UpdateValue()
{
	for (int i = 0; i < text->GetLength(); i++)
	{
		u16 chr = this->text->GetChar(i);
		if (chr == '.')
		{
			this->text->SetChar(i, ' ');
		}
	}
	
	char *hexStr = text->GetStdASCII();
	sscanf(hexStr, "%x", &value);
	
	//LOGD("hexStr=%s value=%4.4x", hexStr, value);
	
	delete hexStr;
}

void CGuiEditHex::FinalizeEntering(u32 keyCode, bool isCancelled)
{
	UpdateValue();
	this->callback->GuiEditHexEnteredValue(this, keyCode, isCancelled);
}

void CGuiEditHex::KeyDown(u32 keyCode)
{
	if (keyCode == MTKEY_ENTER)
	{
		FinalizeEntering(keyCode, false);
	}
	else if (keyCode >= '0' && keyCode <= '9')
	{
		this->text->SetChar(cursorPos, keyCode);
		if (cursorPos == text->GetLength()-1)
		{
			FinalizeEntering(keyCode, false);
		}
		else
		{
			cursorPos++;
		}
	}
	else if (keyCode >= 'a' && keyCode <= 'f')
	{
		if (isCapitalLetters)
		{
			this->text->SetChar(cursorPos, keyCode - 0x20);
		}
		else
		{
			this->text->SetChar(cursorPos, keyCode);
		}
		
		if (cursorPos == text->GetLength()-1)
		{
			FinalizeEntering(keyCode, false);
		}
		else
		{
			cursorPos++;
		}
	}
	else if (keyCode == MTKEY_BACKSPACE)
	{
		if (cursorPos > 0)
			cursorPos--;
	}
	else if (keyCode == MTKEY_ARROW_LEFT)
	{
		if (cursorPos > 0)
		{
			cursorPos--;
		}
		else
		{
			FinalizeEntering(keyCode, false);
		}
	}
	else if (keyCode == MTKEY_ARROW_RIGHT)
	{
		if (cursorPos == text->GetLength()-1)
		{
			FinalizeEntering(keyCode, false);
		}
		else
		{
			cursorPos++;
		}
	}
	
	UpdateCursor();
	return;
}

void CGuiEditHex::UpdateCursor()
{
	textWithCursor->Clear();
	for (int i = 0; i < text->GetLength(); i++)
	{
		u16 chr = text->GetChar(i);
		if (cursorPos == i)
		{
			chr += CBMSHIFTEDFONT_INVERT;
		}
		textWithCursor->Concatenate(chr);
	}
}
