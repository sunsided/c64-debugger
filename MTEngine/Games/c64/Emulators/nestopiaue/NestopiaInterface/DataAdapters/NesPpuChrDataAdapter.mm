#include "NesPpuChrDataAdapter.h"
#include "NesDebugInterface.h"

NesPpuChrDataAdapter::NesPpuChrDataAdapter(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesPpuChrDataAdapter::AdapterGetDataLength()
{
	return 0x10000;
}


void NesPpuChrDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte(pointer);
}

void NesPpuChrDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte(pointer, value);
}


void NesPpuChrDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
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

void NesPpuChrDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByte(pointer, value);
	*isAvailable = true;
}

void NesPpuChrDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemory(buffer, pointerStart, pointerEnd);
}


