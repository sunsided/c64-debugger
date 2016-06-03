#include "CSlrDataAdapter.h"

//void CSlrDataAdapterCallback::ReadByteCallback(CSlrDataAdapter *adapter, int pointer, byte value, bool isAvailable)
//{
//}
//
//void CSlrDataAdapterCallback::WriteByteCallback(CSlrDataAdapter *adapter, int pointer, byte value, bool isAvailable)
//{
//}

CSlrDataAdapter::CSlrDataAdapter()
{
	//this->callback = NULL;
}

CSlrDataAdapter::~CSlrDataAdapter()
{
}

int CSlrDataAdapter::AdapterGetDataLength()
{
	return -1;
}

void CSlrDataAdapter::AdapterReadByte(int pointer, byte *value)
{
	
}

void CSlrDataAdapter::AdapterWriteByte(int pointer, byte value)
{
	
}

void CSlrDataAdapter::AdapterReadByte(int pointer, byte *value, bool *isAvailable)
{
//	if (this->callback != NULL)
//	{
//		this->callback->ReadByteCallback(this, pointer, value, isAvailable);
//	}
}

void CSlrDataAdapter::AdapterWriteByte(int pointer, byte value, bool *isAvailable)
{
//	if (this->callback != NULL)
//	{
//		this->callback->WriteByteCallback(this, pointer, value, isAvailable);
//	}
}

void CSlrDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
}
