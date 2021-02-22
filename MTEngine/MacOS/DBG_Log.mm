/*
 *  DBG_Log.h
 Created by Marcin Skoczylas on 2009-11-19.
 Copyright 2009 Marcin Skoczylas
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

// TODO: add colors http://deepitpro.com/en/articles/XcodeColors/info/

#include "DBG_Log.h"
#include <pthread.h>
#include <sys/time.h>

#if !defined (GLOBAL_DEBUG_OFF)

//#define LOCAL_DEBUG_OFF
//#define FULL_LOG

//#define LOG_FILE

///////////////////////////////////////////////////////////////

#ifdef LOG_FILE
FILE *fpLog = NULL;
#endif

#ifdef FINAL_RELEASE
#define BUFSIZE 256
#else
// 2 MB
#define BUFSIZE 1024*1024*2
#endif

bool logThisLevel(unsigned int level);
const char *getLevelStr(unsigned int level);
void LockLoggerMutex(void);
void UnlockLoggerMutex(void);

pthread_mutex_t loggerMutex;

static unsigned int logger_currentLogLevel = -1;
/*
 DBGLVL_DEBUG        | \
 DBGLVL_MAIN         | \
 DBGLVL_RES          | \
 DBGLVL_GUI          | \
 DBGLVL_PAINT        | \
 DBGLVL_FLURRY       | \
 DBGLVL_WEBSERVICE   | \
 DBGLVL_XML          | \
 DBGLVL_HTTP         | \
 DBGLVL_XMPLAYER     | \
 DBGLVL_AUDIO        | \
 DBGLVL_TODO         | \
 DBGLVL_ERROR;
 */


static bool logger_showTimestamp = true;
static bool logger_showFileName = false;
static bool logger_showThreadName = true;
static bool logger_showCurrentLevel = true;

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

#ifdef LOG_FILE
	time_t rawtime;
	struct tm * timeinfo;
	time ( &rawtime );
	timeinfo = localtime ( &rawtime );

	// log to Documents: NSDocumentDirectory
	// log to Desktop
    NSString *path = [NSString stringWithFormat:@"%@/C64Debugger-%02d%02d%02d-%02d%02d.txt",
                      [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0],
                      (timeinfo->tm_year-100), (timeinfo->tm_mon+1), timeinfo->tm_mday, timeinfo->tm_hour, timeinfo->tm_min];

    NSLog(@"logger file path=%@", path);

	fpLog = fopen([path fileSystemRepresentation], "wb");
#endif

	LOG_SetLevel(DBGLVL_MAIN, true);
	LOG_SetLevel(DBGLVL_WARN, false);
	LOG_SetLevel(DBGLVL_DEBUG, true);
	LOG_SetLevel(DBGLVL_DEBUG2, false);
	LOG_SetLevel(DBGLVL_INPUT, false);
	LOG_SetLevel(DBGLVL_GUI, false);
	LOG_SetLevel(DBGLVL_RES, false);
	LOG_SetLevel(DBGLVL_MEMORY, false);
	LOG_SetLevel(DBGLVL_ANIMATION, false);
	LOG_SetLevel(DBGLVL_LEVEL, false);
	LOG_SetLevel(DBGLVL_XMPLAYER, false);
	LOG_SetLevel(DBGLVL_AUDIO, false);
	LOG_SetLevel(DBGLVL_TODO, false);
	
	LOG_SetLevel(DBGLVL_PAINT, false);
	
	LOG_SetLevel(DBGLVL_VICE_DEBUG, false);
	LOG_SetLevel(DBGLVL_VICE_MAIN, false);
	LOG_SetLevel(DBGLVL_VICE_VERBOSE, false);
	
	LOG_SetLevel(DBGLVL_ATARI_MAIN, false);
	LOG_SetLevel(DBGLVL_ATARI_DEBUG, false);

