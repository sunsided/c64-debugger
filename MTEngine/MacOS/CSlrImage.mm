/*
 *  CSlrImage.cpp
 *  MobiTracker
 *
 *  Created by Marcin Skoczylas on 09-11-23.
 *  Copyright 2009 Marcin Skoczylas. All rights reserved.
 *
 */

//http://stackoverflow.com/questions/1606726/help-loading-textures-in-pvrtc-format-for-the-iphone

// different formats (RGBA4444) -> http://www.cocos2d-iphone.org/archives/61

// loading 4444 texture: 
// http://stackoverflow.com/questions/2255885/when-i-load-a-texture-as-rgba4444-in-opengl-how-much-memory-is-consumed-in-the-d

//http://www.iphonedevsdk.com/forum/iphone-sdk-development/5139-opengl-rendering-issue.html

// check: http://stackoverflow.com/questions/2008842/creating-and-loading-pngs-in-rgba4444-rgba5551-for-opengl
// and: http://www.google.com/search?q=iphone%20rgba4444&ie=utf-8&oe=utf-8

// opengl image filters, sepia: http://developer.apple.com/library/ios/#samplecode/GLImageProcessing/Introduction/Intro.html

//http://www.iphonedevsdk.com/forum/iphone-sdk-game-development/7479-loading-texture2d-parallel-thread.html

#define MT_DBGLOG_NSSTRING
#include "CSlrImage.h"
#include "SYS_Main.h"
#include "SYS_Funct.h"
#include "GLView.h"
#include "VID_GLViewController.h"
#include "SYS_CFileSystem.h"
#include "SYS_DocsVsRes.h"
#include "GFX_Types.h"
#include "RES_ResourceManager.h"
#include "VID_ImageBinding.h"
#include "CSlrFileZlib.h"
#include "zlib.h"
#include "stb_image.h"

#define CHECK_IF_NOT_ACTIVE_AND_LOAD

CGSize PSPNGSizeFromMetaData( NSString* anFileName );

/*
 @implementation NSString(ObjCPlusPlus)
 -(std::string)stdString
 {
 return std::string([self cString]);
 }
 -(NSString *)initWithStdString:(std::string)str
 {
 return [self initWithCString:str.c_str()];
 }
 +(NSString *)stringWithStdString:(std::string)str
 {
 return [NSString stringWithCString:str.c_str()];
 }
 @end
 */

CSlrImage::CSlrImage(CSlrFile *imgFile, bool linearScaling)
: CSlrImageTexture()
{
	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;
	
	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;
	
	this->InitImageLoad(linearScaling);
	this->LoadImage(imgFile);
	
	this->resourceType = RESOURCE_TYPE_IMAGE;
	this->resourcePriority = RESOURCE_PRIORITY_STATIC;
	VID_PostImageBinding(this, NULL);

}

CSlrImage::CSlrImage(char *fileName, bool linearScaling, bool fromResources)
: CSlrImageTexture()
{
	ResourceSetPath(fileName, fromResources);
	
	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;

	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;

	if (fromResources == true)
	{
        #ifndef USE_DOCS_INSTEAD_OF_RESOURCES
            char resNameNoPath[2048];
            int i = strlen(fileName)-1;
            for (  ; i >= 0; i--)
            {
                if (fileName[i] == '/')
                    break;
            }
            
            int j = 0;
            while(true)
            {
                resNameNoPath[j] = fileName[i];
                if (fileName[i] == '\0')
                    break;
                j++;
                i++;
            }

            //    char *buffer = (char*)fileName.c_str();
            //    NSString* nsFileName = [[NSString alloc] initWithBytes:fileName length:sizeof(fileName) encoding:NSASCIIStringEncoding];
            //    NSString* nsFileName = [NSString stringWithCString:fileName.c_str()];
            NSString* nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
        #else

            NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
            
        #endif
            
            //[[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
            
            this->InitImageLoad(linearScaling);
            this->LoadImage(nsFileName, @"png", true);
            this->BindImage();
            this->FreeLoadImage();
    }
	else
	{
		loadImageData = NULL;
		NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
		this->InitImageLoad(linearScaling);
		this->LoadImage(nsFileName, @"png", true);
		this->BindImage();
		this->FreeLoadImage();
		
	}
}

CSlrImage::CSlrImage(char *fileName, bool linearScaling)
: CSlrImageTexture()
{
	ResourceSetPath(fileName, true);

	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;

	loadImageData = NULL;

	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;

#ifndef USE_DOCS_INSTEAD_OF_RESOURCES
	char resNameNoPath[2048];
	int i = strlen(fileName)-1;
	for (  ; i >= 0; i--)
	{
		if (fileName[i] == '/')
			break;
	}
	
	int j = 0;
	while(true)
	{
		resNameNoPath[j] = fileName[i];
		if (fileName[i] == '\0')
			break;
		j++;
		i++;
	}

	//	char *buffer = (char*)fileName.c_str();
	//	NSString* nsFileName = [[NSString alloc] initWithBytes:fileName length:sizeof(fileName) encoding:NSASCIIStringEncoding];	
	//	NSString* nsFileName = [NSString stringWithCString:fileName.c_str()];
	NSString* nsFileName = [NSString stringWithCString:resNameNoPath encoding:NSASCIIStringEncoding];
#else

	NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
	
#endif
	
	//[[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	
	this->InitImageLoad(linearScaling);
	this->LoadImage(nsFileName, @"png", true);
	this->BindImage();
	this->FreeLoadImage();
	
	//	delete nsFileName;
}

CSlrImage::CSlrImage(bool delayedLoad, bool linearScaling)
: CSlrImageTexture()
{
	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;

	loadImageData = NULL;

	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;
	this->InitImageLoad(linearScaling);
}

