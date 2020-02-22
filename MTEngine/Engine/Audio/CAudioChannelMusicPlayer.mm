#include "CAudioChannelMusicPlayer.h"
#include "SND_SoundEngine.h"
#include "CContinuousParamLinear.h"
#include "SYS_Main.h"

CAudioChannelMusicPlayerPlaylistItem::CAudioChannelMusicPlayerPlaylistItem(CSlrMusicFile *music, byte playlistMode)
{
	this->music = music;
	this->playlistMode = playlistMode;
	this->originalVolume = music->volume;
};

CAudioChannelMusicPlayer::CAudioChannelMusicPlayer()
{
	currentPlaylistItem = NULL;
	fadeOutMusic = NULL;
	destroyMe = false;
	removeMe = false;
	isActive = false;
	
	isFadeIn = false;
	
	fadeOutTime = 1.0f;
	
	bufferNumSamples = 1000;
	fadeOutNumSamples = 50;
	paramFadeInVolume = new CContinuousParamLinear();
	paramFadeOutVolume = new CContinuousParamLinear();
}

CAudioChannelMusicPlayer::~CAudioChannelMusicPlayer()
{
}

// overwrites buffer
void CAudioChannelMusicPlayer::Mix(int *mixBuffer, u32 numSamples)
{
	if (!isActive)
		return;
	
	bufferNumSamples = numSamples;
	
	if (currentPlaylistItem != NULL)
	{
		if (isFadeIn)
		{
			paramFadeInVolume->DoLogic();
			currentPlaylistItem->music->volume = paramFadeInVolume->GetValue();
			if (paramFadeInVolume->IsFinished())
			{
				isFadeIn = false;
			}
		}

		currentPlaylistItem->music->Mix(mixBuffer, numSamples);
	}
	
	if (fadeOutMusic)
	{
		paramFadeOutVolume->DoLogic();
		fadeOutMusic->volume = paramFadeOutVolume->GetValue();
		fadeOutMusic->MixIn(mixBuffer, numSamples);
		
		if (paramFadeOutVolume->IsFinished())
		{
			fadeOutMusic = NULL;
		}
	}

	PlaylistTick();
}

void CAudioChannelMusicPlayer::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	bufferNumSamples = numSamples;

	if (!isActive)
		return;
	
	if (currentPlaylistItem != NULL)
	{
		if (isFadeIn)
		{
			paramFadeInVolume->DoLogic();
			currentPlaylistItem->music->volume = paramFadeInVolume->GetValue();
			if (paramFadeInVolume->IsFinished())
			{
				isFadeIn = false;
			}
		}

		currentPlaylistItem->music->MixFloat(mixBufferL, mixBufferR, numSamples);
	}

	if (fadeOutMusic)
	{
		paramFadeOutVolume->DoLogic();
		fadeOutMusic->volume = paramFadeOutVolume->GetValue();
		fadeOutMusic->MixInFloat(mixBufferL, mixBufferR, numSamples);
		if (paramFadeOutVolume->IsFinished())
		{
			fadeOutMusic = NULL;
		}
	}

	PlaylistTick();
}

// adds to buffer
void CAudioChannelMusicPlayer::MixIn(int *mixBuffer, u32 numSamples)
{
	bufferNumSamples = numSamples;

	if (!isActive)
		return;
	
	if (currentPlaylistItem != NULL)
	{
		if (isFadeIn)
		{
			paramFadeInVolume->DoLogic();
			currentPlaylistItem->music->volume = paramFadeInVolume->GetValue();
			
//			LOGD("isFadeIn, vol=%f min=%f max=%f num=%d/%d", currentPlaylistItem->music->volume,
//				 paramFadeInVolume->paramMin, paramFadeInVolume->paramMax,
//				 paramFadeInVolume->frameNum, paramFadeInVolume->numFrames);
				 
			if (paramFadeInVolume->IsFinished())
			{
				isFadeIn = false;
			}
		}

		currentPlaylistItem->music->MixIn(mixBuffer, numSamples);
	}

	if (fadeOutMusic)
	{
		paramFadeOutVolume->DoLogic();
		fadeOutMusic->volume = paramFadeOutVolume->GetValue();
		fadeOutMusic->MixIn(mixBuffer, numSamples);
		if (paramFadeOutVolume->IsFinished())
		{
			fadeOutMusic = NULL;
		}
	}

	PlaylistTick();
}

void CAudioChannelMusicPlayer::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	bufferNumSamples = numSamples;

	if (!isActive)
		return;
	
	if (currentPlaylistItem != NULL)
	{
		if (isFadeIn)
		{
			paramFadeInVolume->DoLogic();
			currentPlaylistItem->music->volume = paramFadeInVolume->GetValue();
			if (paramFadeInVolume->IsFinished())
			{
				isFadeIn = false;
			}
		}

		currentPlaylistItem->music->MixInFloat(mixBufferL, mixBufferR, numSamples);
	}
	
	if (fadeOutMusic)
	{
		paramFadeOutVolume->DoLogic();
		fadeOutMusic->volume = paramFadeOutVolume->GetValue();
		fadeOutMusic->MixInFloat(mixBufferL, mixBufferR, numSamples);
		if (paramFadeOutVolume->IsFinished())
		{
			fadeOutMusic = NULL;
		}
	}

	PlaylistTick();
}

