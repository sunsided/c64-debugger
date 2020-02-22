#include "DBG_Log.h"
#include "SYS_PauseResume.h"
#include "VID_GLViewController.h"
#include "SYS_Threading.h"
#include <list>

std::list<CApplicationPauseResumeListener *> pauseResumeListeners;
CSlrMutex *pauseResumeListenersMutex;
static volatile bool sysPauseResumeInitDone = false;
static volatile byte sysApplicationState = APPLICATION_STATE_UNKNOWN;

std::list<CSlrString *> listOfFilesToOpenAtStartup;

void SYS_InitApplicationPauseResume()
{
	if (sysPauseResumeInitDone == false)
	{
		sysPauseResumeInitDone = true;

		LOGM("SYS_InitApplicationPauseResume()");
		pauseResumeListeners.clear();
		
		pauseResumeListenersMutex = new CSlrMutex("pauseResumeListenersMutex");
		
		sysApplicationState = APPLICATION_STATE_INIT;
	}
}

void LockPauseResumeListenersListMutex()
{
#ifdef LOG_ACCEL_LIST
	LOGD("LockPauseResumeListenersListMutex");
#endif
	
	pauseResumeListenersMutex->Lock();
}

void UnlockPauseResumeListenersListMutex()
{
#ifdef LOG_ACCEL_LIST
	LOGD("UnlockPauseResumeListenersListMutex");
#endif
	
	pauseResumeListenersMutex->Unlock();
}

void SYS_ApplicationAddOpenFileAtStartup(CSlrString *filePath)
{
	SYS_InitApplicationPauseResume();
	
	LOGD("SYS_ApplicationAddOpenFileAtStartup");
	LockPauseResumeListenersListMutex();
	listOfFilesToOpenAtStartup.push_back(filePath);
	UnlockPauseResumeListenersListMutex();
}

std::list<CSlrString *> *SYS_ApplicationGetListOfFilesToOpen()
{
	std::list<CSlrString *> *list = new std::list<CSlrString *>();
	
	LockPauseResumeListenersListMutex();
	
	while (!listOfFilesToOpenAtStartup.empty())
	{
		CSlrString *f = listOfFilesToOpenAtStartup.front();
		list->push_back(f);
		
		listOfFilesToOpenAtStartup.pop_front();
	}
	
	UnlockPauseResumeListenersListMutex();
	return list;
}

bool SYS_ApplicationAreFilesToOpenAvailable()
{
	return !(listOfFilesToOpenAtStartup.empty());
}

void SYS_ApplicationOpenFile()
{
	LOGD("SYS_ApplicationOpenFile()");
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationOpenFiles();
	}
	UnlockPauseResumeListenersListMutex();
}

void SYS_ApplicationStarted()
{
	LOGD("SYS_ApplicationStarted()");
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationStarted();
	}
	UnlockPauseResumeListenersListMutex();

	sysApplicationState = APPLICATION_STATE_RUNNING;
}

void SYS_ApplicationPaused()
{
	LOGD("SYS_ApplicationPaused()");
	sysApplicationState = APPLICATION_STATE_PAUSED;
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationPaused();
	}
	UnlockPauseResumeListenersListMutex();
}

void SYS_ApplicationResumed()
{
	LOGD("SYS_ApplicationResumed()");
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationResumed();
	}
	UnlockPauseResumeListenersListMutex();
	
	VID_ResetLogicClock();
	
	sysApplicationState = APPLICATION_STATE_RUNNING;
}

void SYS_ApplicationEnteredBackground()
{
	LOGG("SYS_ApplicationEnteredBackground()");
	LockPauseResumeListenersListMutex();
	sysApplicationState = APPLICATION_STATE_BACKGROUND;
	
	LOGG("... entered Background");
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		LOGG("... listener");
		listener->ApplicationEnteredBackground();
	}
	UnlockPauseResumeListenersListMutex();
	LOGG("SYS_ApplicationEnteredBackground done");
}

void SYS_ApplicationEnteredForeground()
{
	LOGD("SYS_ApplicationEnteredForeground()");
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationEnteredForeground();
	}
	UnlockPauseResumeListenersListMutex();

	//sysApplicationState = APPLICATION_STATE_FOREGROUND;
}

void SYS_ApplicationShutdown()
{
	LOGD("SYS_ApplicationShutdown()");
	sysApplicationState = APPLICATION_STATE_SHUTDOWN;
	
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationShutdown();
	}
	UnlockPauseResumeListenersListMutex();
	
	VID_StoreMainWindowPosition();
}

void SYS_ApplicationSystemSettingsUpdated(void *settingsData)
{
	LOGD("SYS_ApplicationSystemSettingsUpdated()");
	LockPauseResumeListenersListMutex();
	for (std::list<CApplicationPauseResumeListener *>::iterator itListener = pauseResumeListeners.begin();
		 itListener != pauseResumeListeners.end(); itListener++)
	{
		CApplicationPauseResumeListener *listener = *itListener;
		
		listener->ApplicationSystemSettingsUpdated(settingsData);
	}
	UnlockPauseResumeListenersListMutex();
}

byte SYS_GetApplicationState()
{
	return sysApplicationState;
}

void SYS_AddApplicationPauseResumeListener(CApplicationPauseResumeListener *callback)
{
	LockPauseResumeListenersListMutex();
	pauseResumeListeners.push_back(callback);
	UnlockPauseResumeListenersListMutex();
}

void SYS_RemoveApplicationPauseResumeListener(CApplicationPauseResumeListener *callback)
{
	LockPauseResumeListenersListMutex();
	pauseResumeListeners.remove(callback);
	UnlockPauseResumeListenersListMutex();
}

void CApplicationPauseResumeListener::ApplicationStarted()
{
}

void CApplicationPauseResumeListener::ApplicationPaused()
{
}

void CApplicationPauseResumeListener::ApplicationResumed()
{
}

void CApplicationPauseResumeListener::ApplicationEnteredBackground()
{
}

void CApplicationPauseResumeListener::ApplicationEnteredForeground()
{
}

void CApplicationPauseResumeListener::ApplicationShutdown()
{
}

void CApplicationPauseResumeListener::ApplicationSystemSettingsUpdated(void *settingsData)
{
}

void CApplicationPauseResumeListener::ApplicationOpenFiles()
{
}
