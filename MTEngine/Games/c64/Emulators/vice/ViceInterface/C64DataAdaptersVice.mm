#include "C64DataAdaptersVice.h"
#include "C64DebugInterfaceVice.h"

C64DataAdapterVice::C64DataAdapterVice(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

int C64DataAdapterVice::AdapterGetDataLength()
{
	return 0x10000;
}


void C64DataAdapterVice::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByteC64(pointer);
}

void C64DataAdapterVice::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByteC64(pointer, value);
}


void C64DataAdapterVice::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer < 0x10000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByteC64(pointer);
	}
	else
	{
		*isAvailable = false;
	}
}

void C64DataAdapterVice::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByteC64(pointer, value);
	*isAvailable = true;
}

void C64DataAdapterVice::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemoryC64(buffer, pointerStart, pointerEnd);
}


///

C64DirectRamDataAdapterVice::C64DirectRamDataAdapterVice(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

int C64DirectRamDataAdapterVice::AdapterGetDataLength()
{
	return 0x10000;
}


void C64DirectRamDataAdapterVice::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByteFromRamC64(pointer);
}

void C64DirectRamDataAdapterVice::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByteToRamC64(pointer, value);
}


void C64DirectRamDataAdapterVice::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer >= 0 && pointer < 0x10000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByteFromRamC64(pointer);
	}
	else
	{
		*isAvailable = false;
	}
}

void C64DirectRamDataAdapterVice::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	this->debugInterface->SetByteToRamC64(pointer, value);
	if (pointer >= 0 && pointer < 0x10000)
	{
		*isAvailable = true;
	}
	else
	{
		*isAvailable = false;
	}
}

void C64DirectRamDataAdapterVice::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemoryFromRamC64(buffer, pointerStart, pointerEnd);
}

///

C64DiskDataAdapterVice::C64DiskDataAdapterVice(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

int C64DiskDataAdapterVice::AdapterGetDataLength()
{
	return 0x10000;
}


void C64DiskDataAdapterVice::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByte1541(pointer);
}

void C64DiskDataAdapterVice::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByte1541(pointer, value);
}

void C64DiskDataAdapterVice::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer >= 0x8000 && pointer <= 0x10000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByte1541(pointer);
		return;
	}
	else if (pointer < 0x2000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByte1541(pointer);
		return;
	}
	*isAvailable = false;
	*value = 0x00;
}

void C64DiskDataAdapterVice::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	if (pointer >= 0xc000)
	{
		*isAvailable = true;
		this->debugInterface->SetByte1541(pointer, value);
		return;
	}
	else if (pointer < 0x2000)
	{
		*isAvailable = true;
		this->debugInterface->SetByte1541(pointer, value);
		return;
	}
	*isAvailable = false;
}

void C64DiskDataAdapterVice::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemoryDrive1541(buffer, pointerStart, pointerEnd);
}


///

C64DiskDirectRamDataAdapterVice::C64DiskDirectRamDataAdapterVice(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

int C64DiskDirectRamDataAdapterVice::AdapterGetDataLength()
{
	return 0x10000;
}


void C64DiskDirectRamDataAdapterVice::AdapterReadByte(int pointer, uint8 *value)
{
	*value = this->debugInterface->GetByteFromRam1541(pointer);
}

void C64DiskDirectRamDataAdapterVice::AdapterWriteByte(int pointer, uint8 value)
{
	this->debugInterface->SetByteToRam1541(pointer, value);
}

void C64DiskDirectRamDataAdapterVice::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
	if (pointer >= 0xc000 && pointer <= 0x10000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByteFromRam1541(pointer);
		return;
	}
	else if (pointer < 0x2000)
	{
		*isAvailable = true;
		*value = this->debugInterface->GetByteFromRam1541(pointer);
		return;
	}
	*isAvailable = false;
	*value = 0x00;
}

void C64DiskDirectRamDataAdapterVice::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
	if (pointer < 0x1000)
	{
		*isAvailable = true;
		this->debugInterface->SetByteToRam1541(pointer, value);
		return;
	}
	*isAvailable = false;
}

void C64DiskDirectRamDataAdapterVice::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
	this->debugInterface->GetMemoryFromRamDrive1541(buffer, pointerStart, pointerEnd);
}

// REU

C64ReuDataAdapterVice::C64ReuDataAdapterVice(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

int C64ReuDataAdapterVice::AdapterGetDataLength()
{
	return 16*1024*1024; //16MB;
}


void C64ReuDataAdapterVice::AdapterReadByte(int pointer, uint8 *value)
{
//	*value = this->debugInterface->GetByteFromReu(pointer);
}

void C64ReuDataAdapterVice::AdapterWriteByte(int pointer, uint8 value)
{
//	this->debugInterface->SetByteToReu(pointer, value);
}

void C64ReuDataAdapterVice::AdapterReadByte(int pointer, uint8 *value, bool *isAvailable)
{
//	if (pointer < 16MB)
//	{
//		*isAvailable = true;
//		*value = this->debugInterface->GetByteReu(pointer);
//		return;
//	}
//	*isAvailable = false;
}

void C64ReuDataAdapterVice::AdapterWriteByte(int pointer, uint8 value, bool *isAvailable)
{
//	if (pointer < 16MB)
//	{
//		*isAvailable = true;
//		this->debugInterface->SetByteToReu(pointer, value);
//		return;
//	}
//	*isAvailable = false;
}

void C64ReuDataAdapterVice::AdapterReadBlockDirect(uint8 *buffer, int pointerStart, int pointerEnd)
{
//	this->debugInterface->GetMemoryFromReu(buffer, pointerStart, pointerEnd);
}

