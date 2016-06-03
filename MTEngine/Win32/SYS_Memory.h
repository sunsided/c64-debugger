#ifndef _SYS_MEMORY_H_
#define _SYS_MEMORY_H_

#include "SYS_Defs.h"

void SYS_DebugPrintMemory();
u64 SYS_GetUsedMemory();
u64 SYS_GetFreeMemory();
u64 SYS_GetTotalMemory();

#endif
// SYS_MEMORY
