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
#include "CSlrFile.h"
#include "CSlrImageTexture.h"

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#define IMAGE_LOAD_ERROR_NONE		0x00
#define IMAGE_LOAD_ERROR_NOT_LOADED	0x01
#define IMAGE_LOAD_ERROR_NOT_FOUND	0x02
#define IMAGE_LOAD_ERROR_NOT_IMAGE	0x03

class CSlrImage : public CSlrImageTexture
{
public:	
	// load from resources
	CSlrImage(CSlrFile *imgFile, bool linearScaling);
	CSlrImage(char *fileName, bool linearScaling);
	CSlrImage(char *fileName, bool linearScaling, bool fromResources);
	CSlrImage(NSString *fileName, bool linearScaling);
	CSlrImage(NSString *fileName, NSString *fileExt, bool linearScaling);
	
	// delayed load
	CSlrImage(bool delayedLoad, bool linearScaling);
	
	// init from img atlas
	CSlrImage(CSlrImage *imgAtlas, GLfloat startX, GLfloat startY, GLfloat width, GLfloat height, GLfloat downScale, char *name);
	
	virtual ~CSlrImage();
	
	byte fileLoadError;
	
	void InitImageLoad(bool linearScaling);
	
	//void LoadImage(dword fileHandle);
	void PreloadImage(char *fileName, bool fromResources);
	void DelayedLoadImage(char *fileName, bool fromResources);
	void DelayedLoadImage(NSString *fileName);
	void PreloadImage(NSString *fileName, NSString *fileExt, bool crashIfFailed);
	void LoadImage(NSString *fileName, NSString *fileExt, bool crashIfFailed);
	void LoadImage(CImageData *origImageData);
	void LoadImage(CImageData *origImageData, byte resourcePriority);
	void LoadImage(CImageData *origImageData, byte resourcePriority, bool flipImageVertically);
	void RefreshImageParameters(CImageData *origImageData, byte resourcePriority, bool flipImageVertically);
	void PreloadImage(CSlrFile *imgFile);
	void LoadImage(CSlrFile *imgFile);
	
	//void ConvertDataBufferColor();
	
	virtual void BindImage();
	virtual void ReBindImage();
	virtual void FreeLoadImage();
	virtual void Deallocate();

	// set image data directly it is a hack, be carefull
	void SetLoadImageData(CImageData *imageData);
	void ReplaceImageData(CImageData *imageData);
	
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
	
	NSImage* Resize(NSImage *inImage, CGRect thumbRect);
	
	void DrawLine(float x1, float y1, float x2, float y2);
	
	CImageData *GetImageData(float *imageScale, u32 *width, u32 *height);
	
//	virtual void GetPixel(u16 x, u16 y, byte *r, byte *g, byte *b);
	
public:
	void *loadImageData;
	CGContextRef loadContext;
	CGColorSpaceRef loadColorSpace;	
	GLuint loadImgWidth;
	GLuint loadImgHeight;
	
	float gfxScale;
	
	float origRasterWidth;
	float origRasterHeight;

    NSData *loadTexData;
	NSImage *loadImage;
	
	CImageData *imageData;
	
	///////// resource base
	// should preload resource and set resource size
	virtual bool ResourcePreload(char *fileName, bool fromResources);

	// get size of resource in bytes
	virtual u32 ResourceGetLoadingSize();
	virtual u32 ResourceGetIdleSize();
};


#endif // __VID_CSLRIMAGE_H__
