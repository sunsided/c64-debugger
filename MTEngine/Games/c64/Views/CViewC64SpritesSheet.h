#ifndef _C64_VIEW_SPRITES_SHEET_
#define _C64_VIEW_SPRITES_SHEET_

#include "CGuiView.h"
#include "CGuiLabel.h"
#include "CGuiLockableList.h"
#include "CGuiButtonSwitch.h"

class C64DebugInterface;
class CViewC64VicDisplay;
class CViewC64VicControl;
class CSlrFont;

#define VIEW_C64_ALL_GRAPHICS_MODE_BITMAPS	1
#define VIEW_C64_ALL_GRAPHICS_MODE_SCREENS	2
#define VIEW_C64_ALL_GRAPHICS_MODE_SPRITES	3

#define VIEW_C64_ALL_GRAPHICS_FORCED_NONE	0
#define VIEW_C64_ALL_GRAPHICS_FORCED_GRAY	1
#define VIEW_C64_ALL_GRAPHICS_FORCED_HIRES	2
#define VIEW_C64_ALL_GRAPHICS_FORCED_MULTI	3

class CViewC64SpritesSheet : public CGuiView, CGuiButtonSwitchCallback, CGuiListCallback
{
public:
	CViewC64SpritesSheet(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	virtual ~CViewC64SpritesSheet();

	C64DebugInterface *debugInterface;
	
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	virtual bool DoScrollWheel(float deltaX, float deltaY);

	// multi touch
	virtual bool DoMultiTap(COneTouchData *touch, float x, float y);
	virtual bool DoMultiMove(COneTouchData *touch, float x, float y);
	virtual bool DoMultiFinishTap(COneTouchData *touch, float x, float y);

	virtual void FinishTouches();

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyPressed(u32 keyCode, bool isShift, bool isAlt, bool isControl);	// repeats
	
	virtual void ActivateView();
	virtual void DeactivateView();

	CSlrFont *font;
	float fontScale;
	float fontHeight;

	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

	int displayMode;
	void SetMode(int newMode);
	
	int numBitmapDisplays;
	int numScreenDisplays;
	
	CViewC64VicDisplay **vicDisplays;
	CViewC64VicControl **vicControl;
	int numVicDisplays;
	
	int numVisibleDisplays;
	int numDisplaysColumns;
	int numDisplaysRows;
	
	CGuiButtonSwitch *btnModeBitmapColorsGrayscale;
	CGuiButtonSwitch *btnModeHires;
	CGuiButtonSwitch *btnModeMulti;
	void SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn);
	void SetLockableButtonDefaultColors(CGuiButtonSwitch *btn);
//	void SetButtonState(CGuiButtonSwitch *btn, bool isSet);
	
	CGuiLabel *lblScreenAddress;
	CGuiLockableList *lstScreenAddresses;

	virtual bool ListElementPreSelect(CGuiList *listBox, int elementNum);

	volatile u8 forcedRenderScreenMode;
};

#endif //_C64_VIEW_SPRITES_SHEET_
