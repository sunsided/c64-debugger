#include "SND_Main.h"
#include "SND_SoundEngine.h"
#include "CSlrMusicFileOgg.h"
#include "SYS_Main.h"

#define NUM_OGG_CHANNELS_POOL 16

int SND_numAudioChannels = 0;

std::list<CAudioChannel *> audioChannelsDynamic;
CSlrMusicFileOgg *oggAudioChannelsPool[NUM_OGG_CHANNELS_POOL];
CSlrFileMemory *oggAudioFilesPool[NUM_OGG_CHANNELS_POOL];

void SND_MainInitialize()
{
	LOGA("SND_MainInitialize");

	for (u16 i = 0; i < NUM_OGG_CHANNELS_POOL; i++)
	{
		oggAudioChannelsPool[i] = new CSlrMusicFileOgg();
		oggAudioFilesPool[i] = new CSlrFileMemory();
	}

	SND_numAudioChannels = 0;
}

void SND_MainMixer(int *mixBuffer, u32 numSamples)
{
	//LOGD("SND_MainMixer");
	
	memset(mixBuffer, 0x00, numSamples*4);
	
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

		if (audioChannel->removeMe)
		{
			audioChannelsDynamic.erase(itCurrentAudioChannel);
			continue;
		}
			
		if (audioChannel->bypass)
			continue;

//		LOGD("mixin channel: '%s'", audioChannel->name);
		audioChannel->MixIn(mixBuffer, numSamples, SND_numAudioChannels);
	}

	for (u16 i = 0; i < NUM_OGG_CHANNELS_POOL; i++)
	{
		if (oggAudioChannelsPool[i]->isActive == true)
		{
			if (oggAudioChannelsPool[i]->bypass)
				continue;

			oggAudioChannelsPool[i]->MixIn(mixBuffer, numSamples);
		}
	}

	//LOGD("SND_MainMixer done");
}

void SND_AddChannel(CAudioChannel *channel)
{
	gSoundEngine->LockMutex("SND_AddChannel");
	SND_AddChannel_NoMutex(channel);
	gSoundEngine->UnlockMutex("SND_AddChannel");
}

void SND_RemoveChannel(CAudioChannel *channel)
{
	gSoundEngine->LockMutex("SND_RemoveChannel");
	SND_RemoveChannel_NoMutex(channel);
	gSoundEngine->UnlockMutex("SND_RemoveChannel");
}

void SND_AddChannel_NoMutex(CAudioChannel *channel)
{
	audioChannelsDynamic.push_back(channel);
	SND_numAudioChannels++;
	channel->isActive = true;
}

void SND_RemoveChannel_NoMutex(CAudioChannel *channel)
{
	audioChannelsDynamic.remove(channel);
	channel->isActive = false;
	SND_numAudioChannels--;
}

void SND_PlaySound(CSlrFileMemory *file)
{
	SND_PlaySound(file, 1.0f);
}

void SND_PlaySound(CSlrFileMemory *file, float volume)
{
	if (file == NULL)
	{
		//LOGError("SND_PlaySound: file==NULL");
		SYS_FatalExit("SND_PlaySound: file==NULL");
	}

//	CSlrMusicFileOgg *oggSound = new CSlrMusicFileOgg(fileName, false, true);
//	oggSound->shouldBeDestroyedByEngine = true;
//	oggSound->Play();
//	gSoundEngine->AddChannel(oggSound);

	LOGA("SND_PlaySound '%s', volume=%3.2f", file->fileName, volume);

	gSoundEngine->LockMutex("SND_PlaySound");

	// find not active channel
	u16 playChannel = 0xFFFF;
	for (u16 i = 0; i < NUM_OGG_CHANNELS_POOL; i++)
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
		for (u16 i = 0; i < NUM_OGG_CHANNELS_POOL; i++)
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

	gSoundEngine->UnlockMutex("SND_PlaySound");

	//LOGD("SND_PlaySound done");

}
