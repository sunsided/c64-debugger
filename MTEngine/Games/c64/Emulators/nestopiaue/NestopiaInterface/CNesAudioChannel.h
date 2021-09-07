#ifndef _NESAUDIOCHANNEL_H_
#define _NESAUDIOCHANNEL_H_

#include "CAudioChannel.h"
#include "NesDebugInterface.h"

class CNesAudioChannel : public CAudioChannel
{
public:
	CNesAudioChannel(NesDebugInterface *debugInterface);
	
	NesDebugInterface *debugInterface;
	virtual void FillBuffer(int *mixBuffer, u32 numSamples);
	
	i16 *monoBuffer;
};

#endif

