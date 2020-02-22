#ifndef _SLRIMAGETEXTURE_H_
#define _SLRIMAGETEXTURE_H_

#include "CSlrImageBase.h"

class CSlrImageTexture : public CSlrImageBase
{
public:
	volatile bool isActive;
	volatile bool isBound;

	CSlrImageTexture();
	
	virtual void DelayedLoadImage(char *fileName, bool fromResources);
	virtual void BindImage();
	virtual void FreeLoadImage();
	virtual void Deallocate();

	virtual bool CheckIfActive();
	virtual void Render(float posZ);
	virtual void Render(float posZ, float alpha);
	virtual void RenderMixColor(float posZ, float alpha, float mixColorR, float mixColorG, float mixColorB);

	virtual void Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
	virtual void Render(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			  GLfloat texStartX, GLfloat texStartY,
			  GLfloat texEndX, GLfloat texEndY);
	virtual void Render(GLfloat destX, GLfloat destY, GLfloat z,
						GLfloat sizeX, GLfloat sizeY,
						GLfloat texStartX, GLfloat texStartY,
						GLfloat texEndX, GLfloat texEndY);
	
	
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX,
			GLfloat sizeY, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
				   GLfloat texStartX, GLfloat texStartY,
				   GLfloat texEndX, GLfloat texEndY, GLfloat alpha);
	virtual void RenderAlpha(GLfloat destX, GLfloat destY, GLfloat z,
			GLfloat sizeX, GLfloat sizeY,
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

	///////// resource base
	// resource should free memory, @returns memory freed
	virtual u32 ResourceDeactivate(bool async);

	// resource should load itself, @returns memory allocated
	virtual u32 ResourceActivate(bool async);
	
	virtual char *ResourceGetTypeName();
};

#endif
//
