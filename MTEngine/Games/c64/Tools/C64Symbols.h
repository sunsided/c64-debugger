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
	C64Symbols();
	~C64Symbols();
	
	C64AsmSourceSymbols *asmSource;
	
	void DeleteAllSymbols(CDebugInterface *debugInterface);
	void ParseSymbols(CSlrString *fileName, CDebugInterface *debugInterface);
	void ParseSymbols(CSlrFile *file, CDebugInterface *debugInterface);
	void ParseSymbols(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
	
	void DeleteAllBreakpoints(CDebugInterface *debugInterface);
	void ParseBreakpoints(CSlrString *fileName, CDebugInterface *debugInterface);
	void ParseBreakpoints(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
	
	void DeleteAllWatches(CDebugInterface *debugInterface);
	void ParseWatches(CSlrString *fileName, CDebugInterface *debugInterface);
	void ParseWatches(CSlrFile *file, CDebugInterface *debugInterface);
	void ParseWatches(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);

	void DeleteSourceDebugInfo(CDebugInterface *debugInterface);
	void ParseSourceDebugInfo(CSlrString *fileName, CDebugInterface *debugInterface);
	void ParseSourceDebugInfo(CSlrFile *file, CDebugInterface *debugInterface);
	void ParseSourceDebugInfo(CByteBuffer *byteBuffer, CDebugInterface *debugInterface);
};

#endif
