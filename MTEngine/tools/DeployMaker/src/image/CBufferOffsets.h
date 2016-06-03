#ifndef IMG_CBUFFEROFFSETS_
#define IMG_CBUFFEROFFSETS_

#include "SYS_Defs.h"
#include "SYS_Main.h"
#include "DBG_Log.h"

class CBufferOffsets
{
	public:
		CBufferOffsets(byte imageType, unsigned int height, unsigned int width);
		~CBufferOffsets();

		unsigned int height;
		unsigned int width;
		byte type;
		unsigned int **offsets;
		CBufferOffsets *next;
		CBufferOffsets *prev;
};

class CBufferOffsetsList
{
	public:
		CBufferOffsetsList();
		~CBufferOffsetsList();

		CBufferOffsets *first;
		CBufferOffsets *last;
};

CBufferOffsets * IMG_GetBufferOffsets(byte imageType, unsigned int height, unsigned int width);
void IMG_FreeAllBufferOffsets();

#endif /*IMG_CBUFFEROFFSETS_*/
