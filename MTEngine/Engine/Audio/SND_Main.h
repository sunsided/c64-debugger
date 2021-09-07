#ifndef _SND_SOUNDMIXER_H_
#define _SND_SOUNDMIXER_H_

#include "SYS_Defs.h"
#include "CAudioChannel.h"
#include "CSlrFileMemory.h"
#include "SND_SoundEngine.h"

class CSoundEngine;
extern CSoundEngine *gSoundEngine;

void SND_MainInitialize();
void SND_MainMixer(int *mixBuffer, u32 numSamples);
void SND_AddChannel(CAudioChannel *channel);
void SND_RemoveChannel(CAudioChannel *channel);
void SND_AddChannel_NoMutex(CAudioChannel *channel);
void SND_RemoveChannel_NoMutex(CAudioChannel *channel);
void SND_PlaySound(CSlrFileMemory *file);
void SND_PlaySound(CSlrFileMemory *file, float volume);

#endif
//_SND_SOUNDMIXER_H_
