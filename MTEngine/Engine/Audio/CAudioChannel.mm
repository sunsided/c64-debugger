#include "CAudioChannel.h"
#include "SYS_Main.h"

CAudioChannel::CAudioChannel()
{
	this->isActive = false;
	this->bypass = false;
	this->destroyMe = false;
	this->removeMe = false;

	sprintf(name, "");
}

CAudioChannel::~CAudioChannel()
{

}

void CAudioChannel::Mix(int *mixBuffer, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::Mix");
}

void CAudioChannel::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::MixFloat");
}

void CAudioChannel::MixIn(int *mixBuffer, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::MixIn");
}

void CAudioChannel::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::MixInFloat");
}
