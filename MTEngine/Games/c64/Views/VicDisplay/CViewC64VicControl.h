#ifndef _CViewC64VicControl_H_
#define _CViewC64VicControl_H_

#include "CGuiView.h"
#include "CGuiLockableList.h"
#include "CGuiButtonSwitch.h"
#include "CGuiLabel.h"
#include "CGuiViewFrame.h"

extern "C"
{
#include "ViceWrapper.h"
};

class CSlrMutex;
class C64DebugInterface;
class CSlrFont;
class CViewC64VicDisplay;

class CViewC64VicControl : public CGuiView, CGuiButtonSwitchCallback, CGuiListCallback
{
public:
	
	CViewC64VicControl(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CViewC64VicDisplay *vicDisplay);
	virtual ~CViewC64VicControl();
	
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();
	
	virtual bool IsInside(GLfloat x, GLfloat y);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);
	
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	
	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);
	
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
	
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
	
	void AddGuiButtons();
	void HideGuiButtons();
	
	float fontSize;
	
	void RefreshScreenStateOnly(vicii_cycle_state_t *viciiState);
	
	C64DebugInterface *debugInterface;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY);
	
	//
	CGuiButtonSwitch *btnModeText;
	CGuiButtonSwitch *btnModeBitmap;
	CGuiButtonSwitch *btnModeHires;
	CGuiButtonSwitch *btnModeMulti;
	CGuiButtonSwitch *btnModeStandard;
	CGuiButtonSwitch *btnModeExtended;
	void SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn);
	void SetLockableButtonDefaultColors(CGuiButtonSwitch *btn);
	void SetButtonState(CGuiButtonSwitch *btn, bool isSet);
	
	CGuiLabel *lblScreenAddress;
	CGuiLockableList *lstScreenAddresses;
	CGuiLabel *lblCharsetAddress;
	CGuiLockableList *lstCharsetAddresses;
	CGuiLabel *lblBitmapAddress;
	CGuiLockableList *lstBitmapAddresses;
	virtual bool ListElementPreSelect(CGuiList *listBox, int elementNum);

	CGuiButtonSwitch *btnApplyScrollRegister;
	void UpdateApplyScrollRegister();
	CGuiButtonSwitch *btnShowBadLines;

	CGuiButtonSwitch *btnShowWithBorder;
	CGuiButtonSwitch *btnShowGrid;
	
	CGuiButtonSwitch *btnShowSpritesGraphics;
	CGuiButtonSwitch *btnShowSpritesFrames;
	
	CGuiButtonSwitch *btnToggleBreakpoint;
	float txtCursorPosX, txtCursorPosY;
	float txtCursorCharPosX, txtCursorCharPosY;
	
	CGuiLabel *lblAutolockText;
	CGuiLabel *lblAutolockScrollMode;
	
	CSlrString *txtAutolockRasterPC;
	CSlrString *txtAutolockBitmapAddress;
	CSlrString *txtAutolockTextAddress;
	CSlrString *txtAutolockColourAddress;
	CSlrString *txtAutolockCharsetAddress;
	
	CGuiButtonSwitch *btnLockCursor;
	//	CGuiButton *btnCursorCycleLeft;
	//	CGuiButton *btnCursorCycleRight;
	//	CGuiButton *btnCursorRasterLineUp;
	//	CGuiButton *btnCursorRasterLineDown;
	
	void UnlockAll();
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;
	
	void SetBorderType(u8 borderType);
	void SwitchBorderType();
	
	//
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);
	virtual void RenderFocusBorder();
	
	
	//
	CGuiViewFrame *viewFrame;
	
	// VIC DISPLAY TO CONTROL
	CViewC64VicDisplay *vicDisplay;
	
	//
	void SetAutoScrollModeUI(int newMode);
	void SetViciiPointersFromUI(uint16 *screenAddress, int *charsetAddress, int *bitmapBank);
	void RefreshStateButtonsUI(u8 *mc, u8 *eb, u8 *bm, u8 *blank);

};

#endif //_CViewC64VicControl_H_
