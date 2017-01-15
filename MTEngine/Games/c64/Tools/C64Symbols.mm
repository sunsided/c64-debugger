#include "C64Symbols.h"
#include "CByteBuffer.h"
#include "CSlrString.h"
#include "CSlrFileFromOS.h"
#include "SYS_Threading.h"
#include "C64DebugInterface.h"
#include "SYS_Main.h"
#include "CViewC64.h"
#include "CViewDisassemble.h"
#include "CViewBreakpoints.h"
#include "C64AsmSource.h"

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

void C64Symbols::ParseSymbols(CSlrString *fileName, C64DebugInterface *debugInterface)
{
	char *fname = fileName->GetStdASCII();
	CSlrFileFromOS *file = new CSlrFileFromOS(fname);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseSymbols: file %s does not exist", fname);
		delete [] fname;
		return;
	}
	delete [] fname;
	
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseSymbols(byteBuffer, debugInterface);
	
	delete byteBuffer;
	delete file;
}

void C64Symbols::ClearSymbols(C64DebugInterface *debugInterface)
{
	debugInterface->LockMutex();

	viewC64->viewC64Disassemble->ClearCodeLabels();
	viewC64->viewDrive1541Disassemble->ClearCodeLabels();
	
	debugInterface->UnlockMutex();
}

