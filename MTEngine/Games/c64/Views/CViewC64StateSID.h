#ifndef _CVIEWC64STATESID_H_
#define _CVIEWC64STATESID_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;

class CViewC64StateSIDWaveform : public CGuiView
{
public:
	CViewC64StateSIDWaveform(float posX, float posY, float posZ, float sizeX, float sizeY);
	~CViewC64StateSIDWaveform();

	signed short *waveformData;
	CGLLineStrip *lineStrip;
	
	bool isMuted;
	
	void CalculateWaveform();
	void Render();
};

class CViewC64StateSID : public CGuiView, CGuiEditHexCallback
{
public:
	CViewC64StateSID(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *fontBytes;
	
	float fontSize;
	
	virtual void SetVisible(bool isVisible);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	uint16 sidBase;
	
	C64DebugInterface *debugInterface;
	
	void DumpSidWaveform(uint8 wave, char *buf);
	
	virtual bool SetFocus(bool focus);

	CViewC64StateSIDWaveform *sidChannelWaveform[3];
	CViewC64StateSIDWaveform *sidMixWaveform;
	
	int waveformPos;
	void AddWaveformData(int v1, int v2, int v3, short mix);
};


#endif