CSlrImage::CSlrImage(NSString *fileName, bool linearScaling)
: CSlrImageTexture()
{
	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;

	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;
	
	LOGR("loading image");
	LOGR(fileName);
	
	loadImageData = NULL;
	this->InitImageLoad(linearScaling);
	this->LoadImage(fileName, @"png", true);
	this->BindImage();
	this->FreeLoadImage();
	//dataBuffer = NULL;
	//alphaBuffer = NULL;
	//keyR = keyG = keyB = 0x00;
	
	LOGR("done");
}


CSlrImage::CSlrImage(NSString *fileName, NSString *fileExt, bool linearScaling)
: CSlrImageTexture()
{
	this->imageType = IMAGE_TYPE_BITMAP;
	
	loadColorSpace = NULL;
	loadContext = NULL;
	loadImageData = NULL;
	loadImage = NULL;
	loadTexData = NULL;
	imageData = NULL;

	fileLoadError = IMAGE_LOAD_ERROR_NOT_LOADED;

	loadImageData = NULL;
	this->InitImageLoad(linearScaling);
	this->LoadImage(fileName, fileExt, true);
	this->BindImage();
	this->FreeLoadImage();
	//dataBuffer = NULL;
	//alphaBuffer = NULL;
	//keyR = keyG = keyB = 0x00;
}

CSlrImage::~CSlrImage()
{
	if (this->isFromAtlas == false && this->isBound == true)
		glDeleteTextures(1, &texture[0]);

	FreeLoadImage();
}

void CSlrImage::InitImageLoad(bool linearScaling)
{
	this->isFromAtlas = false;
	this->isBound = false;
	this->imgAtlas = NULL;	
	
	if (gForceLinearScale == false)
	{
		this->linearScaling = linearScaling;
	}
	else
	{
		this->linearScaling = true;
	}
	
	loadImageData = NULL;
    loadTexData = NULL;
	loadImage = NULL;
	
}

void CSlrImage::PreloadImage(char *fileName, bool fromResources)
{
	LOGR("CSlrImage::PreloadImage: '%s' fromResources=%s", fileName, (fromResources ? "true" : "false"));
	
	ResourceSetPath(fileName, fromResources);
	
	loadImageData = NULL;
	
	if (fromResources)
	{
		CSlrFile *file = RES_GetFileFromDeploy(fileName, DEPLOY_FILE_TYPE_GFX);
		if (file != NULL)
		{
			this->PreloadImage(file);
			delete file;
			return;
		}
	}
	
#ifndef USE_DOCS_INSTEAD_OF_RESOURCES
	char fileNamePath[1024];
	if (fromResources == true)
	{
		int i = strlen(fileName)-1;
		for (  ; i >= 0; i--)
		{
			if (fileName[i] == '/')
				break;
		}
		
		int j = 0;
		while(true)
		{
			fileNamePath[j] = fileName[i];
			if (fileName[i] == '\0')
				break;
			j++;
			i++;
		}
	}
	else
	{
		sprintf(fileNamePath, "%s", fileName);
	}
	
	NSString* nsFileName = [NSString stringWithCString:fileNamePath encoding:NSASCIIStringEncoding];
#else
	
	NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];
	
#endif
	
	this->PreloadImage(nsFileName, @"png", true);
}

void CSlrImage::DelayedLoadImage(char *fileName, bool fromResources)
{
	LOGR("CSlrImage::DelayedLoadImage: '%s' fromResources=%s", fileName, (fromResources ? "true" : "false"));

	ResourceSetPath(fileName, fromResources);

	loadImageData = NULL;

	if (fromResources)
	{
		CSlrFile *file = RES_GetFileFromDeploy(fileName, DEPLOY_FILE_TYPE_GFX);
		if (file != NULL)
		{
			this->LoadImage(file);
			delete file;
			return;
		}
	}
	
	LOGR("CSlrImage::DelayedLoadImage: fileName=%s", fileName);
	
#ifndef USE_DOCS_INSTEAD_OF_RESOURCES
	char fileNamePath[1024];
	if (fromResources == true)
	{
		// check is there path '/'
		int i = strlen(fileName);
		bool found = false;
		for (int z = 0; z < i; z++)
		{
			if (fileName[z] == '/')
			{
				found = true;
			}
		}
		
		if (found)
		{
			i = strlen(fileName)-1;
			for (  ; i >= 0; i--)
			{
				if (fileName[i] == '/')
					break;
			}
			
			int j = 0;
			while(true)
			{
				fileNamePath[j] = fileName[i];
				if (fileName[i] == '\0')
					break;
				j++;
				i++;
			}
		}
		else
		{
			// no '/' in path
			sprintf(fileNamePath, "%s", fileName);
		}
		
	}
	else
	{
		sprintf(fileNamePath, "%s", fileName);
	}
	
	NSString* nsFileName = [NSString stringWithCString:fileNamePath encoding:NSASCIIStringEncoding];
	
	LOGR("CSlrImage::DelayedLoadImage: fileNamePath=%s", fileNamePath);

#else
	
	NSString* nsFileName = [NSString stringWithCString:fileName encoding:NSASCIIStringEncoding];

	LOGD(nsFileName);
	
#endif

	this->LoadImage(nsFileName, @"png", true);

}

void CSlrImage::DelayedLoadImage(NSString *fileName)
{
	this->LoadImage(fileName, @"png", true);
}

