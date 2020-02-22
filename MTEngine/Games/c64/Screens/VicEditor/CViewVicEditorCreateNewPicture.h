#ifndef _CViewVicEditorCreateNewPicture_H_
#define _CViewVicEditorCreateNewPicture_H_

#include "SYS_Defs.h"
#include "CGuiWindow.h"
#include "CGuiEditHex.h"
#include "CGuiViewFrame.h"
#include "CGuiList.h"
#include "CGuiButtonSwitch.h"
#include "CViewC64Palette.h"
#include "CGuiLabel.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class C64DebugInterface;
class CViewVicEditor;
class CVicEditorLayer;
class CViewC64Palette;

class CViewVicEditorCreateNewPicture : public CGuiWindow, public CGuiListCallback, CGuiButtonSwitchCallback, CViewC64PaletteCallback
{
public:
	CViewVicEditorCreateNewPicture(GLfloat posX, GLfloat posY, GLfloat posZ, CViewVicEditor *vicEditor);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
//	virtual bool DoFinishRightClick(GLfloat x, GLfloat y);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);

	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	
	virtual void Render();
	virtual void DoLogic();
	
	virtual bool SetFocus(bool focus);
	
	//
	CViewVicEditor *vicEditor;
	
	CSlrFont *font;
	float fontScale;
	
	CGuiButton *btnNewPictureModeTextHires;
	CGuiButton *btnNewPictureModeTextMulti;
	CGuiButton *btnNewPictureModeBitmapHires;
	CGuiButton *btnNewPictureModeBitmapMulti;
//	CGuiButton *btnNewPictureModeHyper;
	
	virtual void ActivateView();

	virtual bool ButtonPressed(CGuiButton *button);

	CViewC64Palette *viewPalette;
	
	void CreateNewPicture(u8 mode, u8 backgroundColor, bool storeUndo);
	
	//
	CGuiLabel *lblPictureMode;
	CGuiLabel *lblBackgroundColor;
	
};


#endif