CAudioChannelMusicPlayerPlaylistItem *CAudioChannelMusicPlayer::AddToPlaylist(CSlrMusicFile *music, byte playlistMode, byte playMode)
{
	gSoundEngine->LockMutex("CAudioChannelMusicPlayer::AddToPlaylist");

	if (currentPlaylistItem != NULL)
	{
		if (currentPlaylistItem->music == music)
		{
			gSoundEngine->UnlockMutex("CAudioChannelMusicPlayer::AddToPlaylist");
			return currentPlaylistItem;
		}
	}
	
	CAudioChannelMusicPlayerPlaylistItem *playlistItem = NULL;
	
	// search if music is already in playlist
	for (std::list<CAudioChannelMusicPlayerPlaylistItem *>::iterator it = playlist.begin(); it != playlist.end(); it++)
	{
		CAudioChannelMusicPlayerPlaylistItem *item = *it;
		if (item->music == music)
		{
			playlistItem = item;
			playlistItem->playlistMode = playlistMode;
			
			playlist.remove(playlistItem);
			break;
		}
	}
	
	if (playlistItem == NULL)
	{
		playlistItem = new CAudioChannelMusicPlayerPlaylistItem(music, playlistMode);
	}

	if (playMode == MT_MUSIC_PLAY_NOW)
	{
		playlist.push_front(playlistItem);
		this->PlaylistStep();
	}
	else if (playMode == MT_MUSIC_PLAY_LATER)
	{
		playlist.push_back(playlistItem);
	}
	
	gSoundEngine->UnlockMutex("CAudioChannelMusicPlayer::AddToPlaylist");
	
	return playlistItem;
}

void CAudioChannelMusicPlayer::PlaylistTick()
{
	if (currentPlaylistItem == NULL)
		return;
	
	if (currentPlaylistItem->music->IsPlaying() == false)
	{
		currentPlaylistItem->music->Rewind();
		this->PlaylistStep();
	}
}

void CAudioChannelMusicPlayer::PlaylistStep()
{
	gSoundEngine->LockMutex("CAudioChannelMusicPlayer::AddToPlaylist");

	CSlrMusicFile *previousMusic = NULL;
	
	if (currentPlaylistItem != NULL)
	{
		previousMusic = currentPlaylistItem->music;
		
		if (IS_SET(currentPlaylistItem->playlistMode, MT_MUSIC_KEEP_IN_LIST))
		{
			playlist.push_back(currentPlaylistItem);
		}
		else
		{
			currentPlaylistItem->music->Rewind();
			currentPlaylistItem->music->volume = currentPlaylistItem->originalVolume;
			delete currentPlaylistItem;
			currentPlaylistItem = NULL;
		}
	}

	if (playlist.empty())
	{
		gSoundEngine->UnlockMutex("CAudioChannelMusicPlayer::AddToPlaylist");
		return;
	}
	
	// pick next playlist item
	currentPlaylistItem = playlist.front();
	playlist.pop_front();
	
	if (currentPlaylistItem->music != previousMusic)
	{
		if (IS_SET(currentPlaylistItem->playlistMode, MT_MUSIC_FADEOUT_CURRENT))
		{
			fadeOutMusic = previousMusic;
			
			float numBuffersPerSecond = (float)SOUND_SAMPLE_RATE / (float)bufferNumSamples;
			fadeOutNumSamples = (int)(numBuffersPerSecond * fadeOutTime);
			
			paramFadeOutVolume->Reset(previousMusic->volume, 0.0f, fadeOutNumSamples);
		}
	}
	
	if (IS_SET(currentPlaylistItem->playlistMode, MT_MUSIC_FADEIN_CURRENT))
	{
		isFadeIn = true;
		
		float numBuffersPerSecond = (float)SOUND_SAMPLE_RATE / (float)bufferNumSamples;
		
		//LOGD("bufferNumSamples=%d numBuffersPerSecond=%f", bufferNumSamples, numBuffersPerSecond);
		
		fadeOutNumSamples = (int)(numBuffersPerSecond * fadeOutTime);
		
		//LOGD("fadeOutNumSamples=%d", fadeOutNumSamples);
		
		if (fadeOutMusic == currentPlaylistItem->music)
		{
			paramFadeInVolume->Reset(currentPlaylistItem->music->volume, currentPlaylistItem->originalVolume, fadeOutNumSamples);
		}
		else
		{
			paramFadeInVolume->Reset(0.0f, currentPlaylistItem->originalVolume, fadeOutNumSamples);
		}
	}
	else
	{
		isFadeIn = false;
		currentPlaylistItem->music->volume = currentPlaylistItem->originalVolume;
	}

	if (currentPlaylistItem->music == fadeOutMusic)
	{
		fadeOutMusic = NULL;
	}
	
	// TODO: fade in?
	currentPlaylistItem->music->volume = currentPlaylistItem->originalVolume;
	
	gSoundEngine->UnlockMutex("CAudioChannelMusicPlayer::AddToPlaylist");
}

void CAudioChannelMusicPlayer::Play()
{
	if (this->isActive)
		return;
	
	PlaylistStep();
	isActive = true;
}

void CAudioChannelMusicPlayer::Pause()
{
	isActive = false;
}

