#ifndef _CSLRMUSICOGG_H_
#define _CSLRMUSICOGG_H_

#include "CSlrMusicFile.h"
#include "CSlrFile.h"
#include "ivorbiscodec.h"
#include "ivorbisfile.h"

class CSlrMutex;

class CSlrMusicFileOgg : public CSlrMusicFile
{
public:
	CSlrMusicFileOgg();
	CSlrMusicFileOgg(char *fileName, bool seekable, bool fromResources);
	CSlrMusicFileOgg(CSlrFile *file, bool seekable);
	~CSlrMusicFileOgg();

	bool Init(char *fileName, bool seekable, bool fromResources);
	bool Init(CSlrFile *file, bool seekable);
	
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
	virtual bool IsPlaying();

	virtual u64 GetLengthSeconds();
	virtual u64 GetLengthSamples();

	CSlrFile *oggFileHandle;
	OggVorbis_File *oggVorbisData;

	virtual void Mix(int *mixBuffer, u32 numSamples);
	virtual void MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);
	virtual void MixIn(int *mixBuffer, u32 numSamples);
	virtual void MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples);

	void OggMix(u32 numSamples);

	volatile bool isPlaying;

	void LockMutex();
	void UnlockMutex();

	void DeleteVorbisData();
	
	// resource should free memory, @returns memory freed
	virtual u32 ResourceDeactivate(bool async);

	// resource should load itself, @returns memory allocated
	virtual u32 ResourceActivate(bool async);

	// get size of resource in bytes
	virtual u32 ResourceGetSize();

private:
	int *oggAudioBuffer; //= NULL;
	int *oggMixBuffer;// = NULL;
	int oggAudioBufferPos;// = 0;
	int oggAudioBufferLen;// = 0;

	CSlrMutex *oggFileMutex;
};

#endif
