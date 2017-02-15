#include "VID_Blits.h"
#include "VID_GLViewController.h"
#include "CSlrImage.h"
#include "CContinuousParamSin.h"
#include "CContinuousParamBezier.h"
#include "MTH_FastMath.h"

// STENCIL
// http://stackoverflow.com/questions/11383940/use-stencil-buffer-with-ios

GLuint      texture[1];

static GLfloat vertices[] = {
	-1.0,  1.0, -3.0,
	1.0,  1.0, -3.0,
	-1.0, -1.0, -3.0,
	1.0, -1.0, -3.0
};


static Vector3D normals[] = {
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0},
	{0.0, 0.0, 1.0}
};

static GLfloat texCoords[] = {
	0.0, 1.0,
	1.0, 1.0,
	0.0, 0.0,
	1.0, 0.0
};

static GLfloat vertsColors[] = {
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0
};

static GLfloat colorsOne[] = {
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0,
	1.0,  1.0, 1.0, 1.0
};

/*static float shrink = 0.00;
static float LEFT_OFFSET_X	= shrink +		0.0;
static float TOP_OFFSET_Y	= shrink +		0.0;
static float RIGHT_OFFSET_X = -shrink +		480.0;
static float BOTTOM_OFFSET_Y = -shrink +	320.0;
float VIEW_SHRINKED_WIDTH = (RIGHT_OFFSET_X - LEFT_OFFSET_X);
float VIEW_SHRINKED_HEIGHT = (BOTTOM_OFFSET_Y - TOP_OFFSET_Y);*/

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	/*
	 texCoords[0] = texStartY;
	 texCoords[1] = texEndX;
	 texCoords[2] = texEndY;
	 texCoords[3] = texEndX;
	 texCoords[4] = texStartY;
	 texCoords[5] = texStartX;
	 texCoords[6] = texEndY;
	 texCoords[7] = texStartX;
	 */

	texCoords[0] = 0.0;
	texCoords[1] = 1.0;
	texCoords[2] = 1.0;
	texCoords[3] = 1.0;
	texCoords[4] = 0.0;
	texCoords[5] = 0.0;
	texCoords[6] = 1.0;
	texCoords[7] = 0.0;

	vertices[0]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[1]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[4]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[7]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[10] =	destY			; //+ TOP_OFFSET_Y;
	vertices[11] =	z;
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, tex);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				 GLfloat texStartX, GLfloat texStartY,
				 GLfloat texEndX, GLfloat texEndY,
				 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[1]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[4]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[7]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[10] =	destY			; //+ TOP_OFFSET_Y;
	vertices[11] =	z;

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBindTexture(GL_TEXTURE_2D, tex);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glColor4f(colorR, colorG, colorB, alpha);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}


void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;

	vertices[0] = -1.0 + destY ; //+ TOP_OFFSET_Y;
	vertices[1] = 1.0 + destX ; //+ LEFT_OFFSET_X;
	vertices[2] = z;

	vertices[3] =  1.0 + destY ; //+ TOP_OFFSET_Y;
	vertices[4] =  1.0 + destX ; //+ LEFT_OFFSET_X;
	vertices[5] = z;

	vertices[6] = -1.0 + destY ; //+ TOP_OFFSET_Y;
	vertices[7] = -1.0 + destX ; //+ LEFT_OFFSET_X;
	vertices[8] = z;

	vertices[9] =  1.0 + destY ; //+ TOP_OFFSET_Y;
	vertices[10] = -1.0 + destX ; //+ LEFT_OFFSET_X;
	vertices[11] = z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;

	vertices[0] = -1.0 + destY  ;
	vertices[1] =  1.0 + destX  ;
	vertices[2] = z;

	vertices[3] =  1.0 + destY  ;
	vertices[4] =  1.0 + destX  ;
	vertices[5] = z;

	vertices[6] = -1.0 + destY  ;
	vertices[7] = -1.0 + destX  ;
	vertices[8] = z;

	vertices[9] =  1.0 + destY  ;
	vertices[10] = -1.0 + destX ;
	vertices[11] = z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}


