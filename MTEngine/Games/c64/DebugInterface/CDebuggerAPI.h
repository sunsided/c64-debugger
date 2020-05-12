#ifndef _CDEBUGGERAPI_H_
#define _CDEBUGGERAPI_H_

#include "SYS_Defs.h"
#include "DebuggerDefs.h"
#include "SYS_KeyCodes.h"
#include "CDebugInterface.h"
#include "SYS_Threading.h"
#include "CImageData.h"

enum {
	ASSEMBLE_TARGET_NONE,
	ASSEMBLE_TARGET_MAIN_CPU,
	ASSEMBLE_TARGET_DISK_DRIVE1
};

class CDebuggerAPI
{
public:
	CDebuggerAPI();
	
	void ResetMachine();
	
	void SwitchToVicEditor();
	void CreateNewPicture(u8 mode, u8 backgroundColor);
	void StartThread(CSlrThread *run);

	// rgb reference image in vic editor
	void ClearReferenceImage();
	void LoadReferenceImage(char *filePath);
	void LoadReferenceImage(CImageData *imageData);
	void SetReferenceImageLayerVisible(bool isVisible);
	CImageData *GetReferenceImage();

	// vic editor dialogs -> to be moved
	void SetTopBarVisible(bool isVisible);
	void SetViewPaletteVisible(bool isVisible);
	void SetViewCharsetVisible(bool isVisible);
	void SetViewSpriteVisible(bool isVisible);
	void SetViewLayersVisible(bool isVisible);
	void SetViewPreviewVisible(bool isVisible);
	void SetSpritesFramesVisible(bool isVisible);
	void ZoomDisplay(float newScale);
	
	// this shows in VicEditor only screen without any other views
	void SetupVicEditorForScreenOnly();
	
	// emulated computer screen
	void ClearScreen();
	
	// load from png file
	void ConvertImageToScreen(char *filePath);

	void ConvertImageToScreen(CImageData *imageData);
	
	CImageData *GetScreenImage(int *width, int *height);
	
	// always returns 320x200 for C64:
	CImageData *GetScreenImageWithoutBorders();

	//
	u8 FindC64Color(u8 r, u8 g, u8 b);
	u8 PaintPixel(int x, int y, u8 color);
	u8 PaintReferenceImagePixel(int x, int y, u8 color);
	u8 PaintReferenceImagePixel(int x, int y, u8 r, u8 g, u8 b, u8 a);
	
	//
	void GetCBMColor(u8 colorNum, u8 *r, u8 *g, u8 *b);
	
	//
	void SetByte(int addr, u8 v);	/// NOTE: this needs change
	void SetByteToRam(int addr, u8 v);
	void SetByteToRamC64(int addr, u8 v);
	u8 GetByteFromRamC64(int addr);
	void SetWord(int addr, u16 v);
	void MakeJMP(int addr);

	//
	void SetCiaRegister(u8 ciaId, u8 registerNum, u8 value);
	void SetVicRegister(u8 registerNum, u8 value);
	
	//
	void DetachEverything();
	void ClearRAM(int startAddr, int endAddr, u8 value);
	
	//
	u8 assembleTarget;
	void SetAssembleTarget(u8 target);
	int Assemble(int addr, char *assembleText);
	
	CByteBuffer *byteBufferAssembleText;
	void Assemble64Tass(char *assembleText, int *codeStartAddr, int *codeSize);
	void Assemble64Tass(int *codeStartAddr, int *codeSize);
	void Assemble64TassAddLine(char *assembleText);
	
	//
	void AddWatch(CSlrString *segmentName, int address, CSlrString *watchName, uint8 representation, int numberOfValues, uint8 bits);
	void AddWatch(int address, char *watchName, uint8 representation, int numberOfValues, uint8 bits);
	void AddWatch(int address, char *watchName);
	
	//
	void BasicUpStart(u16 jmpAddr);
	bool LoadPRG(char *filePath, u16 *fromAddr, u16 *toAddr);
	bool LoadSID(char *filePath, u16 *fromAddr, u16 *toAddr, u16 *initAddr, u16 *playAddr);
//	bool LoadAndRelocateSID(char *filePath, u16 fromAddr, u16 *toAddr, u16 *initAddr, u16 *playAddr);
	void SaveExomizerPRG(u16 fromAddr, u16 toAddr, u16 jmpAddr, char *fileName);
	void SavePRG(u16 fromAddr, u16 toAddr, char *fileName);
	void SaveBinary(u16 fromAddr, u16 toAddr, char *fileName);
	int LoadBinary(u16 fromAddr, char *filePath);

	u8 *ExomizerMemoryRaw(u16 fromAddr, u16 toAddr, int *compressedSize);
	
	//
	void SetScreenAndCharsetAddress(u16 screenAddr, u16 charsetAddr);
	
	//
	void ShowMessage(const char *text);
	void BlitText(const char *text, float posX, float posY, float fontSize);
	void Sleep(long milliseconds);
	long GetCurrentTimeInMilliseconds();
};

#endif
