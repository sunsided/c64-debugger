/*
 *  CSlrFontProportional.mm
 *
 *  Created by Marcin Skoczylas on 11-04-04.
 *  Copyright 2011 rabidus. All rights reserved.
 *
 */

#include "CSlrFontProportional.h"
#include "RES_ResourceManager.h"
#include "CSlrString.h"
#include "SYS_Main.h"
#include "VID_ImageBinding.h"

CSlrFontProportional::CSlrFontProportional()
{
	this->fontType = FONT_TYPE_PROPORTIONAL;
	this->proportionalFontType = FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE;
	this->name = strdup("");
	
	this->texturePage = NULL;
	this->texturePageImageData = NULL;
	this->releaseImage = true;
	this->forceCapitals = false;
	
	this->lineHeight = 0;
	this->base = 0;
	this->width = 0;
	this->height = 0;
	this->pages = 0;
	this->outline = 0;
	
	this->fontHeight = 0.0f;
	
	this->scaleAdjust = 1.0f;
	
	this->texDividerX = 1.0f;
	this->texDividerY = 1.0f;
	texAdvX = 0; //(float) texDividerX/width;
	texAdvY = 0; //(float) texDividerY/height;
}

CSlrFontProportional::CSlrFontProportional(bool fromResources, char *fontPath)
{
	bool linearScale = true;
	
	this->fontType = FONT_TYPE_PROPORTIONAL;
	this->name = strdup(fontPath);
	this->texturePageImageData = NULL;

	ResourceSetPath(fontPath, fromResources);
	
	this->forceCapitals = false;

	char buf[512];
	sprintf(buf, "%s", fontPath);
	CByteBuffer *fontData = new CByteBuffer(fromResources, buf, DEPLOY_FILE_TYPE_FONT);

	this->LoadFontData(fontData, linearScale);
	delete fontData;
	
	this->releaseImage = true;
	if (this->proportionalFontType == FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE)
	{
		this->texturePage = RES_GetImageAsync(fontPath, linearScale, fromResources);
	}

}

CSlrFontProportional::CSlrFontProportional(bool fromResources, char *fontPath, bool linearScale)
{
	this->fontType = FONT_TYPE_PROPORTIONAL;
	this->name = strdup(fontPath);
	this->texturePageImageData = NULL;

	ResourceSetPath(fontPath, fromResources);
	
	this->forceCapitals = false;
	
	char buf[512];
	sprintf(buf, "%s", fontPath);
	CByteBuffer *fontData = new CByteBuffer(fromResources, buf, DEPLOY_FILE_TYPE_FONT);
	
	this->LoadFontData(fontData, linearScale);
	delete fontData;
	
	this->releaseImage = true;
	if (this->proportionalFontType == FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE)
	{
		this->texturePage = RES_GetImageAsync(fontPath, linearScale, fromResources);
	}
}

CSlrFontProportional::CSlrFontProportional(CByteBuffer *fontData, CSlrImage *texturePage, bool linearScale)
{
	LOGTODO("CSlrFontProportional::CSlrFontProportional: from buffer deprecated (res manager) !!!");

	this->name = NULL;
	this->fontType = FONT_TYPE_PROPORTIONAL;
	this->proportionalFontType = FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE;

	this->texturePage = texturePage;
	this->texturePageImageData = NULL;
	this->releaseImage = false;
	this->forceCapitals = false;

	this->LoadFontData(fontData, linearScale);
}

