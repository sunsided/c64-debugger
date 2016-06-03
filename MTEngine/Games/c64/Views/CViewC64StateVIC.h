#ifndef _CVIEWC64STATEVID_H_
#define _CVIEWC64STATEVID_H_

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

class CViewC64StateVIC : public CGuiView, CGuiEditHexCallback
{
public:
	CViewC64StateVIC(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	float fontSize;
	
	float fontBytesSize;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	C64DebugInterface *debugInterface;

	std::vector<CImageData *> *spritesImageData;
	std::vector<CSlrImage *> *spritesImages;

	bool isVertical;
	
	virtual void SetFocus(bool focus);

};



#endif

