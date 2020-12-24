#ifndef _VIEW_C64MEMORYDEBUGGERLAYOUTTOOLBAR_
#define _VIEW_C64MEMORYDEBUGGERLAYOUTTOOLBAR_

#include "CGuiView.h"
#include "CGuiButtonSwitch.h"

class CDebugInterface;

class CViewC64MemoryDebuggerLayoutToolbar : public CGuiView, CGuiButtonSwitchCallback
{
public:
	CViewC64MemoryDebuggerLayoutToolbar(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CDebugInterface *debugInterface);
	virtual ~CViewC64MemoryDebuggerLayoutToolbar();

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
	
	virtual void SetPosition(GLfloat posX, GLfloat posY);
	virtual bool IsFocusable();

	virtual void ActivateView();
	virtual void DeactivateView();

	void UpdateStateFromButtons();
	
	CGuiButton *btnDone;
	virtual bool ButtonClicked(CGuiButton *button);
	virtual bool ButtonPressed(CGuiButton *button);
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

	CDebugInterface *debugInterface;
	
	CSlrFont *font;
	float fontScale;
	float fontHeight;

	CGuiButtonSwitch *btnMemoryDump1IsFromDisk;
	CGuiButtonSwitch *btnMemoryDump2IsFromDisk;
	CGuiButtonSwitch *btnMemoryDump3IsFromDisk;
	
	float fontSize;
};

#endif //_VIEW_TIMELINE_
