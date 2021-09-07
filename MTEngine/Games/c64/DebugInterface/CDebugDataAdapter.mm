//
//  CDebugDataAdapter.cpp
//  MTEngine-MacOS
//
//  Created by Marcin Skoczylas on 04/02/2021.
//

#include "SYS_Defs.h"
#include "CDebugInterface.h"
#include "CDebugDataAdapter.h"
#include "CViewMemoryMap.h"

CDebugDataAdapter::CDebugDataAdapter(CDebugInterface *debugInterface)
: CSlrDataAdapter()
{
	this->debugInterface = debugInterface;
	this->viewMemoryMap = NULL;
}

void CDebugDataAdapter::SetViewMemoryMap(CViewMemoryMap *viewMemoryMap)
{
	this->viewMemoryMap = viewMemoryMap;
}

int CDebugDataAdapter::AdapterGetDataLength()
{
	return CSlrDataAdapter::AdapterGetDataLength();
}

int CDebugDataAdapter::GetDataOffset()
{
	return CSlrDataAdapter::GetDataOffset();
}

void CDebugDataAdapter::AdapterReadByte(int addr, uint8 *value)
{
	CSlrDataAdapter::AdapterReadByte(addr, value);
}

void CDebugDataAdapter::AdapterWriteByte(int addr, uint8 value)
{
	CSlrDataAdapter::AdapterWriteByte(addr, value);
}

void CDebugDataAdapter::AdapterReadByte(int addr, uint8 *value, bool *isAvailable)
{
	CSlrDataAdapter::AdapterReadByte(addr, value, isAvailable);
}

void CDebugDataAdapter::AdapterWriteByte(int addr, uint8 value, bool *isAvailable)
{
	CSlrDataAdapter::AdapterWriteByte(addr, value, isAvailable);
}

void CDebugDataAdapter::AdapterReadBlockDirect(uint8 *buffer, int addrStart, int addrEnd)
{
	CSlrDataAdapter::AdapterReadBlockDirect(buffer, addrStart, addrEnd);
}

void CDebugDataAdapter::MarkCellRead(int addr)
{
	int pc = debugInterface->GetCpuPC();
	viewMemoryMap->CellRead(addr, pc, -1, -1);
}

void CDebugDataAdapter::MarkCellRead(int addr, int pc, int rasterX, int rasterY)
{
	viewMemoryMap->CellRead(addr, pc, rasterX, rasterY);
}

void CDebugDataAdapter::MarkCellWrite(int addr, uint8 value)
{
	int pc = debugInterface->GetCpuPC();
	viewMemoryMap->CellWrite(addr, value, pc, -1, -1);
}

void CDebugDataAdapter::MarkCellWrite(int addr, uint8 value, int pc, int rasterX, int rasterY)
{
	viewMemoryMap->CellWrite(addr, value, pc, rasterX, rasterY);
}

void CDebugDataAdapter::MarkCellExecute(int addr, uint8 opcode)
{
	viewMemoryMap->CellExecute(addr, opcode);
}
