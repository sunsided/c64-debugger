#include "SYS_Types.h"
#include "C64SettingsStorage.h"
#include "CViewC64.h"
#include "C64DebugInterface.h"
#include "C64DebugTypes.h"

extern "C" {
	void sdl_callback(void *userdata, uint8 *stream, int len);
}

#include "CViceAudioChannel.h"

CViceAudioChannel::CViceAudioChannel(C64DebugInterfaceVice *debugInterface)
{
	this->debugInterface = debugInterface;
}

void CViceAudioChannel::MixIn(int *mixBuffer, u32 numSamples)
{
	sdl_callback(NULL, (uint8*)mixBuffer, numSamples);

	
	if (c64SettingsMuteSIDOnPause)
	{
		if (viewC64->debugInterface->GetDebugMode() != C64_DEBUG_RUNNING)
		{
			memset(mixBuffer, 0, numSamples*4);
		}
	}
}


