#ifndef _VIEW_VICEDITOR_
#define _VIEW_VICEDITOR_

#include "CGuiView.h"
#include "CGuiButton.h"
#include "CGuiViewMenu.h"
#include "SYS_CFileSystem.h"
#include "CViewC64VicDisplay.h"
#include "CViewC64Palette.h"
#include "CViewC64Charset.h"
#include "CGlobalOSWindowChangedCallback.h"
#include "CViewVicEditorDisplayPreview.h"
#include <list>

class CSlrKeyboardShortcut;
class CViewC64MenuItem;
class CVicEditorLayer;
class CViewC64Sprite;
class CViewVicEditorLayers;

class CVicEditorLayerC64Screen;
class CVicEditorLayerC64Canvas;
class CVicEditorLayerC64Sprites;
class CVicEditorLayerVirtualSprites;
class CVicEditorLayerUnrestrictedBitmap;

enum
{
	VICEDITOR_EXPORT_UNKNOWN	= 0,
	VICEDITOR_EXPORT_VCE		= 1,
	VICEDITOR_EXPORT_HYPER		= 2,
	VICEDITOR_EXPORT_KOALA		= 3,
	VICEDITOR_EXPORT_ART_STUDIO	= 4,
	VICEDITOR_EXPORT_RAW_TEXT	= 5,
	VICEDITOR_EXPORT_PNG		= 6
};

class CViewVicEditor : public CGuiView, CGuiButtonCallback, CGuiViewMenuCallback, CSystemFileDialogCallback, CGlobalOSWindowChangedCallback
{
public:
	CViewVicEditor(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
	virtual ~CViewVicEditor();
	
	virtual void Render();
	virtual void Render(GLfloat posX, GLfloat posY);
	//virtual void Render(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY);
	virtual void DoLogic();
	
	virtual bool DoTap(GLfloat x, GLfloat y);
	virtual bool DoFinishTap(GLfloat x, GLfloat y);
	
	virtual bool DoDoubleTap(GLfloat x, GLfloat y);
	virtual bool DoFinishDoubleTap(GLfloat posX, GLfloat posY);
	
	virtual bool DoRightClick(GLfloat x, GLfloat y);
	virtual bool DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);
	
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	
	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

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
	
	virtual bool DoScrollWheel(float deltaX, float deltaY);

	CSlrFont *font;
	float fontScale;
	float fontHeight;
	float tr;
	float tg;
	float tb;
	
	CSlrString *strHeader;
	void SwitchToVicEditor();
	

	//
	CViewC64VicDisplay *viewVicDisplayMain;
	CViewVicEditorDisplayPreview *viewVicDisplaySmall;
	CViewC64Palette *viewPalette;
	CViewC64Charset *viewCharset;
	CViewC64Sprite *viewSprite;
	CViewVicEditorLayers *viewLayers;
	
	// layers
	std::list<CVicEditorLayer *> layers;
	CVicEditorLayerC64Screen *layerC64Screen;
	CVicEditorLayerC64Canvas *layerC64Canvas;
	CVicEditorLayerC64Sprites *layerC64Sprites;
	CVicEditorLayerVirtualSprites *layerVirtualSprites;
	CVicEditorLayerUnrestrictedBitmap *layerUnrestrictedBitmap;

	CVicEditorLayer *selectedLayer;
	void SelectLayer(CVicEditorLayer *layer);
	
	bool IsColorReplace();
	
	//
	void InitAddresses();
	
	void UpdateDisplayFrame();
	
	void MoveDisplayDiff(float diffX, float diffY);
	void MoveDisplayToScreenPos(float px, float py);
	void MoveDisplayToPreviewScreenPos(float x, float y);
	void ZoomDisplay(float newScale);
	
	bool isKeyboardMovingDisplay;
	
	bool isPainting;
	
	float prevMousePosX;
	float prevMousePosY;
	
	int prevRx;
	int prevRy;
	
	bool isMovingPreviewFrame;
	bool isPaintingOnPreviewFrame;
	
	void ShowPaintMessage(u8 result);
	
