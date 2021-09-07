#include "C64D_Version.h"

#include "NstApiMachine.hpp"
#include "NstMachine.hpp"
#include "NstApiEmulator.hpp"
#include "NstCpu.hpp"
#include "NstPpu.hpp"

#include "NesPpuNmtDataAdapter.h"
#include "NesDebugInterface.h"

extern Nes::Api::Emulator nesEmulator;

NesPpuNmtDataAdapter::NesPpuNmtDataAdapter(NesDebugInterface *debugInterface)
: CDebugDataAdapter(debugInterface)
{
	this->debugInterface = debugInterface;
}

int NesPpuNmtDataAdapter::AdapterGetDataLength()
{
	return 0x1000;
}

int NesPpuNmtDataAdapter::GetDataOffset()
{
	return 0x2000;
}

void NesPpuNmtDataAdapter::AdapterReadByte(int pointer, uint8 *value)
{
	Nes::Core::Machine& machine = nesEmulator;
	*value = machine.ppu.nmt.Peek(pointer);
}

void NesPpuNmtDataAdapter::AdapterWriteByte(int pointer, uint8 value)
{
	Nes::Core::Machine& machine = nesEmulator;
	machine.ppu.nmt.Poke(pointer, value);
}


void NesPpuNmtDataAdapter::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer < 0x1000)
	{
		*isAvailable = true;
		Nes::Core::Machine& machine = nesEmulator;
		*value = machine.ppu.nmt.Peek(pointer); // + 0x2000);
	}
	else
	{
		*isAvailable = false;
	}
}

void NesPpuNmtDataAdapter::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	if (pointer < 0x1000)
	{
		*isAvailable = true;
		Nes::Core::Machine& machine = nesEmulator;
		machine.ppu.nmt.Poke(pointer, value);
	}
	else
	{
		*isAvailable = false;
	}
}

void NesPpuNmtDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	Nes::Core::Machine& machine = nesEmulator;
	int addr;
	u8 *bufPtr = buffer + pointerStart;
	for (addr = pointerStart; addr < pointerEnd; addr++)
	{
		*bufPtr++ = machine.ppu.nmt.Peek(addr);
	}
}

