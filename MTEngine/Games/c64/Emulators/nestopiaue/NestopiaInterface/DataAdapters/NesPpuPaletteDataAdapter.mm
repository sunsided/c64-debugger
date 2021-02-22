#include "NesPpuPaletteDataAdapter.h"
#include "NesDebugInterface.h"

NesPpuPaletteDataAdapter::NesPpuPaletteDataAdapter(NesDebugInterface *debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesPpuPaletteDataAdapter::AdapterGetDataLength()
{
	return 0x10000;
}


void NesPpuPaletteDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte(pointer);
}

void NesPpuPaletteDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte(pointer, value);
}


void NesPpuPaletteDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
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

void NesPpuPaletteDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByte(pointer, value);
	*isAvailable = true;
}

void NesPpuPaletteDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemory(buffer, pointerStart, pointerEnd);
}


