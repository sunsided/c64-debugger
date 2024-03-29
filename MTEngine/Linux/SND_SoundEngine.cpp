#include "SYS_Main.h"
#include "SND_SoundEngine.h"
#include "SYS_Funct.h"
#include "CSlrMusicFileOgg.h"
#include "SND_Main.h"
#include "RES_ResourceManager.h"
#include "SYS_Threading.h"
#include "CSlrString.h"
#include <math.h>

CSoundEngine *gSoundEngine = NULL;


void SYS_InitSoundEngine()
{
	PaError err = paNoError;
	err = Pa_Initialize();
	if( err != paNoError )
	{
		SYS_FatalExit("SYS_InitSoundEngine failed");
	}

	gSoundEngine = new CSoundEngine();
}

CSoundEngine::CSoundEngine()
{
	LOGA("CSoundEngine init");

	mutex = new CSlrMutex("CSoundEngine");

	audioOutDeviceName = new CSlrString("Default");
	
	// debug print
	LOGA("--- Audio output devices:");
	PaStreamParameters outputParameters;
	outputParameters.channelCount = 2;                     // stereo output
	outputParameters.sampleFormat = paInt16;
	outputParameters.hostApiSpecificStreamInfo = NULL;
	
	int numDevices;
	numDevices = Pa_GetDeviceCount();
	
	const PaDeviceInfo *deviceInfo;
	for(int i = 0; i < numDevices; i++)
	{
		deviceInfo = Pa_GetDeviceInfo( i );
		LOGA("... device #%d: '%s'", i, deviceInfo->name);
		outputParameters.device = i;
		outputParameters.suggestedLatency = deviceInfo->defaultLowOutputLatency;
		
		PaError err;
		err = Pa_IsFormatSupported( NULL, &outputParameters, SOUND_SAMPLE_RATE );
		if( err == paFormatIsSupported )
		{
			LOGA("    device is supported");
		}
		else
		{
			LOGA("    device is not supported");
		}
	}

	deviceOutIndex = Pa_GetDefaultOutputDevice();
	if (deviceOutIndex == paNoDevice)
	{
		SYS_ShowError("No default audio output device detected, bad luck!");
		SYS_CleanExit();
	}

	recordedData = NULL;
	isAudioSessionInitialized = false;
	isRecordingOn = false;
	isPlaybackOn = false;
	guiRecordingCallback = NULL;

	recordingFrequency = 44100;

	removeDC = false;

	this->isMuted = false;

	SND_MainInitialize();
}

//static signed short prevValIn = 0;
//static float prevValOut = 0;	//signed short
//const float R = 0.975;
//	if (gSoundEngine->removeDC)
//	{
//		/*
//		 Some audio algorithms (asymmetric waveshaping, cascaded filters, ...) can produce DC offset.
//		 This offset can accumulate and reduce the signal/noise ratio.
//
//		 So, how to fix it? The example code from Julius O. Smith's document is:
//		 ...
//		 y(n) = x(n) - x(n-1) + R * y(n-1)
//		 // "R" between 0.9 .. 1
//		 // n=current (n-1)=previous in/out value
//		 ...
//		 "R" depends on sampling rate and the low frequency point. Do not set "R" to a fixed value (e.g. 0.99) if you don't know the sample rate. Instead set R to:
//		 (-3dB @ 40Hz): R = 1-(250/samplerate)
//		 (-3dB @ 30Hz): R = 1-(190/samplerate)
//		 (-3dB @ 20Hz): R = 1-(126/samplerate)
//		 */
//
//		int frames = gSoundEngine->inputBufferList->mBuffers[0].mDataByteSize;
//		signed short *dataIn = (signed short *)gSoundEngine->inputBufferList->mBuffers[0].mData;
//		signed short *dataOut = (signed short *)gSoundEngine->recordedData;
//
//		for (int i = 0; i < frames; i++)
//		{
//			dataOut[i] = dataIn[i] - prevValIn + (signed short)(R * prevValOut);
//			prevValIn = dataIn[i];
//			prevValOut = dataOut[i];
//		}
//	}

static int recordCallback( const void *inputBuffer, void *outputBuffer,
						unsigned long framesPerBuffer,
						const PaStreamCallbackTimeInfo* timeInfo,
						PaStreamCallbackFlags statusFlags,
						void *userData )

