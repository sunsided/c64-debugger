#ifndef _CSLRDATAADAPTER_H_
#define _CSLRDATAADAPTER_H_

#include "SYS_Defs.h"

//
// CSlrDataAdapter: abstract/interface class to handle data space with callback
//

class CSlrDataAdapter;

//class CSlrDataAdapterCallback
//{
//public:
//	virtual void ReadByteCallback(CSlrDataAdapter *adapter, int pointer, byte value, bool isAvailable);
//	virtual void WriteByteCallback(CSlrDataAdapter *adapter, int pointer, byte value, bool isAvailable);
//};

class CSlrDataAdapter
{
public:
	CSlrDataAdapter();
	virtual ~CSlrDataAdapter();
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
	
	//CSlrDataAdapterCallback *callback;
};

#endif

