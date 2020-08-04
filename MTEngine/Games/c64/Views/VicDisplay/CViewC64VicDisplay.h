#ifndef _CViewC64VicDisplay_H_
#define _CViewC64VicDisplay_H_

#include "CGuiWindow.h"
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
class CViewC64VicControl;
class C64CharMulti;
class C64CharHires;
class C64VicDisplayCanvas;
class C64VicDisplayCanvasBlank;
class C64VicDisplayCanvasHiresText;
class C64VicDisplayCanvasMultiText;
class C64VicDisplayCanvasExtendedText;
class C64VicDisplayCanvasHiresBitmap;
class C64VicDisplayCanvasMultiBitmap;

enum
{
	AUTOSCROLL_DISASSEMBLE_UNKNOWN	=	0,
	AUTOSCROLL_DISASSEMBLE_RASTER_PC,
	AUTOSCROLL_DISASSEMBLE_BITMAP_ADDRESS,
	AUTOSCROLL_DISASSEMBLE_TEXT_ADDRESS,
	AUTOSCROLL_DISASSEMBLE_COLOUR_ADDRESS,
	AUTOSCROLL_DISASSEMBLE_CHARSET_ADDRESS
};

enum
{
	VIC_DISPLAY_SHOW_BORDER_NONE = 0,
	VIC_DISPLAY_SHOW_BORDER_VISIBLE_AREA = 1,
	VIC_DISPLAY_SHOW_BORDER_FULL = 2,
};


class CViewC64VicDisplay : public CGuiWindow
{
public:
	
	// TODO: hide GuiButtons is temporary, it should be avoided and another view just for these buttons must be created
	//       keep CViewC64VicDisplay just a generic display view with callbacks

	CViewC64VicDisplay(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   C64DebugInterface *debugInterface);

	CViewC64VicDisplay(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
					   C64DebugInterface *debugInterface,
					   CSlrString *windowName, u32 mode, CGuiWindowCallback *callback);
	virtual ~CViewC64VicDisplay();
	
	
	void Initialize(C64DebugInterface *debugInterface);
	void SetVicControlView(CViewC64VicControl *vicControl);

	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();

	virtual bool IsInside(GLfloat x, GLfloat y);

	bool IsInsideDisplay(float x, float y);
	bool IsInsideScreen(float x, float y);
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);

	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	void UpdateDisplayFrame();
	void ZoomDisplay(float newScale);
	void MoveDisplayDiff(float diffX, float diffY);
	void MoveDisplayToScreenPos(float px, float py);
	
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

	CImageData *imageDataScreen;
	CSlrImage *imageScreen;

	// global position offset for positioning with topbar in VIC Editor
	float posOffsetX;
	float posOffsetY;
	
	//
	float scale;
	
	//
	void GetRasterPosFromScreenPos2(float x, float y, float *rasterX, float *rasterY);
	void GetRasterPosFromScreenPosWithoutScroll(float x, float y, float *rasterX, float *rasterY);
	void GetRasterPosFromMousePos2(float *rasterX, float *rasterY);
	void GetRasterPosFromMousePosWithoutScroll(float *rasterX, float *rasterY);
	void GetScreenPosFromRasterPos2(float rasterX, float rasterY, float *x, float *y);
	void GetScreenPosFromRasterPosWithoutScroll(float rasterX, float rasterY, float *x, float *y);
	
	void UpdateAutoscrollDisassemble(bool isForced);
	
	bool ScrollMemoryAndDisassembleToRasterPosition(float rx, float ry, bool forced);
	void RasterCursorLeft();
	void RasterCursorRight();
	void RasterCursorUp();
	void RasterCursorDown();

