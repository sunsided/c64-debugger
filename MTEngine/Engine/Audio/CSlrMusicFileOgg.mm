#include "CSlrMusicFileOgg.h"
#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CSlrFileFromDocuments.h"
#include "CSlrFileFromResources.h"
#include "SND_SoundEngine.h"


size_t _mt_OggReadFunct(void *ptr, size_t size, size_t nmemb, void *datasource)
{
	//LOGD("OggRead: size=%d nmemb=%d", size, nmemb);
	CSlrFile *file = (CSlrFile *)datasource;
	return file->Read((byte*)ptr, size*nmemb);
}

int _mt_OggSeekFunct (void *datasource, ogg_int64_t offset, int whence)
{
	//LOGD("OggSeek: offset=%d", offset);
	CSlrFile *file = (CSlrFile *)datasource;
	return file->Seek(offset, whence);
}

int _mt_OggCloseFunct (void *datasource)
{
	CSlrFile *file = (CSlrFile *)datasource;
	file->Close();
	return 0;
}

long _mt_OggTellFunct (void *datasource)
{
	LOGD("OggTell");
	CSlrFile *file = (CSlrFile *)datasource;
	return file->Tell();
}

/*
typedef struct {
  size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
  int    (*seek_func)  (void *datasource, ogg_int64_t offset, int whence);
  int    (*close_func) (void *datasource);
  long   (*tell_func)  (void *datasource);
} ov_callbacks;
 */
static ov_callbacks OV_CALLBACKS_MTENGINE_SEEKABLE =
{
	(size_t (*)(void *, size_t, size_t, void *))  _mt_OggReadFunct,
	(int (*)(void *, ogg_int64_t, int))           _mt_OggSeekFunct,
	(int (*)(void *))                             _mt_OggCloseFunct,
	(long (*)(void *))                            _mt_OggTellFunct
};

static ov_callbacks OV_CALLBACKS_MTENGINE_NOT_SEEKABLE =
{
	(size_t (*)(void *, size_t, size_t, void *))  _mt_OggReadFunct,
	(int (*)(void *, ogg_int64_t, int))           NULL,
	(int (*)(void *))                             _mt_OggCloseFunct,
	(long (*)(void *))                            _mt_OggTellFunct
};


CSlrMusicFileOgg::CSlrMusicFileOgg()
: CSlrMusicFile()
{
	this->type = MUSIC_TYPE_OGG;
	pthread_mutex_init(&oggFileMutex, NULL);

	oggMixBuffer = new int[SOUND_BUFFER_SIZE];
	oggAudioBuffer = new int[SOUND_BUFFER_SIZE];

	oggVorbisData = NULL;

	this->resourcePriority = RESOURCE_PRIORITY_STATIC;

	sprintf(name, "music ogg");
}

CSlrMusicFileOgg::CSlrMusicFileOgg(char *fileName, bool seekable, bool fromResources)
: CSlrMusicFile()
{
	this->type = MUSIC_TYPE_OGG;
	pthread_mutex_init(&oggFileMutex, NULL);

	oggMixBuffer = new int[SOUND_BUFFER_SIZE];
	oggAudioBuffer = new int[SOUND_BUFFER_SIZE];

	oggVorbisData = NULL;

	if (this->Init(fileName, seekable, fromResources) == false)
		SYS_FatalExit("CSlrMusicFileOgg: unable to init ogg");

	this->resourcePriority = RESOURCE_PRIORITY_STATIC;
}

CSlrMusicFileOgg::CSlrMusicFileOgg(CSlrFile *file, bool seekable)
: CSlrMusicFile()
{
	this->type = MUSIC_TYPE_OGG;
	pthread_mutex_init(&oggFileMutex, NULL);
	
	oggMixBuffer = new int[SOUND_BUFFER_SIZE];
	oggAudioBuffer = new int[SOUND_BUFFER_SIZE];
	
	oggVorbisData = NULL;
	
	if (this->Init(file, seekable) == false)
		SYS_FatalExit("CSlrMusicFileOgg: unable to init ogg");
	
	this->resourcePriority = RESOURCE_PRIORITY_STATIC;
}

bool CSlrMusicFileOgg::Init(char *fileName, bool seekable, bool fromResources)
{
	ResourceSetPath(fileName, fromResources);

	CSlrFile *file = RES_OpenFile(fromResources, fileName, DEPLOY_FILE_TYPE_OGG);
	bool ret = this->Init(file, seekable);
	if (ret == false && fromResources == true)
	{
		SYS_FatalExit("CSlrMusicFileOgg::Init: input does not appear to be an Ogg bitstream (fromResources=true)");
	}
	return ret;
}

