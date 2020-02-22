#ifndef __CViewMemoryMap__
#define __CViewMemoryMap__

#include "CGuiView.h"
#include "DebuggerDefs.h"

class C64;
class CImageData;
class CSlrImage;
class CViewDataDump;
class CDebugInterface;
class CSlrFont;

#define MEMORY_MAP_VALUES_STYLE_RGB			0
#define MEMORY_MAP_VALUES_STYLE_GRAYSCALE	1
#define MEMORY_MAP_VALUES_STYLE_BLACK		2

void C64DebuggerComputeMemoryMapColorTables(uint8 memoryValuesStyle);

#define MEMORY_MAP_MARKER_STYLE_DEFAULT		0
#define MEMORY_MAP_MARKER_STYLE_ICU			1

void C64DebuggerSetMemoryMapMarkersStyle(uint8 memoryMapMarkersStyle);

class CViewMemoryMapCell
{
public:
	CViewMemoryMapCell(int addr);
	
	// cell address (for virtual maps, like Drive 1541 map)
	int addr;
	
	// read/write colors
	float sr, sg, sb, sa;
	
	// value color
	float vr, vg, vb, va;
	
	// render color (s+v)
	float rr, rg, rb, ra;

	//volatile
	bool isExecuteCode;
	//volatile
	bool isExecuteArgument;
	
	bool isRead;
	bool isWrite;
	
	void MarkCellRead();
	void MarkCellWrite(uint8 value);
	void MarkCellExecuteCode(uint8 opcode);
	void MarkCellExecuteArgument();
	
	void ClearExecuteMarkers();
	void ClearReadWriteMarkers();
	
	// last write PC & raster (where was PC & raster when cell was written)
	int writePC;
	int writeRasterLine, writeRasterCycle;
	
	// last read PC & raster (where was PC & raster when cell was read)
	int readPC;
	int readRasterLine, readRasterCycle;
};

void C64DebuggerSetMemoryMapCellsFadeSpeed(float fadeSpeed);

class CViewMemoryMap : public CGuiView
{
public:
	CViewMemoryMap(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
				   CDebugInterface *debugInterface, int imageWidth, int imageHeight, int ramSize, bool isFromDisk);
	~CViewMemoryMap();
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual void DoLogic();
	virtual void Render();
	
	virtual bool DoTap(GLfloat x, GLfloat y);

	virtual bool DoScrollWheel(float deltaX, float deltaY);
	virtual bool InitZoom();
	virtual bool DoZoomBy(GLfloat x, GLfloat y, GLfloat zoomValue, GLfloat difference);
	virtual bool DoMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoRightClick(GLfloat x, GLfloat y);
	virtual bool DoRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat diffX, GLfloat diffY);
	virtual bool FinishRightClickMove(GLfloat x, GLfloat y, GLfloat distX, GLfloat distY, GLfloat accelerationX, GLfloat accelerationY);

	virtual bool DoNotTouchedMove(GLfloat x, GLfloat y);

	CSlrFont *font;
	float fontScale;
	
	// local copy of memory
	uint8 *memoryBuffer;
	
	float currentZoom;
	
	volatile bool cursorInside;
	float cursorX, cursorY;
	
	void ClearZoom();
	void ZoomMap(float zoom);
	void MoveMap(float diffX, float diffY);
	
	CDebugInterface *debugInterface;
	
	CViewMemoryMapCell **memoryCells;
	int ramSize;
	int imageWidth;
	int imageHeight;

	void UpdateWholeMap();
	
	void CellRead(uint16 addr);
	void CellRead(uint16 addr, uint16 pc, int rasterX, int rasterY);
	void CellWrite(uint16 addr, uint8 value);
	void CellWrite(uint16 addr, uint8 value, uint16 pc, int rasterX, int rasterY);
	void CellExecute(uint16 addr, uint8 opcode);
	
	void CellsAnimationLogic();
	void DriveROMCellsAnimationLogic();
	
	CImageData *imageDataMemoryMap;
	CSlrImage *imageMemoryMap;
	
	bool isFromDisk;
	
	int frameCounter;
	int nextScreenUpdateFrame;
	
	bool isDataDirectlyFromRAM;
	
	CViewDataDump *viewDataDump;
	
	void SetViewC64DataDump(CViewDataDump *viewDataDump);
	
	bool IsExecuteCodeAddress(int address);
	void ClearExecuteMarkers();
	void ClearReadWriteMarkers();
	
	void UpdateTexturePosition(float newStartX, float newStartY, float newEndX, float newEndY);
	
	void HexDigitToBinary(uint8 hexDigit, char *buf);
	
	float textureStartX, textureStartY;
	float textureEndX, textureEndY;
	
	float renderTextureStartX, renderTextureStartY;
	float renderTextureEndX, renderTextureEndY;
	
	float mapPosX, mapPosY, mapSizeX, mapSizeY;
	float renderMapPosX, renderMapPosY, renderMapSizeX, renderMapSizeY;
	
	bool renderMapValues;
	float cellSizeX, cellSizeY;
	float cellStartX, cellStartY;
	float cellEndX, cellEndY;
	int cellStartIndex;
	int numCellsInWidth;
	int numCellsInHeight;
	float currentFontDataScale;
	float textDataGapX;
	float textDataGapY;
	float currentFontAddrScale;
	float textAddrGapX;
	float textAddrGapY;
	float currentFontCodeScale;
	float textCodeCenterX;
	float textCodeGapY;
	float textCodeWidth;
	float textCodeWidth3;
	float textCodeWidth3h;
	float textCodeWidth6h;
	float textCodeWidth7h;
	float textCodeWidth8h;
	float textCodeWidth9h;
	float textCodeWidth10h;
	
	bool isBeingMoved;
	void UpdateMapPosition();
	
	// for double click
	long previousClickTime;
	int previousClickAddr;
	
	// move acceleration
	float accelerateX, accelerateY;
	
	bool isForcedMovingMap;
	float prevMousePosX;
	float prevMousePosY;

};

extern float colorExecuteCodeR;
extern float colorExecuteCodeG;
extern float colorExecuteCodeB;
extern float colorExecuteCodeA;

extern float colorExecuteArgumentR;
extern float colorExecuteArgumentG;
extern float colorExecuteArgumentB;
extern float colorExecuteArgumentA;

extern float colorExecuteCodeR2;
extern float colorExecuteCodeG2;
extern float colorExecuteCodeB2;
extern float colorExecuteCodeA2;

extern float colorExecuteArgumentR2;
extern float colorExecuteArgumentG2;
extern float colorExecuteArgumentB2;
extern float colorExecuteArgumentA2;


#endif