void CSlrFontProportional::LoadFontData(CByteBuffer *fontData, bool linearScale)
{
	u32 v = fontData->getUnsignedInt();
	if (v > FONT_PROPORTIONAL_VERSION)
		SYS_FatalExit("Unknown FONT_PROPORTIONAL_VERSION");

	if (v == 1)
	{
		this->proportionalFontType = FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE;
	}
	else
	{
		this->proportionalFontType = fontData->GetByte();
	}
	
	this->lineHeight = fontData->getShort();
	this->base = fontData->getShort();
	this->width = fontData->getShort();
	this->height = fontData->getShort();
	this->pages = fontData->getShort();
	this->outline = fontData->getShort();

	short kernCount = fontData->getShort();
	for (int i = 0; i < kernCount; i++)
	{
		//TODO: kernCount
		//LOGTODO("kernCount=%d, change to map of maps F->S,S,S  S->F,F,F", kernCount);
		KerningInfo *kerningInfo = new KerningInfo();
		kerningInfo->first = fontData->getShort();
		kerningInfo->second = fontData->getShort();
		kerningInfo->amount = fontData->getShort();
		kerning.push_back(kerningInfo);
	}

	short charsCount = fontData->getShort();
	
	this->fontHeight = 0.0f;

	for (int i = 0; i < charsCount; i++)
	{
		CharDescriptor *charDescriptor = new CharDescriptor();
		int val = fontData->getInt();
		charDescriptor->x = fontData->getShort();
		charDescriptor->y = fontData->getShort();
		charDescriptor->width = fontData->getShort();
		charDescriptor->height = fontData->getShort();
		charDescriptor->xOffset = fontData->getShort();
		charDescriptor->yOffset = fontData->getShort();
		charDescriptor->xAdvance = fontData->getShort();
		charDescriptor->page = fontData->getShort();

		float h = (charDescriptor->yOffset + charDescriptor->height);
		if (h > this->fontHeight)
			this->fontHeight = h;

		//LOGD("adding charVal=%d", val);
		chars[val] = charDescriptor;
	}

	this->scaleAdjust = 1.0f;

/*
 * 	  bug: scaled textures for platforms
	u16 loadRasterWidth = NextPow2(texturePage->loadImgWidth);
	u16 loadRasterHeight = NextPow2(texturePage->loadImgHeight);

	if (loadRasterWidth != texturePage->loadImgWidth
			|| loadRasterHeight != texturePage->loadImgHeight)
	{
		LOGD("loadRasterWidth=%d loadRasterHeight=%d", loadRasterWidth, loadRasterHeight);
		LOGD("loadImgWidth=%d loadImgHeight=%d", texturePage->loadImgWidth, texturePage->loadImgHeight);
		this->texDividerX = (float)texturePage->loadImgWidth / (float)loadRasterWidth;
		this->texDividerY = (float)texturePage->loadImgHeight / (float)loadRasterHeight;

		LOGD("texDividerX=%f texDividerY=%f", texDividerX, texDividerY);

		float oneAdvX = 1.0f / (float)texturePage->loadImgWidth;
		float oneAdvY = 1.0f / (float)texturePage->loadImgHeight;

		LOGD("oneAdvX=%f oneAdvY=%f", oneAdvX, oneAdvY);

		this->texAdvX = oneAdvX * texDividerX;
		this->texAdvY = oneAdvY * texDividerY;

		LOGD("texAdvX=%f texAdvY=%f", texAdvX, texAdvY);
	}
	else*/
	{
		this->texDividerX = 1.0f;
		this->texDividerY = 1.0f;
		texAdvX = (float) texDividerX/width;
		texAdvY = (float) texDividerY/height;
	}
	
	// load font texture
	if (proportionalFontType == FONT_PROPORTIONAL_TYPE_WITH_TEXTPAGE)
	{
		CImageData *fontImageData = new CImageData(fontData);


		texturePage = new CSlrImage(true, linearScale);
		texturePage->LoadImage(fontImageData, RESOURCE_PRIORITY_STATIC, false);
		texturePage->resourceType = RESOURCE_TYPE_IMAGE_DYNAMIC;
		texturePage->resourcePriority = RESOURCE_PRIORITY_STATIC;
		VID_PostImageBinding(texturePage, NULL);
		delete fontImageData;
	}
}

void CSlrFontProportional::StoreFontDataToByteBuffer(CByteBuffer *byteBuffer)
{
	this->StoreFontDataToByteBuffer(byteBuffer, FONT_PROPORTIONAL_TYPE_WITHOUT_TEXTPAGE);
}