void BlitSize(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size)
{
	GLfloat sizeX = size;
	GLfloat sizeY = size;

	texCoords[0] = 0.0;
	texCoords[1] = 0.0;
	texCoords[2] = 1.0;
	texCoords[3] = 0.0;
	texCoords[4] = 0.0;
	texCoords[5] = 1.0;
	texCoords[6] = 1.0;
	texCoords[7] = 1.0;

	vertices[0]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[1]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[4]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[7]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[10] =	destY			; //+ TOP_OFFSET_Y;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("Blit: x=%f y=%f sx=%f sy=%f", destX, destY, sizeX, sizeY);

	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[1]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[4]  =  sizeY + destY	; //+ TOP_OFFSET_Y;
	vertices[5]  =	z;

	vertices[6]  =  destX			; //+ LEFT_OFFSET_X;
	vertices[7]  =  destY			; //+ TOP_OFFSET_Y;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	; //+ LEFT_OFFSET_X;
	vertices[10] =	destY			; //+ TOP_OFFSET_Y;
	vertices[11] =	z;

	for (int i = 0; i < 12; i++)
	{
		//LOGD("vertices[%d] = %f", i, vertices[i]);
		//LOGD("  texCoords[%d] = %f", i, texCoords[i]);
	}

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void BlitFlipVertical(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("Blit: x=%f y=%f sx=%f sy=%f", destX, destY, sizeX, sizeY);

	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/

	vertices[0]  =  destX			;
	vertices[1]  =  destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  sizeY + destY	;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	sizeY + destY	;
	vertices[11] =	z;

//	for (int i = 0; i < 12; i++)
//	{
//		LOGD("vertices[%d] = %f", i, vertices[i]);
//		LOGD("  texCoords[%d] = %f", i, texCoords[i]);
//	}

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

void BlitFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	//LOGD("Blit: x=%f y=%f sx=%f sy=%f", destX, destY, sizeX, sizeY);
	
	texCoords[0] = what->defaultTexEndX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexStartX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexEndX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexStartX;
	texCoords[7] = what->defaultTexEndY;
	/*	texCoords[0] = 0.0;
	 texCoords[1] = 0.0;
	 texCoords[2] = 1.0;
	 texCoords[3] = 0.0;
	 texCoords[4] = 0.0;
	 texCoords[5] = 1.0;
	 texCoords[6] = 1.0;
	 texCoords[7] = 1.0;*/
	
	vertices[0]  =  destX	;
	vertices[1]  =  destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  sizeY + destY	;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	sizeY + destY	;
	vertices[11] =	z;
	
//	for (int i = 0; i < 12; i++)
//	{
//		LOGD("vertices[%d] = %f", i, vertices[i]);
//		LOGD("  texCoords[%d] = %f", i, texCoords[i]);
//	}
	
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
}

void BlitAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	sizeX -=1;
	sizeY -=1;
	
	// plain exchange y
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = 1.0f - what->defaultTexStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void BlitAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	sizeX -=1;
	sizeY -=1;

	// plain exchange y
	texCoords[0] = what->defaultTexEndX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexStartX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexEndX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexStartX;
	texCoords[7] = 1.0f - what->defaultTexStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void BlitAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	sizeX -=1;
	sizeY -=1;
	
	// plain exchange y
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = 1.0f - what->defaultTexEndY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = 1.0f - what->defaultTexEndY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = 1.0f - what->defaultTexStartY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = 1.0f - what->defaultTexStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->imgAtlas->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha,
				  GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
	
		glBindTexture(GL_TEXTURE_2D, what->texture[0]);
		glVertexPointer(3, GL_FLOAT, 0, vertices);
		glNormalPointer(GL_FLOAT, 0, normals);
		glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
		
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glColor4f(mixColorR, mixColorG, mixColorB, alpha);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		glColor4f(1.0f, 1.0f, 1.0f, 1.0f);


	
	
//		glBindTexture(GL_TEXTURE_2D, what->texture[0]);
//		
//		//glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
//		glColor4f(mixColorR, mixColorG, mixColorB, alpha);
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//		//glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	texCoords[0] = what->defaultTexStartX;
	texCoords[1] = what->defaultTexStartY;
	texCoords[2] = what->defaultTexEndX;
	texCoords[3] = what->defaultTexStartY;
	texCoords[4] = what->defaultTexStartX;
	texCoords[5] = what->defaultTexEndY;
	texCoords[6] = what->defaultTexEndX;
	texCoords[7] = what->defaultTexEndY;
	
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

void BlitAlphaColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
					GLfloat texStartX, GLfloat texStartY,
					GLfloat texEndX, GLfloat texEndY,
					GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
#ifdef LOG_BLITS  
	LOGG("BlitAlphaColor: %s", what->name);
#endif
	
#ifdef ORIENTATION_LANDSCAPE
	texCoords[0] = texStartY;
	texCoords[1] = texEndX;
	texCoords[2] = texEndY;
	texCoords[3] = texEndX;
	texCoords[4] = texStartY;
	texCoords[5] = texStartX;
	texCoords[6] = texEndY;
	texCoords[7] = texStartX;
	
	vertices[0]  =  destY                   ;
	vertices[1]  =  sizeX + destX   ;
	vertices[2]  =  z;
	
	vertices[3]  =  sizeY + destY   ;
	vertices[4]  =  sizeX + destX   ;
	vertices[5]  =  z;
	
	vertices[6]  =  destY                   ;
	vertices[7]  =  destX                   ;
	vertices[8]  =  z;
	
	vertices[9]  =  sizeY + destY   ;
	vertices[10] =  destX                   ;
	vertices[11] =  z;
#else
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;
	
	vertices[0]  =  destX                   ;
	vertices[1]  =  sizeY + destY   ;
	vertices[2]  =  z;
	
	vertices[3]  =  sizeX + destX   ;
	vertices[4]  =  sizeY + destY   ;
	vertices[5]  =  z;
	
	vertices[6]  =  destX                   ;
	vertices[7]  =  destY                   ;
	vertices[8]  =  z;
	
	vertices[9]  =  sizeX + destX   ;
	vertices[10] =  destY                   ;
	vertices[11] =  z;
#endif
	
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(colorR, colorG, colorB, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
#ifdef LOG_BLITS
	LOGG("BlitAlphaColor done: %s", what->name);
#endif
	
}


void BlitCheckAtl(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	if (what->isFromAtlas)
	{
		BlitAtl(what, destX, destY, z, sizeX, sizeY);
	}
	else
	{
		Blit(what, destX, destY, z, sizeX, sizeY);
	}

}

void BlitCheckAtlAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha)
{
	if (what->isFromAtlas)
	{
		BlitAtlAlpha(what, destX, destY, z, sizeX, sizeY, alpha);
	}
	else
	{
		BlitAlpha(what, destX, destY, z, sizeX, sizeY, alpha);
	}

}

