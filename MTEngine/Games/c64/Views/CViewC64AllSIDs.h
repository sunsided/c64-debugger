#ifndef _C64_VIEW_ALL_SIDS_
#define _C64_VIEW_ALL_SIDS_

#include "CGuiView.h"
#include "CGuiLabel.h"
#include "CGuiLockableList.h"
#include "CGuiButtonSwitch.h"
#include "CViewSIDPianoKeyboard.h"

class C64DebugInterface;
class CViewC64VicDisplay;
class CViewC64VicControl;
class CViewSIDTrackerHistory;
class CSlrFont;

class CViewC64AllSIDs : public CGuiView, CGuiButtonSwitchCallback, CGuiListCallback
{
public:
	CViewC64AllSIDs(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	virtual ~CViewC64AllSIDs();

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
	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

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

	virtual bool SetFocus(CGuiElement *view);

	CSIDPianoKeyboard *viewPianoKeyboard;
	CViewSIDTrackerHistory *viewTrackerHistory;
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;

	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

//	CGuiButtonSwitch *btnShowBitmaps;
//	CGuiButtonSwitch *btnShowScreens;
//	CGuiButtonSwitch *btnShowCharsets;
//	CGuiButtonSwitch *btnShowSprites;
//
//	CGuiButtonSwitch *btnModeBitmapColorsGrayscale;
//	CGuiButtonSwitch *btnModeHires;
//	CGuiButtonSwitch *btnModeMulti;
	void SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn);
	void SetLockableButtonDefaultColors(CGuiButtonSwitch *btn);
//	void SetButtonState(CGuiButtonSwitch *btn, bool isSet);
	
};

#endif //_C64_VIEW_ALL_GRAPHICS_
