#include "SYS_Memory.h"
//#include <windows.h>
#ifdef WIN32
#pragma comment(lib, "psapi.lib")
#include <psapi.h>
#endif

u64 SYS_GetTotalMemory()
{
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    GlobalMemoryStatusEx(&status);
    return status.ullTotalPhys;
}

void SYS_DebugPrintMemory()
{
}

u64 SYS_GetUsedMemory()
{
	//MEMORYSTATUSEX statex;
	//statex.dwLength = sizeof (statex);
	//GlobalMemoryStatusEx (&statex);

//	PROCESS_MEMORY_COUNTERS pMemCountr;
//
//	pMemCountr = new PROCESS_MEMORY_COUNTERS();
//	bool result = GetProcessMemoryInfo(GetCurrentProcess(),
//                                   pMemCountr,
  //                                 sizeof(PPROCESS_MEMORY_COUNTERS));
//
//	return result.WorkingSetSize;

	u32 memory = 0;
	PPROCESS_MEMORY_COUNTERS pMemCountr = new PROCESS_MEMORY_COUNTERS;
	if( GetProcessMemoryInfo(GetCurrentProcess(), pMemCountr, sizeof(PROCESS_MEMORY_COUNTERS)))
	{
		memory = pMemCountr->WorkingSetSize;
	}
	delete pMemCountr;
	return memory;
}

u64 SYS_GetFreeMemory()
{
	return 0;
}




//On Windows, there is GlobalMemoryStatusEx:
//
//}


