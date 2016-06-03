//
//  GLViewController.h
//  LINUX
//
//  Created by Marcin Skoczylas on 09-11-22.
//  Copyright RABIDUS 2009. All rights reserved.
//

#ifndef _GLVIEWCONTROLLER_
#define _GLVIEWCONTROLLER_

#include "SYS_Defs.h"
#include "CSlrImage.h"
#include "CSlrImageBase.h"

extern byte gPlatformType;

extern GLfloat SCREEN_WIDTH;
extern GLfloat SCREEN_HEIGHT;
extern GLfloat SCREEN_SCALE;
extern GLfloat SCREEN_ASPECT_RATIO;

extern float CURRENT_FPS;

extern u64 gCurrentFrameTime;

GLfloat VID_GetScreenWidth();
GLfloat VID_GetScreenHeight();

// for placing buttons in gui inside view
#define SCREEN_EDGE_HEIGHT 2.0
#define SCREEN_EDGE_WIDTH 2.0

#define SCREENSHOT_FILTER_COLOR     1
#define SCREENSHOT_FILTER_SEPIA     2
#define SCREENSHOT_FILTER_GRAYSCALE 3

long SYS_RandomSeed();
void VID_ResetLogicClock();
long SYS_GetCurrentTimeInMillis();

void VID_PrepareScreenshot(byte filterType);
void VID_SaveScreenshot();
void VID_ShowScreenshot();
void VID_HideScreenshot();

void VID_ShowActionSheet();
void VID_ApplicationPreloadingFinished();


//#define GLfloat float
class SysTextFieldEditFinishedCallback
{
public:
	virtual void SysTextFieldEditFinished(UTFString *str);
};

void GUI_SetSysTextFieldEditFinishedCallback(SysTextFieldEditFinishedCallback *callback);
void GUI_ShowSysTextField(GLfloat posX, GLfloat posY, GLfloat sizeX, GLfloat sizeY, UTFString *text);
void GUI_HideSysTextField();

void GUI_ShowVirtualKeyboard();
void GUI_HideVirtualKeyboard();

void GUI_ShowAcknowledgements();
void VID_SetViewKeyboardOffset(float offsetY);

// ads
void VID_RequestBannerAd();
void VID_ShowBannerAd(byte bannerPosition);
void VID_HideBannerAd();
void VID_LoadFullScreenAd();
bool VID_IsFullScreenAdAvailable();
void VID_PresentFullScreenAd();
void VID_CloseFullScreenAd();

typedef struct {
	GLfloat	x;
	GLfloat y;
	GLfloat z;
} Vertex3D;

typedef Vertex3D Vector3D;

class CSlrImage;

extern float VIEW_WIDTH;
extern float VIEW_HEIGHT;

void SYS_LockRenderMutex();
void SYS_UnlockRenderMutex();

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

void VID_InitServerMode();
void VID_InitGL();
void VID_DrawView();
void VID_DoLogic();

void VID_TouchesBegan(int xPos, int yPos, bool alt);
void VID_TouchesMoved(int xPos, int yPos, bool alt);
void VID_TouchesEnded(int xPos, int yPos, bool alt);

void VID_TouchesScrollWheel(float deltaX, float deltaY);

void VID_RightClickBegan(int xPos, int yPos);
void VID_RightClickMoved(int xPos, int yPos);
void VID_RightClickEnded(int xPos, int yPos);

void VID_NotTouchedMoved(int xPos, int yPos);

extern bool gScaleDownImages;

static const float fontQuadZero = 0.006f;
static const float fontQuadOne = 0.994f;

void VID_SetOrthoScreen();
void VID_SetOrtho(GLfloat xMin, GLfloat xMax, GLfloat yMin, GLfloat yMax,
				  GLfloat zMin, GLfloat zMax);
void VID_SetOrthoSwitchBack();

void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY);
void BlitTexture(GLuint tex, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				 GLfloat texStartX, GLfloat texStartY,
				 GLfloat texEndX, GLfloat texEndY,
				 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void Blit(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z);
void BlitAlpha(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha);
void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat alpha, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB);
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
void BlitMixColor(CSlrImage *what, GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY, GLfloat alpha, GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB);
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

void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
void BlitGradientRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
                                                   GLfloat colorR1, GLfloat colorG1, GLfloat colorB1, GLfloat colorA1,
                                                   GLfloat colorR2, GLfloat colorG2, GLfloat colorB2, GLfloat colorA2,
                                                   GLfloat colorR3, GLfloat colorG3, GLfloat colorB3, GLfloat colorA3,
                                                   GLfloat colorR4, GLfloat colorG4, GLfloat colorB4, GLfloat colorA4);

void VID_EnableSolidsOnly();
void VID_DisableSolidsOnly();

void VID_DisableTextures();
void VID_EnableTextures();

void BlitPolygonMixColor(CSlrImage *what,
		GLfloat mixColorR, GLfloat mixColorG, GLfloat mixColorB, GLfloat mixColorA,
		GLfloat *verts, GLfloat *texs, GLfloat *norms, GLuint numVertices);

void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);


void BlitFilledRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
						 GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
				   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);
void BlitRectangle(GLfloat destX, GLfloat destY, GLfloat z, GLfloat sizeX, GLfloat sizeY,
                                   GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha, GLfloat lineWidth);



void BlitLine(GLfloat startX, GLfloat startY, GLfloat endX, GLfloat endY, GLfloat posZ,
			  GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat alpha);

void BlitFilledCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA);
void BlitCircle(GLfloat centerX, GLfloat centerY, GLfloat radius, GLfloat colorR, GLfloat colorG, GLfloat colorB, GLfloat colorA);

void GenerateLineStrip(CGLLineStrip *lineStrip, signed short *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void GenerateLineStripFromFft(CGLLineStrip *lineStrip, float *data, int start, int count, float multiplier, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
void GenerateLineStripFromFloat(CGLLineStrip *lineStrip, float *data, int start, int count, GLfloat posX, GLfloat posY, GLfloat posZ, GLfloat sizeX, GLfloat sizeY);
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

//void SetClipping(GLint x, GLint y, GLsizei sizeX, GLsizei sizeY);
void SetClipping(GLfloat x, GLfloat y, GLfloat sizeX, GLfloat sizeY);
void ResetClipping();

void GUI_SetPressConsumed(bool consumed);

float VID_GetFingerRayLength();

void VID_SetFPS(float fps);

#endif