void BlitCheckAtlFlipHorizontal(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	if (what->isFromAtlas)
	{
		BlitAtlFlipHorizontal(what, destX, destY, z, sizeX, sizeY);
	}
	else
	{
		SYS_FatalExit("not implemented");
		//..BlitFlipHorizontal(what, destX, destY, z, sizeX, sizeY, alpha);
	}

}


void BlitOLD(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY)
{
	texCoords[0] = 0.0;
	texCoords[1] = 1.0;
	texCoords[2] = 1.0;
	texCoords[3] = 1.0;
	texCoords[4] = 0.0;
	texCoords[5] = 0.0;
	texCoords[6] = 1.0;
	texCoords[7] = 0.0;

	vertices[0]  =  destY			;
	vertices[1]  =  sizeX + destX	;
	vertices[2]  =	z;

	vertices[3]  =  sizeY + destY	;
	vertices[4]  =  sizeX + destX	;
	vertices[5]  =	z;

	vertices[6]  =  destY			;
	vertices[7]  =  destX			;
	vertices[8]  =	z;

	vertices[9]  =  sizeY + destY	;
	vertices[10] =	destX			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY)
{
	GLfloat sizeX = size;
	GLfloat sizeY = size;

	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
{
	GLfloat sizeX = size;
	GLfloat sizeY = size;

	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

	glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat size,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY, GLfloat alpha)
{
	GLfloat sizeX = size;
	GLfloat sizeY = size;
	
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;
	
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
	
	glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
}

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
		  GLfloat texStartX, GLfloat texStartY,
		  GLfloat texEndX, GLfloat texEndY)
{
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);


}

