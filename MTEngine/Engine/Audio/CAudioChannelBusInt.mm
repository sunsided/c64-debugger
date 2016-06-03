#include "CAudioChannelBusInt.h"
#include "SYS_Main.h"
#include "SND_SoundEngine.h"

CAudioChannelBusInt::CAudioChannelBusInt(u16 numChannels)
{
	this->numChannels = numChannels;
	
	this->isActive = false;
	this->bypass = false;
	this->destroyMe = false;

	sprintf(name, "bus int");
}

CAudioChannelBusInt::~CAudioChannelBusInt()
{

}

void CAudioChannelBusInt::Mix(int *mixBuffer, u32 numSamples)
{
	for (u16 i = 0; i < numChannels; i++)
	{
		if (oggAudioChannelsPool[i]->isActive == true)
		{
			if (oggAudioChannelsPool[i]->bypass)
				continue;
			
			oggAudioChannelsPool[i]->Mix(mixBuffer, numSamples);
		}
	}
}

void CAudioChannelBusInt::PlaySound(CSlrFileMemory *file)
{
	this->PlaySound(file, 1.0f);
}

void CAudioChannelBusInt::PlaySound(CSlrFileMemory *file, float volume)
{
	//	CSlrMusicFileOgg *oggSound = new CSlrMusicFileOgg(fileName, false, true);
	//	oggSound->shouldBeDestroyedByEngine = true;
	//	oggSound->Play();
	//	gSoundEngine->AddChannel(oggSound);
	
	LOGA("CAudioChannelBusInt::PlaySound '%s', volume=%3.2f", file->fileName, volume);
	
	gSoundEngine->LockMutex("CAudioChannelBusInt::PlaySound");
	
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
	
	// copy file buffer
	oggAudioFilesPool[playChannel]->Open(file);
	
	// init ogg from memory file
	oggAudioChannelsPool[playChannel]->Init(oggAudioFilesPool[playChannel], true);
	
	// play sound
	oggAudioChannelsPool[playChannel]->Play();
	oggAudioChannelsPool[playChannel]->volume = volume;
	
	gSoundEngine->UnlockMutex("CAudioChannelBusInt::PlaySound");
	
	//LOGD("SND_PlaySound done");
	
}
