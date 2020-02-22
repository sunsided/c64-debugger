#ifndef _CSLRMUSIC_H_
#define _CSLRMUSIC_H_

#include "SYS_Defs.h"
#include "CAudioChannel.h"
#include "CSlrResourceBase.h"

#define MUSIC_TYPE_UNKNOWN	0x00
#define MUSIC_TYPE_OGG	0x01

class CSlrMusicFile : public CAudioChannel, public CSlrResourceBase
{
public:
	byte type;
	CSlrMusicFile();
	~CSlrMusicFile();

	virtual void Play();
	virtual void Pause();
	virtual void Stop();
	virtual void Rewind();
	virtual void Seek(double second);
	virtual void Seek(u32 minute, u32 second);
	virtual u32 GetCurrentSecond();
	virtual u64 GetCurrentSampleNum();
	virtual void SeekToSample(u64 sampleNum);
	virtual void SeekToMillisecond(u64 millisecond);
	virtual u64 GetCurrentMillisecond();
	virtual u64 GetLengthSeconds();
	virtual u64 GetLengthSamples();
	
	virtual bool IsPlaying();

	// overwrites buffer
	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	
	// adds to buffer
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);

	float volume;
	
	volatile bool repeat;

	bool shouldBeDestroyedByEngine;
	bool shouldBeRemovedByEngine;

	// resource should free memory, @returns memory freed
	virtual u32 ResourceDeactivate(bool async);

	// resource should load itself, @returns memory allocated
	virtual u32 ResourceActivate(bool async);

	// get size of resource in bytes
	virtual u32 ResourceGetSize();

	virtual char *ResourceGetTypeName();
};

#endif
//_CSLRMUSIC_H_