{
	u32 len = framesPerBuffer * 2;
	//[NSThread setThreadPriority:1.0];

	if (gSoundEngine->isRecordingOn)
	{
		memcpy(gSoundEngine->recordedData,
			   inputBuffer,
			   len);
		//DBG_PrintBytes(gSoundEngine->recordedData, gSoundEngine->recordedDataSizeInBytes);

		if (gSoundEngine->guiRecordingCallback)
		{
			gSoundEngine->guiRecordingCallback->RecordingCallback(gSoundEngine->recordedData, len);
		}
	}

	return paContinue;
}

static int playCallback( const void *inputBuffer, void *outputBuffer,
						unsigned long framesPerBuffer,
						const PaStreamCallbackTimeInfo* timeInfo,
						PaStreamCallbackFlags statusFlags,
						void *userData )

{
	//LOGA("SND_PlaybackCallback");

	u32 len = framesPerBuffer * 4;
	int *mixBuffer = (int*)outputBuffer;
	int numSamples = framesPerBuffer;

//	[NSThread setThreadPriority:1.0];

	if (gSoundEngine->isPlaybackOn == false)
	{
		memset((byte *)mixBuffer, 0x00, len);
		return paContinue;
	}

	int *outBuffer = mixBuffer;

	SND_MainMixer(outBuffer, numSamples);

	//LOGA("SND_PlaybackCallback done");

	return paContinue;
}

i16 *stereoMixBufferForMonoPlayback = NULL;

static int playCallbackMono( const void *inputBuffer, void *outputBuffer,
							unsigned long framesPerBuffer,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData )

{
	//		LOGA("playCallbackMono");
	
	u32 len = framesPerBuffer * 4;
	int *mixBuffer = (int*)stereoMixBufferForMonoPlayback;
	int numSamples = framesPerBuffer;
	
	//	LOGD("framesPerBuffer=%d len=%d", framesPerBuffer, len);
	
	//	u32 j = 0;
	//	for (u32 i = 0; i < framesPerBuffer; i++)
	//	{
	//		mixBuffer[i] = getOneSample();
	//	}
	//	return paContinue;
	//
	
	//	[NSThread setThreadPriority:1.0];
	
	memset((byte *)mixBuffer, 0x00, len);
	
	if (gSoundEngine->isPlaybackOn == false)
	{
		return paContinue;
	}
	
	
	int *stereoBuffer = mixBuffer;
	
	gSoundEngine->LockMutex("playCallbackMono");
	
	//	LOGD("SND_MainMixer: numSamples=%d", numSamples);
	SND_MainMixer(stereoBuffer, numSamples);
	
	gSoundEngine->UnlockMutex("playCallbackMono");
	
	// convert stereo to mono
	i16 *stereoInBuffer = (i16*)stereoBuffer;
	i16 *monoOutBuffer = (i16*)outputBuffer;
	for (u32 i = 0; i < framesPerBuffer; i++)
	{
		i16 left = *stereoInBuffer; stereoInBuffer++;
		i16 right = *stereoInBuffer; stereoInBuffer++;
		i32 v = (left + right) / 2;
		
		*monoOutBuffer = (i16)v;
		monoOutBuffer++;
	}
	
	
#if defined(WRITE_AUDIO_OUT_TO_FILE)
	fwrite(outBuffer, numSamples, 2, fpMainAudioOutWriter);
#endif
	
	//	LOGA("playCallbackMono done");
	
	return paContinue;
}

void CSoundEngine::AllocateInputBuffers(UInt32 inNumberFrames)
{
    LOGD("CSoundEngine::AllocateInputBuffers: inNumberFrames = %d\n", inNumberFrames);

	this->recordedNumberFrames = inNumberFrames;
	int bufferSizeInBytes = inNumberFrames * 4;

    if (recordedData == NULL)
    {
        recordedData = (byte *)malloc(bufferSizeInBytes);
        recordedDataSizeInBytes = bufferSizeInBytes;
    }
}

