#ifndef _CVIEWC64STATESID_H_
#define _CVIEWC64STATESID_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include "ViceWrapper.h"
#include "CGuiButtonSwitch.h"
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

// TODO: make base class to have Vice specific state rendering and editing
//       class CViewC64ViceStateSID : public CViewC64StateSID

class CViewC64StateSID : public CGuiView, CGuiEditHexCallback, CGuiButtonSwitchCallback
{
public:
	CViewC64StateSID(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;
	
	CSlrFont *fontBytes;
	float fontBytesSize;
	
	virtual void SetVisible(bool isVisible);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	C64DebugInterface *debugInterface;
	
	void DumpSidWaveform(uint8 wave, char *buf);
	
	virtual bool SetFocus(bool focus);

	// [sid num][channel num]
	CViewC64StateSIDWaveform *sidChannelWaveform[MAX_NUM_SIDS][3];
	CViewC64StateSIDWaveform *sidMixWaveform[MAX_NUM_SIDS];
	
	int selectedSidNumber;
	
	CGuiButtonSwitch *btnsSelectSID[MAX_NUM_SIDS];
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);
	float buttonSizeX;
	float buttonSizeY;

	void SelectSid(int sidNum);
	
	virtual void RenderStateSID(int sidNum, float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize);
	void PrintSidWaveform(uint8 wave, char *buf);
	
	void UpdateSidButtonsState();
	
	int waveformPos;
	void AddWaveformData(int sidNumber, int v1, int v2, int v3, short mix);
	
	// editing registers
	bool showRegistersOnly;
	int editingRegisterValueIndex;		// -1 means no editing
	int editingSIDIndex;
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);

	//
	virtual void RenderFocusBorder();

};


#endif