void CSlrImage::PreloadImage(NSString *fileName, NSString *fileExt, bool crashIfFailed)
{
	LOGR("PreloadImage:");
	LOGR(fileName);
	
	NSString *fileNameNoSlash = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
	LOGR("PreloadImage, reading:");
	LOGR(fileNameNoSlash);
	
	// scale is 2 because width /2
	gfxScale = 2.0f;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:fileNameNoSlash ofType:fileExt inDirectory:@""];	//@"png"
	
	NSUInteger				_width, _height;
	NSURL					*url = nil;
	CGImageSourceRef		src;
	CGImageRef				image;
	CGContextRef			context = nil;
	CGColorSpaceRef			colorSpace;
	
	if (path == nil)
	{
		LOGR("checking in Documents:");
		//		NSString *path = [[[gOSPathToDocuments stringByAppendingPathComponent:fileName]
		//						  stringByAppendingString:@"."] stringByAppendingPathExtension:fileExt];
		path = [[gOSPathToDocuments stringByAppendingPathComponent:fileName]
				stringByAppendingPathExtension:fileExt];
		
		LOGR("path=");
		LOGR(path);
		//		url = [NSURL fileURLWithPath: path];
		
		//		if (loadTexData == nil)
		//		{
		//			NSString *path = [gOSPathToDocuments stringByAppendingPathComponent:fileName];
		//			this->loadTexData = [[NSData alloc] initWithContentsOfFile:path];
		//			if (loadTexData == nil)
		//			{
		//				LOGError("loadImage == nil:");
		//				LOGError(path);
		//
		//				if (crashIfFailed)
		//					SYS_FatalExit("image not found");
		//
		//				fileLoadError = IMAGE_LOAD_ERROR_NOT_FOUND;
		//				return;
		//			}
		//		}
	}
	
	CGSize size = PSPNGSizeFromMetaData(path);
	
	this->loadImgWidth = size.width;
	this->loadImgHeight = size.height;
	this->rasterWidth = NextPow2(loadImgWidth);
	this->rasterHeight = NextPow2(loadImgHeight);
	this->origRasterWidth = rasterWidth;
	this->origRasterHeight = rasterHeight;
	
	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;
	
	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;
	
	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);

	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;
	
	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;
	
	LOGD("CSlrImage::PreloadImage: rasterWidth=%d rasterHeight=%d resourceLoadingSize=%d resourceIdleSize=%d", rasterWidth, rasterHeight, resourceLoadingSize, resourceIdleSize);
}

void CSlrImage::LoadImage(NSString *fileName, NSString *fileExt, bool crashIfFailed)
{
	LOGR("LoadImage:");
	LOGR(fileName);
	
	NSArray *components = [fileName pathComponents];
	NSString *fileNameNoSlash = [components lastObject];
	
//	NSString *fileNameNoSlash = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
//	LOGR("LoadImage, reading:");

	LOGR(fileNameNoSlash);
	LOGR(fileExt);
	
	// scale is 2 because width /2
	gfxScale = 2.0f;

	NSString *path = [[NSBundle mainBundle] pathForResource:fileNameNoSlash ofType:fileExt inDirectory:@""];	//@"png"
	
	NSUInteger				_width, _height;
	NSURL					*url = nil;
	CGImageSourceRef		src;
	CGImageRef				image;
	CGContextRef			context = nil;
	CGColorSpaceRef			colorSpace;
	
	if (path == nil)
	{
#if !defined(USE_DOCS_INSTEAD_OF_RESOURCES)
		if (crashIfFailed)
		{
			LOGError("File not found in resources... will crash here");
		}
#endif
		
		LOGR("checking in Documents:");
		//		NSString *path = [[[gOSPathToDocuments stringByAppendingPathComponent:fileName]
		//						  stringByAppendingString:@"."] stringByAppendingPathExtension:fileExt];
		path = [[gOSPathToDocuments stringByAppendingPathComponent:fileName]
						  stringByAppendingPathExtension:fileExt];
		
		LOGR("path=");
		LOGR(path);
//		url = [NSURL fileURLWithPath: path];
		
//		if (loadTexData == nil)
//		{
//			NSString *path = [gOSPathToDocuments stringByAppendingPathComponent:fileName];
//			this->loadTexData = [[NSData alloc] initWithContentsOfFile:path];
//			if (loadTexData == nil)
//			{
//				LOGError("loadImage == nil:");
//				LOGError(path);
//				
//				if (crashIfFailed)
//					SYS_FatalExit("image not found");
//				
//				fileLoadError = IMAGE_LOAD_ERROR_NOT_FOUND;
//				return;
//			}
//		}
	}
	
	url = [NSURL fileURLWithPath: path];
	src = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	
	if (!src)
	{
		LOGError("image not found");
		LOGError(path);
		SYS_FatalExit("Image not found");
	}

	image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
	CFRelease(src);
	
	_width = CGImageGetWidth(image);
	_height = CGImageGetHeight(image);
	this->loadImgWidth = _width;
	this->loadImgHeight = _height;
	this->rasterWidth = NextPow2(loadImgWidth);
	this->rasterHeight = NextPow2(loadImgHeight);
	this->origRasterWidth = rasterWidth;
	this->origRasterHeight = rasterHeight;
	colorSpace = CGColorSpaceCreateDeviceRGB();
	
	u32 numBytes = rasterWidth * rasterHeight * 4 * 2;

	this->loadImageData = (GLubyte*) calloc(rasterWidth * rasterHeight * 4, sizeof(GLubyte));

	this->loadContext =
		context = CGBitmapContextCreate(loadImageData, rasterWidth, rasterHeight, 8, 4 * rasterWidth, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
	CGColorSpaceRelease(colorSpace);

	CGContextTranslateCTM (loadContext, 0, rasterHeight);
	CGContextScaleCTM (loadContext, 1.0, -1.0);
	CGContextClearRect( loadContext, CGRectMake( 0, 0, rasterWidth, rasterHeight ) );
	CGContextTranslateCTM( loadContext, 0, rasterHeight - rasterHeight );
	
	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;
	
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	CGContextDrawImage( loadContext, CGRectMake( 0, 0, loadImgWidth, loadImgHeight ), image );
	
	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);
	
	byte *imageData = (byte*)loadImageData;
	unsigned int w = (unsigned int)(rasterWidth*4);
	for (int x = 0; x < loadImgWidth; x++)
	{
		for (int y = 0; y < rasterHeight; y++)
		{
			byte b = imageData[y*w + (x*4) + 0];
			byte g = imageData[y*w + (x*4) + 1];
			byte r = imageData[y*w + (x*4) + 2];
			byte a = imageData[y*w + (x*4) + 3];
			
			// CG makes premultiplication (kCGImageAlphaPremultipliedLast)
			// un-premultiply image pixels
			imageData[y*w + (x*4) + 0] = URANGE(0, r / (a / 255.), 255);
			imageData[y*w + (x*4) + 1] = URANGE(0, g / (a / 255.), 255);
			imageData[y*w + (x*4) + 2] = URANGE(0, b / (a / 255.), 255);
			imageData[y*w + (x*4) + 3] = a;
			
		}
	}
	
	CGContextRelease(context);
	CGImageRelease(image);

	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;
	
	this->fileLoadError = IMAGE_LOAD_ERROR_NONE;

	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;
	
	this->resourceIsActive = true;
	this->resourceState = RESOURCE_STATE_LOADED;
}

