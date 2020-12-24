
#include "C64D_Version.h"

#include <stdint.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <sstream>
#include <fstream>

#include "M_Circlebuf.h"

// this is based on libretro integration
// https://docs.libretro.com/specs/api/

#if defined(RUN_NES)
#include "NstApiMachine.hpp"
#include "NstMachine.hpp"
#include "NstApiEmulator.hpp"
#include "NstApiVideo.hpp"
#include "NstApiCheats.hpp"
#include "NstApiSound.hpp"
#include "NstApiInput.hpp"
#include "NstApiCartridge.hpp"
#include "NstApiUser.hpp"
#include "NstApiFds.hpp"
#include "NstMachine.hpp"
#endif

#include "C64D_Version.h"
#include "NesWrapper.h"
#include "NesDebugInterface.h"
#include "CNesAudioChannel.h"
#include "VID_Main.h"
#include "SYS_Main.h"
#include "SND_Main.h"
#include "SYS_Types.h"
#include "SYS_CommandLine.h"
#include "CGuiMain.h"
#include "CViewC64.h"
#include "CViewMemoryMap.h"
#include "SYS_Threading.h"
#include "SND_SoundEngine.h"
#include "CSnapshotsManager.h"
#include "CViewNesStateAPU.h"
#include <string.h>

volatile int nesd_debug_mode;

#if defined(RUN_NES)

#define NES_NTSC_PAR ((Api::Video::Output::WIDTH - (overscan_h ? 16 : 0)) * (8.0 / 7.0)) / (Api::Video::Output::HEIGHT - (overscan_v ? 16 : 0))
#define NES_PAL_PAR ((Api::Video::Output::WIDTH - (overscan_h ? 16 : 0)) * (2950000.0 / 2128137.0)) / (Api::Video::Output::HEIGHT - (overscan_v ? 16 : 0))
#define NES_4_3_DAR (4.0 / 3.0);

using namespace Nes;

static u32 *video_buffer = NULL;

static i16 audio_buffer[(SOUND_SAMPLE_RATE / 50)];
static i16 audio_stereo_buffer[2 * (SOUND_SAMPLE_RATE / 50)];
static Api::Emulator emulator;
static Api::Machine *machine;
static Api::Fds *fds;
static char g_basename[256];
static char g_rom_dir[256];
static char *g_save_dir = NULL;
static char samp_dir[256];
static unsigned blargg_ntsc;
static bool fds_auto_insert;
static bool overscan_v;
static bool overscan_h;
static unsigned aspect_ratio_mode;
static unsigned tpulse;

i16 video_width = Api::Video::Output::WIDTH;
size_t pitch;

static Api::Video::Output *videoOutput = NULL;
static Api::Sound::Output *audioOutput = NULL;
static Api::Input::Controllers *input = NULL;
static unsigned input_type[4];
static Api::Machine::FavoredSystem favsystem;

static void *sram;
static unsigned long sram_size;
static bool is_pal;
static bool dbpresent;
static byte custpal[64*3];
static char slash;

#include "NesPalette.h"

void nes_draw_crosshair(int x, int y);
void nesd_set_defaults();
void NST_CALLBACK nes_file_io_callback(void*, Api::User::File &file);

static i16 *audio_sdl_buf = NULL;
static volatile int audio_sdl_inptr = 0;
static volatile int audio_sdl_outptr = 0;
static volatile int audio_sdl_full = 0;
static int audio_sdl_len = 0;

u16 currentNesPC = 0;

CSlrMutex *audioBufferMutex;

bool nst_pal() {
	Api::Machine machine(emulator);
	bool isPal = machine.GetMode() == Api::Machine::PAL;
//	LOGD("nst_pal=%d", isPal);
	return isPal;
}

bool NestopiaUE_Initialize()
{
	LOGD("NestopiaUE_Initialize");
	// this is based on libretro port
	
	audioBufferMutex = new CSlrMutex("nes-audio-buffer");
	
	video_buffer = (u32*)malloc(Api::Video::Output::NTSC_WIDTH * Api::Video::Output::HEIGHT * sizeof(u32));
	
	machine = new Api::Machine(emulator);
	input = new Api::Input::Controllers;
	Api::User::fileIoCallback.Set(nes_file_io_callback, 0);

	char db_path[256];
	char *romPath = SYS_GetCharBuf();

#if defined(WIN32)
	sprintf(db_path, ".\\NstDatabase.xml");
	sprintf(romPath, ".\\disksys.rom");
	sprintf(samp_dir, ".");
#elif defined(LINUX)
	sprintf(db_path, "./NstDatabase.xml");
	sprintf(romPath, "./disksys.rom");
	sprintf(samp_dir, ".");
#else
	sprintf(db_path, "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/NstDatabase.xml");
	sprintf(romPath, "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/disksys.rom");
	sprintf(samp_dir, "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes");
	//	sprintf(db_path, "NstDatabase.xml");
	//	sprintf(romPath, "disksys.rom");
	//	sprintf(samp_dir, "nes");
#endif
	LOGTODO("ROM path is %s", romPath);
	
	LOGM("NstDatabase.xml path: %s", db_path);
	
	Api::Cartridge::Database database(emulator);
	std::ifstream *db_file = new std::ifstream(db_path, std::ifstream::in|std::ifstream::binary);
	
	if (db_file->is_open())
	{
		database.Load(*db_file);
		database.Enable(true);
		dbpresent = true;
	}
	else
	{
		LOGError("NstDatabase.xml required to detect region and some mappers");
		delete db_file;
		dbpresent = false;
	}

	fds = new Api::Fds(emulator);
	if (!fds)
	{
		SYS_FatalExit("Api::Fds failed");
	}
	
	std::ifstream *fds_bios_file = new std::ifstream(romPath, std::ifstream::in|std::ifstream::binary);
	
	if (fds_bios_file->is_open())
	{
		fds->SetBIOS(fds_bios_file);
	}
	else
	{
		delete fds_bios_file;
		fds_bios_file = NULL;
		LOGError("Nestopia: missing disksys.rom at %s", romPath);
	}
	SYS_ReleaseCharBuf(romPath);
	
	LOGTODO("set g_save_dir");
	
	is_pal = false;
	nesd_set_defaults();
	
//	// Set the file paths
//	nst_set_paths(filename);
	
//	if (nst_find_patch(patchname, sizeof(patchname), filename)) { // Load with a patch if there is one
//		std::ifstream pfile(patchname, std::ios::in|std::ios::binary);
//		Machine::Patch patch(pfile, false);
//		result = machine.Load(file, nst_default_system(), patch);
//	}
//	else {
	
//	Api::Video ivideo(emulator);
//	ivideo.SetSharpness(Api::Video::DEFAULT_SHARPNESS_RGB);
//	ivideo.SetColorResolution(Api::Video::DEFAULT_COLOR_RESOLUTION_RGB);
//	ivideo.SetColorBleed(Api::Video::DEFAULT_COLOR_BLEED_RGB);
//	ivideo.SetColorArtifacts(Api::Video::DEFAULT_COLOR_ARTIFACTS_RGB);
//	ivideo.SetColorFringing(Api::Video::DEFAULT_COLOR_FRINGING_RGB);
//	
//	Api::Video::RenderState state;
//	state.filter = Api::Video::RenderState::FILTER_NONE;
//	state.width = 256;
//	state.height = 240;
//	state.bits.count = 32;
//	state.bits.mask.r = 0x000000ff;
//	state.bits.mask.g = 0x0000ff00;
//	state.bits.mask.b = 0x00ff0000;
//	ivideo.SetRenderState(state);
//	
//	Api::Sound isound(emulator);
//	isound.SetSampleBits(16);
//	isound.SetSampleRate(SOUND_SAMPLE_RATE);
//	isound.SetSpeaker(Api::Sound::SPEAKER_MONO);
	
	///
	unsigned numSamples = nst_pal() ? (double)SOUND_SAMPLE_RATE / 50.0 : (double)SOUND_SAMPLE_RATE / 60.0;
	audio_sdl_len = numSamples*2;
	
	audio_sdl_inptr = audio_sdl_outptr = audio_sdl_full = 0;
	
	audio_sdl_buf = (i16*)malloc(sizeof(i16)*audio_sdl_len);
	memset(audio_sdl_buf, 0, sizeof(i16)*audio_sdl_len);
	
	///
	
	Api::Input(emulator).AutoSelectController(0);
	Api::Input(emulator).AutoSelectController(1);
	
	videoOutput = new Api::Video::Output(video_buffer, video_width * sizeof(u32));

	nesd_set_defaults();
	
	nesd_sound_init();
	
	return true;
}

