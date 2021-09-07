#include "C64AsmSourceSymbols.h"
#include "CGuiMain.h"
#include "CByteBuffer.h"
#include "CViewC64.h"
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "utf8.h"
#include "pugixml.h"
#include "std_membuf.h"
#include "CSlrFileFromOS.h"
#include "CViewDisassemble.h"
#include "CViewBreakpoints.h"
#include "CViewDataWatch.h"
#include "CDebugInterface.h"
#include "C64DebugInterface.h"

// TODO: the code below is still just a POC written in hurry, meaning this might leak memory a lot and needs proper refactoring
//       hopefully the labels are not loaded very often... be warned!

#define MODE_IDLE				0
#define MODE_READING_SOURCES	1
#define MODE_READING_MAP		2

C64AsmSourceSymbols::C64AsmSourceSymbols(CByteBuffer *byteBuffer, CDebugInterface *debugInterface)
{
	LOGD("C64AsmSourceSymbols::C64AsmSourceSymbols");
	
	this->debugInterface = debugInterface;
	
	CSlrDataAdapter *dataAdapter = debugInterface->GetDataAdapter();
	this->maxMemoryAddress = dataAdapter->AdapterGetDataLength();

	this->currentSelectedSegment = NULL;

//	ParseOldFormat(byteBuffer, debugInterface);
	ParseXML(byteBuffer, debugInterface);
}

C64AsmSourceSymbols::~C64AsmSourceSymbols()
{
	LOGD("~C64AsmSourceSymbols");
	
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	this->DeactivateSegment();

	while (!segments.empty())
	{
		C64AsmSourceSegment *segment = segments.back();
		segments.pop_back();
		delete segment;
	}

	while (!codeSourceFilesById.empty())
	{
		std::map<u32, C64AsmSourceFile *>::iterator it = codeSourceFilesById.begin();
		C64AsmSourceFile *file = it->second;
		codeSourceFilesById.erase(it);
		delete file;
	}
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
	
	LOGD("~C64AsmSourceSymbols finished");
}

//	"   &quot;
//	'   &apos;
//	<   &lt;
//	>   &gt;
//	&   &amp;