void CSlrFontProportional::StoreFontDataToByteBuffer(CByteBuffer *byteBuffer, byte proportionalFontType)
{
	LOGD("CSlrFontProportional::StoreFontDataToByteBuffer");
	byteBuffer->putUnsignedInt(FONT_PROPORTIONAL_VERSION);
	
	byteBuffer->PutByte(proportionalFontType);
	
	LOGD("lineHeight=%d", this->lineHeight);
	byteBuffer->putShort(this->lineHeight);
	byteBuffer->putShort(this->base);
	byteBuffer->putShort(this->width);
	byteBuffer->putShort(this->height);
	byteBuffer->putShort(this->pages);
	byteBuffer->putShort(this->outline);
	LOGD("KernCount=%d", this->kerning.size());
	byteBuffer->putShort(this->kerning.size());
	
	for (std::vector<KerningInfo *>::iterator it = this->kerning.begin(); it != this->kerning.end(); it++)
	{
		KerningInfo *kerningInfo = *it;
		LOGD("%d %d %d", kerningInfo->first, kerningInfo->second, kerningInfo->amount);
		byteBuffer->putShort(kerningInfo->first);
		byteBuffer->putShort(kerningInfo->second);
		byteBuffer->putShort(kerningInfo->amount);
	}
	
	byteBuffer->putShort(this->chars.size());
	LOGD("Chars.size=%d", this->chars.size());
	for (std::map<int, CharDescriptor *>::iterator it = this->chars.begin(); it != chars.end(); it++)
	{
		CharDescriptor *ch = (*it).second;
		
		int chVal = (*it).first;
		
		byteBuffer->putInt(chVal);
		byteBuffer->putShort(ch->x);
		byteBuffer->putShort(ch->y);
		byteBuffer->putShort(ch->width);
		byteBuffer->putShort(ch->height);
		byteBuffer->putShort(ch->xOffset);
		byteBuffer->putShort(ch->yOffset);
		byteBuffer->putShort(ch->xAdvance);
		byteBuffer->putShort(ch->page);
		
		LOGD("chVal=%d | %d %d %d %d %d %d %d %d", chVal, ch->x, ch->y, ch->width, ch->height, ch->xOffset, ch->yOffset, ch->xAdvance, ch->page);
	}
}

void CSlrFontProportional::LoadFontAndTexture(CByteBuffer *fontData)
{
}

void CSlrFontProportional::StoreFontAndTexture(CImageData *image, CByteBuffer *fontData)
{
	this->StoreFontDataToByteBuffer(fontData, FONT_PROPORTIONAL_TYPE_WITH_TEXTPAGE);
	image->StoreToByteBuffer(fontData);
}


// TODO: change to map of maps
int CSlrFontProportional::GetKerningPair(int first, int second)
{
	if (!kerning.empty())
	{
		for (u32 j = 0; j < kerning.size(); j++)
		{
			if (kerning[j]->first == first && kerning[j]->second == second)
			{
				return kerning[j]->amount;
			}
		}
	}

	return 0;
}

float CSlrFontProportional::GetStringWidth(const char *str)
{
	float total=0;

	u32 l = strlen(str);
	for (unsigned int i = 0; i != l; i++)
	{
		CharDescriptor *f = GetCharDescriptor(str[i]);
		if (f == NULL)
			continue;
		
		total += f->xAdvance;
	}

	return total * scaleAdjust;
}

float CSlrFontProportional::GetStringWidth(CSlrString *str)
{
	float total=0;

	u32 l = str->GetLength();
	for (u32 i = 0; i != l; i++)
	{
		CharDescriptor *f = GetCharDescriptorInt(str->GetChar(i));
		if (f == NULL)
			continue;

		total += f->xAdvance;
	}

	return total * scaleAdjust;
}

float CSlrFontProportional::GetStringWidth(CSlrString *str, float advance)
{
	float total=0;
		
	u32 l = str->GetLength();
	for (u32 i = 0; i != l; i++)
	{
		CharDescriptor *f = GetCharDescriptorInt(str->GetChar(i));
		if (f == NULL)
			continue;
		
		total += (f->xAdvance * advance);
	}
	
	return total * scaleAdjust;
}