//	LOG_SetLevel(DBGLVL_MAIN, true);
//	LOG_SetLevel(DBGLVL_DEBUG, true);
//	LOG_SetLevel(DBGLVL_DEBUG2, true);
//	LOG_SetLevel(DBGLVL_INPUT, false);
//	LOG_SetLevel(DBGLVL_RES, false);
//	LOG_SetLevel(DBGLVL_GUI, false);
//	LOG_SetLevel(DBGLVL_MEMORY, false);
//	LOG_SetLevel(DBGLVL_ANIMATION, true);
//	LOG_SetLevel(DBGLVL_LEVEL, true);
//	LOG_SetLevel(DBGLVL_XMPLAYER, false);
//	LOG_SetLevel(DBGLVL_AUDIO, false);
//	LOG_SetLevel(DBGLVL_TODO, true);
//
//	LOG_SetLevel(DBGLVL_PAINT, false);
//	
//	LOG_SetLevel(DBGLVL_VICE_DEBUG, false);
//	LOG_SetLevel(DBGLVL_VICE_MAIN, false);
//	LOG_SetLevel(DBGLVL_VICE_VERBOSE, false);
//
//	LOG_SetLevel(DBGLVL_ATARI_MAIN, true);
//	LOG_SetLevel(DBGLVL_ATARI_DEBUG, true);

	
	/// leave only debug2:
//	LOG_SetLevel(DBGLVL_MAIN, false);
//	LOG_SetLevel(DBGLVL_DEBUG, false);
//	LOG_SetLevel(DBGLVL_RES, false);
//	LOG_SetLevel(DBGLVL_GUI, false);
//	LOG_SetLevel(DBGLVL_ANIMATION, false);
//	LOG_SetLevel(DBGLVL_LEVEL, false);
//	LOG_SetLevel(DBGLVL_XMPLAYER, false);
//	LOG_SetLevel(DBGLVL_AUDIO, false);
//	LOG_SetLevel(DBGLVL_MEMORY, false);
//	LOG_SetLevel(DBGLVL_TODO, false);
//	LOG_SetLevel(DBGLVL_DEBUG2, true);

}

void LOG_SetLevel(unsigned int level, bool isOn)
{
	if (isOn)
	{
		SET_BIT(logger_currentLogLevel, level);
	}
	else
	{
		REMOVE_BIT(logger_currentLogLevel, level);
	}
}

void LOG_Shutdown(void)
{
	fprintf(stderr, "LOG_Shutdown: bye\n");
	fflush(stderr);
#ifdef LOG_FILE
	if (fpLog)
	{
		fprintf(fpLog, "LOG_Shutdown: bye\n");
        fclose(fpLog);
	}
    fpLog = NULL;
#endif
}

void LockLoggerMutex(void)
{
	pthread_mutex_lock(&loggerMutex);
}

void UnlockLoggerMutex(void)
{
	pthread_mutex_unlock(&loggerMutex);
}