void CSlrImage::LoadImage(CImageData *origImageData)
{
	this->LoadImage(origImageData, RESOURCE_PRIORITY_STATIC, true);
}

void CSlrImage::LoadImage(CImageData *origImageData, byte resourcePriority)
{
	this->LoadImage(origImageData, resourcePriority, true);
}

void CSlrImage::LoadImage(CImageData *origImageData, byte resourcePriority, bool flipImageVertically)
{
	LOGR("CSlrImage::LoadImage from CImageData");
	
	gfxScale = 2.0f;
	
	//if (gScaleDownImages == false)
	{
		this->loadImgWidth = origImageData->width;
		this->loadImgHeight = origImageData->height;
		this->rasterWidth = NextPow2(loadImgWidth);
		this->rasterHeight = NextPow2(loadImgHeight);
		this->origRasterWidth = rasterWidth;
		this->origRasterHeight = rasterHeight;
		this->loadImage = NULL;
		this->loadTexData = NULL;
		this->loadContext = NULL;
		this->loadColorSpace = NULL;
		this->width = loadImgWidth/2.0;
		this->height = loadImgHeight/2.0;			
		
		this->defaultTexStartX = 0.0f;
		this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
		this->defaultTexStartY = 0.0f;
		this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);		

		this->loadImageData = malloc( rasterHeight * rasterWidth * 4 );
		memset(this->loadImageData, 0x00, rasterHeight * rasterWidth * 4);
		byte *imageData = (byte*)loadImageData;

		unsigned int w = (unsigned int)(rasterWidth*4);
		for (int x = 0; x < loadImgWidth; x++)
		{
			for (int y = 0; y < loadImgHeight; y++)
			{
				byte r, g, b, a;
				origImageData->GetPixelResultRGBA(x, y, &r, &g, &b, &a);
				imageData[y*w + (x*4) + 0] = r;
				imageData[y*w + (x*4) + 1] = g;
				imageData[y*w + (x*4) + 2] = b;
				imageData[y*w + (x*4) + 3] = a;
				
				//LOGD("rgb=%d %d %d %d", r, g, b, a);
			}
		}
		
		if (flipImageVertically)
		{
			for (int y = 0; y < loadImgHeight/2; y++)
			{
				for (int x = 0; x < rasterWidth; x++)
				{
					byte r = imageData[y*w + (x*4) + 0];
					byte g = imageData[y*w + (x*4) + 1];
					byte b = imageData[y*w + (x*4) + 2];
					byte a = imageData[y*w + (x*4) + 3];
					
					imageData[y*w + (x*4) + 0] = imageData[(loadImgHeight-1-y)*w + (x*4) + 0];
					imageData[y*w + (x*4) + 1] = imageData[(loadImgHeight-1-y)*w + (x*4) + 1];
					imageData[y*w + (x*4) + 2] = imageData[(loadImgHeight-1-y)*w + (x*4) + 2];
					imageData[y*w + (x*4) + 3] = imageData[(loadImgHeight-1-y)*w + (x*4) + 3];
					
					imageData[(loadImgHeight-1-y)*w + (x*4) + 0] = r;
					imageData[(loadImgHeight-1-y)*w + (x*4) + 1] = g;
					imageData[(loadImgHeight-1-y)*w + (x*4) + 2] = b;
					imageData[(loadImgHeight-1-y)*w + (x*4) + 3] = a;
					
				}
			}
		}
	}
	
	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;			
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;			

	this->resourcePriority = resourcePriority;
	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->resourceIsActive = true;
	this->resourceState = RESOURCE_STATE_LOADED;

	//LOGR("image loaded ok");
}