float CSlrFontProportional::GetCharWidth(char ch, float scale)
{
	CharDescriptor *f = GetCharDescriptor(ch);
	if (f == NULL)
		return 0.0f;
	
	return f->xAdvance * scale * scaleAdjust;
}

float CSlrFontProportional::GetCharHeight(char ch, float scale)
{
	CharDescriptor *f = GetCharDescriptor(ch);
	if (f == NULL)
		return 0.0f;
	return f->height * scale * scaleAdjust;
}

void CSlrFontProportional::BlitChar(char chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha)
{
	CharDescriptor *f = GetCharDescriptor(chr);
	if (f == NULL)
		return;

	this->texturePage->RenderAlpha(posX + (f->xOffset*size), posY + (f->yOffset*size), posZ,
			f->width * size, f->height * size,
			texAdvX*f->x,
			texAdvY*f->y,
			texAdvX*(f->x + f->width),
			texAdvY*(f->y + f->height),
			alpha);

}

void CSlrFontProportional::BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size)
{
	CharDescriptor *f = GetCharDescriptorInt(chr);
	if (f == NULL)
		return;
	
	this->texturePage->Render(posX + (f->xOffset*size), posY + (f->yOffset*size), posZ,
								   f->width * size, f->height * size,
								   texAdvX*f->x,
								   texAdvY*f->y,
								   texAdvX*(f->x + f->width) - 0.0005f,
								   texAdvY*(f->y + f->height) - 0.0005f);
}

void CSlrFontProportional::BlitChar(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, GLfloat alpha)
{
	CharDescriptor *f = GetCharDescriptorInt(chr);
	if (f == NULL)
		return;
	
	this->texturePage->RenderAlpha(posX + (f->xOffset*size), posY + (f->yOffset*size), posZ,
								   f->width * size, f->height * size,
								   texAdvX*f->x,
								   texAdvY*f->y,
								   texAdvX*(f->x + f->width) - 0.0005f,
								   texAdvY*(f->y + f->height) - 0.0005f,
								   alpha);
	
}

void CSlrFontProportional::BlitCharColor(u16 chr, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat size, float r, float g, float b, float alpha)
{
	CharDescriptor *f = GetCharDescriptorInt(chr);
	if (f == NULL)
		return;
	
	this->texturePage->RenderAlphaColor(posX + (f->xOffset*size), posY + (f->yOffset*size), posZ,
								   f->width * size, f->height * size,
								   texAdvX*f->x,
								   texAdvY*f->y,
								   texAdvX*(f->x + f->width) - 0.0005f,
								   texAdvY*(f->y + f->height) - 0.0005f,
								   r, g, b, alpha);
	
}


void CSlrFontProportional::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;
	
	float curX = posX;
	float curY = posY;

	posY += lineHeight * scale * scaleAdjust;
	
	u16 l = strlen(text);
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptor(text[i]);
		if (f == NULL)
			continue;
		
		this->texturePage->RenderAlpha(curX + (f->xOffset * scale * scaleAdjust), curY + (f->yOffset * scale * scaleAdjust), posZ,
				  f->width * scale * scaleAdjust, f->height * scale * scaleAdjust,
				  advX*f->x,
				  advY*f->y,
				  advX*(f->x + f->width),
				  advY*(f->y + f->height),
				  1.0f);
		
		if (l > 1 && i < l)
		{
			curX += GetKerningPair(text[i], text[i+1]) * scale * scaleAdjust;
		}
		
		curX += f->xAdvance * scale * scaleAdjust;
	}

}

void CSlrFontProportional::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scaleX, GLfloat scaleY, GLfloat alpha)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;
	
	float curX = posX;
	float curY = posY;
	
	posY += lineHeight * scaleY * scaleAdjust;
	
	u16 l = strlen(text);
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptor(text[i]);
		if (f == NULL)
			continue;
		
		this->texturePage->RenderAlpha(curX + (f->xOffset * scaleX * scaleAdjust), curY + (f->yOffset * scaleY * scaleAdjust), posZ,
									   f->width * scaleX * scaleAdjust, f->height * scaleY * scaleAdjust,
									   advX*f->x,
									   advY*f->y,
									   advX*(f->x + f->width),
									   advY*(f->y + f->height),
									   alpha);
		
		if (l > 1 && i < l1)
		{
			curX += GetKerningPair(text[i], text[i+1]) * scaleX * scaleAdjust;
		}
		
		curX += f->xAdvance * scaleX * scaleAdjust;
	}

}

