#ifndef _CC64TOOLS_H_
#define _CC64TOOLS_H_

#include "SYS_Defs.h"

#define CBMSHIFTEDFONT_INVERT	0x80

class CSlrFontProportional;
class CSlrString;
class CImageData;
class CDebugInterface;
class C64DebugInterface;
class CSlrDataAdapter;

CSlrFontProportional *ProcessFonts(uint8 *charsetData, bool useScreenCodes);
void InvertCBMText(CSlrString *text);
void ClearInvertCBMText(CSlrString *text);

void InvertCBMText(char *text);
void ClearInvertCBMText(char *text);

void ConvertCharacterDataToImage(u8 *characterData, CImageData *imageData);
void ConvertColorCharacterDataToImage(u8 *characterData, CImageData *imageData, u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800, C64DebugInterface *debugInterface);

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, int gap);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD027,
							  C64DebugInterface *debugInterface, int gap);
void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 bkgColorR, u8 bkgColorG, u8 bkgColorB, u8 spriteColorR, u8 spriteColorG, u8 spriteColorB, int gap);

void ConvertColorSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD025, u8 colorD026, u8 colorD027, C64DebugInterface *debugInterface, int gap, u8 alpha);

void GetCBMColor(u8 colorNum, float *r, float *g, float *b);

u8 ConvertPetsciiToScreenCode(u8 chr);

void CopyHiresCharsetToImage(u8 *charsetData, CImageData *imageData, int numColumns,
							 u8 colorBackground, u8 colorForeground, C64DebugInterface *debugInterface);

void CopyMultiCharsetToImage(u8 *charsetData, CImageData *imageData, int numColumns,
							 u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800,
							 C64DebugInterface *debugInterface);

// returns color number from palette that is nearest to rgb
u8 FindC64Color(u8 r, u8 g, u8 b, C64DebugInterface *debugInterface);
float GetC64ColorDistance(u8 color1, u8 color2, C64DebugInterface *debugInterface);

//
void RenderColorRectangle(float px, float py, float ledSizeX, float ledSizeY, float gap, bool isLocked, u8 color,
						  C64DebugInterface *debugInterface);
void RenderColorRectangleWithHexCode(float px, float py, float ledSizeX, float ledSizeY, float gap, bool isLocked, u8 color, float fontSize,
						  C64DebugInterface *debugInterface);

//
uint16 GetSidAddressByChipNum(int chipNum);

// convert SID file to PRG, returns buffer with PRG
CByteBuffer *ConvertSIDtoPRG(CByteBuffer *sidFileData);
bool C64LoadSIDToRam(char *filePath, u16 *fromAddr, u16 *toAddr, u16 *initAddr, u16 *playAddr);

//
bool C64SaveMemory(int fromAddr, int toAddr, bool isPRG, CSlrDataAdapter *dataAdapter, char *filePath);
int C64LoadMemory(int fromAddr, CSlrDataAdapter *dataAdapter, char *filePath);
bool C64SaveMemoryExomizerPRG(int fromAddr, int toAddr, int jmpAddr, char *filePath);
u8 *C64ExomizeMemoryRaw(int fromAddr, int toAddr, int *compressedSize);

#endif
