#ifndef _C64DEBUGGEREMULATORPLUGIN_H_
#define _C64DEBUGGEREMULATORPLUGIN_H_

#include "SYS_Defs.h"
#include "CDebuggerAPI.h"

// this plugin draft is intended for additional work done with emulator
// example: start vice emulator and do something with it, like own function for painting

class CDebugInterface;

class CDebuggerEmulatorPlugin
{
public:
	CDebuggerEmulatorPlugin(u8 emulatorType);
	virtual ~CDebuggerEmulatorPlugin();
	
	u8 emulatorType;
	virtual void SetEmulatorType(u8 emulatorType);
	virtual CDebugInterface *GetDebugInterface();
	
	virtual void Init();
	virtual void DoFrame();
	
	virtual u32 KeyDown(u32 keyCode);
	virtual u32 KeyUp(u32 keyCode);
	
	CDebuggerAPI *api;
};

#endif
