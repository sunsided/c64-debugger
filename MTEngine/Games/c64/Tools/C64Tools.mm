#include "SYS_Main.h"
#include "RES_ResourceManager.h"
#include "CSlrFontProportional.h"
#include "VID_ImageBinding.h"
#include "C64Tools.h"
#include "CSlrString.h"
#include "C64DebugInterface.h"

void AddCBMScreenCharacters(CSlrFontProportional *font);
void AddASCIICharacters(CSlrFontProportional *font);

void ConvertCharacterDataToImage(u8 *characterData, CImageData *imageData)
{
	u8 *chd = characterData;
	
	int gap = 4;

	int chx = 0 + gap;
	int chy = 0 + gap;

	imageData->EraseContent(0,0,0,255);
	
	// copy pixels around character for better linear scaling
	for (int y = -1; y < 9; y++)
	{
		if ((*chd & 0x01) == 0x01)
		{
			imageData->SetPixelResultRGBA(chx + 8, chy + y, 255, 255, 255, 255);
			imageData->SetPixelResultRGBA(chx + 7, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x02) == 0x02)
		{
			imageData->SetPixelResultRGBA(chx + 6, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x04) == 0x04)
		{
			imageData->SetPixelResultRGBA(chx + 5, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x08) == 0x08)
		{
			imageData->SetPixelResultRGBA(chx + 4, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x10) == 0x10)
		{
			imageData->SetPixelResultRGBA(chx + 3, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x20) == 0x20)
		{
			imageData->SetPixelResultRGBA(chx + 2, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x40) == 0x40)
		{
			imageData->SetPixelResultRGBA(chx + 1, chy + y, 255, 255, 255, 255);
		}
		if ((*chd & 0x80) == 0x80)
		{
			imageData->SetPixelResultRGBA(chx + 0, chy + y, 255, 255, 255, 255);
			imageData->SetPixelResultRGBA(chx - 1, chy + y, 255, 255, 255, 255);
		}
		
		if (y == -1 || y == 7)
			continue;
		
		chd++;
	}
}

