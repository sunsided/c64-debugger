#include "SYS_MiniDump.h"
#include "DBG_Log.h"

//http://www.debuginfo.com/examples/effmdmpexamples.html

#define DUMP_FILE_NAME "MTEngineCrash.dmp"

#pragma comment ( lib, "dbghelp.lib" )

#if _WIN32 || _WIN64
#if _WIN64
	NOT SUPPORTED #define ENVIRONMENT64
#else
#define ENVIRONMENT32
#endif
#endif

void SYS_CreateMaxiDump( EXCEPTION_POINTERS* pep ) 
{
	// Open the file 

	HANDLE hFile = CreateFile( _T(DUMP_FILE_NAME), GENERIC_READ | GENERIC_WRITE, 
		0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL ); 

	if( ( hFile != NULL ) && ( hFile != INVALID_HANDLE_VALUE ) ) 
	{
		// Create the minidump 

		MINIDUMP_EXCEPTION_INFORMATION mdei; 

		mdei.ThreadId           = GetCurrentThreadId(); 
		mdei.ExceptionPointers  = pep; 
		mdei.ClientPointers     = FALSE; 

		MINIDUMP_TYPE mdt       = (MINIDUMP_TYPE)(MiniDumpWithFullMemory | 
		                                          MiniDumpWithFullMemoryInfo | 
		                                          MiniDumpWithHandleData | 
		                                          MiniDumpWithThreadInfo | 
		                                          MiniDumpWithUnloadedModules ); 

		BOOL rv = MiniDumpWriteDump( GetCurrentProcess(), GetCurrentProcessId(), 
			hFile, mdt, (pep != 0) ? &mdei : 0, 0, 0 ); 

		if( !rv )
		{
			MessageBox(NULL, "MTEngine crashed. Creating MTEngineCrash.dmp failed", 
				"MTEngine crashed", 
				MB_OK|MB_ICONEXCLAMATION);
			LOGError("SYS_CreateMiniDump: creating dump failed");
			//_tprintf( _T("MiniDumpWriteDump failed. Error: %u \n"), GetLastError() ); 
		}
		else 
		{
			MessageBox(NULL, "MTEngine crashed. Send MTEngineCrash.dmp to Marcin.Skoczylas@me.com", 
				"MTEngine crashed", 
				MB_OK|MB_ICONEXCLAMATION);
			LOGError("SYS_CreateMiniDump: dump created");
			//_tprintf( _T("Minidump created.\n") ); 
		}

		// Close the file 

		CloseHandle( hFile ); 

	}
	else 
	{
		MessageBox(NULL, "MTEngine crashed", "MTEngine crashed. Creating MTEngineCrash.dmp failed", 
			MB_OK|MB_ICONEXCLAMATION);
		//_tprintf( _T("CreateFile failed. Error: %u \n"), GetLastError() ); 
	}
	LOGError("SYS_CreateMiniDump: finished");
}


BOOL CALLBACK MyMiniDumpCallback(
	PVOID                            pParam, 
	const PMINIDUMP_CALLBACK_INPUT   pInput, 
	PMINIDUMP_CALLBACK_OUTPUT        pOutput 
); 

void SYS_CreateMiniDump( EXCEPTION_POINTERS* pep ) 
{
	// Open the file 

	HANDLE hFile = CreateFile( _T(DUMP_FILE_NAME), GENERIC_READ | GENERIC_WRITE, 
		0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL ); 

	if( ( hFile != NULL ) && ( hFile != INVALID_HANDLE_VALUE ) ) 
	{
		// Create the minidump 

		MINIDUMP_EXCEPTION_INFORMATION mdei; 

		mdei.ThreadId           = GetCurrentThreadId(); 
		mdei.ExceptionPointers  = pep; 
		mdei.ClientPointers     = FALSE; 

		MINIDUMP_CALLBACK_INFORMATION mci; 

		mci.CallbackRoutine     = (MINIDUMP_CALLBACK_ROUTINE)MyMiniDumpCallback; 
		mci.CallbackParam       = 0; 

		MINIDUMP_TYPE mdt       = (MINIDUMP_TYPE)(MiniDumpWithIndirectlyReferencedMemory | MiniDumpScanMemory); 

		BOOL rv = MiniDumpWriteDump( GetCurrentProcess(), GetCurrentProcessId(), 
			hFile, mdt, (pep != 0) ? &mdei : 0, 0, &mci ); 

		if( !rv )
		{
			MessageBox(NULL, "MTEngine crashed. Creating MTEngineCrash.dmp failed", 
				"MTEngine crashed", 
				MB_OK|MB_ICONEXCLAMATION);
			LOGError("SYS_CreateMiniDump: creating dump failed");
			//_tprintf( _T("MiniDumpWriteDump failed. Error: %u \n"), GetLastError() ); 
		}
		else 
		{
			MessageBox(NULL, "MTEngine crashed. Send MTEngineCrash.dmp to Marcin.Skoczylas@me.com", 
				"MTEngine crashed", 
				MB_OK|MB_ICONEXCLAMATION);
			LOGError("SYS_CreateMiniDump: dump created");
			//_tprintf( _T("Minidump created.\n") ); 
		}

		// Close the file 

		CloseHandle( hFile ); 

	}
	else 
	{
		MessageBox(NULL, "MTEngine crashed", "MTEngine crashed. Creating MTEngineCrash.dmp failed", 
			MB_OK|MB_ICONEXCLAMATION);
		//_tprintf( _T("CreateFile failed. Error: %u \n"), GetLastError() ); 
	}
	LOGError("SYS_CreateMiniDump: finished");
}


///////////////////////////////////////////////////////////////////////////////
// Custom minidump callback 
//

BOOL CALLBACK MyMiniDumpCallback(
	PVOID                            pParam, 
	const PMINIDUMP_CALLBACK_INPUT   pInput, 
	PMINIDUMP_CALLBACK_OUTPUT        pOutput 
) 
{
	BOOL bRet = FALSE; 


	// Check parameters 

	if( pInput == 0 ) 
		return FALSE; 

	if( pOutput == 0 ) 
		return FALSE; 


	// Process the callbacks 

	switch( pInput->CallbackType ) 
	{
		case IncludeModuleCallback: 
		{
			// Include the module into the dump 
			bRet = TRUE; 
		}
		break; 

		case IncludeThreadCallback: 
		{
			// Include the thread into the dump 
			bRet = TRUE; 
		}
		break; 

		case ModuleCallback: 
		{
			// Does the module have ModuleReferencedByMemory flag set ? 

			if( !(pOutput->ModuleWriteFlags & ModuleReferencedByMemory) ) 
			{
				// No, it does not - exclude it 

				wprintf( L"Excluding module: %s \n", pInput->Module.FullPath ); 

				pOutput->ModuleWriteFlags &= (~ModuleWriteModule); 
			}

			bRet = TRUE; 
		}
		break; 

		case ThreadCallback: 
		{
			// Include all thread information into the minidump 
			bRet = TRUE;  
		}
		break; 

		case ThreadExCallback: 
		{
			// Include this information 
			bRet = TRUE;  
		}
		break; 

		case MemoryCallback: 
		{
			// We do not include any information here -> return FALSE 
			bRet = FALSE; 
		}
		break; 

		case CancelCallback: 
			break; 
	}

	return bRet; 

}

