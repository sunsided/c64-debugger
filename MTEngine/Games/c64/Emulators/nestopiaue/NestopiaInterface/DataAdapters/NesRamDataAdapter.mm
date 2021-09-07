#include "NesRamDataAdapter.h"
#include "NesDebugInterface.h"

NesRamDataAdapter::NesRamDataAdapter(NesDebugInterface *debugInterface)
: CDebugDataAdapter(debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesRamDataAdapter::AdapterGetDataLength()
{
	return 0x10000;
}


void NesRamDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte(pointer);
}

void NesRamDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte(pointer, value);
}


void NesRamDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
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

void NesRamDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByte(pointer, value);
	*isAvailable = true;
}

void NesRamDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemory(buffer, pointerStart, pointerEnd);
}
