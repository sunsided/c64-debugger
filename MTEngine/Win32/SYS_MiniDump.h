#ifndef _SYS_MINIDUMP_H_
#define _SYS_MINIDUMP_H_

#include <windows.h>
#include <tchar.h>
#include <dbghelp.h>
#include <stdio.h>
#include <crtdbg.h>

void SYS_CreateMiniDump( EXCEPTION_POINTERS* pep ); 

#endif
