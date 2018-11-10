#ifndef _CVIEWC64STATEDRIVE1541_H_
#define _CVIEWC64STATEDRIVE1541_H_

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

// TODO: make base class to have Vice specific state rendering and editing
//       class CViewDrive1541ViceStateVIA : public CViewDrive1541StateVIA

class CViewDrive1541StateVIA : public CGuiView, CGuiEditHexCallback
{
public:
	CViewDrive1541StateVIA(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual bool DoTap(GLfloat x, GLfloat y);

	CSlrFont *fontBytes;	
	float fontSize;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	virtual void Render();
	virtual void DoLogic();
	
	C64DebugInterface *debugInterface;
	
	void DumpViaInts(uint8 i, char *buf);
	
	virtual bool SetFocus(bool focus);

	bool renderVIA1;
	bool renderVIA2;
	bool renderDriveLED;
	bool isVertical;
	
	virtual void RenderStateDrive1541(float posX, float posY, float posZ, CSlrFont *fontBytes, float fontSize,
									  int driveId, 
									  bool renderVia1, bool renderVia2, bool renderDriveLed, bool isVertical);
	bool showRegistersOnly;
	
	// editing registers
	int editingRegisterValueIndex;		// -1 means no editing
	int editingVIAIndex;
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);
	
	//
	virtual void RenderFocusBorder();
};


#endif