bool CSlrMusicFileOgg::Init(CSlrFile *file, bool seekable)
{
	this->LockMutex();

	this->oggFileHandle = file;

	this->bypass = false;

	oggAudioBufferPos = SOUND_BUFFER_SIZE;
	oggAudioBufferLen = 0;

	isPlaying = false;

	DeleteVorbisData();
	this->oggVorbisData = (OggVorbis_File *) malloc(sizeof(OggVorbis_File));

	int ret;
	if (seekable)
	{
		//LOGD("seekable");
		ret = ov_open_callbacks(this->oggFileHandle, oggVorbisData, NULL, 0, OV_CALLBACKS_MTENGINE_SEEKABLE);
	}
	else
	{
		ret = ov_open_callbacks(this->oggFileHandle, oggVorbisData, NULL, 0, OV_CALLBACKS_MTENGINE_NOT_SEEKABLE);
	}

	this->UnlockMutex();

	if (ret < 0)
	{
		LOGError("CSlrMusicFileOgg::Init: input does not appear to be an Ogg bitstream");
		return false;
	}

	return true;
}

void CSlrMusicFileOgg::DeleteVorbisData()
{
	ov_clear(oggVorbisData);
	free(oggVorbisData);
	oggVorbisData = NULL;
}

CSlrMusicFileOgg::~CSlrMusicFileOgg()
{
	SYS_FatalExit("CSlrMusicFileOgg::~CSlrMusicFileOgg: %s", this->ResourceGetPath());

	if (this->oggFileHandle != NULL)
		delete this->oggFileHandle;

	DeleteVorbisData();
}

void CSlrMusicFileOgg::Play()
{
	LOGA("CSlrMusicFileOgg::Play()");
	isPlaying = true;
	isActive = true;
}

void CSlrMusicFileOgg::Pause()
{
	LOGA("CSlrMusicFileOgg::Pause()");
	isPlaying = false;
	isActive = false;
}

void CSlrMusicFileOgg::Stop()
{
	LOGA("CSlrMusicFileOgg::Stop()");
	isPlaying = false;
	isActive = false;
}

void CSlrMusicFileOgg::Rewind()
{
	this->Seek(0.0);
}

void CSlrMusicFileOgg::Seek(double second)
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::Seek");
	this->LockMutex();
	//LOGA("CSlrMusicFileOgg::Seek: %f", second);

	double sampleRate = (double)SOUND_SAMPLE_RATE;
	double val = sampleRate * second;

	u64 val64 = (u64)val;

	int ret = ov_pcm_seek(oggVorbisData, val64);
	if (ret == 0)
	{
		//LOGA("Seek OK");
	}
	else if (ret == OV_ENOSEEK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Bitstream is not seekable.");
	}
	else if (ret == OV_EINVAL)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.");
	}
	/*
	undefined
	else if (ret === OV_EREAD)
	{
		LOGError("CSlrMusicFileOgg::Seek: A read from media returned an error.");
	}
	*/
	else if (ret == OV_EFAULT)
	{
		LOGError("CSlrMusicFileOgg::Seek: Internal logic fault; indicates a bug or heap/stack corruption.");
	}
	else if (ret == OV_EBADLINK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.");
	}
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::Seek");
}

void CSlrMusicFileOgg::Seek(u32 minute, u32 second)
{
	double t = (double)minute*60 + (double)second;
	this->Seek(t);
}

u64 CSlrMusicFileOgg::GetCurrentSampleNum()
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::GetCurrentSampleNum");
	this->LockMutex();
	//LOGA("CSlrMusicFileOgg::GetCurrentSampleNum");

	u64 ret = ov_pcm_tell(oggVorbisData);

	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::GetCurrentSampleNum");
	
	return ret;
}

void CSlrMusicFileOgg::SeekToSample(u64 sampleNum)
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::SeekToSample");
	this->LockMutex();
	//LOGA("CSlrMusicFileOgg::Seek: %f", second);
	
	int ret = ov_pcm_seek(oggVorbisData, sampleNum);
	if (ret == 0)
	{
		//LOGA("Seek OK");
	}
	else if (ret == OV_ENOSEEK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Bitstream is not seekable.");
	}
	else if (ret == OV_EINVAL)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.");
	}
	/*
	 undefined
	 else if (ret === OV_EREAD)
	 {
	 LOGError("CSlrMusicFileOgg::Seek: A read from media returned an error.");
	 }
	 */
	else if (ret == OV_EFAULT)
	{
		LOGError("CSlrMusicFileOgg::Seek: Internal logic fault; indicates a bug or heap/stack corruption.");
	}
	else if (ret == OV_EBADLINK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.");
	}
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::Seek");
}

