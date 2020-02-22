#ifndef _CVIEWEMULATIONCOUNTERS_H_
#define _CVIEWEMULATIONCOUNTERS_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class CDebugInterface;

class CViewEmulationCounters : public CGuiView, CGuiEditHexCallback
{
public:
	CViewEmulationCounters(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CDebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	CDebugInterface *debugInterface;

	float fontSize;	
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();	
	
	virtual bool SetFocus(bool focus);

	//
	virtual void RenderEmulationCounters(float px, float py, float posZ, CSlrFont *fontBytes, float fontSize);
	
	
	//
	virtual void RenderFocusBorder();

};


#endif