void CSlrFontProportional::BlitText(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat alpha)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;

	float curX = posX;
	float curY = posY;

	posY += lineHeight * scale * scaleAdjust;

	u16 l = strlen(text);
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptor(text[i]);
		if (f == NULL)
			continue;

		this->texturePage->RenderAlpha(curX + (f->xOffset * scale * scaleAdjust), curY + (f->yOffset * scale * scaleAdjust), posZ,
				f->width * scale * scaleAdjust, f->height * scale * scaleAdjust,
				advX*f->x,
				advY*f->y,
				advX*(f->x + f->width),
				advY*(f->y + f->height),
				alpha);

		if (l > 1 && i < l1)
		{
			curX += GetKerningPair(text[i], text[i+1]) * scale * scaleAdjust;
		}

		curX += f->xAdvance * scale * scaleAdjust;
	}

}

void CSlrFontProportional::BlitTextColor(char *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;

	float curX = posX;
	float curY = posY;

	posY += lineHeight * scale * scaleAdjust;

	u16 l = strlen(text);
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptor(text[i]);
		if (f == NULL)
			continue;

		this->texturePage->RenderAlphaColor(curX + (f->xOffset * scale * scaleAdjust), curY + (f->yOffset * scale * scaleAdjust), posZ,
				f->width * scale * scaleAdjust, f->height * scale * scaleAdjust,
				advX*f->x,
				advY*f->y,
				advX*(f->x + f->width),
				advY*(f->y + f->height),
				colorR, colorG, colorB, alpha);

		if (l > 1 && i < l1)
		{
			curX += GetKerningPair(text[i], text[i+1]) * scale * scaleAdjust;
		}

		curX += f->xAdvance * scale * scaleAdjust;
	}
}

void CSlrFontProportional::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	this->BlitTextColor(text, posX, posY, posZ, scale, colorR, colorG, colorB, alpha, FONT_ALIGN_LEFT);
}

void CSlrFontProportional::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, int align)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;
	
	float curX = posX;
	float curY = posY;
	
	if (align == FONT_ALIGN_RIGHT)
	{
		float w = this->GetTextWidth(text, scale);
		curX -= w;
	}
	else if (align == FONT_ALIGN_CENTER)
	{
		float w = this->GetTextWidth(text, scale);
		curX -= w/2.0f;
	}
	
	posY += lineHeight * scale * scaleAdjust;
	
	u16 l = text->GetLength();
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptorInt(text->GetChar(i));
		if (f == NULL)
			continue;
		
		this->texturePage->RenderAlphaColor(curX + (f->xOffset * scale * scaleAdjust), curY + (f->yOffset * scale * scaleAdjust), posZ,
					   f->width * scale * scaleAdjust, f->height * scale * scaleAdjust,
					   advX*f->x,
					   advY*f->y,
					   advX*(f->x + f->width),
					   advY*(f->y + f->height),
					   colorR, colorG, colorB, alpha);
		
		if (l > 1 && i < l1)
		{
			curX += GetKerningPair(text->GetChar(i), text->GetChar(i+1)) * scale * scaleAdjust;
		}
		
		curX += f->xAdvance * scale * scaleAdjust;
	}
}

