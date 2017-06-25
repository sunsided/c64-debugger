#ifndef _C64VICDISPLAYCANVAS_H_
#define _C64VICDISPLAYCANVAS_H_

#include "SYS_Defs.h"
#include "ViceWrapper.h"
#include <vector>

class CViewC64VicDisplay;
class C64DebugInterface;
class CImageData;

enum c64CanvasType : u8
{
	C64_CANVAS_TYPE_BLANK	= 0,
	C64_CANVAS_TYPE_BITMAP	= 1,
	C64_CANVAS_TYPE_TEXT	= 2,
};

enum
{
	VICEDITOR_COLOR_SOURCE_LMB = 1,
	VICEDITOR_COLOR_SOURCE_RMB = 2
};

enum
{
	PAINT_RESULT_ERROR			= 0,
	PAINT_RESULT_OUTSIDE		= 1,
	PAINT_RESULT_BLOCKED		= 2,
	PAINT_RESULT_OK				= 10,
	PAINT_RESULT_REPLACED_COLOR	= 11,
};

class C64ColorsHistogramElement
{
public:
	C64ColorsHistogramElement(u8 color, int num) { this->color = color; this->num = num; };
	u8 color;
	int num;
};

//class C64ColorsHistogramElement
//{
//public:
//	C64ColorsHistogramElement(u8 color, int num) { this->color = color; this->num = num; };
//	u8 color;
//	int num;
//};


class C64VicDisplayCanvas
{
public:
	C64VicDisplayCanvas(CViewC64VicDisplay *vicDisplay, u8 canvasType, bool isMultiColor, bool isExtendedColor);
	
	u8 canvasType;
	
	bool isMultiColor;
	bool isExtendedColor;
	
	CViewC64VicDisplay *vicDisplay;
	C64DebugInterface *debugInterface;
	
	vicii_cycle_state_t *viciiState;

	virtual u8 GetColorAtPixel(int x, int y);
	
	// @returns painting status (ok, replaced color, blocked)
	virtual u8 PutColorAtPixel(bool forceColorReplace, int x, int y, u8 colorLMB, u8 colorRMB, u8 colorSource, int charValue);
	
	// @returns painting status (ok, replaced color, blocked)
	virtual u8 PaintDither(bool forceColorReplace, int x, int y, u8 colorLMB, u8 colorRMB, u8 colorSource, int charValue);

	// @returns painting status (ok, replaced color, blocked)
	// this is main Paint function:
	virtual u8 Paint(bool forceColorReplace, bool isDither, int x, int y, u8 colorLMB, u8 colorRMB, u8 colorSource, int charValue);
	
	virtual void ClearDitherMask();
	int ditherMaskPosX;
	int ditherMaskPosY;

	// note that viciiState pointer is copied in RefreshScreen which is then used for other methods
	virtual void RefreshScreen(vicii_cycle_state_t *viciiState, CImageData *imageDataScreen);
	virtual void RenderGridLines();
	
	virtual void RenderCanvasSpecificGridLines();
	virtual void RenderCanvasSpecificGridValues();
	
	virtual void ClearScreen();
	virtual void ClearScreen(u8 charValue, u8 colorValue);

	virtual u8 ConvertFrom(CImageData *imageData);
	
	// finds background color (the color that has highest number of appearances)
	virtual std::vector<C64ColorsHistogramElement *> *GetSortedColorsHistogram(CImageData *imageData);
	virtual void DeleteColorsHistogram(std::vector<C64ColorsHistogramElement *> *colors);
	
	// reduces color space to C64 colors only (nearest)
	virtual CImageData *ReducePalette(CImageData *imageData);
};

#endif
