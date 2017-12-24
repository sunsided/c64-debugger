#ifndef _CC64TOOLS_H_
#define _CC64TOOLS_H_

#include "SYS_Defs.h"

#define CBMSHIFTEDFONT_INVERT	0x80

class CSlrFontProportional;
class CSlrString;
class CImageData;
class C64DebugInterface;

CSlrFontProportional *ProcessCBMFonts(uint8 *charsetData, bool useScreenCodes);
void InvertCBMText(CSlrString *text);
void ClearInvertCBMText(CSlrString *text);

void InvertCBMText(char *text);
void ClearInvertCBMText(char *text);

void ConvertCharacterDataToImage(u8 *characterData, CImageData *imageData);
void ConvertColorCharacterDataToImage(u8 *characterData, CImageData *imageData, u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800, C64DebugInterface *debugInterface);

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, int gap);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD027, C64DebugInterface *debugInterface, int gap);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 bkgColorR, u8 bkgColorG, u8 bkgColorB, u8 spriteColorR, u8 spriteColorG, u8 spriteColorB, int gap);

void ConvertColorSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD025, u8 colorD026, u8 colorD027, C64DebugInterface *debugInterface, int gap);

void GetCBMColor(u8 colorNum, float *r, float *g, float *b);

u8 ConvertPetsciiToSreenCode(u8 chr);

void CopyHiresCharsetToImage(u8 *charsetData, CImageData *imageData, int numColumns,
							 u8 colorBackground, u8 colorForeground, C64DebugInterface *debugInterface);

void CopyMultiCharsetToImage(u8 *charsetData, CImageData *imageData, int numColumns,
							 u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800, C64DebugInterface *debugInterface);

// returns color number from palette that is nearest to rgb
u8 FindC64Color(u8 r, u8 g, u8 b, C64DebugInterface *debugInterface);
float GetC64ColorDistance(u8 color1, u8 color2, C64DebugInterface *debugInterface);

//
void RenderColorRectangle(float px, float py, float ledSizeX, float ledSizeY, float gap, bool isLocked, u8 color, C64DebugInterface *debugInterface);

//
uint16 GetSidAddressByChipNum(int chipNum);

#endif
