#include "SYS_Defs.h"
#include "SND_SoundEngine.h"
#include "CSlrMusicFileOgg.h"
#include "SND_Main.h"
#include "CSlrFile.h"
#include "RES_ResourceManager.h"
#include "SYS_Threading.h"
#include "SYS_CFileSystem.h"
#include "CSlrString.h"
#include "pa_debugprint.h"

/// **** WRITE AUDIO TO DISK

//#define WRITE_AUDIO_OUT_TO_FILE

CSoundEngine *gSoundEngine = NULL;

#if defined(WRITE_AUDIO_OUT_TO_FILE)
FILE *fpMainAudioOutWriter;
#endif

OSStatus audioDeviceChangedCallbackFunction(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData)
{
	LOGA("audioDeviceChangedCallbackFunction");
	gSoundEngine->DefaultAudioDeviceChanged();
	return kAudioServicesNoError;
}

void SYS_InitSoundEngine()
{
	LOGA("SYS_InitSoundEngine");
	// setup change device notifications
	AudioObjectPropertyAddress runLoopAddress = {
		kAudioHardwarePropertyRunLoop,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};

	CFRunLoopRef runLoop = NULL;
	UInt32 size = sizeof(CFRunLoopRef);
	AudioObjectSetPropertyData(kAudioObjectSystemObject,
								&runLoopAddress, 0, NULL, size, &runLoop);
	
	AudioObjectPropertyAddress outputDeviceAddress = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMaster
	};
	
	AudioObjectAddPropertyListener(kAudioObjectSystemObject, &outputDeviceAddress, &audioDeviceChangedCallbackFunction, nil);
	//
	PaError             err = paNoError;

	PaUtil_SetDebugPrintFunction(MTEngine_PA_LOG_Callback);
	
	err = Pa_Initialize();
	if( err != paNoError )
	{
		SYS_FatalExit("SYS_InitSoundEngine failed: error=%s", Pa_GetErrorText(err));
	}
	gSoundEngine = new CSoundEngine();	
}

CSoundEngine::CSoundEngine()
{
	LOGA("CSoundEngine init, using %s", Pa_GetVersionText());
	
	audioEngineMutex = new CSlrMutex("CSoundEngine");
	
#if defined(WRITE_AUDIO_OUT_TO_FILE)
	char fpath[1024];
	sprintf(fpath, "%s/MTEngine-AudioOut.raw", gCPathToDocuments);
	
	fpMainAudioOutWriter = fopen(fpath, "wb");
	if (!fpMainAudioOutWriter)
	{
		SYS_FatalExit("CSoundEngine: opening MTEngine-AudioOut.raw for write failed");
	}
	
	LOGM("CSoundEngine: storing audio out to file %s", fpath);
#endif
	
	audioOutDeviceName = new CSlrString("Default");
	
	// debug print
	LOGA("--- Audio output devices (stereo):");
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

	LOGA("--- Audio output devices (mono):");
	outputParameters.channelCount = 1;                     // stereo output
	outputParameters.sampleFormat = paInt16;
	outputParameters.hostApiSpecificStreamInfo = NULL;
	
	numDevices = Pa_GetDeviceCount();
	
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
		SYS_FatalExit("No default audio output device detected, bad luck!");
	}
	
	LOGA("--- default output device: %d", deviceOutIndex);

	recordedData = NULL;
	isAudioSessionInitialized = false;
	isRecordingOn = false;
	isPlaybackOn = false;
	guiRecordingCallback = NULL;
	
	recordingFrequency = 44100;
	whoLocked = NULL;
	removeDC = false;
	
	this->isMuted = false;
	
	SND_MainInitialize();
}

CSoundEngine::~CSoundEngine()
{
}

static int getOneSampleSin()
{
	static float sinPosL = 0;	
	static float sinSpeedL = 0.003;
	static float sinChangeL = 0.000001;
	static float sinPosR = 0;	
	static float sinSpeedR = 0.02;
	static float sinChangeR = 0.00001;

	short chanL = (sin(sinPosL) * 650);
	short chanR = (sin(sinPosR) * 650);
	
	sinPosL += sinSpeedL;
	if (sinPosL > 1)
		sinPosL = -1;
	
	sinSpeedL += sinChangeL;
	
	if (sinSpeedL > 0.03 || sinSpeedL < 0.003)
		sinChangeL = -sinChangeL;
	
	sinPosR += sinSpeedR;
	if (sinPosR > 1)
		sinPosR = -1;
	
	sinSpeedR += sinChangeR;
	
	if (sinSpeedR > 0.03 || sinSpeedR < 0.003)
		sinChangeR = -sinChangeR;
	
	chanL = 0xFFFF - chanL;
	
	return ((chanR & 0x0000FFFF) << 16) | (chanL & 0x0000FFFF);
}

