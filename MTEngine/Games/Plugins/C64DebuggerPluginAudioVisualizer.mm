#include "C64DebuggerPluginAudioVisualizer.h"
#include "MTH_Random.h"
#include "GFX_Types.h"
#include <map>

C64DebuggerPluginAudioVisualizer::C64DebuggerPluginAudioVisualizer()
: CDebuggerEmulatorPlugin(EMULATOR_TYPE_C64_VICE)
{
}

void C64DebuggerPluginAudioVisualizer::Init()
{
	LOGD("C64DebuggerPluginAudioVisualizer::Init");

	api->SwitchToVicEditor();
	
	//
	api->StartThread(this);
}

void C64DebuggerPluginAudioVisualizer::ThreadRun(void *data)
{
	api->DetachEverything();
	
	api->Sleep(500);
	api->ClearRAM(0x0800, 0x10000, 0x00);
	
	api->CreateNewPicture(C64_PICTURE_MODE_BITMAP_MULTI, 0x00);

	api->Sleep(100);
	
	imageDataRef = new CImageData("ref.png");
	
	api->LoadReferenceImage(imageDataRef);
	api->SetReferenceImageLayerVisible(true);
	
	api->ClearReferenceImage();

	api->ConvertImageToScreen(imageDataRef);
	api->ClearScreen();

	api->SetReferenceImageLayerVisible(true);

	api->SetupVicEditorForScreenOnly();

	api->Sleep(500);
}

void C64DebuggerPluginAudioVisualizer::DoFrame()
{
	// do anything you need after each emulation frame, vsync is here:
	
	
//	api->PaintPixel(<#int x#>, <#int y#>, <#u8 color#>);
	
	
//	LOGD("C64DebuggerPluginAudioVisualizer::DoFrame finished");
}

#define ASSEMBLE(fmt, ...) sprintf(buf, fmt, ## __VA_ARGS__); this->Assemble(buf);
#define A(fmt, ...) sprintf(buf, fmt, ## __VA_ARGS__); this->Assemble(buf);
#define PUT(v) this->PutDataByte(v);
#define PC addrAssemble

u32 C64DebuggerPluginAudioVisualizer::KeyDown(u32 keyCode)
{
	if (keyCode == MTKEY_ARROW_UP)
	{
	}
	
	if (keyCode == MTKEY_ARROW_DOWN)
	{
	}
	
	if (keyCode == MTKEY_ARROW_LEFT)
	{
	}
	if (keyCode == MTKEY_ARROW_RIGHT)
	{
	}
	
	return keyCode;
}

u32 C64DebuggerPluginAudioVisualizer::KeyUp(u32 keyCode)
{
	return keyCode;
}
