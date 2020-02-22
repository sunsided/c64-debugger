#ifndef _SYS_THREADING_H_
#define _SYS_THREADING_H_

#include "SYS_Defs.h"

#if defined(WIN32)
#define USE_WIN32_THREADS
#endif

#if defined(USE_WIN32_THREADS)
#include <windows.h>
#endif

#include <pthread.h>

#define MT_THREAD_PRIORITY_NORMAL	0

class CSlrMutex
{
public:
	CSlrMutex(char *name);
	~CSlrMutex();
	
	char name[64];

#if defined(USE_WIN32_THREADS)
	HANDLE mutex;
#else
	pthread_mutex_t mutex;
#endif
	
	// for debug
	volatile int lockedLevel;
	
	void Lock();
	void Unlock();
};

class CSlrThread
{
public:
	pthread_t threadId;
	volatile bool isRunning;
	char threadName[256];
	
	CSlrThread();
	CSlrThread(char *threadName);

	~CSlrThread();

	virtual void ThreadSetName(char *name);
	virtual void ThreadRun(void *passData);
};

void SYS_StartThread(CSlrThread *run, void *passData, float priority);
void SYS_StartThread(CSlrThread *run, void *passData);
void SYS_StartThread(CSlrThread *run);
void SYS_KillThread(CSlrThread *run);

void SYS_SetThreadPriority(float priority);
void SYS_SetThreadName(char *name);

void SYS_SetMainProcessPriorityBoostDisabled(bool isPriorityBoostDisabled);
void SYS_SetMainProcessPriority(int priority);

unsigned long SYS_GetProcessId();

#endif
//_SYS_THREADING_H_