void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat alpha)
{
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;

	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}

void BlitAlpha_aaaa(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
			   GLfloat texStartX, GLfloat texStartY,
			   GLfloat texEndX, GLfloat texEndY,
			   GLfloat alpha)
{
	// plain exchange y
	texCoords[0] = texStartX;
	texCoords[1] = 1.0f - texEndY;
	texCoords[2] = texEndX;
	texCoords[3] = 1.0f - texEndY;
	texCoords[4] = texStartX;
	texCoords[5] = 1.0f - texStartY;
	texCoords[6] = texEndX;
	texCoords[7] = 1.0f - texStartY;
	
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
	
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(alpha, alpha, alpha, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
}

void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;

	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;

	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;

	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;

	glDisable(GL_TEXTURE_2D);

    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);

	glColor4f(colorR, colorG, colorB, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glEnable(GL_TEXTURE_2D);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

}

void BlitGradientRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						   GLfloat colorR1, GLfloat colorG1, GLfloat colorB1, GLfloat colorA1,
						   GLfloat colorR2, GLfloat colorG2, GLfloat colorB2, GLfloat colorA2,
						   GLfloat colorR3, GLfloat colorG3, GLfloat colorB3, GLfloat colorA3,
						   GLfloat colorR4, GLfloat colorG4, GLfloat colorB4, GLfloat colorA4)
						   
{
	vertices[0]  =  destX			;
	vertices[1]  =  sizeY + destY	;
	vertices[2]  =	z;
	
	vertices[3]  =  sizeX + destX	;
	vertices[4]  =  sizeY + destY	;
	vertices[5]  =	z;
	
	vertices[6]  =  destX			;
	vertices[7]  =  destY			;
	vertices[8]  =	z;
	
	vertices[9]  =  sizeX + destX	;
	vertices[10] =	destY			;
	vertices[11] =	z;
		
	vertsColors[0]	= colorR1;
	vertsColors[1]	= colorG1;
	vertsColors[2]	= colorB1;
	vertsColors[3]	= colorA1;

	vertsColors[4]	= colorR2;
	vertsColors[5]	= colorG2;
	vertsColors[6]	= colorB2;
	vertsColors[7]	= colorA2;

	vertsColors[8]	= colorR3;
	vertsColors[9]	= colorG3;
	vertsColors[10]	= colorB3;
	vertsColors[11]	= colorA3;

	vertsColors[12]	= colorR4;
	vertsColors[13]	= colorG4;
	vertsColors[14]	= colorB4;
	vertsColors[15]	= colorA4;

	glDisable(GL_TEXTURE_2D);
	
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
	glColorPointer(4, GL_FLOAT, 0, vertsColors);
	
	glEnableClientState(GL_COLOR_ARRAY);
	
	//glColor4f(1.0f, 0.5f, 1.0f, 1.0f);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glEnable(GL_TEXTURE_2D);
	
	glDisableClientState(GL_COLOR_ARRAY);

	//glColorPointer(3, GL_FLOAT, 0, colorsOne);
	//glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
}

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	BlitLine(destX, destY, destX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY+sizeY, destX+sizeX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX+sizeX, destY, destX+sizeX, destY+sizeY, z, colorR, colorG, colorB, alpha);
	BlitLine(destX, destY, destX+sizeX, destY, z, colorR, colorG, colorB, alpha);
}

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, GLfloat lineWidth)
{
	BlitFilledRectangle(destX, destY - lineWidth, z, sizeX, lineWidth, colorR, colorG, colorB, alpha);
	BlitFilledRectangle(destX, destY + sizeY, z, sizeX, lineWidth, colorR, colorG, colorB, alpha);

	BlitFilledRectangle(destX - lineWidth, destY - lineWidth, z, lineWidth, sizeY + lineWidth*2.0f, colorR, colorG, colorB, alpha);
	BlitFilledRectangle(destX + sizeX, destY - lineWidth, z, lineWidth, sizeY + lineWidth*2.0f, colorR, colorG, colorB, alpha);
}

