#include "SYS_Threading.h"
#include "SYS_Main.h"
#include "VID_GLViewController.h"
#include <signal.h>
#include <errno.h>

//#define DEBUG_MUTEX
//#define DEBUG_MUTEX_TIMEOUT 5000

void CSlrThread::ThreadRun(void *passData)
{
}

class CThreadPassData
{
public:
	void *passData;
	CSlrThread *threadStarter;
	float priority;
};


void *ThreadStarterFuncRun(void *dataToPassWithArg)
{
	CThreadPassData *passArg = (CThreadPassData *)dataToPassWithArg;

#if defined(IPHONE) || defined(MACOS)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:passArg->priority];
#endif
	
	CSlrThread *threadStarter = passArg->threadStarter;
	void *passData = passArg->passData;
	delete passArg;
	
#if !defined(FINAL_RELEASE)
	if (threadStarter->isRunning == true)
	{
		LOGError("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		LOGError("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		LOGError("ThreadStarterFuncRun: threadStarter '%s' is already running", threadStarter->threadName);
		LOGError("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		LOGError("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		//SYS_FatalExit("ThreadStarterFuncRun: threadStarter '%s' is already running", threadStarter->threadName);
	}
#endif

#if defined(IPHONE) || defined(MACOS)
//	NSLog(@"ThreadStarterFuncRun: threadId=%x threadName=%s", (u64)pthread_self(), threadStarter->threadName);
#endif

	threadStarter->isRunning = true;
	threadStarter->ThreadRun(passData);
	threadStarter->isRunning = false;
	
#if defined(IPHONE) || defined(MACOS)
	if (pool != nil)	// ios8 bug
	{
		[pool release];
	}
#endif
	
	return NULL;
}

void SYS_StartThread(CSlrThread *run, void *passData, float priority)
{
#if !defined(WIN32)
	// crashes on windows??
	LOGD("SYS_StartThread: threadId=%d isRunning=%s", run->threadId, STRBOOL(run->isRunning));
#endif

	if (run->isRunning)
	{
		SYS_FatalExit("thread %d is already running", run->threadId);
	}
	
	CThreadPassData *passArg = new CThreadPassData();
	passArg->passData = passData;
	passArg->threadStarter = run;
	passArg->priority = priority;
		
	int result = pthread_create(&run->threadId, NULL, ThreadStarterFuncRun, passArg);
	
	if (result != 0)
		SYS_FatalExit("ThreadedLoadImages: thread creation failed %d", result);
}

void SYS_StartThread(CSlrThread *run, void *passData)
{
	SYS_StartThread(run, passData, MT_THREAD_PRIORITY_NORMAL);
}

void SYS_StartThread(CSlrThread *run)
{
	SYS_StartThread(run, NULL, MT_THREAD_PRIORITY_NORMAL);
}

CSlrThread::CSlrThread()
{
// win32 sucks
#ifndef WIN32
	this->threadId = 0;
#endif
	this->isRunning = false;
	strcpy(this->threadName, "thread");
};

CSlrThread::CSlrThread(char *setThreadName)
{
	// win32 sucks
#ifndef WIN32
	this->threadId = 0;
#endif
	this->isRunning = false;
	strcpy(this->threadName, setThreadName);
};

void CSlrThread::ThreadSetName(char *name)
{
	strcpy(this->threadName, name);
	SYS_SetThreadName(name);
}

CSlrThread::~CSlrThread()
{
	// win32 sucks
#ifndef WIN32
	if (this->threadId != 0)
	{
		SYS_KillThread(this);
	}
#endif
}

void SYS_KillThread(CSlrThread *thread)
{
#ifdef WIN32
	SYS_FatalExit("FUCK YOU");
#else
	pthread_kill(thread->threadId, SIGKILL);
	thread->threadId = 0;
#endif
}

void SYS_SetThreadPriority(float priority)
{
#if defined(IOS) || defined(MACOS)
	[NSThread setThreadPriority:priority];
#else
	LOGTODO("SYS_SetThreadPriority: %f", priority);
#endif
}

void SYS_SetThreadName(char *name)
{
#if defined(IOS) || defined(MACOS)
	
	[[NSThread currentThread] setName:[NSString stringWithUTF8String:name]];

#else
	LOGTODO("SYS_SetThreadName");
#endif
}

#if defined(MACOS) | defined(LINUX)
void SYS_SetMainProcessPriorityBoostDisabled(bool isPriorityBoostDisabled)
{
	LOGTODO("not implemented SYS_SetMainProcessPriorityBoostDisabled: isPriorityBoostDisabled=%s", STRBOOL(isPriorityBoostDisabled));
}

void SYS_SetMainProcessPriority(int priority)
{
	LOGTODO("not implemented SYS_SetMainProcessPriority: priority=%d", priority);
}
#else
// SYS_SetMainProcessPriority and SYS_SetMainProcessPriorityBoost are implemented in SYS_Startup.cpp on Win32
#endif

CSlrMutex::CSlrMutex(char *name)
{
	strcpy(this->name, name);
	
	//LOGD("CSlrMutex::CSlrMutex: %s", this->name);
	
#if defined(USE_WIN32_THREADS)
	mutex = CreateMutex(
						NULL,              // default security attributes
						FALSE,             // initially not owned
						NULL);             // unnamed mutex

	if (mutex == NULL)
	{
		SYS_FatalExit("CreateMutex error: %d\n", GetLastError());
	}
	
#else

	pthread_mutexattr_t attr;
	pthread_mutexattr_init(&attr);
	pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
	
	pthread_mutex_init(&mutex, &attr);
	pthread_mutexattr_destroy(&attr);

	lockedLevel = 0;
	
#endif

}

CSlrMutex::~CSlrMutex()
{
	LOGD("CSlrMutex::~CSlrMutex: %s", this->name);
#if defined(USE_WIN32_THREADS)
//	CloseHandle(mutex);
#else
	pthread_mutex_destroy(&mutex);
	
#endif
}
	
void CSlrMutex::Lock()
{
//	if (strcmp(this->name, "CSoundEngine"))
//	{
//		LOGD("CSlrMutex::Lock: name=%s lockedLevel=%d (after=%d)", this->name, lockedLevel, lockedLevel+1);
//	}
	
#if defined(USE_WIN32_THREADS)
	DWORD dwWaitResult = WaitForSingleObject(
			mutex,    // handle to mutex
            INFINITE);  // no time-out interval
	
	if (dwWaitResult != 0)
	{
		SYS_FatalExit("CSlrMutex::Lock: dwWaitResult=%d %s", dwWaitResult, this->name);
	}
	
#else
	#if defined(DEBUG_MUTEX)
		long timeout = SYS_GetCurrentTimeInMillis() + DEBUG_MUTEX_TIMEOUT;
		
		while (pthread_mutex_trylock(&mutex) == EBUSY)
		{
			long now = SYS_GetCurrentTimeInMillis();
			if (now >= timeout)
			{
				LOGError("Mutex lock timeout, name=%s", this->name);
				return;
			}
			
			SYS_Sleep(5);
		}
		lockedLevel++;
	
	#else
		pthread_mutex_lock(&mutex);
		lockedLevel++;
	#endif
#endif
}

void CSlrMutex::Unlock()
{
//	if (strcmp(this->name, "CSoundEngine"))
//	{
//		LOGD("CSlrMutex::Unlock: name=%s level before=%d (after=%d)", this->name, lockedLevel, lockedLevel-1);
//	}

#if defined(USE_WIN32_THREADS)
	if (!ReleaseMutex(mutex))
	{
		LOGError("Release Mutex %s error %d", this->name, GetLastError());
		SYS_FatalExit("ReleaseMutex %s %d", this->name, GetLastError());
	}
#else
	
	lockedLevel--;
	pthread_mutex_unlock(&mutex);

#endif
}

unsigned long SYS_GetProcessId()
{
#if defined(WIN32)
	return GetCurrentProcessId();
#else
	return getpid();
#endif
}