void CSlrImage::RefreshImageParameters(CImageData *origImageData, byte resourcePriority, bool flipImageVertically)
{
	// only refresh parameters, do not load
	LOGR("CSlrImage::RefreshImageParameters from CImageData");
	
	gfxScale = 2.0f;
	
	//if (gScaleDownImages == false)
	{
		this->loadImgWidth = origImageData->width;
		this->loadImgHeight = origImageData->height;
		this->rasterWidth = NextPow2(loadImgWidth);
		this->rasterHeight = NextPow2(loadImgHeight);
		this->origRasterWidth = rasterWidth;
		this->origRasterHeight = rasterHeight;
		this->loadImage = NULL;
		this->loadTexData = NULL;
		this->loadContext = NULL;
		this->loadColorSpace = NULL;
		this->width = loadImgWidth/2.0;
		this->height = loadImgHeight/2.0;
		
		this->defaultTexStartX = 0.0f;
		this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
		this->defaultTexStartY = 0.0f;
		this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);
		
		this->loadImageData = malloc( rasterHeight * rasterWidth * 4 );
		memset(this->loadImageData, 0x00, rasterHeight * rasterWidth * 4);
	}
	
	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;
	
	this->resourcePriority = resourcePriority;
	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;
	
	this->resourceIsActive = true;
	this->resourceState = RESOURCE_STATE_LOADED;
	
	//LOGR("image loaded ok");
}

void CSlrImage::PreloadImage(CSlrFile *imgFile)
{
	if (imgFile == NULL)
	{
		SYS_FatalExit("PreloadImage: imgFile NULL");
	}
	
	byte magic = imgFile->ReadByte();
	if (magic != GFX_BYTE_MAGIC1)
	{
		SYS_FatalExit("PreloadImage '%s': bad magic %2.2x", imgFile->fileName, magic);
	}
	
	u16 version = imgFile->ReadUnsignedShort();
	if (version > GFX_FILE_VERSION)
	{
		SYS_FatalExit("PreloadImage '%s': version not supported %4.4x", imgFile->fileName, version);
	}
	
	byte gfxType = imgFile->ReadByte();
	if (gfxType != GFX_FILE_TYPE_RGBA)
	{
		SYS_FatalExit("PreloadImage '%s': type not supported %2.2x", imgFile->fileName, gfxType);
	}
	
	u32 targetScreenWidth = imgFile->ReadUnsignedShort();
	u32 origImageWidth = imgFile->ReadUnsignedShort();
	u32 origImageHeight = imgFile->ReadUnsignedShort();
	u32 destScreenWidth = imgFile->ReadUnsignedShort();
	
	this->loadImgWidth = (float)imgFile->ReadUnsignedShort();
	this->loadImgHeight = (float)imgFile->ReadUnsignedShort();
	this->rasterWidth = (float)imgFile->ReadUnsignedShort();
	this->rasterHeight = (float)imgFile->ReadUnsignedShort();
	
	this->resourceLoadingSize = rasterWidth * rasterHeight * 4 * 2;
	this->resourceIdleSize = rasterWidth * rasterHeight * 4;

	this->width = loadImgWidth/2.0;
	this->height = loadImgHeight/2.0;
	
	this->gfxScale = (float)loadImgWidth / (float)origImageWidth;
	this->origRasterWidth = rasterWidth / gfxScale;
	this->origRasterHeight = rasterWidth / gfxScale;
	
	// fake gfxScale *2 because width is /2
	this->gfxScale *= 2.0f;

	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);
	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;
	
	this->resourceIsActive = false;
	this->resourceState = RESOURCE_STATE_PRELOADING;
}

namespace
{
	// stb_image callbacks that operate on a CSlrFile
    int jpegRead(void* user, char* data, int size)
    {
        CSlrFile* stream = static_cast<CSlrFile*>(user);
        return static_cast<int>(stream->Read((byte*)data, size));
    }
    void jpegSkip(void* user, int size)
    {
		LOGError("CSlrImage: jpegSkip=%d not implemented", size);
		CSlrFile* stream = static_cast<CSlrFile*>(user);
		stream->Seek(stream->Tell() + size);
    }
    int jpegEof(void* user)
    {
        CSlrFile* stream = static_cast<CSlrFile*>(user);
        return stream->Eof();
    }
}