void VID_EnableSolidsOnly()
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
	
}

void VID_DisableSolidsOnly()
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
}

void VID_DisableTextures()
{
	glDisable(GL_TEXTURE_2D);
}

void VID_EnableTextures()
{
	glEnable(GL_TEXTURE_2D);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}


void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	vertices[0] = startX;
	vertices[1] = startY;
	vertices[2] = posZ;

	vertices[3] = endX;
	vertices[4] = endY;
	vertices[5] = posZ;

	glColor4f(colorR, colorG, colorB, alpha);

	glDisable(GL_TEXTURE_2D);
	glVertexPointer(3, GL_FLOAT,  0, vertices);

	//glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINE_STRIP, 0, 2);
	//glDisableClientState(GL_VERTEX_ARRAY);

	glEnable(GL_TEXTURE_2D);

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
}

void BlitCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA)
{
	const int numCircleVerts = 48;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);
	
	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = sinf(angle)*radius;
		glverts[i*2+1] = cosf(angle)*radius;
	}
	
	glPushMatrix();
	glTranslatef(centerX, centerY, 0);
	
    //edge lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	glPopMatrix();
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

}

void BlitFilledCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA)
{
	const int numCircleVerts = 32;
    GLfloat glverts[numCircleVerts*2];
    glVertexPointer(2, GL_FLOAT, 0, glverts);
    glEnableClientState(GL_VERTEX_ARRAY);
	
	float angle = 0;
	for (int i = 0; i < numCircleVerts; i++, angle += DEGTORAD*360.0f/(numCircleVerts-1))
	{
		glverts[i*2]   = MTH_FastSin(angle)*radius;	//sinf
		glverts[i*2+1] = MTH_FastCos(angle)*radius;	//cosf
	}
	
	glPushMatrix();
	glTranslatef(centerX, centerY, 0);
	
	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_TRIANGLE_FAN, 0, numCircleVerts);
	
    //edge lines
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	glColor4f(colorR, colorG, colorB, colorA);
	glDrawArrays(GL_LINE_LOOP, 0, numCircleVerts);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	glPopMatrix();

	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
}

void GenerateLineStripFromCircularBuffer(CGLLineStrip *lineStrip, signed short *data, int length, int pos, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = length / sizeX;

	GLfloat samplePos = pos;
	int c = 0;

	for (GLfloat x = 0; x <= sizeX; x += 1.0)
	{
		lineStripData[c] = posX + x;
		c++;
		lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
		c++;
		lineStripData[c] = posZ;
		c++;

		samplePos += step;
		if (samplePos >= length)
			samplePos = 0;

		if ((c+3) >= dataLen)
			break;
	}
	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromCircularBuffer done");
#endif

	return;
}

void GenerateLineStripFromFft(CGLLineStrip *lineStrip, float *data, int start, int count, float multiplier, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	GLfloat endY = posY + sizeY;
	int c = 0;

	float maxVal = data[0];

	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = (endY) - (maxVal*multiplier) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;

			int prevSamplePos = (int)samplePos;
			samplePos += step;
			int nextSamplePos = (int)samplePos;

			if (prevSamplePos+1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int)samplePos];
					if (fabs(val) > fabs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFft done");
#endif

	return;

}