void ConvertColorCharacterDataToImage(u8 *characterData, CImageData *imageData, u8 colorD021, u8 colorD022, u8 colorD023, u8 colorD800, C64DebugInterface*debugInterface)
{
	u8 cD021r, cD021g, cD021b;
	u8 cD022r, cD022g, cD022b;
	u8 cD023r, cD023g, cD023b;
	u8 cD800r, cD800g, cD800b;
	
	debugInterface->GetCBMColor(colorD021, &cD021r, &cD021g, &cD021b);
	debugInterface->GetCBMColor(colorD022, &cD022r, &cD022g, &cD022b);
	debugInterface->GetCBMColor(colorD023, &cD023r, &cD023g, &cD023b);
	debugInterface->GetCBMColor(colorD800, &cD800r, &cD800g, &cD800b);

	u8 *chd = characterData;
	
	int gap = 4;
	
	int chx = 0 + gap;
	int chy = 0 + gap;
	
	imageData->EraseContent(0,0,0,255);
	
	// copy pixels around character for better linear scaling
	for (int y = -1; y < 9; y++)
	{
		u8 v;
		
		// 00000011
		v = (*chd & 0x03);
		if (v == 0x01)
		{
			imageData->SetPixelResultRGBA(chx + 8, chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx + 7, chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx + 6, chy + y, cD022r, cD022g, cD022b, 255);
		}
		else if (v == 0x02)
		{
			imageData->SetPixelResultRGBA(chx + 8, chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx + 7, chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx + 6, chy + y, cD023r, cD023g, cD023b, 255);
		}
		else if (v == 0x03)
		{
			imageData->SetPixelResultRGBA(chx + 8, chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx + 7, chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx + 6, chy + y, cD800r, cD800g, cD800b, 255);
		}

		// 00001100
		v = (*chd & 0x0C);
		if (v == 0x04)
		{
			imageData->SetPixelResultRGBA(chx + 5, chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx + 4, chy + y, cD022r, cD022g, cD022b, 255);
		}
		else if (v == 0x08)
		{
			imageData->SetPixelResultRGBA(chx + 5, chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx + 4, chy + y, cD023r, cD023g, cD023b, 255);
		}
		else if (v == 0x0C)
		{
			imageData->SetPixelResultRGBA(chx + 5, chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx + 4, chy + y, cD800r, cD800g, cD800b, 255);
		}

		// 00110000
		v = (*chd & 0x30);
		if (v == 0x10)
		{
			imageData->SetPixelResultRGBA(chx + 3, chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx + 2, chy + y, cD022r, cD022g, cD022b, 255);
		}
		else if (v == 0x20)
		{
			imageData->SetPixelResultRGBA(chx + 3, chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx + 2, chy + y, cD023r, cD023g, cD023b, 255);
		}
		else if (v == 0x30)
		{
			imageData->SetPixelResultRGBA(chx + 3, chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx + 2, chy + y, cD800r, cD800g, cD800b, 255);
		}
		
		// 11000000
		v = (*chd & 0xC0);
		if (v == 0x40)
		{
			imageData->SetPixelResultRGBA(chx + 1, chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx    , chy + y, cD022r, cD022g, cD022b, 255);
			imageData->SetPixelResultRGBA(chx - 1, chy + y, cD022r, cD022g, cD022b, 255);
		}
		else if (v == 0x80)
		{
			imageData->SetPixelResultRGBA(chx + 1, chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx    , chy + y, cD023r, cD023g, cD023b, 255);
			imageData->SetPixelResultRGBA(chx - 1, chy + y, cD023r, cD023g, cD023b, 255);
		}
		else if (v == 0xC0)
		{
			imageData->SetPixelResultRGBA(chx + 1, chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx    , chy + y, cD800r, cD800g, cD800b, 255);
			imageData->SetPixelResultRGBA(chx - 1, chy + y, cD800r, cD800g, cD800b, 255);
		}
		
		if (y == -1 || y == 7)
			continue;
		
		chd++;
	}
}

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData)
{
	ConvertSpriteDataToImage(spriteData, imageData, 0, 0, 0, 255, 255, 255);
}

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD027, C64DebugInterface *debugInterface)
{
	u8 cD021r, cD021g, cD021b;
	u8 cD027r, cD027g, cD027b;
	
	debugInterface->GetCBMColor(colorD021, &cD021r, &cD021g, &cD021b);
	debugInterface->GetCBMColor(colorD027, &cD027r, &cD027g, &cD027b);

	ConvertSpriteDataToImage(spriteData, imageData, cD021r, cD021g, cD021b, cD027r, cD027g, cD027b);
}

void ConvertSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 bkgColorR, u8 bkgColorG, u8 bkgColorB, u8 spriteColorR, u8 spriteColorG, u8 spriteColorB)
{
	u8 *chd = spriteData;
	
	int gap = 4;
	
	int chy = 0 + gap;
	
	imageData->EraseContent(bkgColorR, bkgColorG, bkgColorB,255);
	
	// copy pixels around character for better linear scaling
	for (int y = 0; y < 21; y++)
	{
		int chx = 0 + gap;
		for (int x = 0; x < 3; x++)
		{
			if ((*chd & 0x01) == 0x01)
			{
				imageData->SetPixelResultRGBA(chx + 7, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x02) == 0x02)
			{
				imageData->SetPixelResultRGBA(chx + 6, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x04) == 0x04)
			{
				imageData->SetPixelResultRGBA(chx + 5, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x08) == 0x08)
			{
				imageData->SetPixelResultRGBA(chx + 4, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x10) == 0x10)
			{
				imageData->SetPixelResultRGBA(chx + 3, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x20) == 0x20)
			{
				imageData->SetPixelResultRGBA(chx + 2, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x40) == 0x40)
			{
				imageData->SetPixelResultRGBA(chx + 1, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}
			if ((*chd & 0x80) == 0x80)
			{
				imageData->SetPixelResultRGBA(chx + 0, chy + y, spriteColorR, spriteColorG, spriteColorB, 255);
			}

//			if (x == -1 || x == 4)
//				continue;
			
			chx += 8;
			chd++;
		}
		
//		if (y == -1 || y == 7)
//			continue;
		
	}

	// will be displayed flipped instead
//	imageData->FlipVertically();
}


void ConvertColorSpriteDataToImage(u8 *spriteData, CImageData *imageData, u8 colorD021, u8 colorD025, u8 colorD026, u8 colorD027, C64DebugInterface *debugInterface)
{
	u8 cD021r, cD021g, cD021b;
	u8 cD025r, cD025g, cD025b;
	u8 cD026r, cD026g, cD026b;
	u8 cD027r, cD027g, cD027b;
	
	debugInterface->GetCBMColor(colorD021, &cD021r, &cD021g, &cD021b);
	debugInterface->GetCBMColor(colorD025, &cD025r, &cD025g, &cD025b);
	debugInterface->GetCBMColor(colorD026, &cD026r, &cD026g, &cD026b);
	debugInterface->GetCBMColor(colorD027, &cD027r, &cD027g, &cD027b);
	
	
	u8 *chd = spriteData;
	
	int gap = 4;
	
	int chy = 0 + gap;
	
	imageData->EraseContent(cD021r, cD021g, cD021b, 255);
	
	// copy pixels around character for better linear scaling
	for (int y = 0; y < 21; y++)
	{
		int chx = 0 + gap;
		for (int x = 0; x < 3; x++)
		{
			u8 v;
			
			// 00000011
			v = (*chd & 0x03);
			if (v == 0x01)
			{
				//D025
				imageData->SetPixelResultRGBA(chx + 7, chy + y, cD025r, cD025g, cD025b, 255);
				imageData->SetPixelResultRGBA(chx + 6, chy + y, cD025r, cD025g, cD025b, 255);
			}
			else if (v == 0x03)
			{
				//D026
				imageData->SetPixelResultRGBA(chx + 7, chy + y, cD026r, cD026g, cD026b, 255);
				imageData->SetPixelResultRGBA(chx + 6, chy + y, cD026r, cD026g, cD026b, 255);
			}
			else if (v == 0x02)
			{
				//D027
				imageData->SetPixelResultRGBA(chx + 7, chy + y, cD027r, cD027g, cD027b, 255);
				imageData->SetPixelResultRGBA(chx + 6, chy + y, cD027r, cD027g, cD027b, 255);
			}

			// 00001100
			v = (*chd & 0x0C);
			if (v == 0x04)
			{
				//D025
				imageData->SetPixelResultRGBA(chx + 5, chy + y, cD025r, cD025g, cD025b, 255);
				imageData->SetPixelResultRGBA(chx + 4, chy + y, cD025r, cD025g, cD025b, 255);
			}
			else if (v == 0x0C)
			{
				//D026
				imageData->SetPixelResultRGBA(chx + 5, chy + y, cD026r, cD026g, cD026b, 255);
				imageData->SetPixelResultRGBA(chx + 4, chy + y, cD026r, cD026g, cD026b, 255);
			}
			else if (v == 0x08)
			{
				//D027
				imageData->SetPixelResultRGBA(chx + 5, chy + y, cD027r, cD027g, cD027b, 255);
				imageData->SetPixelResultRGBA(chx + 4, chy + y, cD027r, cD027g, cD027b, 255);
			}

			// 00110000
			v = (*chd & 0x30);
			if (v == 0x10)
			{
				//D025
				imageData->SetPixelResultRGBA(chx + 3, chy + y, cD025r, cD025g, cD025b, 255);
				imageData->SetPixelResultRGBA(chx + 2, chy + y, cD025r, cD025g, cD025b, 255);
			}
			else if (v == 0x30)
			{
				//D026
				imageData->SetPixelResultRGBA(chx + 3, chy + y, cD026r, cD026g, cD026b, 255);
				imageData->SetPixelResultRGBA(chx + 2, chy + y, cD026r, cD026g, cD026b, 255);
			}
			else if (v == 0x20)
			{
				//D027
				imageData->SetPixelResultRGBA(chx + 3, chy + y, cD027r, cD027g, cD027b, 255);
				imageData->SetPixelResultRGBA(chx + 2, chy + y, cD027r, cD027g, cD027b, 255);
			}
			
			// 11000000
			v = (*chd & 0xC0);
			if (v == 0x40)
			{
				//D025
				imageData->SetPixelResultRGBA(chx + 1, chy + y, cD025r, cD025g, cD025b, 255);
				imageData->SetPixelResultRGBA(chx    , chy + y, cD025r, cD025g, cD025b, 255);
			}
			else if (v == 0xC0)
			{
				//D026
				imageData->SetPixelResultRGBA(chx + 1, chy + y, cD026r, cD026g, cD026b, 255);
				imageData->SetPixelResultRGBA(chx    , chy + y, cD026r, cD026g, cD026b, 255);
			}
			else if (v == 0x80)
			{
				//D027
				imageData->SetPixelResultRGBA(chx + 1, chy + y, cD027r, cD027g, cD027b, 255);
				imageData->SetPixelResultRGBA(chx    , chy + y, cD027r, cD027g, cD027b, 255);
			}
			

			
			//			if (x == -1 || x == 4)
			//				continue;
			
			chx += 8;
			chd++;
		}
		
		//		if (y == -1 || y == 7)
		//			continue;
		
	}
	
	// will be displayed flipped instead
//	imageData->FlipVertically();
}



CSlrFontProportional *ProcessCBMFonts(u8 *charsetData, bool useScreenCodes)
{
	LOGD("--- process fonts ---");
	
	CSlrFontProportional *font = new CSlrFontProportional();
	
	int gap = 4;
	
	CImageData *imageData = new CImageData(256, 256, IMG_TYPE_RGBA);
	imageData->AllocImage(false, true);
	
	int chx = 0 + gap;
	int chy = 0 + gap;
	
	int c = 0;
	for (int charId = 0; charId < 256; charId++)
	{
		u8 *chd = charsetData + 8*charId;
		
		// copy pixels around character for better linear scaling 
		for (int y = -1; y < 9; y++)
		{
			if ((*chd & 0x01) == 0x01)
			{
				imageData->SetPixelResultRGBA(chx + 8, chy + y, 255, 255, 255, 255);
				imageData->SetPixelResultRGBA(chx + 7, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x02) == 0x02)
			{
				imageData->SetPixelResultRGBA(chx + 6, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x04) == 0x04)
			{
				imageData->SetPixelResultRGBA(chx + 5, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x08) == 0x08)
			{
				imageData->SetPixelResultRGBA(chx + 4, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x10) == 0x10)
			{
				imageData->SetPixelResultRGBA(chx + 3, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x20) == 0x20)
			{
				imageData->SetPixelResultRGBA(chx + 2, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x40) == 0x40)
			{
				imageData->SetPixelResultRGBA(chx + 1, chy + y, 255, 255, 255, 255);
			}
			if ((*chd & 0x80) == 0x80)
			{
				imageData->SetPixelResultRGBA(chx + 0, chy + y, 255, 255, 255, 255);
				imageData->SetPixelResultRGBA(chx - 1, chy + y, 255, 255, 255, 255);
			}
			
			if (y == -1 || y == 7)
				continue;
			
			chd++;
		}
		
		chx += 8 + gap;
		c++;
		if (c == 16)
		{
			c = 0;
			chx = 0 + gap;
			chy += 8 + gap;
		}
	}
	
	// don't ask me why - there's a bug in win32 engine part waiting to be fixed
#if !defined(WIN32) && !defined(LINUX)
	imageData->FlipVertically();
#endif
	
	font->texturePageImageData = imageData;
	
	font->texturePage = new CSlrImage(true, false);
	font->texturePage->LoadImage(imageData, RESOURCE_PRIORITY_STATIC, false);
	font->texturePage->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
	font->texturePage->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(font->texturePage, NULL);

	//font->texturePage = RES_GetImage("/c64/c64chars-set1", false, true);
	
	font->lineHeight = 8;
	font->fontHeight = 8;
	font->base = 0;
	font->width = font->texturePage->width;
	font->height = font->texturePage->height;
	font->pages = 1;
	font->outline = 0;
	
	// no kerning
	
	// get chars
	if (useScreenCodes)
	{
		AddCBMScreenCharacters(font);
	}
	else
	{
		AddASCIICharacters(font);
	}
	
	font->texDividerX = 1.0f;
	font->texDividerY = 1.0f;
	font->texAdvX = (float) font->texDividerX/font->width;
	font->texAdvY = (float) font->texDividerY/font->height;
	
//	Cu8Buffer *u8Buffer = new Cu8Buffer();
//	font->StoreFontDataTou8Buffer(u8Buffer);
//	u8Buffer->storeToDocuments("c64chars-set1.fnt");
	
	return font;
}

void AddCBMScreenCharacters(CSlrFontProportional *font)
{
	int gap = 4;
	int gap2 = gap/2;
	

	int val = 0;
	for (int fy = 0; fy < 16; fy++)
	{
		for (int fx = 0; fx < 16; fx++)
		{
			CharDescriptor *charDescriptor = new CharDescriptor();
			charDescriptor->x = gap2 + fx * (4+gap2);
			charDescriptor->y = gap2 + fy * (4+gap2);
			charDescriptor->width = 4;
			charDescriptor->height = 4;
			charDescriptor->xOffset = 0;
			charDescriptor->yOffset = 0;
			charDescriptor->xAdvance = 4;
			charDescriptor->page = 1;
			
			//LOGD("adding charVal=%d", val);
			font->chars[val] = charDescriptor;
			
			val++;
		}
	}
}

void AddASCIICharacter(CSlrFontProportional *font, int fx, int fy, u16 chr)
{
	const int gap = 4;
	const int gap2 = gap/2;

	// normal
	CharDescriptor *charDescriptor = new CharDescriptor();
	charDescriptor->x = gap2 + fx * (4+gap2);
	charDescriptor->y = gap2 + fy * (4+gap2);
	charDescriptor->width = 4;
	charDescriptor->height = 4;
	charDescriptor->xOffset = 0;
	charDescriptor->yOffset = 0;
	charDescriptor->xAdvance = 4;
	charDescriptor->page = 1;

	font->chars[chr] = charDescriptor;

	// inverted char+0x0080 CBMSHIFTEDFONT_INVERT
	charDescriptor = new CharDescriptor();
	charDescriptor->x = gap2 + fx * (4+gap2);
	charDescriptor->y = gap2 + (fy+8) * (4+gap2);
	charDescriptor->width = 4;
	charDescriptor->height = 4;
	charDescriptor->xOffset = 0;
	charDescriptor->yOffset = 0;
	charDescriptor->xAdvance = 4;
	charDescriptor->page = 1;

	font->chars[chr + CBMSHIFTEDFONT_INVERT] = charDescriptor;
}

void AddASCIICharacters(CSlrFontProportional *font)
{
	
	int val = 0;
	for (int fy = 0; fy < 8; fy++)
	{
		for (int fx = 0; fx < 16; fx++)
		{
			//LOGD("adding charVal=%2.2x", val);
			if (val == 0x00)
			{
				AddASCIICharacter(font, fx, fy, '@');
			}
			else if (val >= 0x01 && val <= 0x1A)
			{
				AddASCIICharacter(font, fx, fy, val + 0x60);
			}
			else if (val >= 0x30 && val <= 0x39)
			{
				AddASCIICharacter(font, fx, fy, val);
			}
			else if (val >= 0x41 && val <= 0x5A)
			{
				AddASCIICharacter(font, fx, fy, val);
			}
			else if (val == 0x1B)
			{
				AddASCIICharacter(font, fx, fy, '[');
			}
			else if (val == 0x1C)
			{
				AddASCIICharacter(font, fx, fy, 0x1C);
			}
			else if (val == 0x1D)
			{
				AddASCIICharacter(font, fx, fy, ']');
			}
			else if (val == 0x1E)
			{
				AddASCIICharacter(font, fx, fy, '^');
			}
			else if (val == 0x1F)
			{
				AddASCIICharacter(font, fx, fy, '~');
			}
			else if (val == 0x20)
			{
				AddASCIICharacter(font, fx, fy, ' ');
			}
			else if (val == 0x21)
			{
				AddASCIICharacter(font, fx, fy, '!');
			}
			else if (val == 0x22)
			{
				AddASCIICharacter(font, fx, fy, '\"');
			}
			else if (val == 0x23)
			{
				AddASCIICharacter(font, fx, fy, '#');
			}
			else if (val == 0x24)
			{
				AddASCIICharacter(font, fx, fy, '$');
			}
			else if (val == 0x25)
			{
				AddASCIICharacter(font, fx, fy, '%');
			}
			else if (val == 0x26)
			{
				AddASCIICharacter(font, fx, fy, '&');
			}
			else if (val == 0x27)
			{
				AddASCIICharacter(font, fx, fy, '\'');
			}
			else if (val == 0x28)
			{
				AddASCIICharacter(font, fx, fy, '(');
			}
			else if (val == 0x29)
			{
				AddASCIICharacter(font, fx, fy, ')');
			}
			else if (val == 0x2A)
			{
				AddASCIICharacter(font, fx, fy, '*');
			}
			else if (val == 0x2B)
			{
				AddASCIICharacter(font, fx, fy, '+');
			}
			else if (val == 0x2C)
			{
				AddASCIICharacter(font, fx, fy, ',');
			}
			else if (val == 0x2D)
			{
				AddASCIICharacter(font, fx, fy, '-');
			}
			else if (val == 0x2E)
			{
				AddASCIICharacter(font, fx, fy, '.');
			}
			else if (val == 0x2F)
			{
				AddASCIICharacter(font, fx, fy, '/');
			}
			else if (val == 0x3A)
			{
				AddASCIICharacter(font, fx, fy, ':');
			}
			else if (val == 0x3B)
			{
				AddASCIICharacter(font, fx, fy, ';');
			}
			else if (val == 0x3C)
			{
				AddASCIICharacter(font, fx, fy, '<');
			}
			else if (val == 0x3B)
			{
				AddASCIICharacter(font, fx, fy, ';');
			}
			else if (val == 0x3C)
			{
				AddASCIICharacter(font, fx, fy, '<');
			}
			else if (val == 0x3D)
			{
				AddASCIICharacter(font, fx, fy, '=');
			}
			else if (val == 0x3E)
			{
				AddASCIICharacter(font, fx, fy, '>');
			}
			else if (val == 0x3F)
			{
				AddASCIICharacter(font, fx, fy, '?');
			}
			else if (val == 0x64)
			{
				AddASCIICharacter(font, fx, fy, '_');
			}
			
			val++;
		}
	}
}

void InvertCBMText(CSlrString *text)
{
	for (int i = 0; i < text->GetLength(); i++)
	{
		u16 c = text->GetChar(i);
		c += CBMSHIFTEDFONT_INVERT;
		text->SetChar(i, c);
	}
}

void ClearInvertCBMText(CSlrString *text)
{
	for (int i = 0; i < text->GetLength(); i++)
	{
		u16 c = text->GetChar(i);
		c = c & 0x7F;
		text->SetChar(i, c);
	}
	
}

void InvertCBMText(char *text)
{
	int len = strlen(text);
	for (int i = 0; i < len; i++)
	{
		u8 c = text[i];
		c += CBMSHIFTEDFONT_INVERT;
		text[i] = c;
	}
}

void ClearInvertCBMText(char *text)
{
	int len = strlen(text);
	for (int i = 0; i < len; i++)
	{
		u8 c = text[i];
		c = c & 0x7F;
		text[i] = c;
	}
}

void GetCBMColor(u8 colorNum, float *r, float *g, float *b)
{
	switch (colorNum)
	{
		case 0:
			*r = 0.000f; *g = 0.000f; *b = 0.000f;
			break;
		case 1:
			*r = 1.000f; *g = 1.000f; *b = 1.000f;
			break;
		case 2:
			*r = 0.533f; *g = 0.00f; *b = 0.000f;
			break;
		case 3:
			*r = 0.666f; *g = 1.000f; *b = 0.933f;
			break;
		case 4:
			*r = 0.800f; *g = 0.266f; *b = 0.800f;
			break;
		case 5:
			*r = 0.000f; *g = 0.800f; *b = 0.333f;
			break;
		case 6:
			*r = 0.000f; *g = 0.000f; *b = 0.666f;
			break;
		case 7:
			*r = 0.933f; *g = 0.933f; *b = 0.466f;
			break;
		case 8:
			*r = 0.866f; *g = 0.553f; *b = 0.333f;
			break;
		case 9:
			*r = 0.400f; *g = 0.266f; *b = 0.000f;
			break;
		case 10:
			*r = 1.000f; *g = 0.466f; *b = 0.466f;
			break;
		case 11:
			*r = 0.200f; *g = 0.200f; *b = 0.200f;
			break;
		case 12:
			*r = 0.466f; *g = 0.466f; *b = 0.466f;
			break;
		case 13:
			*r = 0.666f; *g = 1.000f; *b = 0.400f;
			break;
		case 14:
			*r = 0.000f; *g = 0.533f; *b = 1.000f;
			break;
		case 15:
			*r = 0.733f; *g = 0.733f; *b = 0.733f;
			break;
	}
}




/*
 // create ASCII font from CBM characters
 Cu8Buffer *u8Buffer = new Cu8Buffer(false, "/c64/char", DEPLOY_FILE_TYPE_DATA, false);
 uint8 *charData = u8Buffer->data + 0x0800;
 CSlrFontProportional *newFont = ProcessCBMFonts(charData, false);
 delete u8Buffer;
 
 u8Buffer = new Cu8Buffer();
 newFont->StoreFontAndTexture(newFont->texturePageImageData, u8Buffer);
 
 u8Buffer->storeToDocuments("/c64/c64shifted.fnt");
 
 ////
 //		charData = u8Buffer->data; // + 0x0800;
 //		fontCBM1 = ProcessCBMFonts(charData, true);
 //		u8Buffer = new Cu8Buffer();
 //		font->StoreFontAndTexture(font->texturePageImageData, u8Buffer);
 //		u8Buffer->storeToDocuments("/c64/cbm1.fnt");

 
 */

/*
switch (colorNum)
{
	case 0:
		*r =   0; *g =   0; *b =   0;
		break;
	case 1:
		*r = 255; *g = 255; *b = 255;
		break;
	case 2:
		*r = 136; *g =   0; *b =   0;
		break;
	case 3:
		*r = 169; *g = 255; *b = 238;
		break;
	case 4:
		*r = 204; *g =  68; *b = 204;
		break;
	case 5:
		*r =   0; *g = 204; *b =  85;
		break;
	case 6:
		*r =   0; *g =   0; *b = 170;
		break;
	case 7:
		*r = 238; *g = 238; *b = 119;
		break;
	case 8:
		*r = 221; *g = 141; *b =  85;
		break;
	case 9:
		*r = 102; *g =  68; *b = 0;
		break;
	case 10:
		*r = 255; *g = 119; *b = 119;
		break;
	case 11:
		*r =  51; *g =  51; *b =  51;
		break;
	case 12:
		*r = 119; *g = 119; *b = 119;
		break;
	case 13:
		*r = 170; *g = 255; *b = 102;
		break;
	case 14:
		*r =   0; *g = 141; *b = 255;
		break;
	case 15:
		*r = 187; *g = 187; *b = 187;
		break;
}
*/
