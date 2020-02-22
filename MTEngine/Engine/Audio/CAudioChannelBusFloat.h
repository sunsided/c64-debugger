#ifndef _CAUDIOCHANNELBUSFLOAT_H_
#define _CAUDIOCHANNELBUSFLOAT_H_

#include "SYS_Defs.h"

#include "CAudioChannel.h"
#include "CSlrMusicFileOgg.h"
#include "CSlrFileMemory.h"
#include <list>

class CAudioChannelBusFloat : public CAudioChannel
{
public:
	CAudioChannelBusFloat(u16 numChannels);
	~CAudioChannelBusFloat();

	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);

	u16 numChannels;
	std::list<CAudioChannel *> audioChannelsDynamic;
	CSlrMusicFileOgg **oggAudioChannelsPool;
	CSlrFileMemory **oggAudioFilesPool;
		
	void PlaySound(CSlrFileMemory *file);
	void PlaySound(CSlrFileMemory *file, float volume);
	
	u32 fMixBufferSize;
	u32 fMixBufferSizeBytes;
	float *fMixBufferL;
	float *fMixBufferR;

	void AddChannel(CAudioChannel *channel);
	void RemoveChannel(CAudioChannel *channel);
	
private:
	void PreMixFloat(u32 numSamples);
};

#endif