bool NestopiaUE_PostInitialize()
{
	//
#if defined(WIN32)
	char *defaultRomPath = ".\\default.nes";
#elif defined(LINUX)
	char *defaultRomPath = "./default.nes";
#else
	char *defaultRomPath = "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/default.nes";
//	char *defaultRomPath = "default.nes";
	//	char *defaultRomPath = "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/contra.nes";
	//	char *defaultRomPath = "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/mario.nes";
	//	char *defaultRomPath = "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/alien3.nes";
#endif
	
	nesd_insert_cartridge(defaultRomPath);
	
	LOGM("[Nestopia]: Machine is %s.\n", nst_pal() ? "PAL" : "NTSC");
	
	return true;
}

bool nesd_is_pal()
{
	return nst_pal();
}

double nesd_get_cpu_clock_frquency()
{
	if (nst_pal())
	{
		return 1662607.0;
	}
	
	return 1789773.0;
}


bool nesd_insert_cartridge(char *filePath)
{
	debugInterfaceNes->LockMutex();
	nesd_sound_lock("nesd_insert_cartridge");
	
	machine->Unload();
		
	std::ifstream file(filePath, std::ios::in|std::ios::binary);
	
	if (machine->Load(file, favsystem))
	{
		LOGError("Nestopia: Load failed");
		nesd_sound_unlock("nesd_insert_cartridge");
		debugInterfaceNes->UnlockMutex();
		return false;
	}

	nesd_set_defaults();

	machine->Power(true);
	
	if (fds_auto_insert && machine->Is(Nes::Api::Machine::DISK))
	{
		fds->InsertDisk(0, 0);
	}
	
	nesd_sound_unlock("nesd_insert_cartridge");
	debugInterfaceNes->UnlockMutex();
	return true;
}

// sound sync is ugly, needs proper circular buffer.
// threaded frame render sync is queueing samples, meaning sync is too fast... but why? see NestopiaUE_Run

struct circlebuf audioBufferCircle;
#define MAX_NESD_AUDIO_BUFFER_SIZE 	(SOUND_SAMPLE_RATE * sizeof(i16))

void nesd_sound_init()
{
	nesd_sound_lock("nesd_sound_init");
	if (debugInterfaceNes->audioChannel == NULL)
	{
		debugInterfaceNes->audioChannel = new CNesAudioChannel(debugInterfaceNes);
		SND_AddChannel(debugInterfaceNes->audioChannel);
	}
	
	debugInterfaceNes->audioChannel->bypass = false;
	
	circlebuf_init(&audioBufferCircle);
	circlebuf_reserve(&audioBufferCircle, (int)((float)SOUND_SAMPLE_RATE*1.25f) * sizeof(i16));
	nesd_sound_unlock("nesd_sound_init");
}

void nesd_sound_destroy()
{
	circlebuf_free(&audioBufferCircle);
}

void nesd_audio_write(i16 *pbuf, int numSamples)
{
//	LOGD("nesd_audio_write %d samples", numSamples);
	nesd_sound_lock("nesd_audio_write");

//	LOGD("nesd_audio_write: adding %d samples", numSamples);
	circlebuf_push_back(&audioBufferCircle, pbuf, numSamples * sizeof(i16));

	
	nesd_sound_unlock("nesd_audio_write");
//	LOGD("nesd_audio_write done");
}

int audio_sdl_bufferspace(void);

