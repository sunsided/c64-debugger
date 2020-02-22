#ifndef _C64DEBUGGERPLUGINSPIRAL_H_
#define _C64DEBUGGERPLUGINSPIRAL_H_

#include "CDebuggerEmulatorPlugin.h"
#include "CDebuggerAPI.h"
#include <list>

class CImageData;

class CCharLineData
{
public:
	CCharLineData();
	int charX;
	int charY;
	int charWithinY;
	
	int index[4];
	
	std::list<u16> bitmapAddrs;
};

class CSpritePixelMapData
{
public:
	CSpritePixelMapData(int spriteId, int spriteX, int spriteY, int screenX, int screenY);
	int spriteId;
	int spriteX;
	int spriteY;
	int screenX;
	int screenY;
};

class C64DebuggerPluginSpiral : public CDebuggerEmulatorPlugin, CSlrThread
{
public:
	C64DebuggerPluginSpiral();
	
	virtual void Init();
	virtual void ThreadRun(void *data);

	virtual void DoFrame();
	virtual u32 KeyDown(u32 keyCode);
	virtual u32 KeyUp(u32 keyCode);

	CImageData *imageDataRef;
	CImageData *imgIndex;
	CImageData *imgIndexSprites;
	CImageData *imgIndexMask;
	CImageData *imgTextureToParse;
	CImageData *imgTexture1;
	CImageData *imgTexture2;
	CImageData *imgTexture3;
	
	u8 textureColors[4];
	u8 spiral1Colors[4];
	u8 spiral2Colors[4];
	
	double xSkew;
	double ySkew;
	double aStart;
	double bStart;
	double aStep;
	double bStep;
	double angleStep;
	
	int tRepsX;
	int tRepsY;
	
	int mapTextureHeight;
	int mapTextureHeightF;
	
	//
	int txWidth;
	int txHeight;
	
	int nibbleTxSize;
	
	int txOffset;
	
	
	void GenerateTexture();
	void GeneratePackedTexture(int textureNum, CImageData *imgTexture);
	void CreateSpiralIndexImage();

	void GenerateSpeedcode();

	u16 bitmapColorSetCodeAddr;
	void GenerateCodeForSetBitmapColors();

	u16 spritesColorSetCodeAddr;
	void GenerateCodeForSetSpritesColors();

	u16 setTextureCodeAddr;
	void GenerateCodeForSetTexture();

	u16 setShowImageTriggerValAddr;
	int showImageTriggerValAddr;
	
	u16 setFadeOutTextureValAddr;
	u16 fadeOutProcJsrAddr1;
	u16 fadeOutProcJsrAddr2;
	
	u16 endOfInitCodeAddr;
	u16 copyOfZeroPageCodeAddr;

	u16 effectPlayerCodeAddr;
	u16 effectPlayerJMPToSpeedcodeAddr1;
//	u16 effectPlayerJMPToSpeedcodeAddr2;
	u16 effectPlayerDelayCounterAddr;
	u16 effectLoadSpritesProcJmpAddr;
	u16 effectFadeOutJmpAddr;
	u16 effectLoadNextPartProcJmpAddr;
	void GenerateCodeForEffectPlayer();
	
	void EffectDataPutSetTexture(u16 textureAddr);
	void EffectDataPutSetBitmapPalette(u8 color1, u8 color2, u8 color3);
	void EffectDataPutSetSpritesPalette(u8 color1, u8 color2, u8 color3);
	void EffectDataPutSetBitmapSpeed(u8 speed);
	void EffectDataPutSetSpritesSpeed(u8 speed);
	void EffectDataPutSetBitmapIndex(u8 index);
	void EffectDataPutSetSpritesIndex(u8 index);
	void EffectDataPutJumpTo(u8 jumpIndex);
	void EffectDataPutTriggerShowImage();
	void EffectDataPutTriggerEndEffect();
	void EffectDataPutLoadNextDemoPart();
	void EffectDataPutWait(u16 waitNum);
	
	u16 effectPlayerSpritesSpeedSetAddr;
	u16 effectPlayerBitmapSpeedSetAddr;
	u16 effectPlayerSpritesIndexSetAddr;
	u16 effectPlayerBitmapIndexSetAddr;
	
	u16 showImageColorCharsetValAddr;
	u16 showImageColorRamValAddr;
	
	u16 showImageBneAddr;
	
	u16 effectPlayerParseAddr;
	
	void GenerateSpritesTable();
	void GenerateSpritesMultiplexer();
	
	void LoadBitmap(u16 addr);
	
	u8 GetPixelColorIndex(int x, int y);

	int color;
	void setColor(int color);
	void plot(int x, int y, int color);
	void plot(int x, int y);
	void refplot(int x, int y, int color);
	void refplot(int x, int y);
	
	u8 colr; u8 colg; u8 colb;
	void setColorRGB(u8 r, u8 g, u8 b);
	void rgbplot(int x, int y, u8 r, u8 g, u8 b);
	void rgbplot(int x, int y);
	
	int frameNum;
	
	//
	std::list<CCharLineData *> charLinesBitmap;
	std::list<CCharLineData *> charLinesSprites;
	void AddAddrBitmap(int *index, u16 bitmapAddr);
	void AddAddrSprites(int *index, u16 bitmapAddr);
	void DebugDumpLines();
	
	int numFound;
	int numNotFound;
	
	u16 sidFromAddr, sidToAddr, sidInitAddr, sidPlayAddr;

	// assemble
	u16 addrAssemble;
	void Assemble(char *buf);
	void PutDataByte(u8 v);
	
	//
	int spiralStartX;
	int spiralEndX;
	int spiralStartY;
	int spiralEndY;
	
	u16 spritesTableAddr;
	u16 spritesTableIndexAddr;
	
	u16 spritesLineStart;
	
	u16 spritesDataStart;
	u16 spritesPointerStart;

	u16 spritesDataSize;
	u16 spritesDataNumLines;
	
	// calibration
	int calibrationSpriteId;
	int calibrationSpriteX;
	int calibrationSpriteY;
	void SpritesCalibrationSetup();
	void ClearSpritesData();
	void SpritesCalibrationFrame();
	void SetSpritesForCalibration(int spritePointer, int px, int py, u8 colorIndex);
	
	void SpritesGenerateImageData();
	
	CSpritePixelMapData *screenSpriteMapping[320][200];
	void LoadScreenSpritesMap();
	
	void ClearRAM();
	
	void SetWord(u16 addr, u16 v);
	

};

#endif
