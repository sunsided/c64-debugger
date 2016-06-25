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

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD027, C64DebugInterface *debugInterface);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 bkgColorR, u8 bkgColorG, u8 bkgColorB, u8 spriteColorR, u8 spriteColorG, u8 spriteColorB);

void ConvertColorSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD025, u8 colorD026, u8 colorD027, C64DebugInterface *debugInterface);

void GetCBMColor(u8 colorNum, float *r, float *g, float *b);

#endif
