#ifndef _CAUDIOCHANNELMUSICPLAYER_H_
#define _CAUDIOCHANNELMUSICPLAYER_H_

#include "SYS_Defs.h"
#include "CAudioChannel.h"
#include "CSlrMusicFile.h"
#include <list>

#define MT_MUSIC_KEEP_IN_LIST			BV01
#define MT_MUSIC_REMOVE_WHEN_FINISHED	BV02
#define MT_MUSIC_FADEIN_CURRENT			BV03
#define MT_MUSIC_FADEOUT_CURRENT		BV04
#define MT_MUSIC_FADEIN_NEXT			BV05

#define MT_MUSIC_PLAY_NOW				BV01
#define MT_MUSIC_PLAY_LATER				BV02

class CContinuousParam;

class CAudioChannelMusicPlayerPlaylistItem
{
public:
	CAudioChannelMusicPlayerPlaylistItem(CSlrMusicFile *music, byte playlistMode);
	CSlrMusicFile *music;
	byte playlistMode;
	float originalVolume;
};

class CAudioChannelMusicPlayer : public CAudioChannel
{
public:
	CAudioChannelMusicPlayer();
	~CAudioChannelMusicPlayer();
	
	// overwrites buffer
	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	
	// adds to buffer
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);

	CAudioChannelMusicPlayerPlaylistItem *currentPlaylistItem;
	std::list<CAudioChannelMusicPlayerPlaylistItem *> playlist;
	
	void Play();
	void Pause();
	CAudioChannelMusicPlayerPlaylistItem *AddToPlaylist(CSlrMusicFile *music, byte playlistMode, byte playMode);
	void PlaylistTick();
	void PlaylistStep();
	
	CSlrMusicFile *fadeOutMusic;
	bool isFadeIn;
	CContinuousParam *paramFadeInVolume;
	CContinuousParam *paramFadeOutVolume;
	
	float fadeOutTime;

	int fadeOutNumSamples;
	u32 bufferNumSamples;
};

#endif
