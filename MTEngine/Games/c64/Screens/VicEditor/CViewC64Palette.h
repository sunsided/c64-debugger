#ifndef _CViewC64Palette_H_
#define _CViewC64Palette_H_

#include "SYS_Defs.h"
#include "CGuiWindow.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;

class CViewC64PaletteCallback
{
public:
	// callback from palette on change color
	virtual void PaletteColorChanged(u8 colorSource, u8 newColorValue);
};

class CViewC64Palette : public CGuiWindow, public CGuiEditHexCallback
{
public:
	CViewC64Palette(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewC64PaletteCallback *callback);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);

	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	void SetPosition(float posX, float posY, float posZ, float scale);
	void SetPosition(float posX, float posY, float sizeX, bool isVertical);
	
	virtual void Render();
	virtual void DoLogic();
	
	virtual bool SetFocus(bool focus);

	void RenderPalette(bool renderBackgroundInformation);

	//
	CViewC64PaletteCallback *callback;
	
	void SetPaletteRectScale(float scale);
	
	int GetColorIndex(float x, float y);
	
	void SetColorLMB(u8 color);
	void SetColorRMB(u8 color);
	
	bool isVertical;

	float gap1;
	float gap2;
	float rectSize;
	float rectSize4;
	float rectSizeBig;
	
	//
	u8 colorD020;
	u8 colorD021;
	u8 colorLMB;
	u8 colorRMB;

	
};


#endif

