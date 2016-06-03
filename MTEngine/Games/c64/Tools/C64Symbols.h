#ifndef _C64SYMBOLS_H_
#define _C64SYMBOLS_H_

#include "SYS_Defs.h"
#include <map>

class CSlrFile;
class CByteBuffer;
class CSlrString;
class C64DebugInterface;

class C64Symbol
{
public:
	int address;
	CSlrString *label;
};

class C64Symbols
{
public:
	C64Symbols();
	~C64Symbols();
	
	void ParseSymbols(CByteBuffer *byteBuffer);
	void ParseBreakpoints(char *fileName, C64DebugInterface *debugInterface);
	void ParseBreakpoints(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
	
	std::map<int, C64Symbol *> symbols;
};

#endif