void CSlrImage::LoadImage(CSlrFile *imgFile)
{
	if (imgFile == NULL)
	{
		SYS_FatalExit("LoadImage: imgFile NULL");
	}
	
	byte magic = imgFile->ReadByte();
	if (magic != GFX_BYTE_MAGIC1)
	{
		SYS_FatalExit("LoadImage '%s': bad magic %2.2x", imgFile->fileName, magic);
	}
	
	u16 version = imgFile->ReadUnsignedShort();
	if (version > GFX_FILE_VERSION)
	{
		SYS_FatalExit("LoadImage '%s': version not supported %4.4x", imgFile->fileName, version);
	}
	
	byte gfxType = imgFile->ReadByte();
	if (gfxType != GFX_FILE_TYPE_RGBA)
	{
		SYS_FatalExit("LoadImage '%s': type not supported %2.2x", imgFile->fileName, gfxType);
	}
	
	u32 targetScreenWidth = imgFile->ReadUnsignedShort();
	u32 origImageWidth = imgFile->ReadUnsignedShort();
	u32 origImageHeight = imgFile->ReadUnsignedShort();
	u32 destScreenWidth = imgFile->ReadUnsignedShort();
	
	this->loadImgWidth = (float)imgFile->ReadUnsignedShort();
	this->loadImgHeight = (float)imgFile->ReadUnsignedShort();
	this->rasterWidth = (float)imgFile->ReadUnsignedShort();
	this->rasterHeight = (float)imgFile->ReadUnsignedShort();
	
//	LOGD("... targetScreenWidth=%d", targetScreenWidth);
//	LOGD("... origImageWidth=%d", origImageWidth);
//	LOGD("... origImageHeight=%d", origImageHeight);
//	LOGD("... destScreenWidth=%d", destScreenWidth);
//	LOGD("... imageWidth=%d", loadImgWidth);
//	LOGD("... imageHeight=%d", loadImgHeight);
	
	this->width = ((float)origImageWidth)/2.0f;
	this->height = ((float)origImageHeight)/2.0;
	
//	LOGD("... rasterWidth=%f", rasterWidth);
//	LOGD("... rasterHeight=%f", rasterHeight);

	this->gfxScale = (float)loadImgWidth / (float)origImageWidth;
//	LOGD("... gfxScale=%3.2f", this->gfxScale);
	
	this->origRasterWidth = rasterWidth / gfxScale;
	this->origRasterHeight = rasterWidth / gfxScale;

	// fake gfxScale *2 because width is /2
	this->gfxScale *= 2.0f;
	
	this->defaultTexStartX = 0.0f;
	this->defaultTexEndX = ((GLfloat)loadImgWidth / (GLfloat)rasterWidth);
	this->defaultTexStartY = 0.0f;
	this->defaultTexEndY = ((GLfloat)loadImgHeight / (GLfloat)rasterHeight);
	
	u32 numBytes = rasterWidth * rasterHeight * 4;
	
	byte compressionType = imgFile->ReadByte();
	
	
	if (compressionType == GFX_COMPRESSION_TYPE_UNCOMPRESSED)
	{
		this->loadImageData = malloc( rasterHeight * rasterWidth * 4 );
		byte *imageBuffer = (byte *)this->loadImageData;

		imgFile->Read(imageBuffer, numBytes);
	}
	else if (compressionType == GFX_COMPRESSION_TYPE_ZLIB)
	{
		u32 imageNumBytes = numBytes;
		this->loadImageData = malloc( imageNumBytes );
		byte *imageBuffer = (byte *)this->loadImageData;
		

		u32 compSize = imgFile->ReadUnsignedInt();
		
		CSlrFileZlib *fileZlib = new CSlrFileZlib(imgFile);
		fileZlib->Read(imageBuffer, imageNumBytes);
		
		delete fileZlib;
		
		//// original:
//		uLong destSize = (uLong)numBytes;
//		uLong sourceLen = compSize;
//		byte *compBuffer = new byte[compSize];
//		imgFile->Read(compBuffer, compSize);
//
//		int result = uncompress (imageBuffer, &destSize, compBuffer, sourceLen);
//		if (result != Z_OK)
//		{
//			SYS_FatalExit("LoadImage '%s': zlib error %d", imgFile->fileName, result);
//		}
//		delete [] compBuffer;
		//////////////
		
		
		/*
#define ZLIB_CHUNK_SIZE 1024*1024
		
		byte *chunkBuf = new byte[ZLIB_CHUNK_SIZE];
		
		int ret;
		z_stream strm;
		strm.zalloc = Z_NULL;
		strm.zfree = Z_NULL;
		strm.opaque = Z_NULL;
		strm.avail_in = 0;
		strm.next_in = Z_NULL;
		ret = inflateInit(&strm);
		if (ret != Z_OK)
		{
			SYS_FatalExit("inflateInit failed");
		}

		do
		{
			u32 numBytes = imgFile->GetFileSize() - imgFile->Tell();
			if (numBytes == 0)
			{
				LOGError("CSlrFile stream ended before Z_STREAM_END");
				break;
			}
			
			if (numBytes > ZLIB_CHUNK_SIZE)
			{
				numBytes = ZLIB_CHUNK_SIZE;
			}
			
			imgFile->Read(chunkBuf, numBytes);

			strm.avail_in = numBytes;
			strm.next_in = chunkBuf;
			
			// run inflate() on input until output buffer not full
			do
			{
				strm.avail_out = imageNumBytes;
				strm.next_out = imageBuffer;
				ret = inflate(&strm, Z_NO_FLUSH);
				assert(ret != Z_STREAM_ERROR);  // state not clobbered
				
				if (ret == Z_STREAM_END)
				{
					break;
				}
				else if (ret == Z_NEED_DICT)
				{
					LOGError("zlib: Z_NEED_DICT");
					break;
				}
				else if (ret == Z_DATA_ERROR)
				{
					LOGError("zlib: Z_DATA_ERROR");
					break;
				}
				else if (ret == Z_MEM_ERROR)
				{
					LOGError("zlib: Z_MEM_ERROR");
					break;
				}
				
				u32 have = imageNumBytes - strm.avail_out;
				imageBuffer += have;
				imageNumBytes -= have;

			} while (strm.avail_out == 0);
			
			// done when inflate() says it's done
		} while (ret != Z_STREAM_END);
		
		delete chunkBuf;
		inflateEnd(&strm);
		*/
		
		
		
		
//		CByteBuffer *buf = new CByteBuffer();
//		buf->PutBytes(imageBuffer, width * height * 4);
//		buf->storeToDocuments("TESTZLIB");
//		LOGD("stored TESTZLIB");


	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG)
	{
		u32 compSize = imgFile->ReadUnsignedInt();
		
		stbi_io_callbacks callbacks;
		callbacks.read = &jpegRead;
		callbacks.skip = &jpegSkip;
		callbacks.eof  = &jpegEof;
		
		int jpegWidth, jpegHeight, jpegChannels;
		this->loadImageData = stbi_load_from_callbacks(&callbacks, imgFile, &jpegWidth, &jpegHeight, &jpegChannels, STBI_rgb_alpha);
		
		//LOGD("failure=%s", stbi_failure_reason());
				
		LOGD("jpeg loaded: width=%d height=%d channels=%d", jpegWidth, jpegHeight, jpegChannels);

//		CByteBuffer *buf = new CByteBuffer();
//		buf->PutBytes((byte*)this->loadImageData, width * height * 4);
//		buf->storeToDocuments("TESTJPEG");
//		LOGD("stored TESTJPEG");

	}
	else if (compressionType == GFX_COMPRESSION_TYPE_JPEG_ZLIB)
	{
		u32 compSize = imgFile->ReadUnsignedInt();
		
		
		
//		uLong destSize = (uLong)numBytes;
//		uLong sourceLen = compSize;
//		byte *compBuffer = new byte[compSize];
//		
//		byte *jpegBuf = new byte[numBytes];
//		
//		imgFile->Read(compBuffer, compSize);
//		
//		int result = uncompress (jpegBuf, &destSize, compBuffer, sourceLen);
//		if (result != Z_OK)
//		{
//			SYS_FatalExit("LoadImage '%s': zlib error %d", imgFile->fileName, result);
//		}
//		delete [] compBuffer;
//		CSlrFileMemory *fileZlib = new CSlrFileMemory(jpegBuf, destSize);
		
		
		CSlrFileZlib *fileZlib = new CSlrFileZlib(imgFile);
		fileZlib->fileSize = compSize;
		
		
		stbi_io_callbacks callbacks;
		callbacks.read = &jpegRead;
		callbacks.skip = &jpegSkip;
		callbacks.eof  = &jpegEof;
		
		int jpegWidth, jpegHeight, jpegChannels;
		this->loadImageData = stbi_load_from_callbacks(&callbacks, fileZlib, &jpegWidth, &jpegHeight, &jpegChannels, STBI_rgb_alpha);
		
		//LOGD("failure=%s", stbi_failure_reason());
		
		LOGD("jpeg-zlib loaded: width=%d height=%d channels=%d", jpegWidth, jpegHeight, jpegChannels);
		
		delete fileZlib;
		
		//		CByteBuffer *buf = new CByteBuffer();
		//		buf->PutBytes((byte*)this->loadImageData, width * height * 4);
		//		buf->storeToDocuments("TESTJPEG");
		//		LOGD("stored TESTJPEG");
		
	}
	
	else SYS_FatalExit("CSlrImage::LoadImage: unknown compression type %2.2x (fileName='%s')", compressionType, imgFile->fileName);
	
	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;

	this->resourceIdleSize = rasterWidth * rasterHeight * 4;
	
	this->resourceIsActive = true;
	this->resourceState = RESOURCE_STATE_LOADED;
}