std::list<CSlrString *> *CSoundEngine::EnumerateAvailableOutputDevices()
{
        LOGD("CSoundEngine::EnumerateAvailableOutputDevices");
        std::list<CSlrString *> *audioOutDevices = new std::list<CSlrString *>();

        PaStreamParameters outputParameters;
        outputParameters.channelCount = 2;                     // stereo output
        outputParameters.sampleFormat = paInt16;
        outputParameters.hostApiSpecificStreamInfo = NULL;

        int numDevices;
        numDevices = Pa_GetDeviceCount();

        const PaDeviceInfo *deviceInfo;
        for(int i = 0; i < numDevices; i++)
        {
                deviceInfo = Pa_GetDeviceInfo( i );
                LOGD("... device #%d: '%s'", i, deviceInfo->name);
                outputParameters.device = i;
                outputParameters.suggestedLatency = deviceInfo->defaultLowOutputLatency;

                PaError err;
                err = Pa_IsFormatSupported( NULL, &outputParameters, SOUND_SAMPLE_RATE );
                if( err == paFormatIsSupported )
                {
                        audioOutDevices->push_back(new CSlrString(deviceInfo->name));
                }
        }

        return audioOutDevices;
}

bool CSoundEngine::SetOutputAudioDevice(CSlrString *deviceName)
{
	if (deviceName != this->audioOutDeviceName && this->audioOutDeviceName != NULL)
	{
		delete audioOutDeviceName;
	}
	
	this->audioOutDeviceName = new CSlrString(deviceName);

	LOGD("CSoundEngine::SetOutputAudioDevice");
	
	char *strDeviceName = deviceName->GetStdASCII();	
	LOGD("... device name='%s'", strDeviceName);
	
	bool playing = isPlaybackOn;
	bool recording = isRecordingOn;
	int recordFreq = recordingFrequency;
	
	StopAudioUnit();
	
	bool deviceFound = false;
	
	if (deviceName->CompareWith("Default"))
	{
		deviceOutIndex = Pa_GetDefaultOutputDevice();
		
		LOGD("Default deviceOutIndex=%d", deviceOutIndex);
		deviceFound = true;
	}
	else
	{
		PaStreamParameters outputParameters;
		outputParameters.channelCount = 2;                     // stereo output
		outputParameters.sampleFormat = paInt16;
		outputParameters.hostApiSpecificStreamInfo = NULL;
		
		int numDevices;
		numDevices = Pa_GetDeviceCount();
		
		const PaDeviceInfo *deviceInfo;
		for(int i = 0; i < numDevices; i++)
		{
			deviceInfo = Pa_GetDeviceInfo( i );
			LOGD("... device #%d: '%s'", i, deviceInfo->name);
			outputParameters.device = i;
			outputParameters.suggestedLatency = deviceInfo->defaultLowOutputLatency;
			
			PaError err;
			err = Pa_IsFormatSupported( NULL, &outputParameters, SOUND_SAMPLE_RATE );
			if( err == paFormatIsSupported )
			{
				if (!strcmp(deviceInfo->name, strDeviceName))
				{
					deviceFound = true;
					deviceOutIndex = i;
				}
			}
		}
		
		LOGD("... SetOutputAudioDevice: device found=%s", STRBOOL(deviceFound));
		
		if (!deviceFound)
		{
			if (FUN_IsNumber(strDeviceName))
			{
				int deviceId = atoi(strDeviceName);
				LOGD("strDeviceName is number, checking deviceId=%d", deviceId);
				
				if (deviceId >= 0 && deviceId < numDevices)
				{
					deviceInfo = Pa_GetDeviceInfo( deviceId );
					LOGD("... device #%d: '%s'", deviceId, deviceInfo->name);
					outputParameters.device = deviceId;
					outputParameters.suggestedLatency = deviceInfo->defaultLowOutputLatency;
					
					PaError err;
					err = Pa_IsFormatSupported( NULL, &outputParameters, SOUND_SAMPLE_RATE );
					if( err == paFormatIsSupported )
					{
						deviceFound = true;
						deviceOutIndex = deviceId;
					}
				}
			}
			
			if (!deviceFound)
			{
				LOGError("selected device '%s' not found, falling back to default", strDeviceName);
				deviceOutIndex = Pa_GetDefaultOutputDevice();
				if (audioOutDeviceName != NULL)
					delete audioOutDeviceName;
				
				this->audioOutDeviceName = new CSlrString("Default");
			}
		}
	}
	
	LOGD("CSoundEngine::SetOutputAudioDevice: StartAudioUnit");
	StartAudioUnit(playing, recording, recordFreq);
	
	delete [] strDeviceName;
	
	LOGD("CSoundEngine::SetOutputAudioDevice: finished");
	
	return deviceFound;

}


