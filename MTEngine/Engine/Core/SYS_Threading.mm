#include "SYS_Threading.h"
#include "SYS_Main.h"
#include "VID_GLViewController.h"
#include <signal.h>

#define DEBUG_MUTEX

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

CSlrMutex::CSlrMutex(char *name)
{
	strcpy(this->name, name);
	
//#if defined(LINUX)

	pthread_mutexattr_t attr;
	pthread_mutexattr_init(&attr);
	pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
	
	pthread_mutex_init(&mutex, &attr);
	pthread_mutexattr_destroy(&attr);

	lockedLevel = 0;
	
//#elif defined(WINDOWS)
//	mutex = new CRITICAL_SECTION;
//	InitializeCriticalSection((CRITICAL_SECTION *)mutex);
//#endif
}

CSlrMutex::~CSlrMutex()
{
//#if defined(LINUX)

	pthread_mutex_destroy(&mutex);
	
//#elif defined(HAVE_MS_THREAD)
//	DeleteCriticalSection((CRITICAL_SECTION *)mutex);
//	delete (CRITICAL_SECTION *)mutex;
//#endif
}
	
void CSlrMutex::Lock()
{
//#ifdef HAVE_PTHREAD
//	pthread_mutex_lock((pthread_mutex_t*)mutex);
//#elif defined(HAVE_MS_THREAD)
//	EnterCriticalSection((CRITICAL_SECTION *)mutex);
//#endif
	
#if defined(DEBUG_MUTEX)
	long timeout = SYS_GetCurrentTimeInMillis() + 5000;
	
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
	
#else
	pthread_mutex_lock(&mutex);
	lockedLevel++;
#endif
	
}

void CSlrMutex::Unlock()
{
//#ifdef HAVE_PTHREAD
//	pthread_mutex_unlock((pthread_mutex_t*)mutex);
//#elif defined(HAVE_MS_THREAD)
//	LeaveCriticalSection((CRITICAL_SECTION *)mutex);
//#endif
	
	
	lockedLevel--;
	pthread_mutex_unlock(&mutex);
}

unsigned long SYS_GetProcessId()
{
#if defined(WIN32)
	return GetCurrentProcessId();
#else
	return getpid();
#endif
}

