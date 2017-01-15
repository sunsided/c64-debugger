#include "C64AsmSource.h"
#include "CByteBuffer.h"
#include "C64DebugInterface.h"
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "utf8.h"
#include "std_membuf.h"

C64AsmSource::C64AsmSource(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface)
{
	LOGD("C64AsmSource::C64AsmSource");
	
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	std::list<u16> splitChars;
	splitChars.push_back(' ');
	
	// Play with all the lines in the file
	while (getline(reader, line))
	{
		//LOGD(".. line=%d", lineNum);
		// check for invalid utf-8 (for a simple yes/no check, there is also utf8::is_valid function)
		std::string::iterator end_it = utf8::find_invalid(line.begin(), line.end());
		if (end_it != line.end())
		{
			LOGError("Invalid UTF-8 encoding detected at line %d", lineNum);
		}
		
		// Get the line length (at least for the valid part)
		//int length = utf8::distance(line.begin(), end_it);
		//LOGD("========================= Length of line %d is %d", lineNum, length);
		
		// Convert it to utf-16
		std::vector<unsigned short> utf16line;
		utf8::utf8to16(line.begin(), end_it, back_inserter(utf16line));
		
		CSlrString *str = new CSlrString(utf16line);
		//str->DebugPrint("str=");
		
		std::vector<CSlrString *> *words = str->SplitWithChars(splitChars);
		
		if (words->size() == 0)
		{
			lineNum++;
			continue;
		}
		
		//LOGD("words->size=%d", words->size());
		
		CSlrString *command = (*words)[0];
		
		// comment?
		if (command->GetChar(0) == '#')
		{
			lineNum++;
			continue;
		}
		
		command->ConvertToLowerCase();
		
		
		
		///////////////////////////////////////// TODO
		
		
		
		delete str;
		for (int i = 0; i < words->size(); i++)
		{
			delete (*words)[i];
		}
		delete  words;
		
		lineNum++;
	}
	
}
