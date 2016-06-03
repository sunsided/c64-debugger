/*
 *  DBG_Log.h
 Created by Marcin Skoczylas on 09-11-19.
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
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#if !defined (GLOBAL_DEBUG_OFF)

//#define LOCAL_DEBUG_OFF
//#define FULL_LOG

//#define LOG_FILE
#undef LOG_FILE

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
 DBGLVL_FACEBOOK     | \
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
static bool logger_showThreadName = false;
static bool logger_showCurrentLevel = true;

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

#ifdef LOG_FILE
	time_t rawtime;
	struct tm * timeinfo;
	time ( &rawtime );
	timeinfo = localtime ( &rawtime );

    NSString *path = [NSString stringWithFormat:@"%@/MTEngine-%02d%02d%02d-%02d%02d.txt",
                      [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0],
                      (timeinfo->tm_year-100), (timeinfo->tm_mon+1), timeinfo->tm_mday, timeinfo->tm_hour, timeinfo->tm_min];

    NSLog(@"logger file path=%@", path);

	fpLog = fopen([path fileSystemRepresentation], "wb");
#endif

	LOG_SetLevel(DBGLVL_MAIN, true);
	LOG_SetLevel(DBGLVL_DEBUG, true);
	LOG_SetLevel(DBGLVL_DEBUG2, true);
	LOG_SetLevel(DBGLVL_RES, false);
	LOG_SetLevel(DBGLVL_GUI, false);
	LOG_SetLevel(DBGLVL_MEMORY, false);
	LOG_SetLevel(DBGLVL_ANIMATION, false);
	LOG_SetLevel(DBGLVL_LEVEL, true);
	LOG_SetLevel(DBGLVL_XMPLAYER, false);
	LOG_SetLevel(DBGLVL_AUDIO, false);
	LOG_SetLevel(DBGLVL_TODO, true);

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

void _LOGGER(unsigned int level, const char *fileName, unsigned int lineNum, const char *functionName, const char *format, ...)
{
	if (logThisLevel(level) == false)
		return;

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

//    if (logger_showThreadName)
//    {
//        NSString *threadName = [NSThread currentThread].name;
//        if (threadName == nil || [threadName length] == 0)
//        {
//            fprintf(stderr, "%8ld ", (unsigned long)pthread_self());
//#ifdef LOG_FILE
//            if (fpLog)
//                fprintf(fpLog, "%8ld ", (unsigned long)pthread_self());
//#endif
//        }
//        else
//        {
//            fprintf(stderr, "%-8s ", [threadName UTF8String]);
//#ifdef LOG_FILE
//            if (fpLog)
//                fprintf(fpLog, "%-8s ", [threadName UTF8String]);
//#endif
//        }
//    }

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
	if (level == DBGLVL_RES)
		return "[RES  ]";
	if (level == DBGLVL_GUI)
		return "[GUI  ]";
	if (level == DBGLVL_MEMORY)
		return "[MEM  ]";
	if (level == DBGLVL_FACEBOOK)
		return "[FB   ]";
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

	return "[> UNKNOWN <]";
	//return     "[>???<]";
}


#else
// GLOBAL_DEBUG_OFF

void LOG_Init(void) {}
void LOG_SetLevel(unsigned int level, bool isOn) {}
void LOG_Shutdown(void) {}

#endif









/*
 *  DBG_Logf.cpp
 *  MobiTracker
 *
 * [C] Marcin Skoczylas
 * debug console/file code
 *

#include "DBG_Log.h"
#include "SYS_Defs.h"
#include "SYS_CFileSystem.h"
#include <sys/time.h>

//#define DEBUG_OFF
//#define FULL_LOG

//#define LOG_FILE
#undef LOG_FILE

#ifdef LOG_FILE
FILE *fpLog = NULL;
#endif
*/

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

/*
 CMLog(@"My iPhone is an %@, v %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]);
 */

/*
 #define START_TIMER NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
 #define END_TIMER(msg) 	NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate]; CMLog([NSString stringWithFormat:@"%@ Time = %f", msg, stop-start]);

 - (NSData *)loadDataFromURL:(NSString *)dataURL
 {
 START_TIMER;
 NSData *data = [self doSomeStuff:dataURL];
 END_TIMER(@"loadDataFromURL");
 return data;
 }*/

// does not work: target_ip_sim is defined also on the device!
//#if defined(TARGET_IPHONE_SIMULATOR)
//#undef DEBUG_OFF
//#endif

