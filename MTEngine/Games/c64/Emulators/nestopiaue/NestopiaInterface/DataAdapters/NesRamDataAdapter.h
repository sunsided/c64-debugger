#ifndef _NesRamDataAdapter_H_
#define _NesRamDataAdapter_H_

#include "CDebugDataAdapter.h"

class NesDebugInterface;

class NesRamDataAdapter : public CDebugDataAdapter
{
public:
	NesRamDataAdapter(NesDebugInterface *debugInterface);
	NesDebugInterface *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};



#endif

