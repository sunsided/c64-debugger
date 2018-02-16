/*
 *  DBG_Logf.cpp
 *  MobiTracker
 *
 * [C] Marcin Skoczylas
 * debug console/file code 
 *
 */

// date time in win32
// http://stackoverflow.com/questions/1695288/getting-the-current-time-in-milliseconds-from-the-system-clock-in-windows

#include "DBG_ConStream.h"
#include "DBG_Log.h"
#include "SYS_Defs.h"
#include "CLogByteBuffer.h"
#include <pthread.h>

#if !defined(GLOBAL_DEBUG_OFF)

#define USE_COUT

#define LOG_CONSOLE
#define WIN_CONSOLE
#define LOG_FILE

//#define DEBUG_OFF
//#define FULL_LOG

/*
 TODO:
 + (NSString *) myFormattedString:(NSString *)format, ... {
 va_list args;
 va_start(args, format);
 
 NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
 [str autorelease];
 
 va_end(args);
 
 return [NSString stringWithFormat:@"Foo: %@.", str];
 }
 */


static int currentLogLevel;
pthread_mutex_t loggerMutex;

#ifdef LOG_FILE
FILE *fpLog = NULL;
#endif

#ifdef WIN_CONSOLE
ConStream m_Log;
#endif

#ifndef DEBUG_OFF
#ifdef FULL_LOG

bool logThisLevel(int level)
{
	return true;
}

#else

bool logThisLevel(int level)
{
//		return true;
	if (level == DBGLVL_MAIN) return true; 
	if (level == DBGLVL_DEBUG) return true;
	if (level == DBGLVL_RES) return false;
	if (level == DBGLVL_GUI) return false; //	true	false
	if (level == DBGLVL_HTTP) return false;
	if (level == DBGLVL_XMPLAYER) return false;
	if (level == DBGLVL_AUDIO) return false;
	if (level == DBGLVL_XML) return true;
	if (level == DBGLVL_SQL) return true;
	if (level == DBGLVL_ERROR) return true;	// always
	if (level == DBGLVL_TODO) return true;
	if (level == DBGLVL_ANIMATION) return false;
	if (level == DBGLVL_NET) return true;
	if (level == DBGLVL_NET_SERVER) return true;
	if (level == DBGLVL_NET_CLIENT) return true;
	if (level == DBGLVL_INPUT) return false;
	if (level == DBGLVL_VICE_DEBUG) return true;
	if (level == DBGLVL_VICE_MAIN) return true;
	if (level == DBGLVL_VICE_VERBOSE) return true;

	if (level == currentLogLevel)
		return true;
	
	return false;
}

#endif // FULL_LOG

#else

bool logThisLevel(int level)
{
//	if (level == DBGLVL_DEBUG) return true;
	return false;
}
#endif


const char *getLevelStr(int level)
{
	if (level == DBGLVL_MAIN)
		return "[MAIN] ";
	if (level == DBGLVL_DEBUG)
		return "[DEBUG]";
	if (level == DBGLVL_INPUT)
		return "[INPUT]";
	if (level == DBGLVL_RES)
		return "[RES]  ";
	if (level == DBGLVL_GUI)
		return "[GUI]  ";
	if (level == DBGLVL_XMPLAYER)
		return "[XM]   ";
	if (level == DBGLVL_AUDIO)
		return "[AUDIO]";
	if (level == DBGLVL_HTTP)
		return "[HTTP] ";
	if (level == DBGLVL_ANIMATION)
		return "[ANIM] ";
	if (level == DBGLVL_MEMORY)
		return "[MEM ] ";
	if (level == DBGLVL_ERROR)
		return "[ERROR]";
	if (level == DBGLVL_TODO)
		return "[TODO] ";
	if (level == DBGLVL_NET)
		return "[NET ] ";
	if (level == DBGLVL_NET_SERVER)
		return "[SERV>]";
	if (level == DBGLVL_NET_CLIENT)
		return "[<CLNT]";
	if (level == DBGLVL_VICE_DEBUG)
		return "[VICE ]";
	if (level == DBGLVL_VICE_MAIN)
		return "[VICEM]";
	if (level == DBGLVL_VICE_VERBOSE)
		return "[VICEV]";

	return "[UNKNOWN]";
}

