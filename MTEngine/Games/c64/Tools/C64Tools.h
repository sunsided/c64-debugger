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

void ConvertCharacterDataToImage(byte *characterData, CImageData *imageData);
void ConvertColorCharacterDataToImage(byte *characterData, CImageData *imageData, byte colorD021, byte colorD022, byte colorD023, byte colorD800, C64DebugInterface *debugInterface);

void ConvertSpriteDataToImage(byte *spriteData, CImageData *imageData);
void ConvertColorSpriteDataToImage(byte *spriteData, CImageData *imageData, byte colorD021, byte colorD025, byte colorD026, byte colorD027, C64DebugInterface *debugInterface);

void GetCBMColor(byte colorNum, float *r, float *g, float *b);

#endif
