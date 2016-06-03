#include "CSlrTextParser.h"
#include "SYS_Main.h"
#include "SYS_Funct.h"

CSlrTextParser::CSlrTextParser(char *text)
{
	this->text = text;
	this->textLength = strlen(text);
	this->textIndex = 0;
}

void CSlrTextParser::ToLower()
{
	for (int i = 0; i < textLength; i++)
	{
		this->text[i] = tolower(this->text[i]);
	}
}

void CSlrTextParser::ToUpper()
{
	for (int i = 0; i < textLength; i++)
	{
		this->text[i] = toupper(this->text[i]);
	}
}

bool CSlrTextParser::IsEof()
{
	if (this->textIndex == this->textLength)
		return true;
	
	return false;
}

char CSlrTextParser::GetChar()
{
	//LOGD("CSlrTextParser::GetChar: textIndex=%d textLength=%d", textIndex, textLength);
	if (textIndex == textLength)
		return 0x00;
	
	char c = text[textIndex];
	textIndex++;
	
	//LOGD("CSlrTextParser::GetChar: (return) textIndex=%d textLength=%d c=%2.2x '%c'", textIndex, textLength, c, c);
	
	return c;
}

void CSlrTextParser::GetChars(char *buf, int numChars)
{
	for (int i = 0; i < numChars; i++)
	{
		buf[i] = GetChar();
	}
}

int CSlrTextParser::GetIntNumber()
{
	char buf[32] = {0};
	
	for (int i = 0; i < 32; i++)
	{
		char c = GetChar();
		if (FUN_IsNumber(c))
		{
			buf[i] = c;
		}
		else
		{
			break;
		}
	}
	
	if (buf[0] == 0x00)
	{
		LOGError("CSlrTextParser::GetNumber: number buffer empty");
		return -1;
	}
	
	return atoi(buf);
}

int CSlrTextParser::GetHexNumber()
{
	char buf[9] = {0};
	
	for (int i = 0; i < 9; i++)
	{
		if (IsEof())
			break;
		
		char c = GetChar();
		if (FUN_IsHexNumber(c))
		{
			buf[i] = tolower(c);
		}
		else
		{
			ScrollBack();
			break;
		}
	}
	
	if (buf[0] == 0x00)
	{
		LOGError("CSlrTextParser::GetNumber: number buffer empty");
		return -1;
	}
	
	int val = 0;
	
	sscanf(buf, "%x", &val);
	return val;
}

void CSlrTextParser::ScrollBack()
{
	if (textIndex == 0)
	{
		LOGError("CSlrTextParser::ScrollBack: already at the beginning");
		return;
	}
	
	textIndex--;
}

void CSlrTextParser::ScrollWhiteChars()
{
	if (textIndex == textLength)
		return;
	
	while (true)
	{
		char c = GetChar();
		if (c == ' ' || c == '\t')
			continue;
		
		break;
	}
	
	ScrollBack();
}