// FORMATOWANIE w NSLog jest SPIERDOLONE chociaz sie kompiluje!!
// NSLog(@"%@", s);
// NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

//#define USE_COUT
CLogByteBuffer *logEventsBuffer;

void DBG_SendLog(int debugLevel, char *message);

char logBuf[512];
HANDLE pipeHandle;

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

#ifdef LOG_FILE
	SYSTEMTIME tmeCurrent;
	GetLocalTime(&tmeCurrent);

	DWORD processId = GetCurrentProcessId();

	sprintf(logBuf, "./log/MTEngine-%04d%02d%02d-%02d%02d%02d-%d.txt", tmeCurrent.wYear, tmeCurrent.wMonth, tmeCurrent.wDay,
		tmeCurrent.wHour, tmeCurrent.wMinute, tmeCurrent.wSecond, processId);

	fpLog = fopen(logBuf, "wb");

	if (fpLog == NULL)
	{
		sprintf(logBuf, "MTEngine-%04d%02d%02d-%02d%02d%02d-%d.txt", tmeCurrent.wYear, tmeCurrent.wMonth, tmeCurrent.wDay,
			tmeCurrent.wHour, tmeCurrent.wMinute, tmeCurrent.wSecond, processId);

		fpLog = fopen(logBuf, "wb");
	}
#endif

#ifdef WIN_CONSOLE
	//m_Log.Open();
#endif

#ifdef LOG_CONSOLE
//	DWORD processId = GetCurrentProcessId();

#ifdef WIN_CONSOLE
	m_Log << "processId=" << processId << std::endl;
	m_Log << "start LogConsole.exe";
#endif

	STARTUPINFO         siStartupInfo;
	PROCESS_INFORMATION piProcessInfo;

    memset(&siStartupInfo, 0, sizeof(siStartupInfo));
    memset(&piProcessInfo, 0, sizeof(piProcessInfo));

    siStartupInfo.cb = sizeof(siStartupInfo);

	//hostProcID.ToString()
      //          + " \"" + LogEngine.Settings.settingsName + "\" \"" + windowCaption + "\"";

//	sprintf(logBuf, " %d \"MTEngine\" \"MTEngine log console (" __DATE__ " " __TIME__ ")\"");
	sprintf(logBuf, " %d \"MTEngine\" \"MTEngine log console\"");

    if(CreateProcess("LogConsole.exe",     // Application name
                     logBuf,                 // Application arguments
                     0,
                     0,
                     FALSE,
                     CREATE_DEFAULT_ERROR_MODE,
                     0,
                     0,                              // Working directory
                     &siStartupInfo,
                     &piProcessInfo) == FALSE)
	{
		DWORD err = GetLastError();
		//m_Log << "error=" << err << std::endl;
	}
	else
	{
		//m_Log << "ok, connect to pipe" << std::endl;
		// connect to pipe
		sprintf(logBuf, "\\\\.\\pipe\\logconsole%d");
	
		while(true)
		{
			pipeHandle = CreateFile(logBuf,
						GENERIC_READ | GENERIC_WRITE,
						0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

			if (pipeHandle != INVALID_HANDLE_VALUE)
				break;

			Sleep(15);
		}
		//m_Log << "pipe connected" << std::endl;
	}

	logEventsBuffer = new CLogByteBuffer(8192);

#endif

	//currentLogLevel = DBGLVL_HTTP;
}

void LOG_Shutdown(void)
{
	LOGF(DBGLVL_MAIN, "closing stdlib & logfile\nbye!\n");
	
#ifdef LOG_FILE
	fclose(fpLog);
#endif

}

void LockLoggerMutex()
{
#ifdef WIN_CONSOLE
	//m_Log << "LOCK" << endl;
#endif
	pthread_mutex_lock(&loggerMutex);
}

