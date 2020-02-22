#include "CAudioChannelBusFloat.h"
#include "SYS_Main.h"
#include "SND_SoundEngine.h"

CAudioChannelBusFloat::CAudioChannelBusFloat(u16 numChannels)
{
	this->numChannels = numChannels;

	this->fMixBufferL = NULL;
	this->fMixBufferR = NULL;
	this->fMixBufferSize = 0;

	this->isActive = true;
	this->bypass = false;
	this->destroyMe = false;

	oggAudioChannelsPool = new CSlrMusicFileOgg *[numChannels];
	oggAudioFilesPool = new CSlrFileMemory *[numChannels];

	for (u16 i = 0; i < numChannels; i++)
	{
		oggAudioChannelsPool[i] = new CSlrMusicFileOgg();
		oggAudioFilesPool[i] = new CSlrFileMemory();
	}

	sprintf(name, "bus float");

}

CAudioChannelBusFloat::~CAudioChannelBusFloat()
{

}

void CAudioChannelBusFloat::PreMixFloat(u32 numSamples)
{
	if (fMixBufferSize != numSamples)
	{
		if (fMixBufferSize < numSamples)
		{
			if (this->fMixBufferL)
			{
				delete [] this->fMixBufferL;
				delete [] this->fMixBufferR;
			}
			
			fMixBufferL = new float[numSamples];
			fMixBufferR = new float[numSamples];
			fMixBufferSize = numSamples;
			fMixBufferSizeBytes = numSamples * sizeof(float);
			
			LOGD("CAudioChannelBusFloat::Mix: recreated fMixBuffer with %d samples", numSamples);
		}
	}
	
	memset(fMixBufferL, 0x00, fMixBufferSizeBytes);
	memset(fMixBufferR, 0x00, fMixBufferSizeBytes);
	
	for (std::list<CAudioChannel *>::iterator itAudioChannel = audioChannelsDynamic.begin();
		 itAudioChannel !=  audioChannelsDynamic.end(); )
	{
		CAudioChannel *audioChannel = *itAudioChannel;
		
		std::list<CAudioChannel *>::iterator itCurrentAudioChannel = itAudioChannel;
		itAudioChannel++;
		
		if (audioChannel->destroyMe)
		{
			audioChannelsDynamic.erase(itCurrentAudioChannel);
			delete audioChannel;
			continue;
		}
		
		if (!audioChannel->isActive)
			continue;
		
		if (audioChannel->bypass)
			continue;
		
		audioChannel->MixInFloat(fMixBufferL, fMixBufferR, numSamples);
	}
	
	for (u16 i = 0; i < numChannels; i++)
	{
		if (oggAudioChannelsPool[i]->isActive == true)
		{
			if (oggAudioChannelsPool[i]->bypass)
				continue;
			
			oggAudioChannelsPool[i]->MixInFloat(fMixBufferL, fMixBufferR, fMixBufferSize);
		}
	}
	
}

void CAudioChannelBusFloat::MixFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	//LOGD("CAudioChannelBusFloat::MixFloat: numSamples=%d", numSamples);
	this->PreMixFloat(numSamples);
	
	// fill float mix buffer
	float *pMixBufferL = fMixBufferL;
	float *pMixBufferR = fMixBufferR;
	float *pMixOutBufferL = mixBufferL;
	float *pMixOutBufferR = mixBufferR;
	
	for (u32 i = 0; i < numSamples; i++)
	{
		*pMixOutBufferL = *pMixBufferL;
		pMixBufferL++;
		pMixOutBufferL++;
		*pMixOutBufferR = *pMixBufferR;
		pMixBufferR++;
		pMixOutBufferR++;
	}
}

void CAudioChannelBusFloat::Mix(int *mixBuffer, u32 numSamples)
{
	//LOGD("CAudioChannelBusFloat::Mix: numSamples=%d", numSamples);
	this->PreMixFloat(numSamples);

	// fill int mix buffer
	float *pMixBufferL = fMixBufferL;
	float *pMixBufferR = fMixBufferR;
	i16 *pMixBuffer = (i16 *)mixBuffer;
	for (u32 i = 0; i < numSamples; i++)
	{
		*pMixBuffer = (short int) (*pMixBufferL * 32767.0f);
		pMixBufferL++;
		pMixBuffer++;
		*pMixBuffer = (short int) (*pMixBufferR * 32767.0f);
		pMixBuffer++;
		pMixBufferR++;
	}
	
//	pMixBuffer = (i16 *)mixBuffer;
//	u32 j = 0;
//	for (u32 i = 0; i < numSamples; i++)
//	{
//		LOGD("mixBuffer[%d] = %d", i, mixBuffer[i]);
//		LOGD("pMixBuffer[%d] = %d", j, pMixBuffer[j]);
//		j++;
//		LOGD("pMixBuffer[%d] = %d", j, pMixBuffer[j]);
//		j++;
//	}
//	
//	LOGD("done");
}

