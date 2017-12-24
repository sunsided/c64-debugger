#ifndef _C64SYMBOLS_H_
#define _C64SYMBOLS_H_

#include "SYS_Defs.h"
#include <list>

class CSlrFile;
class CByteBuffer;
class CSlrString;
class C64DebugInterface;
class C64AsmSource;

#define C64_SYMBOL_DEVICE_COMMODORE	1
#define C64_SYMBOL_DEVICE_DRIVE1541	2

class C64Symbols
{
public:
	C64Symbols();
	~C64Symbols();
	
	C64AsmSource *asmSource;
	
	void ClearSymbols(C64DebugInterface *debugInterface);
	void ParseSymbols(CSlrString *fileName, C64DebugInterface *debugInterface);
	void ParseSymbols(CSlrFile *file, C64DebugInterface *debugInterface);
	void ParseSymbols(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
	
	void ClearBreakpoints(C64DebugInterface *debugInterface);
	void ParseBreakpoints(CSlrString *fileName, C64DebugInterface *debugInterface);
	void ParseBreakpoints(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
	
	void ClearWatches(C64DebugInterface *debugInterface);
	void ParseWatches(CSlrString *fileName, C64DebugInterface *debugInterface);
	void ParseWatches(CSlrFile *file, C64DebugInterface *debugInterface);
	void ParseWatches(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);

	void ClearSourceDebugInfo(C64DebugInterface *debugInterface);
	void ParseSourceDebugInfo(CSlrString *fileName, C64DebugInterface *debugInterface);
	void ParseSourceDebugInfo(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
};

#endif