void UnlockLoggerMutex()
{
#ifdef WIN_CONSOLE
	//m_Log << "UNLOCK" << endl;
#endif
	pthread_mutex_unlock(&loggerMutex);
}

int a = 3;
void DBG_SendLog(int debugLevel, char *message)
{
	if (message == NULL)
	{
		a = 4;
		return;
	}

	SYSTEMTIME tmeCurrent;
	GetLocalTime(&tmeCurrent);

	DWORD threadId = GetCurrentThreadId();

#ifdef WIN_CONSOLE
	//m_Log << message << std::endl;
	//fflush(stdout);
#endif

#ifdef LOG_CONSOLE
	logEventsBuffer->Clear();
	logEventsBuffer->putInt(debugLevel);
	logEventsBuffer->putInt(tmeCurrent.wYear);
	logEventsBuffer->putByte(tmeCurrent.wMonth);
	logEventsBuffer->putByte(tmeCurrent.wDay);
	logEventsBuffer->putByte(tmeCurrent.wHour);
	logEventsBuffer->putByte(tmeCurrent.wMinute);
	logEventsBuffer->putByte(tmeCurrent.wSecond);
	logEventsBuffer->putInt(tmeCurrent.wMilliseconds);
	logEventsBuffer->putString("");	//method
	sprintf(logBuf, "%8.8X", threadId);
	logEventsBuffer->putString(logBuf);	// thread
	logEventsBuffer->putString(message);

	byte sizeBuf[2];
	sizeBuf[0] = (byte)((logEventsBuffer->index) >> 8);
	sizeBuf[1] = (byte)(logEventsBuffer->index);

	DWORD b;
	WriteFile(pipeHandle, sizeBuf, 2, &b, NULL);
	WriteFile(pipeHandle, logEventsBuffer->data, logEventsBuffer->index, &b, NULL);
	FlushFileBuffers(pipeHandle);
#endif

#ifdef LOG_FILE
	//03:22:07,127 000010B4 [DEBUG] CGuiList::CGuiList done
	fprintf(fpLog, "%02d:%02d:%02d,%03d %8.8X %s %s\n", 
		tmeCurrent.wHour, tmeCurrent.wMinute, tmeCurrent.wSecond, tmeCurrent.wMilliseconds,
		threadId, getLevelStr(debugLevel), message);
	fflush(fpLog);
#endif

}

void DBG_PrintBytes(void *data, unsigned int numBytes)
{
	LockLoggerMutex();
	
	static char buf[2];
//	unsigned char *array = data;
	for (unsigned int i = 0; i < numBytes; i++)
	{
		unsigned char c = ((unsigned char *)data)[i];
		printf("%2.2x ", c);
	}
	fflush(stdout);
	UnlockLoggerMutex();
}

void LOGT(int level, char *what)
{
	if (!logThisLevel(level))
		return;
	LOGF(level, what);
}

void LOGT(int level, const char *what)
{
	if (!logThisLevel(level))
		return;

	LOGF(level, what);
}

void LOGF(int level, char *fmt, ... )
{
    char buffer[4096] = {0};

    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(level, buffer);

	UnlockLoggerMutex();
	
}

void LOGF(int level, std::string what)
{
	if (!logThisLevel(level))
		return;
	LOGF(level, what.c_str());
}

void LOGF(int level, const char *fmt, ... )
{
	if (!logThisLevel(level))
		return;
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(level, buffer);

	UnlockLoggerMutex();
}

////////LOGG

void LOGG(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_GUI))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_GUI, buffer);

	UnlockLoggerMutex();
}

void LOGG(std::string what)
{
	if (!logThisLevel(DBGLVL_GUI))
		return;
	
	LOGF(DBGLVL_GUI, what.c_str());
}

void LOGG(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_GUI))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_GUI, buffer);

	UnlockLoggerMutex();
}
///////////// LOGG

////////LOGD

