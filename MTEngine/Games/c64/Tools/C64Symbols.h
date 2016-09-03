#ifndef _C64SYMBOLS_H_
#define _C64SYMBOLS_H_

#include "SYS_Defs.h"
#include <list>

class CSlrFile;
class CByteBuffer;
class CSlrString;
class C64DebugInterface;

#define C64_SYMBOL_DEVICE_COMMODORE	1
#define C64_SYMBOL_DEVICE_DRIVE1541	2

class C64Symbols
{
public:
	C64Symbols();
	~C64Symbols();
	
	void ParseSymbols(char *fileName, C64DebugInterface *debugInterface);
	void ParseSymbols(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
	void ParseBreakpoints(char *fileName, C64DebugInterface *debugInterface);
	void ParseBreakpoints(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
};

#endif