void nesd_audio_callback(i16 *monoBuffer, int numSamples)
{
//	LOGD("nesd_audio_callback: audioBuffer.size=%d numSamples=%d", audioBuffer.size(), numSamples);

	i16 *s = (i16*)monoBuffer;
	
	int lostBuffers = 0;
	nesd_sound_lock("nesd_audio_callback");
	
	// check if we have too much audio in the buffer (more than a second)
	if (audioBufferCircle.size > MAX_NESD_AUDIO_BUFFER_SIZE)
	{
		audioBufferCircle.start_pos = 0;
		audioBufferCircle.end_pos = 0;
	}
	
	while (++lostBuffers < 2)
	{
		u32 availableSamples = audioBufferCircle.size * sizeof(i16);
		if (availableSamples < numSamples)
		{
			nesd_sound_unlock("nesd_audio_callback loop");
//			LOGD("nesd_audio_callback: sleep audioBuffer.size=%d", audioBuffer.size());
			SYS_Sleep(20);
			nesd_sound_lock("nesd_audio_callback loop");
			continue;
		}
	}
	
	if (audioBufferCircle.size > numSamples * sizeof(i16))
	{
		circlebuf_pop_front(&audioBufferCircle, s, numSamples * sizeof(i16));
	}
	else
	{
//		LOGD("nesd_audio_callback: buffer underrun");
		for (int i = 0; i < numSamples; i++)
		{
			s[i] = 0;
		}
	}
	
	nesd_sound_unlock("nesd_audio_callback");
	
	// debug: synced audio & emulation version below:
//	for (int i = 0; i < numSamples; i++)
//	{
//		if (audioBuffer.empty())
//		{
////			LOGWarning("audioBuffer.empty()");
////			debugInterfaceNes->LockMutex();
//			
//			emulator.Execute(video, audio, input);
//			
//			unsigned numSamples = nst_pal() ? (double)SOUND_SAMPLE_RATE / 50.0 : (double)SOUND_SAMPLE_RATE / 60.0;
//			nesd_audio_write(audio_buffer, numSamples);
////			previous = SYS_GetCurrentTimeInMillis();
////			debugInterfaceNes->UnlockMutex();
//		}
//		s[i] = audioBuffer.front();
//		audioBuffer.pop_front();
//	}
	
}

int audio_sdl_bufferspace(void)
{
	//	LOGD("soundsdl: sdl_bufferspace");
	
	int amount;
	int ret;
	
	if (audio_sdl_full)
	{
		amount = audio_sdl_len;
	}
	else
	{
		amount = audio_sdl_inptr - audio_sdl_outptr;
	}
	
	if (amount < 0)
	{
		amount += audio_sdl_len;
	}
	
	ret = audio_sdl_len - amount;
	
	//	LOGD("sdl_bufferspace ret=%d", ret);
	return ret;
}

bool nesd_finished = false;

double previous;
double lag;

void nesd_reset_sync()
{
	previous = SYS_GetCurrentTimeInMillis();
	lag = 0;
}

// TODO: add synced events (i.e. reset, insert rom, ...)

bool NestopiaUE_Run()
{
	LOGM("NestopiaUE_Run()");
	
	previous = SYS_GetCurrentTimeInMillis();
	
//	double t0 = SYS_GetCurrentTimeInMillis();

	while(!nesd_finished)
	{
		double current = SYS_GetCurrentTimeInMillis();
		double desiredTime = nst_pal() ? 1000.0 / 50.0 : 1000.0 / 60.0;

		double elapsed = current - previous;
		
		previous = current;
		lag += elapsed;

//		unsigned numSamples = nst_pal() ? (double)SOUND_SAMPLE_RATE / 50.0 : (double)SOUND_SAMPLE_RATE / 60.0;

//		LOGD("numSamples 1 = %d", numSamples);
		
		if (lag >= desiredTime)
		{
			while (lag >= desiredTime)
			{

				//		update_input();
				
//						LOGD("NestopiaUE_Run: emulator.Execute");
				
				double framerate = nst_pal() ? (60.0 / 6.0) * 5.0 : 60.0;
				//
				
				unsigned numSamples = (double)SOUND_SAMPLE_RATE / framerate;

//				LOGD("numSamples 2 = %d", numSamples);

				audioOutput->samples[0] = audio_buffer;
				audioOutput->length[0] = SOUND_SAMPLE_RATE / framerate;

//				double t1 = SYS_GetCurrentTimeInMillis();
//				LOGD("t = %f desired=%f", t1 - t0, desiredTime);
//				debugInterfaceNes->LockMutex();
				emulator.Execute(videoOutput, audioOutput, input);
//				debugInterfaceNes->UnlockMutex();

//				t0 = t1;
				
				//		if (Api::Input(emulator).GetConnectedController(1) == 5)
				//			draw_crosshair(crossx, crossy);
//

//				for (unsigned i = 0; i < numSamples; i++)
//					audio_stereo_buffer[(i << 1) + 0] = audio_stereo_buffer[(i << 1) + 1] = audio_buffer[i];
//				audio_batch_cb(audio_stereo_buffer, numSamples);

				nesd_audio_write(audio_buffer, numSamples);
				
				//
				//		bool updated = false;
				//		if (environ_cb(RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE, &updated) && updated)
				//		{
				//			check_variables();
				//			delete video;
				//			video = 0;
				//			video = new Api::Video::Output(video_buffer, video_width * sizeof(uint32_t));
				//		}
				
				//		// Absolute mess of inline if statements...
				//		int dif = blargg_ntsc ? 18 : 8;
				//
				//		video_cb(video_buffer + (overscan_v ? ((overscan_h ? dif : 0) + (blargg_ntsc ? Api::Video::Output::NTSC_WIDTH : Api::Video::Output::WIDTH) * 8) : (overscan_h ? dif : 0) + 0),
				//				 video_width - (overscan_h ? 2 * dif : 0),
				//				 Api::Video::Output::HEIGHT - (overscan_v ? 16 : 0),
				//				 pitch);
				
				
				lag -= desiredTime;
			}
			
			
			////////////////
			// TODO: MOVE THIS TO REFRESH SCREEN AND COPY SCREEN AFTER FRAME / PPU IS COMPLETED
			// TODO: ADD CODE TO REFRESH SCREEN TILL CURRENT RASTER POSITION CYCLE
			
			// update screen
			debugInterfaceNes->LockRenderScreenMutex();
			
			int dif = blargg_ntsc ? 18 : 8;
			
			u8 *screenBuffer = (u8*) video_buffer + (overscan_v ? ((overscan_h ? dif : 0) + (blargg_ntsc ? Api::Video::Output::NTSC_WIDTH : Api::Video::Output::WIDTH) * 8) : (overscan_h ? dif : 0) + 0);
			
			// dest screen width is 512*supersampling
			
			uint8 *srcScreenPtr = screenBuffer;
			uint8 *destScreenPtr = (uint8 *)debugInterfaceNes->screenImage->resultData;
			
			int screenWidth = video_width - (overscan_h ? 2 * dif : 0);
			int screenHeight = Api::Video::Output::HEIGHT - (overscan_v ? 16 : 0);

			int superSample = debugInterfaceNes->screenSupersampleFactor;
			
			if (superSample == 1)
			{
				for (int y = 0; y < screenHeight; y++)
				{
					uint8 *srcPtr = srcScreenPtr;
					uint8 *destPtr = destScreenPtr;
					
					for (int x = 0; x < screenWidth; x++)
					{
						*destPtr++ = *srcPtr++;
						*destPtr++ = *srcPtr++;
						*destPtr++ = *srcPtr++;
						*destPtr++ = 255; srcPtr++;
					}
					
					srcScreenPtr += pitch;
					destScreenPtr += 512*4;
				}
			}
			else
			{
				for (int y = 0; y < screenHeight; y++)
				{
					for (int j = 0; j < superSample; j++)
					{
						uint8 *pScreenPtrSrc = srcScreenPtr;
						uint8 *pScreenPtrDest = destScreenPtr;
						
						for (int x = 0; x < screenWidth; x++)
						{
							u8 r = *pScreenPtrSrc++;
							u8 g = *pScreenPtrSrc++;
							u8 b = *pScreenPtrSrc++;
							pScreenPtrSrc++;
							for (int i = 0; i < superSample; i++)
							{
								*pScreenPtrDest++ = r;
								*pScreenPtrDest++ = g;
								*pScreenPtrDest++ = b;
								*pScreenPtrDest++ = 255;
							}
						}
						
						destScreenPtr += (512)*superSample*4;
					}
					
					srcScreenPtr += pitch;
				}

			}
			
			debugInterfaceNes->UnlockRenderScreenMutex();

			debugInterfaceNes->DoFrame();			
		}
		else
		{
			long s = desiredTime - lag; // - 2;
			
			if (s > 0)
			{
				SYS_Sleep(s);
			}
		}
	}
	
	LOGM("NestopiaUE_Run finished");
	return true;
}