void LOGD(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_DEBUG, buffer);

	UnlockLoggerMutex();
	
}

void LOGD(std::string what)
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;
	
	LOGF(DBGLVL_DEBUG, what.c_str());
}

void LOGD(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_DEBUG, buffer);

	UnlockLoggerMutex();
}
///////////// LOGD

////////LOGD

void LOGVD(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_VICE_DEBUG))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_VICE_DEBUG, buffer);

	UnlockLoggerMutex();
	
}

void LOGVD(std::string what)
{
	if (!logThisLevel(DBGLVL_VICE_DEBUG))
		return;
	
	LOGF(DBGLVL_VICE_DEBUG, what.c_str());
}

void LOGVD(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_VICE_DEBUG))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_VICE_DEBUG, buffer);

	UnlockLoggerMutex();
}
///////////// LOGVD





void LOGMEM(std::string what)
{
	if (!logThisLevel(DBGLVL_MEMORY))
		return;
	
	LOGF(DBGLVL_MEMORY, what.c_str());
}

void LOGMEM(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_MEMORY))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_MEMORY, buffer);

	UnlockLoggerMutex();
}
///////////// LOGMEM

////////LOGS

void LOGS(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_SCRIPT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_SCRIPT, buffer);

	UnlockLoggerMutex();
	
}

void LOGS(std::string what)
{
	if (!logThisLevel(DBGLVL_SCRIPT))
		return;
	
	LOGF(DBGLVL_SCRIPT, what.c_str());
}

void LOGS(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_SCRIPT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_SCRIPT, buffer);

	UnlockLoggerMutex();
}
///////////// LOGS

////////LOGC

void LOGC(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET, buffer);

	UnlockLoggerMutex();
	
}

void LOGC(std::string what)
{
	if (!logThisLevel(DBGLVL_NET))
		return;
	
	LOGF(DBGLVL_NET, what.c_str());
}

void LOGC(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET, buffer);

	UnlockLoggerMutex();
}
///////////// LOGC

////////LOGCC
void LOGCC(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET_CLIENT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET_CLIENT, buffer);

	UnlockLoggerMutex();
	
}

void LOGCC(std::string what)
{
	if (!logThisLevel(DBGLVL_NET_CLIENT))
		return;
	
	LOGF(DBGLVL_NET_CLIENT, what.c_str());
}

void LOGCC(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET_CLIENT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET_CLIENT, buffer);

	UnlockLoggerMutex();
}
///////////// LOGCC

////////LOGCS
void LOGCS(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET_SERVER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET_SERVER, buffer);

	UnlockLoggerMutex();
	
}

void LOGCS(std::string what)
{
	if (!logThisLevel(DBGLVL_NET_SERVER))
		return;
	
	LOGF(DBGLVL_NET_SERVER, what.c_str());
}

void LOGCS(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_NET_SERVER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_NET_SERVER, buffer);

	UnlockLoggerMutex();
}
///////////// LOGCS


////////LOGM
void LOGM(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_MAIN))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_MAIN, buffer);

	UnlockLoggerMutex();
	
}

void LOGM(std::string what)
{
	if (!logThisLevel(DBGLVL_MAIN))
		return;
	
	LOGF(DBGLVL_MAIN, what.c_str());
}

void LOGM(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_MAIN))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_MAIN, buffer);

	UnlockLoggerMutex();
}
///////////// LOGM

////////LOGM

void LOGN(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_ANIMATION))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ANIMATION, buffer);

	UnlockLoggerMutex();
	
}

void LOGN(std::string what)
{
	if (!logThisLevel(DBGLVL_ANIMATION))
		return;
	
	LOGF(DBGLVL_ANIMATION, what.c_str());
}

void LOGN(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_ANIMATION))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ANIMATION, buffer);

	UnlockLoggerMutex();
}
///////////// LOGN

////////LOGA

void LOGA(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_AUDIO))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_AUDIO, buffer);

	UnlockLoggerMutex();
}

