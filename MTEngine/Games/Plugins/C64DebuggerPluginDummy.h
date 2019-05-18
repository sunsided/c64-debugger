#ifndef _C64DEBUGGER_PLUGIN_DUMMY_H_
#define _C64DEBUGGER_PLUGIN_DUMMY_H_

#include "CDebuggerEmulatorPlugin.h"
#include "CDebuggerAPI.h"
#include <list>

class CImageData;

class C64DebuggerPluginDummy : public CDebuggerEmulatorPlugin, CSlrThread
{
public:
	C64DebuggerPluginDummy();
	
	virtual void Init();
	virtual void ThreadRun(void *data);

	virtual void DoFrame();
	virtual u32 KeyDown(u32 keyCode);
	virtual u32 KeyUp(u32 keyCode);

	CImageData *imageDataRef;
	
	// assemble
	u16 addrAssemble;
	void Assemble(char *buf);
	void PutDataByte(u8 v);
};

#endif