void NestopiaUE_Unload()
{
	if (machine)
	{
		machine->Unload();
		
		if (machine->Is(Nes::Api::Machine::DISK))
		{
			if (fds)
				delete fds;
			fds = 0;
		}
		
		delete machine;
	}
	
	if (videoOutput)
		delete videoOutput;
	if (audioOutput)
		delete audioOutput;
	if (input)
		delete input;
	
	machine = NULL;
	videoOutput = NULL;
	audioOutput = NULL;
	input   = 0;
	
	sram = 0;
	sram_size = 0;
	
	free(video_buffer);
	video_buffer = NULL;
}

// save state
CByteBuffer *nesd_store_state()
{
	debugInterfaceNes->LockMutex();
	
	std::stringstream ss;
	if (machine->SaveState(ss, Api::Machine::NO_COMPRESSION))
		return NULL;
	
	std::string state = ss.str();

	CByteBuffer *byteBuffer = new CByteBuffer(state.size());
	std::copy(state.begin(), state.end(), reinterpret_cast<char*>(byteBuffer->data));

	byteBuffer->length = state.size();
	byteBuffer->index = 0;
	
	debugInterfaceNes->UnlockMutex();
	
	return byteBuffer;
}

bool nesd_restore_state(CByteBuffer *byteBuffer)
{
	debugInterfaceNes->LockMutex();

	std::stringstream ss(std::string(reinterpret_cast<const char*>(byteBuffer->data),
									 reinterpret_cast<const char*>(byteBuffer->data) + byteBuffer->length));
	bool ret = !machine->LoadState(ss);
	
	debugInterfaceNes->UnlockMutex();
	
	return ret;
}

bool retro_serialize(void *data, size_t size)
{
	std::stringstream ss;
	if (machine->SaveState(ss, Api::Machine::NO_COMPRESSION))
		return false;
	
	std::string state = ss.str();
	if (state.size() > size)
		return false;
	
	std::copy(state.begin(), state.end(), reinterpret_cast<char*>(data));
	return true;
}

// load state
bool retro_unserialize(const void *data, size_t size)
{
	std::stringstream ss(std::string(reinterpret_cast<const char*>(data),
									 reinterpret_cast<const char*>(data) + size));
	return !machine->LoadState(ss);
}

////////////////
//////////////// //////////// NES DEBUGGER
///////////////

// TODO: note that we need to have a local copy of PC for now, as op fetch (to peek what's there) is increasing PC in ExecuteOp. change this behaviour to allow peek without increasing PC and then this below will be obsolete:
// this is called by CPU emulation engine (ExecuteOp)
void nesd_update_cpu_pc_by_emulator(uint16 cpuPC)
{
	currentNesPC = cpuPC;
}

unsigned int nesd_get_cpu_pc()
{
	return currentNesPC;
	
//	Core::Machine& machineGet = emulator;
////	LOGD("pc=%d", machineGet.cpu.pc);
//	return machineGet.cpu.pc;
}

void nesd_get_cpu_regs(unsigned short *pc, unsigned char *a, unsigned char *x, unsigned char *y, unsigned char *p, unsigned char *s, unsigned char *irq)
{
	Core::Machine& machineGet = emulator;
	
//	LOGD("pc=%d", machineGet.cpu.pc);
	*pc = currentNesPC; //machineGet.cpu.pc;

	*a = machineGet.cpu.a;
	*x = machineGet.cpu.x;
	*y = machineGet.cpu.y;
	*p = machineGet.cpu.flags.Pack();
	*s = machineGet.cpu.sp;
	*irq = machineGet.cpu.interrupt.low;
}

u8 *nesd_get_ram()
{
	Core::Machine& machineGet = emulator;
	return &machineGet.cpu.GetRam()[0];
}

u8 nesd_peek_io(u16 addr)
{
	Core::Machine& machineGet = emulator;
	return machineGet.cpu.Peek(addr);
}

u8 nesd_peek_safe_io(u16 addr)
{
//	LOGD("nesd_peek_safe_io");
	Core::Machine& machineGet = emulator;
	u8 *ram = &machineGet.cpu.GetRam()[0];
//	if (addr > 0x0000 && addr < 0x10000)
//	{
//		return ram[addr];
//	}


	if (addr > 0x0000 && addr < 0x2000)
	{
		return machineGet.cpu.Peek_NoMarking(addr);
	}

	// PPU
	if (addr > 0x2000 && addr < 0x3FFF)
	{
		return ram[addr];
	}
	
	// APU
	if (addr > 0x4000 && addr < 0x4020)
	{
		return ram[addr];
	}
	
//	if (addr > 0xC000 && addr < 0xE000)
//	{
//		return ram[addr];
//	}
//
//	if (addr > 0xE000 && addr < 0xFFFF)
//	{
//		return ram[addr];
//	}

	if (addr > 0x5000 && addr < 0x10000)
	{
		return machineGet.cpu.Peek_NoMarking(addr);
	}

	return ram[addr];
}