static int getOneSample()
{
	SYS_FatalExit("getOneSample()");
	/*
	if (xmAudioBufferPos >= xmAudioBufferLen)
	{
		// render one buffer
		pthread_mutex_lock(&gSoundEngine->xmPlayerMutex);	
		//LOGF("render");
		xmAudioBufferLen = gSoundEngine->xmPlayer->Render2(xmAudioBufferL, xmAudioBufferR, SOUND_BUFFER_SIZE);
		pthread_mutex_unlock(&gSoundEngine->xmPlayerMutex);					

		xmAudioBufferPos = 0;
	}

	int sample = ((xmAudioBufferR[xmAudioBufferPos] & 0x0000FFFF) << 16) | (xmAudioBufferL[xmAudioBufferPos] & 0x0000FFFF);
	xmAudioBufferPos++;*/
	
	return 0x00; //sample;
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
//	LOGA("playCallback");
	
	u32 len = framesPerBuffer * 4;
	int *mixBuffer = (int*)outputBuffer;
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
	
	
	int *outBuffer = mixBuffer;
		
	gSoundEngine->LockMutex("playCallback");
	
//	LOGD("SND_MainMixer: numSamples=%d", numSamples);
	SND_MainMixer(outBuffer, numSamples);

	gSoundEngine->UnlockMutex("playCallback");

#if defined(WRITE_AUDIO_OUT_TO_FILE)
	fwrite(outBuffer, numSamples, 4, fpMainAudioOutWriter);
#endif
	
//	LOGA("playCallback done");

	return paContinue;
}

i16 *stereoMixBufferForMonoPlayback = NULL;

static int playCallbackMono( const void *inputBuffer, void *outputBuffer,
						unsigned long framesPerBuffer,
						const PaStreamCallbackTimeInfo* timeInfo,
						PaStreamCallbackFlags statusFlags,
						void *userData )

{
//	LOGA("playCallbackMono");
	
	u32 len = framesPerBuffer * 4;
	int *mixBuffer = (int*)stereoMixBufferForMonoPlayback;
	int numSamples = framesPerBuffer;
	
//	LOGA("framesPerBuffer=%d len=%d mixBuffer=%x numSamples=%d", framesPerBuffer, len, mixBuffer, numSamples);
	
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
		//LOGA("isPlaybackOn=false, return");
		return paContinue;
	}
	
	
	int *stereoBuffer = mixBuffer;
	
	gSoundEngine->LockMutex("playCallbackMono");
	
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
	
	return paContinue;
}

void CSoundEngine::AllocateInputBuffers(UInt32 inNumberFrames)
{
    LOGA("CSoundEngine::AllocateInputBuffers: inNumberFrames = %d\n", inNumberFrames);
	
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
	
	this->LockMutex("CSoundEngine::EnumerateAvailableOutputDevices");

	bool wasPlayback = isPlaybackOn;
	bool wasRecording = isRecordingOn;

	this->StopAudioUnit();
	
	audioOutDevices->push_back(new CSlrString("Default"));
	
	PaStreamParameters outputParametersStereo;
	PaStreamParameters outputParametersMono;
	outputParametersStereo.channelCount = 2;                     // stereo output
	outputParametersStereo.sampleFormat = paInt16;
	outputParametersStereo.hostApiSpecificStreamInfo = NULL;

	outputParametersMono.channelCount = 1;
	outputParametersMono.sampleFormat = paInt16;
	outputParametersMono.hostApiSpecificStreamInfo = NULL;
	
	
	int numDevices;
	numDevices = Pa_GetDeviceCount();
	
	const PaDeviceInfo *deviceInfo;
	for(int i = 0; i < numDevices; i++)
	{
		deviceInfo = Pa_GetDeviceInfo( i );
		
		LOGD("... device #%d: '%s', out chans=%d", i, deviceInfo->name, deviceInfo->maxOutputChannels);
		outputParametersStereo.device = i;
		outputParametersStereo.suggestedLatency = deviceInfo->defaultLowOutputLatency;
		
		PaError err;
		err = Pa_IsFormatSupported( NULL, &outputParametersStereo, SOUND_SAMPLE_RATE );
		if( err == paFormatIsSupported )
		{
			LOGD("... OK stereo");
			audioOutDevices->push_back(new CSlrString(deviceInfo->name));
		}
		else
		{
			err = Pa_IsFormatSupported( NULL, &outputParametersMono, SOUND_SAMPLE_RATE );
			if( err == paFormatIsSupported )
			{
				LOGD("... OK mono");
				audioOutDevices->push_back(new CSlrString(deviceInfo->name));
			}
		}		
	}
	
	if (wasPlayback || wasRecording)
	{
		this->StartAudioUnit(wasPlayback, wasRecording, recordingFrequency);
	}
	
	this->UnlockMutex("CSoundEngine::EnumerateAvailableOutputDevices");
	
	LOGD("CSoundEngine::EnumerateAvailableOutputDevices finished");

	return audioOutDevices;
}

