#ifndef _CVIEWC64STATEVID_H_
#define _CVIEWC64STATEVID_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
extern "C"
{
#include "ViceWrapper.h"
};

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
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);

	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	float fontSize;
	
	float fontBytesSize;

	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	void RenderColorRectangle(float px, float py, float ledSizeX, float ledSizeY, float gap, bool isLocked, u8 color);
	
	void UpdateSpritesImages();
	
	C64DebugInterface *debugInterface;

	std::vector<CImageData *> *spritesImageData;
	std::vector<CSlrImage *> *spritesImages;

	bool isVertical;
	bool showSprites;
	
	virtual bool SetFocus(bool focus);

	volatile bool isLockedState;
	
	// force colors D020-D02E, -1 = don't force
	int forceColors[0x0F];
	int forceColorD800;
};



#endif