bool CSoundEngine::StartAudioUnit(bool isPlayback, bool isRecording, int recordingFrequency)
{
	// TODO: check recording in http://code.google.com/p/soundflower/

	LOGA("StartAudioUnit: isPlayback=%s isRecording=%s recordingFreq=%d", STRBOOL(isPlayback), STRBOOL(isRecording), recordingFrequency);

	if (this->recordedData != NULL)
	{
		delete [] this->recordedData;
		this->recordedData = NULL;
	}

	if (isPlaybackOn || isRecordingOn)
	{
		SYS_FatalExit("TODO: already init");
	}

	PaStreamParameters  inputParameters, outputParameters;
	u32 framesPerBuffer = 512;

	if (isPlayback)
	{
		LOGA("opening output stream, deviceOutIndex=%d", deviceOutIndex);
		
		int numDevices = Pa_GetDeviceCount();
		
		LOGA("Pa_GetDeviceCount=%d", numDevices);
		if (deviceOutIndex >= numDevices)
		{
			deviceOutIndex = Pa_GetDefaultOutputDevice(); // default output device
			LOGA("deviceOutIndex=%d", deviceOutIndex);
			if (deviceOutIndex == paNoDevice)
			{
				SYS_FatalExit("No default audio output device detected, bad luck!");
			}
		}
		
		// copy device output name
		LOGA("Pa_GetDeviceInfo");
		const PaDeviceInfo *deviceInfo;
		deviceInfo = Pa_GetDeviceInfo( deviceOutIndex );
		
		LOGA("deviceInfo name=%s", deviceInfo->name);
		//		strncpy(deviceOutName, deviceInfo->name, 512);
		
		outputParameters.device = deviceOutIndex;
		outputParameters.sampleFormat = paInt16;
		outputParameters.suggestedLatency = Pa_GetDeviceInfo( outputParameters.device )->defaultLowOutputLatency;
		outputParameters.hostApiSpecificStreamInfo = NULL;
		
		if (deviceInfo->maxOutputChannels >= 2)
		{
			outputParameters.channelCount = 2;                     // stereo output
			
			LOGA("Pa_OpenStream stereo");
			err = Pa_OpenStream(&streamOutput,
								NULL, /* no input */
								&outputParameters,
								SOUND_SAMPLE_RATE,
								512, //SOUND_BUFFER_SIZE / SOUND_SAMPLE_RATE,
								paClipOff,      // we won't output out of range samples so don't bother clipping them
								playCallback,
								NULL );
		}
		else if (deviceInfo->maxOutputChannels == 1)
		{
			if (stereoMixBufferForMonoPlayback != NULL)
			{
				stereoMixBufferForMonoPlayback = new i16[SOUND_BUFFER_SIZE * 2];
			}
			outputParameters.channelCount = 1;                     // stereo output
			
			LOGA("Pa_OpenStream mono");
			err = Pa_OpenStream(&streamOutput,
								NULL, /* no input */
								&outputParameters,
								SOUND_SAMPLE_RATE,
								512, //SOUND_BUFFER_SIZE / SOUND_SAMPLE_RATE,
								paClipOff,      // we won't output out of range samples so don't bother clipping them
								playCallbackMono,
								NULL );
		}
		else
		{
			SYS_FatalExit("Output device does not support number of channels, required channels=%d", deviceInfo->maxOutputChannels);
		}
		
		if( err != paNoError )
		{
			SYS_FatalExit("Opening output stream failed");
		}
		
		LOGA("Pa_StartStream");
		err = Pa_StartStream( streamOutput );
		if( err != paNoError )
		{
			SYS_FatalExit("Starting output stream failed");
		}
		
		//		LOGM("Audio output stream opened, device=%s", deviceOutName);
	}
	
	if (isRecording)
	{
		LOGA("opening input stream");
		inputParameters.device = Pa_GetDefaultInputDevice();
		if (inputParameters.device == paNoDevice)
		{
			SYS_ShowError("No default audio input device detected, bad luck!");
			SYS_CleanExit();
		}
		inputParameters.channelCount = 1;                     // mono input
		inputParameters.sampleFormat = paInt16;
		inputParameters.suggestedLatency = Pa_GetDeviceInfo( inputParameters.device )->defaultLowOutputLatency;
		inputParameters.hostApiSpecificStreamInfo = NULL;

		LOGA("Pa_OpenStream");
		err = Pa_OpenStream(
							&streamInput,
							&inputParameters,
							NULL,
							recordingFrequency,
							framesPerBuffer, //SOUND_BUFFER_SIZE / SOUND_SAMPLE_RATE,
							paClipOff,      // we won't output out of range samples so don't bother clipping them
							recordCallback,
							NULL );

		if( err != paNoError )
		{
			SYS_FatalExit("Opening input stream failed");
		}

		if (gSoundEngine->recordedData == NULL)
		{
			gSoundEngine->AllocateInputBuffers(framesPerBuffer);
		}

		LOGA("Pa_StartStream");
		err = Pa_StartStream( streamInput );
        if( err != paNoError )
		{
			SYS_FatalExit("Starting input+output stream failed");
		}

		LOGA("input stream opened");
	}

	this->isRecordingOn = isRecording;
	this->isPlaybackOn = isPlayback;

	LOGA("starting AudioUnit done");
	return true;
}