void CAudioChannelBusFloat::MixInFloat(float *mixBufferL, float *mixBufferR, u32 numSamples)
{
	//LOGD("CAudioChannelBusFloat::MixFloat: numSamples=%d", numSamples);
	this->PreMixFloat(numSamples);
	
	// fill float mix buffer
	float *pMixBufferL = fMixBufferL;
	float *pMixBufferR = fMixBufferR;
	float *pMixOutBufferL = mixBufferL;
	float *pMixOutBufferR = mixBufferR;
	
	for (u32 i = 0; i < numSamples; i++)
	{
		*pMixOutBufferL += *pMixBufferL;
		pMixBufferL++;
		pMixOutBufferL++;
		*pMixOutBufferR += *pMixBufferR;
		pMixBufferR++;
		pMixOutBufferR++;
	}
}

void CAudioChannelBusFloat::MixIn(int *mixBuffer, u32 numSamples)
{
	//LOGD("CAudioChannelBusFloat::Mix: numSamples=%d", numSamples);
	this->PreMixFloat(numSamples);
	
	// fill int mix buffer
	float *pMixBufferL = fMixBufferL;
	float *pMixBufferR = fMixBufferR;
	i16 *pMixBuffer = (i16 *)mixBuffer;
	for (u32 i = 0; i < numSamples; i++)
	{
		*pMixBuffer += (short int) (*pMixBufferL * 32767.0f);
		pMixBufferL++;
		pMixBuffer++;
		*pMixBuffer += (short int) (*pMixBufferR * 32767.0f);
		pMixBuffer++;
		pMixBufferR++;
	}
	
	//	pMixBuffer = (i16 *)mixBuffer;
	//	u32 j = 0;
	//	for (u32 i = 0; i < numSamples; i++)
	//	{
	//		LOGD("mixBuffer[%d] = %d", i, mixBuffer[i]);
	//		LOGD("pMixBuffer[%d] = %d", j, pMixBuffer[j]);
	//		j++;
	//		LOGD("pMixBuffer[%d] = %d", j, pMixBuffer[j]);
	//		j++;
	//	}
	//
	//	LOGD("done");
}

void CAudioChannelBusFloat::AddChannel(CAudioChannel *channel)
{
	gSoundEngine->LockMutex("CAudioChannelBusFloat::AddChannel");
	audioChannelsDynamic.push_back(channel);
	gSoundEngine->UnlockMutex("CAudioChannelBusFloat::AddChannel");
}

void CAudioChannelBusFloat::RemoveChannel(CAudioChannel *channel)
{
	gSoundEngine->LockMutex("CAudioChannelBusFloat::RemoveChannel");
	audioChannelsDynamic.remove(channel);
	gSoundEngine->UnlockMutex("CAudioChannelBusFloat::RemoveChannel");
}


void CAudioChannelBusFloat::PlaySound(CSlrFileMemory *file)
{
	this->PlaySound(file, 1.0f);
}

void CAudioChannelBusFloat::PlaySound(CSlrFileMemory *file, float volume)
{
	//	CSlrMusicFileOgg *oggSound = new CSlrMusicFileOgg(fileName, false, true);
	//	oggSound->shouldBeDestroyedByEngine = true;
	//	oggSound->Play();
	//	gSoundEngine->AddChannel(oggSound);

	LOGA("CAudioChannelBusFloat::PlaySound '%s', volume=%3.2f", file->fileName, volume);

	gSoundEngine->LockMutex("CAudioChannelBusFloat::PlaySound");

	// find not active channel
	u16 playChannel = 0xFFFF;
	for (u16 i = 0; i < this->numChannels; i++)
	{
		if (oggAudioChannelsPool[i]->isActive == false)
		{
			playChannel = i;
			break;
		}
	}

	if (playChannel == 0xFFFF)
	{
		// find most-finished sound
		u32 remainingBytes = 0xFFFFFFFF;
		for (u16 i = 0; i < numChannels; i++)
		{
			u32 r = oggAudioFilesPool[i]->GetFileSize() - oggAudioFilesPool[i]->Tell();
			if (r < remainingBytes)
			{
				playChannel = i;
				remainingBytes = r;
			}
		}
	}

#if !defined(FINAL_RELEASE)
	if (playChannel == 0xFFFF)
	{
		SYS_FatalExit("CAudioChannelBusFloat::PlaySound: channel not found, numChannels=%d", numChannels);
	}
#endif

	// copy file buffer
	oggAudioFilesPool[playChannel]->Open(file);

	// init ogg from memory file
	oggAudioChannelsPool[playChannel]->Init(oggAudioFilesPool[playChannel], true);

	// play sound
	oggAudioChannelsPool[playChannel]->Play();
	oggAudioChannelsPool[playChannel]->volume = volume;

	gSoundEngine->UnlockMutex("CAudioChannelBusFloat::PlaySound");

	//LOGD("SND_PlaySound done");

}