CImageData *CSlrImage::GetImageData(float *imageScale, u32 *width, u32 *height)
{
	*imageScale = this->gfxScale;
	*width = this->loadImgWidth;
	*height = this->loadImgHeight;

	if (this->imageData != NULL)
	{
		return this->imageData;
	}
	
	imageData = new CImageData(this->rasterWidth, this->rasterHeight, IMG_TYPE_RGBA, this->loadImageData);
	return imageData;
}

void CSlrImage::BindImage()
{
	//LOGD("BindImage()");

	if (this->loadImageData == NULL)
		SYS_FatalExit("BindImage() loadImageData NULL");
	
	glGenTextures(1, &texture[0]);
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	///glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, texture[0]);
	
	
	isBound = true;
	isActive = true;
	
	resourceIsActive = true;
	resourceState = RESOURCE_STATE_LOADED;

	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	if (this->linearScaling)
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else 
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
//  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rasterWidth, rasterHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, loadImageData);
}

void CSlrImage::ReBindImage()
{
	//LOGD("ReBindImage()");
	
	if (this->loadImageData == NULL)
		SYS_FatalExit("BindImage() loadImageData NULL");
	
	glBindTexture(GL_TEXTURE_2D, texture[0]);
	
	isBound = true;
	isActive = true;
	
	resourceIsActive = true;
	resourceState = RESOURCE_STATE_LOADED;
	
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	if (this->linearScaling)
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	}
	else
	{
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	}
	
	
	//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	//  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, rasterWidth, rasterHeight, GL_RGBA, GL_UNSIGNED_BYTE, loadImageData);
}


void CSlrImage::FreeLoadImage()
{
	/*
	if (loadColorSpace != NULL)
		CGColorSpaceRelease( loadColorSpace );
	loadColorSpace = NULL;
	
	if (loadContext != NULL)
		CGContextRelease(loadContext);	
	loadContext = NULL;
	*/
	
	if (imageData != NULL)
	{
		delete imageData;
		imageData = NULL;
		this->loadImageData = NULL;
	}

	if (loadImageData != NULL)
		free(loadImageData);	
	loadImageData = NULL;
	
	 /*
	if (loadImage != NULL)
		[loadImage release];	
	loadImage = NULL;
	
	if (loadTexData != NULL)
		[loadTexData release];	
	loadTexData = NULL;*/
}

void CSlrImage::Deallocate()
{
	this->FreeLoadImage();
	glDeleteTextures(1, &texture[0]);
	this->isBound = false;
}

NSImage* CSlrImage::Resize(NSImage *inImage, CGRect thumbRect)
{
	SYS_FatalExit("CSlrImage::Resize: TODO");
	return NULL;
}

// set image data directly it is a hack, be carefull
void CSlrImage::SetLoadImageData(CImageData *imageData)
{
	loadImageData = imageData->resultData;
}

void CSlrImage::ReplaceImageData(CImageData *imageData)
{
	this->SetLoadImageData(imageData);
	this->ReBindImage();
	this->loadImageData = NULL;
}