void LOGA(std::string what)
{
	if (!logThisLevel(DBGLVL_AUDIO))
		return;
	
	LOGF(DBGLVL_AUDIO, what.c_str());
}

void LOGA(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_AUDIO))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_AUDIO, buffer);

	UnlockLoggerMutex();
}
///////////// LOGA

////////LOGI

void LOGI(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_INPUT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_INPUT, buffer);

	UnlockLoggerMutex();
}

void LOGI(std::string what)
{
	if (!logThisLevel(DBGLVL_INPUT))
		return;
	
	LOGF(DBGLVL_INPUT, what.c_str());
}

void LOGI(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_INPUT))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_INPUT, buffer);

	UnlockLoggerMutex();
}
///////////// LOGI

////////LOGX

void LOGX(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_XMPLAYER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_XMPLAYER, buffer);

	UnlockLoggerMutex();
}

void LOGX(std::string what)
{
	if (!logThisLevel(DBGLVL_XMPLAYER))
		return;
	
	LOGF(DBGLVL_XMPLAYER, what.c_str());
}

void LOGX(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_XMPLAYER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_XMPLAYER, buffer);

	UnlockLoggerMutex();
}
///////////// LOGX

////////LOGL

void LOGL(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_LEVEL))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_LEVEL, buffer);

	UnlockLoggerMutex();
}

void LOGL(std::string what)
{
	if (!logThisLevel(DBGLVL_LEVEL))
		return;
	
	LOGF(DBGLVL_LEVEL, what.c_str());
}

void LOGL(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_LEVEL))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_LEVEL, buffer);

	UnlockLoggerMutex();
}
///////////// LOGL

////////LOGR

void LOGR(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_RES))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_RES, buffer);

	UnlockLoggerMutex();
}

void LOGR(std::string what)
{
	if (!logThisLevel(DBGLVL_RES))
		return;
	
	LOGF(DBGLVL_RES, what.c_str());
}

void LOGR(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_RES))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_RES, buffer);

	UnlockLoggerMutex();
}
///////////// LOGR

////////LOGTODO

void LOGTODO(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_TODO))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();
	DBG_SendLog(DBGLVL_TODO, buffer);
	UnlockLoggerMutex();
	
}

void LOGTODO(std::string what)
{
	if (!logThisLevel(DBGLVL_TODO))
		return;
	
	LOGF(DBGLVL_TODO, what.c_str());
}

void LOGTODO(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_TODO))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();
	DBG_SendLog(DBGLVL_TODO, buffer);
	UnlockLoggerMutex();
}
///////////// LOGTODO
void LOGError(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_ERROR))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ERROR, buffer);

	UnlockLoggerMutex();

}

void LOGError(std::string what)
{
	if (!logThisLevel(DBGLVL_ERROR))
		return;
	
	LOGF(DBGLVL_GUI, what.c_str());
}

void LOGError(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_ERROR))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ERROR, buffer);

	UnlockLoggerMutex();
}
/////////////


///////////////

void SYS_Errorf(char *fmt, ... )
{
	//m_Log << "ERROR:" << std::endl;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ERROR, buffer);

	UnlockLoggerMutex();
}

void SYS_Errorf(const char *fmt, ... )
{
	//m_Log << "ERROR:" << std::endl;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

	DBG_SendLog(DBGLVL_ERROR, buffer);

	UnlockLoggerMutex();
}

/*
 void Byte2Hex2digits(byte value, char *bufOut)
 {
 unsigned char c1;
 unsigned char c2;
 
 c1 = (unsigned char)(value & 0xF0);
 c1 = (unsigned char)(value >> 4);
 
 c2 = (unsigned char)(value & 0x0F);
 
 bufOut[0] = (unsigned char)hexTable[c1];
 bufOut[1] = (unsigned char)hexTable[c2];
 
 }
 
*/

#else

void LOG_Init(void) {}
void LOG_SetLevel(unsigned int level, bool isOn) {}
void LOG_Shutdown(void) {}

#endif