int crossx = 0;
int crossy = 0;

#define CROSSHAIR_SIZE 3

void nes_draw_crosshair(int x, int y)
{
	u32 w = 0xFFFFFFFF;
	u32 b = 0x00000000;
	int current_width = 256;
	
	if (blargg_ntsc){
		x *= 2.36;
		current_width = 602;
	}
	
	for (int i = UMAX(-CROSSHAIR_SIZE, -x); i <= UMIN(CROSSHAIR_SIZE, current_width - x); i++) {
		video_buffer[current_width * y + x + i] = i % 2 == 0 ? w : b;
	}
	
	for (int i = UMAX(-CROSSHAIR_SIZE, -y); i <= UMIN(CROSSHAIR_SIZE, 239 - y); i++) {
		video_buffer[current_width * (y + i) + x] = i % 2 == 0 ? w : b;
	}
}

static void nes_load_wav(const char* sampgame, Api::User::File& file)
{
	char samp_path[292];
	
	snprintf(samp_path, sizeof(samp_path), "%s%c%s%c%02d.wav", samp_dir, slash, sampgame, slash, file.GetId());
	
	std::ifstream samp_file(samp_path, std::ifstream::in|std::ifstream::binary);
	
	if (samp_file) {
		samp_file.seekg(0, samp_file.end);
		int length = samp_file.tellg();
		samp_file.seekg(0, samp_file.beg);

		char *wavfile = new char[length];
		samp_file.read(wavfile, length);
		
		// Check to see if it has a valid header
		char fmt[4] = { 0x66, 0x6d, 0x74, 0x20};
		char subchunk2id[4] = { 0x64, 0x61, 0x74, 0x61};
		if (memcmp(&wavfile[0x00], "RIFF", 4) != 0) { return; }
		if (memcmp(&wavfile[0x08], "WAVE", 4) != 0) { return; }
		if (memcmp(&wavfile[0x0c], &fmt, 4) != 0) { return; }
		if (memcmp(&wavfile[0x24], &subchunk2id, 4) != 0) { return; }
		
		// Load the sample into the emulator
		char *dataptr = &wavfile[0x2c];
		int blockalign = wavfile[0x21] << 8 | wavfile[0x20];
		int numchannels = wavfile[0x17] << 8 | wavfile[0x16];
		int bitspersample = wavfile[0x23] << 8 | wavfile[0x22];
		file.SetSampleContent(dataptr, (length - 44) / blockalign, 0, bitspersample, 44100);

		delete [] wavfile;
	}
}

void NST_CALLBACK nes_file_io_callback(void*, Api::User::File &file)
{
	const void *addr;
	unsigned long addr_size;
	
#ifdef _WIN32
	slash = '\\';
#else
	slash = '/';
#endif
	
	switch (file.GetAction())
	{
		case Api::User::File::LOAD_SAMPLE_MOERO_PRO_YAKYUU:
			nes_load_wav("moepro", file); break;
		case Api::User::File::LOAD_SAMPLE_MOERO_PRO_YAKYUU_88:
			nes_load_wav("moepro88", file); break;
		case Api::User::File::LOAD_SAMPLE_MOERO_PRO_TENNIS:
			nes_load_wav("mptennis", file); break;
		case Api::User::File::LOAD_SAMPLE_TERAO_NO_DOSUKOI_OOZUMOU:
			nes_load_wav("terao", file); break;
		case Api::User::File::LOAD_SAMPLE_AEROBICS_STUDIO:
			nes_load_wav("ftaerobi", file); break;
			
		case Api::User::File::LOAD_BATTERY:
		case Api::User::File::LOAD_EEPROM:
		case Api::User::File::LOAD_TAPE:
		case Api::User::File::LOAD_TURBOFILE:
			file.GetRawStorage(sram, sram_size);
			break;
			
		case Api::User::File::SAVE_BATTERY:
		case Api::User::File::SAVE_EEPROM:
		case Api::User::File::SAVE_TAPE:
		case Api::User::File::SAVE_TURBOFILE:
			file.GetContent(addr, addr_size);
			if (addr != sram || sram_size != addr_size)
			{
				LOGWarning("[Nestopia]: SRAM changed place in RAM");
			}
			break;
		case Api::User::File::LOAD_FDS:
		{
			char base[256];
			sprintf(base, "%s%c%s.sav", g_save_dir, slash, g_basename);
			
			LOGM("Want to load FDS sav from: %s\n", base);
			std::ifstream in_tmp(base,std::ifstream::in|std::ifstream::binary);
			
			if (!in_tmp.is_open())
				return;
			
			file.SetPatchContent(in_tmp);
		}
			break;
		case Api::User::File::SAVE_FDS:
		{
			char base[256];
			sprintf(base, "%s%c%s.sav", g_save_dir, slash, g_basename);
			LOGM("Want to save FDS sav to: %s\n", base);
			std::ofstream out_tmp(base,std::ifstream::out|std::ifstream::binary);
			
			if (out_tmp.is_open())
				file.GetPatchContent(Api::User::File::PATCH_UPS, out_tmp);
		}
			break;
		default:
			break;
	}
}

void nesd_reset()
{
	debugInterfaceNes->LockMutex();
	
	machine->Reset(false);
	
	if (machine->Is(Nes::Api::Machine::DISK))
	{
		fds->EjectDisk();
		if (fds_auto_insert)
		{
			fds->InsertDisk(0, 0);
		}
	}

	debugInterfaceNes->UnlockMutex();
}

