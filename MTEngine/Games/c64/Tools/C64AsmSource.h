#ifndef _C64ASMSOURCE_H_
#define _C64ASMSOURCE_H_

#include "SYS_Defs.h"
#include "CSlrString.h"
#include <map>

class CByteBuffer;
class C64DebugInterface;

class C64AsmSourceFile
{
public:
	CSlrString *sourceFileName;
};

class C64AsmSourceLine
{
public:
	C64AsmSourceFile *codeFile;
	CSlrString *codeText;
	
	u32 codeLine;
	u32 memoryAddressStart;
	u32 memoryAddressEnd;
};

class C64AsmSource
{
public:
	C64AsmSource(CByteBuffer *byteBuffer, C64DebugInterface *debugInterface);
	std::list<C64AsmSourceFile *> codeSourceFiles;
	std::map<u32, C64AsmSourceLine *> codeStringByLine;
	std::map<u32, C64AsmSourceLine *> codeStringByMemoryAddress;
};

#endif
//_C64ASMSOURCE_H_

