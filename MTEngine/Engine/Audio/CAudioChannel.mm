#include "CAudioChannel.h"
#include "SYS_Main.h"

#define DEFAULT_BUFFER_NUM_SAMPLES 4096

CAudioChannel::CAudioChannel()
{
	this->isActive = false;
	this->bypass = false;
	this->destroyMe = false;
	this->removeMe = false;

	sprintf(name, "");
	
	this->CreateChannelBuffer(DEFAULT_BUFFER_NUM_SAMPLES);
}

CAudioChannel::~CAudioChannel()
{

}

void CAudioChannel::CreateChannelBuffer(u32 numSamples)
{
	this->channelBuffer = new int[numSamples];
}

void CAudioChannel::Start()
{
	this->bypass = false;
}

void CAudioChannel::Stop()
{
	this->bypass = true;
}

// for backwards-compatibility reasons
void CAudioChannel::Mix(int *mixBuffer, u32 numSamples)
{
	this->FillBuffer(mixBuffer, numSamples);
}

void CAudioChannel::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	this->FillBufferFloat(mixBufferL, mixBufferR, numSamples);
}

void CAudioChannel::FillBuffer(int *mixBuffer, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::Mix");
}

void CAudioChannel::FillBufferFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::MixFloat");
}


void CAudioChannel::MixIn(int *mixBuffer, u32 numSamples, int numAudioChannels)
{
//	memset(mixBuffer, 0x00, numSamples*4);
	
	this->FillBuffer(channelBuffer, numSamples);
	
	i16 *inPtr = (i16*)channelBuffer;
	i16 *outPtr = (i16*)mixBuffer;
	for (int i = 0; i < numSamples; i++)
	{
//		mixBuffer[i] = channelBuffer[i];
		
		int sL = (int)(*inPtr++)/numAudioChannels + (int)(*outPtr);
		int sR = (int)(*inPtr++)/numAudioChannels + (int)(*(outPtr+1));
		
		*outPtr = sL; outPtr++;
		*outPtr = sR; outPtr++;
	}
}

void CAudioChannel::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CAudioChannel::MixInFloat");
}
