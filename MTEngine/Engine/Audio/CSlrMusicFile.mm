#include "CSlrMusicFile.h"
#include "SYS_Main.h"

CSlrMusicFile::CSlrMusicFile()
: CAudioChannel()
{
	this->resourceType = RESOURCE_TYPE_MUSIC;
	this->type = MUSIC_TYPE_UNKNOWN;
	this->bypass = false;
	this->volume = 1.0f;
	this->shouldBeDestroyedByEngine = false;
	this->shouldBeRemovedByEngine = false;
	this->repeat = false;

	this->resourcePriority = RESOURCE_PRIORITY_STATIC;
}

CSlrMusicFile::~CSlrMusicFile()
{

}

void CSlrMusicFile::Play()
{
	SYS_FatalExit("abstract CSlrMusicFile::Play");
}

void CSlrMusicFile::Pause()
{
	SYS_FatalExit("abstract CSlrMusicFile::Pause");
}

void CSlrMusicFile::Stop()
{
	SYS_FatalExit("abstract CSlrMusicFile::Stop");
}

void CSlrMusicFile::Rewind()
{
	SYS_FatalExit("abstract CSlrMusicFile::Rewind");
}

void CSlrMusicFile::Seek(double second)
{
	SYS_FatalExit("abstract CSlrMusicFile::Seek");
}

void CSlrMusicFile::Seek(u32 minute, u32 second)
{
	SYS_FatalExit("abstract CSlrMusicFile::Seek2");
}

u32 CSlrMusicFile::GetCurrentSecond()
{
	SYS_FatalExit("abstract CSlrMusicFile::GetCurrentSecond");
	return 0;
}

u64 CSlrMusicFile::GetCurrentSampleNum()
{
	SYS_FatalExit("abstract CSlrMusicFile::GetCurrentSampleNum");
	return 0;
}

void CSlrMusicFile::SeekToSample(u64 sampleNum)
{
	SYS_FatalExit("abstract CSlrMusicFile::SeekToSample");
}

void CSlrMusicFile::SeekToMillisecond(u64 millisecond)
{
	SYS_FatalExit("abstract CSlrMusicFile::SeekToMillisecond");
}

u64 CSlrMusicFile::GetCurrentMillisecond()
{
	SYS_FatalExit("abstract CSlrMusicFile::GetCurrentMillisecond");
	return 0;
}

u64 CSlrMusicFile::GetLengthSeconds()
{
	SYS_FatalExit("abstract CSlrMusicFile::GetLengthSeconds");
	return 0;
	
}

u64 CSlrMusicFile::GetLengthSamples()
{
	SYS_FatalExit("abstract CSlrMusicFile::GetLengthSamples");
	return 0;
	
}


bool CSlrMusicFile::IsPlaying()
{
	SYS_FatalExit("abstract CSlrMusicFile::IsPlaying");
	return 0;
}

void CSlrMusicFile::Mix(int *mixBuffer, u32 numSamples)
{
	SYS_FatalExit("abstract CSlrMusicFile::Mix");
}

void CSlrMusicFile::MixIn(int *mixBuffer, u32 numSamples)
{
	SYS_FatalExit("abstract CSlrMusicFile::Mix");
}

void CSlrMusicFile::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CSlrMusicFile::MixFloat");
}

void CSlrMusicFile::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	SYS_FatalExit("abstract CSlrMusicFile::MixInFloat");
}

// resource should free memory, @returns memory freed
u32 CSlrMusicFile::ResourceDeactivate(bool async)
{
	SYS_FatalExit("abstract CSlrMusicFile::ResourceDeactivate");
	return 0;
}

// resource should load itself, @returns memory allocated
u32 CSlrMusicFile::ResourceActivate(bool async)
{
	SYS_FatalExit("abstract CSlrMusicFile::ResourceActivate");
	return 0;
}

// get size of resource in bytes
u32 CSlrMusicFile::ResourceGetSize()
{
	SYS_FatalExit("abstract CSlrMusicFile::ResourceGetSize");
	return 0;
}

char *CSlrMusicFile::ResourceGetTypeName()
{
	return "music";
}

