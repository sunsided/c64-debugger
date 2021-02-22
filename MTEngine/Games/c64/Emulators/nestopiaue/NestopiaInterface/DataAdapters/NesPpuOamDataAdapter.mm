#include "NesPpuOamDataAdapter.h"
#include "NesDebugInterface.h"

NesPpuOamDataAdapter::NesPpuOamDataAdapter(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesPpuOamDataAdapter::AdapterGetDataLength()
{
	return 0x10000;
}


void NesPpuOamDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte(pointer);
}

void NesPpuOamDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte(pointer, value);
}


void NesPpuOamDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
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

void NesPpuOamDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByte(pointer, value);
	*isAvailable = true;
}

void NesPpuOamDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemory(buffer, pointerStart, pointerEnd);
}