void GenerateLineStripFromFloat(CGLLineStrip *lineStrip, float *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFloat");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	int c = 0;

	float maxVal = data[0];

	//if (step <= 1.0)
	{
		for (GLfloat x = 0; x <= sizeX; x += 1.0)
		{
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posY + (maxVal) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;

			int prevSamplePos = (int)samplePos;
			samplePos += step;
			int nextSamplePos = (int)samplePos;

			if (prevSamplePos+1 < nextSamplePos)
			{
				maxVal = 0.0;
				for (int i = prevSamplePos; i <= nextSamplePos; i++)
				{
					float val = data[(int)samplePos];
					if (fabs(val) > fabs(maxVal))
					{
						maxVal = val;
					}
				}
			}
			else
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromFloat done");
#endif

	return;

}

#ifdef IS_TRACKER
void GenerateLineStripFromEnvelope(CGLLineStrip *lineStrip,
								   envelope_t *envelope,
								   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromEnvelope");
#endif

	int dataLen = (int)(envelope->numPoints * 3);
	lineStrip->Update(dataLen);

	GLfloat *lineStripData = lineStrip->lineStripData;

	//LOGG("GenerateLineStripFromEnvelope: envelope numPoints=%d", envelope->numPoints);

	// x = 0..324
	// y = 0..64
	int c = 0;
	for (int currentPoint = 0; currentPoint < envelope->numPoints; currentPoint++)
	{
		GLfloat x = envelope->points[currentPoint * 2];
		GLfloat y = envelope->points[currentPoint * 2 + 1];

		//LOGG("point=%d x=%f y=%f", currentPoint, x, y);
		lineStripData[c] = posX + (x / 324.0) * sizeX;
		c++;
		lineStripData[c] = posY + ((64.0 - y)/64.0) * sizeY;
		c++;
		lineStripData[c] = posZ;
		c++;

	}

	//SYS_FatalExit("exit");
	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStripFromEnvelope done");
#endif

	return;

	//SYS_Errorf("generatelinestrip");
}
#endif


void GenerateLineStrip(CGLLineStrip *lineStrip,
					   signed short *data,
					   int start, int count,
					   GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY)
{
#ifdef LOG_BLITS
	LOGG("GenerateLineStrip");
#endif

	int dataLen = (int)((sizeX+1) * 3.0);
	lineStrip->Update(dataLen);
	GLfloat *lineStripData = lineStrip->lineStripData;

	GLfloat step = count / sizeX;

	GLfloat samplePos = start;
	GLfloat counter = 0;
	int c = 0;
	GLfloat end = (GLfloat)(start+count);
	signed short maxVal = data[0];

	//if (step <= 1.0)
	{
		for (float x = 0; x <= sizeX; x += 1.0)
		{
			//lineStripData[c] = posY + (((GLfloat)data[(int)samplePos] + 32767.0) / 65536.0) * sizeY;
			lineStripData[c] = posX + x;
			c++;
			lineStripData[c] = posY + (((float)maxVal + 32767.0) / 65536.0) * sizeY;
			c++;
			lineStripData[c] = posZ;
			c++;

			//int prevSamplePos = (int)samplePos;
			samplePos += step;
			//int nextSamplePos = (int)samplePos;

			if (samplePos >= end)
				break;

			// debug -> simple:
			/* maxVal
			 if (prevSamplePos+1 < nextSamplePos)
			 {
			 maxVal = 0.0;
			 for (int i = prevSamplePos; i <= nextSamplePos; i++)
			 {
			 signed short val = data[(int)samplePos];
			 if (abs(val) > abs(maxVal))
			 {
			 maxVal = val;
			 }
			 }
			 }
			 else*/
			{
				maxVal = data[(int)samplePos];
			}

			counter += step;
			if (((int)counter) >= (int)count)
				break;
		}
	}

	lineStrip->length = (int)(c / 3);

#ifdef LOG_BLITS
	LOGG("GenerateLineStrip done");
#endif


	return;
}




void BlitLineStrip(CGLLineStrip *glLineStrip, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha)
{
	glColor4f(colorR, colorG, colorB, alpha);

	glDisable(GL_TEXTURE_2D);
	glVertexPointer(3, GL_FLOAT,  0, glLineStrip->lineStripData);

	//glEnableClientState(GL_VERTEX_ARRAY);
	glDrawArrays(GL_LINE_STRIP, 0, glLineStrip->length);
	//glDisableClientState(GL_VERTEX_ARRAY);

	glEnable(GL_TEXTURE_2D);

	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
}

#define CENTER_MARKER_SIZE 12.0

void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha)
{
	BlitLine(posX, posY-CENTER_MARKER_SIZE,
			 posX, posY+CENTER_MARKER_SIZE, posZ,
			 r, g, b, alpha);

	BlitLine(posX-CENTER_MARKER_SIZE, posY,
			 posX+CENTER_MARKER_SIZE, posY, posZ,
			 r, g, b, alpha);
}

void BlitPlus(GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY, GLfloat r, GLfloat g, GLfloat b, GLfloat alpha)
{
	BlitLine(posX, posY-sizeY/2.0f,
			 posX, posY+sizeY/2.0f, posZ,
			 r, g, b, alpha);

	BlitLine(posX-sizeX/2.0f, posY,
			 posX+sizeX/2.0f, posY, posZ,
			 r, g, b, alpha);
}

void PushMatrix2D()
{
	glPushMatrix();
}

void PopMatrix2D()
{
	glPopMatrix();
}

void Translate2D(GLfloat posX, GLfloat posY, GLfloat posZ)
{
	glTranslatef(posX, posY, posZ);
}

void Rotate2D(GLfloat angle)
{
	glRotatef( angle , 0, 0, 1 );	//* RADTODEG
}

void Scale2D(GLfloat scaleX, GLfloat scaleY, GLfloat scaleZ)
{
	glScalef(scaleX, scaleY, scaleZ);
}

void BlitRotatedImage(CSlrImage *image, GLfloat pX, GLfloat pY, GLfloat pZ, GLfloat rotationAngle, GLfloat alpha)
{
	GLfloat rPosX = pX;
	GLfloat rPosY = pY;
	GLfloat rPosZ = pZ;
	GLfloat rSizeX = image->width;
	GLfloat rSizeY = image->height;
	GLfloat rSizeX2 = rSizeX/2.0f;
	GLfloat rSizeY2 = rSizeY/2.0f;
	rPosX -= rSizeX2;
	rPosY -= rSizeY2;

	//LOGD("BLIT: %3.2f %3.2f %3.2f | %3.2f %3.2f", rPosX, rPosY, rPosZ, rSizeX, rSizeY);

	PushMatrix2D();

	Translate2D(rPosX + rSizeX2, rPosY + rSizeY2, rPosZ);
	Rotate2D(rotationAngle);

	BlitAlpha(image, -rSizeX2, -rSizeY2, 0, rSizeX, rSizeY, alpha);
	PopMatrix2D();
}

void BlitTriangleAlpha(CSlrImage *what, GLfloat z, GLfloat alpha,
					   GLfloat vert1x, GLfloat vert1y, GLfloat tex1x, GLfloat tex1y,
					   GLfloat vert2x, GLfloat vert2y, GLfloat tex2x, GLfloat tex2y,
					   GLfloat vert3x, GLfloat vert3y, GLfloat tex3x, GLfloat tex3y)
{
#ifdef LOG_BLITS
	LOGG("BlitTriangleAlpha: %s", what->name);
#endif
	
	GLfloat tx = (what->defaultTexEndX - what->defaultTexStartX);
	GLfloat ty = (what->defaultTexEndY - what->defaultTexStartY);
	
	GLfloat t1x = tx * tex1x + what->defaultTexStartX;
	GLfloat t1y = ty * (1.0f-tex1y) + what->defaultTexStartY;
	GLfloat t2x = tx * tex2x + what->defaultTexStartX;
	GLfloat t2y = ty * (1.0f-tex2y) + what->defaultTexStartY;
	GLfloat t3x = tx * tex3x + what->defaultTexStartX;
	GLfloat t3y = ty * (1.0f-tex3y) + what->defaultTexStartY;
	
	texCoords[0] = t1x;
	texCoords[1] = t1y;
	texCoords[2] = t2x;
	texCoords[3] = t2y;
	texCoords[4] = t3x;
	texCoords[5] = t3y;
	
	vertices[0]  =  vert1x;
	vertices[1]  =  vert1y;
	vertices[2]  =	z;
	
	vertices[3]  =  vert2x;
	vertices[4]  =  vert2y;
	vertices[5]  =	z;
	
	vertices[6]  =  vert3x;
	vertices[7]  =  vert3y;
	vertices[8]  =	z;
	
//	LOGD(" >>>> BlitTriangleAlpha <<<<");
//	for (u32 i = 0; i < 6; i++)
//		LOGD("texCoords[%d]=%3.2f", i, texCoords[i]);
//	
//	for (u32 i = 0; i < 9; i++)
//		LOGD("vertices[%d]=%3.2f", i, vertices[i]);
//
//	float *norms = (float *)normals;
//	for (u32 i = 0; i < 9; i++)
//		LOGD("normals[%d]=%3.2f", i, norms[i]);

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
#ifdef LOG_BLITS
	LOGG("BlitTriangleAlpha done: %s", what->name);
#endif
	
}

void BlitPolygonAlpha(CSlrImage *what, GLfloat alpha, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#ifdef LOG_BLITS
	LOGG("BlitPolygonAlpha: %s", what->name);
#endif
	
//	LOGD("========= BlitPolygonAlpha ========");
//	for (u32 i = 0; i < 6; i++)
//		LOGD("texCoords[%d]=%3.2f", i, texs[i]);
//	
//	for (u32 i = 0; i < 9; i++)
//		LOGD("vertices[%d]=%3.2f", i, verts[i]);
//	
//	for (u32 i = 0; i < 9; i++)
//		LOGD("normals[%d]=%3.2f", i, norms[i]);

    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glNormalPointer(GL_FLOAT, 0, norms);
    glTexCoordPointer(2, GL_FLOAT, 0, texs);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0f, 1.0f, 1.0f, alpha);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numVertices);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

