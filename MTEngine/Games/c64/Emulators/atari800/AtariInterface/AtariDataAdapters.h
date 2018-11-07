#ifndef _ATARIDATAADAPTERS_H_
#define _ATARIDATAADAPTERS_H_

#include "CSlrDataAdapter.h"

class AtariDebugInterface;

class AtariDataAdapter : public CSlrDataAdapter
{
public:
	AtariDataAdapter(AtariDebugInterface *debugInterface);
	AtariDebugInterface *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};



#endif

