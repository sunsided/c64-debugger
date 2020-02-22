#ifndef _CSLRTEXTPARSER_H_
#define _CSLRTEXTPARSER_H_

#include "SYS_Defs.h"

class CSlrTextParser
{
public:
	CSlrTextParser(char *text);
	char *text;
	int textLength;
	int textIndex;

	void ToLower();
	void ToUpper();
	
	bool IsEof();
	
	char GetChar();
	void GetChars(char *buf, int numChars);
	int GetIntNumber();
	int GetHexNumber();
	
	void ScrollBack();
	void ScrollWhiteChars();
};

#endif