/*
static byte currentLogLevel;
pthread_mutex_t loggerMutex;

#ifndef DEBUG_OFF

#ifdef FULL_LOG

bool logThisLevel(byte level)
{
	return true;
}

#else

bool logThisLevel(byte level)
{
	if (level == DBGLVL_MAIN) return true;
	if (level == DBGLVL_DEBUG) return true;
	if (level == DBGLVL_RES) return false;
	if (level == DBGLVL_GUI) return false; //	true	false
	if (level == DBGLVL_HTTP) return false;
	if (level == DBGLVL_XMPLAYER) return false;
	if (level == DBGLVL_AUDIO) return false;
	if (level == DBGLVL_ERROR) return true;	// always
	if (level == DBGLVL_TODO) return true;
	if (level == DBGLVL_SQL) return false;
	if (level == DBGLVL_XML) return false;

	if (level == currentLogLevel)
		return true;

	return false;
}

#endif // FULL_LOG

#else

bool logThisLevel(byte level)
{
//	if (level == DBGLVL_DEBUG) return true;
	return false;
}
#endif


const char *getLevelStr(byte level)
{
	if (level == DBGLVL_MAIN)
		return "[MAIN ]";
	if (level == DBGLVL_DEBUG)
		return "[DEBUG]";
	if (level == DBGLVL_RES)
		return "[RES  ]";
	if (level == DBGLVL_GUI)
		return "[GUI  ]";
	if (level == DBGLVL_XMPLAYER)
		return "[XM   ]";
	if (level == DBGLVL_AUDIO)
		return "[AUDIO]";
	if (level == DBGLVL_HTTP)
		return "[HTTP ]";
	if (level == DBGLVL_ERROR)
		return "[ERROR]";
	if (level == DBGLVL_TODO)
		return "[TODO ]";

	return "[> UNKNOWN <]";
}

// FORMATOWANIE w NSLog jest SPIERDOLONE chociaz sie kompiluje!!
// NSLog(@"%@", s);
// NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

//#define USE_COUT
char logBuf[512];

void LOG_Init(void)
{
	pthread_mutex_init(&loggerMutex, NULL);

	//currentLogLevel = DBGLVL_HTTP;

#ifdef LOG_FILE
	time_t rawtime;
	struct tm * timeinfo;
	time ( &rawtime );
	timeinfo = localtime ( &rawtime );

	sprintf(logBuf, "/tmp/MTEngine-%02d%02d%02d-%02d%02d.txt", (timeinfo->tm_year-100), (timeinfo->tm_mon+1), timeinfo->tm_mday,
			timeinfo->tm_hour, timeinfo->tm_min);

	NSString *fnameS = [[NSString alloc] initWithBytes:logBuf length:strlen(logBuf) encoding:NSASCIIStringEncoding];
	//	NSLog(@"%@", fnameS);

	NSString *path = [gPathToDocuments stringByAppendingPathComponent:fnameS];
	//	NSString *path = [NSString stringWithFormat:@"%@%@", gPathToTemp, fnameS];
	//	NSLog(@"%@", path);


	//fpLog = fopen([path fileSystemRepresentation], "wb");
	fpLog = fopen(logBuf, "wb");

	[fnameS release];
#endif

}

void LOG_Shutdown(void)
{
	LOGF(DBGLVL_MAIN, "closing stdlib & logfile\nbye!\n");
#ifdef LOG_FILE
	if (fpLog != NULL)
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

const char *getLevelStr(int level)
{
	if (level == DBGLVL_MAIN)
		return "[MAIN] ";
	if (level == DBGLVL_DEBUG)
		return "[DEBUG]";
	//if (level == DBGLVL_WARN)
	//	return "[WARN] ";
	if (level == DBGLVL_RES)
		return "[RES]  ";
	if (level == DBGLVL_GUI)
		return "[GUI]  ";
	if (level == DBGLVL_HTTP)
		return "[HTTP] ";
	//if (level == DBGLVL_DATABASE)		// cyan
	//	return "[DB]   ";
	if (level == DBGLVL_XMPLAYER)
		return "[PLAY] ";
	if (level == DBGLVL_AUDIO)
		return "[AUDIO]";
	if (level == DBGLVL_ERROR)
		return "[ERROR]";
	if (level == DBGLVL_TODO)
		return "[TODO] ";
	//if (level == DBGLVL_MEMORY)
	//	return "[MEM]  ";

	return "[UNKNOWN]";
}

void LOGT(byte level, char *what)
{
	if (!logThisLevel(level))
		return;
	LOGF(level, what);
}

void LOGT(byte level, const char *what)
{
	if (!logThisLevel(level))
		return;

	LOGF(level, what);
}

void LOGF(byte level, NSString *what)
{
	if (!logThisLevel(level))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_ERROR), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

void LOGF(byte level, char *fmt, ... )
{
    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);
	UnlockLoggerMutex();

}

void LOGF(byte level, std::string what)
{
	if (!logThisLevel(level))
		return;
	LOGF(level, what.c_str());
}

void LOGF(byte level, const char *fmt, ... )
{
	if (!logThisLevel(level))
		return;
    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(level), buffer);
		fflush(fpLog);
	}
#endif
	UnlockLoggerMutex();
}

////////LOGG

void LOGG(NSString *what)
{
	if (!logThisLevel(DBGLVL_GUI))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_GUI), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_GUI), buffer);
		fflush(fpLog);
	}
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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_GUI), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGG

////////LOGD

void _LOGD(const char *functName, NSString *what)
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%s %@", functName, what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

	UnlockLoggerMutex();
}

void _LOGD(const char *functName, char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%s %@", functName, s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_DEBUG), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();

}

void _LOGD(const char *functName, std::string what)
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;

	LOGF(DBGLVL_DEBUG, what.c_str());
}

void _LOGD(const char *functName, const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_DEBUG))
		return;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%s %@", functName, s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_DEBUG), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGD


////////LOGM

void LOGM(NSString *what)
{
	if (!logThisLevel(DBGLVL_MAIN))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_MAIN), buffer);
		fflush(fpLog);
	}
#endif
	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_MAIN), buffer);
		fflush(fpLog);
	}
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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_MAIN), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGM

////////LOGA

void LOGA(NSString *what)
{
	if (!logThisLevel(DBGLVL_AUDIO))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_AUDIO), buffer);
		fflush(fpLog);
	}
#endif
	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_AUDIO), buffer);
		fflush(fpLog);
	}
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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_AUDIO), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGA

////////LOGX

void LOGX(NSString *what)
{
	if (!logThisLevel(DBGLVL_XMPLAYER))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_XMPLAYER), buffer);
		fflush(fpLog);
	}
#endif
	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_XMPLAYER), buffer);
		fflush(fpLog);
	}
#endif

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_XMPLAYER), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGX


////////LOGR

void LOGR(NSString *what)
{
	if (!logThisLevel(DBGLVL_RES))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGR

////////LOGH

void LOGH(NSString *what)
{
	if (!logThisLevel(DBGLVL_HTTP))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

void LOGH(char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_HTTP))
		return;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

void LOGH(std::string what)
{
	if (!logThisLevel(DBGLVL_HTTP))
		return;

	LOGF(DBGLVL_RES, what.c_str());
}

void LOGH(const char *fmt, ... )
{
	if (!logThisLevel(DBGLVL_HTTP))
		return;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_RES), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGH

////////LOGTODO

void LOGTODO(NSString *what)
{
	if (!logThisLevel(DBGLVL_TODO))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"\n\n  ##################################### TODO: ######################################");
	NSLog(@"%@", what);
	NSLog(@"\n\n################################### ^^^ TODO ^^^ #####################################");
#else
	std::cout << what << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_TODO), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];

	NSLog(@"\n\n  ##################################### TODO: ######################################");
	NSLog(@"%@", s);
	NSLog(@"\n\n################################### ^^^ TODO ^^^ #####################################");

	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_TODO), buffer);
		fflush(fpLog);
	}
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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"\n\n  ##################################### TODO: ######################################");
	NSLog(@"%@", s);
	NSLog(@"\n\n################################### ^^^ TODO ^^^ #####################################");
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_TODO), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
///////////// LOGTODO



void LOGError(NSString *what)
{
	if (!logThisLevel(DBGLVL_ERROR))
		return;

	LockLoggerMutex();
#ifndef USE_COUT
	NSLog(@"%@", what);
#else
	std::cout << what << std::endl;
#endif

#ifdef LOG_FILE
	const char* buffer = [what UTF8String];
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_ERROR), buffer);
		fflush(fpLog);
	}
#endif

	fflush(stdout);
	UnlockLoggerMutex();
}

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);

#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_ERROR), buffer);
		fflush(fpLog);
	}
#endif

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
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);
#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_ERROR), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
/////////////


///////////////

void SYS_Errorf(char *fmt, ... )
{
	std::cout << "ERROR:" << std::endl;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);
	UnlockLoggerMutex();
}

void SYS_Errorf(const char *fmt, ... )
{
	std::cout << "ERROR:" << std::endl;

    char buffer[4096] = {0};

    va_list args;

    va_start(args, fmt);
    vsprintf(buffer, fmt, args);
    va_end(args);

	LockLoggerMutex();
#ifndef USE_COUT
	NSString* s = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
#else
	std::cout << buffer << std::endl;
#endif
	fflush(stdout);
#ifdef LOG_FILE
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;

	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);

	unsigned int threadId = (long int)syscall(224);

	int ms = tv.tv_usec/10000;
	if (fpLog != NULL)
	{
		fprintf(fpLog, "%02d:%02d:%02d,%03d %4.4x %s %s\n",
				tm->tm_hour, tm->tm_min, tm->tm_sec, ms,
				threadId, getLevelStr(DBGLVL_ERROR), buffer);
		fflush(fpLog);
	}
#endif

	UnlockLoggerMutex();
}
*/

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
