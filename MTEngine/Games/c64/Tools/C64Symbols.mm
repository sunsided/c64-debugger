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
#include "C64AsmSourceSymbols.h"
#include "CViewDataWatch.h"
#include "CGuiMain.h"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "utf8.h"
#include "std_membuf.h"

C64Symbols::C64Symbols(CDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
	this->asmSource = NULL;
}

C64Symbols::~C64Symbols()
{
}

void C64Symbols::ParseSymbols(CSlrString *fileName)
{
	char *fname = fileName->GetStdASCII();
	
	LOGD("C64Symbols::ParseSymbols: %s", fname);
	
	CSlrFileFromOS *file = new CSlrFileFromOS(fname);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseSymbols: file %s does not exist", fname);
		delete [] fname;
		return;
	}
	delete [] fname;

	ParseSymbols(file);

	delete file;
}

void C64Symbols::ParseSymbols(CSlrFile *file)
{
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseSymbols(byteBuffer);
	
	delete byteBuffer;
}

void C64Symbols::DeleteAllSymbols()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();

	CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
	CViewDisassemble *viewDisassembleDrive = debugInterface->GetViewDriveDisassemble(0);

	if (viewDisassembleMainCpu)
	{
		viewDisassembleMainCpu->DeleteCodeLabels();
	}

	if (viewDisassembleDrive)
	{
		viewDisassembleDrive->DeleteCodeLabels();
	}

	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64Symbols::ParseSymbols(CByteBuffer *byteBuffer)
{
	LOGM("C64Symbols::ParseSymbols");
	
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	if (byteBuffer->length < 8)
	{
		LOGError("Empty symbols file");
		debugInterface->UnlockMutex();
		guiMain->UnlockMutex();
		return;
	}
	
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	std::list<u16> splitChars;
	splitChars.push_back(' ');
	splitChars.push_back('\t');
	splitChars.push_back('=');
	
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
		
//		LOGD("LINE #%d", lineNum);
		CSlrString *str = new CSlrString(utf16line);
//		str->DebugPrint("str=");
		
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
		
		if (words->size() >= 5 && (command->Equals("al") || command->Equals("AL")))
		{
//			if (words->size() < 5)
//			{
//				LOGError("ParseSymbols: error in line %d", lineNum);
//				break;
//			}
			
			CSlrString *deviceAndAddr = (*words)[2];
			CSlrString *labelName = (*words)[4];
			
//			deviceAndAddr->DebugPrint("deviceAndAddr=");
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

//			LOGD("addr=%x", addr);
			
			// remove leading dot
			if (labelName->GetChar(0) == '.')
			{				
				labelName->RemoveCharAt(0);
			}
			
//			labelName->DebugPrint("labelName=");

			char *labelNameStr = labelName->GetStdASCII();
			
			LOGD("labelNameStr=%s  addr=%04x", labelNameStr, addr);

			CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
			CViewDisassemble *viewDisassembleDrive = debugInterface->GetViewDriveDisassemble(0);

			if (deviceId == C64_SYMBOL_DEVICE_COMMODORE)
			{
				if (viewDisassembleMainCpu)
				{
					viewDisassembleMainCpu->AddNewCodeLabel(addr, labelNameStr);
				}
			}
			else if (deviceId == C64_SYMBOL_DEVICE_DRIVE1541)
			{
				if (viewDisassembleDrive)
				{
					viewDisassembleDrive->AddNewCodeLabel(addr, labelNameStr);
				}
			}
		}
		else if (words->size() > 3)
		{
			// assume tass64 label
			// example: DRIVERDONE      = $0c48
			
			//			LOGD("words->size=%d", words->size());

			int index = 0;
			CSlrString *labelName = (*words)[index++];
			CSlrString *equals = (*words)[words->size()-3];
//			equals->DebugPrint("equals=");
			if (equals->GetChar(0)== '=')
			{
				CSlrString *labelName = (*words)[0];
				char *labelNameStr = labelName->GetStdASCII();

//				LOGD("labelNameStr='%s'", labelNameStr);
				
				CSlrString *addrSlrStr = (*words)[words->size()-1];
				char *addrStr = addrSlrStr->GetStdASCII();

//				addrSlrStr->DebugPrint("addrStr=");
				
				int addr;
				if (addrStr[0] == '$')
				{
					sscanf((addrStr+1), "%x", &addr);
				}
				else
				{
					sscanf(addrStr, "%d", &addr);
				}
				
				LOGD("labelNameStr=%s  addr=%04x", labelNameStr, addr);
				CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
				viewDisassembleMainCpu->AddNewCodeLabel(addr, labelNameStr);
				
				delete []addrStr;
//				delete []labelNameStr;	TODO: AddCodeLabel does not allocate own string
			}
			else
			{
				LOGError("ParseSymbols: error in line %d (unknown label type)", lineNum);
				break;
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

	// update positions
	CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
	CViewDisassemble *viewDisassembleDrive = debugInterface->GetViewDriveDisassemble(0);

	if (viewDisassembleMainCpu)
		viewDisassembleMainCpu->UpdateLabelsPositions();
	
	if (viewDisassembleDrive)
		viewDisassembleDrive->UpdateLabelsPositions();
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
	
	LOGD("C64Symbols::ParseSymbols: done");
}


void C64Symbols::DeleteAllBreakpoints()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();
	debugInterface->ClearBreakpoints();
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64Symbols::ParseBreakpoints(CSlrString *fileName)
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
	
	ParseBreakpoints(byteBuffer);
	
	delete byteBuffer;
	delete file;
}

void C64Symbols::ParseBreakpoints(CByteBuffer *byteBuffer)
{
	LOGM("C64Symbols::ParseBreakpoints");
	
	debugInterface->LockMutex();
	
	if (byteBuffer->length < 8)
	{
		LOGError("Empty breakpoints file");
		debugInterface->UnlockMutex();
		return;
	}

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
			
			std::map<int, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsPC->breakpoints.find(address);
			if (it == debugInterface->breakpointsPC->breakpoints.end())
			{
				// not found
				CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(address);
				addrBreakpoint->actions = ADDR_BREAKPOINT_ACTION_STOP;
				debugInterface->breakpointsPC->breakpoints[address] = addrBreakpoint;
				
				debugInterface->breakOnPC = true;
			}
			else
			{
				LOGD("...... exists %4.4x", address);
				CAddrBreakpoint *addrBreakpoint = it->second;
				SET_BIT(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_STOP);
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
			
			std::map<int, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsPC->breakpoints.find(address);
			if (it == debugInterface->breakpointsPC->breakpoints.end())
			{
				// not found
				CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(address);
				addrBreakpoint->actions = ADDR_BREAKPOINT_ACTION_SET_BACKGROUND;
				addrBreakpoint->data = value;
				debugInterface->breakpointsPC->breakpoints[address] = addrBreakpoint;
				
				debugInterface->breakOnPC = true;
			}
			else
			{
				LOGD("...... exists %4.4x", address);
				CAddrBreakpoint *addrBreakpoint = it->second;
				addrBreakpoint->data = value;
				SET_BIT(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_SET_BACKGROUND);
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
			
			CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(rasterNum);
			debugInterface->breakpointsRaster->breakpoints[rasterNum] = addrBreakpoint;
			
			debugInterface->breakOnRaster = true;
		}
		else if (command->Equals("breakvic") || command->Equals("breakonvic") || command->Equals("breakonirqvic"))
		{
			if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
			{
				((C64DebugInterface*)debugInterface)->breakOnC64IrqVIC = true;
				LOGD(".. adding breakOnC64IrqVIC");
			}
		}
		else if (command->Equals("breakcia") || command->Equals("breakoncia") || command->Equals("breakonirqcia"))
		{
			if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
			{
				((C64DebugInterface*)debugInterface)->breakOnC64IrqCIA = true;
				LOGD(".. adding breakOnC64IrqCIA");
			}
		}
		else if (command->Equals("breaknmi") || command->Equals("breakonnmi") || command->Equals("breakonirqnmi"))
		{
			if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
			{
				((C64DebugInterface*)debugInterface)->breakOnC64IrqNMI = true;
				LOGD(".. adding breakOnC64IrqNMI");
			}
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
				memBreakType = MEMORY_BREAKPOINT_EQUAL;
			}
			else if (op->Equals("!="))
			{
				memBreakType = MEMORY_BREAKPOINT_NOT_EQUAL;
			}
			else if (op->Equals("<"))
			{
				memBreakType = MEMORY_BREAKPOINT_LESS;
			}
			else if (op->Equals("<=") || op->Equals("=<"))
			{
				memBreakType = MEMORY_BREAKPOINT_LESS_OR_EQUAL;
			}
			else if (op->Equals(">"))
			{
				memBreakType = MEMORY_BREAKPOINT_GREATER;
			}
			else if (op->Equals(">=") || op->Equals("=>"))
			{
				memBreakType = MEMORY_BREAKPOINT_GREATER_OR_EQUAL;
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
			
			CMemoryBreakpoint *memBreakpoint = new CMemoryBreakpoint(address, memBreakType, value);
			debugInterface->breakpointsMemory->breakpoints[address] = memBreakpoint;
			
			debugInterface->breakOnMemory = true;
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
	
	CViewBreakpoints *viewBreakpoints = debugInterface->GetViewBreakpoints();
	if (viewBreakpoints)
	{
		viewBreakpoints->UpdateRenderBreakpoints();
	}
	
	LOGD("C64Symbols::ParseBreakpoints: done");
}

///
void C64Symbols::DeleteAllWatches()
{
	LOGD("C64Symbols::DeleteAllWatches");
	
	// bug: this freezes gui at startup, and is not needed
//	debugInterface->LockMutex();
	
	CViewDataWatch *viewMainCpuDataWatch = debugInterface->GetViewMemoryDataWatch();
	if (viewMainCpuDataWatch)
	{
		viewMainCpuDataWatch->DeleteAllWatches();
	}
	
	// TODO: this below breaks the idea, we *must* have a specific debug interface for the C64 drives
	if (viewC64->debugInterfaceC64)
	{
		viewC64->viewDrive1541MemoryDataWatch->DeleteAllWatches();
	}
	
//	debugInterface->UnlockMutex();
}

void C64Symbols::ParseWatches(CSlrString *fileName)
{
	char *fname = fileName->GetStdASCII();
	
	LOGD("C64Symbols::ParseWatches: %s", fname);
	
	CSlrFileFromOS *file = new CSlrFileFromOS(fname);
	
	if (file->Exists() == false)
	{
		LOGError("C64Symbols::ParseWatches: file %s does not exist", fname);
		delete [] fname;
		return;
	}
	delete [] fname;
	
	ParseWatches(file);
	
	delete file;
}

void C64Symbols::ParseWatches(CSlrFile *file)
{
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseWatches(byteBuffer);
	
	delete byteBuffer;
}


void C64Symbols::ParseWatches(CByteBuffer *byteBuffer)
{
	LOGM("C64Symbols::ParseWatches");
	
	LOGTODO("ParseWatches: viewC64->viewC64MemoryDataWatch->AddWatch: make generic for C64 drives (TODO: drive debug interface)");

	// bug: this freezes gui at startup, and is not needed
//	debugInterface->LockMutex();
	
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	std::list<u16> splitChars;
	splitChars.push_back(' ');
	splitChars.push_back('\t');
	splitChars.push_back('=');

	std::list<u16> splitCharsComma;
	splitCharsComma.push_back(',');

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
		str->DebugPrint("str=");
		
		std::vector<CSlrString *> *words = str->SplitWithChars(splitChars);
		
		LOGD("words->size=%d", words->size());
		for (int i = 0; i < words->size(); i++)
		{
			LOGD("...words[%d]", i);
			(*words)[i]->DebugPrint("...=");
		}
		
		LOGD("------");

		if (words->size() < 3)
		{
			lineNum++;
			continue;
		}
		
		CSlrString *dataSlrStr = (*words)[0];
		
		// comment?
		if (dataSlrStr->GetChar(0) == '#')
		{
			lineNum++;
			continue;
		}
		
		
		if (words->size() == 3)
		{
			// addr 0
			// watch name 2
			
			CSlrString *watchName = (*words)[2];
			watchName->DebugPrint("watchName=");

			char *watchNameStr = watchName->GetStdASCII();
			
			std::vector<CSlrString *> *dataWords = dataSlrStr->SplitWithChars(splitCharsComma);
			
//			for (int i = 0; i < dataWords->size(); i++)
//			{
//				LOGD("...dataWords[%d]", i);
//				(*dataWords)[i]->DebugPrint("...=");
//			}
			
			CSlrString *addrSlrStr = dataSlrStr; //(*dataWords)[0];
			int addr = addrSlrStr->ToIntFromHex();
			
			LOGD("addr=%x", addr);
			
			// Not finished / TODO:
//			int representation = WATCH_REPRESENTATION_HEX;
//			int numberOfValues = 1;
//			int bits = WATCH_BITS_8;
//			
//			if (dataWords->size() > 2)
//			{
//				CSlrString *repStr = (*dataWords)[2];
//				repStr->DebugPrint("repStr=");
//				
//				if (repStr->CompareWith("hex") || repStr->CompareWith("HEX"))
//				{
//					representation = WATCH_REPRESENTATION_HEX;
//				}
//				else if (repStr->CompareWith("bin") || repStr->CompareWith("BIN"))
//				{
//					representation = WATCH_REPRESENTATION_BIN;
//				}
//				else if (repStr->CompareWith("dec") || repStr->CompareWith("DEC"))
//				{
//					representation = WATCH_REPRESENTATION_UNSIGNED_DEC;
//				}
//				else if (repStr->CompareWith("sdec") || repStr->CompareWith("SDEC") || repStr->CompareWith("signed"))
//				{
//					representation = WATCH_REPRESENTATION_SIGNED_DEC;
//				}
//				else if (repStr->CompareWith("text") || repStr->CompareWith("TEXT"))
//				{
//					representation = WATCH_REPRESENTATION_TEXT;
//				}
//			}
//			
//			if (dataWords->size() > 4)
//			{
//				CSlrString *nrValsStr = (*dataWords)[4];
//				numberOfValues = nrValsStr->ToInt();
//			}
//			
//			if (dataWords->size() > 6)
//			{
//				CSlrString *bitsStr = (*dataWords)[6];
//				if (bitsStr->CompareWith("8"))
//				{
//					bits = WATCH_BITS_8;
//				}
//				else if (bitsStr->CompareWith("16"))
//				{
//					bits = WATCH_BITS_16;
//				}
//				else if (bitsStr->CompareWith("32"))
//				{
//					bits = WATCH_BITS_32;
//				}
//			}
			
			CViewDataWatch *viewMemoryDataWatch = debugInterface->GetViewMemoryDataWatch();
			if (viewMemoryDataWatch)
			{
				viewMemoryDataWatch->AddNewWatch(addr, watchNameStr); //, representation, numberOfValues, bits);
			}
			
			delete [] watchNameStr;

		}
		else if (words->size() > 3)
		{
			// assume tass64 label
			// example: DRIVERDONE      = $0c48
			
						LOGD("words->size=%d", words->size());
			
			int index = 0;
			CSlrString *labelName = (*words)[index++];
			CSlrString *equals = (*words)[words->size()-3];
						equals->DebugPrint("equals=");
			if (equals->GetChar(0)== '=')
			{
				CSlrString *labelName = (*words)[0];
				char *labelNameStr = labelName->GetStdASCII();
				
								LOGD("labelNameStr='%s'", labelNameStr);
				
				CSlrString *addrSlrStr = (*words)[words->size()-1];
				char *addrStr = addrSlrStr->GetStdASCII();
				
								addrSlrStr->DebugPrint("addrStr=");
				
				int addr;
				if (addrStr[0] == '$')
				{
					sscanf((addrStr+1), "%x", &addr);
				}
				else
				{
					sscanf(addrStr, "%d", &addr);
				}
				
				LOGD("watchNameStr=%s  addr=%04x", labelNameStr, addr);
				
				//				LOGTODO("!!!!!!!!!!!!!!!!!! REMOVE ME / TESTING VIEW !!!!!!!!!!!!");
				//				if (addr >= 0x0900 && addr < 0x0B60)
				//				{
				//					viewC64->viewC64MemoryDataWatch->AddWatch(labelNameStr, addr);
				//				}
				
				CViewDataWatch *viewMemoryDataWatch = debugInterface->GetViewMemoryDataWatch();
				if (viewMemoryDataWatch)
				{
					viewMemoryDataWatch->AddNewWatch(addr, labelNameStr);
				}
				
				delete []addrStr;
				delete []labelNameStr;
			}
			else
			{
				LOGError("ParseSymbols: error in line %d (unknown label type)", lineNum);
				break;
			}
		}
		else
		{
			LOGError("ParseWatches: error in line %d (unknown watch format)", lineNum);
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
	
	//LOGTODO("update watches max length for display");
	
//	debugInterface->UnlockMutex();
	
	LOGD("C64Symbols::Watches: done");
}

///

void C64Symbols::ParseSourceDebugInfo(CSlrString *fileName)
{
	LOGM("C64Symbols::ParseSourceDebugInfo");
	fileName->DebugPrint("C64Symbols::ParseSourceDebugInfo fileName=");
	
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
	
	ParseSourceDebugInfo(byteBuffer);
	
	delete byteBuffer;
	delete file;
}

void C64Symbols::ParseSourceDebugInfo(CSlrFile *file)
{
	CByteBuffer *byteBuffer = new CByteBuffer(file, false);
	
	ParseSourceDebugInfo(byteBuffer);
	
	delete byteBuffer;
}

void C64Symbols::DeleteSourceDebugInfo()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	if (this->asmSource)
	{
		delete this->asmSource;
	}
	this->asmSource = NULL;
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64Symbols::ParseSourceDebugInfo(CByteBuffer *byteBuffer)
{
	LOGM("C64Symbols::ParseSourceDebugInfo: byteBuffer=%x", byteBuffer);
	
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	LOGTODO("move this->asmSource to debugInterfce->asmSource");
	if (this->asmSource != NULL)
	{
		delete this->asmSource;
		asmSource = NULL;
	}
	
	LOGD("create asmSource C64AsmSourceSymbols");
	this->asmSource = new C64AsmSourceSymbols(byteBuffer, debugInterface);
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();

	LOGD("C64Symbols::ParseSymbols: done");
}

