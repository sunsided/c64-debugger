#include "SYS_SharedMemory.h"
#include "SYS_Threading.h"
#include "CSlrString.h"
#include "SYS_Funct.h"
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>

#include <list>
#include <errno.h>
#include "libclipboard.h"

void *mtSharedMemoryDescriptor = NULL;
uint8 *mtSharedMemory = NULL;
u32 mtSharedMemorySize = 0;
u32 mtSharedMemoryKey = 0;

std::list<CSharedMemorySignalCallback *> mtSharedMemoryCallbacks;
CSlrMutex *mtSharedMemoryMutex;

void mtEngineSignalHandlerUSR(int signo);


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



//bool SYS_SharedMemoryExists(int memoryKeyId, int memorySize)
//{
//	int keyId = shmget(memoryKeyId, memorySize, NULL);
//
//	if (keyId == -1)
//		return false;
//
//	return true;
//}

pid_t proc_find_other_instance(const char* name)
{
    DIR* dir;
    struct dirent* ent;
    char* endptr;
    char buf[512];

    pid_t currentPid = getpid();

    if (!(dir = opendir("/proc"))) {
        perror("can't open /proc");
        return -1;
    }

    while((ent = readdir(dir)) != NULL) {
        /* if endptr is not a null character, the directory is not
         * entirely numeric, so ignore it */
        long lpid = strtol(ent->d_name, &endptr, 10);
        if (*endptr != '\0') {
            continue;
        }

        if (lpid == currentPid)
        {
        	LOGD("found myself, pid=%d", lpid);
        	continue;
        }

        /* try to open the cmdline file */
        snprintf(buf, sizeof(buf), "/proc/%ld/cmdline", lpid);
        FILE* fp = fopen(buf, "r");

        if (fp)
        {
            if (fgets(buf, sizeof(buf), fp) != NULL)
            {
                /* check the first token in the file, the program name */
                char *cmdlinePath = strtok(buf, " ");

            	char *fileName = SYS_GetFileNameFromFullPath(cmdlinePath);

            	if (fileName == NULL)
            		continue;

            	char *fileName2 = fileName;

                LOGD(" ... cmdlinePath='%s' fileName2='%s' name='%s' pid=%d", cmdlinePath, fileName2, name, lpid);


            	if (fileName[0] == '\\' || fileName[0] == '/')
            	{
            		fileName2++;
            	}

                if (!strcmp(fileName2, name))
                {
                	LOGD("found!!! lpid=%d", lpid);
                	free(fileName);
                	fclose(fp);
                    closedir(dir);
                    return (pid_t)lpid;

                }

                free(fileName);
            }
            fclose(fp);
        }

    }

    closedir(dir);
    return -1;
}

int SYS_SendConfigurationToOtherAppInstance(CByteBuffer *byteBuffer)
{
	extern char *__progname;
	LOGM("SYS_SendConfigurationToOtherAppInstance: progname=%s", __progname);

	// Find other instance pid, store data to shared memory and raise signal SIGUSR1

	pid_t pid = proc_find_other_instance(__progname);

	if (pid != -1)
	{
		LOGD("Found other instance of app, pid=%d", pid);

		// Store new configuration to shared memory
		//LOGD("Send byteBuffer to pid=%d", pid);
		//byteBuffer->DebugPrint();

		SYS_StoreToSharedMemory(byteBuffer->data, byteBuffer->length);

		// Send signal to instance to flag new data
		kill(pid, SIGUSR1);

		printf("Sent new configuration to instance pid=%d\n", pid);

		SYS_CleanExit();

		return pid;

	}

	LOGError("Other process instance not found");

	// other instance not found
	return -1;
}

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

	clipboard_c *cb = clipboard_new(NULL);
	if (cb == NULL)
	{
		LOGError("SYS_GetClipboardAsSlrString: clipboard initialisation failed");
		return NULL;
	}

	int len;

	char *text = clipboard_text_ex(cb, &len, LCB_SELECTION);
	if (text != NULL)
	{
		CSlrString *ret = new CSlrString(text);

		free(text);
		clipboard_free(cb);
		return ret;
	}

	text = clipboard_text_ex(cb, &len, LCB_CLIPBOARD);
	if (text != NULL)
	{
		CSlrString *ret = new CSlrString(text);

		free(text);
		clipboard_free(cb);
		return ret;
	}


	clipboard_free(cb);

	return NULL;
}