void CSoundEngine::StopAudioUnit()
{
	LOGA("StopAudioUnit");

	if (isPlaybackOn)
	{
		if (streamOutput != NULL)
		{
			err = Pa_CloseStream( streamOutput );
			if( err != paNoError )
			{
				LOGError("Pa_CloseStream failed");
			}

			streamOutput = NULL;
		}
	}

	if (isRecordingOn)
	{
		if (streamInput != NULL)
		{
			err = Pa_CloseStream( streamInput );
			if( err != paNoError )
			{
				LOGError("Pa_CloseStream failed");
			}

			streamInput = NULL;
		}
	}

	this->isPlaybackOn = false;
	this->isRecordingOn = false;

	LOGA("stopping AudioUnit done");
}

void CSoundEngine::RestartAudioUnit()
{
	LOGA("CSoundEngine::RestartAudioUnit");
	
	this->LockMutex("CSoundEngine::RestartAudioUnit");
	audioOutDeviceName->DebugPrint("audioOutDeviceName=");
	
	bool playbackOn = this->isPlaybackOn;
	bool recordingOn = this->isRecordingOn;
	int freq = this->recordingFrequency;
	
	// this sometimes locks forever on macOS
	this->StopAudioUnit();
	
	LOGD("Pa_Terminate");
	Pa_Terminate();
	
	LOGD("Pa_Initialize");
	err = Pa_Initialize();
	if( err != paNoError )
	{
		SYS_FatalExit("CSoundEngine::RestartAudioUnit Pa_Initialize failed");
	}
	
	this->isPlaybackOn = playbackOn;
	this->isRecordingOn = recordingOn;
	this->recordingFrequency = freq;
	
	if (audioOutDeviceName != NULL)
	{
		this->SetOutputAudioDevice(audioOutDeviceName);
	}
	else
	{
		this->StopAudioUnit();
		this->StartAudioUnit(playbackOn, recordingOn, freq);
	}
	
	this->UnlockMutex("CSoundEngine::RestartAudioUnit");
	
	LOGD("RestartAudioUnit");
}

void CSoundEngine::DefaultAudioDeviceChanged()
{
	LOGA("CSoundEngine::DefaultAudioDeviceChanged");
	if (audioOutDeviceName && audioOutDeviceName->CompareWith("Default"))
	{
		this->RestartAudioUnit();
	}
	
	LOGD("CSoundEngine::DefaultAudioDeviceChanged done");
}

void CSoundEngine::SetRecordingCallback(CAudioRecordingCallback *guiRecordingCallback)
{
	this->guiRecordingCallback = guiRecordingCallback;
}

void CSoundEngine::StartRecording(bool isPlaybackOn, int recordingFrequency, CAudioRecordingCallback *guiRecordingCallback)
{
	LOGA("StartRecording()");

	this->StopAudioUnit();
	this->guiRecordingCallback = guiRecordingCallback;
	this->StartAudioUnit(isPlaybackOn, true, recordingFrequency);
}

void CSoundEngine::StopRecording()
{
	LOGA("StopRecording()");

	this->guiRecordingCallback = NULL;
	this->StopAudioUnit();
	this->StartAudioUnit(true, false, 0);
}


void CSoundEngine::LockMutex(char *_whoLocked)
{
	/*LOGD("CSoundEngine::LockMutex: %s", _whoLocked);
	if (this->whoLocked != NULL)
	{
		LOGD("already locked by %s", this->whoLocked);
	}
	this->whoLocked = _whoLocked;
	*/

	mutex->Lock();

	//pthread_mutex_lock(&xmPlayerMutex);

	//LOGD("CSoundEngine::LockMutex: %s success", _whoLocked);
}