void CSlrMusicFileOgg::SeekToMillisecond(u64 millisecond)
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::SeekToMillisecond");
	this->LockMutex();
	//LOGD("CSlrMusicFileOgg::Seek: %d", millisecond);
	
	int ret = ov_time_seek(oggVorbisData, millisecond);
	if (ret == 0)
	{
		//LOGA("Seek OK");
	}
	else if (ret == OV_ENOSEEK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Bitstream is not seekable.");
	}
	else if (ret == OV_EINVAL)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid argument value; possibly called with an OggVorbis_File structure that isn't open.");
	}
	/*
	 undefined
	 else if (ret === OV_EREAD)
	 {
	 LOGError("CSlrMusicFileOgg::Seek: A read from media returned an error.");
	 }
	 */
	else if (ret == OV_EFAULT)
	{
		LOGError("CSlrMusicFileOgg::Seek: Internal logic fault; indicates a bug or heap/stack corruption.");
	}
	else if (ret == OV_EBADLINK)
	{
		LOGError("CSlrMusicFileOgg::Seek: Invalid stream section supplied to libvorbisfile, or the requested link is corrupt.");
	}
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::Seek");
}

u64 CSlrMusicFileOgg::GetLengthSeconds()
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::SeekToMillisecond");
	this->LockMutex();
	//LOGD("CSlrMusicFileOgg::Seek: %d", millisecond);
	
	u64 len = ov_raw_total(oggVorbisData, -1);
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::Seek");
	
	return len;
}

u64 CSlrMusicFileOgg::GetLengthSamples()
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::SeekToMillisecond");
	this->LockMutex();
	//LOGD("CSlrMusicFileOgg::Seek: %d", millisecond);
	
	u64 len = ov_raw_total(oggVorbisData, -1);
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::Seek");
	
	return len;
}


u64 CSlrMusicFileOgg::GetCurrentMillisecond()
{
	gSoundEngine->LockMutex("CSlrMusicFileOgg::GetCurrentMillisecond");
	this->LockMutex();
	//LOGA("CSlrMusicFileOgg::GetCurrentSampleNum");
	
	u64 ret = ov_time_tell(oggVorbisData);
	
	this->UnlockMutex();
	gSoundEngine->UnlockMutex("CSlrMusicFileOgg::GetCurrentMillisecond");
	
	return ret;
}


u32 CSlrMusicFileOgg::GetCurrentSecond()
{
	SYS_FatalExit("CSlrMusicFileOgg::GetCurrentSecond");
	return 0;
}

bool CSlrMusicFileOgg::IsPlaying()
{
	return this->isPlaying;
}

/*void checkZero(int *mixBuffer, char *when)
{
	byte *buf = (byte*)mixBuffer;
	for (int i = 0; i < len; i++)
	{
		if (buf[i] != 0x00)
		{
			LOGError("when= %s");
			LOGError("buf[%d] == %2.2x", i, buf[i]);
			SYS_FatalExit("not zeroed");
		}
	}
}
*/

