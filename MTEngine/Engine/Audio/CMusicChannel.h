#ifndef _COGGCHANNEL_H_
#define _COGGCHANNEL_H_

#include "CAudioChannel.h"
#include "CSlrMusicFile.h"

class CMusicChannel : public CAudioChannel
{
public:
	CMusicChannel(CSlrMusicFile *musicFile);
	~CMusicChannel();

	// overwrites buffer
	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	
	// adds to buffer
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);

	CSlrMusicFile *musicFile;
};

#endif
