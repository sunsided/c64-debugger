#include "CSlrMusicSwitcher.h"
#include "SND_SoundEngine.h"
#include "SND_Main.h"

CSlrMusicSwitcher::CSlrMusicSwitcher()
{
	currentMusic = NULL;
	prevMusic = NULL;
	fadeoutTime = 1.5f;
}

CSlrMusicSwitcher::~CSlrMusicSwitcher()
{
}

void CSlrMusicSwitcher::StopMusic()
{
	if (currentMusic)
	{
		currentMusic->Pause();
		SND_RemoveChannel(currentMusic);
		prevMusic = currentMusic;
	}

	currentMusic = NULL;
}

void CSlrMusicSwitcher::PlayMusic(CSlrMusicFile *music)
{
	LOGD("CSlrMusicSwitcher::PlayMusic: %s", music->ResourceGetPath());
	
	if (currentMusic == music)
		return;

	if (currentMusic)
	{
		currentMusic->Pause();
		SND_RemoveChannel(currentMusic);
		prevMusic = currentMusic;
	}
	
	currentMusic = music;

	if (music != NULL)
	{
		SND_AddChannel(music);
		
		gSoundEngine->LockMutex("SlrMusicSwitcher::PlayMusic");
		music->Play();
		
		gSoundEngine->UnlockMutex("SlrMusicSwitcher::PlayMusic");
	}
}