#ifdef LOG_BLITS
	LOGG("BlitPolygonAlpha done: %s", what->name);
#endif

}

void BlitPolygonMixColor(CSlrImage *what, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA, GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices)
{
#ifdef LOG_BLITS
	LOGG("BlitPolygonMixColor: %s", what->name);
#endif
	
	//	LOGD("========= BlitPolygonAlpha ========");
	//	for (u32 i = 0; i < 6; i++)
	//		LOGD("texCoords[%d]=%3.2f", i, texs[i]);
	//
	//	for (u32 i = 0; i < 9; i++)
	//		LOGD("vertices[%d]=%3.2f", i, verts[i]);
	//
	//	for (u32 i = 0; i < 9; i++)
	//		LOGD("normals[%d]=%3.2f", i, norms[i]);
	
    glBindTexture(GL_TEXTURE_2D, what->texture[0]);
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glNormalPointer(GL_FLOAT, 0, norms);
    glTexCoordPointer(2, GL_FLOAT, 0, texs);
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(mixColorR, mixColorG, mixColorB, mixColorA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, numVertices);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);

#ifdef LOG_BLITS
	LOGG("BlitPolygonMixColor done: %s", what->name);
#endif
	
}

// lorna
// anrol

/*
STENCIL     -> http://answers.oreilly.com/topic/1655-a-super-simple-sample-app-for-supersampling-on-ios/
 
1/ The stencil buffer has not been created correctly. It should be initialized like this:

glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthStencilRenderbuffer);
glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 
						 GL_DEPTH24_STENCIL8_OES, 
						 backingWidth, 
						 backingHeight);
It's the principal reason why my rendering was not affected by my mask.

2/ To be able to make use of a texture as a mask, I replaced the black color with an alpha channel and enable blending in my rendering.

My final rendering code looks like this :

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, vertices);
glTexCoordPointer(2, GL_FLOAT, 0, texcoords);

glClearStencil(0); 
glClearColor (0.0,0.0,0.0,1);
glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT); 


// mask rendering
glColorMask( GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE );
glEnable(GL_STENCIL_TEST);
glEnable(GL_ALPHA_TEST);
glBlendFunc( GL_ONE, GL_ONE );
glAlphaFunc( GL_NOTEQUAL, 0.0 );
glStencilFunc(GL_ALWAYS, 1, 1);
glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);

glBindTexture(GL_TEXTURE_2D, _mask);
glDrawArrays(GL_TRIANGLE_STRIP, 4, 4);  

// scene rendering
glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); 
glStencilFunc(GL_EQUAL, 1, 1);
glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);

glDisable(GL_STENCIL_TEST);
glDisable(GL_ALPHA_TEST);
glBindTexture(GL_TEXTURE_2D, _texture);
glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);  

*/

/*
stencil android:
http://opengles-book-samples.googlecode.com/svn-history/r47/trunk/Android/Ch11_Stencil_Test/src/com/openglesbook/stenciltest/StencilTestRenderer.java

*/
