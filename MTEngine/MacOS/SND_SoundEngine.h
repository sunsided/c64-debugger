/*
 *  SND_CSoundEngine.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-19.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _CSOUNDENGINE_
#define _CSOUNDENGINE_

#include "DBG_Log.h"
#include "SYS_Defs.h"

#include <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
//#import <AVFoundation/AVFoundation.h>

#include "ivorbiscodec.h"
#include "ivorbisfile.h"

#include "CAudioChannel.h"

#include "portaudio.h"

#include <list>

//#if (defined(TARGET_OS_IPHONE) && defined(IS_TRACKER))
//#define SOUND_SAMPLE_RATE 22050
//#else
#define SOUND_SAMPLE_RATE 44100
//44100
//#endif

#define SOUND_BUFFER_SIZE 48000
//0xA000
//0xA000 // 48K - around 1/2 sec of 44kHz 16 bit mono PCM     
#define kNumberBuffers 2

void SYS_InitSoundEngine();
void SYS_CheckOSStatus(OSStatus *status);

class CSlrMutex;
class CSlrString;

class CAudioRecordingCallback
{
public:
	virtual void RecordingCallback(byte *buffer, UInt32 numBytes);
};

class CSoundEngine
{
public:
	CSoundEngine();
	~CSoundEngine();
	
	std::list<CSlrString *> *EnumerateAvailableOutputDevices();
	bool SetOutputAudioDevice(CSlrString *deviceName);
	
	CSlrString *audioOutDeviceName;
	int deviceOutIndex;
	
	void StartAudioUnit(bool isPlayback, bool isRecording, int recordingFrequency);
	void StopAudioUnit();
	void RestartAudioUnit();
	void DefaultAudioDeviceChanged();
	
	// portaudio
	PaStream *streamOutput;
	PaStream *streamInput;
    PaError err;
	
    byte *recordedData;
    UInt32 recordedDataSizeInBytes;
	int recordedNumberFrames;
	volatile bool isRecordingOn;
	volatile int recordingFrequency;
	volatile bool isPlaybackOn;
	CAudioRecordingCallback *guiRecordingCallback;
	void StartRecording(bool isPlaybackOn, int recordingFrequency, CAudioRecordingCallback *guiRecordingCallback);
	void SetRecordingCallback(CAudioRecordingCallback *guiRecordingCallback);
	void StopRecording();
	volatile bool isAudioSessionInitialized;
	
	void AllocateInputBuffers(UInt32 inNumberFrames);
	
	volatile bool isMuted;
	
	bool removeDC;
	
	// sound channels
	void PlaySound(char *fileName);
	void PlaySound(char *fileName, float volume);
	
	char *whoLocked;
	void LockMutex(char *_whoLocked);
	void UnlockMutex(char *_whoLocked);
	
	CSlrMutex *audioEngineMutex;
};

extern "C" {
	void MTEngine_PA_LOG_Callback(const char *str);
}

extern CSoundEngine *gSoundEngine;

void playbackFakeCallback(int numSamples);

#endif //CSOUNDENGINE







/*
http://runningaround.org/wp/2009/04/24/five-iphone-development-sound-tips/

 Five iPhone development sound tips
 April24
 
 A few sound-related tips I’ve discovered along the way that I’d like to share:
 
 1. You can’t play two compressed (aac, mp3, alac) files at the same time because there is only one hardware uncompressor
 available. Here’s a little more info from Apple’s documentation:
 http://developer.apple.com/iphone/library/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/AudioandVideoTechnologies/AudioandVideoTechnologies.html#//apple_ref/doc/uid/TP40007072-CH19-SW9
 
 The following list summarizes how iPhone OS supports audio formats for single or multiple playback:
 
 * Linear PCM and IMA4 (IMA/ADPCM) You can play multiple linear PCM or IMA4 format sounds simultaneously in iPhone OS 
 without incurring CPU resource problems. The same is true for the AMR and iLBC speech-quality formats, and for the 
 µ-law and a-law compressed formats.
 * AAC, MP3, and ALAC (Apple Lossless) Playback for AAC, MP3, and ALAC sounds uses efficient hardware-based decoding 
 on iPhone OS–based devices, but these codecs all share a single hardware path. The device can play only 
 a single instance of one of these formats at a time.
 
 The single hardware path for AAC, MP3, and ALAC audio entails implications for “play along” style applications, such as 
 a virtual piano. If the user is playing a sound in one of these three formats in the iPod application, 
 then your application—to play along over that audio—must use one of the software-decoded formats: 
 linear PCM, IMA4, AMR, iLBC, µ-law, or a-law.
 
 2. Use the compressed format for the largest file (for example, background music.) In my case, I’m using a very compressed 
 mp3. (22050 sample rate, mono, low quality VBR).
 
 3. Use Audacity (I’m using the beta with no problems) to create your compressed mp3s. It provides a nice GUI for you to 
 trim your sound file.  The sampling rate is in the lower left corner of the window, and you can change the 
 variable-bit-rate range by selecting File->Export…, selecting mp3 as your format, and clicking the ‘Options’ button.
 
 4. For your other sounds, like sound effects, that you’d like to play concurrently with your background music, run the 
 following command in Terminal to convert your sounds to a software-compressed format (I’m using IMA4, seems to be the 
 best size/quality compromise). I first tried to use sox, but afconvert will more reliably give you a file that the apple 
 development environment is happy with:
 
 % afconvert -d 'ima4' -f 'caff' inputfile.mp3 outputfile.caf
 
 You can also check to make sure they are readable by the iPhone SDK with afinfo and listen to them with afplay. IMA4 is 
 a compressed format but the quality seems to be pretty decent.
 
 5. AVAudioPlayer is a very easy way to get compatible sound files into your application. It only works on OS 2.2 or 
 greater. To use it,
 
 
 #import <AVFoundation/AVFoundation.h>
 
 bgMusicPlayer = [AVAudioPlayer alloc ];
 [bgMusicPlayer initWithContentsOfURL: [NSURL fileURLWithPath:
 [ [ NSBundle mainBundle ] pathForResource: @”street_level-small”
 ofType:@”mp3″
 inDirectory:@”/” ] ]
 error:nil
 ];
 
 [bgMusicPlayer prepareToPlay];
 
 // when you want to play the file
 
 [bgMusicPlayer play];
 
 You will also need to include the AVFoundation framework. Ctrl-click (or right click) on Frameworks in your Xcode window, 
 then select Add->Existing Frameworks…  The AVFoundation framework is in /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.sdk/System/Library/Frameworks/

*/