void nesd_set_defaults()
{
	debugInterfaceNes->LockMutex();
	nesd_sound_lock("nesd_set_defaults");

	Api::Sound sound(emulator);
	sound.SetSampleBits(16);
	sound.SetSampleRate(SOUND_SAMPLE_RATE);
	sound.SetSpeaker(Api::Sound::SPEAKER_MONO);

	Api::Video video(emulator);
	Api::Video::RenderState renderState;
	Api::Video::RenderState::Filter filter;

	is_pal = false;

	Api::Machine machine(emulator);
	machine.SetMode(machine.GetDesiredMode());
	if (machine.GetMode() == Api::Machine::PAL)
	{
		is_pal = true;
		favsystem = Api::Machine::FAVORED_NES_PAL;
		machine.SetMode(Api::Machine::PAL);
	}
	else
	{
		favsystem = Api::Machine::FAVORED_NES_NTSC;
		machine.SetMode(Api::Machine::NTSC);
	}
	
	if (audioOutput)
	{
		delete audioOutput;
	}
	audioOutput = new Api::Sound::Output(audio_buffer, nst_pal() ? (double)SOUND_SAMPLE_RATE / 50.0 : (double)SOUND_SAMPLE_RATE / 60.0);

	sound.SetGenie(0);
	machine.SetRamPowerState(0);
	video.EnableUnlimSprites(false);
	video.EnableOverclocking(false);
	fds_auto_insert = true;
	
	blargg_ntsc = 0;
	filter = Api::Video::RenderState::FILTER_NONE;
	video_width = Api::Video::Output::WIDTH;
	video.SetSaturation(Api::Video::DEFAULT_SATURATION);
	
	video.GetPalette().SetMode(Api::Video::Palette::MODE_CUSTOM);
	video.GetPalette().SetCustom(cxa2025as_palette, Api::Video::Palette::STD_PALETTE);
	
	overscan_v = false;
	overscan_h = false;
	
	aspect_ratio_mode = 0;
	
	Api::Input(emulator).AutoSelectController(2);
	Api::Input(emulator).AutoSelectController(3);
	Api::Input(emulator).AutoSelectAdapter();
	
	tpulse = 2;
	
	pitch = video_width * 4;
	
	renderState.filter = filter;
	renderState.width = video_width;
	renderState.height = Api::Video::Output::HEIGHT;
	renderState.bits.count = 32;
	renderState.bits.mask.r = 0x000000ff;
	renderState.bits.mask.g = 0x0000ff00;
	renderState.bits.mask.b = 0x00ff0000;
	if (NES_FAILED(video.SetRenderState( renderState )))
	{
		LOGError("Nestopia core rejected render state\n");
	}
	
//	retro_get_system_av_info(&av_info);
//	environ_cb(RETRO_ENVIRONMENT_SET_GEOMETRY, &av_info);

	nesd_sound_unlock("nesd_set_defaults");
	debugInterfaceNes->UnlockMutex();
}

//#define JOYPAD_FIRE	0x10
//#define JOYPAD_E		0x08
//#define JOYPAD_W		0x04
//#define JOYPAD_S		0x02
//#define JOYPAD_N		0x01
//#define JOYPAD_IDLE	0x00

//	A      = 0x01,
//	B      = 0x02,
//	SELECT = 0x04,
//	START  = 0x08,
//	UP     = 0x10,
//	DOWN   = 0x20,
//	LEFT   = 0x40,
//	RIGHT  = 0x80

int nesd_joystick_axis_to_pad_button(uint32 axis)
{
	int padButton = 0;

	if ((axis & JOYPAD_START) == JOYPAD_START)
	{
		padButton |= Core::Input::Controllers::Pad::START;
	}

	if ((axis & JOYPAD_SELECT) == JOYPAD_SELECT)
	{
		padButton |= Core::Input::Controllers::Pad::SELECT;
	}
	
	if ((axis & JOYPAD_FIRE) == JOYPAD_FIRE)
	{
		padButton |= Core::Input::Controllers::Pad::A;
	}
	
	if ((axis & JOYPAD_FIRE_B) == JOYPAD_FIRE_B)
	{
		padButton |= Core::Input::Controllers::Pad::B;
	}

	if ((axis & JOYPAD_E) == JOYPAD_E)
	{
		padButton |= Core::Input::Controllers::Pad::LEFT;
	}

	if ((axis & JOYPAD_W) == JOYPAD_W)
	{
		padButton |= Core::Input::Controllers::Pad::RIGHT;
	}

	if ((axis & JOYPAD_S) == JOYPAD_S)
	{
		padButton |= Core::Input::Controllers::Pad::DOWN;
	}

	if ((axis & JOYPAD_N) == JOYPAD_N)
	{
		padButton |= Core::Input::Controllers::Pad::UP;
	}
	
	return padButton;
}

void nesd_joystick_down(int port, uint32 axis)
{
	LOGD("nesd_joystick_down: %d %x btns=%x", port, axis, input->pad[port].buttons);

	int padButton = nesd_joystick_axis_to_pad_button(axis);

	if (axis == JOYPAD_N)
	{
		if (input->pad[port].buttons & nesd_joystick_axis_to_pad_button(JOYPAD_S))
		{
			input->pad[port].buttons &= ~nesd_joystick_axis_to_pad_button(JOYPAD_S);
		}
	}
	if (axis == JOYPAD_S)
	{
		if (input->pad[port].buttons & nesd_joystick_axis_to_pad_button(JOYPAD_N))
		{
			input->pad[port].buttons &= ~nesd_joystick_axis_to_pad_button(JOYPAD_N);
		}
	}
	if (axis == JOYPAD_E)
	{
		if (input->pad[port].buttons & nesd_joystick_axis_to_pad_button(JOYPAD_W))
		{
			input->pad[port].buttons &= ~nesd_joystick_axis_to_pad_button(JOYPAD_W);
		}
	}
	if (axis == JOYPAD_W)
	{
		if (input->pad[port].buttons & nesd_joystick_axis_to_pad_button(JOYPAD_E))
		{
			input->pad[port].buttons &= ~nesd_joystick_axis_to_pad_button(JOYPAD_E);
		}
	}

	LOGD("         padButton: %x", padButton);
	input->pad[port].buttons |= padButton;
	
	LOGD("                  : buttons=%x", input->pad[port].buttons);
}

void nesd_joystick_up(int port, uint32 axis)
{
	LOGD("^ nesd_joystick_up: %d %x btns=%x", port, axis, input->pad[port].buttons);

	int padButton = nesd_joystick_axis_to_pad_button(axis);
	LOGD("         padButton: %x", padButton);

	input->pad[port].buttons &= ~padButton;

	LOGD("^^^^^^^^^^^^^^^^^^: buttons=%x", input->pad[port].buttons);
}

/*
 static int nstd_quit = 0;
 
 extern Input::Controllers *cNstPads;
 extern nstpaths_t nstpaths;
 
 extern bool (*nst_archive_select)(const char*, char*, size_t);
 extern void (*audio_deinit)();
 
 //void nst_schedule_quit() {
 //	nst_quit = 1;
 //}
 
*/

