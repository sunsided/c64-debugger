#ifndef _C64DATAADAPTERS_H_
#define _C64DATAADAPTERS_H_

#include "CSlrDataAdapter.h"

class CSlrFile;
class CByteBuffer;


class C64FileDataAdapter : public CSlrDataAdapter
{
public:
	C64FileDataAdapter(CSlrFile *file);

	CByteBuffer *byteBuffer;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, byte *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, byte value, bool *isAvailable);
};

#endif
