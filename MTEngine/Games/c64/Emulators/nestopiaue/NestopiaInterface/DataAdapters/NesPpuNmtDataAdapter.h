#ifndef _NESPPUNMTDATAADAPTER_H_
#define _NESPPUNMTDATAADAPTER_H_

#include "CDebugDataAdapter.h"

class NesDebugInterface;

class NesPpuNmtDataAdapter : public CDebugDataAdapter
{
public:
	NesPpuNmtDataAdapter(NesDebugInterface *debugInterface);
	
	virtual int AdapterGetDataLength();
	
	// renderers should add this offset to the presented address
	virtual int GetDataOffset();
	
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};



#endif