int _LOGGER(unsigned int level, const char *fileName, unsigned int lineNum, const char *functionName, const char *format, ...)
{
	if (logThisLevel(level) == false)
		return 0;

	LockLoggerMutex();

    if (logger_showTimestamp)
    {
        struct timeval  tv;
        struct timezone tz;
        struct tm      *tm;

        gettimeofday(&tv, &tz);
        tm = localtime(&tv.tv_sec);

        unsigned int ms = (unsigned int)tv.tv_usec/(unsigned int)10000;

        fprintf(stderr, "%02d:%02d:%02d,%03d ",
                tm->tm_hour, tm->tm_min, tm->tm_sec, ms);
#ifdef LOG_FILE
        if (fpLog)
        {
            fprintf(fpLog, "%02d:%02d:%02d,%03d ",
                    tm->tm_hour, tm->tm_min, tm->tm_sec, ms);
        }
#endif

    }

	if (logger_showFileName)
	{
		fprintf(stderr, "%s:%d ", fileName, lineNum);
#ifdef LOG_FILE
        if (fpLog)
        {
            fprintf(fpLog, "%s:%d ", fileName, lineNum);
        }
#endif
	}

    if (logger_showThreadName)
    {
        NSString *threadName = [NSThread currentThread].name;
        if (threadName == nil || [threadName length] == 0)
        {
            fprintf(stderr, "%8ld ", (unsigned long)pthread_self());
#ifdef LOG_FILE
            if (fpLog)
                fprintf(fpLog, "%8ld ", (unsigned long)pthread_self());
#endif
        }
        else
        {
            fprintf(stderr, "%-8s ", [threadName UTF8String]);
#ifdef LOG_FILE
            if (fpLog)
                fprintf(fpLog, "%-8s ", [threadName UTF8String]);
#endif
        }
    }

    if (logger_showCurrentLevel)
    {
        fprintf(stderr, "%s ", getLevelStr(level));
#ifdef LOG_FILE
        if (fpLog)
			fprintf(fpLog, "%s ", getLevelStr(level));
#endif
    }

	static char buffer[BUFSIZE];
	//memset(buffer, 0x00, BUFSIZE);

    va_list args;

    va_start(args, format);
    vsnprintf(buffer, BUFSIZE, format, args);
    va_end(args);

	int l = strlen(buffer);
	for (int i = 0; i < l; i++)
	{
		if (buffer[i] < 32 && buffer[i] != 0x0A && buffer[i] != 0x0D && buffer[i] != 0x09)
		{
			buffer[i] = '?';
		}
	}
	buffer[BUFSIZE-1] = 0x00;

	fprintf(stderr, "%s", buffer);

#ifdef LOG_FILE
	if (fpLog)
		fprintf(fpLog, "%s", buffer);
#endif

    fprintf(stderr, "\n");
    fflush(stderr);
#ifdef LOG_FILE
    if (fpLog)
	{
		fprintf(fpLog, "\n");
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
	
	return 0;
}

int _LOGGER(unsigned int level, const char *fileName, unsigned int lineNum, const char *functionName, const NSString *format, ...)
{
	if (logThisLevel(level) == false)
		return 0;

	LockLoggerMutex();

    if (logger_showTimestamp)
    {
        struct timeval  tv;
        struct timezone tz;
        struct tm      *tm;

        gettimeofday(&tv, &tz);
        tm = localtime(&tv.tv_sec);

        unsigned int ms = (unsigned int)tv.tv_usec/(unsigned int)10000;

        fprintf(stderr, "%02d:%02d:%02d,%03d ",
                tm->tm_hour, tm->tm_min, tm->tm_sec, ms);
#ifdef LOG_FILE
        if (fpLog)
        {
            fprintf(fpLog, "%02d:%02d:%02d,%03d ",
                    tm->tm_hour, tm->tm_min, tm->tm_sec, ms);
        }
#endif

    }

	if (logger_showFileName)
	{
		fprintf(stderr, "%s:%d ", fileName, lineNum);
#ifdef LOG_FILE
        if (fpLog)
        {
            fprintf(fpLog, "%s:%d ", fileName, lineNum);
        }
#endif
	}

    if (logger_showThreadName)
    {
        NSString *threadName = [NSThread currentThread].name;
        if (threadName == nil || [threadName length] == 0)
        {
            fprintf(stderr, "%8ld ", (unsigned long)pthread_self());
#ifdef LOG_FILE
            if (fpLog)
                fprintf(fpLog, "%8ld ", (unsigned long)pthread_self());
#endif
        }
        else
        {
            fprintf(stderr, "%-8s ", [threadName UTF8String]);
#ifdef LOG_FILE
            if (fpLog)
                fprintf(fpLog, "%-8s ", [threadName UTF8String]);
#endif
        }
    }

    if (logger_showCurrentLevel)
    {
        fprintf(stderr, "%s ", getLevelStr(level));
#ifdef LOG_FILE
        if (fpLog)
			fprintf(fpLog, "%s ", getLevelStr(level));
#endif
    }

    va_list argList;
	va_start(argList, format);

	CFStringRef log = CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)format, argList);
	char *ptr = (char *)CFStringGetCStringPtr(log, kCFStringEncodingUTF8);
	if (ptr)
    {
		fprintf(stderr, "%s", ptr);
#ifdef LOG_FILE
        if (fpLog)
			fprintf(fpLog, "%s", ptr);
#endif
    }
	else
    {
		unsigned buflen = CFStringGetLength(log) * 4;
		ptr = (char*)malloc(buflen);
		if (CFStringGetCString(log, ptr, buflen, kCFStringEncodingUTF8))
		{
            fprintf(stderr, "%s", ptr);
#ifdef LOG_FILE
			if (fpLog)
				fprintf(fpLog, "%s", ptr);
#endif
		}
		free(ptr);
	}
	CFRelease(log);

	va_end(argList);

    fprintf(stderr, "\n");
    fflush(stderr);