void CSoundEngine::UnlockMutex(char *_whoLocked)
{
	/*
	LOGD("CSoundEngine::UnlockMutex: %s", _whoLocked);
	if (this->whoLocked != NULL)
	{
		LOGD("was locked by %s", this->whoLocked);
	}*/

	mutex->Unlock();

	//pthread_mutex_unlock(&xmPlayerMutex);

	//this->whoLocked = NULL;
	//LOGD("CSoundEngine::UnlockMutex: %s success", _whoLocked);
}

#if !defined(USE_FAKE_CALLBACK)
void playbackFakeCallback(int numSamples)
{
	SYS_FatalExit("playbackFakeCallback is OFF");
}

#else

// for rendering when queue is not used
void playbackFakeCallback(int numSamples)
{
	static int *outBuffer = NULL;
	static int numBytes = -1;

	if (numBytes < numSamples)
	{
		outBuffer = new int[numSamples];
		numBytes = numSamples;
	}

    //int totalNumberOfSamples = _pcm.size();
	//for(UInt32 bufNum = 0; bufNum < ioData->mNumberBuffers; bufNum++)
	{
		//LOGF("bufSize=%d", ioData->mBuffers[bufNum].mDataByteSize);

		//int numSamples = ioData->mBuffers[bufNum].mDataByteSize / 4;

		//int *outBuffer = (int *)ioData->mBuffers[bufNum].mData;

		if (gSoundEngine->xmPlayer == NULL)
		{
			memset(outBuffer, 0, numSamples);
			return;
		}

		/*
		 for (int i = 0; i < numSamples; i++)
		 {
		 outBuffer[i] = getOneSample();
		 }*/

		int samplePos = 0;

		while(samplePos < numSamples)
		{
			//LOGF("samplePos=%d numSamples=%d xmAudioBufferPos=%d xmAudioBufferLen=%d", samplePos, numSamples, xmAudioBufferPos, xmAudioBufferLen);
			if (xmAudioBufferPos >= xmAudioBufferLen)
			{
				// render one buffer
				pthread_mutex_lock(&gSoundEngine->xmPlayerMutex);
				//LOGF("render");
				xmAudioBufferLen = gSoundEngine->xmPlayer->Render(xmAudioBuffer, SOUND_BUFFER_SIZE);
				pthread_mutex_unlock(&gSoundEngine->xmPlayerMutex);

				//LOGF("xmAudioBufferLen=%d", xmAudioBufferLen);
				if (xmAudioBufferLen >= SOUND_BUFFER_SIZE)
				{
					LOGA("XMPlayer buffer overflow");
				}
				else if (xmAudioBufferLen + samplePos < numSamples)
				{
					memcpy(outBuffer + samplePos, xmAudioBuffer, xmAudioBufferLen * sizeof(int));
					samplePos += xmAudioBufferLen;
					xmAudioBufferPos = xmAudioBufferLen;
				}
				else if (xmAudioBufferLen + samplePos >= numSamples)
				{
					int lenLeft = numSamples - samplePos;
					memcpy(outBuffer + samplePos, xmAudioBuffer, lenLeft * sizeof(int));
					xmAudioBufferPos = lenLeft;
					samplePos += lenLeft;
				}
			}
			else
			{
				int xmLenLeft = xmAudioBufferLen - xmAudioBufferPos;

				if (samplePos + xmLenLeft >= numSamples)
				{
					int lenLeft = numSamples - samplePos;
					memcpy(outBuffer + samplePos, xmAudioBuffer + xmAudioBufferPos, lenLeft * sizeof(int));
					samplePos += lenLeft;
					xmAudioBufferPos += lenLeft;
				}
				else if (samplePos + xmLenLeft < numSamples)
				{
					memcpy(outBuffer + samplePos, xmAudioBuffer + xmAudioBufferPos, xmLenLeft * sizeof(int));
					samplePos += xmLenLeft;
					xmAudioBufferPos += xmLenLeft;
				}
			}

		}
	}

#ifdef MIX_CHANNELS
	static int fakeMixBuffer[SOUND_BUFFER_SIZE];
	for (std::list<CAudioChannel *>::iterator itAudioChannel = gSoundEngine->audioChannels.begin();
		 itAudioChannel !=  gSoundEngine->audioChannels.end(); itAudioChannel++)
	{
		CAudioChannel *audioChannel = *itAudioChannel;

		if (audioChannel->bypass)
			continue;

		audioChannel->Mix(fakeMixBuffer, numSamples);
	}
#endif

    return;
}
#endif

