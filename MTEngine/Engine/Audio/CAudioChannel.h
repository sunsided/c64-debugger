#ifndef _CAUDIOCHANNEL_H_
#define _CAUDIOCHANNEL_H_

#include "SYS_Defs.h"

class CAudioChannel
{
public:
	CAudioChannel();
	~CAudioChannel();

	char name[32];


	bool isActive;
	bool removeMe;	// audio channel should be removed by engine immediately
	bool destroyMe;	// audio channel should be destroyed by engine immediately
	bool bypass;
	
	// overwrites buffer
	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	
	// adds to buffer
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
};

#endif