void NestopiaUE_Initialize_SDL()
{
	/*	LOGM("NestopiaUE_Initialize_SDL");
	 
	 // This is the main function
	 
	 // Set up directories
	 nst_set_dirs();
	 
	 // Set default config options
	 config_set_default();
	 
	 // Read the config file and override defaults
	 config_file_read(nstpaths.nstdir);
	 
	 
	 //	// Exit if there is no CLI argument
	 //	if (argc == 1) {
	 //		cli_show_usage();
	 //		return 0;
	 //	}
	 //
	 //	// Handle command line arguments
	 //	cli_handle_command(argc, argv);
	 
	 
	 // Set up callbacks
	 nst_set_callbacks();
	 
	 
	 // NESFIXME
	 
	 
	 //	// Initialize SDL
	 //	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_JOYSTICK) < 0) {
	 //		fprintf(stderr, "Couldn't initialize SDL: %s\n", SDL_GetError());
	 //		return 1;
	 //	}
	 
	 
	 
	 // Detect Joysticks
	 nstsdl_input_joysticks_detect();
	 
	 // Set default input keys
	 nstsdl_input_conf_defaults();
	 
	 // Read the input config file and override defaults
	 nstsdl_input_conf_read();
	 
	 // Set archive handler function pointer
	 nst_archive_select = &nst_archive_select_file;
	 
	 // Set audio function pointers
	 audio_set_funcs();
	 
	 // Set the video dimensions
	 video_set_dimensions();
	 
	 // Initialize and load FDS BIOS and NstDatabase.xml
	 nst_fds_bios_load();
	 nst_db_load();
	 
	 // Load a rom from the command line
	 //	if (argc > 1)
	 
	 char *defaultRomPath = "/Users/mars/develop/MTEngine/_RUNTIME_/Documents/nes/contra.nes";
	 
	 {
		if (!nst_load(defaultRomPath))
		{
	 nstd_quit = 1;
		}
		else
		{
	 // Create the window
	 nstsdl_video_create();
	 nstsdl_video_set_title(nstpaths.gamename);
	 
	 // Set play in motion
	 nst_play();
	 
	 // Set the cursor if needed
	 nstsdl_video_set_cursor();
		}
	 }
	 
	 LOGM("NestopiaUE_Initialize_SDL finished");*/
}

void NestopiaUE_Run_SDL()
{
	/*
	// Start the main loop
	
	//	SDL_Event event;
	while (!nstd_quit)
	{
		nst_ogl_render();
		nstsdl_video_swapbuffers();

//		while (SDL_PollEvent(&event))
//		{
//			switch (event.type) {
//				case SDL_QUIT:
//					nst_quit = 1;
//					break;
//
//				case SDL_KEYDOWN:
//				case SDL_KEYUP:
//				case SDL_JOYHATMOTION:
//				case SDL_JOYAXISMOTION:
//				case SDL_JOYBUTTONDOWN:
//				case SDL_JOYBUTTONUP:
//				case SDL_MOUSEBUTTONDOWN:
//				case SDL_MOUSEBUTTONUP:
//					nstsdl_input_process(cNstPads, event);
//					break;
//				default: break;
//			}
//		}

		nst_emuloop();
	}
	
	// Remove the cartridge and shut down the NES
	nst_unload();
	
	// Unload the FDS BIOS, NstDatabase.xml, and the custom palette
	nst_db_unload();
	nst_fds_bios_unload();
	nst_palette_unload();
	
	// Deinitialize audio
	audio_deinit();
	
	// Deinitialize joysticks
	nstsdl_input_joysticks_close();
	
	// Write the input config file
	nstsdl_input_conf_write();
	
	// Write the config file
	config_file_write(nstpaths.nstdir);
	*/
}


// TODO: memory read breakpoints
void nesd_mark_cell_read(uint16 addr)
{
	int pc = nesd_get_cpu_pc();
	
	viewC64->viewNesMemoryMap->CellRead(addr, pc, -1, -1);
}