void C64Symbols::ParseSymbols(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface)
{
	LOGM("C64Symbols::ParseSymbols");
	
	debugInterface->LockMutex();
	
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
		
		if (command->Equals("al"))
		{
			if (words->size() < 5)
			{
				LOGError("ParseSymbols: error in line %d", lineNum);
				break;
			}
			
			CSlrString *deviceAndAddr = (*words)[2];
			CSlrString *labelName = (*words)[4];
			
			deviceAndAddr->DebugPrint("deviceAndAddr=");
			int deviceId = 0;
			
			char deviceIdChar = deviceAndAddr->GetChar(0);
			
			if (deviceIdChar == 'C' || deviceIdChar == 'c')
			{
				deviceId = C64_SYMBOL_DEVICE_COMMODORE;
			}
			else if (deviceIdChar == 'D' || deviceIdChar == 'd')
			{
				deviceId = C64_SYMBOL_DEVICE_DRIVE1541;
			}
			else
			{
				LOGError("ParseSymbols: unknown device in line %d", lineNum);
				break;
			}
			
			char addrStr[5];
			addrStr[0] = deviceAndAddr->GetChar(2);
			addrStr[1] = deviceAndAddr->GetChar(3);
			addrStr[2] = deviceAndAddr->GetChar(4);
			addrStr[3] = deviceAndAddr->GetChar(5);
			addrStr[4] = 0x00;
			
			int addr;
			sscanf(addrStr, "%x", &addr);

			LOGD("addr=%x", addr);
			
			// remove leading dot
			if (labelName->GetChar(0) == '.')
			{				
				labelName->RemoveCharAt(0);
			}
			
			labelName->DebugPrint("labelName=");

			char *labelNameStr = labelName->GetStdASCII();
			
			if (deviceId == C64_SYMBOL_DEVICE_COMMODORE)
			{
				viewC64->viewC64Disassemble->AddCodeLabel(addr, labelNameStr);
			}
			else if (deviceId == C64_SYMBOL_DEVICE_DRIVE1541)
			{
				viewC64->viewDrive1541Disassemble->AddCodeLabel(addr, labelNameStr);
			}
		}
		else
		{
			LOGError("ParseSymbols: error in line %d (unknown label type)", lineNum);
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
	
	LOGD("C64Symbols::ParseSymbols: done");
}


void C64Symbols::ClearBreakpoints(C64DebugInterface *debugInterface)
{
	viewC64->debugInterface->LockMutex();
	viewC64->debugInterface->ClearBreakpoints();
	viewC64->debugInterface->UnlockMutex();
}

void C64Symbols::ParseBreakpoints(CSlrString *fileName, C64DebugInterface *debugInterface)
{
	char *fname = fileName->GetStdASCII();
	CSlrFileFromOS *file = new CSlrFileFromOS(fname);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseBreakpoints: file %s does not exist", fname);
		delete [] fname;
		return;
	}
	delete [] fname;
	
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
			
			std::map<uint16, C64AddrBreakpoint *>::iterator it = debugInterface->breakpointsC64PC.find(address);
			if (it == debugInterface->breakpointsC64PC.end())
			{
				// not found
				C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(address);
				addrBreakpoint->actions = C64_ADDR_BREAKPOINT_ACTION_STOP;
				debugInterface->breakpointsC64PC[address] = addrBreakpoint;
				
				debugInterface->breakOnC64PC = true;
			}
			else
			{
				LOGD("...... exists %4.4x", address);
				C64AddrBreakpoint *addrBreakpoint = it->second;
				SET_BIT(addrBreakpoint->actions, C64_ADDR_BREAKPOINT_ACTION_STOP);
			}
		}
		else if (command->Equals("setbkg") || command->Equals("setbackground"))
		{
			if (words->size() < 5)
			{
				LOGError("ParseBreakpoints: error in line %d", lineNum);
				break;
			}
			
			// pc breakpoint
			CSlrString *arg = (*words)[2];
			//arg->DebugPrint(" arg=");
			int address = arg->ToIntFromHex();
			
			arg = (*words)[4];
			int value = arg->ToIntFromHex();
			
			LOGD(".. adding setBkg %4.4x %2.2x", address, value);
			
			std::map<uint16, C64AddrBreakpoint *>::iterator it = debugInterface->breakpointsC64PC.find(address);
			if (it == debugInterface->breakpointsC64PC.end())
			{
				// not found
				C64AddrBreakpoint *addrBreakpoint = new C64AddrBreakpoint(address);
				addrBreakpoint->actions = C64_ADDR_BREAKPOINT_ACTION_SET_BACKGROUND;
				addrBreakpoint->data = value;
				debugInterface->breakpointsC64PC[address] = addrBreakpoint;
				
				debugInterface->breakOnC64PC = true;
			}
			else
			{
				LOGD("...... exists %4.4x", address);
				C64AddrBreakpoint *addrBreakpoint = it->second;
				addrBreakpoint->data = value;
				SET_BIT(addrBreakpoint->actions, C64_ADDR_BREAKPOINT_ACTION_SET_BACKGROUND);
			}
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
	
	viewC64->viewC64Breakpoints->UpdateRenderBreakpoints();
	
	LOGD("C64Symbols::ParseBreakpoints: done");
}

///

void C64Symbols::ParseSourceDebugInfo(CSlrString *fileName, C64DebugInterface *debugInterface)
{
	char *fname = fileName->GetStdASCII();
	CSlrFileFromOS *file = new CSlrFileFromOS(fname);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseSourceDebugInfo: file %s does not exist", fname);
		delete [] fname;
		return;
	}
	delete [] fname;
	
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseSourceDebugInfo(byteBuffer, debugInterface);
	
	delete byteBuffer;
	delete file;
}

void C64Symbols::ClearSourceDebugInfo(C64DebugInterface *debugInterface)
{
	debugInterface->LockMutex();
	
	delete this->asmSource;
	this->asmSource = NULL;
	
	debugInterface->UnlockMutex();
}

void C64Symbols::ParseSourceDebugInfo(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface)
{
	LOGM("C64Symbols::ParseSourceDebugInfo");
	
	debugInterface->LockMutex();
	
	if (this->asmSource != NULL)
	{
		delete this->asmSource;
		asmSource = NULL;
	}
	
	this->asmSource = new C64AsmSource(byteBuffer, debugInterface);
	
	
	debugInterface->UnlockMutex();
	
	LOGD("C64Symbols::ParseSymbols: done");
}

