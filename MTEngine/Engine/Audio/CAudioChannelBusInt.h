#ifndef _CAUDIOCHANNELBUSINT_H_
#define _CAUDIOCHANNELBUSINT_H_

#include "SYS_Defs.h"

#include "CAudioChannel.h"
#include "CSlrMusicFileOgg.h"
#include "CSlrFileMemory.h"

// short int bus
class CAudioChannelBusInt : public CAudioChannel
{
public:
	CAudioChannelBusInt(u16 numChannels);
	~CAudioChannelBusInt();

	virtual void Mix(int *mixBuffer, u32 numSamples);

	u16 numChannels;
	CSlrMusicFileOgg **oggAudioChannelsPool;
	CSlrFileMemory **oggAudioFilesPool;

	void PlaySound(CSlrFileMemory *file);
	void PlaySound(CSlrFileMemory *file, float volume);
};

#endif
