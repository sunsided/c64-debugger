#ifndef _CVIEWC64DATADUMP_H_
#define _CVIEWC64DATADUMP_H_

#include "SYS_Defs.h"
#include "CGuiView.h"
#include "CGuiEditHex.h"
#include <vector>
#include <list>

class CSlrFont;
class CSlrDataAdapter;
class CViewMemoryMap;
class CSlrMutex;
class CDebugInterface;
class CViewDisassemble;

class CViewDataDump : public CGuiView, CGuiEditHexCallback
{
public:
	CViewDataDump(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY,
				  CSlrDataAdapter *dataAdapter, CViewMemoryMap *viewMemoryMap, CViewDisassemble *viewDisassemble,
				  CDebugInterface *debugInterface);
	
	virtual bool KeyDown(u32 keyCode, bool isShift, bool isAlt, bool isControl);
	virtual bool KeyUp(u32 keyCode, bool isShift, bool isAlt, bool isControl);

	virtual bool DoScrollWheel(float deltaX, float deltaY);

	virtual bool DoTap(GLfloat x, GLfloat y);

	CDebugInterface *debugInterface;
	
	CSlrFont *fontBytes;
	CSlrFont *fontCharacters;
	
	float fontSize;
	
	float fontBytesSize;
	float fontCharactersSize;
	float fontCharactersWidth;
	float markerSizeX, markerSizeY;
	
	int numberOfBytesPerLine;
	
	CSlrDataAdapter *dataAdapter;
	CViewMemoryMap *viewMemoryMap;
	CViewDisassemble *viewDisassemble;

	void SetDataAdapter(CSlrDataAdapter *newDataAdapter);
	
	int dataShowStart;
	int dataShowEnd;
	int dataShowSize;
	
//	bool isVisibleEditCursor;
	int editCursorPositionX;
	int editCursorPositionY;
	int dataAddr;
	int numberOfLines;
	
	void ScrollDataUp();
	void ScrollDataPageUp();
	void ScrollDataDown();
	void ScrollDataPageDown();
	
	bool FindDataPosition(float x, float y, int *dataPositionX, int *dataPositionY, int *dataPositionAddr);
	int GetAddrFromDataPosition(int dataPositionX, int dataPositionY);
	
	virtual void SetPosition(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);

	virtual void Render();
	float gapAddress;
	float gapHexData;
	float gapDataCharacters;

	virtual void DoLogic();

	std::list<CImageData *> charactersImageData;
	std::list<CSlrImage *> charactersImages;
	
	std::list<CImageData *> spritesImageData;
	std::list<CSlrImage *> spritesImages;

	
	CSlrFont *fontAtari;
	CSlrFont *fontCBM1;
	CSlrFont *fontCBM2;
	
	CSlrFont *fonts[3];

	
	bool isEditingValue;
	CGuiEditHex *editHex;
	virtual void GuiEditHexEnteredValue(CGuiEditHex *editHex, u32 lastKeyCode, bool isCancelled);

	bool isEditingValueAddr;

	CSlrString *strTemp;
	
	volatile bool renderDataWithColors;
	
	int numberOfCharactersToShow;
	void UpdateCharacters(bool useColors, byte colorD021, byte colorD022, byte colorD023, byte colorD800);
	
	int numberOfSpritesToShow;
	void UpdateSprites(bool useColors, byte colorD021, byte colorD025, byte colorD026, byte colorD027);
	
	void ScrollToAddress(int address);
	
	long previousClickTime;
	int previousClickAddr;
	
	void PasteHexValuesFromClipboard();
	void CopyHexValuesToClipboard();
	void CopyHexAddressToClipboard();
	
	bool showCharacters;
	bool showSprites;
};


#endif

