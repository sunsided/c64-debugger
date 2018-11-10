#include <windows.h>

#include "SYS_SharedMemory.h"
#include "SYS_Threading.h"
#include "SYS_CFileSystem.h"
#include "SYS_CommandLine.h"
#include "SYS_Funct.h"
#include "CSlrString.h"
#include "SYS_Startup.h"
#include <signal.h>
#include <sys/stat.h>
#include <psapi.h> 
#include <list>
#include <tchar.h>

#include <Shlwapi.h>
#pragma comment(lib, "Shlwapi.lib")

#define MAX_PROCESSES 4096

DWORD FindOtherProcessInstance(__in_z LPCTSTR lpcszFileName);
HWND FindWindowFromPid(DWORD pidToFind);

void *mtSharedMemoryDescriptor = NULL;
uint8 *mtSharedMemory = NULL;
u32 mtSharedMemorySize = 0;
u32 mtSharedMemoryKey = 0;

std::list<CSharedMemorySignalCallback *> mtSharedMemoryCallbacks;
CSlrMutex *mtSharedMemoryMutex;

void mtEngineHandleWM_USER();

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

void mtEngineHandleWM_USER()
{
	LOGD("mtEngineHandleWM_USER");
	
	//if (signo == SIGINT)
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
	
	LOGD("mtEngineHandleWM_USER done");
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
	LOGM("SYS_SendConfigurationToOtherAppInstance");

	// Find other instance pid, store data to shared memory and raise signal SIGUSR1

	TCHAR buffer[MAX_PATH]={0};
	TCHAR *out;
	DWORD bufSize=sizeof(buffer)/sizeof(*buffer);

	// Get the fully-qualified path of the executable
	if(GetModuleFileName(NULL, buffer, bufSize)==bufSize)
	{
		LOGError("SYS_SendConfigurationToOtherAppInstance: EXE file path too long");
		return -1;
	}

	// Go to the beginning of the file name
	out = PathFindFileName(buffer);

	// Set the dot before the extension to 0 (terminate the string there)
	//*(PathFindExtension(out)) = 0;

	DWORD bundlePid = FindOtherProcessInstance(out);

	if (bundlePid == 0)
	{
		LOGD("Other instance not found");
		return -1;
	}

	LOGD("Found other instance of app, pid=%d", bundlePid);

	// Store new configuration to shared memory
	LOGD("Send byteBuffer to pid=%d", bundlePid);
	byteBuffer->DebugPrint();
				
	SYS_StoreToSharedMemory(byteBuffer->data, byteBuffer->length);
				
	// Send signal to instance to flag new data
	HWND hWnd = FindWindowFromPid(bundlePid);

	if (hWnd == NULL)
	{
		LOGError("Other instance found pid=%d, but window not found", bundlePid);
		return -1;
	}

	LOGM("PostMessage WM_USER to hWnd=%x", hWnd);

	PostMessage(hWnd, WM_USER, 0, 0);

	//SYS_Sleep(15000);

	return bundlePid;
}

//bool SYS_SharedMemoryExists(int memoryKeyId, int memorySize)
//{
//	return true;
//}

uint8 *SYS_MapSharedMemory(int memorySize, int memoryKeyId, void **fileDescriptor)
{
	LOGD("SYS_MapSharedMemory: memoryKeyId=%d", memoryKeyId);

	TCHAR szName[]=TEXT("C64Debugger");

	HANDLE *hMapFile = (HANDLE*)malloc(sizeof(HANDLE));

	LPCTSTR pBuf;

	*hMapFile = CreateFileMapping(
                 INVALID_HANDLE_VALUE,    // use paging file
                 NULL,                    // default security
                 PAGE_READWRITE,          // read/write access
                 0,                       // maximum object size (high-order DWORD)
                 memorySize,                // maximum object size (low-order DWORD)
                 szName);                 // name of mapping object

   if (*hMapFile == NULL)
   {
      LOGError("Could not create file mapping object (%d)", GetLastError());
      return NULL;
   }
   pBuf = (LPTSTR) MapViewOfFile(*hMapFile,   // handle to map object
                        FILE_MAP_ALL_ACCESS, // read/write permission
                        0,
                        0,
                        memorySize);

   if (pBuf == NULL)
   {
		LOGError("Could not map view of file (%d)", GetLastError());
		CloseHandle(*hMapFile);
		return NULL;
   }

   LOGD("SYS_MapSharedMemory: mapped memory to %x", pBuf);

	*fileDescriptor = hMapFile;

   return (uint8*)pBuf;
}

void SYS_UnMapSharedMemory(void **fileDescriptor, uint8 *memory)
{
	LOGD("SYS_UnMapSharedMemory: memory=%x", memory);
		
	if (memory == NULL)
	{
		LOGError("SYS_UnMapSharedMemory: memory is NULL");
		return;
	}

	LPCTSTR pBuf = (LPCTSTR)memory;
	HANDLE *hMapFile = (HANDLE*)*fileDescriptor;
 
	UnmapViewOfFile(memory);
	CloseHandle(hMapFile);

	return;
}

