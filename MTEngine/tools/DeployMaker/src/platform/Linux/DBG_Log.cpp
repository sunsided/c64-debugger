/*
 * DBG_Log.cpp
 *
 *  Created on: Jun 9, 2011
 *      Author: mars
 */
#include "DBG_Log.h"
//#include "CByteBuffer.h"
#include <pthread.h>
#include <sys/time.h>
#include <unistd.h>

#define USE_COLOR_CONSOLE
//#define LOG_FILE
//#define DEBUG_OFF
//#define FULL_LOG

static int currentLogLevel;
pthread_mutex_t loggerMutex;

#ifdef LOG_FILE
FILE *fpLog = NULL;
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
	if (level == DBGLVL_WARN)
		return "[WARN] ";
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
//CByteBuffer *logEventsBuffer;

void DBG_SendLog(int debugLevel, char *message);

char logBuf[512];

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

#ifdef LOG_FILE
	time_t rawtime;
	struct tm * timeinfo;
	time ( &rawtime );
	timeinfo = localtime ( &rawtime );

	sprintf(logBuf, "./log/MTEngine-%02d%02d%02d-%02d%02d.txt", (timeinfo->tm_year-100), (timeinfo->tm_mon+1), timeinfo->tm_mday,
												timeinfo->tm_hour, timeinfo->tm_min);

	fpLog = fopen(logBuf, "wb");
#endif

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
	/*
	 *
	  	\033[22;30m - black
		\033[22;31m - red
		\033[22;32m - green
		\033[22;33m - brown
		\033[22;34m - blue
		\033[22;35m - magenta
		\033[22;36m - cyan
		\033[22;37m - gray
		\033[01;30m - dark gray
		\033[01;31m - light red
		\033[01;32m - light green
		\033[01;33m - yellow
		\033[01;34m - light blue
		\033[01;35m - light magenta
		\033[01;36m - light cyan
		\033[01;37m - white
	 */

#ifdef USE_COLOR_CONSOLE
	switch(debugLevel)
	{
		case DBGLVL_INFO:
			fprintf(stdout, "\033[01;33m");
			break;
		case DBGLVL_ERROR:
			fprintf(stdout, "\033[01;31m");
			break;
		case DBGLVL_WARN:
			fprintf(stdout, "\033[01;35m");
			break;
		case DBGLVL_FATAL:
			fprintf(stdout, "\033[01;31m");
			break;
		case DBGLVL_MEMORY:
			fprintf(stdout, "\033[01;31m");
			break;
		case DBGLVL_DATABASE:
			fprintf(stdout, "\033[22;36m");
			break;
		case DBGLVL_DEBUG:
			fprintf(stdout, "\033[22;37m");
			break;
		case DBGLVL_GUI:
			fprintf(stdout, "\033[01;32m");
			break;
		default:
			fprintf(stdout, "\033[22;37m");
			break;
	}
#endif

	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
#ifdef LOG_FILE
	//03:22:07,127 000010B4 [DEBUG] CGuiList::CGuiList done
	fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4X %s %s\n",
			tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
			threadId, getLevelStr(debugLevel), message);
	fflush(fpLog);
#endif

	fprintf(stdout, "%02d:%02d:%02d,%03d %4.4X %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(debugLevel), message);
	fflush(stdout);

}

void DBG_PrintBytes(void *data, unsigned int numBytes)
{
	LockLoggerMutex();

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

	DBG_SendLog(DBGLVL_PLAYER, buffer);

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

	DBG_SendLog(DBGLVL_PLAYER, buffer);

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

	DBG_SendLog(DBGLVL_ERROR, buffer);

	UnlockLoggerMutex();
}
/////////////

///////////// LOGTODO
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

	DBG_SendLog(DBGLVL_WARN, buffer);

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

	DBG_SendLog(DBGLVL_WARN, buffer);

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