#ifdef LOG_FILE
    if (fpLog)
	{
		fprintf(fpLog, "\n");
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
	
	return 0;
}


bool logThisLevel(unsigned int level)
{
#if defined(FULL_LOG)
    return true;
#elif defined(LOCAL_DEBUG_OFF)
    return false;
#else
    if (IS_SET(logger_currentLogLevel, level))
        return true;

    return false;
#endif

}

const char *getLevelStr(unsigned int level)
{
	if (level == DBGLVL_MAIN)
		return "[MAIN ]";
	if (level == DBGLVL_DEBUG)
		return "[DEBUG]";
	if (level == DBGLVL_DEBUG2)
		return "[DEBG2]";
	if (level == DBGLVL_INPUT)
		return "[INPUT]";
	if (level == DBGLVL_RES)
		return "[RES  ]";
	if (level == DBGLVL_GUI)
		return "[GUI  ]";
	if (level == DBGLVL_MEMORY)
		return "[MEM  ]";
	if (level == DBGLVL_PAINT)
		return "[PAINT]";
	if (level == DBGLVL_FLURRY)
		return "[LEVEL]";	//FLURRY
	if (level == DBGLVL_WEBSERVICE)
		return "[WEBS ]";
	if (level == DBGLVL_XML)
		return "[XML  ]";
	if (level == DBGLVL_HTTP)
		return "[HTTP ]";
	if (level == DBGLVL_XMPLAYER)
		return "[XM   ]";
	if (level == DBGLVL_AUDIO)
		return "[AUDIO]";
	if (level == DBGLVL_ADS)
		return "[ ADS ]";
	if (level == DBGLVL_ANIMATION)
		return "[ANIM ]";
	if (level == DBGLVL_SCRIPT)
		return ">SCRPT<";
	if (level == DBGLVL_NET)
		return "[NET ] ";
	if (level == DBGLVL_NET_SERVER)
		return "[SERV>]";
	if (level == DBGLVL_NET_CLIENT)
		return "[<CLNT]";
	if (level == DBGLVL_ERROR)
		return "[> ERROR <]";
	if (level == DBGLVL_WARN)
		return "[> WARNING <]";
	if (level == DBGLVL_TODO)
		return "[TODO ]";
	if (level == DBGLVL_VICE_DEBUG)
		return "[VICE ]";
	if (level == DBGLVL_VICE_MAIN)
		return "[*VICE]";
	if (level == DBGLVL_VICE_VERBOSE)
		return "[VICE ]";

	if (level == DBGLVL_ATARI_DEBUG)
		return "[ATARI]";
	if (level == DBGLVL_ATARI_MAIN)
		return "[ATARI]";

	return "[> UNKNOWN <]";
	//return     "[>???<]";
}


#else
// GLOBAL_DEBUG_OFF

void LOG_Init(void) {}
void LOG_SetLevel(unsigned int level, bool isOn) {}
void LOG_Shutdown(void) {}

#endif

