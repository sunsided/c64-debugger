#ifndef _SYS_SHAREDMEMORY_H_
#define _SYS_SHAREDMEMORY_H_

#include "SYS_Main.h"
#include "CByteBuffer.h"

void SYS_InitSharedMemory(u32 sharedMemoryKey, u32 sharedMemorySize);
void SYS_InitSharedMemorySignalHandlers();

//bool SYS_SharedMemoryExists(int memoryKeyId, int memorySize);
uint8 *SYS_MapSharedMemory(int memorySize, int memoryKeyId, void **fileDescriptor);
void SYS_UnMapSharedMemory(void **fileDescriptor, uint8 *memory);

void SYS_StoreToSharedMemory(uint8 *data, uint32 dataSize);
uint8 *SYS_ReadFromSharedMemory(uint32 *dataSize);

int SYS_SendConfigurationToOtherAppInstance(CByteBuffer *byteBuffer);

class CSharedMemorySignalCallback
{
public:
	virtual void SharedMemorySignalCallback(CByteBuffer *sharedMemoryData);
};

void SYS_SharedMemoryRegisterCallback(CSharedMemorySignalCallback *callback);
void SYS_SharedMemoryUnregisterCallback(CSharedMemorySignalCallback *callback);

//

CSlrString *SYS_GetClipboardAsSlrString();
bool SYS_SetClipboardAsSlrString(CSlrString *str);


#endif
