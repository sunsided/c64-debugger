#ifndef _C64DEBUGGERPLUGINAUDIOVISUALIZER_H_
#define _C64DEBUGGERPLUGINAUDIOVISUALIZER_H_

#include "CDebuggerEmulatorPlugin.h"
#include "CDebuggerAPI.h"
#include <list>

class CImageData;

class C64DebuggerPluginAudioVisualizer : public CDebuggerEmulatorPlugin, CSlrThread
{
public:
	C64DebuggerPluginAudioVisualizer();
	
	virtual void Init();
	virtual void ThreadRun(void *data);

	virtual void DoFrame();
	virtual u32 KeyDown(u32 keyCode);
	virtual u32 KeyUp(u32 keyCode);

	CImageData *imageDataRef;
};

#endif