	u8 PaintBrushLine(CImageData *brush, int rx0, int ry0, int rx1, int ry1, u8 colorSource);
	void PaintBrushLineWithMessage(CImageData *brush, int rx1, int ry1, int rx2, int ry2, u8 colorSource);
	u8 PaintBrush(CImageData *brush, int rx, int ry, u8 colorSource);
	void PaintBrushWithMessage(CImageData *brush, int rx, int ry, u8 colorSource);
	u8 PaintPixel(int rx, int ry, u8 colorSource);
	
	bool GetColorAtRasterPos(int rx, int ry, u8 *color);
	
	bool inPresentationScreen;
	bool prevVisiblePreview;
	bool prevVisiblePalette;
	bool prevVisibleCharset;
	bool prevVisibleSprite;
	bool prevVisibleLayers;
	
	///
	
	void SetShowDisplayBorderType(u8 newBorderType);
	
	//
	void UpdateSmallDisplayScale();
	void ResetSmallDisplayScale(double newRealScale);
	int resetDisplayScaleIndex;
	
	CImageData *currentBrush;
	
	int brushSize;
	CImageData *CreateBrushCircle(int newSize);
	CImageData *CreateBrushRectangle(int newSize);
	
	//
	void EnsureCorrectScreenAndBitmapAddr();
	
	// undo
	void DebugPrintUndo(char *header);
	std::list<CByteBuffer *> poolList;
	std::list<CByteBuffer *> undoList;
	std::list<CByteBuffer *> redoList;
	void StoreUndo();
	void DoUndo();
	void DoRedo();
	void Serialise(CByteBuffer *byteBuffer, bool storeVicRegisters, bool storeC64Memory, bool storeVicDisplayControlState);
	void Deserialise(CByteBuffer *byteBuffer, int version);
	
	// import / export
	std::list<CSlrString *> importFileExtensions;
	std::list<CSlrString *> exportHiresBitmapFileExtensions;
	std::list<CSlrString *> exportMultiBitmapFileExtensions;
	std::list<CSlrString *> exportHiresTextFileExtensions;
	std::list<CSlrString *> exportHyperBitmapFileExtensions;
	std::list<CSlrString *> exportVCEFileExtensions;
	std::list<CSlrString *> exportPNGFileExtensions;
	
	u8 exportMode;
	
	void OpenDialogImportFile();

	virtual void SystemDialogFileOpenSelected(CSlrString *path);
	virtual void SystemDialogFileOpenCancelled();
	virtual void SystemDialogFileSaveSelected(CSlrString *path);
	virtual void SystemDialogFileSaveCancelled();

	void SetVicMode(bool isBitmapMode, bool isMultiColor, bool isExtendedBackground);
	void SetVicAddresses(int vbank, int screenAddr, int charsetAddr, int bitmapAddr);

	bool ImportVCE(CSlrString *path);
	bool ImportPNG(CSlrString *path);
	bool ImportKoala(CSlrString *path);
	bool ImportDoodle(CSlrString *path);
	bool ImportArtStudio(CSlrString *path);
	
	void OpenDialogExportFile();
	void OpenDialogSaveVCE();
	u8 exportFileDialogMode;
	
	bool ExportVCE(CSlrString *path);
	bool ExportKoala(CSlrString *path);
	bool ExportArtStudio(CSlrString *path);
	bool ExportRawText(CSlrString *path);
	bool ExportHyper(CSlrString *path);

	bool ExportCharset(CSlrString *path);
	bool ExportSpritesData(CSlrString *path);
	
	void SaveScreenshotAsPNG();

	bool ExportPNG(CSlrString *path);
	
	// callback from palette on change color, TODO: change this to proper callback
	virtual void PaletteColorChanged(u8 colorSource, u8 newColorValue);
	
	// callback when OS window size is changed
	virtual void GlobalOSWindowChangedCallback();

	//
	std::vector<CGuiView *> traversalOfViews;
	bool CanSelectView(CGuiView *view);
	void MoveFocusToNextView();
	void MoveFocusToPrevView();

	void InitPaintGridColors();
	void InitPaintGridShowZoomLevel();

	bool backupRenderDataWithColors;
	
	///
	void RunDebug();
};


#endif //_VIEW_VICEDITOR_