void C64AsmSourceSymbols::ParseXML(CByteBuffer *byteBuffer, CDebugInterface *debugInterface)
{
	LOGD("C64AsmSourceSymbols::ParseXML byteBuffer=%x debugInterface=%x", byteBuffer, debugInterface);

	byteBuffer->removeCRLFinQuotations();
	
	pugi::xml_document doc;
	pugi::xml_parse_result result = doc.load_buffer(byteBuffer->data, byteBuffer->length);
	
	if (!result)
	{
		LOGError("Loading debug symbols failed: %s at %d", result.description(), result.offset);
		return;
	}
	
	LOGD("C64AsmSourceSymbols::ParseXML: parsed OK");

	pugi::xml_node rootTag = doc.first_child();
	pugi::xml_attribute rootAttr = rootTag.first_attribute();
	
	if (strcmp(rootAttr.name(), "version"))
	{
		LOGError("Version tag mismatch (%s)", rootAttr.name());
		return;
	}
	if (strcmp(rootAttr.value(), "1.0"))
	{
		LOGError("Unknown version of debug symbols (%s)", rootAttr.value());
		return;
	}
	
	//
	//	for (pugi::xml_node tag = rootTag.first_child(); tag; tag = tag.next_sibling())
	//	{
	//		LOGD(">>> %s:", tag.name());
	//
	//		for (pugi::xml_attribute attr = tag.first_attribute(); attr; attr = attr.next_attribute())
	//		{
	//			LOGD("%s=%s", attr.name(), attr.value());
	//			LOGD("   %s", tag.child_value());
	//		}
	//	}

	
	// parse_escapes
	std::list<u16> splitCharsLine;
	splitCharsLine.push_back('\n');
	splitCharsLine.push_back('\r');

	std::list<u16> splitCharsComma;
	splitCharsComma.push_back(',');
	
	std::list<u16> splitCharsBreakpoints;
	splitCharsBreakpoints.push_back(' ');
	splitCharsBreakpoints.push_back('<');
	splitCharsBreakpoints.push_back('>');
	splitCharsBreakpoints.push_back('=');
	splitCharsBreakpoints.push_back('!');
	splitCharsBreakpoints.push_back('#');

	LOGD("== Sources");
	pugi::xml_node nodeSources = rootTag.child("Sources");
	
	if (nodeSources.empty())
	{
		LOGError("Sources list not found");
		return;
	}
	
	// parse sources
	CSlrString *strSources = new CSlrString(nodeSources.child_value());
	std::vector<CSlrString *> *lines = strSources->SplitWithChars(splitCharsLine);
	
	LOGD("lines=");
	for (std::vector<CSlrString *>::iterator it = lines->begin(); it != lines->end(); it++)
	{
		CSlrString *oneLine = *it;
		if (oneLine->GetLength() < 2)
			continue;
		
		oneLine->RemoveFromBeginningSelectedCharacter(' ');
		oneLine->RemoveFromBeginningSelectedCharacter('\t');
		
		//				oneLine->DebugPrint("oneLine");
		//				oneLine->DebugPrintVector("oneLine");
		
		std::vector<CSlrString *> *words = oneLine->SplitWithChars(splitCharsComma);
		
		if (words->size() == 0)
			continue;
		
		if (words->size() != 3)
		{
			LOGError("Wrong format for sources list (%d words)", words->size()); // at line #%d", tag.l);
			continue;
		}
		
		C64AsmSourceFile *asmSourceFile = new C64AsmSourceFile();
		
		int sourceId = (*words)[0]->ToInt();
		
		asmSourceFile->sourceId = sourceId;
		asmSourceFile->sourceFilePath = new CSlrString((*words)[2]);
		asmSourceFile->sourceFileName = asmSourceFile->sourceFilePath->GetFileNameComponentFromPath();
		
		codeSourceFilesById[sourceId] = asmSourceFile;
		
		LOGD("... added source id: %d", asmSourceFile->sourceId);
		asmSourceFile->sourceFilePath->DebugPrint("...    source file path=");
		
		CSlrString::DeleteVectorElements(words);
	}
	CSlrString::DeleteVectorElements(lines);
	delete strSources;
	
	LOGD("== Segments");

	int segmentNum = 0;
	for (pugi::xml_node segmentNode = rootTag.child("Segment"); segmentNode; segmentNode = segmentNode.next_sibling("Segment"))
	{
		pugi::xml_attribute attrSegmentName = segmentNode.attribute("name");
		LOGD("Segment: %s", attrSegmentName.value());
		
		CSlrString *segmentName = new CSlrString(attrSegmentName.value());
		
		C64AsmSourceSegment *segment = new C64AsmSourceSegment(this, segmentName, segmentNum++);
		this->segments.push_back(segment);

		for (pugi::xml_node blockNode = segmentNode.child("Block"); blockNode; blockNode = blockNode.next_sibling("Block"))
		{
			pugi::xml_attribute attrBlockName = blockNode.attribute("name");
			LOGD("  Block: %s", attrBlockName.value());
			
			CSlrString *blockName = new CSlrString(attrBlockName.value());
			
			C64AsmSourceBlock *block = new C64AsmSourceBlock(segment, blockName);
			segment->blocks.push_back(block);
			
			// parse sources
			CSlrString *strBlock = new CSlrString(blockNode.child_value());
			std::vector<CSlrString *> *lines = strBlock->SplitWithChars(splitCharsLine);
			
			for (std::vector<CSlrString *>::iterator it = lines->begin(); it != lines->end(); it++)
			{
				CSlrString *oneLine = *it;
				if (oneLine->GetLength() < 2)
					continue;
				
				oneLine->RemoveFromBeginningSelectedCharacter(' ');
				oneLine->RemoveFromBeginningSelectedCharacter('\t');
				
//				oneLine->DebugPrint("  > ");
				//			oneLine->DebugPrintVector("oneLine");
				
				std::vector<CSlrString *> *words = oneLine->SplitWithChars(splitCharsComma);
				
				if (words->size() == 0)
					continue;
				
//				LOGD("words->size=%d", words->size());
				
				if (words->size() == 13)
				{
//								LOGD("... parsing");
					
					int memoryAddrStart = (*words)[0]->ToIntFromHex();
//								LOGD("   memoryAddrStart=%04x", memoryAddrStart);
					
					int memoryAddrEnd = (*words)[2]->ToIntFromHex();
//								LOGD("   memoryAddrEnd=%04x", memoryAddrEnd);
					
					int sourceId = (*words)[4]->ToInt();
//								LOGD("   sourceId=%d", sourceId);
					
					int lineNumStart = (*words)[6]->ToInt();
//								LOGD("   lineNumStart=%d", lineNumStart);
					
					int columnNumStart = (*words)[8]->ToInt();
//								LOGD("   columnNumStart=%d", columnNumStart);
					
					int lineNumEnd = (*words)[10]->ToInt();
//								LOGD("   lineNumEnd=%d", lineNumEnd);
					
					int columnNumEnd = (*words)[12]->ToInt();
//								LOGD("   columnNumEnd=%d", columnNumEnd);
					
					
					std::map<u32, C64AsmSourceFile *>::iterator it = codeSourceFilesById.find(sourceId);
					
					if (it != codeSourceFilesById.end())
					{
						C64AsmSourceFile *asmSourceFile = it->second;
						
						C64AsmSourceLine *asmSourceLine = new C64AsmSourceLine();
						asmSourceLine->codeFile = asmSourceFile;
						asmSourceLine->block = block;
						asmSourceLine->codeLineNumberStart = lineNumStart;
						asmSourceLine->codeColumnNumberStart = columnNumStart;
						asmSourceLine->codeLineNumberEnd = lineNumEnd;
						asmSourceLine->codeColumnNumberEnd = columnNumEnd;
						asmSourceLine->memoryAddressStart = memoryAddrStart;
						asmSourceLine->memoryAddressEnd = memoryAddrEnd;
						
						asmSourceFile->asmSourceLines.push_back(asmSourceLine);
						
						for (int addr = memoryAddrStart; addr <= memoryAddrEnd; addr++)
						{
							if (addr >= 0 && addr < maxMemoryAddress)
							{
								segment->codeSourceLineByMemoryAddress[addr] = asmSourceLine;
//								block->codeSourceLineByMemoryAddress[addr] = asmSourceLine;
							}
							else
							{
								LOGError("Address %04x is out of memory range", addr); // at line #%d", addr, lineNum);
								break;
							}
						}

					}
					else
					{
						LOGError("Source code id #%d not found", sourceId); // at line #%d", sourceId, lineNum);
					}
				}
				else
				{
					LOGError("Wrong format for source code address mapping"); // at line #%d", lineNum);
				}
				CSlrString::DeleteVectorElements(words);
			}
			CSlrString::DeleteVectorElements(lines);
			delete strBlock;
		}
	}
	
	LOGD("== Labels");
	pugi::xml_node nodeLabels = rootTag.child("Labels");
	
	if (!nodeLabels.empty())
	{
		// parse labels
		CSlrString *strLabels = new CSlrString(nodeLabels.child_value());
		std::vector<CSlrString *> *lines = strLabels->SplitWithChars(splitCharsLine);
		
		LOGD("lines=");
		for (std::vector<CSlrString *>::iterator it = lines->begin(); it != lines->end(); it++)
		{
			CSlrString *oneLine = *it;
			if (oneLine->GetLength() < 2)
				continue;
			
			oneLine->RemoveFromBeginningSelectedCharacter(' ');
			oneLine->RemoveFromBeginningSelectedCharacter('\t');
			
							oneLine->DebugPrint("> ");
			//				oneLine->DebugPrintVector("oneLine");
			
			std::vector<CSlrString *> *words = oneLine->Split(splitCharsComma);
			
			if (words->size() == 0)
				continue;
			
			// Note, Mads changed format recently and now labels also include information about code lines which are not needed for us now
			if (words->size() < 3)
			{
				LOGError("Not enough words for label definition (%d words)", words->size()); // at line #%d", tag.line);
				CSlrString::DeleteVectorElements(words);
				continue;
			}
//			if (words->size() > 3)
//			{
//				LOGWarning("Wrong format for labels (%d words)", words->size()); // at line #%d", tag.line);
//			}

			CSlrString *segmentName = (*words)[0];
			CSlrString *strAddr = (*words)[1];
			int address = strAddr->ToIntFromHex();
			CSlrString *labelName = (*words)[2];
			char *labelNameStr = labelName->GetStdASCII();
			
			C64AsmSourceSegment *segment = this->FindSegment(segmentName);
			if (segment == NULL)
			{
				segmentName->DebugPrint("segment=");
				LOGError("ParseLabels: segment not found");
				CSlrString::DeleteVectorElements(words);
				continue;
			}

			segment->AddCodeLabel(address, labelNameStr);

			CSlrString::DeleteVectorElements(words);
		}
	}
	
	LOGD("== Watchpoints");
	pugi::xml_node nodeWatches = rootTag.child("Watchpoints");
	
	if (!nodeWatches.empty())
	{
		// parse watches
		CSlrString *strWatches = new CSlrString(nodeWatches.child_value());
		std::vector<CSlrString *> *lines = strWatches->SplitWithChars(splitCharsLine);
		
		LOGD("lines=");
		for (std::vector<CSlrString *>::iterator it = lines->begin(); it != lines->end(); it++)
		{
			CSlrString *oneLine = *it;
			if (oneLine->GetLength() < 2)
				continue;
			
			oneLine->RemoveFromBeginningSelectedCharacter(' ');
			oneLine->RemoveFromBeginningSelectedCharacter('\t');
			
			oneLine->DebugPrint("> ");
			//				oneLine->DebugPrintVector("oneLine");
			
			std::vector<CSlrString *> *words = oneLine->Split(splitCharsComma);
			
			if (words->size() == 0)
				continue;
			
			if (words->size() < 2)
			{
				LOGError("Wrong format for watches (%d words)", words->size()); // at line #%d", tag.line);
				CSlrString::DeleteVectorElements(words);
				continue;
			}
			
			CSlrString *segmentName = (*words)[0];
			CSlrString *strAddr = (*words)[1];
			int address = strAddr->ToIntFromHex();
			
			int numberOfValues = 1;
			CSlrString *strRepresentation = NULL;
			
			if (words->size() > 2)
			{
				CSlrString *strNumberOfValues = (*words)[2];
				numberOfValues = strNumberOfValues->ToInt();
				if (numberOfValues < 1)
				{
					numberOfValues = 1;
				}
			}
			
			if (words->size() > 3)
			{
				strRepresentation = (*words)[3];
			}
			
			C64AsmSourceSegment *segment = this->FindSegment(segmentName);
			if (segment == NULL)
			{
				segmentName->DebugPrint("segment=");
				LOGError("ParseWatches: segment not found");
				CSlrString::DeleteVectorElements(words);
				continue;
			}
			
			segment->AddWatch(address, numberOfValues, strRepresentation);
			
			CSlrString::DeleteVectorElements(words);
		}
	}


	LOGD("== Breakpoints");
	pugi::xml_node nodeBreakpoints = rootTag.child("Breakpoints");
	
	if (!nodeBreakpoints.empty())
	{
		// parse sources
		CSlrString *strBreakpoints = new CSlrString(nodeBreakpoints.child_value());
		std::vector<CSlrString *> *lines = strBreakpoints->SplitWithChars(splitCharsLine);
		
		for (std::vector<CSlrString *>::iterator it = lines->begin(); it != lines->end(); it++)
		{
			CSlrString *oneLine = *it;
			if (oneLine->GetLength() < 2)
				continue;
			
			oneLine->RemoveFromBeginningSelectedCharacter(' ');
			oneLine->RemoveFromBeginningSelectedCharacter('\t');
			
			oneLine->DebugPrint("  > ");
//			oneLine->DebugPrintVector("oneLine");
			
			std::vector<CSlrString *> *breakpointWords = oneLine->SplitWithChars(splitCharsComma);
			
			if (breakpointWords->size() == 0)
				continue;
			
//			LOGD("breakpointWords->size=%d", breakpointWords->size());
			
			//
			CSlrString *segmentName = (*breakpointWords)[0];
			CSlrString *strAddr = (*breakpointWords)[2];
			int breakpointAddress = strAddr->ToIntFromHex();
			
			C64AsmSourceSegment *segment = this->FindSegment(segmentName);
			if (segment == NULL)
			{
				segmentName->DebugPrint("segment=");
				LOGError("ParseBreakpoints: segment not found");
				CSlrString::DeleteVectorElements(breakpointWords);
				continue;
			}

			if (breakpointWords->size() == 4)
			{
				segment->AddBreakpointPC(breakpointAddress);
				
				CSlrString::DeleteVectorElements(breakpointWords);
				continue;
			}

			if (breakpointWords->size() != 5)
			{
				LOGError("ParseBreakpoints: unknown format (num elements=%d)", breakpointWords->size());
				CSlrString::DeleteVectorElements(breakpointWords);
				continue;
			}
			
			CSlrString *breakpointDefinitionStr = (*breakpointWords)[4];
//				breakpointDefinitionStr->DebugPrint("breakpointDefinitionStr=");
			std::vector<CSlrString *> *words = breakpointDefinitionStr->SplitWithChars(splitCharsBreakpoints);
			
//				LOGD(">>>> words->size=%d:", words->size());
//				for (int i = 0; i < words->size(); i++)
//				{
//					(*words)[i]->DebugPrint();
//				}
//				LOGD("<<<<");
			
			CSlrString *command = (*words)[0];
			
//				command->DebugPrint("command=");
			
			// comment?
			if (command->GetChar(0) == '#')
			{
				continue;
			}
			
			command->ConvertToLowerCase();
			
			if (command->Equals("break") || command->Equals("breakpc") || command->Equals("breakonpc"))
			{
				LOGD(".. adding breakOnPC %4.4x", breakpointAddress);
				
				segment->AddBreakpointPC(breakpointAddress);
			}
			else if (command->Equals("setbkg") || command->Equals("setbackground"))
			{
				if (words->size() < 3)
				{
					LOGError("ParseBreakpoints: error with setbkg"); //in line %d", lineNum);
					break;
				}
				
				// pc breakpoint
				CSlrString *arg = (*words)[2];
				int value = arg->ToIntFromHex();
				
				LOGD(".. adding setBkg %4.4x %2.2x", breakpointAddress, value);
				
				segment->AddBreakpointSetBackground(breakpointAddress, value);
				
			}
			else if (command->Equals("breakraster") || command->Equals("breakonraster")
					 || command->Equals("raster"))
			{
				if (words->size() < 3)
				{
					LOGError("ParseBreakpoints: error with breakraster"); //in line %d", lineNum);
					break;
				}
				
				// raster breakpoint
				CSlrString *arg = (*words)[2];
				//arg->DebugPrint(" arg=");
				int rasterNum = arg->ToIntFromHex();
				
				LOGD(".. adding breakOnRaster %4.4x", rasterNum);

				segment->AddBreakpointRaster(rasterNum);
			}
			else if (command->Equals("breakvic") || command->Equals("breakonvic") || command->Equals("breakonirqvic")
					 || command->Equals("vic"))
			{
				LOGD(".. adding breakOnC64IrqVIC");
				
				segment->AddBreakpointVIC();
			}
			else if (command->Equals("breakcia") || command->Equals("breakoncia") || command->Equals("breakonirqcia")
					 || command->Equals("cia"))
			{
				segment->AddBreakpointCIA();
			}
			else if (command->Equals("breaknmi") || command->Equals("breakonnmi") || command->Equals("breakonirqnmi")
					 || command->Equals("nmi"))
			{
				segment->AddBreakpointNMI();
			}
			else if (command->Equals("breakmemory") || command->Equals("breakonmemory") || command->Equals("breakmem")
					 || command->Equals("mem"))
			{
				if (words->size() < 4)
				{
					LOGError("ParseBreakpoints: error with breakmemory"); //in line %d", lineNum);
					break;
				}
				
				CSlrString *addressStr = (*words)[2];
//					addressStr->DebugPrint(" addressStr=");
				int address = addressStr->ToIntFromHex();
				
				int index = 3;
				CSlrString *op = new CSlrString();
				
				while (index < words->size()-1)
				{
					CSlrString *f = (*words)[index];
					f->ConvertToLowerCase();
					
//							f->DebugPrint(".... f= ");
					
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
					LOGError("ParseBreakpoints: error"); //in line %d", lineNum);
					break;
				}
				
				CSlrString *arg = (*words)[index];
//					arg->DebugPrint(" arg=");
				
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
					LOGError("ParseBreakpoints: unknown operator for memory breakpoint"); //, lineNum);
					break;
				}
				
				LOGD(".. adding breakOnMemory");
				LOGD("..... addr=%4.4x", address);
				op->DebugPrint("..... op=");
				LOGD("..... value=%2.2x", value);
				
				segment->AddBreakpointMemory(address, memBreakType, value);
				
			}
			else
			{
				LOGError("ParseBreakpoints: unknown breakpoint type"); //, lineNum);
				break;
			}
			
			CSlrString::DeleteVectorElements(words);
			CSlrString::DeleteVectorElements(breakpointWords);
		}
		CSlrString::DeleteVectorElements(lines);
		delete strBreakpoints;
	}
	

	LOGD("== ");

	//
	// load source files
	//
	
	for (std::map<u32, C64AsmSourceFile *>::iterator it = codeSourceFilesById.begin();
		 it != codeSourceFilesById.end(); it++)
	{
		C64AsmSourceFile *asmSourceFile = it->second;
		
		CSlrFile *file = new CSlrFileFromOS(asmSourceFile->sourceFilePath);
		
		//
		if (file->Exists())
		{
			asmSourceFile->sourceFilePath->DebugPrint("<<<<<< OPENED  sourceFilePath=");
			LOGD("File opened");
			
			this->LoadSource(asmSourceFile, file);
			
			asmSourceFile->sourceFilePath->DebugPrint(">>>>> FINISHED loading source=");
		}
	}
	
	// activate first segment
	this->segments[0]->Activate(this->debugInterface);
	
	LOGM("C64AsmSourceSymbols::ParseXML: symbols loaded");
}

