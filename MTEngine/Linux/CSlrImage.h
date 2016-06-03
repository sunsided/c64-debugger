/*
 *  CSlrImage.h
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-23.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

#ifndef __VID_CSLRIMAGE_H__
#define __VID_CSLRIMAGE_H__

#include "SYS_Defs.h"
#include "CImageData.h"
//#include "OpenGLCommon.h"
//#include "XF_Files.h"
//#include "VID_CAppView.h"
#include "CSlrFile.h"
#include "CSlrImageTexture.h"

class CSlrImage : public CSlrImageTexture
{
public:
	// load from resources
	CSlrImage(CSlrFile *imgFile, bool linearScaling);
	CSlrImage(char *fileName, bool linearScaling);
	CSlrImage(char *fileName, bool linearScaling, bool fromResources);
	//CSlrImage(NSString *fileName, bool linearScaling);
	//CSlrImage(NSString *fileName, NSString *fileExt, bool linearScaling);

	// delayed load
	CSlrImage(bool delayedLoad, bool linearScaling);

	// init from img atlas
	CSlrImage(CSlrImage *imgAtlas, GLfloat startX, GLfloat startY, GLfloat width, GLfloat height, GLfloat downScale, char *name);

	virtual ~CSlrImage();

	void InitImageLoad(bool linearScaling);

	void DelayedLoadImage(UTFString *fileName, bool fromResources);
	void PreloadImage(char *fileName, bool fromResources);
	void LoadImage(UTFString *fileName, UTFString *fileExt);
	void LoadImage(CImageData *imageData);
	void LoadImage(CImageData *imageData, byte resourcePriority);
	void LoadImage(CImageData *imageData, byte resourcePriority, bool flipImageVertically);
	void PreloadImage(CSlrFile *imgFile);
	void LoadImage(CSlrFile *imgFile);

	void SetLoadImageData(CImageData *imageData);
    void ReplaceImageData(CImageData *imageData);

	byte fileLoadError;

	void BindImage();
	void FreeLoadImage();

	char *name;

	bool linearScaling;

	bool isFromAtlas;
	CSlrImage *imgAtlas;

	GLuint      texture[1];
	//byte keyR, keyG, keyB;

	//unsigned char *dataBuffer;
	//unsigned char *alphaBuffer;

	//CAppView *appView;
	//CXFiles *xFiles;

	GLfloat rasterHeight;
	GLfloat rasterWidth;

	GLfloat defaultTexStartX;
	GLfloat defaultTexEndX;
	GLfloat defaultTexStartY;
	GLfloat defaultTexEndY;

	GLfloat downScale;

	void DrawLine(float x1, float y1, float x2, float y2);

	CImageData *GetImageData(float *imageScale, u32 *width, u32 *height);

public:
	CImageData *loadImageData;
//	void *loadImageData;
//	CGContextRef loadContext;
//	CGColorSpaceRef loadColorSpace;
	GLuint loadImgWidth;
	GLuint loadImgHeight;

	float gfxScale;

	float origRasterWidth;
	float origRasterHeight;

 //   NSData *loadTexData;
//	UIImage *loadImage;

	virtual void Deallocate();
	virtual bool ResourcePreload(char *fileName, bool fromResources);
	virtual u32 ResourceGetLoadingSize();
	virtual u32 ResourceGetIdleSize();


};


#endif // __VID_CSLRIMAGE_H__