void CSlrMusicFileOgg::OggMix(u32 numSamples)
{
	// mixin ogg
	u32 samplePos = 0;
	u32 len = numSamples*4;

//	memset((byte *) oggMixBuffer, 0x00, len);
//	for (u32 i = 0; i < numSamples; i++)
//	{
//		oggMixBuffer[i] = (i % 50)+200;
//	}
//	return;

	//checkZero(mixBuffer, "enter");

	while (samplePos < numSamples)
	{
		if (oggAudioBufferPos >= oggAudioBufferLen)
		{
			// render one buffer
			//pthread_mutex_lock(&gSoundEngine->oggPlayerMutex);
			//LOGD("ogg render");

			if (oggVorbisData == NULL || !this->isPlaying)
			{
				memset((byte *) oggMixBuffer, 0x00, len);
				oggAudioBufferPos = SOUND_BUFFER_SIZE;
				//pthread_mutex_unlock(&gSoundEngine->oggPlayerMutex);

				if (shouldBeDestroyedByEngine)
					this->destroyMe = true;
				
				if (shouldBeRemovedByEngine)
					this->removeMe = true;

				this->isActive = false;

				break;
			}

			int currentSection;
			this->LockMutex();
			oggAudioBufferLen = ov_read(oggVorbisData,
					(char*) oggAudioBuffer, SOUND_BUFFER_SIZE, &currentSection);
			this->UnlockMutex();

			if (oggAudioBufferLen == 0)
			{
				if (repeat)
				{
					this->Rewind();
				}
				else
				{
					this->isPlaying = false;
					memset((byte *) oggMixBuffer, 0x00, len);
					oggAudioBufferPos = SOUND_BUFFER_SIZE;

					if (shouldBeDestroyedByEngine)
						this->destroyMe = true;

					this->isActive = false;
				}

				break;
			}

			oggAudioBufferLen /= 4;
			//pthread_mutex_unlock(&gSoundEngine->oggPlayerMutex);

			//LOGD("oggAudioBufferLen=%d", oggAudioBufferLen);
			if (oggAudioBufferLen >= SOUND_BUFFER_SIZE)
			{
				LOGError("ogg player buffer overflow");
			}
			else if (oggAudioBufferLen + samplePos < numSamples)
			{
				memcpy(oggMixBuffer + samplePos, oggAudioBuffer,
						oggAudioBufferLen * sizeof(int));
				samplePos += oggAudioBufferLen;
				oggAudioBufferPos = oggAudioBufferLen;
			}
			else if (oggAudioBufferLen + samplePos >= numSamples)
			{
				int lenLeft = numSamples - samplePos;
				memcpy(oggMixBuffer + samplePos, oggAudioBuffer,
						lenLeft * sizeof(int));
				oggAudioBufferPos = lenLeft;
				samplePos += lenLeft;
			}
		}
		else
		{
			int oggLenLeft = oggAudioBufferLen - oggAudioBufferPos;

			if (samplePos + oggLenLeft >= numSamples)
			{
				int lenLeft = numSamples - samplePos;
				memcpy(oggMixBuffer + samplePos,
						oggAudioBuffer + oggAudioBufferPos,
						lenLeft * sizeof(int));
				samplePos += lenLeft;
				oggAudioBufferPos += lenLeft;
			}
			else if (samplePos + oggLenLeft < numSamples)
			{
				memcpy(oggMixBuffer + samplePos,
						oggAudioBuffer + oggAudioBufferPos,
						oggLenLeft * sizeof(int));
				samplePos += oggLenLeft;
				oggAudioBufferPos += oggLenLeft;
			}
		}
	}
}

void CSlrMusicFileOgg::Mix(int *mixBuffer, u32 numSamples)
{
	this->OggMix(numSamples);

	//static int pass = 0;

	u32 j = 0;

	//memset((byte *) mixBuffer, 0x00, len);
	//LOGD("len=%d", len);

	signed short *outBuf = (signed short *)mixBuffer;
	signed short *inBuf = (signed short *)oggMixBuffer;

	if (volume == 1.0f)
	{
		//LOGD("pass=%d numSamples=%d", pass, numSamples);
		for (u32 i = 0; i < numSamples; i++)
		{
			//if (pass > 995)
				//LOGD("L : outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			outBuf[j] = inBuf[j];

	//		if (pass > 995)
				//LOGD("L+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;

			outBuf[j] = inBuf[j];
				//LOGD("R+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;
		}
	}
	else
	{
		//LOGD("pass=%d numSamples=%d volume=%f", pass, numSamples, volume);
		for (u32 i = 0; i < numSamples; i++)
		{
			//if (pass > 995)
				//LOGD("L : outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			outBuf[j] = (signed short)((signed short)((float)inBuf[j] * volume));

	//		if (pass > 995)
				//LOGD("L+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;

			outBuf[j] = (signed short)((signed short)((float)inBuf[j] * volume));
				//LOGD("R+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);

			j++;
		}
	}
	
	//LOGD("done");
	//if (pass == 1000)
		//SYS_FatalExit("DONE");
}

void CSlrMusicFileOgg::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	this->OggMix(numSamples);

	signed short *inBuf = (signed short *)oggMixBuffer;

	float *pMixBufferL = mixBufferL;
	float *pMixBufferR = mixBufferR;
	{
		for (u32 i = 0; i < numSamples; i++)
		{
			*pMixBufferL = ( ((float) (*inBuf)) / 32767.0f ) * volume;
			inBuf++;
			pMixBufferL++;
			*pMixBufferR = ( ((float) (*inBuf)) / 32767.0f ) * volume;
			inBuf++;
			pMixBufferR++;
		}
	}

	LOGD("------ CSlrMusicFileOgg::MixFloat %d samples -------", numSamples);