//	vicii_cycle_state_t *currentViciiState;
	
	void GetViciiPointers(vicii_cycle_state_t *viciiState,
						  u8 **screen_ptr, u8 **color_ram_ptr, u8 **chargen_ptr,
						  u8 **bitmap_low_ptr, u8 **bitmap_high_ptr,
						  u8 *colors);
	void RefreshScreen(vicii_cycle_state_t *viciiState);
	void RefreshScreenImageData(vicii_cycle_state_t *viciiState, u8 backgroundColorAlpha, u8 foregroundColorAlpha);
	
	//
	void RefreshScreenStateOnly(vicii_cycle_state_t *viciiState);
	
	float screenTexEndX, screenTexEndY;
	
	C64DebugInterface *debugInterface;
	
	virtual void SetPosition(GLfloat posX, GLfloat posY);
	
	void SetDisplayPosition(float posX, float posY, float scale, bool updateViewAspectRatio);
	
	void SetDisplayScale(float scale);
	
	//
	void RenderDisplay();
	void RenderDisplayScreen();
	void RenderDisplayScreen(CSlrImage *imageScreenToRender);
	void RenderDisplaySprites(vicii_cycle_state_t *viciiState);
	void RenderDisplaySpritesOnly(vicii_cycle_state_t *viciiState);
	void RenderGridSpritesOnly(vicii_cycle_state_t *viciiState);

	void RenderGridLines();
	void RenderCursor();
	void RenderCursor(float rasterCursorPosX, float rasterCursorPosY);
			 
	bool IsRasterCursorInsideScreen();
	vicii_cycle_state_t *UpdateViciiState();
	void CopyViciiStateFromCurrent();
	vicii_cycle_state_t *UpdateViciiStateNonVisible(float rx, float ry);
	
	float rasterCursorPosX, rasterCursorPosY;
	void UpdateRasterCursorPos();
	void ClearRasterCursorPos();
	
	void LockCursor();
	void UnlockCursor();

	CSlrFont *font;
	float fontScale;
	float fontHeight;
	
	// screen is full scan with borders
	float fullScanScreenPosX;
	float fullScanScreenPosY;
	float fullScanScreenSizeX;
	float fullScanScreenSizeY;
	
	// display is interior part of c64 screen
	float displayPosX;
	float displayPosY;
	float displayPosWithScrollX;
	float displayPosWithScrollY;
	float displaySizeX;
	float displaySizeY;
	
	// visible screen with borders
	float visibleScreenPosX;
	float visibleScreenPosY;
	float visibleScreenSizeX;
	float visibleScreenSizeY;

	void SetScreenAndDisplaySize(float dPosX, float dPosY, float dSizeX, float dSizeY);
	
	//
	virtual void RenderFocusBorder();
	
	void UpdateDisplayPosFromScrollRegister(vicii_cycle_state_t *viciiState);

	//
	bool showRasterCursor;

	void UpdateRasterCrossFactors();
	
	float rasterScaleFactorX;
	float rasterScaleFactorY;

	float screenScaleFactorX;
	float screenScaleFactorY;

	float rasterCrossOffsetX;
	float rasterCrossOffsetY;
	
	float rasterCrossWidth;
	float rasterCrossWidth2;
	
	float rasterCrossSizeX;
	float rasterCrossSizeY;
	float rasterCrossSizeX2;
	float rasterCrossSizeY2;
	float rasterCrossSizeX34;
	float rasterCrossSizeY34;
	float rasterCrossSizeX3;
	float rasterCrossSizeY3;
	float rasterCrossSizeX4;
	float rasterCrossSizeY4;
	float rasterCrossSizeX6;
	float rasterCrossSizeY6;
	
	/// long screen line
	float rasterLongScrenLineR;
	float rasterLongScrenLineG;
	float rasterLongScrenLineB;
	float rasterLongScrenLineA;
	
	// red cross
	float rasterCrossExteriorR;
	float rasterCrossExteriorG;
	float rasterCrossExteriorB;
	float rasterCrossExteriorA;
	
	// cross ending tip
	float rasterCrossEndingTipR;
	float rasterCrossEndingTipG;
	float rasterCrossEndingTipB;
	float rasterCrossEndingTipA;
	
	// white interior cross
	float rasterCrossInteriorR;
	float rasterCrossInteriorG;
	float rasterCrossInteriorB;
	float rasterCrossInteriorA;

	// TODO: move this to Tools
	void InitRasterColorsFromScheme();
	void GetRasterColorScheme(int schemeNum, float splitAmount, float *r, float *g, float *b);
	
	void InitGridLinesColorFromSettings();
	
	void RenderRasterCursor(int rasterX, int rasterY);
	
	void RenderBadLines();
	
	bool showGridLines;
	
	float gridLinesColorR;
	float gridLinesColorG;
	float gridLinesColorB;
	float gridLinesColorA;

	float gridLinesColorR2;
	float gridLinesColorG2;
	float gridLinesColorB2;
	float gridLinesColorA2;

	
	// frame for display
	bool renderDisplayFrame;
	float displayFrameRasterX, displayFrameRasterY, displayFrameRasterSizeX, displayFrameRasterSizeY;		// in c64's coordinates
	float displayFrameScreenPosX, displayFrameScreenPosY, displayFrameScreenSizeX, displayFrameScreenSizeY;	// in view/screen coordinates
	void UpdateDisplayFrameScreen();
	
	void SetDisplayFrameRaster(float rasterX, float rasterY, float rasterSizeX, float rasterSizeY);
	
	//
	u16 screenAddress;
	int bitmapAddress;
	int charsetAddress;
	
	int GetAddressForRaster(int x, int y);
	int GetScreenAddressForRaster(int x, int y);
	int GetBitmapModeAddressForRaster(int x, int y);
	int GetColorAddressForRaster(int x, int y);
	int GetCharsetAddressForRaster(int x, int y);
	
	int currentVicMode;
	
	u8 showDisplayBorderType;
	void SetShowDisplayBorderType(u8 borderType);

	bool showSpritesGraphics;
	bool showSpritesFrames;
	
	bool canScrollDisassemble;
	
	bool isCursorLocked;
	
	byte autoScrollMode;
	void SetAutoScrollMode(int newMode);
	void SetNextAutoScrollMode();
	
	//
	bool applyScrollRegister;
	int scrollInRasterPixelsX;
	int scrollInRasterPixelsY;
	
	//
	bool arrowKeyDown;
	bool foundMemoryCellPC;
	
	void ResetCursorLock();
	
	// control UI of this VIC Display
	CViewC64VicControl *viewVicControl;
	
	//
	//
	C64VicDisplayCanvas *currentCanvas;
	void RefreshCurrentCanvas(vicii_cycle_state_t *viciiState);
	void SetCurrentCanvas(u8 bm, u8 mc, u8 eb, u8 blank);
	
	//
	std::list<u32> shortcutZones;
	
	void ToggleVICRasterBreakpoint();

	bool backupRenderDataWithColors;
	
	u8 backgroundColorAlpha;
	u8 foregroundColorAlpha;
	
private:

	C64VicDisplayCanvasBlank *canvasBlank;
	C64VicDisplayCanvasHiresText *canvasHiresText;
	C64VicDisplayCanvasMultiText *canvasMultiText;
	C64VicDisplayCanvasExtendedText *canvasExtendedText;
	C64VicDisplayCanvasHiresBitmap *canvasHiresBitmap;
	C64VicDisplayCanvasMultiBitmap *canvasMultiBitmap;
	
	bool updateViewAspectRatio;
};

#endif //_CViewC64VicDisplay_H_
