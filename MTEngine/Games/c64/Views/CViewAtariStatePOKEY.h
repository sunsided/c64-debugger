#ifndef _CViewAtariStatePOKEY_H_
#define _CViewAtariStatePOKEY_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include <vector>
#include <list>

extern "C" {
#include "AtariWrapper.h"
}

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class AtariDebugInterface;
class CViewC64StateSIDWaveform;

class CViewAtariStatePOKEY : public CGuiView, CGuiEditHexCallback
{
public:
	CViewAtariStatePOKEY(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, AtariDebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	AtariDebugInterface *debugInterface;

	float fontSize;	
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual void SetVisible(bool isVisible);
	virtual void Render();
	virtual void DoLogic();	
	
	virtual bool SetFocus(bool focus);
	
	// [sid num][channel num]
	CViewC64StateSIDWaveform *pokeyChannelWaveform[MAX_NUM_POKEYS][4];
	CViewC64StateSIDWaveform *pokeyMixWaveform[MAX_NUM_POKEYS];

	int waveformPos;
	void AddWaveformData(int pokeyNumber, int v1, int v2, int v3, int v4, short mix);

	//
	virtual void RenderState(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize, int pokeyId);
	
	// editing registers
	bool showRegistersOnly;
	int editingRegisterValueIndex;		// -1 means no editing
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);
	
	//
	virtual void RenderFocusBorder();

};


#endif

