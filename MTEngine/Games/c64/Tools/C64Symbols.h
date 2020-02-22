#ifndef _C64SYMBOLS_H_
#define _C64SYMBOLS_H_

#include "SYS_Defs.h"
#include <list>

class CSlrFile;
class CByteBuffer;
class CSlrString;
class CDebugInterface;
class C64AsmSourceSymbols;

#define C64_SYMBOL_DEVICE_COMMODORE	1
#define C64_SYMBOL_DEVICE_DRIVE1541	2

class C64Symbols
{
public:
	C64Symbols(CDebugInterface *debugInterface);
	~C64Symbols();
	
	CDebugInterface *debugInterface;
	C64AsmSourceSymbols *asmSource;
	
	void DeleteAllSymbols();
	void ParseSymbols(CSlrString *fileName);
	void ParseSymbols(CSlrFile *file);
	void ParseSymbols(CByteBuffer *byteBuffer);
	
	void DeleteAllBreakpoints();
	void ParseBreakpoints(CSlrString *fileName);
	void ParseBreakpoints(CByteBuffer *byteBuffer);
	
	void DeleteAllWatches();
	void ParseWatches(CSlrString *fileName);
	void ParseWatches(CSlrFile *file);
	void ParseWatches(CByteBuffer *byteBuffer);

	void DeleteSourceDebugInfo();
	void ParseSourceDebugInfo(CSlrString *fileName);
	void ParseSourceDebugInfo(CSlrFile *file);
	void ParseSourceDebugInfo(CByteBuffer *byteBuffer);
};

#endif
