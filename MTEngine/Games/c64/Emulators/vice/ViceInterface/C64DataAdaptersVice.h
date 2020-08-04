#ifndef _C64DATAADAPTERSVICE_H_
#define _C64DATAADAPTERSVICE_H_

#include "CSlrDataAdapter.h"

class C64DebugInterfaceVice;

class C64DataAdapterVice : public CSlrDataAdapter
{
public:
	C64DataAdapterVice(C64DebugInterfaceVice *debugInterface);
	C64DebugInterfaceVice *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};

class C64DirectRamDataAdapterVice : public CSlrDataAdapter
{
public:
	C64DirectRamDataAdapterVice(C64DebugInterfaceVice *debugInterface);
	C64DebugInterfaceVice *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};

class C64DiskDataAdapterVice : public CSlrDataAdapter
{
public:
	C64DiskDataAdapterVice(C64DebugInterfaceVice *debugInterface);
	C64DebugInterfaceVice *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};

class C64DiskDirectRamDataAdapterVice : public CSlrDataAdapter
{
public:
	C64DiskDirectRamDataAdapterVice(C64DebugInterfaceVice *debugInterface);
	C64DebugInterfaceVice *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};

//
class C64ReuDataAdapterVice : public CSlrDataAdapter
{
public:
	C64ReuDataAdapterVice(C64DebugInterfaceVice *debugInterface);
	C64DebugInterfaceVice *debugInterface;
	
	virtual int AdapterGetDataLength();
	virtual void AdapterReadByte(int pointer, uint8 *value);
	virtual void AdapterWriteByte(int pointer, uint8 value);
	virtual void AdapterReadByte(int pointer, uint8 *value, bool *isAvailable);
	virtual void AdapterWriteByte(int pointer, uint8 value, bool *isAvailable);
	virtual void AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd);
};


#endif