C64AsmSourceSegment *C64AsmSourceSymbols::FindSegment(CSlrString *segmentName)
{
//	LOGD("C64AsmSourceSymbols::FindSegment");
//	segmentName->DebugPrint("segmentName=");
//	segmentName->DebugPrintVector("segmentName=");
	// TODO: create map of segment names
	for (std::vector<C64AsmSourceSegment *>::iterator it = segments.begin(); it != segments.end(); it++)
	{
		C64AsmSourceSegment *segment = *it;
		if (segmentName->CompareWith(segment->name))
		{
			return segment;
		}
	}
	
	return NULL;
}

// this is parser for "old" debug symbols format discussed with Mads long time ago (not XML-based, not used anymore)
void C64AsmSourceSymbols::ParseOldFormat(CByteBuffer *byteBuffer, CDebugInterface *debugInterface)
{
	int currentMode = MODE_IDLE;
	
	// create default segment
	C64AsmSourceSegment *segment = new C64AsmSourceSegment(this, new CSlrString("Default"), 0);
	this->segments.push_back(segment);
	
	// parse
	byteBuffer->removeCRLFinQuotations();
	
	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	std::list<u16> splitChars;
	splitChars.push_back(' ');
	splitChars.push_back(',');
	
	// Play with all the lines in the file
	while (true)
	{
		if (!getline(reader, line))
			break;
		
		LOGD("---- line=%d", lineNum);

		if (line.length() == 0)
		{
			lineNum++;
			continue;
		}

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
		
		CSlrString *strLine = new CSlrString(utf16line);
		strLine->RemoveEndLineCharacter();	// workaround for stupid Windows getline implementation
		
		strLine->DebugPrint("line str=");
		
		std::vector<CSlrString *> *words = strLine->SplitWithChars(splitChars);
		
		if (words->size() == 0)
		{
			lineNum++;
			continue;
		}
		
//		LOGD("words->size=%d", words->size());
//		for (int i = 0; i < words->size(); i++)
//		{
//			LOGD("... words[%d]", i);
//			CSlrString *str = (*words)[i];
//			str->DebugPrint("... =");
//		}

		CSlrString *command = (*words)[0];
		
		// comment?
		if (command->GetChar(0) == '#')
		{
			lineNum++;
			continue;
		}

		if (currentMode == MODE_IDLE)
		{
			command->ConvertToLowerCase();
			command->DebugPrint("command=");
			if (command->CompareWith("sources={"))
			{
				// load list of file sources
				LOGD("...sources:");
				currentMode = MODE_READING_SOURCES;
			}
			else
			{
				LOGError("Unknown command at line #%d (MODE_IDLE)", lineNum);
				continue;
			}
		}
		else if (currentMode == MODE_READING_SOURCES)
		{
			LOGD("... one source");
			
			if (command->CompareWith("}"))
			{
				LOGD("... done reading sources");
				currentMode = MODE_READING_MAP;
				continue;
			}
			
			if (words->size() != 3)
			{
				LOGError("Wrong format for sources list at line #%d", lineNum);
				continue;
			}
			
			C64AsmSourceFile *asmSourceFile = new C64AsmSourceFile();
			
			int sourceId = (*words)[0]->ToInt();

			asmSourceFile->sourceId = sourceId;
			asmSourceFile->sourceFilePath = new CSlrString((*words)[2]);
			asmSourceFile->sourceFileName = asmSourceFile->sourceFilePath->GetFileNameComponentFromPath();
			
			codeSourceFilesById[sourceId] = asmSourceFile;
			
			LOGD("... added source id: %d", asmSourceFile->sourceId);
			asmSourceFile->sourceFilePath->DebugPrint("...    source file path=");
		}
		else if (currentMode == MODE_READING_MAP)
		{
			LOGD("... map line");
			
			if (words->size() != 13)
			{
				LOGError("Wrong format for source code address mapping at line #%d", lineNum);
				continue;
			}
			
//			LOGD("... parsing");
			
			int memoryAddrStart = (*words)[0]->ToIntFromHex();
//			LOGD("   memoryAddrStart=%04x", memoryAddrStart);

			int memoryAddrEnd = (*words)[2]->ToIntFromHex();
//			LOGD("   memoryAddrEnd=%04x", memoryAddrEnd);

			int sourceId = (*words)[4]->ToInt();
//			LOGD("   sourceId=%d", sourceId);

			int lineNumStart = (*words)[6]->ToInt();
//			LOGD("   lineNumStart=%d", lineNumStart);

			int columnNumStart = (*words)[8]->ToInt();
//			LOGD("   columnNumStart=%d", columnNumStart);

			int lineNumEnd = (*words)[10]->ToInt();
//			LOGD("   lineNumEnd=%d", lineNumEnd);
			
			int columnNumEnd = (*words)[12]->ToInt();
//			LOGD("   columnNumEnd=%d", columnNumEnd);
			
			
			std::map<u32, C64AsmSourceFile *>::iterator it = codeSourceFilesById.find(sourceId);
			
			if (it == codeSourceFilesById.end())
			{
				LOGError("Source code id #%d not found at line #%d", sourceId, lineNum);
				continue;
			}
			
			C64AsmSourceFile *asmSourceFile = it->second;
			
			C64AsmSourceLine *asmSourceLine = new C64AsmSourceLine();
			asmSourceLine->codeFile = asmSourceFile;
			asmSourceLine->block = NULL;
			asmSourceLine->codeLineNumberStart = lineNumStart;
			asmSourceLine->codeColumnNumberStart = columnNumStart;
			asmSourceLine->codeLineNumberEnd = lineNumEnd;
			asmSourceLine->codeColumnNumberEnd = columnNumEnd;
			asmSourceLine->memoryAddressStart = memoryAddrStart;
			asmSourceLine->memoryAddressEnd = memoryAddrEnd;
			
			asmSourceFile->asmSourceLines.push_back(asmSourceLine);
			
			for (int addr = memoryAddrStart; addr <= memoryAddrEnd; addr++)
			{
				if (addr >= 0 && addr < maxMemoryAddress)
				{
					segment->codeSourceLineByMemoryAddress[addr] = asmSourceLine;
				}
				else
				{
					LOGError("Address %04x is out of memory range at line #%d", addr, lineNum);
					break;
				}
			}
			
//			LOGD("---");
			
		}
		
		
		delete strLine;
		for (int i = 0; i < words->size(); i++)
		{
			delete (*words)[i];
		}
		delete  words;
		
		lineNum++;
	}
	
	// load source files
	
	// 	std::map<u32, C64AsmSourceSymbolsFile *> codeSourceFilesById;

	std::map<u32, C64AsmSourceFile *>::iterator it = codeSourceFilesById.begin();
	
	// TODO: convert makefiles to c11
	for (
		 // it
		 ;  it != codeSourceFilesById.end();
			it++)
	{
		C64AsmSourceFile *asmSourceFile = it->second;
		
		CSlrFile *file = new CSlrFileFromOS(asmSourceFile->sourceFilePath);
		
		//
		if (file->Exists())
		{
			asmSourceFile->sourceFilePath->DebugPrint("<<<<<< OPENED  sourceFilePath=");
			LOGD("File opened");
			
			this->LoadSource(asmSourceFile, file);
			
			asmSourceFile->sourceFilePath->DebugPrint(">>>>> FINISHED loading source=");
		}
	}
	
	segment->Activate(debugInterface);
	
	/////////////////////////////////////////

	LOGD("C64AsmSourceSymbols::C64AsmSourceSymbols: ParseOldFormat finished");

}