CSlrImage::CSlrImage(CSlrImage *imgAtlas, GLfloat startX, GLfloat startY, GLfloat width, GLfloat height, GLfloat downScale, char *name)
{
	//LOGD("ImageFromAtlas: '%s' %f %f %f %f", name, startX, startY, width, height);
	
	//	this->InitFromAtlas(CSlrImage *imgAtlas, int startX, int startY, int endX, int endY, GLfloat downScale);
	
	this->isFromAtlas = true;
	this->imgAtlas = imgAtlas;
	//(texture[0]) = &(texture[0]);
	
	if (!(ispow2((int)imgAtlas->origRasterWidth)))
		SYS_FatalExit("ImgAtlas is !pow2");
	
	GLfloat atlStartX = 0;
	GLfloat atlStartY = 0;
	GLfloat atlEndX = 0;
	GLfloat atlEndY = 0;
	
	if (gScaleDownImages == true)
	{
		this->width = width/2; //(GLfloat)((GLfloat)atlEndX - (GLfloat)atlStartX);
		this->height = height/2; //(GLfloat)((GLfloat)atlEndY - (GLfloat)atlStartY);
		
		atlStartX = startX/2; // / (GLfloat)(2.0f); //startX >> 1;
		atlEndX = startX/2 + this->width; // / (GLfloat)(2.0f); //endX >> 1;
		atlStartY = startY/2; // / (GLfloat)(2.0f); //startY >> 1;
		atlEndY = startY/2 + this->height; // / (GLfloat)(2.0f); //endY >> 1;
		
	}
	else //if (gScaleDownImages == false)
	{
		this->width = width/2; //(GLfloat)((GLfloat)atlEndX - (GLfloat)atlStartX);
		this->height = height/2; //(GLfloat)((GLfloat)atlEndY - (GLfloat)atlStartY);		
		
		atlStartX = startX;
		atlEndX = startX + width-2;
		atlStartY = startY;
		atlEndY = startY + height-2;
	}
	
	/* 
	 2010-12-14 13:52:26.185 KidsChristmasTree[6832:207] InitFromAtlas: 1.000000 1.000000 95.000000 95.000000
	 2010-12-14 13:52:26.189 KidsChristmasTree[6832:207] 0.000977 0.092773 0.000977 0.092773
	 */
	
	this->rasterWidth = imgAtlas->origRasterWidth;
	this->rasterHeight = imgAtlas->origRasterHeight;
	
	this->defaultTexStartX = ((GLfloat)atlStartX / (GLfloat)rasterWidth);
	this->defaultTexEndX = ((GLfloat)atlEndX / (GLfloat)rasterWidth);
	this->defaultTexStartY = ((GLfloat)atlStartY / (GLfloat)rasterHeight);
	this->defaultTexEndY = ((GLfloat)atlEndY / (GLfloat)rasterHeight);
	
	//LOGD("width=%f height=%f", width, height);
	//LOGD("atl= %f %f %f %f", atlStartX, atlEndX, atlStartY, atlEndY);
	//LOGD("raster= %f %f", imgAtlas->rasterWidth, imgAtlas->rasterHeight);
	//LOGD("tex= %f %f %f %f", defaultTexStartX, defaultTexEndX, defaultTexStartY, defaultTexEndY);

	this->widthD2 = this->width/2.0;
	this->heightD2 = this->height/2.0;			
	this->widthM2 = this->width*2.0;
	this->heightM2 = this->height*2.0;			

}

/// resource manager

// should preload resource and set resource size
bool CSlrImage::ResourcePreload(char *fileName, bool fromResources)
{
	this->resourceIsActive = false;
	this->PreloadImage(fileName, fromResources);
	return true;
}

// get size of resource in bytes
u32 CSlrImage::ResourceGetLoadingSize()
{
	return this->resourceLoadingSize;
}

u32 CSlrImage::ResourceGetIdleSize()
{
	return this->resourceIdleSize;
}

CGSize PSPNGSizeFromMetaData( NSString* anFileName )
{
    // File Name from Bundle Path.
    NSString *fullFileName = anFileName; //[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], anFileName ];
	
    // File Name to C String.
    const char* fileName = [fullFileName UTF8String];
	
    // source file
    FILE * infile;
	
    // Check if can open the file.
    if ((infile = fopen(fileName, "rb")) == NULL)
    {
        NSLog(@"PSFramework Warning >> (PSPNGSizeFromMetaData) can't open the file: %@", fullFileName );
		
#if defined(FINAL_RELEASE)
		SYS_FatalExit("PSPNGSizeFromMetaData: file not found");
#endif
        return CGSizeZero;
		
    }
	
    //////  ////// 	////// 	////// 	////// 	////// 	////// 	////// 	////// 	////// 	//////
	
    // Lenght of Buffer.
#define bytesLenght 30
	
    // Bytes Buffer.
    unsigned char buffer[bytesLenght];
	
    // Grab Only First Bytes.
    fread(buffer, 1, bytesLenght, infile);
	
    // Close File.
    fclose(infile);
	
    //////  ////// 	////// 	////// 	//////
	
    // PNG Signature.
    unsigned char png_signature[8] = {137, 80, 78, 71, 13, 10, 26, 10};
	
    // Compare File signature.
    if ((int)(memcmp(&buffer[0], &png_signature[0], 8))) {
		
        NSLog(@"PSFramework Warning >> (PSPNGSizeFromMetaData) : The file (%@) don't is one PNG file.", anFileName);
        return CGSizeZero;
		
    }
	
    //////  ////// 	////// 	////// 	////// ////// 	////// 	////// 	////// 	//////
	
    // Calc Sizes. Isolate only four bytes of each size (width, height).
    int width[4];
    int height[4];
    for ( int d = 16; d < ( 16 + 4 ); d++ ) {
        width[ d-16] = buffer[ d ];
        height[d-16] = buffer[ d + 4];
    }
	
    // Convert bytes to Long (Integer)
    long resultWidth = (width[0] << (int)24) | (width[1] << (int)16) | (width[2] << (int)8) | width[3];
    long resultHeight = (height[0] << (int)24) | (height[1] << (int)16) | (height[2] << (int)8) | height[3];
	
    // Return Size.
    return CGSizeMake( resultWidth, resultHeight );
	
}

