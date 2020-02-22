/*
 **************************************************************************
 *
 *    Copyright 2008 Marcin Skoczylas    
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 **************************************************************************
 * 
 * @author: Marcin.Skoczylas@pb.edu.pl
 *  
 */

 /*
 *  DBG_Logf.cpp
 *  FastLogConsole
 *
 * [C] Marcin Skoczylas
 * debug console/file code 
 *
 */

// the code below is completely in "ALPHA" version, but somehow works 
// with C# FastLogConsole. don't take it seriously.
 
#include "DBG_ConStream.h"
#include "DBG_Log.h"
#include "./../CByteBuffer.h"
#include <pthread.h>

#define USE_COUT

#define LOG_CONSOLE
#define WIN_CONSOLE
#define LOG_FILE
//#define DEBUG_OFF
//#define FULL_LOG

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
	if (level == DBGLVL_MAIN) return true; 
	if (level == DBGLVL_DEBUG) return true;
	if (level == DBGLVL_RES) return true;
	if (level == DBGLVL_GUI) return true; //	true	false
	if (level == DBGLVL_HTTP) return true;
	if (level == DBGLVL_DATABASE) return true;
	if (level == DBGLVL_PLAYER) return true;
	if (level == DBGLVL_AUDIO) return true;
	if (level == DBGLVL_ERROR) return true;	// always
	if (level == DBGLVL_WARN) return true;	// always
	if (level == DBGLVL_TODO) return true;
	if (level == DBGLVL_MEMORY) return true;

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
	if (level == DBGLVL_RES)
		return "[RES]  ";
	if (level == DBGLVL_GUI)
		return "[GUI]  ";
	if (level == DBGLVL_HTTP)
		return "[HTTP] ";
	if (level == DBGLVL_DATABASE)		// cyan
		return "[DB]   ";
	if (level == DBGLVL_PLAYER)
		return "[PLAY] ";
	if (level == DBGLVL_AUDIO)
		return "[AUDIO]";
	if (level == DBGLVL_ERROR)
		return "[ERROR]";
	if (level == DBGLVL_TODO)
		return "[TODO] ";
	if (level == DBGLVL_MEMORY)
		return "[MEM]  ";
	
	return "[UNKNOWN]";
}

//#define USE_COUT
CByteBuffer *logEventsBuffer;

void DBG_SendLog(int debugLevel, char *message);

char logBuf[512];
HANDLE pipeHandle;

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

#ifdef LOG_FILE
	SYSTEMTIME tmeCurrent;
	GetLocalTime(&tmeCurrent);

	sprintf(logBuf, "./log/MTEngine-%04d%02d%02d-%02d%02d.txt", tmeCurrent.wYear, tmeCurrent.wMonth, tmeCurrent.wDay,
												tmeCurrent.wHour, tmeCurrent.wMinute);

	fpLog = fopen(logBuf, "wb");
#endif

#ifdef WIN_CONSOLE
	//m_Log.Open();
#endif

#ifdef LOG_CONSOLE
	DWORD processId = GetCurrentProcessId();

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

	sprintf(logBuf, " %d \"FastLogConsole\" \"FastLogConsole log console\"");

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
	}

	logEventsBuffer = new CByteBuffer(8192);

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
	pthread_mutex_lock(&loggerMutex);
}

void UnlockLoggerMutex()
{
	pthread_mutex_unlock(&loggerMutex);
}

void DBG_SendLog(int debugLevel, char *message)
{
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
	sprintf(logBuf, "%4.4X", threadId);
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

#ifdef LOG_CONSOLE
	DBG_SendLog(level, buffer);
#endif

#ifdef WIN_CONSOLE
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(level, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_GUI, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_GUI, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_DEBUG, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_DEBUG, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
///////////// LOGD


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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_MAIN, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_MAIN, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
///////////// LOGM

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_AUDIO, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_AUDIO, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
///////////// LOGA

////////LOGX

void LOGX(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_PLAYER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_PLAYER, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}

void LOGX(std::string what)
{
	if (!logThisLevel(DBGLVL_PLAYER))
		return;
	
	LOGF(DBGLVL_PLAYER, what.c_str());
}

void LOGX(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_PLAYER))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_PLAYER, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
///////////// LOGX


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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_RES, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_RES, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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
	#ifdef LOG_CONSOLE
		DBG_SendLog(DBGLVL_TODO, buffer);
	#else
		m_Log << buffer << std::endl;
		fflush(stdout);
	#endif
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
	#ifdef LOG_CONSOLE
		DBG_SendLog(DBGLVL_TODO, buffer);
	#else
		m_Log << buffer << std::endl;
		fflush(stdout);
	#endif
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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_ERROR, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();

}

void LOGError(std::string what)
{
	if (!logThisLevel(DBGLVL_ERROR))
		return;
	
	LOGF(DBGLVL_ERROR, what.c_str());
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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_ERROR, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
/////////////

void LOGWarning(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_WARN))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_WARN, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();

}

void LOGWarning(std::string what)
{
	if (!logThisLevel(DBGLVL_WARN))
		return;
	
	LOGF(DBGLVL_WARN, what.c_str());
}

void LOGWarning(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_WARN))
		return;
	
    char buffer[4096] = {0};
	
    va_list args;
	
    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);
	
	LockLoggerMutex();

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_WARN, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_ERROR, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

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

#ifdef LOG_CONSOLE
	DBG_SendLog(DBGLVL_ERROR, buffer);
#else
	m_Log << buffer << std::endl;
	fflush(stdout);
#endif

	UnlockLoggerMutex();
}