void C64AsmSourceSymbols::LoadSource(C64AsmSourceFile *asmSourceFile, CSlrFile *file)
{
	CByteBuffer *byteBuffer = file->GetByteBuffer();
	//			byteBuffer->DebugPrint();
	
	LOGD("LoadSource...");
	
	//byteBuffer->removeCRLFinQuotations();

	std_membuf mb(byteBuffer->data, byteBuffer->length);
	std::istream reader(&mb);
	
	unsigned lineNum = 1;
	std::string line;
	line.clear();
	
	// push zero line
	asmSourceFile->codeTextByLineNum.push_back(new CSlrString(""));

	// TODO: UI -> replace tabs with 4 spaces
	CSlrString *strTabs = new CSlrString("    ");
	
	while (true)
	{
		if (!getline(reader, line))
			break;
		
//		LOGD("---- line=%d len=%d eof=%s", lineNum, line.length(), STRBOOL(reader.eof()));
		
//		std::cout << line.length() << std::endl;
//		
//		LOGD("Line is:");
//		std::cout << line << std::endl;
//
//		LOGD("---- parse line %d", lineNum);
//
		
		// check for invalid utf-8 (for a simple yes/no check, there is also utf8::is_valid function)
		std::string::iterator end_it = utf8::find_invalid(line.begin(), line.end());
		if (end_it != line.end())
		{
			LOGError("Invalid UTF-8 encoding detected at line %d", lineNum);
		}
		
		// Get the line length (at least for the valid part)
		int length = utf8::distance(line.begin(), end_it);
//		LOGD("========================= Length of line %d is %d", lineNum, length);
		
		// Convert it to utf-16
		std::vector<unsigned short> utf16line;
		utf8::utf8to16(line.begin(), end_it, back_inserter(utf16line));
		
		CSlrString *strLine = new CSlrString(utf16line);
		strLine->RemoveEndLineCharacter();	// workaround for stupid Windows getline implementation
//		strLine->DebugPrint("line str=");
		
//		if (lineNum == 1)
//		{
//			LOGError("TODO: BUG: line without UTF8 header is imported without 4 letters");
//					strLine->DebugPrint("line str=");
//		}

		u16 tabChar = (u16)('\t');
		strLine->ReplaceCharacter(tabChar, strTabs);
		
		asmSourceFile->codeTextByLineNum.push_back(strLine);

		//		do not delete strLine, it is used

		lineNum++;
	}
	
	delete strTabs;
	
	LOGD("LoadSource done");
	

//	LOGD("LoadSource debug check");
//	asmSourceFile->sourceFilePath->DebugPrint("sourceFilePath=");
//	
//	for (int i = 0; i < 10; i++)
//	{
//		LOGD("         ========== printing source line %d", i);
//		asmSourceFile->codeTextByLineNum[i]->DebugPrint("");
//		
//	}
//	LOGD("check done");
	
}