void nesd_mark_cell_write(uint16 addr, uint8 value)
{
	NesDebugInterface *debugInterface = debugInterfaceNes;
	
	int pc = nesd_get_cpu_pc();
	viewC64->viewNesMemoryMap->CellWrite(addr, value, pc, -1, -1);
	
	// TODO: make breakpoints generic
	
	// skip checking breakpoints when quick fast-forward/restoring snapshot
	if (debugInterface->snapshotsManager->IsPerformingSnapshotRestore())
		return;
	
	if (debugInterface->breakOnMemory)
	{
		debugInterface->LockMutex();
		
		std::map<uint16, CMemoryBreakpoint *>::iterator it = debugInterface->breakpointsMemory.find(addr);
		if (it != debugInterface->breakpointsMemory.end())
		{
			CMemoryBreakpoint *memoryBreakpoint = it->second;
			
			if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_EQUAL)
			{
				if (value == memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_NOT_EQUAL)
			{
				if (value != memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS)
			{
				if (value < memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_LESS_OR_EQUAL)
			{
				if (value <= memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER)
			{
				if (value > memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
			else if (memoryBreakpoint->breakpointType == MEMORY_BREAKPOINT_GREATER_OR_EQUAL)
			{
				if (value >= memoryBreakpoint->value)
				{
					debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
				}
			}
		}
		
		debugInterface->UnlockMutex();
	}
}

void nesd_mark_cell_execute(uint16 addr, uint8 opcode)
{
//	LOGD("nesd_mark_cell_execute: %04x %02x", addr, opcode);
	viewC64->viewNesMemoryMap->CellExecute(addr, opcode);
}

bool nesd_is_debug_on()
{
	return debugInterfaceNes->isDebugOn;
}

void nesd_check_pc_breakpoint(uint16 pc)
{
//	LOGD("nesd_check_pc_breakpoint: pc=%04x", pc);

	NesDebugInterface *debugInterface = debugInterfaceNes;

	if ((int)pc == debugInterface->temporaryBreakpointPC)
	{
		debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
		debugInterface->temporaryBreakpointPC = -1;
	}
	else if (debugInterface->breakOnPC)
	{
		debugInterface->LockMutex();
		std::map<uint16, CAddrBreakpoint *>::iterator it = debugInterface->breakpointsPC.find(pc);
		if (it != debugInterface->breakpointsPC.end())
		{
			CAddrBreakpoint *addrBreakpoint = it->second;

			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_SET_BACKGROUND))
			{
				// Not supported
			}

			if (IS_SET(addrBreakpoint->actions, ADDR_BREAKPOINT_ACTION_STOP))
			{
				debugInterface->SetDebugMode(DEBUGGER_MODE_PAUSED);
			}
		}
		debugInterface->UnlockMutex();
	}
}


void nesd_debug_pause_check()
{
//	LOGD("nesd_debug_pause_check, nesd_debug_mode=%d", nesd_debug_mode);
	if (nesd_debug_mode == DEBUGGER_MODE_PAUSED)
	{
		//		c64d_refresh_previous_lines();
		//		c64d_refresh_dbuf();
		//		c64d_refresh_cia();

		while (nesd_debug_mode == DEBUGGER_MODE_PAUSED)
		{
//			LOGD("nesd_debug_pause_check, waiting... nesd_debug_mode=%d PC=%04x", nesd_debug_mode, nesd_get_cpu_pc());
			mt_SYS_Sleep(10);
			//			vsync_do_vsync(vicii.raster.canvas, 0, 1);
			//mt_SYS_Sleep(50);
		}

		LOGD("nesd_debug_pause_check: new mode is %d PC=%04x", nesd_debug_mode, nesd_get_cpu_pc());
	}
}

void nesd_mute_channels(bool muteSquare1, bool muteSquare2, bool muteTriangle, bool muteNoise, bool muteDmc, bool muteExt)
{
	bool channels[MAX_NESD_CHANNELS];
	for (int i = 0; i < MAX_NESD_CHANNELS; i++)
	{
		channels[i] = false;
	}
	
	channels[0] = muteSquare1;
	channels[1] = muteSquare2;
	channels[2] = muteTriangle;
	channels[3] = muteNoise;
	channels[4] = muteDmc;
	channels[5] = muteExt;

	Core::Machine& machineGet = emulator;
	machineGet.cpu.apu.SetVolume(channels);
}

volatile bool nesd_isReceiveChannelsData = false;

void nesd_receive_channels_data(unsigned int valSquare1, unsigned int valSquare2, unsigned int valTriangle, unsigned int valNoise, unsigned int valDmc, unsigned int valExt, unsigned int valMix)
{
	float f = 1.75f;
	viewC64->viewNesStateAPU->AddWaveformData(0, (int)((float)valSquare1*f),
												 (int)((float)valSquare2*f),
												 (int)((float)valTriangle*f),
												 (int)((float)valNoise*f),
												 (int)((float)valDmc*f),
												 (int)((float)valExt*f),
												 (int)((float)valMix*f));
}

uint8 nesd_get_apu_register(uint16 addr)
{
	Core::Machine& machineGet = emulator;
	u8 val = machineGet.cpu.apu.regs[addr & 0x001F];
	return val;
}

////
//int nesd_get_joystick_state(int joystickNum)
//{
//	return debugInterfaceAtari->joystickState[joystickNum];
//}



void nesd_sound_pause()
{
	debugInterfaceNes->audioChannel->bypass = true;
}

void nesd_sound_resume()
{
	debugInterfaceNes->audioChannel->bypass = false;
}

//static u8 nesdLockCount = 0;

void nesd_sound_lock(char *whoLocked)
{
	//LOGD("nesd_sound_lock: %s (count=%d)", whoLocked, nesdLockCount);
	audioBufferMutex->Lock();
	//nesdLockCount++;
	//LOGD("nesd_sound_lock locked by %s (count=%d)", whoLocked, nesdLockCount);
}

void nesd_sound_unlock(char *whoLocked)
{
	//LOGD("nesd_sound_unlock: %s (cound=%d)", whoLocked, nesdLockCount);
	//nesdLockCount--;
	audioBufferMutex->Unlock();
	//LOGD("nesd_sound_unlock unlocked by %s (count=%d)", whoLocked, nesdLockCount);
}

void nesd_mutex_lock()
{
	debugInterfaceNes->LockMutex();
}

void nesd_mutex_unlock()
{
	debugInterfaceNes->UnlockMutex();
}

#else
// no RUN_NES, dummy functions

///// aka the ...RELEASE MEEEEEE FROM THIS CAGEEEEE... ghost

bool NestopiaUE_Initialize() { return false; }
bool NestopiaUE_Run() { return false; }

bool nesd_insert_cartridge(char *filePath) { return false; }

void nesd_reset() {}
unsigned char *nesd_get_ram() { return NULL; }

CByteBuffer *nesd_store_state() { return NULL; }
bool nesd_restore_state(CByteBuffer *byteBuffer) { return false; }

void nesd_sound_init() {}
void nesd_sound_pause() {}
void nesd_sound_resume() {}

void nesd_reset_sync() {}
bool nesd_is_debug_on() { return false; }

void nesd_audio_callback(i16 *monoBuffer, int numSamples) {}

void nesd_mark_cell_read(uint16 addr) {}
void nesd_mark_cell_write(uint16 addr, uint8 value) {}
void nesd_mark_cell_execute(uint16 addr, uint8 opcode) {}

void nesd_debug_pause_check() {}

void nesd_joystick_down(int port, uint32 axis) {}
void nesd_joystick_up(int port, uint32 axis) {}

unsigned int nesd_get_cpu_pc() { return 0; }
unsigned char nesd_peek_io(unsigned short addr) { return 0; }
unsigned char nesd_peek_safe_io(unsigned short addr) { return 0; }
void nesd_get_cpu_regs(unsigned short *pc, unsigned char *a, unsigned char *x, unsigned char *y, unsigned char *p, unsigned char *s, unsigned char *irq) {}
void nesd_check_pc_breakpoint(uint16 pc) {}
void nesd_update_cpu_pc_by_emulator(uint16 cpuPC) {}

void nesd_mute_channels(bool muteSquare1, bool muteSquare2, bool muteTriangle, bool muteNoise, bool muteDmc, bool muteExt) {}
volatile bool nesd_isReceiveChannelsData;
void nesd_receive_channels_data(unsigned int valSquare1, unsigned int valSquare2, unsigned int valTriangle, unsigned int valNoise, unsigned int valDmc, unsigned int valExt, unsigned int valMix) {}

uint8 nesd_get_apu_register(uint16 addr) { return 0; }
bool nesd_is_pal() { return false; }
double nesd_get_cpu_clock_frquency() { return 0.0; }

void nesd_audio_callback(uint8 *stream, int numSamples) {}
void nesd_sound_lock() {}
void nesd_sound_unlock() {}

#endif
