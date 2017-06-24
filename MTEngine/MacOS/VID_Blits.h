#ifndef _VID_BLITS_H_
#define _VID_BLITS_H_

#import <OpenGL/glu.h>
#include "CSlrImage.h"

class CGLLineStrip
{
public:
	GLfloat *lineStripData;
	int length;
	int dataLen;
	
	CGLLineStrip()
	{
		this->lineStripData = NULL;
		this->length = 0;
		this->dataLen = 0;
	}
	
	CGLLineStrip(GLfloat *lineStripData, int length, int dataLen)
	{
		this->lineStripData = lineStripData;
		this->length = length;
		this->dataLen = dataLen;
	}
	
	void Clear()
	{
		if (lineStripData)
		{
			delete [] lineStripData;
			lineStripData = NULL;
		}
		this->length = 0;
		this->dataLen = 0;
	}
	
	void Update(int dataLen)
	{
		if (this->dataLen != dataLen)
		{
			if (lineStripData)
				delete []lineStripData;
			
			this->lineStripData = new GLfloat[dataLen];
		}
	}
	
	~CGLLineStrip()
	{
		if (lineStripData)
			delete [] this->lineStripData;
	}
};


static const float fontQuadZero = 0.006f;
static const float fontQuadOne = 0.994f;

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
				 GLfloat texStartX, GLfloat texStartY,
				 GLfloat texEndX, GLfloat texEndY,
				 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z);
void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha);
void BlitSize(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size);
void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size, 
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY);
void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size, 
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, GLfloat alpha);

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitFlipVertical(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
#define BlitFlippedVertical BlitFlipVertical
#define BlitFlippedHorizontal BlitFlipHorizontal
void BlitCheckAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha);
void BlitAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha);
void BlitCheckAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha);
void BlitCheckAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY);

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, 
			   GLfloat alpha);

void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha,
				  GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB);

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, 
			   GLfloat alpha);

void BlitAlphaColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
					GLfloat texStartX, GLfloat texStartY,
					GLfloat texEndX, GLfloat texEndY,
					GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitTriangleAlpha(CSlrImage *what, GLfloat z, GLfloat alpha,
					   GLfloat vert1x, GLfloat vert1y, GLfloat tex1x, GLfloat tex1y,
					   GLfloat vert2x, GLfloat vert2y, GLfloat tex2x, GLfloat tex2y,
					   GLfloat vert3x, GLfloat vert3y, GLfloat tex3x, GLfloat tex3y);

void BlitPolygonAlpha(CSlrImage *what, GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices);
void BlitPolygonMixColor(CSlrImage *what, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices);

void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitGradientRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						   GLfloat colorR1, GLfloat colorG1, GLfloat colorB1, GLfloat colorA1,
						   GLfloat colorR2, GLfloat colorG2, GLfloat colorB2, GLfloat colorA2,
						   GLfloat colorR3, GLfloat colorG3, GLfloat colorB3, GLfloat colorA3,
						   GLfloat colorR4, GLfloat colorG4, GLfloat colorB4, GLfloat colorA4);

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, float width);


void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, 
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, GLfloat lineWidth);

void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA);
void BlitFilledCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA);

void VID_EnableSolidsOnly();
void VID_DisableSolidsOnly();

void VID_DisableTextures();
void VID_EnableTextures();

//void BlitFilledPolygon(b2PolygonShape *polygon, GLfloat posZ,
//					   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void GenerateLineStrip(CGLLineStrip *lineStrip, signed short *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void GenerateLineStripFromFft(CGLLineStrip *lineStrip, float *data, int start, int count, float multiplier, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void GenerateLineStripFromFloat(CGLLineStrip *lineStrip, float *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void GenerateLineStripFromCircularBuffer(CGLLineStrip *lineStrip, signed short *data, int length, int pos, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void BlitLineStrip(CGLLineStrip *glLineStrip, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha);
void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha);

void PushMatrix2D();
void PopMatrix2D();
void Translate2D(GLfloat posX, GLfloat posY, GLfloat posZ);
void Rotate2D(GLfloat angle);
void Scale2D(GLfloat scaleX, GLfloat scaleY, GLfloat scaleZ);

void BlitRotatedImage(CSlrImage *image, GLfloat pX, GLfloat pY, GLfloat pZ, GLfloat rotationAngle, GLfloat alpha);

void glEnable2D();
void glDisable2D();

#endif
//_VID_BLITS_H_

