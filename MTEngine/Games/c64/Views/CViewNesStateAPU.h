#ifndef _CViewNesStateAPU_H_
#define _CViewNesStateAPU_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include <vector>
#include <list>

extern "C" {
#include "NesWrapper.h"
}

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class NesDebugInterface;
class CViewC64StateSIDWaveform;

#define MAX_NUM_NES_APUS 1

class CViewNesStateAPU : public CGuiView, CGuiEditHexCallback
{
public:
	CViewNesStateAPU(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, NesDebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	NesDebugInterface *debugInterface;

	float fontSize;	
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual void SetVisible(bool isVisible);
	virtual void Render();
	virtual void DoLogic();	
	
	virtual bool SetFocus(bool focus);
	
	// [apu num][channel num]
	// square0, square1, triangle, noise, dmc, extChannel
	CViewC64StateSIDWaveform *nesChannelWaveform[MAX_NUM_NES_APUS][6];
	CViewC64StateSIDWaveform *nesMixWaveform[MAX_NUM_NES_APUS];

	int waveformPos;
	void AddWaveformData(int apuNumber, int v1, int v2, int v3, int v4, int v5, int v6, short mix);

	//
	virtual void RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int apuId);
	
	// editing registers
	bool showRegistersOnly;
	int editingRegisterValueIndex;		// -1 means no editing
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);
	
	//
	virtual void RenderFocusBorder();

};


#endif