void CSharedMemorySignalCallback::SharedMemorySignalCallback(CByteBuffer *sharedMemoryData)
{
	
}



DWORD FindOtherProcessInstance(__in_z LPCTSTR lpcszFileName) 
{ 
  LPDWORD lpdwProcessIds; 
  LPTSTR  lpszBaseName; 
  HANDLE  hProcess; 
  DWORD   i, cdwProcesses, dwProcessId = 0; 

  DWORD   currentProcessId = GetCurrentProcessId();

  lpdwProcessIds = (LPDWORD)HeapAlloc(GetProcessHeap(), 0, MAX_PROCESSES*sizeof(DWORD)); 
  if (lpdwProcessIds != NULL) 
  { 
    if (EnumProcesses(lpdwProcessIds, MAX_PROCESSES*sizeof(DWORD), &cdwProcesses)) 
    { 
      lpszBaseName = (LPTSTR)HeapAlloc(GetProcessHeap(), 0, MAX_PATH*sizeof(TCHAR)); 
      if (lpszBaseName != NULL) 
      { 
        cdwProcesses /= sizeof(DWORD); 
        for (i = 0; i < cdwProcesses; i++) 
        { 
			if (currentProcessId == lpdwProcessIds[i])
				continue;

          hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, lpdwProcessIds[i]); 
          if (hProcess != NULL) 
          { 
            if (GetModuleBaseName(hProcess, NULL, lpszBaseName, MAX_PATH) > 0) 
            { 
				LOGD("lpszBaseName='%s'", lpszBaseName);
              if (!lstrcmpi(lpszBaseName, lpcszFileName)) 
              { 
                dwProcessId = lpdwProcessIds[i]; 
                CloseHandle(hProcess); 
                break; 
              } 
            } 
            CloseHandle(hProcess); 
          } 
        } 
        HeapFree(GetProcessHeap(), 0, (LPVOID)lpszBaseName); 
      } 
    } 
    HeapFree(GetProcessHeap(), 0, (LPVOID)lpdwProcessIds); 
  } 
  return dwProcessId; 
}

HWND FindWindowFromPid(DWORD pidToFind)
{
	LOGD("FindWindowFromPid");
	HWND hCurWnd = GetTopWindow(0);
	while (hCurWnd != NULL)
	{
		DWORD cur_pid;
		DWORD dwTheardId = GetWindowThreadProcessId(hCurWnd, &cur_pid);
				
		if (cur_pid == pidToFind)
		{
			if (IsWindowVisible(hCurWnd) != 0)
			{
				TCHAR szClassName[256];
				GetClassName(hCurWnd, szClassName, 256);

				LOGD("...hCurWnd=%x szClassName='%s' HWND_CLASS_NAME='%s'", hCurWnd, szClassName, HWND_CLASS_NAME);

				if (_tcscmp(szClassName,HWND_CLASS_NAME)==0)
					return hCurWnd;
			}
		}
		hCurWnd = GetNextWindow(hCurWnd, GW_HWNDNEXT);
	}
	return NULL;
}

//

CSlrString *SYS_GetClipboardAsSlrString()
{
	// Try opening the clipboard
	if (! OpenClipboard(NULL))
	{
		LOGError("SYS_GetClipboardAsSlrString: Error while OpenClipboard");
		return NULL;
	}

	// Get handle of clipboard object for ANSI text
	HANDLE hData = GetClipboardData(CF_TEXT);
	if (hData == NULL)
	{
	  return NULL;
	}

	// Lock the handle to get the actual text pointer
	char * pszText = static_cast<char*>( GlobalLock(hData) );
	if (pszText == NULL)
	{
		GlobalUnlock( hData );
		return NULL;
	}

	// Save text in a string class instance
	CSlrString *str = new CSlrString(pszText);

	LOGD("SYS_GetClipboardAsSlrString: Clipboard text='%s'", pszText);
	str->DebugPrint("str=");

	// Release the lock
	GlobalUnlock( hData );

	// Release the clipboard
	CloseClipboard();

	return str;
}

bool SYS_SetClipboardAsSlrString(CSlrString *str)
{
	// Try opening the clipboard
	if (! OpenClipboard(NULL))
	{
		LOGError("SYS_SetClipboardAsSlrString: Error while OpenClipboard");
		return false;
	}
	
	char *output = str->GetStdASCII();
	const size_t len = strlen(output) + 1;

	HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, len);
	memcpy(GlobalLock(hMem), output, len);
	
	GlobalUnlock(hMem);
	
	EmptyClipboard();
	SetClipboardData(CF_TEXT, hMem);

	delete [] output;

	// Release the clipboard
	CloseClipboard();
	
	return true;
}
