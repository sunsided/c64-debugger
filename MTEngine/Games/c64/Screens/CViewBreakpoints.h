#ifndef _VIEW_C64BREAKPOINTS_
#define _VIEW_C64BREAKPOINTS_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiButtonSwitch.h"
#include "CGuiLabel.h"
#include "CGuiEditHex.h"
#include "CColorsTheme.h"

class CAddrBreakpoint;
class CMemoryBreakpoint;
class CDebuggerAddrBreakpoints;
class CDebuggerMemoryBreakpoints;

class CViewBreakpoints : public CGuiView, CGuiButtonSwitchCallback, CGuiEditHexCallback
{
public:
	CViewBreakpoints(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, CDebugInterface *debugInterface);
	virtual ~CViewBreakpoints();

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

	CGuiButton *btnDone;
	bool ButtonClicked(CGuiButton *button);
	bool ButtonPressed(CGuiButton *button);
	
	CDebugInterface *debugInterface;
	
	CSlrFont *font;
	float fontScale;
	float fontWidth;
	float fontHeight;
	float fontNumbersScale;
	float fontNumbersWidth;
	float fontNumbersHeight;
	
	float tr;
	float tg;
	float tb;
	
	char buf[128];
	
	CSlrString *strHeader;

	CGuiLabel *lblPlatform;
	CGuiButtonSwitch *btnBreakpointsPC;
	CGuiButtonSwitch *btnBreakpointsMemory;
	CGuiButtonSwitch *btnBreakpointsRaster;

	CGuiButtonSwitch *btnBreakpointC64IrqVIC;
	CGuiButtonSwitch *btnBreakpointC64IrqCIA;
	CGuiButtonSwitch *btnBreakpointC64IrqNMI;

	CGuiLabel *lbl1541Drive;
	CGuiButtonSwitch *btnBreakpointDrive1541IrqVIA1;
	CGuiButtonSwitch *btnBreakpointDrive1541IrqVIA2;
	CGuiButtonSwitch *btnBreakpointDrive1541IrqIEC;
	CGuiButtonSwitch *btnBreakpointsDrive1541PC;
	CGuiButtonSwitch *btnBreakpointsDrive1541Memory;

	
	float pcBreakpointsX;
	float pcBreakpointsY;
	float memoryBreakpointsX;
	float memoryBreakpointsY;
	float rasterBreakpointsX;
	float rasterBreakpointsY;

	float Drive1541PCBreakpointsX;
	float Drive1541PCBreakpointsY;
	float Drive1541MemoryBreakpointsX;
	float Drive1541MemoryBreakpointsY;
	float Drive1541RasterBreakpointsX;
	float Drive1541RasterBreakpointsY;

	int cursorGroup;
	int cursorElement;
	int cursorPosition;
	
	CSlrString *strTemp;
	
	void SwitchBreakpointsScreen();
	void UpdateCursor();
	void ClearCursor();

	bool isEditingValue;
	
	virtual bool ButtonSwitchChanged(CGuiButtonSwitch *button);

	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);

	CAddrBreakpoint *editingBreakpoint;
	CGuiEditHex *editHex;

	void UpdateRenderBreakpoints();
	
	//
	void RenderAddrBreakpoints(CDebuggerAddrBreakpoints *addrBreakpoints, float pStartX, float pStartY, int cursorGroupId,
							   char *addrFormatStr, char *addrEmptyStr);
	void RenderMemoryBreakpoints(CDebuggerMemoryBreakpoints *memoryBreakpoints, float pStartX, float pStartY, int cursorGroupId);
	
	bool CheckTapAddrBreakpoints(float x, float y,
								 CDebuggerAddrBreakpoints *addrBreakpoints,
								 float pStartX, float pStartY, int cursorGroupId);
	
	bool CheckTapMemoryBreakpoints(float x, float y,
								   CDebuggerMemoryBreakpoints *memoryBreakpoints,
								   float pStartX, float pStartY, int cursorGroupId);

	
	void GuiEditHexEnteredValueAddr(CGuiEditHex *editHex, CDebuggerAddrBreakpoints *addrBreakpoints);
	void GuiEditHexEnteredValueMemory(CGuiEditHex *editHex, u32 lastKeyCode, CDebuggerMemoryBreakpoints *memoryBreakpoints);
	
	void StartEditingSelectedAddrBreakpoint(CDebuggerAddrBreakpoints *addrBreakpoints, char *emptyAddrStr);
	void StartEditingSelectedMemoryBreakpoint(CDebuggerMemoryBreakpoints *memoryBreakpoints);
	
	void DeleteSelectedAddrBreakpoint(CDebuggerAddrBreakpoints *addrBreakpoints);
	void DeleteSelectedMemoryBreakpoint(CDebuggerMemoryBreakpoints *memoryBreakpoints);
	
	CGuiView *prevView;
	
	virtual void UpdateTheme();
};

#endif //_VIEW_C64BREAKPOINTS_
