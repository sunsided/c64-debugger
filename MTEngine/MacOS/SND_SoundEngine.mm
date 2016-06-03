// http://atastypixel.com/blog/using-remoteio-audio-unit/
// http://idimp.googlecode.com/
// http://developer.apple.com/iphone/library/documentation/audio/conceptual/AudioSessionProgrammingGuide/Cookbook/Cookbook.html

// TODO: add JACKiOS support: http://www.crudebyte.com/jack-ios/sdk/doc/getting_started.html

#include "SYS_Defs.h"
#include "SND_SoundEngine.h"
#include "CSlrMusicFileOgg.h"
#include "SND_Main.h"
#include "CSlrFile.h"
#include "RES_ResourceManager.h"
#include "SYS_Threading.h"

class CSlrMusicFileOgg;

CSoundEngine *gSoundEngine = NULL;


void SYS_InitSoundEngine()
{
	PaError             err = paNoError;

	err = Pa_Initialize();	
	if( err != paNoError )
	{
		SYS_FatalExit("SYS_InitSoundEngine failed");
	}
	gSoundEngine = new CSoundEngine();	
}

CSoundEngine::CSoundEngine()// :
//	mIsRunning(false),
//	mIsInitialized(false),
//	mCurrentPacket(0)
{
	LOGA("CSoundEngine init");
	
	audioEngineMutex = new CSlrMutex();
	
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
	pthread_mutex_destroy(&xmPlayerMutex);
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
	//LOGA("SND_PlaybackCallback");
	
	u32 len = framesPerBuffer * 4;
	int *mixBuffer = (int*)outputBuffer;
	int numSamples = framesPerBuffer;
	
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
	
	SND_MainMixer(outBuffer, numSamples);

	gSoundEngine->UnlockMutex("playCallback");

	//LOGA("SND_PlaybackCallback done");

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

void CSoundEngine::ResetAudioUnit(bool isRecordingOn)
{
	LOGTODO("CSoundEngine::ResetAudioUnit");
	//LockMutex();
	//StopAudioUnit();
	//StartAudioUnit(isRecordingOn);
	//UnlockMutex();
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
		SYS_FatalExit("TODO: already init");
	}
	
	PaStreamParameters  inputParameters, outputParameters;
	u32 framesPerBuffer = 512;
	
	if (isPlayback)
	{
		LOGA("opening output stream");
		outputParameters.device = Pa_GetDefaultOutputDevice(); // default output device
		LOGTODO("TODO: check paNoDevice");
		if (outputParameters.device == paNoDevice) 
		{
			SYS_FatalExit("No output device");
		}
		outputParameters.channelCount = 2;                     // stereo output
		outputParameters.sampleFormat = paInt16;
		outputParameters.suggestedLatency = 
			Pa_GetDeviceInfo( outputParameters.device )->defaultLowOutputLatency;
		outputParameters.hostApiSpecificStreamInfo = NULL;
		
		LOGA("Pa_OpenStream");
		err = Pa_OpenStream(
							&streamOutput,
							NULL, /* no input */
							&outputParameters,
							SOUND_SAMPLE_RATE,
							512, //SOUND_BUFFER_SIZE / SOUND_SAMPLE_RATE,
							paClipOff,      // we won't output out of range samples so don't bother clipping them
							playCallback,
							NULL );

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

		LOGA("output stream opened");
	}
	
	if (isRecording)
	{
		LOGA("opening input stream");
		inputParameters.device = Pa_GetDefaultInputDevice();
		LOGTODO("TODO: check paNoDevice");
		if (inputParameters.device == paNoDevice) 
		{
			SYS_FatalExit("No input device");
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

//void CSoundEngine::AllocMP3(NSString *fileName)
//{
//	/*
//	NSString *path = [[NSBundle mainBundle] pathForResource:@"mjus-v1" ofType:@"mp3"];
//	NSData *musicData = [[NSData alloc] initWithContentsOfFile:path];
//	NSError* error = nil;
//	avAudioPlayer = [[AVAudioPlayer alloc] initWithData:musicData error:&error];
//	if (error)
//	{
//		NSLog(@"Error with initWithData: %@", [error localizedDescription]);
//	}*/
//
//	
//	NSError* error = nil;
//	avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: fileName ofType: @"mp3"]] error:&error];
//	if (error)
//	{
//		NSLog(@"Error with initWithData: %@", [error localizedDescription]);
//	}
//	
//	avAudioPlayer.numberOfLoops = -1;		
//	[avAudioPlayer prepareToPlay];	
//}
//
//void CSoundEngine::PlayMP3()
//{
//	if (avAudioPlayer == nil)
//		return;
//	
//	// when you want to play the file	
//    [avAudioPlayer play];
//
//}
//
//void CSoundEngine::StopMP3()
//{
//	LOGD("CSoundEngine::StopMP3");
//	if (avAudioPlayer == nil)
//		return;
//	
//    [avAudioPlayer stop];
//}

OggVorbis_File *CSoundEngine::LoadOGG(char *fileName)
{
	pthread_mutex_lock(&gSoundEngine->oggPlayerMutex);	

	OggVorbis_File *retOggFile;
	retOggFile = (OggVorbis_File *)malloc(sizeof(OggVorbis_File));
	
	char resNameNoPath[2048];
	int i = strlen(fileName)-1;
	for (  ; i >= 0; i--)
	{
		if (fileName[i] == '/')
			break;
	}
	
	int j = 0;
	while(true)
	{
		if (fileName[i] == '.')
		{
			resNameNoPath[j] = '\0';
			break;			
		}
		resNameNoPath[j] = fileName[i];
		if (fileName[i] == '\0')
			break;
		j++;
		i++;
	}
	
	NSString *nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
	NSString *path = [[NSBundle mainBundle] pathForResource:nsFileName ofType:@"ogg"];
	
	FILE *fp = fopen([path fileSystemRepresentation], "rb");
	if(ov_open(fp, retOggFile, NULL, 0) < 0) 
	{
		SYS_FatalExit("PlayOGG: input does not appear to be an Ogg bitstream");
	}
	
	pthread_mutex_unlock(&gSoundEngine->oggPlayerMutex);	
	
	return retOggFile;
}

void CSoundEngine::PlayOGG(char *fileName)
{
	pthread_mutex_lock(&gSoundEngine->oggPlayerMutex);	
	
	oggFile = (OggVorbis_File *)malloc(sizeof(OggVorbis_File));
	
	char resNameNoPath[2048];
	int i = strlen(fileName)-1;
	for (  ; i >= 0; i--)
	{
		if (fileName[i] == '/')
			break;
	}
	
	int j = 0;
	while(true)
	{
		if (fileName[i] == '.')
		{
			resNameNoPath[j] = '\0';
			break;			
		}
		resNameNoPath[j] = fileName[i];
		if (fileName[i] == '\0')
			break;
		j++;
		i++;
	}
	
	NSString *nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
	NSString *path = [[NSBundle mainBundle] pathForResource:nsFileName ofType:@"ogg"];
	
	FILE *fp = fopen([path fileSystemRepresentation], "rb");
	if(ov_open(fp, oggFile, NULL, 0) < 0) 
	{
		SYS_FatalExit("PlayOGG: input does not appear to be an Ogg bitstream");
	}
	
	pthread_mutex_unlock(&gSoundEngine->oggPlayerMutex);	
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
