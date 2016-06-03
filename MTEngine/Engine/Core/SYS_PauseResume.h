#ifndef _SYS_PAUSERESUME_H_
#define _SYS_PAUSERESUME_H_

#include "SYS_Defs.h"
#include <list>
class CSlrString;

#define APPLICATION_STATE_UNKNOWN	0
#define APPLICATION_STATE_INIT		1
#define APPLICATION_STATE_RUNNING	2
#define APPLICATION_STATE_PAUSED	3
#define APPLICATION_STATE_BACKGROUND	4
#define APPLICATION_STATE_SHUTDOWN	5

class CApplicationPauseResumeListener
{
public:
	virtual void ApplicationStarted();
	virtual void ApplicationPaused();
	virtual void ApplicationResumed();
	virtual void ApplicationEnteredBackground();
	virtual void ApplicationEnteredForeground();
	
	// system depended settings object (iPhone=NSUserDefaults)
	virtual void ApplicationSystemSettingsUpdated(void *settingsData);
	
	// when received should call SYS_ApplicationGetListOfFilesToOpen
	virtual void ApplicationOpenFiles();
	
	virtual void ApplicationShutdown();
};

void SYS_InitApplicationPauseResume();
void SYS_ApplicationStarted();
void SYS_ApplicationPaused();
void SYS_ApplicationResumed();
void SYS_ApplicationEnteredBackground();
void SYS_ApplicationEnteredForeground();
void SYS_ApplicationSystemSettingsUpdated(void *settingsData);

// user opened a file and selected our app to insert it
void SYS_ApplicationOpenFile();

void SYS_ApplicationShutdown();

void SYS_AddApplicationPauseResumeListener(CApplicationPauseResumeListener *callback);
void SYS_RemoveApplicationPauseResumeListener(CApplicationPauseResumeListener *callback);

void SYS_ApplicationAddOpenFileAtStartup(CSlrString *filePath);
std::list<CSlrString *> *SYS_ApplicationGetListOfFilesToOpen();

// this is not synced!
bool SYS_ApplicationAreFilesToOpenAvailable();

byte SYS_GetApplicationState();

#endif
