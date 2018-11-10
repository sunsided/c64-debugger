#include "SYS_SharedMemory.h"
#include "SYS_Threading.h"
#include "CSlrString.h"
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <list>

void *mtSharedMemoryDescriptor = NULL;
uint8 *mtSharedMemory = NULL;
u32 mtSharedMemorySize = 0;
u32 mtSharedMemoryKey = 0;

std::list<CSharedMemorySignalCallback *> mtSharedMemoryCallbacks;
CSlrMutex *mtSharedMemoryMutex;

void mtEngineSignalHandlerUSR(int signo);


// MacOS Xcode workaround to pass SIGUSR1:
// |  add symbolic breakpoint on symbol NSApplicationMain with empty module and condition
// |      set Action "Debugger Command": process handle SIGUSR1 -n true -p true -s false
// |      set to continue execution

void SYS_InitSharedMemory(u32 sharedMemoryKey, u32 sharedMemorySize)
{
	LOGD("SYS_InitSharedMemory: key=%d size=%d", sharedMemoryKey, sharedMemorySize);
	
	mtSharedMemoryMutex = new CSlrMutex();
	
	mtSharedMemory = SYS_MapSharedMemory(sharedMemorySize, sharedMemoryKey, &mtSharedMemoryDescriptor);
	
	if (mtSharedMemory == NULL)
	{
		LOGError("SYS_InitSharedMemory: mtSharedMemory is NULL!");
		return;
	}
	
	mtSharedMemorySize = sharedMemorySize;
	mtSharedMemoryKey = sharedMemoryKey;
	
	memset(mtSharedMemory, 0, sharedMemorySize);
}

void SYS_InitSharedMemorySignalHandlers()
{
#if !defined(WIN32)
	// set signal
	struct sigaction sa;
	sa.sa_handler = &mtEngineSignalHandlerUSR;
	sa.sa_flags = SA_RESTART;
	sigfillset(&sa.sa_mask);
	
	if (sigaction(SIGUSR1, &sa, NULL) == -1)
	{
		LOGError("SYS_InitSignalHandlers: can't catch SIGUSR1");
	}
#else
	if (signal(SIGUSR1, mtEngineSignalHandlerUSR))
	{
		LOGError("SYS_InitSignalHandlers: can't catch SIGUSR1");
	}
#endif
}

void SYS_SharedMemoryRegisterCallback(CSharedMemorySignalCallback *callback)
{
	mtSharedMemoryMutex->Lock();
	
	mtSharedMemoryCallbacks.push_back(callback);
	
	mtSharedMemoryMutex->Unlock();
}

void SYS_SharedMemoryUnregisterCallback(CSharedMemorySignalCallback *callback)
{
	mtSharedMemoryMutex->Lock();
	
	mtSharedMemoryCallbacks.remove(callback);
	
	mtSharedMemoryMutex->Unlock();
}

void mtEngineSignalHandlerUSR(int signo)
{
	LOGD("mtEngineSignalHandlerUSR");
	
	if (signo == SIGUSR1)
	{
		// load new configuration from shared memory
		uint32 dataSize;
		uint8 *data = SYS_ReadFromSharedMemory(&dataSize);
		
		CByteBuffer *byteBuffer = new CByteBuffer(data, dataSize);
		
		mtSharedMemoryMutex->Lock();
		
		for (std::list<CSharedMemorySignalCallback *>::iterator it = mtSharedMemoryCallbacks.begin(); it != mtSharedMemoryCallbacks.end(); it++)
		{
			CSharedMemorySignalCallback *callback = *it;
			byteBuffer->Rewind();
			callback->SharedMemorySignalCallback(byteBuffer);
		}
		
		mtSharedMemoryMutex->Unlock();

		delete byteBuffer;
		
		memset(mtSharedMemory, 0, mtSharedMemorySize);
	}
	
	LOGD("mtEngineSignalHandlerUSR done");
}

void SYS_StoreToSharedMemory(uint8 *data, uint32 dataSize)
{
	LOGD("SYS_StoreToSharedMemory: length=%d", dataSize);
	
	if (mtSharedMemory == NULL)
	{
		LOGError("SYS_StoreToSharedMemory: sharedMemory is NULL!");
		return;
	}
	
	if (dataSize >= mtSharedMemorySize)
	{
		LOGError("SYS_StoreToSharedMemory: dataSize=%d > max=%d", dataSize, mtSharedMemorySize);
		return;
	}
	
	mtSharedMemory[0] = (uint8) (((dataSize) >> 24) & 0x00FF);
	mtSharedMemory[1] = (uint8) (((dataSize) >> 16) & 0x00FF);
	mtSharedMemory[2] = (uint8) (((dataSize) >> 8) & 0x00FF);
	mtSharedMemory[3] = (uint8) ((dataSize) & 0x00FF);
	
	memcpy(mtSharedMemory + 4, data, dataSize);
	
	LOGD("SYS_StoreToSharedMemory: stored %d bytes", dataSize);
}

