#ifndef _ATARIAUDIOCHANNEL_H_
#define _ATARIAUDIOCHANNEL_H_

#include "CAudioChannel.h"
#include "AtariDebugInterface.h"

class CAtariAudioChannel : public CAudioChannel
{
public:
	CAtariAudioChannel(AtariDebugInterface *debugInterface);
	
	AtariDebugInterface *debugInterface;
	virtual void FillBuffer(int *mixBuffer, u32 numSamples);
	
	u16 *monoBuffer;
};

#endif

