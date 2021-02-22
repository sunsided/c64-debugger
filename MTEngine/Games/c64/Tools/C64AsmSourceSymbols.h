#ifndef _C64ASMSOURCE_H_
#define _C64ASMSOURCE_H_

// TODO: refactor this to generic CAsmSourceSymbols and generalise with Atari800
// TODO: move currentSelectedSegment to CDebugInterface

#include "SYS_Defs.h"
#include "CSlrString.h"
#include "CDebuggerBreakpoints.h"
#include <map>
#include <vector>

class CByteBuffer;
class CDebugInterface;

class C64AsmSourceBlock;
class C64AsmSourceSegment;
class C64AsmSourceLine;
class C64AsmSourceSymbols;
class CDisassembleCodeLabel;
class CDataWatchDetails;
class CSlrFile;

class C64AsmSourceFile
{
public:
	~C64AsmSourceFile();
	
	CSlrString *sourceFilePath;
	CSlrString *sourceFileName;
	int sourceId;
	
	std::vector<CSlrString *> codeTextByLineNum;
	
	// for deletion purposes:
	std::list<C64AsmSourceLine *> asmSourceLines;
};

class C64AsmSourceLine
{
public:
	C64AsmSourceFile *codeFile;
	C64AsmSourceBlock *block;
	
	int codeLineNumberStart;
	int codeColumnNumberStart;
	int codeLineNumberEnd;
	int codeColumnNumberEnd;
	
	u32 memoryAddressStart;
	u32 memoryAddressEnd;
};

class C64AsmSourceBlock
{
public:
	C64AsmSourceBlock(C64AsmSourceSegment *segment, CSlrString *name);
	~C64AsmSourceBlock();
	CSlrString *name;

	C64AsmSourceSegment *segment;
//	C64AsmSourceLine **codeSourceLineByMemoryAddress;
};

class C64AsmSourceSegment
{
public:
	C64AsmSourceSegment(C64AsmSourceSymbols *symbols, CSlrString *name, int segmentNum);
	~C64AsmSourceSegment();
	
	int segmentNum;
	CSlrString *name;
	
	C64AsmSourceSymbols *symbols;
	
	C64AsmSourceLine **codeSourceLineByMemoryAddress;
	std::vector<C64AsmSourceBlock *> blocks;

	// breakpoints
	bool breakOnPC;
	std::map<int, CAddrBreakpoint *> breakpointsPC;
	bool breakOnMemory;
	std::map<int, CMemoryBreakpoint *> breakpointsMemory;
	bool breakOnRaster;
	std::map<int, CAddrBreakpoint *> breakpointsRaster;

	bool breakOnC64IrqVIC;
	bool breakOnC64IrqCIA;
	bool breakOnC64IrqNMI;
	
	//
	void AddBreakpointPC(int address);
	void AddBreakpointSetBackground(int address, int value);
	void AddBreakpointRaster(int rasterNum);
	void AddBreakpointMemory(int address, u8 breakpointType, int value);
	void AddBreakpointVIC();
	void AddBreakpointCIA();
	void AddBreakpointNMI();
	
	// labels
	std::map<int, CDisassembleCodeLabel *> codeLabels;
	void AddCodeLabel(int address, char *text);
	CDisassembleCodeLabel *FindLabel(int address);
	
	// watches
	std::map<int, CDataWatchDetails *> watches;
	void AddWatch(int address, int numberOfValues, CSlrString *strRepresentation);
	void AddWatch(int address, char *name, uint8 representation, int numberOfValues, uint8 bits);
	
	//
	void Activate(CDebugInterface *debugInterface);
	void CopyBreakpointsAndWatchesFromDebugInterface(CDebugInterface *debugInterface);
};

class C64AsmSourceSymbols
{
public:
	C64AsmSourceSymbols(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
	~C64AsmSourceSymbols();
	CDebugInterface *debugInterface;
	
	void ParseXML(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
	void ParseOldFormat(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
	
	std::map<u32, C64AsmSourceFile *> codeSourceFilesById;
	std::vector<C64AsmSourceSegment *> segments;
	
	C64AsmSourceSegment *FindSegment(CSlrString *segmentName);
	
	int maxMemoryAddress;
	
	void LoadSource(C64AsmSourceFile *asmSourceFile, CSlrFile *file);
	
	// TODO: move currentSelectedSegment to CDebugInterface
	C64AsmSourceSegment *currentSelectedSegment;
	int currentSelectedSegmentNum;
	
	void ActivateSegment(C64AsmSourceSegment *segment);
	void DeactivateSegment();
	
	//
	void SelectNextSegment();
	void SelectPreviousSegment();
};

#endif
//_C64ASMSOURCE_H_

