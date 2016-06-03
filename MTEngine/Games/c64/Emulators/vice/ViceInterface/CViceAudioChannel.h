#ifndef _VICEAUDIOCHANNEL_H_
#define _VICEAUDIOCHANNEL_H_

#include "CAudioChannel.h"
#include "C64DebugInterfaceVice.h"

class CViceAudioChannel : public CAudioChannel
{
public:
	CViceAudioChannel(C64DebugInterfaceVice *debugInterface);
	
	C64DebugInterfaceVice *debugInterface;
	virtual void MixIn(int *mixBuffer, u32 numSamples);
};

#endif

