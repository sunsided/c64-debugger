#ifndef _CViewC64Sprite_H_
#define _CViewC64Sprite_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include "C64Sprite.h"
#include "CGuiButtonSwitch.h"
#include "CGuiViewToolBox.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;
class C64Sprite;

class CViewC64Sprite : public CGuiWindow, CGuiEditHexCallback, CGuiButtonSwitchCallback, public CGuiViewToolBoxCallback, public CGuiWindowCallback, CSystemFileDialogCallback
{
public:
	CViewC64Sprite(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewVicEditor *vicEditor);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoRightClick(GLfloat x, GLfloat y);
//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);

	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	virtual bool SetFocus(bool focus);
	
	//
	CViewVicEditor *vicEditor;
	
	CImageData *imageDataSprite;
	CSlrImage *imageSprite;
	
	bool isSpriteLocked;
	
	int spriteRasterX;
	int spriteRasterY;
	
	CSlrFont *font;
	float fontScale;
	float fontWidth;
	float fontHeight;

	CGuiButtonSwitch *btnScanForSprites;

	CGuiButtonSwitch *btnIsMultiColor;
	CGuiButtonSwitch *btnIsStretchX;
	CGuiButtonSwitch *btnIsStretchY;

	int prevSpriteId;
	
	int selectedColor;
	
	u8 paintColorD021;
	u8 paintColorSprite;
	u8 paintColorD025;
	u8 paintColorD026;
	
	u8 GetPaintColorByNum(u8 colorNum);
	
	vicii_cycle_state_t *viciiState;
	
	// callback from palette on change color
	virtual void PaletteColorChanged(u8 colorSource, u8 newColorValue);

	void UpdateSelectedColorInPalette();
	
	//
	void MoveSelectedSprite(int deltaX, int deltaY);

	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

	//
	CSlrImage *imgIconExport;
	CSlrImage *imgIconImport;

	virtual void ToolBoxIconPressed(CSlrImage *imgIcon);
	
	std::list<CSlrString *> spriteFileExtensions;
	
	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();
	
	uint8 currentSpriteData[63];

	// returns sprite addr
	int ImportSprite(CSlrString *path);
	void ExportSprite(CSlrString *path);

};


#endif