void CSlrFontProportional::BlitTextColor(CSlrString *text, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat scale, float advance, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	float advX = (float) 1.0f/width;
	float advY = (float) 1.0f/height;
	
	float curX = posX;
	float curY = posY;
	
	posY += lineHeight * scale * scaleAdjust;
	
	u16 l = text->GetLength();
	u16 l1 = l-1;
	for (u16 i = 0; i < l; i++)
	{
		CharDescriptor *f = GetCharDescriptorInt(text->GetChar(i));
		if (f == NULL)
			continue;
		
		this->texturePage->RenderAlphaColor(curX + (f->xOffset * scale * scaleAdjust), curY + (f->yOffset * scale * scaleAdjust), posZ,
											f->width * scale * scaleAdjust, f->height * scale * scaleAdjust,
											advX*f->x,
											advY*f->y,
											advX*(f->x + f->width),
											advY*(f->y + f->height),
											colorR, colorG, colorB, alpha);
		
		if (l > 1 && i < l1)
		{
			curX += GetKerningPair(text->GetChar(i), text->GetChar(i+1)) * scale * scaleAdjust;
		}
		
		curX += (f->xAdvance * advance) * scale * scaleAdjust;
	}
}

void CSlrFontProportional::BlitText(char *text, GLfloat x, GLfloat y, GLfloat z,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha,
			  int align, GLfloat scale)
{
	if (align != FONT_ALIGN_LEFT)
		SYS_FatalExit("CSlrFontProportional::BlitText: align=%d not implemented", align);
	this->BlitText(text, x, y, z, scale, alpha);
}


float CSlrFontProportional::GetTextWidth(char *text, float scale)
{
	return this->GetStringWidth(text) * scale;
}

float CSlrFontProportional::GetTextWidth(CSlrString *text, float scale)
{
	return this->GetStringWidth(text) * scale;
}

void CSlrFontProportional::GetTextSize(CSlrString *text, float scale, float *width, float *height)
{
	*width = this->GetStringWidth(text) * scale;
	*height = ((float)this->fontHeight * scale * scaleAdjust);
}

void CSlrFontProportional::GetTextSize(CSlrString *text, float scale, float advance, float *width, float *height)
{
	*width = this->GetStringWidth(text, advance) * scale;
	*height = ((float)this->fontHeight * scale * scaleAdjust);
}

void CSlrFontProportional::GetTextSize(char *text, float scale, u16 *width, u16 *height)
{
	*width = this->GetTextWidth(text, scale);
	*height = (u16)((float)this->lineHeight * scale * scaleAdjust);
}

void CSlrFontProportional::GetTextSize(char *text, float scale, float *width, float *height)
{
	*width = this->GetTextWidth(text, scale);
	*height = ((float)this->fontHeight * scale * scaleAdjust);
}


CharDescriptor *CSlrFontProportional::GetCharDescriptor(char ch)
{
	char c = ch;
	
	if (this->forceCapitals)
	{
		c = toupper(ch);
	}
	
	int val = (int)c;
	std::map<int, CharDescriptor *>::iterator it = chars.find(val);
	if (it == chars.end())
	{
		//LOGError("CSlrFontProportional::BlitText: char %d not found", val);
		return NULL;
	}
	CharDescriptor *f = (*it).second;
	return f;
}

CharDescriptor *CSlrFontProportional::GetCharDescriptorInt(u16 ch)
{
	if (this->forceCapitals)
	{
		if (ch > 0x60 && ch < 0x7B)
		{
			ch -= 0x20;
		}
		else if (ch > 0x100)
		{
			LOGTODO("CSlrFontProportional::GetCharDescriptorInt: forceCapitals");
		}
	}

	int val = (int)ch;
	std::map<int, CharDescriptor *>::iterator it = chars.find(val);
	if (it == chars.end())
	{
		//LOGError("CSlrFontProportional::BlitText: char %d not found", val);
		return NULL;
	}
	CharDescriptor *f = (*it).second;
	return f;
}

float CSlrFontProportional::GetLineHeight()
{
	return this->fontHeight * scaleAdjust;
}

void CSlrFontProportional::ResourcesPrepare()
{
	texturePage->ResourcePrepare();
}

void CSlrFontProportional::ResourceSetPriority(byte newPriority)
{
	CSlrResourceBase::ResourceSetPriority(newPriority);
	this->texturePage->ResourceSetPriority(newPriority);
}

CSlrFontProportional::~CSlrFontProportional()
{
	if (this->name)
		free(name);
	name = NULL;
	
	if (releaseImage)
	{
		RES_ReleaseImage(this->texturePage);
	}
}