//	u32 j = 0;
//	inBuf = (signed short *)oggMixBuffer;
//
//	pMixBufferL = mixBufferL;
//	pMixBufferR = mixBufferR;
//	for (u32 i = 0; i < numSamples; i++)
//	{
//		LOGD("--i=%d", i);
//		LOGD("inBuf[%d]=%d pMixBufferL[%d]=%f", j, inBuf[j], i, pMixBufferL[i]);
//		j++;
//		LOGD("inBuf[%d]=%d pMixBufferR[%d]=%f", j, inBuf[j], i, pMixBufferR[i]);
//		j++;
//	}
	
//	LOGD("done");
}

void CSlrMusicFileOgg::MixIn(int *mixBuffer, u32 numSamples)
{
	this->OggMix(numSamples);

	//static int pass = 0;

	u32 j = 0;

	//memset((byte *) mixBuffer, 0x00, len);
	//LOGD("len=%d", len);

	signed short *outBuf = (signed short *)mixBuffer;
	signed short *inBuf = (signed short *)oggMixBuffer;

	if (volume == 1.0f)
	{
		//LOGD("pass=%d numSamples=%d", pass, numSamples);
		for (u32 i = 0; i < numSamples; i++)
		{
			//if (pass > 995)
				//LOGD("L : outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			outBuf[j] = outBuf[j] + inBuf[j];

	//		if (pass > 995)
				//LOGD("L+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;

			outBuf[j] = outBuf[j] + inBuf[j];
				//LOGD("R+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;
		}
	}
	else
	{
		//LOGD("pass=%d numSamples=%d volume=%f", pass, numSamples, volume);
		for (u32 i = 0; i < numSamples; i++)
		{
			//if (pass > 995)
				//LOGD("L : outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			outBuf[j] = outBuf[j] + (signed short)((signed short)((float)inBuf[j] * volume));

	//		if (pass > 995)
				//LOGD("L+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);
			j++;

			outBuf[j] = outBuf[j] + (signed short)((signed short)((float)inBuf[j] * volume));
				//LOGD("R+: outBuf[%d] = %d inBuf[%d] = %d", j, outBuf[j], j, inBuf[j]);

			j++;
		}
	}
	
	//LOGD("done");
	//if (pass == 1000)
		//SYS_FatalExit("DONE");
}

void CSlrMusicFileOgg::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	this->OggMix(numSamples);
	
	signed short *inBuf = (signed short *)oggMixBuffer;
	
	float *pMixBufferL = mixBufferL;
	float *pMixBufferR = mixBufferR;
	{
		for (u32 i = 0; i < numSamples; i++)
		{
			*pMixBufferL += ( ((float) (*inBuf)) / 32767.0f ) * volume;
			inBuf++;
			pMixBufferL++;
			*pMixBufferR += ( ((float) (*inBuf)) / 32767.0f ) * volume;
			inBuf++;
			pMixBufferR++;
		}
	}
	
	//LOGD("------ CSlrMusicFileOgg::MixFloat %d samples -------", numSamples);
	//	u32 j = 0;
	//	inBuf = (signed short *)oggMixBuffer;
	//
	//	pMixBufferL = mixBufferL;
	//	pMixBufferR = mixBufferR;
	//	for (u32 i = 0; i < numSamples; i++)
	//	{
	//		LOGD("--i=%d", i);
	//		LOGD("inBuf[%d]=%d pMixBufferL[%d]=%f", j, inBuf[j], i, pMixBufferL[i]);
	//		j++;
	//		LOGD("inBuf[%d]=%d pMixBufferR[%d]=%f", j, inBuf[j], i, pMixBufferR[i]);
	//		j++;
	//	}
	
	//	LOGD("done");
}

// resource should free memory, @returns memory freed
u32 CSlrMusicFileOgg::ResourceDeactivate(bool async)
{
	LOGWarning("CSlrMusicFileOgg::ResourceDeactivate: should not happen");
	return 0;
}

// resource should load itself, @returns memory allocated
u32 CSlrMusicFileOgg::ResourceActivate(bool async)
{
	LOGWarning("CSlrMusicFileOgg::ResourceActivate: should not happen");
	return 0;
}

// get size of resource in bytes
u32 CSlrMusicFileOgg::ResourceGetSize()
{
	return sizeof(OggVorbis_File);
}


void CSlrMusicFileOgg::LockMutex()
{
	pthread_mutex_lock(&oggFileMutex);
}

void CSlrMusicFileOgg::UnlockMutex()
{
	pthread_mutex_unlock(&oggFileMutex);
}

