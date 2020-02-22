#include "CMusicChannel.h"
#include "SYS_Main.h"

CMusicChannel::CMusicChannel(CSlrMusicFile *musicFile)
{
	LOGA("CMusicChannel::CMusicChannel");
	this->musicFile = musicFile;
	this->bypass = false;
}

CMusicChannel::~CMusicChannel()
{

}

void CMusicChannel::Mix(int *mixBuffer, u32 numSamples)
{
	LOGA("CMusicChannel::Mix");
	// musicFile is CAudioChannel too
	this->musicFile->Mix(mixBuffer, numSamples);
}

void CMusicChannel::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	LOGA("CMusicChannel::Mix");
	// musicFile is CAudioChannel too
	this->musicFile->MixFloat(mixBufferL, mixBufferR, numSamples);
}

void CMusicChannel::MixIn(int *mixBuffer, u32 numSamples)
{
	LOGA("CMusicChannel::Mix");
	// musicFile is CAudioChannel too
	this->musicFile->MixIn(mixBuffer, numSamples);
}

void CMusicChannel::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	this->musicFile->MixFloat(mixBufferL, mixBufferR, numSamples);
}
