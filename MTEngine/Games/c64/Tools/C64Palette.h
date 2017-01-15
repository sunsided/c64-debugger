#ifndef _C64PALETTE_H_
#define _C64PALETTE_H_

#include "SYS_Defs.h"
#include <vector>

class C64PaletteData
{
public:
	C64PaletteData(char *paletteName, uint8 *palette);
	char *paletteName;
	uint8 *palette;
};

void C64InitPalette();
void C64SetPalette(uint8 *palette);
void C64SetPalette(char *paletteName);

std::vector<C64PaletteData *> *C64GetAvailablePalettes();

#endif


