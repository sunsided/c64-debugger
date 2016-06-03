#ifndef _CSLRIMAGEBASE_H_
#define _CSLRIMAGEBASE_H_

#include "CSlrResourceBase.h"

#define IMAGE_TYPE_UNKNOWN	0x00
#define IMAGE_TYPE_BITMAP	0x01
#define IMAGE_TYPE_ATLAS	0x02
#define IMAGE_TYPE_FRAGMENT	0x03
#define IMAGE_TYPE_CONTAINER	0x04

#define IMAGE_LOAD_ERROR_NONE           0x00
#define IMAGE_LOAD_ERROR_NOT_LOADED     0x01
#define IMAGE_LOAD_ERROR_NOT_FOUND      0x02
#define IMAGE_LOAD_ERROR_NOT_IMAGE      0x03


class CSlrImageBase : public CSlrResourceBase
{
public:
	CSlrImageBase();
	virtual ~CSlrImageBase();
	
	byte imageType;
	
	GLfloat height;
	GLfloat width;
	GLfloat heightD2;	// divided by 2
	GLfloat widthD2;
	GLfloat heightM2;	// multiplied by 2
	GLfloat widthM2;

	virtual void Render(float posZ);
	virtual void Render(float posZ, float alpha);
	virtual void RenderMixColor(float posZ, float alpha, float mixColorR, float mixColorG, float mixColorB);
	
	virtual void GetPixel(u16 x, u16 y, byte *r, byte *g, byte *b);

	virtual void Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
	virtual void Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			  GLfloat texStartX, GLfloat texStartY,
			  GLfloat texEndX, GLfloat texEndY);

	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
			GLfloat sizeY, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY,
				   GLfloat alpha);
	virtual void RenderAlpha_aaaa(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY,
				   GLfloat alpha);
	virtual void RenderAlphaColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

	virtual void RenderAlphaMixColor(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
									 GLfloat sizeY, float mixColorR, float mixColorG, float mixColorB, float alpha);
	
	virtual void RenderPolygonAlpha(GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices);
	virtual void RenderPolygonMixColor(GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices);
	virtual void RenderFlipHorizontal(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);

	// should preload resource and set resource size
	virtual bool ResourcePreload(char *fileName, bool fromResources);

	// resource should free memory, @returns memory freed
	virtual u32 ResourceDeactivate(bool async);

	// resource should load itself, @returns memory allocated
	virtual u32 ResourceActivate(bool async);

	// get size of resource in bytes
	virtual u32 ResourceGetLoadingSize();
	virtual u32 ResourceGetIdleSize();
};

#endif
//_CSLRIMAGEBASE_H_