bool CSoundEngine::SetOutputAudioDevice(CSlrString *deviceName)
{
	LOGD("CSoundEngine::SetOutputAudioDevice");
	if (deviceName != this->audioOutDeviceName && this->audioOutDeviceName != NULL)
	{
		delete audioOutDeviceName;
	}
	
	this->audioOutDeviceName = new CSlrString(deviceName);
	char *strDeviceName = deviceName->GetStdASCII();
	
	LOGD("... SetOutputAudioDevice: device name='%s'", strDeviceName);
	
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
		PaStreamParameters outputParametersStereo;
		PaStreamParameters outputParametersMono;
		outputParametersStereo.channelCount = 2;                     // stereo output
		outputParametersStereo.sampleFormat = paInt16;
		outputParametersStereo.hostApiSpecificStreamInfo = NULL;

		outputParametersMono.channelCount = 1;
		outputParametersMono.sampleFormat = paInt16;
		outputParametersMono.hostApiSpecificStreamInfo = NULL;

		int numDevices;
		numDevices = Pa_GetDeviceCount();
		
		const PaDeviceInfo *deviceInfo;
		for(int i = 0; i < numDevices; i++)
		{
			deviceInfo = Pa_GetDeviceInfo( i );
			LOGD("... device #%d: '%s'", i, deviceInfo->name);
			outputParametersStereo.device = i;
			outputParametersStereo.suggestedLatency = deviceInfo->defaultLowOutputLatency;
			
			PaError err;
			err = Pa_IsFormatSupported( NULL, &outputParametersStereo, SOUND_SAMPLE_RATE );
			if( err == paFormatIsSupported )
			{
				if (!strcmp(deviceInfo->name, strDeviceName))
				{
					deviceFound = true;
					deviceOutIndex = i;
				}
			}
			else
			{
				outputParametersMono.device = i;
				outputParametersMono.suggestedLatency = deviceInfo->defaultLowOutputLatency;
				err = Pa_IsFormatSupported( NULL, &outputParametersMono, SOUND_SAMPLE_RATE );
				if( err == paFormatIsSupported )
				{
					if (!strcmp(deviceInfo->name, strDeviceName))
					{
						deviceFound = true;
						deviceOutIndex = i;
					}
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
					outputParametersStereo.device = deviceId;
					outputParametersStereo.suggestedLatency = deviceInfo->defaultLowOutputLatency;
					
					PaError err;
					err = Pa_IsFormatSupported( NULL, &outputParametersStereo, SOUND_SAMPLE_RATE );
					if( err == paFormatIsSupported )
					{
						deviceFound = true;
						deviceOutIndex = deviceId;
					}
					else
					{
						err = Pa_IsFormatSupported( NULL, &outputParametersMono, SOUND_SAMPLE_RATE );
						if( err == paFormatIsSupported )
						{
							deviceFound = true;
							deviceOutIndex = deviceId;
						}
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

void CSoundEngine::StartAudioUnit(bool isPlayback, bool isRecording, int recordingFrequency)
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
		SYS_FatalExit("Audio is already playing, you need to stop audio streams first");
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
			if (stereoMixBufferForMonoPlayback == NULL)
			{
				stereoMixBufferForMonoPlayback = new i16[SOUND_BUFFER_SIZE * 2 + 2];
			}
			outputParameters.channelCount = 1;                     // mono output
			
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
			const PaHostErrorInfo *hostErrorInfo = Pa_GetLastHostErrorInfo();
			LOGError("PaHostErrorInfo: %d %s", hostErrorInfo->errorCode, hostErrorInfo->errorText);
			SYS_FatalExit("Opening output stream failed: error=%s", Pa_GetErrorText(err));
		}
		
		LOGA("Pa_StartStream");
		err = Pa_StartStream( streamOutput );
        if( err != paNoError )
		{
			const PaHostErrorInfo *hostErrorInfo = Pa_GetLastHostErrorInfo();
			LOGError("PaHostErrorInfo: %d %s", hostErrorInfo->errorCode, hostErrorInfo->errorText);
			SYS_FatalExit("Starting output stream failed error=%s", Pa_GetErrorText(err));
		}
		
		LOGA("Audio output stream opened, device=%s", deviceInfo->name);
	}
	
	if (isRecording)
	{
		LOGA("opening input stream");
		inputParameters.device = Pa_GetDefaultInputDevice();

		if (inputParameters.device == paNoDevice)
		{
			SYS_FatalExit("No default audio input device detected, bad luck!");
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
			const PaHostErrorInfo *hostErrorInfo = Pa_GetLastHostErrorInfo();
			LOGError("PaHostErrorInfo: %d %s", hostErrorInfo->errorCode, hostErrorInfo->errorText);
			SYS_FatalExit("Starting input+output stream failed");
		}
		
		LOGA("input stream opened");
	}
	
	this->isRecordingOn = isRecording;
	this->isPlaybackOn = isPlayback;
	
	LOGA("starting AudioUnit done");
}

void CSoundEngine::StopAudioUnit()
{
	LOGA("StopAudioUnit");
	
	this->LockMutex("CSoundEngine::StopAudioUnit");
	
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
	
	this->UnlockMutex("CSoundEngine::StopAudioUnit");
	
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
		const PaHostErrorInfo *hostErrorInfo = Pa_GetLastHostErrorInfo();
		LOGError("PaHostErrorInfo: %d %s", hostErrorInfo->errorCode, hostErrorInfo->errorText);
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
	
	LOGA("CSoundEngine::DefaultAudioDeviceChanged done");
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


#define USE_FAKE_CALLBACK
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
	
	
	gSoundEngine->LockMutex("playCallback");
	
	SND_MainMixer(outBuffer, numSamples);
	
	gSoundEngine->UnlockMutex("playCallback");
	
    return;
}
#endif

void CSoundEngine::LockMutex(char *_whoLocked)
{
//	LOGD("CSoundEngine::LockMutex: %s", _whoLocked);
//	if (this->whoLocked != NULL)
//	{
//		LOGD("already locked by %s", this->whoLocked);
//	}
	
	audioEngineMutex->Lock();
//	this->whoLocked = _whoLocked;
	
//	LOGD("CSoundEngine::LockMutex: %s success", _whoLocked);
}

void CSoundEngine::UnlockMutex(char *_whoLocked)
{
//	LOGD("CSoundEngine::UnlockMutex: %s", _whoLocked);
//	if (this->whoLocked != NULL)
//	{
//		LOGD("was locked by %s", this->whoLocked);
//	}
	
	audioEngineMutex->Unlock();
	
//	this->whoLocked = NULL;
//	LOGD("CSoundEngine::UnlockMutex: %s success", _whoLocked);
}

void CAudioRecordingCallback::RecordingCallback(byte *buffer, UInt32 numBytes)
{
}

NSString *OSStatusToStr(OSStatus st)
{
    switch (st) {
        case kAudioFileUnspecifiedError:
            return @"kAudioFileUnspecifiedError";
			
        case kAudioFileUnsupportedFileTypeError:
            return @"kAudioFileUnsupportedFileTypeError";
			
        case kAudioFileUnsupportedDataFormatError:
            return @"kAudioFileUnsupportedDataFormatError";
			
        case kAudioFileUnsupportedPropertyError:
            return @"kAudioFileUnsupportedPropertyError";
			
        case kAudioFileBadPropertySizeError:
            return @"kAudioFileBadPropertySizeError";
			
        case kAudioFilePermissionsError:
            return @"kAudioFilePermissionsError";
			
        case kAudioFileNotOptimizedError:
            return @"kAudioFileNotOptimizedError";
			
        case kAudioFileInvalidChunkError:
            return @"kAudioFileInvalidChunkError";
			
        case kAudioFileDoesNotAllow64BitDataSizeError:
            return @"kAudioFileDoesNotAllow64BitDataSizeError";
			
        case kAudioFileInvalidPacketOffsetError:
            return @"kAudioFileInvalidPacketOffsetError";
			
        case kAudioFileInvalidFileError:
            return @"kAudioFileInvalidFileError";
			
        case kAudioFileOperationNotSupportedError:
            return @"kAudioFileOperationNotSupportedError";
			
//        case kAudioFileNotOpenError:
//            return @"kAudioFileNotOpenError";
//			
//        case kAudioFileEndOfFileError:
//            return @"kAudioFileEndOfFileError";
//			
//        case kAudioFilePositionError:
//            return @"kAudioFilePositionError";
//			
//        case kAudioFileFileNotFoundError:
//            return @"kAudioFileFileNotFoundError";
			
        default:
            return @"unknown error";
    }
}

void SYS_CheckOSStatus(OSStatus *status)
{
	if ((*status) != noErr)
	{
		LOGA("ERROR: OSStatus %d", *status);
		/*
		 char *err1 = GetMacOSStatusErrorString(*status);
		 LOGF(DBGLVL_MAIN, err1);
		 char *err2 = GetMacOSStatusCommentString(*status);
		 LOGF(DBGLVL_MAIN, err2);
		 */
		
		NSString *strError = OSStatusToStr(*status);
		LOGA(strError);

		
		// fuckin apple bugs!! never fatal!
		SYS_FatalExit("Fatal Exit");
	}
	return;
}

void MTEngine_PA_LOG_Callback(const char *str)
{
	LOGA(str);
}