uint8 *SYS_ReadFromSharedMemory(uint32 *dataSize)
{
	LOGD("SYS_ReadFromSharedMemory");
	if (mtSharedMemory == NULL)
	{
		LOGError("SYS_ReadFromSharedMemory: sharedMemory is NULL!");
		*dataSize = 0;
		return NULL;
	}
	
	*dataSize = mtSharedMemory[3] | (mtSharedMemory[2] << 8) | (mtSharedMemory[1] << 16) | (mtSharedMemory[0] << 24);
	
	if (*dataSize >= mtSharedMemorySize)
	{
		LOGError("SYS_ReadFromSharedMemory: dataSize=%d > max=%d", *dataSize, mtSharedMemorySize);
		*dataSize = 0;
		return NULL;
	}
	
	uint8 *data = new uint8[*dataSize];
	
	memcpy(data, mtSharedMemory + 4, *dataSize);
	
	LOGD("SYS_ReadFromSharedMemory: read %d bytes", *dataSize);
	return data;
}

int SYS_SendConfigurationToOtherAppInstance(CByteBuffer *byteBuffer)
{

	// Find other instance pid, store data to shared memory and raise signal SIGUSR1


	/////
	
	// MacOS
	
	
	//	http://www.cplusplus.com/forum/windows/12137/
	//https://ubuntuforums.org/showthread.php?t=1326074
	
	//http://stackoverflow.com/questions/2518160/programmatically-check-if-a-process-is-running-on-mac
	
	
	
	NSString *appBundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	int appPid = getpid();
	
	//NSLog(@"appBundleName=%@ appPid=%d", appBundleName, appPid);
	
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	while (GetNextProcess(&psn) == noErr)
	{
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
		if (cfDict)
		{
			NSDictionary *dict = (NSDictionary *)cfDict;
			
			NSString *bundleName = [dict objectForKey:(id)kCFBundleNameKey];
			NSString *bundlePidStr = [dict objectForKey:@"pid"];
			
			int bundlePid = [bundlePidStr intValue];
			//NSLog(@"  bundleName=%@ bundlePid=%d", bundleName, bundlePid);
			
			if ([appBundleName isEqualToString:bundleName] && appPid != bundlePid)
			{
				LOGD("Found other instance of app, pid=%d", bundlePid);
				CFRelease(cfDict);
				
				// Store new configuration to shared memory
				//LOGD("Send byteBuffer to pid=%d", bundlePid);
				//byteBuffer->DebugPrint();
				
				SYS_StoreToSharedMemory(byteBuffer->data, byteBuffer->length);
				
				// Send signal to instance to flag new data
				kill(bundlePid, SIGUSR1);
				
				return bundlePid;
			}
			CFRelease(cfDict);
		}
	}
	
	//NSLog(@"...");
	
	// other instance not found
	return -1;
}

//bool SYS_SharedMemoryExists(int memoryKeyId, int memorySize)
//{
//	int keyId = shmget(memoryKeyId, memorySize, NULL);
//
//	if (keyId == -1)
//		return false;
//
//	return true;
//}

uint8 *SYS_MapSharedMemory(int memorySize, int memoryKeyId, void **fileDescriptor)
{
	LOGD("SYS_MapSharedMemory: memoryKeyId=%d", memoryKeyId);
	int *fileHandle = (int*)malloc(sizeof(int));
	fileDescriptor = (void**)(&fileHandle);
	
	*fileHandle = shmget(memoryKeyId, memorySize, IPC_CREAT | 0666);
	
	uint8 *memory = NULL;
	memory = (uint8*)shmat(*fileHandle, NULL, 0);
	
	if (memory == (void *) -1)
	{
		LOGError("SYS_MapSharedMemory: errno=%d", errno);
		return NULL;
	}
	
	LOGD("SYS_MapSharedMemory: mapped memory=%x", memory);
	
	return memory;
}

void SYS_UnMapSharedMemory(void **fileDescriptor, uint8 *memory)
{
	LOGD("SYS_UnMapSharedMemory: memory=%x", memory);
	
	if (shmdt(memory) == -1)
	{
		LOGError("SYS_UnMapSharedMemory: errno=%d", errno);
	}
}

void CSharedMemorySignalCallback::SharedMemorySignalCallback(CByteBuffer *sharedMemoryData)
{
	
}

///

CSlrString *SYS_GetClipboardAsSlrString()
{
	LOGD("SYS_GetClipboardAsSlrString");
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	NSString *str = [pasteBoard stringForType:NSPasteboardTypeString];
	//	NSLog(@"SYS_GetClipboardAsSlrString: str=%@", str);
	
	if (str == nil)
		return NULL;
	
	CSlrString *retStr = FUN_ConvertNSStringToCSlrString(str);
	
	return retStr;
}

bool SYS_SetClipboardAsSlrString(CSlrString *str)
{
	LOGD("SYS_SetClipboardAsSlrString");
	
	NSString *nsStr = FUN_ConvertCSlrStringToNSString(str);
	
	NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard clearContents];
	[pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
	BOOL ret = [pasteBoard setString:nsStr forType:NSPasteboardTypeString];

	[nsStr dealloc];
	
	return (bool)ret;
}