void C64AsmSourceSymbols::ActivateSegment(C64AsmSourceSegment *segment)
{
	LOGD("C64AsmSourceSymbols::ActivateSegment");
	
	// TODO: we should store this directly and in a generic way.
	//       this now is temporary and needs proper refactor:
	
	// first, copy current breakpoints to segment in case they have been changed
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	if (this->currentSelectedSegment)
	{
		this->currentSelectedSegment->CopyBreakpointsAndWatchesFromDebugInterface(this->debugInterface);
	}
	
	segment->Activate(this->debugInterface);

	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

C64AsmSourceSegment::C64AsmSourceSegment(C64AsmSourceSymbols *symbols, CSlrString *name, int segmentNum)
{
	this->symbols = symbols;
	this->name = name;
	this->segmentNum = segmentNum;
	
	codeSourceLineByMemoryAddress = new C64AsmSourceLine* [symbols->maxMemoryAddress];
	for (int i = 0; i < symbols->maxMemoryAddress; i++)
	{
		codeSourceLineByMemoryAddress[i] = NULL;
	}
	
	breakOnPC = false;
	breakOnMemory = false;
	breakOnRaster = false;
	
	breakOnC64IrqVIC = false;
	breakOnC64IrqCIA = false;
	breakOnC64IrqNMI = false;

}

C64AsmSourceSegment::~C64AsmSourceSegment()
{
	name->DebugPrint("~C64AsmSourceSegment ");
	delete name;
	
	delete codeSourceLineByMemoryAddress;
	
	while (!blocks.empty())
	{
		C64AsmSourceBlock *b = blocks.back();
		blocks.pop_back();
		delete b;
	}
}

void C64AsmSourceSegment::AddBreakpointPC(int address)
{
	std::map<int, CAddrBreakpoint *>::iterator it = this->breakpointsPC.find(address);
	if (it == this->breakpointsPC.end())
	{
		// not found
		CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(address);
		addrBreakpoint->actions = ADDR_BREAKPOINT_ACTION_STOP;
		this->breakpointsPC[address] = addrBreakpoint;
		
		this->breakOnPC = true;
	}
	else
	{
		LOGD("...... exists %4.4x", address);
		CAddrBreakpoint *addrBreakpoint = it->second;
		SET_BIT(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_STOP);
	}
}

void C64AsmSourceSegment::AddBreakpointSetBackground(int address, int value)
{
	std::map<int, CAddrBreakpoint *>::iterator it = this->breakpointsPC.find(address);
	if (it == this->breakpointsPC.end())
	{
		// not found
		CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(address);
		addrBreakpoint->actions = ADDR_BREAKPOINT_ACTION_SET_BACKGROUND;
		addrBreakpoint->data = value;
		this->breakpointsPC[address] = addrBreakpoint;
		
		this->breakOnPC = true;
	}
	else
	{
		LOGD("...... exists %4.4x", address);
		CAddrBreakpoint *addrBreakpoint = it->second;
		addrBreakpoint->data = value;
		SET_BIT(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_SET_BACKGROUND);
	}
}

void C64AsmSourceSegment::AddBreakpointRaster(int rasterNum)
{
	CAddrBreakpoint *addrBreakpoint = new CAddrBreakpoint(rasterNum);
	this->breakpointsRaster[rasterNum] = addrBreakpoint;
	
	this->breakOnRaster = true;
}

void C64AsmSourceSegment::AddBreakpointMemory(int address, u8 breakpointType, int value)
{
	CMemoryBreakpoint *memBreakpoint = new CMemoryBreakpoint(address, breakpointType, value);
	this->breakpointsMemory[address] = memBreakpoint;
	
	this->breakOnMemory = true;
}

void C64AsmSourceSegment::AddBreakpointVIC()
{
	this->breakOnC64IrqVIC = true;
}

void C64AsmSourceSegment::AddBreakpointCIA()
{
	this->breakOnC64IrqCIA = true;
}

void C64AsmSourceSegment::AddBreakpointNMI()
{
	this->breakOnC64IrqNMI = true;
}

void C64AsmSourceSegment::AddCodeLabel(int address, char *text)
{
	// check if exists
	std::map<int, CDisassembleCodeLabel *>::iterator it = codeLabels.find(address);
	
	if (it != codeLabels.end())
	{
		CDisassembleCodeLabel *label = it->second;
		codeLabels.erase(it);
		delete label;
	}

	CDisassembleCodeLabel *label;
	
	// TODO: this is generic but we need to add Drive 1541 labels via specific debug interface
	
	CViewDisassemble *viewDisassembleMainCpu = symbols->debugInterface->GetViewMainCpuDisassemble();
	label = viewDisassembleMainCpu->CreateCodeLabel(address, text);
	
	codeLabels[address] = label;
}

CDisassembleCodeLabel *C64AsmSourceSegment::FindLabel(int address)
{
	// check if exists
	std::map<int, CDisassembleCodeLabel *>::iterator it = codeLabels.find(address);
	
	if (it != codeLabels.end())
	{
		CDisassembleCodeLabel *label = it->second;
		return label;
	}
	
	return NULL;
}

void C64AsmSourceSegment::AddWatch(int address, char *name, uint8 representation, int numberOfValues, uint8 bits)
{
	LOGD("C64AsmSourceSegment::AddWatch: %04x, %s, %d %d %d", address, name, representation, numberOfValues, bits);
	
	// check if exists
	std::map<int, CDataWatchDetails *>::iterator it = watches.find(address);
	
	if (it != watches.end())
	{
		CDataWatchDetails *watch = it->second;
		watches.erase(it);
		delete watch;
	}
	
	CDataWatchDetails *watch;
	
	// TODO: make this generic, temporary for now. add Drive 1541 watches
	
	CViewDataWatch *viewMemoryDataWatch = symbols->debugInterface->GetViewMemoryDataWatch();
	if (viewMemoryDataWatch)
	{
		watch = viewMemoryDataWatch->CreateWatch(address, name, representation, numberOfValues, bits);
	}
	
	watches[address] = watch;
}

void C64AsmSourceSegment::AddWatch(int address, int numberOfValues, CSlrString *strRepresentation)
{
	int representation = WATCH_REPRESENTATION_HEX;
	int numberOfBits = WATCH_BITS_8;
	
	if (strRepresentation != NULL)
	{
		if (strRepresentation->CompareWith("hex")
			|| strRepresentation->CompareWith("h")
			|| strRepresentation->CompareWith("hex8")
			|| strRepresentation->CompareWith("h8"))
		{
			representation = WATCH_REPRESENTATION_HEX;
			numberOfBits = WATCH_BITS_8;
		}
		else if (strRepresentation->CompareWith("hex16")
				 || strRepresentation->CompareWith("h16"))
		{
			representation = WATCH_REPRESENTATION_HEX;
			numberOfBits = WATCH_BITS_16;
		}
		else if (strRepresentation->CompareWith("hex32")
				 || strRepresentation->CompareWith("h32"))
		{
			representation = WATCH_REPRESENTATION_HEX;
			numberOfBits = WATCH_BITS_32;
		}
		
		if (strRepresentation->CompareWith("dec")
			|| strRepresentation->CompareWith("dec8")
			|| strRepresentation->CompareWith("unsigned")
			|| strRepresentation->CompareWith("unsigned8")
			|| strRepresentation->CompareWith("u")
			|| strRepresentation->CompareWith("u8"))
		{
			representation = WATCH_REPRESENTATION_UNSIGNED_DEC;
			numberOfBits = WATCH_BITS_8;
		}
		else if (strRepresentation->CompareWith("dec16")
				 || strRepresentation->CompareWith("unsigned16")
				 || strRepresentation->CompareWith("u16"))
		{
			representation = WATCH_REPRESENTATION_UNSIGNED_DEC;
			numberOfBits = WATCH_BITS_16;
		}
		else if (strRepresentation->CompareWith("dec32")
				 || strRepresentation->CompareWith("unsigned32")
				 || strRepresentation->CompareWith("u32"))
		{
			representation = WATCH_REPRESENTATION_UNSIGNED_DEC;
			numberOfBits = WATCH_BITS_32;
		}
		
		if (strRepresentation->CompareWith("signed")
			|| strRepresentation->CompareWith("signed8")
			|| strRepresentation->CompareWith("s8"))
		{
			representation = WATCH_REPRESENTATION_SIGNED_DEC;
			numberOfBits = WATCH_BITS_8;
		}
		else if (strRepresentation->CompareWith("signed16")
				 || strRepresentation->CompareWith("s16"))
		{
			representation = WATCH_REPRESENTATION_SIGNED_DEC;
			numberOfBits = WATCH_BITS_16;
		}
		else if (strRepresentation->CompareWith("signed32")
				 || strRepresentation->CompareWith("s32"))
		{
			representation = WATCH_REPRESENTATION_SIGNED_DEC;
			numberOfBits = WATCH_BITS_32;
		}
		
		if (strRepresentation->CompareWith("bin")
			|| strRepresentation->CompareWith("bin8")
			|| strRepresentation->CompareWith("b")
			|| strRepresentation->CompareWith("b8"))
		{
			representation = WATCH_REPRESENTATION_BIN;
			numberOfBits = WATCH_BITS_8;
		}
		else if (strRepresentation->CompareWith("bin16")
				 || strRepresentation->CompareWith("b16"))
		{
			representation = WATCH_REPRESENTATION_BIN;
			numberOfBits = WATCH_BITS_16;
		}
		else if (strRepresentation->CompareWith("bin32")
				 || strRepresentation->CompareWith("bin32"))
		{
			representation = WATCH_REPRESENTATION_BIN;
			numberOfBits = WATCH_BITS_32;
		}
		
		else if (strRepresentation->CompareWith("text")
				 || strRepresentation->CompareWith("t"))
		{
			representation = WATCH_REPRESENTATION_TEXT;
			numberOfBits = WATCH_BITS_8;
		}
	}
	
	CDisassembleCodeLabel *label = this->FindLabel(address);
	
	char *labelText;
	if (label == NULL)
	{
		labelText = new char[6];
		sprintf(labelText, "%04x", address);
	}
	else
	{
		// TODO: ugh! what is this?
		labelText = new char[strlen(label->labelText)];
		strcpy(labelText, label->labelText);
	}

	this->AddWatch(address, labelText, representation, numberOfValues, numberOfBits);
}


// this activates the segment in debug interface.
// TODO: due to no time for now it is just copying the breakpoints/labels to proper places in the debugger,
// but we should have this inplace there and a pointer to currently selected segment in CDebugInterface.
// TODO: warning - ugly code below:
void C64AsmSourceSegment::Activate(CDebugInterface *debugInterface)
{
	LOGD("C64AsmSourceSegment::Activate");
	this->name->DebugPrint("segment=");
	
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	// PC breakpoints
	debugInterface->breakpointsPC->breakpoints.clear();
	for (std::map<int, CAddrBreakpoint *>::iterator it = this->breakpointsPC.begin();
		 it != this->breakpointsPC.end(); it++)
	{
		debugInterface->breakpointsPC->breakpoints[it->first] = it->second;
	}
	debugInterface->breakOnPC = this->breakOnPC;
	
	// raster
	debugInterface->breakpointsRaster->breakpoints.clear();
	for (std::map<int, CAddrBreakpoint *>::iterator it = this->breakpointsRaster.begin(); it != this->breakpointsRaster.end(); it++)
	{
		debugInterface->breakpointsRaster->breakpoints[it->first] = it->second;
	}
	debugInterface->breakOnRaster = this->breakOnRaster;

	// memory
	debugInterface->breakpointsMemory->breakpoints.clear();
	for (std::map<int, CMemoryBreakpoint *>::iterator it = this->breakpointsMemory.begin(); it != this->breakpointsMemory.end(); it++)
	{
		debugInterface->breakpointsMemory->breakpoints[it->first] = it->second;
	}
	debugInterface->breakOnMemory = this->breakOnMemory;
	
	//
	// activate labels
	CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
	
	if (viewDisassembleMainCpu)
	{
		viewDisassembleMainCpu->codeLabels.clear();
		for(std::map<int, CDisassembleCodeLabel *> ::iterator it = this->codeLabels.begin(); it != this->codeLabels.end(); it++)
		{
			viewDisassembleMainCpu->codeLabels[it->first] = it->second;
		}
		
		viewDisassembleMainCpu->UpdateLabelsPositions();
	}
	
	CViewBreakpoints *viewBreakpoints = debugInterface->GetViewBreakpoints();
	if (viewBreakpoints)
	{
		viewBreakpoints->UpdateRenderBreakpoints();
	}
	
	// TODO: add 1541 drive watches
	CViewDataWatch *viewMemoryDataWatch = debugInterface->GetViewMemoryDataWatch();
	if (viewMemoryDataWatch)
	{
		// activate watches
		viewMemoryDataWatch->watches.clear();
		for(std::map<int, CDataWatchDetails *> ::iterator it = this->watches.begin(); it != this->watches.end(); it++)
		{
			viewMemoryDataWatch->watches[it->first] = it->second;
		}
	}
	
	// TODO: this is really ugly code, make this generic somehow and specific for C64
	if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
	{
		C64DebugInterface *debugInterfaceC64 = (C64DebugInterface*)debugInterface;
		debugInterfaceC64->breakOnC64IrqVIC = this->breakOnC64IrqVIC;
		debugInterfaceC64->breakOnC64IrqCIA = this->breakOnC64IrqCIA;
		debugInterfaceC64->breakOnC64IrqNMI = this->breakOnC64IrqNMI;
	}
	
	this->symbols->currentSelectedSegment = this;
	this->symbols->currentSelectedSegmentNum = this->segmentNum;
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64AsmSourceSegment::CopyBreakpointsAndWatchesFromDebugInterface(CDebugInterface *debugInterface)
{
	// PC breakpoints
	this->breakpointsPC.clear();
	for (std::map<int, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsPC->breakpoints.begin();
		 it != debugInterface->breakpointsPC->breakpoints.end(); it++)
	{
		this->breakpointsPC[it->first] = it->second;
	}
	this->breakOnPC = debugInterface->breakOnPC;
	
	// raster
	this->breakpointsRaster.clear();
	for (std::map<int, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsRaster->breakpoints.begin();
		 it != debugInterface->breakpointsRaster->breakpoints.end(); it++)
	{
		this->breakpointsRaster[it->first] = it->second;
	}
	this->breakOnRaster = debugInterface->breakOnRaster;
	
	// memory
	this->breakpointsMemory.clear();
	for (std::map<int, CMemoryBreakpoint *>::iterator it = debugInterface->breakpointsMemory->breakpoints.begin(); it != debugInterface->breakpointsMemory->breakpoints.end(); it++)
	{
		this->breakpointsMemory[it->first] = it->second;
	}
	this->breakOnMemory = debugInterface->breakOnMemory;
	
	// TODO: this is really ugly code, make this generic
	if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
	{
		C64DebugInterface *debugInterfaceC64 = (C64DebugInterface*)debugInterface;
		this->breakOnC64IrqVIC = debugInterfaceC64->breakOnC64IrqVIC;
		this->breakOnC64IrqCIA = debugInterfaceC64->breakOnC64IrqCIA;
		this->breakOnC64IrqNMI = debugInterfaceC64->breakOnC64IrqNMI;
	}
	
	CViewDataWatch *viewMemoryDataWatch = debugInterface->GetViewMemoryDataWatch();
	if (viewMemoryDataWatch)
	{
		// copy watches
		this->watches.clear();
		for (std::map<int, CDataWatchDetails *>::iterator it = viewMemoryDataWatch->watches.begin();
			 it != viewMemoryDataWatch->watches.end(); it++)
		{
			this->watches[it->first] = it->second;
		}
	}
}

void C64AsmSourceSymbols::DeactivateSegment()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	// PC breakpoints
	debugInterface->breakpointsPC->breakpoints.clear();
	debugInterface->breakOnPC = false;
	debugInterface->breakpointsRaster->breakpoints.clear();
	debugInterface->breakOnRaster = false;
	debugInterface->breakpointsMemory->breakpoints.clear();
	debugInterface->breakOnMemory = false;
	
	// TODO: this is really ugly code, make this generic
	if (debugInterface->GetEmulatorType() == EMULATOR_TYPE_C64_VICE)
	{
		C64DebugInterface *debugInterfaceC64 = (C64DebugInterface*)debugInterface;
		debugInterfaceC64->breakOnC64IrqVIC = false;
		debugInterfaceC64->breakOnC64IrqCIA = false;
		debugInterfaceC64->breakOnC64IrqNMI = false;
	}
	
	// deactivate labels
	CViewDisassemble *viewDisassembleMainCpu = debugInterface->GetViewMainCpuDisassemble();
	if (viewDisassembleMainCpu)
	{
		viewDisassembleMainCpu->codeLabels.clear();
		viewDisassembleMainCpu->UpdateLabelsPositions();
	}
	
	CViewDataWatch *viewMemoryDataWatch = debugInterface->GetViewMemoryDataWatch();
	if (viewMemoryDataWatch)
	{
		// deactivate watches
		viewMemoryDataWatch->watches.clear();
	}
	
	this->currentSelectedSegment = NULL;
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

//
void C64AsmSourceSymbols::SelectNextSegment()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();

	this->currentSelectedSegment->CopyBreakpointsAndWatchesFromDebugInterface(this->debugInterface);

	this->currentSelectedSegmentNum++;
	
	if (this->currentSelectedSegmentNum == this->segments.size())
	{
		this->currentSelectedSegmentNum = 0;
	}
	
	C64AsmSourceSegment *segment = this->segments[this->currentSelectedSegmentNum];
	this->ActivateSegment(segment);
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}

void C64AsmSourceSymbols::SelectPreviousSegment()
{
	guiMain->LockMutex();
	debugInterface->LockMutex();
	
	this->currentSelectedSegment->CopyBreakpointsAndWatchesFromDebugInterface(this->debugInterface);
	
	if (this->currentSelectedSegmentNum == 0)
	{
		this->currentSelectedSegmentNum = this->segments.size()-1;
	}
	else
	{
		this->currentSelectedSegmentNum--;
	}
	C64AsmSourceSegment *segment = this->segments[this->currentSelectedSegmentNum];
	this->ActivateSegment(segment);
	
	debugInterface->UnlockMutex();
	guiMain->UnlockMutex();
}



C64AsmSourceBlock::C64AsmSourceBlock(C64AsmSourceSegment *segment, CSlrString *name)
{
	this->segment = segment;
	this->name = name;
	
//	codeSourceLineByMemoryAddress = new C64AsmSourceLine* [symbols->maxMemoryAddress];
//	for (int i = 0; i < symbols->maxMemoryAddress; i++)
//	{
//		codeSourceLineByMemoryAddress[i] = NULL;
//	}
}

C64AsmSourceBlock::~C64AsmSourceBlock()
{
	name->DebugPrint("~C64AsmSourceBlock: ");
	delete name;
}

C64AsmSourceFile::~C64AsmSourceFile()
{
	sourceFileName->DebugPrint("~C64AsmSourceFile: ");
	
	delete sourceFilePath;
	delete sourceFileName;

	while (!codeTextByLineNum.empty())
	{
		CSlrString *t = codeTextByLineNum.back();
		codeTextByLineNum.pop_back();
		delete t;
	}

	while (!asmSourceLines.empty())
	{
		C64AsmSourceLine *l = asmSourceLines.back();
		asmSourceLines.pop_back();
		delete l;
	}
}


