#include "C64Palette.h"

std::vector<C64PaletteData *> c64AvailablePalettes;

void C64SetPalette(char *paletteName)
{
	for (std::vector<C64PaletteData *>::iterator it = c64AvailablePalettes.begin(); it != c64AvailablePalettes.end(); it++)
	{
		C64PaletteData *paletteData = *it;
		if (!strcmp(paletteName, paletteData->paletteName))
		{
			C64SetPalette(paletteData->palette);
		}
	}
}

void C64SetPalette(uint8 *palette)
{
	LOGD("C64SetPalette");
}


uint8 frodo2_palette[48] = {
	0x00, 0x00, 0x00,
	0xFF, 0xFF, 0xFF,
	0x99, 0x00, 0x00,
	0x00, 0xFF, 0xCC,
	0xCC, 0x00, 0xCC,
	0x44, 0xCC, 0x44,
	0x11, 0x00, 0x99,
	0xFF, 0xFF, 0x00,
	0xAA, 0x55, 0x00,
	0x66, 0x33, 0x00,
	0xFF, 0x66, 0x66,
	0x40, 0x40, 0x40,
	0x80, 0x80, 0x80,
	0x66, 0xFF, 0x66,
	0x77, 0x77, 0xFF,
	0xC0, 0xC0, 0xC0
};

void C64InitPalette()
{
	c64AvailablePalettes.push_back(new C64PaletteData("frodo2", frodo2_palette));
}

C64PaletteData::C64PaletteData(char *paletteName, uint8 *palette)
{
	this->paletteName = paletteName;
	this->palette = palette;
}



