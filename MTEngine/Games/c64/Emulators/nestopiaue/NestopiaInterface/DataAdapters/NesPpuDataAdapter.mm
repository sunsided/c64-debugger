#include "NesPpuDataAdapter.h"
#include "NesDebugInterface.h"

NesPpuDataAdapter::NesPpuDataAdapter(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesPpuDataAdapter::AdapterGetDataLength()
{
	return 0x10000;
}


void NesPpuDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte(pointer);
}

void NesPpuDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte(pointer, value);
}


void NesPpuDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer < 0x10000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByte(pointer);
	}
	else
	{
		*isAvailable = false;
	}
}

void NesPpuDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByte(pointer, value);
	*isAvailable = true;
}

void NesPpuDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemory(buffer, pointerStart, pointerEnd);
}


