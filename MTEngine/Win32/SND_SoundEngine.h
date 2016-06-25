#ifndef _CSOUNDENGINE_
#define _CSOUNDENGINE_  

// dsound.lib dxguid.lib winmm.lib

#include "DBG_Log.h"
#include <pthread.h>
#include "SYS_Threading.h"
#include "CSlrString.h"

#include "ivorbiscodec.h"
#include "ivorbisfile.h"

#include "CAudioChannel.h"
#include <list>

#include "portaudio.h"

#define SOUND_SAMPLE_RATE 44100
//#define SOUND_SAMPLE_RATE 22050

#define SOUND_BUFFER_SIZE 48000 
//0xA000
//0xA000 // 48K - around 1/2 sec of 44kHz 16 bit mono PCM     
#define kNumberBuffers 2

void SYS_InitSoundEngine();

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
	void SetOutputAudioDevice(CSlrString *deviceName);

	char deviceOutName[512];
	int deviceOutIndex;

	bool StartAudioUnit(bool isPlayback, bool isRecording, int recordingFrequency);
	void StopAudioUnit();
	void ResetAudioUnit(bool isRecordingOn);

	void AllocateInputBuffers(UInt32 inNumberFrames);
	// portaudio
	PaStream *streamOutput;
	PaStream *streamInput;
    PaError err;
	
	CAudioRecordingCallback *guiRecordingCallback;
	byte *recordedData;
    UInt32 recordedDataSizeInBytes;
	int recordedNumberFrames; 
	bool removeDC;

	void StartRecording(bool isPlaybackOn, int recordingFrequency, CAudioRecordingCallback *guiRecordingCallback);
	void SetRecordingCallback(CAudioRecordingCallback *guiRecordingCallback);
	void StopRecording(); 
	
	volatile bool isAudioSessionInitialized;
	volatile bool isRecordingOn;
	volatile int recordingFrequency;
	volatile bool isPlaybackOn;
	
	char *whoLocked;
	void LockMutex(char *_whoLocked);
	void UnlockMutex(char *_whoLocked);

//private:
	CSlrMutex *mutex;


};

extern CSoundEngine *gSoundEngine;

void playbackFakeCallback(int numSamples);





#endif //CSOUNDENGINE