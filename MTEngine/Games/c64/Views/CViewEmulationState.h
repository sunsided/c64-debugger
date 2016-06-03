#ifndef _CVIEWEMULATIONSTATE_H_
#define _CVIEWEMULATIONSTATE_H_

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

class CViewEmulationState : public CGuiView, CGuiEditHexCallback
{
public:
	CViewEmulationState(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual bool DoTap(GLfloat x, GLfloat y);

	CSlrFont *fontBytes;	
	float fontSize;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	virtual void Render();
	virtual void DoLogic();
	
	C64DebugInterface *debugInterface;
	
	virtual void SetFocus(bool focus);
};


#endif

