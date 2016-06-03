#ifndef _MUSICSWITCHER_H_
#define _MUSICSWITCHER_H_

#include "SYS_Defs.h"
#include "CSlrMusicFile.h"
#include "MTH_MTRand.h"
#include "CGlobalLogicCallback.h"
#include <vector>

//class CSlrMusicPlayerCallback;

class CContinuousParam;

class CSlrMusicSwitcher : public CGlobalLogicCallback
{
public:
	CSlrMusicSwitcher();	//CSlrMusicPlayerCallback *callback
	~CSlrMusicSwitcher();

	CSlrMusicFile *prevMusic;
	CSlrMusicFile *currentMusic;

	void StopMusic();
	//void FadeOutMusic();
	void PlayMusic(CSlrMusicFile *music);

	float fadeoutTime;
	CContinuousParam *fadeParam;
	
	
};


#endif

//_MUSICSWITCHER_H_

