#ifndef _CDEBUGGERAPI_H_
#define _CDEBUGGERAPI_H_

#include "SYS_Defs.h"
#include "DebuggerDefs.h"
#include "SYS_KeyCodes.h"
#include "CDebugInterface.h"
#include "SYS_Threading.h"
#include "CImageData.h"

class CDebuggerAPI
{
public:
	CDebuggerAPI();
	
	void SwitchToVicEditor();
	void CreateNewPicture(u8 mode, u8 backgroundColor);
	void StartThread(CSlrThread *run);

	// rgb reference image in vic editor
	void ClearReferenceImage();
	void LoadReferenceImage(char *filePath);
	void LoadReferenceImage(CImageData *imageData);
	void SetReferenceImageLayerVisible(bool isVisible);
	CImageData *GetReferenceImage();

	void SetTopBarVisible(bool isVisible);
	void SetViewPaletteVisible(bool isVisible);
	void SetViewCharsetVisible(bool isVisible);
	void SetViewSpriteVisible(bool isVisible);
	void SetViewLayersVisible(bool isVisible);
	
	// emulated computer screen
	void ClearScreen();
	void ConvertImageToScreen(char *filePath);
	void ConvertImageToScreen(CImageData *imageData);

	//
	u8 FindC64Color(u8 r, u8 g, u8 b);
	u8 PaintPixel(int x, int y, u8 color);
	u8 PaintReferenceImagePixel(int x, int y, u8 color);
	u8 PaintReferenceImagePixel(int x, int y, u8 r, u8 g, u8 b, u8 a);
	
	//
	void SetByteToRam(int addr, u8 v);
	void SetByteToRamC64(int addr, u8 v);
	u8 GetByteFromRamC64(int addr);
	void MakeJMP(int addr);

	//
	void DetachEverything();
	
	//
	int Assemble(int addr, char *buf);
	
	//
	void BasicUpStart(u16 jmpAddr);
	bool LoadSID(char *filePath, u16 *fromAddr, u16 *toAddr, u16 *initAddr, u16 *playAddr);
	void ExomizerSave(u16 fromAddr, u16 toAddr, u16 jmpAddr, char *fileName);

	//
	void Sleep(long milliseconds);
};

#endif
