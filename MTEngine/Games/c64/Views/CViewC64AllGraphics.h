#ifndef _C64_VIEW_ALL_GRAPHICS_
#define _C64_VIEW_ALL_GRAPHICS_

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
#define VIEW_C64_ALL_GRAPHICS_MODE_CHARSETS	3
#define VIEW_C64_ALL_GRAPHICS_MODE_SPRITES	4

#define VIEW_C64_ALL_GRAPHICS_FORCED_NONE	0
#define VIEW_C64_ALL_GRAPHICS_FORCED_GRAY	1
#define VIEW_C64_ALL_GRAPHICS_FORCED_HIRES	2
#define VIEW_C64_ALL_GRAPHICS_FORCED_MULTI	3

class CViewC64AllGraphics : public CGuiView, CGuiButtonSwitchCallback, CGuiListCallback
{
public:
	CViewC64AllGraphics(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, C64DebugInterface *debugInterface);
	virtual ~CViewC64AllGraphics();

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

	float charsetScale;
	float charsetSizeX;
	float charsetSizeY;
	float charsetScaleB;
	float charsetSizeXB;
	float charsetSizeYB;
	float spriteScale;
	float spriteSizeX;
	float spriteSizeY;
	float spriteScaleB;
	float spriteSizeXB;
	float spriteSizeYB;

	float charsetsOffsetY;
	
	CGuiButtonSwitch *btnShowBitmaps;
	CGuiButtonSwitch *btnShowScreens;
	CGuiButtonSwitch *btnShowCharsets;
	CGuiButtonSwitch *btnShowSprites;

	CGuiButtonSwitch *btnModeBitmapColorsGrayscale;
	CGuiButtonSwitch *btnModeHires;
	CGuiButtonSwitch *btnModeMulti;
	void SetSwitchButtonDefaultColors(CGuiButtonSwitch *btn);
	void SetLockableButtonDefaultColors(CGuiButtonSwitch *btn);
//	void SetButtonState(CGuiButtonSwitch *btn, bool isSet);
	
	CGuiLabel *lblScreenAddress;
	CGuiLockableList *lstScreenAddresses;

	CGuiLabel *lblCharsetAddress;
	CGuiLockableList *lstCharsetAddresses;

	CGuiButtonSwitch *btnShowRAMorIO;
	void UpdateShowIOButton();
	
	virtual bool ListElementPreSelect(CGuiList *listBox, int elementNum);

	volatile u8 forcedRenderScreenMode;

	bool GetIsSelectedItem();
	void SetIsSelectedItem(bool isSelected);
	bool isSelectedItemBitmap;
	bool isSelectedItemScreen;
	bool isSelectedItemCharset;
	bool isSelectedItemSprite;
	volatile int selectedBitmapId;
	volatile int selectedScreenId;
	volatile int selectedCharsetId;
	volatile int selectedSpriteId;

	int GetItemIdAt(float x, float y);
	int GetSelectedItemId();
	void SetSelectedItemId(int itemId);
	
	// sprites
	std::vector<CImageData *> spritesImageData;
	std::vector<CSlrImage *> spritesImages;
	void UpdateSprites(bool useColors, u8 colorD021, u8 colorD025, u8 colorD026, u8 colorD027);
	
	// charsets
	std::vector<CImageData *> charsetsImageData;
	std::vector<CSlrImage *> charsetsImages;
	void UpdateCharsets(bool useColors, u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800);
	
	// handle ctrl+k shortcut
	void UpdateRenderDataWithColors();

	void ClearRasterCursorPos();
	void ClearGraphicsForcedMode();
};

#endif //_C64_VIEW_ALL_GRAPHICS_
