#include "C64Symbols.h"
#include "CByteBuffer.h"
#include "CSlrString.h"
#include "CSlrFileFromOS.h"
#include "SYS_Threading.h"
#include "C64DebugInterface.h"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "utf8.h"
#include "std_membuf.h"

C64Symbols::C64Symbols()
{
}

C64Symbols::~C64Symbols()
{
}

void C64Symbols::ParseSymbols(CByteBuffer *byteBuffer)
{
	
}

void C64Symbols::ParseBreakpoints(char *fileName, C64DebugInterface *debugInterface)
{
	CSlrFileFromOS *file = new CSlrFileFromOS(fileName);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseBreakpoints: file %s does not exist", fileName);
		return;
	}
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseBreakpoints(byteBuffer, debugInterface);
	
	delete byteBuffer;
	delete file;
}

void C64Symbols::ParseBreakpoints(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface)
{
	LOGM("C64Symbols::ParseBreakpoints");
	
	debugInterface->LockMutex();
	
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	std::list<u16> splitChars;
	splitChars.push_back(' ');
	splitChars.push_back('<');
	splitChars.push_back('>');
	splitChars.push_back('=');
	splitChars.push_back('!');
	splitChars.push_back('#');
	
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
		
		if (command->Equals("break") || command->Equals("breakpc") || command->Equals("breakonpc"))
		{
			if (words->size() < 3)
			{
				LOGError("ParseBreakpoints: error in line %d", lineNum);
				break;
			}
			
			// pc breakpoint
			CSlrString *arg = (*words)[2];
			//arg->DebugPrint(" arg=");
			int address = arg->ToIntFromHex();
			
			LOGD(".. adding breakOnPC %4.4x", address);
			
			C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(address);
			debugInterface->breakpointsC64PC[address] = addrBreakpoint;
			
			debugInterface->breakOnC64PC = true;
		}
		else if (command->Equals("breakraster") || command->Equals("breakonraster"))
		{
			if (words->size() < 3)
			{
				LOGError("ParseBreakpoints: error in line %d", lineNum);
				break;
			}
			
			// raster breakpoint
			CSlrString *arg = (*words)[2];
			//arg->DebugPrint(" arg=");
			int rasterNum = arg->ToIntFromHex();
			
			LOGD(".. adding breakOnRaster %4.4x", rasterNum);
			
			C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(rasterNum);
			debugInterface->breakpointsC64Raster[rasterNum] = addrBreakpoint;
			
			debugInterface->breakOnC64Raster = true;
		}
		else if (command->Equals("breakvic") || command->Equals("breakonvic") || command->Equals("breakonirqvic"))
		{
			debugInterface->breakOnC64IrqVIC = true;
			LOGD(".. adding breakOnC64IrqVIC");
		}
		else if (command->Equals("breakcia") || command->Equals("breakoncia") || command->Equals("breakonirqcia"))
		{
			debugInterface->breakOnC64IrqCIA = true;
			LOGD(".. adding breakOnC64IrqCIA");
		}
		else if (command->Equals("breaknmi") || command->Equals("breakonnmi") || command->Equals("breakonirqnmi"))
		{
			debugInterface->breakOnC64IrqNMI = true;
			LOGD(".. adding breakOnC64IrqNMI");
		}
		else if (command->Equals("breakmemory") || command->Equals("breakonmemory") || command->Equals("breakmem"))
		{
			if (words->size() < 4)
			{
				LOGError("ParseBreakpoints: error in line %d", lineNum);
				break;
			}
			
			CSlrString *addressStr = (*words)[2];
			//addressStr->DebugPrint(" addressStr=");
			int address = addressStr->ToIntFromHex();

			int index = 3;
			CSlrString *op = new CSlrString();
			
			while (index < words->size()-1)
			{
				CSlrString *f = (*words)[index];
				f->ConvertToLowerCase();
				
			//	f->DebugPrint(".... f= ");

				u16 chr = f->GetChar(0);
				if (chr == ' ')
				{
					index++;
					continue;
				}
				
				if ( (chr >= '0' && chr <= '9') || (chr >= 'a' && chr <= 'f') )
				{
					break;
				}
				
				op->Concatenate(f);
				
				index++;
			}
			
			if (index >= words->size())
			{
				LOGError("ParseBreakpoints: error in line %d", lineNum);
				break;
			}
			
			CSlrString *arg = (*words)[index];
			//arg->DebugPrint(" arg=");
			
			int value = arg->ToIntFromHex();

			int memBreakType = -1;
			
			if (op->Equals("==") || op->Equals("="))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_EQUAL;
			}
			else if (op->Equals("!="))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_NOT_EQUAL;
			}
			else if (op->Equals("<"))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_LESS;
			}
			else if (op->Equals("<=") || op->Equals("=<"))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_LESS_OR_EQUAL;
			}
			else if (op->Equals(">"))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_GREATER;
			}
			else if (op->Equals(">=") || op->Equals("=>"))
			{
				memBreakType = C64_MEMORY_BREAKPOINT_GREATER_OR_EQUAL;
			}
			else
			{
				LOGError("ParseBreakpoints: error in line %d (unknown operator for memory breakpoint)", lineNum);
				break;
			}

			LOGD(".. adding breakOnMemory");
			LOGD("..... addr=%4.4x", address);
			op->DebugPrint("..... op=");
			LOGD("..... value=%2.2x", value);
			
			C64MemoryBreakpoint *memBreakpoint = new C64MemoryBreakpoint(address, memBreakType, value);
			debugInterface->breakpointsC64Memory[address] = memBreakpoint;
			
			debugInterface->breakOnC64Memory = true;
		}
		else
		{
			LOGError("ParseBreakpoints: error in line %d (unknown breakpoint type)", lineNum);
			break;
		}
		
		delete str;
		for (int i = 0; i < words->size(); i++)
		{
			delete (*words)[i];
		}
		delete  words;
		
		lineNum++;
	}
	
	debugInterface->UnlockMutex();
	
	LOGD("C64Symbols::ParseBreakpoints: done");
}
