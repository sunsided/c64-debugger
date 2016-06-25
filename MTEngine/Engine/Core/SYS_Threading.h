#ifndef _SYS_THREADING_H_
#define _SYS_THREADING_H_

#include <pthread.h>
#include "SYS_Defs.h"

#define MT_THREAD_PRIORITY_NORMAL	0

class CSlrMutex
{
public:
	CSlrMutex();
	~CSlrMutex();
	
	pthread_mutex_t mutex;

	// for debug
//	volatile bool isLocked;
	
	void Lock();
	void Unlock();
};

class CSlrThread
{
public:
	pthread_t threadId;
	volatile bool isRunning;
	char threadName[32];
	
	CSlrThread();
	~CSlrThread();

	virtual void ThreadSetName(char *name);
	virtual void ThreadRun(void *data);
};

void SYS_StartThread(CSlrThread *run, void *passData, float priority);
void SYS_StartThread(CSlrThread *run, void *passData);
void SYS_StartThread(CSlrThread *run);
void SYS_KillThread(CSlrThread *run);

void SYS_SetThreadPriority(float priority);
void SYS_SetThreadName(char *name);

#endif
//_SYS_THREADING_H_
